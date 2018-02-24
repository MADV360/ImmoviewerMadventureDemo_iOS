package com.madv360.madv.connection;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.text.TextUtils;
import android.util.Log;

import com.madv360.glrenderer.MadvGLRenderer;
import com.madv360.madv.common.BackgroundExecutor;
import com.madv360.madv.common.Const;
import com.madv360.madv.connection.ambarequest.AMBASetWifiRequest;
import com.madv360.madv.connection.ambaresponse.AMBAGetAllModeParamResponse;
import com.madv360.madv.connection.ambaresponse.AMBAGetAllSettingParamResponse;
import com.madv360.madv.connection.ambaresponse.AMBASaveMediaFileDoneResponse;
import com.madv360.madv.connection.ambaresponse.AMBASyncStorageAllStateResponse;
import com.madv360.madv.media.MVMedia;
import com.madv360.madv.media.MVMediaManager;
import com.madv360.madv.model.MVCameraDevice;
import com.madv360.madv.model.bean.ImageFilterBean;
import com.madv360.madv.model.bean.SettingTreeNode;
import com.madv360.madv.utils.DateUtil;
import com.madv360.madv.utils.FileUtil;
import com.madv360.madv.utils.MD5Util;
import com.madv360.madv.utils.StringUtil;

import java.io.File;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.LinkedList;
import java.util.List;

import bootstrap.appContainer.AppStorageManager;
import bootstrap.appContainer.ElephantApp;
import bootstrap.appContainer.UserAppConst;
import foundation.activeandroid.query.Select;
import foundation.downloader.bizs.DLManager;
import foundation.helper.SystemInfo;
import uikit.component.Util;

/**
 * Created by qiudong on 16/6/8.
 * 相机代理类，封装了与控制相机直接相关的方法和属性
 */
