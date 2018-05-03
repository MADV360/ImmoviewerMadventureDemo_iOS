//
//  MVCameraClient.h
//  Madv360_v1
//
//  封装了作为相机Server的Client去操作相机的方法
//  Created by 张巧隔 on 16/8/10.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MVCameraDevice.h"
#import "ImageFilterBean.h"
#import "AMBACommands.h"

/** App与相机的连接状态 */
typedef enum : NSInteger {
    CameraClientStateNotConnected = 1, //未连接
    CameraClientStateConnecting = 2, //正在连接
    CameraClientStateConnected = 4, //已连接
    CameraClientStateDisconnecting = 8, //正在断开连接
    CameraClientStateReConnecting = 16, //正在重连
} CameraClientState;

/** 相机的工作状态
 *  刚进入拍摄预览界面时应根据cameraWorkState属性的值来决定界面如何显示；
 *  关于USB存储模式和待机两种状态，目前SDK层在刚连接上相机时如果发现处于这两种状态之一，会直接断掉连接，
 *  应用层无需做特殊处理，只需正常处理didDisconnect回调即可。
 */
typedef enum : NSInteger {
    CameraWorkStateIdle = AMBA_PARAM_CAMERA_STATE_IDLE, //空闲
    CameraWorkStateCapturing = AMBA_PARAM_CAMERA_STATE_CAPTURING,//正在摄像
    CameraWorkStateStorage = AMBA_PARAM_CAMERA_STATE_STORAGE, //USB存储模式
    CameraWorkStateStandby = AMBA_PARAM_CAMERA_STATE_STANDBY,//待机
    CameraWorkStateCapturingMicro = AMBA_PARAM_CAMERA_STATE_CAPTURING_MICRO,//正在秒拍
    CameraWorkStateCapturingTimeLapse = AMBA_PARAM_CAMERA_STATE_CAPTURING_TIMELAPSE,//正在延时摄像
    CameraWorkStatePhotoing = AMBA_PARAM_CAMERA_STATE_PHOTOING,//正在拍照
    CameraWorkStatePhotoingDelayed = AMBA_PARAM_CAMERA_STATE_PHOTOING_DELAYED,//正在定时拍照
    CameraWorkStatePhotoingInterval = AMBA_PARAM_CAMERA_STATE_PHOTOING_INTERVAL,//正在间隔拍照
    CameraWorkStateCapturingSlowMotion = AMBA_PARAM_CAMERA_STATE_CAPTURING_SLOWMOTION,//正在慢动作摄像
    CameraWorkStatePhotoingContinuous = AMBA_PARAM_CAMERA_STATE_CAPTURING_CONTINUOUS,//正在连续拍照
    CameraWorkStatePhotoingSurroundExp = AMBA_PARAM_CAMERA_STATE_CAPTURING_SURROUNDEXP,//正在连续拍照
} CameraWorkState;

/** 存储卡容量状态 */
typedef enum : NSInteger {
    StorageStateAvailable = AMBA_PARAM_SDCARD_FULL_NO, //可用
    StorageStateAboutFull = AMBA_PARAM_SDCARD_FULL_ALMOST, //即将满
    StorageStateFull = AMBA_PARAM_SDCARD_FULL_YES, //已满
} StorageState;

/** 存储卡加载状态 */
typedef enum : NSInteger {
    StorageMountStateNO = 0,//没插卡
    StorageMountStateError = -1,//错误卡
    StorageMountStateOK = 1, //正常卡
    StorageMountStateFault = -2,//黑名单卡
    StorageMountStateUnsure = -3,//灰名单卡
} StorageMountState;

/** 相机断开连接时返回的断开原因参数 */
typedef enum : NSInteger {
    CameraDisconnectReasonUnknown = 0, //任何不在以下原因中的其它原因
    CameraDisconnectReasonOtherClient = 1, //因有其它客户端正在连接
    CameraDisconnectReasonInStorageMode = 2, //因处于USB存储模式而断开
    CameraDisconnectReasonStandBy = 3, //因待机而断开
} CameraDisconnectReason;

