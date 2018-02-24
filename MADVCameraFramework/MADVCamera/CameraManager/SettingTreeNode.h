//
//  SettingTreeNode.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/9.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    // 用弹出或二级菜单作单选。例如分辨率
    ViewTypeSingleSelection = 0,
    // 用滑杆作单选，此时应根据subOptions的value属性求出最小值和最大值，以决定滑杆的取值范围。例如曝光
    ViewTypeSliderSelection = 1,
    
    //只读，在右侧显示name。例如设备版本号
    ViewTypeReadOnly = 2,
    //点击后是弹出提示框提示用户执行某个操作。例如格式化和恢复出厂设置
    ViewTypeAction = 3,
    //点击后跳转到某个页面，具体由id决定。例如WiFi设置
    ViewTypeJump = 4,
    //右边是switch按钮
    ViewTypeSwitch = 5,
} SettingViewType;

typedef enum : NSInteger {
    SettingNodeIDVideoFrameRateSetting = 0,
    SettingNodeIDVideoWBSetting = 1,
    SettingNodeIDVideoEVSetting = 3,
    SettingNodeIDCameraLoopSetting = 4,
    SettingNodeIDPhotoResolutionSetting = 10,
    SettingNodeIDPhotoWBSetting = 11,
    SettingNodeIDPhotoISOSetting = 12,
    SettingNodeIDPhotoShutterSetting = 13,
    SettingNodeIDPhotoEVSetting = 14,
    SettingNodeIDJumpToWiFiSetting = 20,
    SettingNodeIDFormatSD = 21,
    SettingNodeIDCameraPreviewMode = 22,
    SettingNodeIDCameraPowerOffSetting = 23,
    SettingNodeIDCameraBuzzerSetting = 24,
    SettingNodeIDCameraLedSetting = 26,
    SettingNodeIDCameraPowerOff = 27,
    SettingNodeIDCameraProduceNameSetting = 30,
    SettingNodeIDSerialID = 31,
    SettingNodeIDFirmwareVersion = 32,
    SettingNodeIDResetToDefaultSettings = 33,
} SettingNodeID;

@interface SettingTreeNode : NSObject
@property(nonatomic,assign) SettingViewType viewType;
@property(nonatomic,assign) int uid;// 唯一ID(只要在同一层级中唯一即可）
@property(nonatomic,assign) int msgID;// AMBA命令的msg_id（如果有的话）
@property(nonatomic,copy) NSString * name;
@property(nonatomic,assign) float value;

@property(nonatomic,copy) NSString * jsonParamKey;

@property(nonatomic,assign) int selectedSubOptionUID;
@property(nonatomic,strong) NSArray* subOptions;//这存放它的字节点

- (SettingTreeNode *)findSubOptionByUID:(int)subOptionUID;

- (SettingTreeNode *)findSubOptionByMsgID:(int)subOptionMsgID;

+ (id)settingTreeNodeWithDict:(NSDictionary *)dict;

+ (id)cameraModeParamNodeWithDict:(NSDictionary *)dict modeName:(NSString *)modeName subModeName:(NSString *)subModeName;
+ (id)cameraModeParamNodeWithDict:(NSDictionary *)dict modeUid:(int)uid subModeUid:(int)subModeUid;

- (BOOL)isSupportSlowMotionParameter:(int)parameter;
- (BOOL)isSupportVideoTimelapse;
- (BOOL)isSupportBracketing;
@end
