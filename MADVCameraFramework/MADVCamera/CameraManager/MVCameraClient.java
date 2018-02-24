package com.madv360.madv.connection;

/**
 * Created by qiudong on 16/6/8.
 * 相机代理类，封装了与控制相机直接相关的方法和属性
 */

import com.madv360.madv.model.MVCameraDevice;
import com.madv360.madv.model.bean.ImageFilterBean;
import com.madv360.madv.model.bean.SettingTreeNode;

import java.util.List;

import bootstrap.appContainer.EnviromentConfig;

public abstract class MVCameraClient {
    //常量及枚举值定义：
    public static final int CameraClientStateNotConnected = 1;
    public static final int CameraClientStateConnecting = 2;
    public static final int CameraClientStateConnected = 4;
    public static final int CameraClientStateDisconnecting = 8;

    public static final int CameraWorkStateIdle = AMBACommands.AMBA_PARAM_CAMERA_STATE_IDLE;//空闲
    public static final int CameraWorkStateStandby = AMBACommands.AMBA_PARAM_CAMERA_STATE_STANDBY;//待机
    public static final int CameraWorkStateStorage = AMBACommands.AMBA_PARAM_CAMERA_STATE_STORAGE;//U盘模式
    public static final int CameraWorkStateCapturing = AMBACommands.AMBA_PARAM_CAMERA_STATE_CAPTURING;//正在摄像
    public static final int CameraWorkStateCapturingMicro = AMBACommands.AMBA_PARAM_CAMERA_STATE_CAPTURING_MICRO;//正在秒拍
    public static final int CameraWorkStateCapturingSlow = AMBACommands.AMBA_PARAM_CAMERA_STATE_CAPTURING_SLOW;//正在延时摄像
    public static final int CameraWorkStatePhotoing = AMBACommands.AMBA_PARAM_CAMERA_STATE_PHOTOING;//正在拍照
    public static final int CameraWorkStatePhotoingDelayed = AMBACommands.AMBA_PARAM_CAMERA_STATE_PHOTOING_DELAYED;//正在定时拍照

    public static final int StorageStateAvailable = AMBACommands.AMBA_PARAM_SDCARD_FULL_NO;
    public static final int StorageStateAboutFull = AMBACommands.AMBA_PARAM_SDCARD_FULL_ALMOST;
    public static final int StorageStateFull = AMBACommands.AMBA_PARAM_SDCARD_FULL_YES;
    public static final int StorageStateUnknown = AMBACommands.AMBA_PARAM_SDCARD_FULL_UNKNOWN;

    public static final int CameraExceptionUnknown = 0;
    public static final int CameraExceptionOtherClient = 1;
    public static final int CameraExceptionInStorageMode = 2;
    public static final int CameraExceptionStandBy = 3;
    public static final int CameraExceptionSwitchConnect = 4;

    public static final String StringFromCameraWorkState(int cameraWorkState) {
        switch (cameraWorkState) {
            case CameraWorkStateCapturing:
                return "CameraWorkStateCapturing";
            case CameraWorkStateCapturingMicro:
                return "CameraWorkStateCapturingMicro";
            case CameraWorkStateCapturingSlow:
                return "CameraWorkStateCapturingSlow";
            case CameraWorkStateIdle:
                return "CameraWorkStateIdle";
            case CameraWorkStatePhotoing:
                return "CameraWorkStatePhotoing";
            case CameraWorkStatePhotoingDelayed:
                return "CameraWorkStatePhotoingDelayed";
            case CameraWorkStateStandby:
                return "CameraWorkStateStandby";
            case CameraWorkStateStorage:
                return "CameraWorkStateStorage";
            default:
                return "N/A";
        }
    }

    public static final String NotificationFormatWithoutSD = "No SDCard";
    public static final String NotificationFormatWhileWorking = "Format while camera is busy";
    public static final String NotificationInvalidOperation = "Invalid operation";
    public static final String NotificationInvalidToken = "Invalid token";
    public static final String NotificationLowBattery = "Low battery";
    public static final String NotificationNoFirmware = "No firmware";
    public static final String NotificationNoSDCard = "No SD card";
    public static final String NotificationSDCardFull = "SD card full";
    public static final String NotificationWrongMode = "Wrong mode";
    public static final String NotificationFormatSDSuccess = "Format SDCard success";
    public static final String NotificationCameraOverheated = "camera overheated";
    public static final String NotificationRecoveryMediaFile = "recovery media file";
    public static final String NotificationStartLoopFail = "start loop fail";