typedef enum : int {
    VideoRecordingSpeedNormal = AMBA_PARAM_VIDEO_RECORDING_SPEED_1X,
    VideoRecordingSpeed2X = AMBA_PARAM_VIDEO_RECORDING_SPEED_2X,
    VideoRecordingSpeed4X = AMBA_PARAM_VIDEO_RECORDING_SPEED_4X,
    VideoRecordingSpeed2D = AMBA_PARAM_VIDEO_RECORDING_SPEED_2D,
    VideoRecordingSpeed4D = AMBA_PARAM_VIDEO_RECORDING_SPEED_4D,
} VideoRecordingSpeed;

typedef enum : int {
    LensUsageModeFront = AMBA_PARAM_LENS_USAGE_LOGO,
    LensUsageModeBack = AMBA_PARAM_LENS_USAGE_LED,
    LensUsageModeBoth = AMBA_PARAM_LENS_USAGE_BOTH,
} LensUsageMode;

typedef enum : int {
    VideoSegmentDuration15s = 15,
    VideoSegmentDuration60s = 60,
    VideoSegmentDuration30s = 30,
    VideoSegmentDuration300s = 300,
} VideoSegmentDuration;

/** 通知类型 */
#ifdef __cplusplus
extern "C" {
#endif
    
    extern NSString* NotificationFormatWithoutSD;
    extern NSString* NotificationFormatSDSuccess;
    extern NSString* NotificationFormatWhileWorking;
    extern NSString* NotificationInvalidOperation;
    extern NSString* NotificationInvalidToken;
    extern NSString* NotificationLowBattery;
    extern NSString* NotificationNoFirmware;
    extern NSString* NotificationNoSDCard;
    extern NSString* NotificationSDCardFull;
    extern NSString* NotificationWrongMode;
    extern NSString* NotificationCameraOverheated;
    extern NSString* NotificationRecoveryMediaFile;
    
    NSString* NotificationStringOfNotification(int notification);
    
#ifdef __cplusplus
}
#endif

/** 相机客户端监听者。定义了相机各种状态变化的回调 */
@protocol MVCameraClientObserver <NSObject>

/** 即将连接 */
- (void) willConnect;

/** 连接相机成功。此时state属性为CameraClientStateConnected
 * device: 连接到的相机设备，其中包含了其唯一ID、SSID、密码等等信息，见#MVCameraDevice#类
 */
-(void) didConnectSuccess:(MVCameraDevice*) device;

/** 连接相机失败。此时state属性为CameraClientStateNotConnected
 *  errorMessage: 错误提示信息
 */
- (void) didConnectFail:(NSString *)errorMessage;

/** 设置相机WiFi结果 */
-(void) didSetWifi:(BOOL)success errMsg:(NSString *)errMsg;

/** 重启相机WiFi结果 */
-(void) didRestartWifi:(BOOL)success errMsg:(NSString *)errMsg;

/** 即将断开
 * reason: 断开连接的原因，见#CameraDisconnectReason#枚举
 */
-(void) willDisconnect:(CameraDisconnectReason)reason;

/** 断开相机连接（包括主动断开和异常断开都会到这里）。此时state属性会返回CameraClientStateNotConnected
 * reason: 断开连接的原因，见#CameraDisconnectReason#枚举
 */
-(void) didDisconnect:(CameraDisconnectReason)reason;

/** 相机电量发生变化的通知
 * percent: 电量百分比数
 * isCharging: 是否正在充电
 */
-(void) didVoltagePercentChanged:(int)percent isCharging:(BOOL)isCharging;

/** 相机拍摄模式发生变化
 * mode: 主模式，见#MVCameraDevice#的#CameraMode#枚举值
 * subMode: 子模式，见#MVCameraDevice#的#CameraSubMode#枚举值
 * param: 子模式下具体设置值，如延时摄像时是倍速数，定时拍照时是倒计时秒数
 */
-(void) didCameraModeChange:(CameraMode)mode subMode:(CameraSubMode)subMode param:(NSInteger) param;

/** 相机模式切换失败
 *
 * @param errMsg
 */
- (void) didSwitchCameraModeFail:(NSString *)errMsg;

/** 摄像启动
 * error: 错误代码。如果正常启动摄像应为0
 */
