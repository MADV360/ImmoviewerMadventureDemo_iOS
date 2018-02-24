package com.madv360.madv.model;

import android.text.TextUtils;
import android.util.Log;

import com.madv360.glrenderer.MadvGLRenderer;
import com.madv360.madv.R;
import com.madv360.madv.model.bean.SettingTreeNode;

import org.w3c.dom.Element;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import bootstrap.appContainer.ElephantApp;
import foundation.activeandroid.Model;
import foundation.activeandroid.annotation.Column;
import foundation.activeandroid.annotation.Table;
import foundation.network.vender.androidquery.util.XmlDom;

import com.madv360.madv.media.MVMedia;

/**
 * Created by qiudong on 16/6/15.
 */
@Table(name = "MVCameraDevice")
public class MVCameraDevice extends Model {
    public static final int CameraModeVideo = 0;//拍摄主模式：摄像
    public static final int CameraSubmodeVideoNormal = 0;//摄像子模式：常规
    public static final int CAMERA_SUBMODE_VIDEO_SLOW = 1;//摄像子模式：延时
    public static final int CameraSubmodeVideoMicro = 3;//摄像子模式：秒拍
    public static final int CameraSubmodeVideoFilter = 4;//摄像子模式：滤镜
    public static final int CAMERA_SUBMODE_VIDEO_LIVE = 5;//摄像子模式：直播（预留）

    public static final int CameraModePhoto = 1;//拍摄主模式：拍照
    public static final int CameraSubmodePhotoFilter = 0;//拍照子模式：美颜
    public static final int CameraSubmodePhotoNormal = 1;//拍照子模式：常规
    public static final int CameraSubmodePhotoTiming = 2;//拍照子模式：定时

    public static final String StringFromCameraMode(int mode, int subMode, int param) {
        StringBuilder sb = new StringBuilder();
        switch (mode) {
            case CameraModeVideo:
                sb.append("(Video, ");
                switch (subMode) {
                    case CameraSubmodeVideoMicro:
                        sb.append("Micro)");
                        break;
                    case CameraSubmodeVideoNormal:
                        sb.append("Normal)");
                        break;
                    case CAMERA_SUBMODE_VIDEO_SLOW:
                        sb.append("Slow)");
                        break;
                }
                break;
            case CameraModePhoto:
                sb.append("Photo, ");
                switch (subMode) {
                    case CameraSubmodePhotoFilter:
                        sb.append("Filter)");
                        break;
                    case CameraSubmodePhotoNormal:
                        sb.append("Normal)");
                        break;
                    case CameraSubmodePhotoTiming:
                        sb.append("Timing)");
                        break;
                }
                break;
        }
        sb.append(", ");
        sb.append(param);
        return sb.toString();
    }

    public static final int InitMicroVideoModeParam = 10;
    public static final int InitSlowVideoModeParam = 1;
    public static final int InitTimingPhotoModeParam = 3;

    private static final String XmlTagMode = "mode";
    private static final String XmlTagSubMode = "subMode";
    private static final String XmlTagGroup = "group";
    private static final String XmlTagOption = "option";
    private static final String XmlTagParam = "param";
    private static final String XmlAttrUID = "uid";
    private static final String XmlAttrMsgID = "msgID";
    private static final String XmlAttrName = "name";
    private static final String XmlAttrType = "type";
    private static final String XmlAttrValue = "value";
    private static final String XmlValueTypeReadOnly = "readonly";
    private static final String XmlValueTypeSingle = "single";
    private static final String XmlValueTypeSlider = "slider";
    private static final String XmlValueTypeAction = "action";
    private static final String XmlValueTypeJump = "jump";

