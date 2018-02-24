package com.madv360.madv.model.bean;

import java.io.Serializable;
import java.util.ArrayList;

public class SettingTreeNode implements Serializable {
    // 用弹出或二级菜单作单选。例如分辨率
    public static final int ViewTypeSingleSelection = 0;

    // 用滑杆作单选，此时应根据subOptions的value属性求出最小值和最大值，以决定滑杆的取值范围。例如曝光
    public static final int ViewTypeSliderSelection = 1;

    // 只读，在右侧显示name。例如设备版本号
    public static final int ViewTypeReadOnly = 2;

    // 点击后是弹出提示框提示用户执行某个操作。例如格式化和恢复出厂设置
    public static final int ViewTypeAction = 3;

    // 点击后跳转到某个页面，具体由id决定。例如WiFi设置
    public static final int ViewTypeJump = 4;

    public static final int VideoResolutionSetting = 0;
    public static final int VideoWBSetting = 1;
    public static final int VideoEVSetting = 3;
    public static final int CameraLoopSetting = 4;
    public static final int PhotoResolutionSetting = 10;
    public static final int PhotoWBSetting = 11;
    public static final int PhotoISOSetting = 12;
    public static final int PhotoShutterSetting = 13;
    public static final int PhotoEVSetting = 14;
    public static final int JumpToWiFiSetting = 20;
    public static final int FormatSD = 21;
    public static final int CameraPreviewMode = 22;
    public static final int CameraPowerOffSetting = 23;
    public static final int CameraBuzzerSetting = 24;
    public static final int CameraLedSetting = 26;
    public static final int CameraPowerOff = 27;
    public static final int CameraProduceNameSetting = 30;
    public static final int SerialID = 31;
    public static final int FirmwareVersion = 32;
    public static final int ResetToDefaultSettings = 33;

    public static final int VideoResolution60fpsUID = 2;

    public int uid;// 唯一ID(只要在同一层级中唯一即可）

    public int msgID;// AMBA命令的msg_id（如果有的话）

    public String name;

    public float value;

    public int viewType;

    protected int selectedSubOptionUID;

    public int getSelectedSubOptionUID() {
        return selectedSubOptionUID;
    }

    public void setSelectedSubOptionByUID(int subOptionUID) {
        for (SettingTreeNode option : subOptions) {
            if (option.uid == subOptionUID) {
                selectedSubOptionUID = subOptionUID;
                return;
            }
        }
    }

    public void setSelectedSubOptionByMsgID(int subOptionMsgID) {
        for (SettingTreeNode option : subOptions) {
            if (option.msgID == subOptionMsgID) {
                selectedSubOptionUID = option.uid;
                return;
            }
        }
    }

    public ArrayList<SettingTreeNode> subOptions = new ArrayList<>();

    public SettingTreeNode findSubOptionByUID(int subOptionUID) {
        for (SettingTreeNode option : subOptions) {
            if (option.uid == subOptionUID)
                return option;
        }
        return null;
    }

    public SettingTreeNode findSubOptionByMsgID(int subOptionMsgID) {
        for (SettingTreeNode option : subOptions) {
            if (option.msgID == subOptionMsgID)
                return option;
        }
        return null;
    }
}