- (void) didBeginShooting:(int)error numberOfPhoto:(int)numberOfPhoto;

/** 摄像时长计时器回调
 * 拍摄预览界面上的计时显示应该以此回调的数值为准。应用层无需自己设置计时器
 * shootTime: 摄像开始到当前时刻的秒数
 * videoTime: 实际拍摄出的视频的当前时长（只在延时摄像时有意义，其它情况下与shootTime一致）
 */
- (void) didShootingTimerTick:(int)shootTime videoTime:(int)videoTime;

/** 定时拍照倒计时回调 */
- (void) didCountDownTimerTick:(int)timingStart;
    
/** 摄像（或定时拍照）已停止 参数没什么用  只是告诉摄像已完成*/
-(void) didEndShooting:(NSString *)remoteFilePath videoDurationMills:(NSInteger)videoDurationMills error:(int)error errMsg:(NSString *)errMsg;

/** 存储卡写入缓慢的通知 */
- (void) didSDCardSlowlyWrite;
    
/** 录像停止
 * error: 错误代码。如果正常停止摄像应为0
 */
- (void)didStopShooting:(int)error;

///** 摄像或拍照结束后得到缩略图 */
//-(void) didTakeMedia:(UIImage *)thumbnailImage;

///** 录剪已启动 */
//-(void) didClippingBegin;
///** 录剪片段计时器回调，secondsLeft为当前录剪片段还剩余的时长（秒） */
//-(void) didClippingTimerTick:(int)secondsLeft;
///** 录剪已结束，totalClips为当前摄像过程总共录剪的片段数 */
//-(void) didClippingEnd:(int)totalClips;

/** 相机设置发生变化
 * optionUID: 设置项ID
 * paramUID: 设置项下子项的ID
 * errMsg: 发生错误时错误信息
 */
-(void) didSettingsChange:(int)optionUID paramUID:(int)paramUID errMsg:(NSString *)errMsg;

-(void) didReceiveAllSettingItems:(int)errorCode;

/**
 * 相机工作状态发生变化
 * @param workState 相机工作状态，见#CameraWorkState#枚举
 */
-(void) didWorkStateChange:(CameraWorkState)workState;

/**
 * 相机存储卡加载状态发生变化
 * @param mounted:存储卡加载状态，见#StorageMountState#枚举
 */
-(void) didStorageMountedStateChanged:(StorageMountState)mounted;

/**
 * 相机SD卡存储容量发生变化
 * @param capacity StorageCapacityAvailable:未满; StorageCapacityAboutFull:将满; StorageCapacityFull:已满;
 */
-(void) didStorageStateChanged:(StorageState)newState oldState:(StorageState)oldState;

/** 存储卡容量发生变化 */
- (void) didStorageTotalFreeChanged:(int)total free:(int)free;

/**
 * 收到相机发来的通知，需要UI通知给用户
 * @param notification: 以字符串常量表示的通知，如#NotificationFormatWithoutSD#等
 */
-(void) didReceiveCameraNotification:(NSString*)notification;

/**
 * 相机陀螺仪校正结果
 */
- (void)didAdjustedCameraGyro:(int)errorCode;

@optional

-(void) willStopCapturing:(id)param;

-(void) willStartCapturing:(id)param;

@end

/** 相机客户端代理类
 * 这是一个单例类，封装了应用层用以操作相机和获取相机各种状态通知的方法
 */
@interface MVCameraClient : NSObject

/** 添加状态回调监听者 */
-(void) addObserver:(id<MVCameraClientObserver>) observer;
/** 移除状态回调监听者 */
-(void) removeObserver:(id<MVCameraClientObserver>) observer;

/** 连接相机 */
-(void)connectCamera;

/** 唤醒处于Standby状态的相机（目前不需要这个方法 只要相机处于待机就会回调断开方法）*/
-(void) wakeupCamera;

/** 断开相机连接 */
-(void) disconnectCamera;

///** 手机当前连接到的WiFi的SSID */
//-(NSString *) currentConnectingSSID;

/** 手机当前正在连接的相机，当没有连接相机时为nil */
@property (nonatomic,strong,readonly) MVCameraDevice* connectingCamera;