    public static final String NotificationStringOfNotification(int notification) {
        switch (notification) {
            case AMBACommands.AMBA_RVAL_ERROR_BUSY:
                return NotificationFormatWhileWorking;
            case AMBACommands.AMBA_RVAL_ERROR_INVALID_OPERATION:
                return NotificationInvalidOperation;
            case AMBACommands.AMBA_RVAL_ERROR_INVALID_TOKEN:
                return NotificationInvalidToken;
            case AMBACommands.AMBA_RVAL_ERROR_LOW_BATTERY:
                return NotificationLowBattery;
            case AMBACommands.AMBA_RVAL_ERROR_NO_FIRMWARE:
                return NotificationNoFirmware;
            case AMBACommands.AMBA_RVAL_ERROR_NO_SDCARD:
                return NotificationNoSDCard;
            case AMBACommands.AMBA_RVAL_ERROR_SDCARD_FULL:
                return NotificationSDCardFull;
            case AMBACommands.AMBA_RVAL_ERROR_WRONG_MODE:
                return NotificationWrongMode;
            case AMBACommands.AMBA_MSGID_FORMAT_SD:
                return NotificationFormatSDSuccess;
            case AMBACommands.AMBA_MSGID_CAMERA_OVERHEATED:
                return NotificationCameraOverheated;
            case AMBACommands.AMBA_MSGID_RECOVERY_MEDIA_FILE:
                return NotificationRecoveryMediaFile;
            case AMBACommands.AMBA_MSGID_START_LOOP_FAIL:
                return NotificationStartLoopFail;
            default:
                return "Error";
        }
    }

    /** 相机状态回调接口 */
    public interface StateListener {
        /** 连接相机成功
         * device: 连接到的相机设备，其中包含了其SSID和密码信息，用于判断是否要强制用户设置WiFi密码
         */
        void didConnectSuccess(MVCameraDevice device);

        /** 连接相机失败
         *  errorMessage: 错误提示信息
         */
        void didConnectFail(String errorMessage);

        /** 设置相机WiFi结果 */
        void didSetWifi(boolean success, String errMsg);

        /** 重启相机WiFi结果 */
        void didRestartWifi(boolean success, String errMsg);

        /** 断开相机连接
         * @param cameraException : 表示断开连接原因的枚举值
         * */
        void didDisconnect(int cameraException);

        /** 相机电量发生变化 */
        void didVoltagePercentChanged(int percent, boolean isCharging);

        /** 相机拍摄模式发生变化
         * mode: 主模式
         * subMode: 子模式
         * param: 子模式下具体设置值，如延时摄像时是倍速数，定时拍照时是倒计时秒数
         */
        void didCameraModeChange(int mode, int subMode, int param);

        /** 相机模式切换失败
         *
         * @param errMsg
         */
        void didSwitchCameraModeFail(String errMsg);

        /** 摄像已启动 */
        void didBeginShooting();

        void didBeginShootingError(int error);

        /** 摄像时长计时器回调
         * shootTime: 摄像开始到当前时刻的秒数
         * videoTime: 实际拍摄出的视频的当前时长（只在延时摄像时有意义）
         */
        void didShootingTimerTick(int shootTime, int videoTime);

        void didCountDownTimerTick(int timingStart);

        /** 摄像（或定时拍照）已停止 */
        void didEndShooting(String remoteFilePath, int error, String errMsg);

        void didEndShootingError(int error);

        void didSDCardSlowlyWrite();

        void didWaitSaveVideoDone();

        /** 录剪已启动 */
        void didClippingBegin();

        /** 录剪片段计时器回调，secondsLeft为当前录剪片段还剩余的时长（秒） */
        void didClippingTimerTick(int secondsLeft);

        /** 录剪已结束，totalClips为当前摄像过程总共录剪的片段数 */
        void didClippingEnd(int totalClips);

        void didReceiveAllSettingItems(int errorCode);

        /** 相机设置发生变化
         * optionUID: 设置项ID
         * paramUID: 设置项下子项的ID
         * errMsg: 发生错误时错误信息
         */
        void didSettingItemChanged(int optionUID, int paramUID, String errMsg);

        /**
         * 相机工作状态发生变化
         * @param workState 工作状态枚举值，有：
         *                  CameraWorkStateIdle：正常空闲
         *                  CameraWorkStateStandby: 待机
         *                  CameraWorkStateStorage: USB存储器模式
         *                  CameraWorkStateCapturing: 正在摄像中
         */
        void didWorkStateChange(int workState);

        /**
         * 相机SD卡状态发生变化
         * @param mountState true:SD卡已插入 false:SD卡未插入
         */
        void didStorageMountedStateChanged(int mountState);

        /**
         * 相机SD卡存储容量发生变化
         * StorageStateAvailable:未满; StorageStateAboutFull:将满; StorageStateFull:已满;
         */
        void didStorageStateChanged(int oldState, int newState);

        void didStorageTotalFreeChanged(int total, int free);