    /**
     * 获取相机全部设置项，以树状结构给出
     * 第一级列表：分组标题
     * 第二级列表：分组中的设置项
     * 第三级列表：分组中设置项下可选的全部设置值，如果该列表为空则说明是一个单一功能选项，比如当设置项为“格式化SD卡”时
     *
     * @return
     */
    public static synchronized ArrayList<SettingTreeNode> getCameraSettings() {
        if (deviceSettingsList == null) {
            // 分组列表
            deviceSettingsList = new ArrayList<>();
            try {
                InputStream ins = ElephantApp.getInstance().getResources().openRawResource(R.raw.device_settings);
                XmlDom xmlRoot = new XmlDom(ins);
                List<XmlDom> groups = xmlRoot.children(XmlTagGroup);
                for (XmlDom group : groups) {
                    SettingTreeNode groupNode = new SettingTreeNode();
                    deviceSettingsList.add(groupNode);

                    Element groupElement = group.getElement();
                    groupNode.uid = Integer.valueOf(groupElement.getAttribute(XmlAttrUID));
                    groupNode.name = groupElement.getAttribute(XmlAttrName);
                    Log.e("QD", "group: id = " + groupNode.uid + ", name = " + groupNode.name);

                    List<XmlDom> options = group.children(XmlTagOption);
                    for (XmlDom option : options) {
                        SettingTreeNode optionNode = new SettingTreeNode();
                        groupNode.subOptions.add(optionNode);

                        Element optionElement = option.getElement();
                        optionNode.uid = Integer.valueOf(optionElement.getAttribute(XmlAttrUID));
                        optionNode.msgID = Integer.valueOf(optionElement.getAttribute(XmlAttrMsgID));
                        optionNode.name = optionElement.getAttribute(XmlAttrName);
                        String viewType = optionElement.getAttribute(XmlAttrType);
                        if (XmlValueTypeAction.equals(viewType))
                            optionNode.viewType = SettingTreeNode.ViewTypeAction;
                        else if (XmlValueTypeSingle.equals(viewType))
                            optionNode.viewType = SettingTreeNode.ViewTypeSingleSelection;
                        else if (XmlValueTypeSlider.equals(viewType))
                            optionNode.viewType = SettingTreeNode.ViewTypeSliderSelection;
                        else if (XmlValueTypeReadOnly.equals(viewType))
                            optionNode.viewType = SettingTreeNode.ViewTypeReadOnly;
                        else if (XmlValueTypeJump.equals(viewType))
                            optionNode.viewType = SettingTreeNode.ViewTypeJump;
                        else
                            optionNode.viewType = SettingTreeNode.ViewTypeSingleSelection;

                        Log.e("QD", "   option: id = " + optionNode.uid + ", msgID = " + optionNode.msgID + ", name = " + optionNode.name + ", type = " + viewType);

                        if (optionNode.viewType == SettingTreeNode.ViewTypeReadOnly
                                || optionNode.viewType == SettingTreeNode.ViewTypeSingleSelection
                                || optionNode.viewType == SettingTreeNode.ViewTypeSliderSelection
                                || optionNode.viewType == SettingTreeNode.ViewTypeAction) {
                            List<XmlDom> params = option.children(XmlTagParam);
                            for (XmlDom param : params) {
                                SettingTreeNode paramNode = new SettingTreeNode();
                                optionNode.subOptions.add(paramNode);

                                Element paramElement = param.getElement();
                                paramNode.uid = Integer.valueOf(paramElement.getAttribute(XmlAttrUID));
                                paramNode.msgID = Integer.valueOf(paramElement.getAttribute(XmlAttrMsgID));
                                paramNode.name = paramElement.getAttribute(XmlAttrName);
                            }

                            if (optionNode.viewType == SettingTreeNode.ViewTypeReadOnly
                                    && optionNode.subOptions.size() == 0) {
                                SettingTreeNode paramNode = new SettingTreeNode();
                                paramNode.uid = 0;
                                optionNode.subOptions.add(paramNode);
                                optionNode.setSelectedSubOptionByUID(paramNode.uid);
                            }
                        }
                    }
                }

                ins.close();
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }
        return deviceSettingsList;
    }

    public static SettingTreeNode findOptionNodeByUID(int optionUID) {
        List<SettingTreeNode> groups = MVCameraDevice.getCameraSettings();
        for (SettingTreeNode groupNode : groups) {
            for (SettingTreeNode optionNode : groupNode.subOptions) {
                if (optionNode.uid == optionUID) {
                    return optionNode;
                }
            }
        }
        return null;
    }

    /**
     * 获取相机指定拍摄模式及子模式下所有可选参数值，以SettingTreeNode对象返回
     *
     * @param cameraMode
     * @param cameraSubMode
     * @return
     */
    public static SettingTreeNode getCameraModeParameters(int cameraMode, int cameraSubMode) {
        SettingTreeNode cameraModeTree = getCameraModeTree();
        SettingTreeNode cameraModeNode = cameraModeTree.findSubOptionByUID(cameraMode);
        if (null == cameraModeNode) return null;
        SettingTreeNode cameraSubModeNode = cameraModeNode.findSubOptionByUID(cameraSubMode);
        return cameraSubModeNode;
    }

    /**
     * 获取相机所有的拍摄模式、子模式，以及子模式可选参数值，以SettingTreeNode对象返回
     *
     * @return
     */
    public static synchronized SettingTreeNode getCameraModeTree() {
        if (cameraModeParameters == null) {
            // 分组列表
            cameraModeParameters = new SettingTreeNode();
            try {
                InputStream ins = ElephantApp.getInstance().getResources().openRawResource(R.raw.camera_mode_params);
                XmlDom xmlRoot = new XmlDom(ins);
                XmlDom group = xmlRoot.children(XmlTagGroup).get(0);
                Element groupElement = group.getElement();
                cameraModeParameters.msgID = Integer.valueOf(groupElement.getAttribute(XmlAttrMsgID));

                List<XmlDom> modes = group.children(XmlTagMode);
                for (XmlDom mode : modes) {
                    SettingTreeNode modeNode = new SettingTreeNode();
                    cameraModeParameters.subOptions.add(modeNode);

                    Element modeElement = mode.getElement();
                    modeNode.uid = Integer.valueOf(modeElement.getAttribute(XmlAttrUID));
                    modeNode.msgID = Integer.valueOf(modeElement.getAttribute(XmlAttrMsgID));
                    modeNode.name = modeElement.getAttribute(XmlAttrName);

                    List<XmlDom> subModes = mode.children(XmlTagSubMode);
                    for (XmlDom subMode : subModes) {
                        SettingTreeNode subModeNode = new SettingTreeNode();
                        modeNode.subOptions.add(subModeNode);

                        Element subModeElement = subMode.getElement();
                        subModeNode.uid = Integer.valueOf(subModeElement.getAttribute(XmlAttrUID));
                        subModeNode.msgID = Integer.valueOf(subModeElement.getAttribute(XmlAttrMsgID));
                        subModeNode.name = subModeElement.getAttribute(XmlAttrName);

                        List<XmlDom> params = subMode.children(XmlTagParam);
                        for (XmlDom param : params) {
                            SettingTreeNode paramNode = new SettingTreeNode();
                            subModeNode.subOptions.add(paramNode);

                            Element paramElement = param.getElement();
                            paramNode.msgID = Integer.valueOf(paramElement.getAttribute(XmlAttrMsgID));
                            paramNode.value = Float.valueOf(paramElement.getAttribute(XmlAttrValue));
                            paramNode.name = paramElement.getAttribute(XmlAttrName);
                        }
                    }
                }

                ins.close();
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }

        return cameraModeParameters;
    }

    static ArrayList<SettingTreeNode> deviceSettingsList = null;

    static SettingTreeNode cameraModeParameters = null;

    /// As ViewModel properties:
    public static final int STATE_WIFI_CONNECTED = 0x01;
    public static final int STATE_SESSION_CONNECTING = 0x10;
    public static final int STATE_SESSION_CONNECTED = 0x20;

    //相机的唯一ID
    public static final String DB_KEY_UUID = "uuid";
    @Column(name = DB_KEY_UUID, unique = true)
    public String uuid;

    public String getUUID() {
        return uuid;
    }

    public static final String DB_KEY_SSID = "SSID";
    @Column(name = DB_KEY_SSID)
    public String SSID;

    public String getSSID() {
        return SSID;
    }

    public static final String DB_KEY_PASSWORD = "password";
    @Column(name = DB_KEY_PASSWORD)
    public String password;

    public String getPassword() {
        return password;
    }

    //相机固件版本
    public static final String DB_KEY_FW_VERSION = "fwVer";
    @Column(name = DB_KEY_FW_VERSION)
    public String fwVer;

    public String getFirmwareVersion() {
        return fwVer;
    }

    //遥控器版本
    public String rcwVer;

    public String getRemoterVersion() {
        return rcwVer;
    }

    //相机序列号
    public static final String DB_KEY_SID_VERSION = "serialID";
    @Column(name = DB_KEY_SID_VERSION)
    public String serialID;

    public String getSerialID() {
        return serialID;
    }

    //拍摄主模式
    public static final String DB_KEY_CAMMODE = "cammode";
    @Column(name = DB_KEY_CAMMODE)
    public int cameraMode = CameraModeVideo;

    public int getCameraMode() {
        return cameraMode;
    }

    //拍摄子模式
    public static final String DB_KEY_CAMSUBMODE = "camsubmode";
    @Column(name = DB_KEY_CAMSUBMODE)
    public int cameraSubMode = CameraSubmodeVideoNormal;

    public int getCameraSubMode() {
        return cameraSubMode;
    }

    //拍摄子模式下设置参数
    public static final String DB_KEY_CAMSUBMODEPARAM = "camsubmodeparam";
    @Column(name = DB_KEY_CAMSUBMODEPARAM)
    public int cameraSubModeParam = 0;

    public int getCameraSubModeParam() {
        return cameraSubModeParam;
    }

    //预览模式
//    public static final String DB_KEY_PREVIEW_MODE = "previewMode";
//    @Column(name = DB_KEY_PREVIEW_MODE)
    public int cameraPreviewMode = MadvGLRenderer.PanoramaDisplayModeStereoGraphic;

    public int getCameraPreviewMode() {
        return cameraPreviewMode;
    }

    public static final String DB_KEY_LAST_SYNC_TIME = "lastsynctime";
    @Column(name = DB_KEY_LAST_SYNC_TIME)
    public Date lastSyncTime;

    public Date getLastSyncTime() {
        return lastSyncTime;
    }

    public MVMedia recentMedia = null;

    public boolean shouldSetWiFiPassword() {
        return TextUtils.isEmpty(password);
    }

    @Override
    public int hashCode() {
        String identifier = SSID + password + uuid;
        return identifier.hashCode();
    }

    @Override
    public boolean equals(Object other) {
        if (!(other instanceof MVCameraDevice))
            return false;

        MVCameraDevice otherDevice = (MVCameraDevice) other;
        if (uuid != null)
            return uuid.equals(otherDevice.uuid);
        else if (SSID != null)
            return SSID.equals(otherDevice.SSID);
        else if (password != null)
            return password.equals(otherDevice.password);
        else
            return false;
    }

    @Override
    public String toString() {
        return "(UUID=" + uuid + ", SSID=" + SSID + ", Password=" + password + ", CameraMode=" + cameraMode + ", CameraSubMode=" + cameraSubMode + ")";
    }

    public int connectionState;
}