/** 已保存的全部相机列表
 *  在相机列表有更新时（比如刚添加了相机或刚删除了相机）需主动调用以刷新列表
 */
-(NSArray<MVCameraDevice *> *) allStoredDevices;

/** 从存储的相机列表中移除（如果已连接，会包括必要的断开连接操作，无需应用层另外调用） */
-(void) removeStoredDevice:(MVCameraDevice *) device;

/** 设置相机SSID与密码 */
-(void) setCameraWifi:(NSString *)ssid password:(NSString *)password;

/**  重启相机的WiFi（目前的相机固件已将重置密码和重启WiFi合二为一，只需设置相机WiFi成功，相机就会自动重启，无需调用） */
-(void) restartCameraWiFi;

/** 设置相机拍摄模式，用于拍摄预览界面
 * 只要拍摄的主模式、子模式、或子模式参数中有任一个需要通过UI操作发生变化，则应调用此API
 * 拍摄预览界面UI元素的更新应遵循“先调用，再等回调”的模式：
 * 界面上与当前拍摄的模式、状态有关的UI元素不应由应用层主动更新，而是在回调时根据回调传回的参数来更新，或者在刚创建界面时根据主动查询得到的值来更新。
 * 以下的各种与拍摄有关的API调用也是相似逻辑，不再赘述
 * mode: 主模式
 * subMode: 子模式
 * param: 子模式下具体设置值，如延时摄像时是倍速数，定时拍照时是倒计时秒数
 */
-(void)setCameraMode:(CameraMode)mode subMode:(CameraSubMode)subMode param:(NSInteger)param;

/** 启动摄像或拍照
 * 拍摄按钮的外观更新也应遵循“先调用，再等回调”的模式，见setCameraMode的注释
 */
-(void) startShooting;

-(void) startShootingWithAudio:(BOOL)withAudio;

-(void) startShootingWithTimeoutMills:(int)timeoutMills;

-(void) startShootingWithTimeoutMills:(int)timeoutMills withAudio:(BOOL)withAudio;

/** 停止摄像或拍照(拍照主要是间隔拍照的停止)
 * 拍摄按钮的外观更新也应遵循“先调用，再等回调”的模式，见setCameraMode的注释
 */
-(void) stopShooting;

///** 启动录剪，返回值表示是否成功 （一期未实现）*/
//-(BOOL)cutClip;

/** 设置相机设置项。详见MVCameraDevice和SettingTreeNode
 * optionUID: 设置项ID
 * paramUID: 设置项下子项的ID
 */
-(void) setSettingOption:(int)optionUID paramUID:(int)paramUID;

/** 获取相机指定设置项下的当前设置值
 * option:要查询的设置项ID
 * 返回：该设置项下选择的子项SettingTreeNode对象
 */
-(SettingTreeNode *)selectedParamOfOption:(int) optionUID;

/** 获取美颜模式下所有可用的滤镜
 *
 * @return 可用滤镜的列表，见ImageFilterBean类
 */
- (NSArray<ImageFilterBean *>*)imageFilters;

//获取子模式下的参数
//- (SettingTreeNode *)getCameraModeParameters:(CameraMode)cameraMode cameraSubMode:(CameraSubMode)cameraSubMode;

/** 是否开启循环录像 */
@property (nonatomic, assign, readonly) BOOL loopRecord;

////当前是否可启动录剪
//@property (nonatomic, assign, readonly) BOOL isClippingAvailable;

/** 当前电量百分比 */
@property (nonatomic, assign, readonly) int voltagePercent;
/** 是否正在充电 */
@property (nonatomic, assign, readonly) BOOL isCharging;

/** 当前相机存储卡容量状态 */
@property (nonatomic, assign, readonly) StorageState storageState;

/** 当前相机剩余存储卡容量可供拍摄视频的分钟数 */
@property (nonatomic, assign, readonly) int videoCapacity;

/** 当前相机剩余存储卡容量可供拍摄照片的张数 */
@property (nonatomic, assign, readonly) int photoCapacity;