        /**
         * 收到相机发来的通知，需要UI通知给用户
         * @param notification
         */
        void didReceiveCameraNotification(String notification);
    }

    /// ‘单例’(类)方法:

    /** 添加状态回调监听者 */
    public abstract void addStateListener(StateListener listener);

    /** 移除状态回调监听者 */
    public abstract void removeStateListener(StateListener listener);

    /** 连接相机 */
    public abstract void connectCamera();

    /** 唤醒处于Standby状态的相机 */
    public abstract void wakeupCamera();

    /** 断开相机连接 */
    public abstract void disconnectCamera();

    public abstract void disconnectCamera(int reason);

    /** 手机当前连接到的WiFi的SSID */
    public abstract String currentConnectingSSID();

    /** 手机当前正在连接的相机 */
    public abstract MVCameraDevice connectingCamera();

    /** 手机当前正在U盘模式连接相机 */
    public abstract boolean connectingCameraOnUDiskMode();

    /** 手机当前正在U盘模式连接相机的序列号 */
    public abstract String connectingCameraOnUDiskSerialNumber();

    public abstract void setConnectingCameraOnUDiskSerialNumber(String serialNumber);

    /** 已保存的全部相机列表 */
    public abstract List<MVCameraDevice> getAllStoredDevices();

    public abstract int getConnectingCameraPreviewMode();

    /** 从存储的相机列表中移除 */
    public abstract void removeStoredDevice(MVCameraDevice device);

    /// 实例方法：

    /** 设置相机SSID与密码 */
    public abstract void setCameraWifi(String said, String password);

    /**  重启相机的WiFi */
    public abstract void restartCameraWiFi();

    /** 设置相机拍摄模式
     * mode: 主模式
     * subMode: 子模式
     * param: 子模式下具体设置值，如延时摄像时是倍速数，定时拍照时是倒计时秒数
     */
    public abstract void setCameraMode(int mode, int subMode, int param);

    /** 启动摄像或拍照 */
    public abstract void startShooting();

    /** 停止摄像或拍照 */
    public abstract void stopShooting();

    /** 启动录剪，返回值表示是否成功 */
    public abstract boolean cutClip();

    /** 设置相机设置项
     * optionUID: 设置项ID
     * paramUID: 设置项下子项的ID
     */
    public abstract void setSettingOption(int optionUID, int paramUID);

    /** 获取相机指定设置项下的当前设置值
     * option:要查询的设置项ID
     * 返回：该设置项下选择的子项SettingTreeNode对象
     */
    public SettingTreeNode getSelectedParamOfOption(int optionUID) {
        SettingTreeNode optionNode = MVCameraDevice.findOptionNodeByUID(optionUID);
        if (null != optionNode) {
            return optionNode.findSubOptionByUID(optionNode.getSelectedSubOptionUID());
        }
        return null;
    }

    /** 获取美颜模式下的滤镜
     *
     * @return
     */
    public abstract List<ImageFilterBean> getImageFilters();

    // 实例属性：

    // 非持久化属性：

    //当前是否正在摄像
    public abstract boolean isVideoShooting();

    //当前是否可启动录剪
    public abstract boolean isClippingAvailable();

    //当前电量百分比
    public abstract int getVoltagePercent();

    public boolean isCharging() {
        return false;
    }

    public boolean isSDCardMounted() {
        return true;
    }

    public int sdCardFreeSize() {
        //KB
        return 0;
    }

    public boolean isLoopRecord() {
        return false;
    }

    public int getStorageState() {
        return StorageStateAvailable;
    }

    /**
     * 获取SD卡剩余容量可摄像的时长，单位为秒。如果未知则返回-1
     * @return
     */
    public int getVideoCapacity() {
        return -1;
    }

    /**
     * 获取SD卡剩余容量可拍照的数量，单位为张。如果未知则返回-1
     * @return
     */
    public int getPhotoCapacity() {
        return -1;
    }

    public void synchronizeCameraStorageAllState() {

    }

    public abstract void checkAndUpdateRemoter();

    public abstract int getState();

    public abstract int getWorkState();

    public abstract int waitForState(int state);

    public int getToken() {
        return 0;
    }

    public void setHeartbeatEnabled(boolean enabled) {
        isHeartbeatEnabled = enabled;
    }

    protected boolean isHeartbeatEnabled = false;

    private static MVCameraClient sharedInstance = null;

    public static synchronized MVCameraClient getInstance() {
        if (null == sharedInstance) {
            if (EnviromentConfig.environment() == EnviromentConfig.ENVIRONMENT_DEVELOPMENT) {
                sharedInstance = new MVCameraClientMock();
            } else {
                sharedInstance = new MVCameraClientImpl();
            }
        }
        return sharedInstance;
    }
}