public class MVCameraClientImpl extends MVCameraClient implements CMDConnectManager.CMDConnectionObserver,
        DATAConnectManager.DataConnectionObserver {
    private static final String TAG = "QD:MVCameraClientImpl";
    private static final int MSG_STATE_CHANGED = 1;
    private static final int MSG_WIFI_SET = 2;
    private static final int MSG_WIFI_RESTART = 3;
    private static final int MSG_MODE_CHANGED = 4;
    private static final int MSG_BEGIN_SHOOTING = 5;
    private static final int MSG_BEGIN_SHOOTING_ERROR = 6;
    private static final int MSG_END_SHOOTING_ERROR = 7;
    private static final int MSG_END_SHOOTING = 8;
    private static final int MSG_TIMER_TICKED = 9;
    private static final int MSG_SETTING_CHANGED = 10;
    private static final int MSG_VOLTAGE_CHANGED = 11;
    private static final int MSG_WORK_STATE_CHANGED = 12;
    private static final int MSG_RECEIVE_NOTIFICATION = 13;
    private static final int MSG_STORAGE_MOUNTED_STATE_CHANGED = 14;
    private static final int MSG_STORAGE_STATE_CHANGED = 15;
    private static final int MSG_STORAGE_TOTAL_FREE_CHANGED = 16;
    private static final int MSG_ALL_SETTING_RECEIVED = 17;
    private static final int MSG_COUNT_DOWN_TICKED = 18;
    private static final int MSG_SDCARD_SLOWLY_WRITE = 19;
    private static final int MSG_WAIT_SAVE_VIDEO_DONE = 20;

    private int sessionToken = AMBACommands.AMBA_SESSION_TOKEN_INIT;
    private int state = CameraClientStateNotConnected;
    private int workState = CameraWorkStateIdle;
    private LinkedList<WeakReference<StateListener>> stateListeners = new LinkedList<>();

    // 非持久化属性：
    private MVCameraDevice connectingCamera = null;
    private ImageFilterBean currentFilter = null;
    private String mUsbSerialNumber;

    private boolean isTiming = false;
    private boolean isShooting = false;//Is camera busy capturing?
    private int storageMounted = 1;
    private int storageState = StorageStateAvailable;
    private int storageTotal = -1;
    private int storageFree = -1;
    private int videoCapacity = -1;
    private int photoCapacity = -1;
    private int loopRecord = 0;

    private int voltagePercent = 100;
    private boolean isCharging = false;

    public MVCameraClientImpl() {
        DATAConnectManager.getInstance().addObserver(this);
        CMDConnectManager.getInstance().addObserver(this);
    }

    @Override
    public void finalize() {
        CMDConnectManager.getInstance().removeObserver(this);
        DATAConnectManager.getInstance().removeObserver(this);
    }

    /**
     * 添加状态回调监听者
     */
    public void addStateListener(StateListener listener) {
        stateListeners.add(new WeakReference<>(listener));
    }

    /**
     * 移除状态回调监听者
     */
    public void removeStateListener(StateListener listener) {
        int index = 0;
        for (WeakReference<StateListener> ref : stateListeners) {
            if (ref.get() == listener) {
                break;
            }
            index++;
        }
        if (index < stateListeners.size()) {
            stateListeners.remove(index);
        }
    }

    public static final String StringFromState(int state) {
        switch (state) {
            case CameraClientStateConnected:
                return "CameraClientStateConnected";
            case CameraClientStateConnecting:
                return "CameraClientStateConnecting";
            case CameraClientStateNotConnected:
                return "CameraClientStateNotConnected";
            case CameraClientStateDisconnecting:
                return "CameraClientStateDisconnecting";
        }
        return "N/A";
    }

    public static final String StringFromWorkState(int workState) {
        switch (workState) {
            case AMBACommands.AMBA_PARAM_CAMERA_STATE_IDLE:
                return "Idle";
            case AMBACommands.AMBA_PARAM_CAMERA_STATE_STANDBY:
                return "Standby";
            case AMBACommands.AMBA_PARAM_CAMERA_STATE_STORAGE:
                return "Storage";
            case AMBACommands.AMBA_PARAM_CAMERA_STATE_CAPTURING:
                return "Capturing";
            case AMBACommands.AMBA_PARAM_CAMERA_STATE_CAPTURING_MICRO:
                return "CapturingMicro";
            case AMBACommands.AMBA_PARAM_CAMERA_STATE_CAPTURING_SLOW:
                return "CapturingSlow";
            case AMBACommands.AMBA_PARAM_CAMERA_STATE_PHOTOING:
                return "Photoing";
        }
        return "N/A";
    }

    public static String remoteFilePathOfRTOSPath(String rtosFilePath) {
        String remoteFilePath = rtosFilePath.replace('\\', '/');
        remoteFilePath = remoteFilePath.replace("C:/", "/tmp/SD0/");
        return remoteFilePath;
    }

    public static String remoteFilePathOfLocalMountedPath(String mountedFilePath) {
        String remoteFilePath = mountedFilePath.replace('\\', '/');
        remoteFilePath = remoteFilePath.replace("C:/", "/tmp/SD0/");
        return remoteFilePath;
    }

    /**
     * 连接相机
     */
    public void connectCamera() {
        if (getState() == CameraClientStateNotConnected
                || getState() == CameraClientStateDisconnecting) {
            setState(CameraClientStateConnecting);
            CMDConnectManager.getInstance().openConnection();
        } else if (getState() == CameraClientStateConnected) {
            setState(CameraClientStateConnecting);
            CMDConnectManager.getInstance().openConnection();
            startSessionAndSyncCamera();
        }
    }

    public boolean connectCamera(String ssid) {
        if (WiFiConnectManager.getInstance().isEqualsWithCurrentWiFi(ssid)) {
            connectCamera();
            return true;
        } else {
            return false;
        }
    }

    private void startSessionAndSyncCamera() {
        class SetClientInfoListener implements AMBARequest.ResponseListener {
            @Override
            public void onResponseReceived(AMBAResponse response) {
                if (response.isRvalOK()) {
                    // Synchronize LUT
                    checkAndSynchronizeLUT(connectingCamera.getUUID(), (String) response.getParam());
                    // Synchronize Camera Work State & Mode:
                    synchronizeWorkStateAndCameraMode();
                    // Synchronize Time:
                    synchronizeCameraTime();
                    // Synchronize storage:
                    storageState = StorageStateAvailable;
                    synchronizeCameraStorageAllState();
                    // Synchronize Settings:
                    synchronizeCameraSettings();
                } else {
                    disconnectCamera();
                }
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {
                disconnectCamera();
            }
        }

        class GetWiFiSettingsListener implements AMBARequest.ResponseListener {
            private MVCameraDevice device;

            public GetWiFiSettingsListener(MVCameraDevice device) {
                this.device = device;
            }

            @Override
            public void onResponseReceived(AMBAResponse response) {
                if (response.isRvalOK()) {
                    String param = (String) response.getParam();
                    String[] params = param.split("\n");
                    for (String str : params) {
                        if (null == str) continue;
                        if (str.contains(AMBACommands.PASSWORD_TAG)) {
                            String[] args = str.split("=");
                            if (args.length >= 2) {
                                device.password = args[1];
                            }
                        } else if (str.contains(AMBACommands.APPUBLIC_TAG)) {
                            String[] args = str.split("=");
                            if (args.length >= 2) {
                                if (args[1].toLowerCase().equals("yes")) {
                                    device.password = "";
                                }
                            }
                        } else if (str.contains(AMBACommands.SSID_TAG)) {
                            String[] args = str.split("=");
                            if (args.length >= 2) {
                                device.SSID = args[1];
                            }
                        }
                    }

                    connectingCamera = device;
                    device.save();

                    // setClientInfo and synchronize State & Mode
                    String localIP = WiFiConnectManager.getInstance().getWiFiIP();
                    SetClientInfoListener setClientInfoListener = new SetClientInfoListener();
                    AMBARequest setClientInfoRequest = new AMBARequest(setClientInfoListener, null);
                    setClientInfoRequest.setMsg_id(AMBACommands.AMBA_MSGID_SET_CLNT_INFO);
                    setClientInfoRequest.setType(AMBACommands.AMBA_SESSION_TYPE);
                    setClientInfoRequest.setToken(sessionToken);
                    setClientInfoRequest.setParam(localIP);
                    CMDConnectManager.getInstance().sendRequest(setClientInfoRequest);
                } else {
                    disconnectCamera();
                }
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {
                disconnectCamera();
            }
        }

        class GetSerialIDListener implements AMBARequest.ResponseListener {
            @Override
            public void onResponseReceived(AMBAResponse response) {
                if (response.isRvalOK()) {
                    String UUID = (String) response.getParam();
                    String SSID = WiFiConnectManager.getInstance().getWiFiSSID();

                    MVCameraDevice device = new Select()
                            .from(MVCameraDevice.class)
                            .where(MVCameraDevice.DB_KEY_UUID + " = ?", UUID)
                            .executeSingle();
                    if (null == device) {
                        device = new MVCameraDevice();
                        device.uuid = UUID;
                        device.SSID = SSID;
                        device.lastSyncTime = new Date();
                        device.save();
                    } else {
                        device.uuid = UUID;
                        device.SSID = SSID;
                        device.lastSyncTime = new Date();
                        device.save();
                    }

                    GetWiFiSettingsListener getWiFiSettingsListener = new GetWiFiSettingsListener(device);
                    AMBARequest getWiFiSettingsRequest = new AMBARequest(getWiFiSettingsListener, null);
                    getWiFiSettingsRequest.setMsg_id(AMBACommands.AMBA_MSGID_GET_WIFI_SETTING);
                    getWiFiSettingsRequest.setToken(sessionToken);
                    CMDConnectManager.getInstance().sendRequest(getWiFiSettingsRequest);
                } else {
                    disconnectCamera();
                }
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {
                disconnectCamera();
            }
        }

        AMBARequest.ResponseListener startSessionListener = new AMBARequest.ResponseListener() {
            @Override
            public void onResponseReceived(AMBAResponse response) {
                if (response.isRvalOK()) {
                    sessionToken = (int) ((Double) response.getParam()).doubleValue();
                    GetSerialIDListener getSerialIDListener = new GetSerialIDListener();
                    AMBARequest getSerialIDRequest = new AMBARequest(getSerialIDListener, null);
                    getSerialIDRequest.setMsg_id(AMBACommands.AMBA_MSGID_GET_SN);
                    getSerialIDRequest.setToken(sessionToken);
                    CMDConnectManager.getInstance().sendRequest(getSerialIDRequest);
                } else if (AMBACommands.AMBA_RVAL_START_SESSION_DENIED == response.getRval()) {
                    sessionToken = AMBACommands.AMBA_SESSION_TOKEN_INIT;
                    disconnectCamera(CameraExceptionOtherClient);
                }
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {
                disconnectCamera();
            }
        };
        AMBARequest startSessionRequest = new AMBARequest(startSessionListener, null);
        startSessionRequest.setToken(AMBACommands.AMBA_SESSION_TOKEN_INIT);
        startSessionRequest.setMsg_id(AMBACommands.AMBA_MSGID_START_SESSION);
        CMDConnectManager.getInstance().sendRequest(startSessionRequest);
    }

    private void synchronizeWorkStateAndCameraMode() {
        AMBARequest.ResponseListener getStateListener = new AMBARequest.ResponseListener() {
            @Override
            public void onResponseReceived(AMBAResponse response) {
                AMBAGetAllModeParamResponse allModeParamResponse = (AMBAGetAllModeParamResponse) response;
                if (allModeParamResponse.isRvalOK() && null != connectingCamera) {
                    workState = allModeParamResponse.getStatus();
                    int seconds = allModeParamResponse.getRec_time();
                    sendMessageToHandler(MSG_WORK_STATE_CHANGED, workState, 0, null);
                    switch (workState) {
                        case AMBACommands.AMBA_PARAM_CAMERA_STATE_STORAGE:
                            disconnectCamera(CameraExceptionInStorageMode);
                            break;
                        case AMBACommands.AMBA_PARAM_CAMERA_STATE_STANDBY:
                            break;
                        case AMBACommands.AMBA_PARAM_CAMERA_STATE_IDLE:
                            isShooting = false;
                            stopTimer();
                            connectingCamera.cameraMode = allModeParamResponse.getMode();
                            if (connectingCamera.cameraMode == MVCameraDevice.CameraModeVideo) {
                                connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodeVideoNormal;
                            } else if (connectingCamera.cameraMode == MVCameraDevice.CameraModePhoto) {
                                connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodePhotoNormal;
                            }
                            connectingCamera.cameraSubModeParam = 0;
                            connectingCamera.save();
                            sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);
                            sendMessageToHandler(MSG_END_SHOOTING, 0, 0, null);
                            break;
                        case AMBACommands.AMBA_PARAM_CAMERA_STATE_CAPTURING:
                            isShooting = true;
                            connectingCamera.cameraMode = MVCameraDevice.CameraModeVideo;
                            connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodeVideoNormal;
                            connectingCamera.cameraSubModeParam = 0;
                            connectingCamera.save();
                            startTimer(seconds, 300);
                            sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);
                            sendMessageToHandler(MSG_BEGIN_SHOOTING, 0, 0, null);
                            break;
                        case AMBACommands.AMBA_PARAM_CAMERA_STATE_CAPTURING_MICRO:
                            isShooting = true;
                            connectingCamera.cameraMode = MVCameraDevice.CameraModeVideo;
                            connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodeVideoMicro;
                            connectingCamera.cameraSubModeParam = allModeParamResponse.getSecond();
                            connectingCamera.save();
                            startTimer(seconds, 300);
                            sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);
                            sendMessageToHandler(MSG_BEGIN_SHOOTING, 0, 0, null);
                            break;
                        case AMBACommands.AMBA_PARAM_CAMERA_STATE_CAPTURING_SLOW:
                            isShooting = true;
                            connectingCamera.cameraMode = MVCameraDevice.CameraModeVideo;
                            connectingCamera.cameraSubMode = MVCameraDevice.CAMERA_SUBMODE_VIDEO_SLOW;
                            connectingCamera.cameraSubModeParam = allModeParamResponse.getLapse();
                            connectingCamera.save();
                            startTimer(seconds, 300);
                            sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);
                            sendMessageToHandler(MSG_BEGIN_SHOOTING, 0, 0, null);
                            break;
                        case AMBACommands.AMBA_PARAM_CAMERA_STATE_PHOTOING:
                            isShooting = true;
                            connectingCamera.cameraMode = MVCameraDevice.CameraModePhoto;
                            connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodePhotoNormal;
                            connectingCamera.cameraSubModeParam = 0;
                            connectingCamera.save();
                            sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);
                            sendMessageToHandler(MSG_BEGIN_SHOOTING, 0, 0, null);
                            break;
                        case AMBACommands.AMBA_PARAM_CAMERA_STATE_PHOTOING_DELAYED:
                            isShooting = true;
                            connectingCamera.cameraMode = MVCameraDevice.CameraModePhoto;
                            connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodePhotoTiming;
                            connectingCamera.cameraSubModeParam = allModeParamResponse.getTiming();
                            connectingCamera.save();
                            int timing = allModeParamResponse.getTiming();
                            int timing_c = allModeParamResponse.getTiming_c();
                            if (timing_c > 0 && timing_c < timing) {
                                timing -= timing_c;
                            }
                            startCountDown(timing);
                            sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);
                            break;
                    }
                } else {
                    isShooting = false;
                }
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {
                isShooting = false;
            }
        };
        AMBARequest getStateRequest = new AMBARequest(getStateListener, AMBAGetAllModeParamResponse.class);
        getStateRequest.setMsg_id(AMBACommands.AMBA_MSGID_GET_CAMERA_ALL_MODE_PARAM);
        getStateRequest.setToken(sessionToken);
        CMDConnectManager.getInstance().sendRequest(getStateRequest);
    }

    private void synchronizeCameraTime() {
        Date date = Calendar.getInstance().getTime();
        int weekDay = DateUtil.getDayOfWeek(date);
        String dateDesc = DateUtil.format(date, "yyyy-MM-dd-HH-mm-ss") + "-" + weekDay;
        AMBARequest rtcRequest = new AMBARequest(null);
        rtcRequest.setMsg_id(AMBACommands.AMBA_MSGID_RTC_SYNC);
        rtcRequest.setToken(sessionToken);
        rtcRequest.setParam(dateDesc);
        CMDConnectManager.getInstance().sendRequest(rtcRequest);
    }

    @Override
    public void synchronizeCameraStorageAllState() {
        AMBARequest.ResponseListener storageAllStateListener = new AMBARequest.ResponseListener() {
            @Override
            public void onResponseReceived(AMBAResponse response) {
                AMBASyncStorageAllStateResponse allStateResponse = (AMBASyncStorageAllStateResponse) response;
                int preStorageState = storageState;
                int prevStorageMounted = storageMounted;
                if (allStateResponse.isRvalOK()) {
                    storageMounted = 1;//mounted
                    storageState = allStateResponse.getSd_full();
                    storageTotal = allStateResponse.getSd_total();
                    storageFree = allStateResponse.getSd_free();
                    photoCapacity = allStateResponse.getRemain_jpg();
                    videoCapacity = allStateResponse.getRemain_video();
                } else if (allStateResponse.getRval() == AMBACommands.AMBA_RVAL_ERROR_NO_SDCARD) {
                    storageMounted = 0;//unmounted
                    storageState = StorageStateUnknown;
                    storageTotal = 0;
                    storageFree = 0;
                    photoCapacity = -1;
                    videoCapacity = -1;
                } else if (allStateResponse.getRval() == AMBACommands.AMBA_RVAL_ERROR_SDCARD) {
                    storageMounted = -1;//error
                    storageState = StorageStateUnknown;
                    storageTotal = 0;
                    storageFree = 0;
                    photoCapacity = -1;
                    videoCapacity = -1;
                } else {
                    storageMounted = 1;//mounted
                    storageState = StorageStateUnknown;
                    storageTotal = 0;
                    storageFree = 0;
                    photoCapacity = -1;
                    videoCapacity = -1;
                }
                if (prevStorageMounted != storageMounted) {
                    sendMessageToHandler(MSG_STORAGE_MOUNTED_STATE_CHANGED, storageMounted, 0, null);
                }
                sendMessageToHandler(MSG_STORAGE_STATE_CHANGED, preStorageState, storageState, null);

                if (isShooting && 0 == storageMounted) {
                    isShooting = false;
                    stopTimer();
                    sendMessageToHandler(MSG_END_SHOOTING, 0, 0, "");
                }

                SettingTreeNode optionNode = MVCameraDevice.findOptionNodeByUID(SettingTreeNode.FormatSD);
                if (null != optionNode && optionNode.subOptions.size() > 0) {
                    optionNode.setSelectedSubOptionByUID(0);
                    SettingTreeNode subOptionNode = optionNode.findSubOptionByUID(0);
                    subOptionNode.name = StringUtil.formatSDStorage(storageTotal, storageFree);
                }
                sendMessageToHandler(MSG_STORAGE_TOTAL_FREE_CHANGED, storageTotal, storageFree, null);
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {

            }
        };
        AMBARequest storageAllStateRequest = new AMBARequest(storageAllStateListener, AMBASyncStorageAllStateResponse.class);
        storageAllStateRequest.setMsg_id(AMBACommands.AMBA_MSGID_GET_STORAGE_ALL_STATE);
        storageAllStateRequest.setToken(sessionToken);
        CMDConnectManager.getInstance().sendRequest(storageAllStateRequest);
    }

    private void synchronizeCameraSettings() {
        class GetAllSettingListener implements AMBARequest.ResponseListener {
            @Override
            public void onResponseReceived(AMBAResponse response) {
                AMBAGetAllSettingParamResponse paramResponse = (AMBAGetAllSettingParamResponse) response;
                if (paramResponse.isRvalOK() && null != connectingCamera) {
                    List<SettingTreeNode> settingGroups = MVCameraDevice.getCameraSettings();
                    SettingTreeNode paramNode;
                    for (SettingTreeNode groupNode : settingGroups) {
                        for (SettingTreeNode optionNode : groupNode.subOptions) {
                            switch (optionNode.uid) {
                                case SettingTreeNode.VideoResolutionSetting:
                                    paramNode = optionNode.findSubOptionByMsgID(paramResponse.getV_res());
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.VideoWBSetting:
                                    paramNode = optionNode.findSubOptionByMsgID(paramResponse.getVideo_wb());
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.VideoEVSetting:
                                    paramNode = optionNode.findSubOptionByMsgID(paramResponse.getVideo_ev());
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.CameraLoopSetting:
                                    loopRecord = paramResponse.getLoop();
                                    paramNode = optionNode.findSubOptionByMsgID(paramResponse.getLoop());
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.PhotoResolutionSetting:
                                    paramNode = optionNode.findSubOptionByMsgID(paramResponse.getP_res());
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.PhotoWBSetting:
                                    paramNode = optionNode.findSubOptionByMsgID(paramResponse.getStill_wb());
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.PhotoISOSetting:
                                    paramNode = optionNode.findSubOptionByMsgID(paramResponse.getStill_iso());
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.PhotoShutterSetting:
                                    paramNode = optionNode.findSubOptionByMsgID(paramResponse.getStill_shutter());
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.PhotoEVSetting:
                                    paramNode = optionNode.findSubOptionByMsgID(paramResponse.getStill_ev());
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.CameraPreviewMode:
                                    int previewMode = getConnectingCameraPreviewMode();
                                    paramNode = optionNode.findSubOptionByMsgID(previewMode);
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.CameraPowerOffSetting:
                                    paramNode = optionNode.findSubOptionByMsgID(paramResponse.getPoweroff_time());
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.CameraBuzzerSetting:
                                    paramNode = optionNode.findSubOptionByMsgID(paramResponse.getBuzzer());
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.CameraLedSetting:
                                    paramNode = optionNode.findSubOptionByMsgID(paramResponse.getLed());
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.CameraProduceNameSetting:
                                    paramNode = optionNode.subOptions.get(0);
                                    paramNode.name = paramResponse.getProduct();
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);
                                    break;
                                case SettingTreeNode.SerialID:
                                    paramNode = optionNode.subOptions.get(0);
                                    paramNode.name = paramResponse.getSn();
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);

                                    connectingCamera.serialID = paramNode.name;
                                    connectingCamera.save();
                                    break;
                                case SettingTreeNode.FirmwareVersion:
                                    String version = paramResponse.getVer();
                                    String fwVersion = version.substring(0, version.indexOf(';'));
                                    String rcwVersion = version.substring(version.lastIndexOf(';') + 1, version.length());
                                    paramNode = optionNode.subOptions.get(0);
                                    paramNode.name = fwVersion;
                                    optionNode.setSelectedSubOptionByUID(paramNode.uid);

                                    connectingCamera.fwVer = fwVersion;
                                    connectingCamera.rcwVer = rcwVersion;
                                    connectingCamera.save();
                                    break;
                            }
                        }
                    }
                    sendMessageToHandler(MSG_ALL_SETTING_RECEIVED, 0, 0, null);
                    //电池电量
                    handleBatteryResponse(paramResponse.getBattery());
                } else {
                    disconnectCamera();
                }
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {

            }
        }
        GetAllSettingListener getAllSettingListener = new GetAllSettingListener();
        AMBARequest getAllSettingRequest = new AMBARequest(getAllSettingListener, AMBAGetAllSettingParamResponse.class);
        getAllSettingRequest.setToken(sessionToken);
        getAllSettingRequest.setMsg_id(AMBACommands.AMBA_MSGID_GET_CAMERA_ALL_SETTING_PARAM);
        CMDConnectManager.getInstance().sendRequest(getAllSettingRequest);
    }

    @Override
    public void wakeupCamera() {
        AMBARequest.ResponseListener wakeupListener = new AMBARequest.ResponseListener() {
            @Override
            public void onResponseReceived(AMBAResponse response) {

            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {

            }
        };
        AMBARequest wakeupRequest = new AMBARequest(wakeupListener);
        wakeupRequest.setToken(sessionToken);
        wakeupRequest.setMsg_id(AMBACommands.AMBA_MSGID_WAKEUP_CAMERA);
        CMDConnectManager.getInstance().sendRequest(wakeupRequest);
    }

    /**
     * 断开相机连接
     */
    @Override
    public void disconnectCamera() {
        disconnectCamera(0);
    }

    @Override
    public void disconnectCamera(final int reason) {
        DLManager.getInstance().dlClear();
        DATAConnectManager.getInstance().closeConnection();

        if (CMDConnectManager.getInstance().getState() == CMDConnectManager.SOCKET_STATE_NOT_READY) {
            setState(CameraClientStateNotConnected, new Integer(reason));
            return;
        }

        // Connecting: 1.Connect CMD Socket; 2.Start Session; 3.Sync Info; (4).Connect Data Socket;
        // Disconnecting: (1).Disconnect Data Socket; 2.Stop Session; 3.Disconnect CMD Socket;
        setState(CameraClientStateDisconnecting);
        AMBARequest.ResponseListener stopSessionListener = new AMBARequest.ResponseListener() {
            @Override
            public void onResponseReceived(AMBAResponse response) {
                callback();
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {
                callback();
            }

            private void callback() {
                setState(CameraClientStateNotConnected, new Integer(reason));
                CMDConnectManager.getInstance().closeConnection(reason);
            }
        };
        AMBARequest request = new AMBARequest(stopSessionListener, null);
        request.setToken(sessionToken);
        request.setMsg_id(AMBACommands.AMBA_MSGID_STOP_SESSION);
        CMDConnectManager.getInstance().sendRequestAndClearOthers(request);
    }

    /**
     * sessionToken
     */
    public int getToken() {
        return sessionToken;
    }

    /**
     * 手机当前连接到的WiFi的SSID
     */
    public String currentConnectingSSID() {
        return WiFiConnectManager.getInstance().getWiFiSSID();
    }

    /**
     * 手机当前正在连接的相机
     */
    public MVCameraDevice connectingCamera() {
        return connectingCamera;
    }

    @Override
    public boolean connectingCameraOnUDiskMode() {
        return Util.isNotEmpty(mUsbSerialNumber);
    }

    @Override
    public String connectingCameraOnUDiskSerialNumber() {
        return mUsbSerialNumber;
    }

    @Override
    public void setConnectingCameraOnUDiskSerialNumber(String serialNumber) {
        if (Util.isNotEmpty(mUsbSerialNumber) && Util.isEmpty(serialNumber)) {
            MVMediaManager.sharedInstance().cameraDisconnectFromUDiskMode();
        }
        mUsbSerialNumber = serialNumber;
    }

    /**
     * 已保存的全部相机列表
     */
    public List<MVCameraDevice> getAllStoredDevices() {
        List<MVCameraDevice> devices = new Select()
                .from(MVCameraDevice.class)
                .orderBy(MVCameraDevice.DB_KEY_LAST_SYNC_TIME + " DESC")
                .execute();
        ArrayList<MVCameraDevice> result = new ArrayList<>(devices);

        int currentDeviceIndex = -1;
        WiFiConnectManager wifiMgr = WiFiConnectManager.getInstance();
        int cameraClientState = getState();
        for (int i = result.size() - 1; i >= 0; --i) {
            MVCameraDevice device = result.get(i);
            device.connectionState = 0;

            if (wifiMgr.isWiFiOpened() && wifiMgr.isEqualsWithCurrentWiFi(device.getSSID())) {
                currentDeviceIndex = i;
                device.connectionState |= MVCameraDevice.STATE_WIFI_CONNECTED;
                if (connectingCamera != null && TextUtils.equals(connectingCamera.uuid, device.uuid)) {
                    device.connectionState |= MVCameraDevice.STATE_SESSION_CONNECTED;
                } else if (cameraClientState == CameraClientStateConnecting) {
                    device.connectionState |= MVCameraDevice.STATE_SESSION_CONNECTING;
                }
            }
        }

        if (currentDeviceIndex >= 0) {
            MVCameraDevice currentDevice = result.get(currentDeviceIndex);
            result.set(currentDeviceIndex, result.get(0));
            result.set(0, currentDevice);
        }
        return result;
    }

    @Override
    public int getConnectingCameraPreviewMode() {
        if (null == connectingCamera) {
            return MadvGLRenderer.PanoramaDisplayModeStereoGraphic;
        } else {
            return connectingCamera.getCameraPreviewMode();
        }
    }

    /**
     * 从存储的相机列表中移除
     */
    public void removeStoredDevice(MVCameraDevice device) {
        if (device == null) {
            return;
        }

        if (connectingCamera != null && connectingCamera.equals(device)) {
            disconnectCamera();
        }
        device.delete();
    }

    /// 实例方法：

    /**
     * 设置相机SSID与密码
     */
    public void setCameraWifi(final String ssid, final String password) {
        AMBARequest.ResponseListener responseListener = new AMBARequest.ResponseListener() {
            @Override
            public void onResponseReceived(AMBAResponse response) {
                if (response.isRvalOK()) {
                    if (null != connectingCamera) {
                        connectingCamera.SSID = ssid;
                        connectingCamera.password = password;
                        connectingCamera.save();
                    }
                    sendMessageToHandler(MSG_WIFI_SET, 0, 0, null);
                } else {
                    sendMessageToHandler(MSG_WIFI_SET, response.getRval(), 0, null);
                }
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {
                sendMessageToHandler(MSG_WIFI_SET, error, 0, null);
            }
        };
        AMBASetWifiRequest request = new AMBASetWifiRequest(responseListener);
        request.setToken(sessionToken);
        request.setMsg_id(AMBACommands.AMBA_MSGID_SET_WIFI_NEW);
        request.ssid = ssid;
        request.passwd = password;
        CMDConnectManager.getInstance().sendRequest(request);
    }

    /**
     * 设置相机拍摄模式
     * mode: 主模式
     * subMode: 子模式
     * param: 子模式下具体设置值，如延时摄像时是倍速数，定时拍照时是倒计时秒数
     */
    public void setCameraMode(final int mode, final int subMode, final int param) {
        if (connectingCamera == null) {
            return;
        }

        if (connectingCamera.getCameraMode() == mode
                && connectingCamera.getCameraSubMode() == subMode
                && connectingCamera.getCameraSubModeParam() == param) {
            sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);
            return;
        }

        int setMainModeParam = -1;
        if (mode != connectingCamera.cameraMode) {
            if (mode == MVCameraDevice.CameraModePhoto) {
                setMainModeParam = AMBACommands.AMBA_PARAM_CAMERA_MODE_PHOTO;
            } else if (mode == MVCameraDevice.CameraModeVideo) {
                setMainModeParam = AMBACommands.AMBA_PARAM_CAMERA_MODE_VIDEO;
                currentFilter = null;
            }
        }
        if (setMainModeParam != -1) {
            AMBARequest.ResponseListener setModeListener = new AMBARequest.ResponseListener() {
                @Override
                public void onResponseReceived(AMBAResponse response) {
                    if (response.isRvalOK()) {
                        setCameraSubMode(mode, subMode, param);
                    } else {
                        sendMessageToHandler(MSG_MODE_CHANGED, response.getRval(), 0, null);
                    }
                }

                @Override
                public void onResponseError(AMBARequest request, int error, String msg) {
                    sendMessageToHandler(MSG_MODE_CHANGED, error, 0, null);
                }
            };
            AMBARequest setModeRequest = new AMBARequest(setModeListener);
            setModeRequest.setMsg_id(AMBACommands.AMBA_MSGID_SET_CAMERA_MODE);
            setModeRequest.setParam(Integer.toString(setMainModeParam));
            setModeRequest.setToken(MVCameraClient.getInstance().getToken());
            CMDConnectManager.getInstance().sendRequest(setModeRequest);
        } else {
            setCameraSubMode(mode, subMode, param);
        }
    }

    private void setCameraSubMode(final int mode, final int subMode, final int param) {
        if (mode != MVCameraDevice.CameraModePhoto
                || subMode != MVCameraDevice.CameraSubmodePhotoFilter) {
            currentFilter = null;
        }

        int msgID = -1;
        switch (mode) {
            case MVCameraDevice.CameraModePhoto:
                switch (subMode) {
                    case MVCameraDevice.CameraSubmodePhotoTiming:
                        msgID = AMBACommands.AMBA_MSGID_SET_PHOTO_TIMING_PARAM;
                        break;
                    case MVCameraDevice.CameraSubmodePhotoFilter:
                        currentFilter = ImageFilterBean.findImageFilterByID(param);
                        break;
                }
                break;
            case MVCameraDevice.CameraModeVideo:
                switch (subMode) {
                    case MVCameraDevice.CAMERA_SUBMODE_VIDEO_SLOW:
                        msgID = AMBACommands.AMBA_MSGID_SET_VIDEO_SLOW_PARAM;
                        break;
                    case MVCameraDevice.CameraSubmodeVideoMicro:
                        msgID = AMBACommands.AMBA_MSGID_SET_VIDEO_MICRO_PARAM;
                        break;
                    case MVCameraDevice.CameraSubmodeVideoFilter:
                        msgID = AMBACommands.AMBA_MSGID_SET_VIDEO_FILTER;
                        break;
                }
                break;
        }

        connectingCamera.cameraMode = mode;
        connectingCamera.cameraSubMode = subMode;
        connectingCamera.cameraSubModeParam = param;
        connectingCamera.save();

        if (msgID != -1) {
            AMBARequest.ResponseListener setSubModeListener = new AMBARequest.ResponseListener() {
                @Override
                public void onResponseReceived(AMBAResponse response) {
                    if (response.isRvalOK()) {
                        sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);
                    } else {
                        sendMessageToHandler(MSG_MODE_CHANGED, response.getRval(), 0, null);
                    }
                }

                @Override
                public void onResponseError(AMBARequest request, int error, String msg) {
                    sendMessageToHandler(MSG_MODE_CHANGED, error, 0, null);
                }
            };
            AMBARequest setSubModeRequest = new AMBARequest(setSubModeListener, null);
            setSubModeRequest.setToken(sessionToken);
            setSubModeRequest.setMsg_id(msgID);
            setSubModeRequest.setParam(Integer.toString(param));
            CMDConnectManager.getInstance().sendRequest(setSubModeRequest);
        } else {
            sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);
        }
    }

    /**
     * 启动摄像或拍照
     */
    public void startShooting() {
        if (null == connectingCamera || isShooting) {
            return;
        }

        int msgID = -1;
        switch (connectingCamera.getCameraMode()) {
            case MVCameraDevice.CameraModePhoto:
                isShooting = true;
                switch (connectingCamera.getCameraSubMode()) {
                    case MVCameraDevice.CameraSubmodePhotoTiming:
                        msgID = AMBACommands.AMBA_MSGID_SHOOT_PHOTO_TIMING;
                        break;
                    default:
                        msgID = AMBACommands.AMBA_MSGID_SHOOT_PHOTO_NORMAL;
                        break;
                }
                AMBARequest.ResponseListener takePhotoListener = new AMBARequest.ResponseListener() {
                    @Override
                    public void onResponseReceived(AMBAResponse response) {
                        if (response.isRvalOK()) {
                            sendMessageToHandler(MSG_BEGIN_SHOOTING, 0, 0, null);
                        } else {
                            isShooting = false;
                            sendMessageToHandler(MSG_BEGIN_SHOOTING_ERROR, response.getRval(), 0, null);
                        }
                    }

                    @Override
                    public void onResponseError(AMBARequest request, int error, String msg) {
                        isShooting = false;
                        sendMessageToHandler(MSG_BEGIN_SHOOTING_ERROR, error, 0, null);
                    }
                };
                AMBARequest takePhotoRequest = new AMBARequest(takePhotoListener, null);
                takePhotoRequest.setToken(sessionToken);
                takePhotoRequest.setMsg_id(msgID);
                CMDConnectManager.getInstance().sendRequest(takePhotoRequest);
                break;
            case MVCameraDevice.CameraModeVideo:
                switch (connectingCamera.getCameraSubMode()) {
                    case MVCameraDevice.CAMERA_SUBMODE_VIDEO_SLOW:
                        msgID = AMBACommands.AMBA_MSGID_START_VIDEO_SLOW;
                        break;
                    case MVCameraDevice.CameraSubmodeVideoMicro:
                        msgID = AMBACommands.AMBA_MSGID_START_VIDEO_MICRO;
                        break;
                    default:
                        msgID = AMBACommands.AMBA_MSGID_START_VIDEO_NORMAL;
                        break;
                }
                AMBARequest.ResponseListener startShootingListener = new AMBARequest.ResponseListener() {
                    @Override
                    public void onResponseReceived(AMBAResponse response) {
                        if (response.isRvalOK()) {
                            isShooting = true;
                            startTimer(0);
                            sendMessageToHandler(MSG_BEGIN_SHOOTING, 0, 0, null);
                        } else {
                            isShooting = false;
                            sendMessageToHandler(MSG_BEGIN_SHOOTING_ERROR, response.getRval(), 0, null);
                        }
                    }

                    @Override
                    public void onResponseError(AMBARequest request, int error, String msg) {
                        isShooting = false;
                        sendMessageToHandler(MSG_BEGIN_SHOOTING_ERROR, error, 0, null);
                    }
                };

                if (!isShooting) {
                    isShooting = true;
                    AMBARequest startShootingRequest = new AMBARequest(startShootingListener, null);
                    startShootingRequest.setToken(sessionToken);
                    startShootingRequest.setMsg_id(msgID);
                    CMDConnectManager.getInstance().sendRequest(startShootingRequest);
                }
                break;
        }
    }

    /**
     * 停止摄像或拍照
     */
    public void stopShooting() {
        if (null == connectingCamera || !isShooting) {
            return;
        }

        switch (connectingCamera.getCameraMode()) {
            case MVCameraDevice.CameraModePhoto:
                isShooting = false;
                break;
            case MVCameraDevice.CameraModeVideo:
                AMBARequest.ResponseListener stopShootingListener = new AMBARequest.ResponseListener() {
                    @Override
                    public void onResponseReceived(AMBAResponse response) {
                        if (response.isRvalOK()) {
                            isShooting = false;
                            stopTimer();
                            sendMessageToHandler(MSG_WAIT_SAVE_VIDEO_DONE, 0, 0, null);
                        } else {
                            sendMessageToHandler(MSG_END_SHOOTING_ERROR, response.getRval(), 0, null);
                        }
                    }

                    @Override
                    public void onResponseError(AMBARequest request, int error, String msg) {
                        sendMessageToHandler(MSG_END_SHOOTING_ERROR, error, 0, null);
                    }
                };

                if (isShooting) {
                    AMBARequest stopShootingRequest = new AMBARequest(stopShootingListener, null);
                    stopShootingRequest.setToken(sessionToken);
                    stopShootingRequest.setMsg_id(AMBACommands.AMBA_MSGID_STOP_VIDEO);
                    CMDConnectManager.getInstance().sendRequest(stopShootingRequest);
                }
                break;
        }
    }

    private void startTimer(int startSeconds) {
        isTiming = true;
        callbackHandler.removeMessages(MSG_TIMER_TICKED);
        sendDelayedMessageToHandler(MSG_TIMER_TICKED, startSeconds, videoTimeOfShootingTime(startSeconds), null, 0);
    }

    private void startTimer(int startSeconds, int delay) {
        isTiming = true;
        callbackHandler.removeMessages(MSG_TIMER_TICKED);
        sendDelayedMessageToHandler(MSG_TIMER_TICKED, startSeconds, videoTimeOfShootingTime(startSeconds), null, delay);
    }

    private void stopTimer() {
        isTiming = false;
        callbackHandler.removeMessages(MSG_TIMER_TICKED);
    }

    private void startCountDown(int timingStart) {
        callbackHandler.removeMessages(MSG_COUNT_DOWN_TICKED);
        sendDelayedMessageToHandler(MSG_COUNT_DOWN_TICKED, timingStart - 1, 0, null, 1000);
    }

    /**
     * 启动录剪，返回值表示是否成功
     */
    public boolean cutClip() {
        return true;
    }

    //当前是否可启动录剪
    public boolean isClippingAvailable() {
        return false;
    }

    /**
     * 参数设置
     */
    @Override
    public void setSettingOption(int optionUID, int paramUID) {
        SettingTreeNode optionNode = MVCameraDevice.findOptionNodeByUID(optionUID);
        if (optionNode == null) {
            return;
        }

        switch (optionNode.viewType) {
            case SettingTreeNode.ViewTypeAction:
                doSettingAction(optionUID);
                break;
            case SettingTreeNode.ViewTypeSingleSelection:
            case SettingTreeNode.ViewTypeSliderSelection:
                final int blkOptionUID = optionUID, blkParamUID = paramUID;
                AMBARequest.ResponseListener settingListener = new AMBARequest.ResponseListener() {
                    @Override
                    public void onResponseReceived(AMBAResponse response) {
                        if (response.isRvalOK()) {
                            SettingTreeNode optionNode = MVCameraDevice.findOptionNodeByUID(blkOptionUID);
                            SettingTreeNode paramNode = optionNode.findSubOptionByUID(blkParamUID);
                            if (null != optionNode && null != paramNode) {
                                optionNode.setSelectedSubOptionByUID(paramNode.uid);
                            }

                            if (blkOptionUID == SettingTreeNode.VideoResolutionSetting
                                    || blkOptionUID == SettingTreeNode.PhotoResolutionSetting) {
                                synchronizeCameraStorageAllState();
                            } else if (blkOptionUID == SettingTreeNode.CameraLoopSetting) {
                                loopRecord = paramNode.msgID;
                            }
                            sendMessageToHandler(MSG_SETTING_CHANGED, blkOptionUID, blkParamUID, null);
                        } else {
                            sendMessageToHandler(MSG_SETTING_CHANGED, blkOptionUID, blkParamUID, null);
                        }
                    }

                    @Override
                    public void onResponseError(AMBARequest request, int error, String msg) {
                        sendMessageToHandler(MSG_SETTING_CHANGED, error, 0, null);
                    }
                };

                if (optionNode.uid == SettingTreeNode.CameraPreviewMode) {
                    optionNode.setSelectedSubOptionByUID(paramUID);
                    int previewMode = optionNode.findSubOptionByUID(paramUID).msgID;
                    if (null != connectingCamera) {
                        connectingCamera.cameraPreviewMode = previewMode;
                        connectingCamera.save();
                    }
                    sendMessageToHandler(MSG_SETTING_CHANGED, optionUID, paramUID, null);
                } else {
                    AMBARequest settingRequest = new AMBARequest(settingListener);
                    settingRequest.setToken(sessionToken);
                    settingRequest.setMsg_id(optionNode.msgID);
                    int paramMsgID = optionNode.findSubOptionByUID(paramUID).msgID;
                    settingRequest.setParam(Integer.toString(paramMsgID));
                    CMDConnectManager.getInstance().sendRequest(settingRequest);
                }
                break;
            case SettingTreeNode.ViewTypeReadOnly:
                break;
        }
    }

    private void doSettingAction(int optionUID) {
        int msgID = -1;
        String param = null;
        switch (optionUID) {
            case SettingTreeNode.FormatSD:
                msgID = AMBACommands.AMBA_MSGID_FORMAT_SD;
                param = "c";
                break;
            case SettingTreeNode.CameraPowerOff:
                msgID = AMBACommands.AMBA_MSGID_CLOSE_CAMERA;
                break;
            case SettingTreeNode.ResetToDefaultSettings:
                msgID = AMBACommands.AMBA_MSGID_RESET_DEFAULT_SETTINGS;
                break;
        }
        if (msgID != -1) {
            AMBARequest.ResponseListener setParamListener = new AMBARequest.ResponseListener() {
                @Override
                public void onResponseReceived(AMBAResponse response) {
                    if (response.getMsg_id() == AMBACommands.AMBA_MSGID_FORMAT_SD) {
                        if (response.isRvalOK()) {
                            response.getRval();
                            //sdcard storage
                            synchronizeCameraStorageAllState();
                            sendMessageToHandler(MSG_RECEIVE_NOTIFICATION, AMBACommands.AMBA_MSGID_FORMAT_SD, 0, null);
                            MVMediaManager.sharedInstance().getCameraMedias(true);
                        } else if (response.getRval() == AMBACommands.AMBA_RVAL_ERROR_NO_SDCARD) {
                            sendMessageToHandler(MSG_RECEIVE_NOTIFICATION, AMBACommands.AMBA_RVAL_ERROR_NO_SDCARD, 0, null);
                        } else if (response.getRval() == AMBACommands.AMBA_RVAL_ERROR_BUSY) {
                            sendMessageToHandler(MSG_RECEIVE_NOTIFICATION, AMBACommands.AMBA_RVAL_ERROR_BUSY, 0, null);
                        }
                    } else if (response.getMsg_id() == AMBACommands.AMBA_MSGID_CLOSE_CAMERA) {
                        disconnectCamera();
                    }
                }

                @Override
                public void onResponseError(AMBARequest request, int error, String msg) {
                }
            };
            AMBARequest request = new AMBARequest(setParamListener);
            request.setMsg_id(msgID);
            request.setToken(sessionToken);
            request.setParam(param);
            CMDConnectManager.getInstance().sendRequest(request);
        }
    }

    public List<ImageFilterBean> getImageFilters() {
        return ImageFilterBean.allImageFilters();
    }

    //当前是否正在摄像
    public boolean isVideoShooting() {
        return isShooting;
    }

    //当前电量百分比
    public int getVoltagePercent() {
        return voltagePercent;
    }

    public boolean isCharging() {
        return isCharging;
    }

    @Override
    public boolean isSDCardMounted() {
        return storageMounted != 0;
    }

    @Override
    public int sdCardFreeSize() {
        return storageFree;
    }

    @Override
    public boolean isLoopRecord() {
        return loopRecord != 0;
    }

    @Override
    public int getStorageState() {
        return storageState;
    }

    @Override
    public int getVideoCapacity() {
        return videoCapacity;
    }

    @Override
    public int getPhotoCapacity() {
        return photoCapacity;
    }

    public void restartCameraWiFi() {
        AMBARequest.ResponseListener responseListener = new AMBARequest.ResponseListener() {
            @Override
            public void onResponseReceived(AMBAResponse response) {
                if (response.isRvalOK()) {
                    sendMessageToHandler(MSG_WIFI_RESTART, 0, 0, null);
                } else {
                    sendMessageToHandler(MSG_WIFI_RESTART, response.getRval(), 0, null);
                }
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {
                sendMessageToHandler(MSG_WIFI_RESTART, error, 0, null);
            }
        };
        AMBARequest request = new AMBARequest(responseListener, null);
        request.setToken(sessionToken);
        request.setMsg_id(AMBACommands.AMBA_MSGID_WIFI_RESTART);
        CMDConnectManager.getInstance().sendRequest(request);
    }

    @Override
    public void onConnectionStateChanged(int newState, int oldState, Object object) {
        int reason = 0;
        if (object instanceof Integer) {
            reason = (Integer) object;
        }

        switch (getState()) {
            case CameraClientStateConnected:
                if (newState == CMDConnectManager.SOCKET_STATE_NOT_READY) {
                    disconnectCamera(reason);
                }
                break;
            case CameraClientStateConnecting:
                if (newState == CMDConnectManager.SOCKET_STATE_READY) {
                    startSessionAndSyncCamera();
                } else if (newState == CMDConnectManager.SOCKET_STATE_NOT_READY) {
                    disconnectCamera(reason);
                }
                break;
            case CameraClientStateDisconnecting:
                if (newState == CMDConnectManager.SOCKET_STATE_NOT_READY) {
                    setState(CameraClientStateNotConnected, object);
                }
                break;
            case CameraClientStateNotConnected:
                break;
            default:
                break;
        }
    }

    @Override
    public void onReceiveCameraResponse(AMBAResponse response) {
        Log.d(Const.CallbackLogTag, "onReceiveCameraResponse : " + response);
        if (null == response || !response.isRvalOK()) {
            return;
        }

        switch (response.getMsg_id()) {
            case AMBACommands.AMBA_MSGID_QUERY_SESSION_HOLDER:
                if (getState() == CameraClientStateConnected) {
                    AMBARequest request = new AMBARequest(null);
                    request.shouldWaitUntilPreviousResponded = false;
                    request.setToken(sessionToken);
                    request.setMsg_id(AMBACommands.AMBA_MSGID_QUERY_SESSION_HOLDER);
                    request.setParam(Integer.toString(sessionToken));
                    CMDConnectManager.getInstance().sendRequest(request);
                }

                break;
            case AMBACommands.AMBA_MSGID_GET_CAMERA_STATE:
                handleCameraWorkState((int) (double) (Double) response.getParam(), true);

                break;
            case AMBACommands.AMBA_MSGID_SET_CAMERA_MODE:
                connectingCamera.cameraMode = (int) (double) (Double) response.getParam();
                if (MVCameraDevice.CameraModeVideo == connectingCamera.cameraMode)
                    connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodeVideoNormal;
                else if (MVCameraDevice.CameraModePhoto == connectingCamera.cameraMode)
                    connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodePhotoNormal;
                sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);

                break;
            case AMBACommands.AMBA_MSGID_IS_SDCARD_MOUNTED:
                //sdcard storage
                synchronizeCameraStorageAllState();

                break;
            case AMBACommands.AMBA_MSGID_IS_SDCARD_FULL:
                //sdcard storage
                synchronizeCameraStorageAllState();

                break;
            case AMBACommands.AMBA_MSGID_SDCARD_SLOWLY_WRITE:
                isShooting = false;
                stopTimer();
                sendMessageToHandler(MSG_SDCARD_SLOWLY_WRITE, 0, 0, null);

                break;
            case AMBACommands.AMBA_MSGID_SAVE_VIDEO_DONE:
            case AMBACommands.AMBA_MSGID_SAVE_PHOTO_DONE:
                AMBASaveMediaFileDoneResponse saveDoneResponse = (AMBASaveMediaFileDoneResponse) response;
                String remoteFilePath = remoteFilePathOfRTOSPath((String) saveDoneResponse.getParam());
                sendMessageToHandler(MSG_END_SHOOTING, 0, 0, remoteFilePath);
                isShooting = false;
                stopTimer();

                MVMedia media = MVMediaManager.sharedInstance().obtainCameraMedia(connectingCamera().getUUID(), remoteFilePath, false);
                if (currentFilter != null && media.getMediaType() == MVMedia.MediaTypePhoto) {
                    media.setFilterID(currentFilter.uuid);
                }
                media.saveCommonFields();

                //sdcard storage
                int preStorageState = storageState;
                storageState = saveDoneResponse.getSd_full();
                storageTotal = saveDoneResponse.getSd_total();
                storageFree = saveDoneResponse.getSd_free();
                photoCapacity = saveDoneResponse.getRemain_jpg();
                videoCapacity = saveDoneResponse.getRemain_video();
                sendMessageToHandler(MSG_STORAGE_STATE_CHANGED, preStorageState, storageState, null);
                SettingTreeNode optionNode = MVCameraDevice.findOptionNodeByUID(SettingTreeNode.FormatSD);
                if (null != optionNode && optionNode.subOptions.size() > 0) {
                    SettingTreeNode subOptionNode = optionNode.findSubOptionByUID(0);
                    subOptionNode.name = StringUtil.formatSDStorage(storageTotal, storageFree);
                }
                sendMessageToHandler(MSG_STORAGE_TOTAL_FREE_CHANGED, storageTotal, storageFree, null);
                break;
            case AMBACommands.AMBA_MSGID_MP4_FILE_SPLIT_DONE:
                String splitFilePath = (String) response.getParam();
                if (Util.isNotEmpty(splitFilePath)) {
                    String remoteSplitFilePath = remoteFilePathOfRTOSPath(splitFilePath);
                    MVMediaManager.sharedInstance().obtainCameraMedia(connectingCamera().getUUID(), remoteSplitFilePath, false);
                }
                break;
            case AMBACommands.AMBA_MSGID_GET_BATTERY_VOLUME:
                int voltage = (int) (double) (Double) response.getParam();
                handleBatteryResponse(voltage);

                break;
            case AMBACommands.AMBA_MSGID_START_VIDEO_NORMAL:
                workState = CameraWorkStateCapturing;
                connectingCamera.cameraMode = MVCameraDevice.CameraModeVideo;
                connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodeVideoNormal;
                connectingCamera.cameraSubModeParam = 0;
                connectingCamera.save();
                sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);

                isShooting = true;
                sendMessageToHandler(MSG_BEGIN_SHOOTING, 0, 0, null);
                startTimer(0);

                break;
            case AMBACommands.AMBA_MSGID_START_VIDEO_MICRO:
                workState = CameraWorkStateCapturingMicro;
                connectingCamera.cameraMode = MVCameraDevice.CameraModeVideo;
                connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodeVideoMicro;
                connectingCamera.cameraSubModeParam = (int) (double) (Double) response.getParam();
                connectingCamera.save();
                sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);

                isShooting = true;
                sendMessageToHandler(MSG_BEGIN_SHOOTING, 0, 0, null);
                startTimer(0);

                break;
            case AMBACommands.AMBA_MSGID_START_VIDEO_SLOW:
                workState = CameraWorkStateCapturingSlow;
                connectingCamera.cameraMode = MVCameraDevice.CameraModeVideo;
                connectingCamera.cameraSubMode = MVCameraDevice.CAMERA_SUBMODE_VIDEO_SLOW;
                connectingCamera.cameraSubModeParam = (int) (double) (Double) response.getParam();
                connectingCamera.save();
                sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);

                isShooting = true;
                sendMessageToHandler(MSG_BEGIN_SHOOTING, 0, 0, null);
                startTimer(0);

                break;
            case AMBACommands.AMBA_MSGID_STOP_VIDEO:
                isShooting = false;
                stopTimer();
                sendMessageToHandler(MSG_WAIT_SAVE_VIDEO_DONE, 0, 0, null);

                break;
            case AMBACommands.AMBA_MSGID_SHOOT_PHOTO_TIMING:
                workState = CameraWorkStatePhotoingDelayed;
                connectingCamera.cameraMode = MVCameraDevice.CameraModePhoto;
                connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodePhotoTiming;
                connectingCamera.cameraSubModeParam = (int) (double) (Double) response.getParam();
                connectingCamera.save();
                sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);

                isShooting = true;
                sendMessageToHandler(MSG_BEGIN_SHOOTING, 0, 0, null);

                break;
            case AMBACommands.AMBA_MSGID_SHOOT_PHOTO_NORMAL:
                workState = CameraWorkStatePhotoing;
                if (MVCameraDevice.CameraModePhoto == connectingCamera.cameraMode
                        && MVCameraDevice.CameraSubmodePhotoFilter == connectingCamera.cameraSubMode) {
                    isShooting = true;
                    sendMessageToHandler(MSG_BEGIN_SHOOTING, 0, 0, null);
                } else {
                    connectingCamera.cameraMode = MVCameraDevice.CameraModePhoto;
                    connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodePhotoNormal;
                    connectingCamera.cameraSubModeParam = 0;
                    connectingCamera.save();
                    sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);

                    isShooting = true;
                    sendMessageToHandler(MSG_BEGIN_SHOOTING, 0, 0, null);
                }

                break;
            case AMBACommands.AMBA_MSGID_CLOSE_CAMERA:
                disconnectCamera();
                break;
            case AMBACommands.AMBA_MSGID_CAMERA_OVERHEATED:
                sendMessageToHandler(MSG_RECEIVE_NOTIFICATION, AMBACommands.AMBA_MSGID_CAMERA_OVERHEATED, 0, null);
                break;
            case AMBACommands.AMBA_MSGID_RECOVERY_MEDIA_FILE:
                sendMessageToHandler(MSG_RECEIVE_NOTIFICATION, AMBACommands.AMBA_MSGID_RECOVERY_MEDIA_FILE, 0, null);
                break;
            case AMBACommands.AMBA_MSGID_START_LOOP_FAIL:
                sendMessageToHandler(MSG_RECEIVE_NOTIFICATION, AMBACommands.AMBA_MSGID_START_LOOP_FAIL, 0, null);
                break;
        }
    }

    @Override
    public void onHeartbeatRequired() {
        if (DLManager.getInstance().isBusy()) {
            AMBARequest request = new AMBARequest(null);
            request.shouldWaitUntilPreviousResponded = false;
            request.setToken(sessionToken);
            request.setMsg_id(AMBACommands.AMBA_MSGID_WAKEUP_CAMERA);
            request.setParam(Integer.toString(sessionToken));
            CMDConnectManager.getInstance().sendRequest(request);
        }
    }

    @Override
    public void onDataConnectionStateChanged(int newState, int oldState, Object object) {
        Log.d(TAG, "onDataConnectionStateChanged: new = " + DATAConnectManager.StringFromState(newState) + ", old = " + DATAConnectManager.StringFromState(oldState));
        switch (getState()) {
            case CameraClientStateConnected:
                if (newState == DATAConnectManager.SOCKET_STATE_NOT_READY
                        && (oldState == DATAConnectManager.SOCKET_STATE_READY
                        || oldState == DATAConnectManager.SOCKET_STATE_DISCONNECTING)) {
                    disconnectCamera();
                }
                break;
            case CameraClientStateDisconnecting:
                break;
            case CameraClientStateNotConnected:
                break;
            default:
                break;
        }
    }

    @Override
    public void onReceiverEmptied() {

    }

    @Override
    public void onSpeedLogUpdated(String log) {

    }

    public int getState() {
        return state;
    }

    @Override
    public int getWorkState() {
        return workState;
    }

    private void setState(int newState) {
        setState(newState, null);
    }

    private void setState(int newState, Object object) {
        synchronized (this) {
            int oldState = state;
            state = newState;
            if (state == CameraClientStateNotConnected) {
                resetStates();
                connectingCamera = null;
                sessionToken = AMBACommands.AMBA_SESSION_TOKEN_INIT;
            }

            notifyAll();
            notifyStateChanged(newState, oldState, object);
        }
    }

    private void resetStates() {
        workState = CameraWorkStateIdle;
        connectingCamera = null;
        currentFilter = null;
        mUsbSerialNumber = null;

        stopTimer();
        isShooting = false;//Is camera busy capturing?
        storageMounted = 1;
        storageState = StorageStateAvailable;
        storageTotal = -1;
        storageFree = -1;
        videoCapacity = -1;
        photoCapacity = -1;
        loopRecord = 0;

        voltagePercent = 100;
        isCharging = false;
    }

    public int waitForState(int stateCombo) {
        // Exit when: (state == 0 && stateCombo == 0) || ((state & stateCombo) != 0)
        synchronized (this) {
            while ((state != 0 || stateCombo != 0) && ((state & stateCombo) == 0)) {
                try {
                    wait();
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
        }
        return state;
    }


    private void notifyStateChanged(int newState, int oldState, Object object) {
        sendMessageToHandler(MSG_STATE_CHANGED, newState, oldState, object);
    }

    private void sendMessageToHandler(int what, int arg1, int arg2, Object object) {
        Message msg = callbackHandler.obtainMessage(what, arg1, arg2, object);
        callbackHandler.sendMessage(msg);
    }

    private void sendDelayedMessageToHandler(int what, int arg1, int arg2, Object object, long delayMills) {
        Message msg = callbackHandler.obtainMessage(what, arg1, arg2, object);
        callbackHandler.sendMessageDelayed(msg, delayMills);
    }

    private final Handler callbackHandler = new Handler(Looper.getMainLooper()) {
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case MSG_STATE_CHANGED:
                    onStateChanged(msg.arg1, msg.arg2, msg.obj);
                    break;
                case MSG_WIFI_SET:
                    onWiFiSet(msg.arg1, (String) msg.obj);
                    break;
                case MSG_WIFI_RESTART:
                    onWiFiRestart(msg.arg1, (String) msg.obj);
                    break;
                case MSG_MODE_CHANGED:
                    onCameraModeChanged(msg.arg1, (String) msg.obj);
                    break;
                case MSG_BEGIN_SHOOTING:
                    onShootingBegan();
                    break;
                case MSG_BEGIN_SHOOTING_ERROR:
                    onShootingBeginError(msg.arg1);
                    break;
                case MSG_END_SHOOTING_ERROR:
                    onShootingEndError(msg.arg1);
                    break;
                case MSG_END_SHOOTING:
                    if (msg.arg1 == 0) {
                        onShootingEnded((String) msg.obj, 0, null);
                    } else {
                        onShootingEnded(null, msg.arg1, (String) msg.obj);
                    }
                    break;
                case MSG_TIMER_TICKED:
                    onShootingTimerTicked(msg.arg1, msg.arg2);
                    break;
                case MSG_ALL_SETTING_RECEIVED:
                    onAllSettingReceived(msg.arg1);
                    break;
                case MSG_SETTING_CHANGED:
                    onSettingChanged(msg.arg1, msg.arg2, (String) msg.obj);
                    break;
                case MSG_VOLTAGE_CHANGED:
                    onVoltageChanged(msg.arg1, 0 != msg.arg2);
                    break;
                case MSG_WORK_STATE_CHANGED:
                    onWorkStateChanged(msg.arg1);
                    break;
                case MSG_STORAGE_MOUNTED_STATE_CHANGED:
                    onStorageMountedStateChanged(msg.arg1);
                    break;
                case MSG_STORAGE_STATE_CHANGED:
                    onStorageStateChanged(msg.arg1, msg.arg2);
                    break;
                case MSG_RECEIVE_NOTIFICATION:
                    onReceiveNotification(msg.arg1);
                    break;
                case MSG_STORAGE_TOTAL_FREE_CHANGED:
                    onStorageTotalFreeChanged(msg.arg1, msg.arg2);
                    break;
                case MSG_COUNT_DOWN_TICKED:
                    onCountDownTicked(msg.arg1);
                    break;
                case MSG_SDCARD_SLOWLY_WRITE:
                    onSDCardSlowlyWrite();
                    break;
                case MSG_WAIT_SAVE_VIDEO_DONE:
                    onWaitSaveVideoDone();
                default:
                    break;
            }
        }
    };

    private void onCountDownTicked(int timingStart) {
        if (null == connectingCamera) {
            return;
        }

        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) {
                continue;
            }
            listener.didCountDownTimerTick(timingStart);
        }

        if (timingStart > 1) {
            sendDelayedMessageToHandler(MSG_COUNT_DOWN_TICKED, timingStart - 1, 0, null, 1000);
        }
    }

    private void onSDCardSlowlyWrite() {
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didSDCardSlowlyWrite();
        }
    }

    private void onWaitSaveVideoDone() {
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didWaitSaveVideoDone();
        }
    }

    private void onShootingTimerTicked(int shootingTime, int videoTime) {
        if (null == connectingCamera || !isTiming) {
            return;
        }

        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) {
                continue;
            }
            listener.didShootingTimerTick(shootingTime, videoTime);
        }

        shootingTime++;
        if (MVCameraDevice.CameraSubmodeVideoMicro == connectingCamera.cameraSubMode) {
            if (shootingTime > connectingCamera.cameraSubModeParam) {
                shootingTime = connectingCamera.cameraSubModeParam;
            }
        }
        sendDelayedMessageToHandler(MSG_TIMER_TICKED, shootingTime, videoTimeOfShootingTime(shootingTime), null, 1000L);
    }

    private void onShootingBegan() {
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didBeginShooting();
        }
    }

    private void onShootingBeginError(int error) {
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didBeginShootingError(error);
        }
    }

    private void onShootingEndError(int error) {
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didEndShootingError(error);
        }
    }

    private void onShootingEnded(String remoteFilePath, int error, String errMsg) {
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didEndShooting(remoteFilePath, error, errMsg);
        }
    }

    private void onCameraModeChanged(int error, String errMsg) {
        if (null == connectingCamera) {
            return;
        }

        MVCameraDevice camera = connectingCamera;
        if (error != 0 || errMsg != null) {
            for (WeakReference<StateListener> ref : stateListeners) {
                StateListener listener = ref.get();
                if (null == listener) continue;

                listener.didSwitchCameraModeFail(errMsg);
            }
        } else {
            if (null == camera) {
                camera = new MVCameraDevice();
            }

            for (WeakReference<StateListener> ref : stateListeners) {
                StateListener listener = ref.get();
                if (null == listener) continue;

                listener.didCameraModeChange(camera.cameraMode, camera.cameraSubMode, camera.cameraSubModeParam);
            }
        }
    }

    private void onWiFiSet(int error, String errMsg) {
        boolean success = (error == 0);
        errMsg = (success ? null : errMsg);
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didSetWifi(success, errMsg);
        }
    }

    private void onWiFiRestart(int error, String errMsg) {
        boolean success = (error == 0);
        errMsg = (success ? null : errMsg);
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didRestartWifi(success, errMsg);
        }
    }

    private void onAllSettingReceived(int errorCode) {
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didReceiveAllSettingItems(errorCode);
        }
    }

    private void onSettingChanged(int option, int param, String errMsg) {
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didSettingItemChanged(option, param, errMsg);
        }
    }

    private void onVoltageChanged(int percent, boolean isCharging) {
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didVoltagePercentChanged(percent, isCharging);
        }
    }

    private void onWorkStateChanged(int workState) {
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didWorkStateChange(workState);
        }
    }

    private void onStorageMountedStateChanged(int mountedState) {
        if (CameraClientStateConnected == state) {
            MVMediaManager.sharedInstance().getCameraMedias(true);
        }

        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didStorageMountedStateChanged(mountedState);
        }
    }

    private void onStorageStateChanged(int oldState, int newState) {
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didStorageStateChanged(oldState, newState);
        }
    }

    private void onStorageTotalFreeChanged(int total, int free) {
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didStorageTotalFreeChanged(total, free);
        }
    }

    private void onReceiveNotification(int notification) {
        String notificationString = NotificationStringOfNotification(notification);
        for (WeakReference<StateListener> ref : stateListeners) {
            StateListener listener = ref.get();
            if (null == listener) continue;

            listener.didReceiveCameraNotification(notificationString);
        }
    }

    private void onStateChanged(int newState, int oldState, Object object) {
        if (newState == CameraClientStateNotConnected) {
            if (oldState == CameraClientStateConnecting) {
                for (WeakReference<StateListener> ref : stateListeners) {
                    StateListener listener = ref.get();
                    if (null == listener) continue;

                    listener.didConnectFail(null == object ? "" : object.toString());
                }
            } else if (oldState == CameraClientStateDisconnecting
                    || oldState == CameraClientStateConnected) {
                int reason = 0;
                if (object instanceof Integer) {
                    reason = (Integer) object;
                }

                for (WeakReference<StateListener> ref : stateListeners) {
                    StateListener listener = ref.get();
                    if (null == listener) continue;

                    listener.didDisconnect(reason);
                }
            }
        } else if (newState == CameraClientStateConnected) {
            for (WeakReference<StateListener> ref : stateListeners) {
                StateListener listener = ref.get();
                if (null == listener) continue;

                listener.didConnectSuccess((MVCameraDevice) object);
            }
        }
    }

    private void handleCameraWorkState(int cameraWorkState, final boolean notifyChange) {
        workState = cameraWorkState;
        if (notifyChange) {
            sendMessageToHandler(MSG_WORK_STATE_CHANGED, workState, 0, null);
        }

        switch (workState) {
            case AMBACommands.AMBA_PARAM_CAMERA_STATE_STORAGE:
                disconnectCamera(CameraExceptionInStorageMode);
                break;
            case AMBACommands.AMBA_PARAM_CAMERA_STATE_STANDBY:
                break;
            case AMBACommands.AMBA_PARAM_CAMERA_STATE_IDLE:
                isShooting = false;
                stopTimer();
                // Get Camera Mode:
                AMBARequest.ResponseListener getModeListener = new AMBARequest.ResponseListener() {
                    @Override
                    public void onResponseReceived(AMBAResponse response) {
                        if (response.isRvalOK()) {
                            connectingCamera.cameraMode = (int) (double) (Double) response.getParam();
                            if (connectingCamera.cameraMode == MVCameraDevice.CameraModeVideo) {
                                connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodeVideoNormal;
                            } else if (connectingCamera.cameraMode == MVCameraDevice.CameraModePhoto) {
                                connectingCamera.cameraSubMode = MVCameraDevice.CameraSubmodePhotoNormal;
                            }
                            connectingCamera.cameraSubModeParam = 0;
                            connectingCamera.save();

                            if (notifyChange) {
                                sendMessageToHandler(MSG_MODE_CHANGED, 0, 0, null);
                                sendMessageToHandler(MSG_END_SHOOTING, 0, 0, null);
                            }
                        }
                    }

                    @Override
                    public void onResponseError(AMBARequest request, int error, String msg) {

                    }
                };
                AMBARequest getModeRequest = new AMBARequest(getModeListener);
                getModeRequest.setMsg_id(AMBACommands.AMBA_MSGID_SET_CAMERA_MODE);
                getModeRequest.setToken(sessionToken);
                CMDConnectManager.getInstance().sendRequest(getModeRequest);
                break;
        }
    }

    private void handleBatteryResponse(int voltage) {
        if (voltage == AMBACommands.AMBA_PARAM_BATTERY_CHARGE_FULL) {
            isCharging = false;
        } else {
            isCharging = (0 != (voltage & 0x80));
        }

        switch (voltage & 0x0F) {
            case AMBACommands.AMBA_PARAM_BATTERY_PERCENT5:
                voltagePercent = 5;
                break;
            case AMBACommands.AMBA_PARAM_BATTERY_PERCENT25:
                voltagePercent = 25;
                break;
            case AMBACommands.AMBA_PARAM_BATTERY_PERCENT50:
                voltagePercent = 50;
                break;
            case AMBACommands.AMBA_PARAM_BATTERY_PERCENT75:
                voltagePercent = 75;
                break;
            case AMBACommands.AMBA_PARAM_BATTERY_PERCENT100:
                voltagePercent = 100;
                break;
        }
        sendMessageToHandler(MSG_VOLTAGE_CHANGED, voltagePercent, (isCharging ? 1 : 0), null);
    }

    private void checkAndSynchronizeLUT(final String cameraUUID, final String md5) {
        MVCameraDownloadManager.FileDownloadCallback downloadCallback = new MVCameraDownloadManager.FileDownloadCallback() {
            @Override
            public void onGotFileSize(long remSize, long totalSize) {
                super.onGotFileSize(remSize, totalSize);
            }

            @Override
            public void onCompleted(long bytesReceived) {
                super.onCompleted(bytesReceived);
            }

            @Override
            public void onAllCompleted() {
                super.onAllCompleted();

                String uuidDirStr = cameraUUID.replace(':', '_');
                String lutDirStr = AppStorageManager.getLutDirEndWithSeparator() + uuidDirStr;
                String lutFileNameStr = uuidDirStr + "_lut.bin";
                File lutBinFilePath = new File(lutDirStr, lutFileNameStr);
                if (lutBinFilePath.exists()) {
                    FileUtil.extractLUTFiles(lutDirStr, lutBinFilePath.getAbsolutePath(), 0);
                }
                setState(CameraClientStateConnected, connectingCamera);
            }

            @Override
            public void onError(int errorCode) {
                super.onError(errorCode);
                setState(CameraClientStateConnected, connectingCamera);
            }

            @Override
            public void onProgressUpdated(long totalBytes, long downloadedBytes) {
                super.onProgressUpdated(totalBytes, downloadedBytes);
            }
        };

        try {
            String uuidDirStr = cameraUUID.replace(':', '_');
            String lutDirStr = AppStorageManager.getLutDirEndWithSeparator() + uuidDirStr;
            String lutFileNameStr = uuidDirStr + "_lut.bin";
            File lutFilePath = new File(lutDirStr, lutFileNameStr);
            if (lutFilePath.exists()) {
                String localLutMd5 = MD5Util.getMD5ForFile(lutFilePath.getAbsolutePath());
                if (Util.isAllNotEmpty(localLutMd5, md5) && localLutMd5.equals(md5)) {
                    setState(CameraClientStateConnected, connectingCamera);
                    return;
                }
            }

            File lutDirPath = new File(lutDirStr);
            if (!lutDirPath.exists()) {
                lutDirPath.mkdirs();
            }

            MVCameraDownloadManager.DownloadChunkInfo downloadChunk = new MVCameraDownloadManager.DownloadChunkInfo(cameraUUID, "/tmp/FL0/lut/app_lut.bin", lutFilePath.getAbsolutePath(), 0, 0);
            MVCameraDownloadManager.getInstance().addContinuousFileDownloading(downloadChunk, MVCameraDownloadManager.TASK_PRIORITY_EMERGENCY, downloadCallback);
        } catch (Exception ex) {
            Log.d(TAG, ex.getMessage());
            setState(CameraClientStateConnected, connectingCamera);
        }
    }

    private String remoterFWLocalPath = AppStorageManager.getDownloadDir() + "/" + UserAppConst.CACHE_DOWNLOAD_BIN + "/";
    private String remoterFWRemotePath = UserAppConst.REMOTER_UPDATE_PATH;

    @Override
    public void checkAndUpdateRemoter() {
        BackgroundExecutor.execute(new BackgroundExecutor.Task("checkUpdate", 2000L, "checkUpdate") {
            @Override
            public void execute() {
                Context context = ElephantApp.getInstance().getApplicationContext();
                MVCameraDevice connectingCamera = MVCameraClient.getInstance().connectingCamera();
                if (null != connectingCamera) {
                    String cameraRemoterVersion = connectingCamera.getRemoterVersion();
                    SystemInfo.setRemoterVersionName(context, cameraRemoterVersion);
                    String localRemoterVersion = SystemInfo.getLocalRWVersionName(context);
                    String localRemoterFileName = SystemInfo.getLocalRWFileName(context);
                    boolean needUpdate = false;
                    if (Util.isAllNotEmpty(localRemoterVersion, localRemoterFileName)) {
                        if (Util.isNotEmpty(cameraRemoterVersion)) {
                            int ret = localRemoterVersion.compareToIgnoreCase(cameraRemoterVersion);
                            if (ret > 0) {
                                needUpdate = true;
                            }
                        } else {
                            needUpdate = true;
                        }
                    }

                    if (needUpdate
                            && !MVCameraClient.getInstance().isVideoShooting()
                            && MVCameraClient.getInstance().isSDCardMounted()) {
                        String localFilePath = remoterFWLocalPath + localRemoterFileName;
                        MVCameraUploadManager.UpdateRemoterTask updateRemoterTask = new MVCameraUploadManager.UpdateRemoterTask(localFilePath, remoterFWRemotePath, null);
                        MVCameraUploadManager.getInstance().updateRemoterVersion(updateRemoterTask);
                    }
                }
            }
        });
    }

    private int videoTimeOfShootingTime(int shootingTime) {
        if (null == connectingCamera) {
            return shootingTime;
        }

        if (connectingCamera.cameraMode == MVCameraDevice.CameraModeVideo
                && connectingCamera.cameraSubMode == MVCameraDevice.CAMERA_SUBMODE_VIDEO_SLOW) {
            SettingTreeNode paramsNode = MVCameraDevice.getCameraModeParameters(connectingCamera.cameraMode, connectingCamera.cameraSubMode);
            SettingTreeNode paramNode = paramsNode.findSubOptionByMsgID(connectingCamera.cameraSubModeParam);
            float interval = Float.valueOf(paramNode.name.substring(0, paramNode.name.length() - 1));
            SettingTreeNode resolutionSettingNode = MVCameraDevice.findOptionNodeByUID(SettingTreeNode.VideoResolutionSetting);
            int resolutionSelectedUID = resolutionSettingNode.getSelectedSubOptionUID();
            if (resolutionSelectedUID == SettingTreeNode.VideoResolution60fpsUID) {
                return (connectingCamera.cameraSubModeParam == 0 ? 0 : (int) ((float) shootingTime / interval / 60.f));
            } else {
                return (connectingCamera.cameraSubModeParam == 0 ? 0 : (int) ((float) shootingTime / interval / 30.f));
            }
        }

        return shootingTime;
    }
}