/** 存储卡总容量，单位字节 */
@property(nonatomic,assign,readonly) int totalStorage;
/** 存储卡剩余可用容量，单位字节 */
@property(nonatomic,assign,readonly) int freeStorage;

/** 用于判断存储卡是白名单、灰名单，还是黑名单卡的三个标识量（别问我我也不懂） */
@property(nonatomic,assign,readonly) int sdOID;
@property(nonatomic,assign,readonly) int sdMID;
@property(nonatomic,copy,readonly) NSString* sdPNM;

/** 当前相机SD卡是否插上 */
@property (nonatomic, assign, readonly) BOOL isSDCardMounted;

/** 当前存储卡加载状态 */
@property(nonatomic,assign) StorageMountState storageMounted;

/** 存储卡加载状态最近一次变化前的状态 */
@property(nonatomic,assign) StorageMountState oldStorageMounted;

/** 相机当前连接状态 */
@property (nonatomic, assign, readonly) CameraClientState state;

/** 相机当前工作状态 */
@property (nonatomic, assign, readonly) CameraWorkState cameraWorkState;

/** 相机是否正在摄像 */
@property(nonatomic,assign,readonly)BOOL isShooting;

/** 如果相机正在定时拍照倒计时中，返回当前倒计时秒数 */
@property(nonatomic,assign,readonly) int downCounter;

/** 预览模式，见#MadvGLRenderer#的#PanoramaDisplayMode#枚举 */
@property (nonatomic, assign, readonly) int cameraPreviewMode;

/** 如果相机正在间隔拍照中，返回当前拍照数量,-1则表示此次间隔拍照过程结束 */
@property(nonatomic,assign,readonly) int intervalPhotosNumber;
/** 如果相机正在包围曝光拍照中，返回当前拍照数量,3则表示此次包围曝光过程结束 */
@property(nonatomic,assign)int surroundExpNumberOfPhoto;

/** 设置是否要给相机发送保活心跳包
 * 如果相机在一定时间内收不到任何指令，则会进入待机状态，从而会影响到诸如HTTP文件下载、实时视频预览这些活动不能正常维持
 * 因此需要在开始这类活动时使能保活心跳包，则SDK会自动在没有发送任何指令的期间及时发送保活心跳包，阻止相机进入待机
 * enabled: 开启还是关闭
 * demander: 用以表示每一种需要开启/关闭心跳包的活动的名称。当至少有一种活动要求开启心跳包时，就会实际开启心跳包。
 * 只有当没有任何一个活动要求开启心跳包时，才实际关闭保活心跳包
 */
- (void) setHeartbeatEnabled:(BOOL)enabled forDemander:(NSString*)demander;

- (void) startGPSInfoSynchronization:(BOOL)isGPSParamChange;
- (void) stopGPSInfoSynchronization;
//相机陀螺仪校正
- (void)startAdjustCameraGyro;

/** 相机的存储卡是否为白名单卡 */
+ (BOOL)isSdWhiteSd_mid:(NSInteger)sd_mid sd_oid:(NSInteger)sd_oid sd_pnm:(NSString *)sd_pnm;

/** #Douyin# 设置抖音视频长度，单位秒 */
- (void) setVideoSegmentSeconds:(int)seconds;

/** #Douyin# 设置相机摄像倍速，参数取值#VideoRecordingSpeed#枚举 */
- (void) setVideoRecordingSpeed:(VideoRecordingSpeed)speed;

/** #Douyin# 设置镜头模式，参数取值#LensUsageMode#枚举 */
- (void) setLensUsageMode:(LensUsageMode)mode;

/** #Douyin# 设置摄像码率 */
- (void) setVideoRecordingMBPS:(int)Mbps;

/** #Douyin# 设置目前连接的手机APP，相机以此决定一些工作模式设置
 * @param appID : 0代表全景相机，2代表抖音
 */
- (void) setCurrentApp:(int)appID;

+ (instancetype) sharedInstance;

#pragma mark    Protected
/// 应用层不会直接用到的（可理解为protected）属性和方法 ///

@property (nonatomic, assign, readonly) NSInteger sessionToken;

+ (NSString*) formattedCameraUUID:(NSString*)cameraUUID;

- (void) synchronizeCameraStorageAllState;

@end
