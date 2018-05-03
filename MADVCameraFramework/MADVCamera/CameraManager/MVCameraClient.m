//
//  MVCameraClient.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/10.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVCameraClient.h"
#import "MVCameraDownloadManager.h"
#import "CMDConnectManager.h"
#import "AMBARequest.h"
#import "AMBAGetWiFiStatusResponse.h"
#import "AMBACommands.h"
#import "WiFiConnectManager.h"
#import "CMDConnectManager.h"
#import "DATAConnectManager.h"
#import "AMBASetWifiRequest.h"
#import "AMBASyncStorageAllStateResponse.h"
#import "AMBAGetAllSettingParamResponse.h"
#import "AMBASaveMediaFileDoneResponse.h"
#import "AMBAGetAllModeParamResponse.h"
#import "AMBASetClientInfoResponse.h"
#import "AMBASetCameraModeResponse.h"
#import "AMBAShootPhotoIntervalResponse.h"
#import "AMBASetGPSInfoRequest.h"
#import "MVMedia.h"
#import "MVMediaManager.h"
#import "NSRecursiveCondition.h"
#import "z_Sandbox.h"
#import "RealmSerialQueue.h"
#import "MadvGLRenderer_iOS.h"
#ifdef MADVPANO_BY_SOURCE
#import "MadvUtils.h"
#else
#import <MADVPano/MadvUtils.h>
#endif
#import "SocketHelper.h"
#import "MVCameraUploadManager.h"
#import "SdWhiteDetail.h"
#import "helper.h"
#import <CoreLocation/CoreLocation.h>
#import "AMBAShootPhotoSurroundexpResponse.h"

#define MSG_STATE_CHANGED 1
#define MSG_WIFI_SET 2
#define MSG_WIFI_RESTART 3
#define MSG_MODE_CHANGED 4
#define MSG_BEGIN_SHOOTING 5
#define MSG_BEGIN_SHOOTING_ERROR 6
#define MSG_END_SHOOTING 7
#define MSG_TIMER_TICKED 9
#define MSG_SETTING_CHANGED 10
#define MSG_VOLTAGE_CHANGED 11
#define MSG_WORK_STATE_CHANGED 12
#define MSG_RECEIVE_NOTIFICATION 13
#define MSG_STORAGE_MOUNTED_STATE_CHANGED 14
#define MSG_STORAGE_STATE_CHANGED 15
#define MSG_STORAGE_TOTAL_FREE_CHANGED 16
#define MSG_ALL_SETTING_RECEIVED 17
#define MSG_STOP_SHOOTING 18
#define MSG_COUNT_DOWN_TICKED 19
#define MSG_SDCARD_SLOWLY_WRITE 20
//#define MSG_WAIT_SAVE_VIDEO_DONE 21
#define MSG_DOUYIN_WILL_STOP_CAPTURING 22
#define MSG_DOUYIN_WILL_START_CAPTURING 23
#define MSG_ADJUST_CAMERA_GYRO_DONE 24

NSString* NotificationFormatWithoutSD = @"No SDCard";
NSString* NotificationFormatSDSuccess = @"Format SDCard success";
NSString* NotificationFormatWhileWorking = @"Format while camera is busy";
NSString* NotificationInvalidOperation = @"Invalid operation";
NSString* NotificationInvalidToken = @"Invalid token";
NSString* NotificationLowBattery = @"Low battery";
NSString* NotificationNoFirmware = @"No firmware";
NSString* NotificationNoSDCard = @"No SD card";
NSString* NotificationSDCardFull = @"SD card full";
NSString* NotificationWrongMode = @"Wrong mode";
NSString* NotificationCameraOverheated = @"camera overheated";
NSString* NotificationRecoveryMediaFile = @"recovery media file";

NSString* NotificationStringOfNotification(int notification) {
    switch (notification)
    {
        case AMBA_RVAL_ERROR_BUSY:
            return NotificationFormatWhileWorking;
        case AMBA_RVAL_ERROR_INVALID_OPERATION:
            return NotificationInvalidOperation;
        case AMBA_MSGID_FORMAT_SD:
            return NotificationFormatSDSuccess;
        case AMBA_RVAL_ERROR_INVALID_TOKEN:
            return NotificationInvalidToken;
        case AMBA_RVAL_ERROR_LOW_BATTERY:
            return NotificationLowBattery;
        case AMBA_RVAL_ERROR_NO_FIRMWARE:
            return NotificationNoFirmware;
        case AMBA_RVAL_ERROR_NO_SDCARD:
            return NotificationNoSDCard;
        case AMBA_RVAL_ERROR_SDCARD_FULL:
            return NotificationSDCardFull;
        case AMBA_RVAL_ERROR_WRONG_MODE:
            return NotificationWrongMode;
        case AMBA_MSGID_CAMERA_OVERHEATED:
            return NotificationCameraOverheated;
        case AMBA_MSGID_RECOVERY_MEDIA_FILE:
            return NotificationRecoveryMediaFile;
        default:
            return @"Error";
    }
}

@interface MVCameraClient () <CMDConnectionObserver,DataConnectionObserver>
{
    NSRecursiveCondition* _cond;
    
    CameraClientState _state;
    
    NSMutableArray<id<MVCameraClientObserver> >* _observers;
    
    BOOL _isCharging;
    
    int _videoCapacity;
    int _photoCapacity;
    int _totalStorage;
    int _freeStorage;
    
    dispatch_queue_t _timingQueue;
    NSTimer* _gpsSyncTimer;
}

@property (nonatomic, assign) CameraWorkState cameraWorkState;
@property (nonatomic, assign) CameraClientState state;
@property (nonatomic, assign) int voltagePercent;
@property (nonatomic, assign) BOOL isCharging;
@property (nonatomic, assign) StorageState storageState;
@property (nonatomic, assign) int videoCapacity;
@property (nonatomic, assign) int photoCapacity;
@property (nonatomic, assign) int totalStorage;
@property (nonatomic, assign) int freeStorage;
@property (nonatomic, assign) BOOL isSDCardMounted;
@property(nonatomic,assign) int sdOID;
@property(nonatomic,assign) int sdMID;
@property(nonatomic,copy) NSString* sdPNM;
@property (nonatomic, assign) BOOL isClippingAvailable;
@property (nonatomic, assign) BOOL loopRecord;

@property(nonatomic,strong)MVCameraDevice * connectingCamera;
@property (nonatomic, assign) NSInteger sessionToken;
@property(nonatomic,assign)BOOL isTiming;
@property(nonatomic,assign)BOOL isCountingDown;
@property(nonatomic,assign) int downCounter;
@property(nonatomic,assign) int intervalPhotosNumber;
@property(nonatomic,assign)BOOL isShooting;

@property(nonatomic,strong)ImageFilterBean *currentFilter;
@property(nonatomic,assign)int currentMicroParam;
@property(nonatomic, strong) NSMutableSet* isHeartbeatEnabledForDemander;

@property (nonatomic, assign) uint32_t rtspSessionID;

@property (nonatomic, assign) BOOL isLUTSynchronized;
@property (nonatomic, assign) BOOL isSettingsSynchronized;
@property (nonatomic, assign) BOOL isConnectedStateNotified;

- (void) disconnectCamera:(CameraDisconnectReason)reason;

/** 等待CameraClient达到指定的状态，在未满足条件时阻塞
 *  主要是供SDK层其它类调用，应用层可以不关心
 *  @param state 可以用按位或运算指定多个CameraClientStaite枚举值，当状态是其中任意一个时都算满足条件
 *  @return 当前实际的状态值
 */
- (CameraClientState) waitForState:(CameraClientState)state;

@end

@implementation MVCameraClient

@synthesize cameraWorkState;
@synthesize connectingCamera;
@synthesize sessionToken;
@synthesize isTiming;
@synthesize isCountingDown;
@synthesize downCounter;
@synthesize voltagePercent;
@synthesize storageState;
@synthesize isClippingAvailable;
@synthesize isHeartbeatEnabledForDemander;
@synthesize isCharging = _isCharging;
@synthesize videoCapacity = _videoCapacity;
@synthesize photoCapacity = _photoCapacity;
@synthesize totalStorage = _totalStorage;
@synthesize freeStorage = _freeStorage;
@synthesize sdOID;
@synthesize sdMID;
@synthesize sdPNM;
@synthesize loopRecord;
@synthesize rtspSessionID;
@synthesize isLUTSynchronized;
@synthesize isSettingsSynchronized;

+ (NSString*) formattedCameraUUID:(NSString*)cameraUUID {
    return [[cameraUUID stringByReplacingOccurrencesOfString:@":" withString:@"_"]  stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
}

- (BOOL) isSDCardMounted {
    return (self.storageMounted != StorageMountStateNO);
}

- (id)init
{
    if (self =[super init]) {
        _cond = [[NSRecursiveCondition alloc] init];
        _observers = [[NSMutableArray alloc] init];
        [self setState:CameraClientStateNotConnected];
        self.sessionToken = AMBA_SESSION_TOKEN_INIT;
        self.isTiming = NO;
        self.cameraWorkState = CameraWorkStateIdle;
        self.isShooting = NO;
        self.downCounter = -1;
        self.storageMounted = StorageMountStateOK;
        self.voltagePercent = 100;
        self.storageState = StorageStateAvailable;
        self.isHeartbeatEnabledForDemander = [[NSMutableSet alloc] init];
        _videoCapacity = -1;
        _photoCapacity = -1;
        _totalStorage = -1;
        _freeStorage = -1;
        _isCharging = NO;
        self.isLUTSynchronized = NO;
        self.isSettingsSynchronized = NO;
        self.isConnectedStateNotified = NO;
        _timingQueue = dispatch_queue_create("Timing", DISPATCH_QUEUE_SERIAL);
        [[DATAConnectManager sharedInstance] addObserver:self];
        [[CMDConnectManager sharedInstance] addObserver:self];
    }
    return self;
}

- (int) videoCapacity {
    return _videoCapacity;
}

- (int) photoCapacity {
    return _photoCapacity;
}

/** 添加状态回调监听者 */
- (void)addObserver:(id<MVCameraClientObserver>)observer
{
    [_observers addObject:observer];
}

/** 移除状态回调监听者 */
- (void)removeObserver:(id<MVCameraClientObserver>)observer
{
    [_observers removeObject:observer];
}

/** 连接相机 */
- (void) wakeupCamera {
    AMBARequest* wakeupRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        
    }];
    wakeupRequest.token = self.sessionToken;
    wakeupRequest.msgID = AMBA_MSGID_WAKEUP_CAMERA;
    [[CMDConnectManager sharedInstance] sendRequest:wakeupRequest];
}

- (BOOL) connectCamera:(NSString*)ssid {
    if ([[WiFiConnectManager wifiSSID] isEqualToString:ssid])
    {
        [self connectCamera];
        return YES;
    }
    return NO;
}

- (void) connectCamera {
    switch (self.state)
    {
        case CameraClientStateNotConnected:
        case CameraClientStateDisconnecting:
        case CameraClientStateConnected:
        {
            self.state = CameraClientStateConnecting;
            if ([[CMDConnectManager sharedInstance] openConnection])
            {
                [self cmdConnectionStateChanged:CmdSocketStateReady oldState:CmdSocketStateReady object:nil];
            }
        }
            break;
        default:
            break;
    }
}

- (void) disconnectCamera {
    [self disconnectCamera:(CameraDisconnectReason)0];
}

- (void) disconnectCamera:(CameraDisconnectReason)reason {
    DoctorLog(@"#Disconnect# Begin disconnectCamera");
    [[DATAConnectManager sharedInstance] closeConnection];
    
    if (CmdSocketStateNotReady == [CMDConnectManager sharedInstance].state)
    {
        DoctorLog(@"#Disconnect# End Return");
        [self setState:CameraClientStateNotConnected object:@(reason)];
        return;
    }
    
    self.state = CameraClientStateDisconnecting;
    void(^callback)() = ^() {
        [self setState:CameraClientStateNotConnected object:@(reason)];
        DoctorLog(@"#Disconnect# End");
        [[CMDConnectManager sharedInstance] closeConnection:@(reason)];
    };
    AMBARequest* stopSessionRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        DoctorLog(@"#Disconnect# Response");
        callback();
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        DoctorLog(@"#Disconnect# Error");
        callback();
    }];
    stopSessionRequest.token = self.sessionToken;
    stopSessionRequest.msgID = AMBA_MSGID_STOP_SESSION;
    [[CMDConnectManager sharedInstance] sendRequestAndClearOthers:stopSessionRequest];
}

-(NSString *) currentConnectingSSID {
    return [WiFiConnectManager wifiSSID];
}

-(NSArray<MVCameraDevice *> *) allStoredDevices
{
    NSMutableArray * devices = [[NSMutableArray alloc] init];
    __block RLMResults * results;
    [[RealmSerialQueue shareRealmQueue] sync:^{
        results = [[MVCameraDevice objectsWhere:@"DBUuid != ''"] sortedResultsUsingProperty:@"DBLastSyncTime" ascending:YES];
//        [results sortedResultsUsingProperty:@"DBLastSyncTime" ascending:YES];
        int currentDeviceIndex = -1;
        int cameraClientState = self.state;
        
        WiFiConnectManager* wifiMgr = [WiFiConnectManager sharedInstance];
        for (int i=(int)results.count-1; i>=0; --i)
        {
            MVCameraDevice* device = results[i];
            device.connectionState = 0;
            if ([wifiMgr isWiFiReachable] && [[WiFiConnectManager wifiSSID] isEqualToString:device.SSID])
            {
                currentDeviceIndex = (int)results.count-1-i;
                device.connectionState |= STATE_WIFI_CONNECTED;
                
                if (self.connectingCamera != nil && [self.connectingCamera.uuid isEqualToString:device.uuid])
                {
                    if (![self.connectingCamera shouldSetWiFiPassword])
                    {
                        device.connectionState |= STATE_SESSION_CONNECTED;
                    }
                }
                else if (cameraClientState == CameraClientStateConnecting)
                {
                    device.connectionState |= STATE_SESSION_CONNECTING;
                }
            }
            
            [devices addObject:device];
        }
        
        if (currentDeviceIndex >= 0)
        {
            [devices exchangeObjectAtIndex:0 withObjectAtIndex:currentDeviceIndex];
        }
    }];
    //    RLMResults* results = [MVCameraDevice allObjects];
    
    return devices;
}
/** 从存储的相机列表中移除 */

-(void) removeStoredDevice:(MVCameraDevice *) device
{
    if (!device)
    {
        return;
    }
    
    if (self.connectingCamera != nil && [self.connectingCamera isEqual:device])
    {
        [self disconnectCamera];
    }
    [device delete];
}
/** 设置相机SSID与密码 */
- (void)setCameraWifi:(NSString *)ssid password:(NSString *)password
{
    //    NSString * param=[NSString stringWithFormat:@"%@:%@%@%@:%@%@",SSID_TAG,ssid,@"\n",PASSWORD_TAG,password,@"\n"];
    AMBASetWifiRequest* request = [[AMBASetWifiRequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        if (response.isRvalOK)
        {
            if (nil != connectingCamera)
            {
                [self.connectingCamera transactionWithBlock:^{
                    self.connectingCamera.SSID = ssid;
                    self.connectingCamera.password = password;
                }];
                self.connectingCamera=[self.connectingCamera save];
            }
            [self sendMessageToHandler:MSG_WIFI_SET arg1:0 arg2:0 object:nil];
        }
        else
        {
            [self sendMessageToHandler:MSG_WIFI_SET arg1:response.rval arg2:0 object:nil];
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        [self sendMessageToHandler:MSG_WIFI_SET arg1:error arg2:0 object:nil];
    }];
    request.token = self.sessionToken;
    request.msgID = AMBA_MSGID_SET_WIFI_NEW;
    request.ssid = ssid;
    request.passwd = password;
    [[CMDConnectManager sharedInstance] sendRequest:request];
}
/** 设置相机拍摄模式
 * mode: 主模式
 * subMode: 子模式
 * param: 子模式下具体设置值，如延时摄像时是倍速数，定时拍照时是倒计时秒数
 */

- (void)setCameraMode:(CameraMode)mode subMode:(CameraSubMode)subMode param:(NSInteger)param
{
    if (!self.connectingCamera)
    {
        return;
    }
    if (self.connectingCamera.cameraMode == mode && self.connectingCamera.cameraSubMode == subMode && self.connectingCamera.cameraSubModeParam == param)
    {
        [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
        return;
    }
    
    int setMainModeParam = -1;
    if (mode != self.connectingCamera.cameraMode)
    {
        if (mode == CameraModePhoto)
        {
            setMainModeParam = AMBA_PARAM_CAMERA_MODE_PHOTO;
//            self.currentMicroParam = 0;
        }
        else if (mode == CameraModeVideo)
        {
            setMainModeParam = AMBA_PARAM_CAMERA_MODE_VIDEO;
            self.currentFilter = nil;
        }
    }
    if (setMainModeParam != -1)
    {
        AMBARequest* setModeRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
            AMBASetCameraModeResponse* setCameraModeResponse = (AMBASetCameraModeResponse*) response;
            if (setCameraModeResponse.isRvalOK)
            {
                int sub_mode = setCameraModeResponse.sub_mode;
                int sub_mode_param = setCameraModeResponse.sub_mode_param;
                [self.connectingCamera transactionWithBlock:^{
                    if (mode == CameraModeVideo)
                    {
                        self.connectingCamera.cameraMode = CameraModeVideo;
                        switch (sub_mode) {
                            case 1:
                                self.connectingCamera.cameraSubMode = CameraSubmodeVideoMicro;
                                self.connectingCamera.cameraSubModeParam = sub_mode_param;
                                break;
                            case 2:
                                self.connectingCamera.cameraSubMode = CameraSubmodeVideoTimelapse;
                                self.connectingCamera.cameraSubModeParam = sub_mode_param;
                                break;
                            case 3:
                                self.connectingCamera.cameraSubMode = CameraSubmodeVideoSlowMotion;
                                self.connectingCamera.cameraSubModeParam = sub_mode_param;
                                break;
                            default:
                                self.connectingCamera.cameraSubMode = CameraSubmodeVideoNormal;
                                self.connectingCamera.cameraSubModeParam = 0;
                                break;
                        }
                    } else {
                        self.connectingCamera.cameraMode = CameraModePhoto;
                        switch (sub_mode) {
                            case 1:
                                self.connectingCamera.cameraSubMode = CameraSubmodePhotoTiming;
                                self.connectingCamera.cameraSubModeParam = sub_mode_param;
                                break;
                            case 2:
                                self.connectingCamera.cameraSubMode = CameraSubmodePhotoInterval;
                                self.connectingCamera.cameraSubModeParam = sub_mode_param;
                                break;
                            case 3:
                                self.connectingCamera.cameraSubMode = CameraSubmodePhotoContinuous;
                                self.connectingCamera.cameraSubModeParam = sub_mode_param;
                                break;
                            case 4:
                                self.connectingCamera.cameraSubMode = CameraSubmodePhotoSurroundExp;
                                self.connectingCamera.cameraSubModeParam = sub_mode_param;
                                break;
                            default:
                                self.connectingCamera.cameraSubMode = CameraSubmodePhotoNormal;
                                self.connectingCamera.cameraSubModeParam = 0;
                                break;
                        }
                    }
                }];
                
                self.connectingCamera = [self.connectingCamera save];
                self.isShooting = NO;
                self.cameraWorkState = CameraWorkStateIdle;
                [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
            }
            else
            {
                [self sendMessageToHandler:MSG_MODE_CHANGED arg1:response.rval arg2:0 object:[NSString stringWithFormat:@"ResponseFail:%ld param:%@",(long)response.rval,response.param]];
            }
        } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
            [self sendMessageToHandler:MSG_MODE_CHANGED arg1:error arg2:0 object:msg];
        } responseClass:AMBASetCameraModeResponse.class];
        setModeRequest.msgID = AMBA_MSGID_SET_CAMERA_MODE;
        setModeRequest.param = [@(setMainModeParam) stringValue];
        setModeRequest.token = self.sessionToken;
        [[CMDConnectManager sharedInstance] sendRequest:setModeRequest];
        
    }
    else
    {
        [self setCameraSubMode:mode subMode:subMode param:(int)param];
    }
}

- (void)setCameraSubMode:(int)mode subMode:(int)subMode param:(int)param
{
    if (mode != CameraModePhoto || subMode != CameraSubmodePhotoFilter)
    {
        self.currentFilter = nil;
    }
    
//    if (mode != CameraModeVideo || subMode != CameraSubmodeVideoMicro)
//    {
//        self.currentMicroParam = 0;
//    }
    
    int msgID = -1;
    switch (mode)
    {
        case CameraModePhoto:
        {
            switch (subMode)
            {
                case CameraSubmodePhotoTiming:
                    msgID = AMBA_MSGID_SET_PHOTO_TIMING_PARAM;
                    break;
                case CameraSubmodePhotoFilter:
                    self.currentFilter = [ImageFilterBean findImageFilterByID:param];
                    break;
                case CameraSubmodePhotoInterval:
                    msgID = AMBA_MSGID_SET_PHOTO_INTERVAL_PARAM;
                    break;
                case CameraSubmodePhotoContinuous:
                    msgID = AMBA_MSGID_SET_PHOTO_CONTINUOUS_PARAM;
                    break;
                case CameraSubmodePhotoSurroundExp:
                    msgID = AMBA_MSGID_SET_PHOTO_SURROUNDEXP_PARAM;
                    break;
                case CameraSubmodePhotoNormal:
                {
                    switch (self.connectingCamera.cameraSubMode)
                    {
                        case CameraSubmodePhotoTiming:
                            msgID = AMBA_MSGID_SET_PHOTO_TIMING_PARAM;
                            break;
                        case CameraSubmodePhotoInterval:
                            msgID = AMBA_MSGID_SET_PHOTO_INTERVAL_PARAM;
                            break;
                        case CameraSubmodePhotoContinuous:
                            msgID = AMBA_MSGID_SET_PHOTO_CONTINUOUS_PARAM;
                            break;
                        case CameraSubmodePhotoSurroundExp:
                            msgID = AMBA_MSGID_SET_PHOTO_SURROUNDEXP_PARAM;
                            break;
                    }
                    break;
                }
                default:
                    break;
            }
        }
            break;
        case CameraModeVideo:
        {
            switch (subMode)
            {
                case CameraSubmodeVideoTimelapse:
                    msgID = AMBA_MSGID_SET_VIDEO_TIMELAPSE_PARAM;
                    break;
                case CameraSubmodeVideoMicro:
                    msgID = AMBA_MSGID_SET_VIDEO_MICRO_PARAM;
                    break;
                case CameraSubmodeVideoFilter:
                    msgID = AMBA_MSGID_SET_VIDEO_FILTER;
                    break;
                case CameraSubmodeVideoSlowMotion:
                    msgID = AMBA_MSGID_SET_VIDEO_SLOWMOTION_PARAM;
                    break;
                case CameraSubmodeVideoNormal:
                {
                    switch (self.connectingCamera.cameraSubMode)
                    {
                        case CameraSubmodeVideoTimelapse:
                            msgID = AMBA_MSGID_SET_VIDEO_TIMELAPSE_PARAM;
                            break;
                        case CameraSubmodeVideoMicro:
                            msgID = AMBA_MSGID_SET_VIDEO_MICRO_PARAM;
                            break;
                        case CameraSubmodeVideoSlowMotion:
                            msgID = AMBA_MSGID_SET_VIDEO_SLOWMOTION_PARAM;
                            break;
                    }
                    break;
                }
                default:
                    break;
            }
        }
            break;
        default:
            break;
    }
    
    [self.connectingCamera transactionWithBlock:^{
        self.connectingCamera.cameraMode = (CameraMode)mode;
        self.connectingCamera.cameraSubMode = (CameraSubMode)subMode;
        self.connectingCamera.cameraSubModeParam = param;
    }];
    self.connectingCamera = [self.connectingCamera save];
    
    if (msgID != -1)
    {
        AMBARequest* setSubModeRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
            if (response.isRvalOK)
            {
//                if (mode == CameraModeVideo
//                    && subMode == CameraSubmodeVideoMicro) {
//                    self.currentMicroParam = (int) self.connectingCamera.cameraSubModeParam;
//                }
                
                [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
            }
            else
            {
                [self sendMessageToHandler:MSG_MODE_CHANGED arg1:response.rval arg2:0 object:[NSString stringWithFormat:@"ResponseFail:%ld param:%@",(long)response.rval,response.param]];
            }
            
        } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
            [self sendMessageToHandler:MSG_MODE_CHANGED arg1:error arg2:0 object:msg];
        } responseClass:nil];
        setSubModeRequest.token = self.sessionToken;
        setSubModeRequest.msgID = msgID;
        setSubModeRequest.param = [@(param) stringValue];
        [[CMDConnectManager sharedInstance] sendRequest:setSubModeRequest];
        
    }
    else
    {
        [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
    }
}

-(void) startShooting {
    [self startShootingWithTimeoutMills:0 withAudio:YES];
}

-(void) startShootingWithAudio:(BOOL)withAudio {
    [self startShootingWithTimeoutMills:0 withAudio:withAudio];
}

-(void) startShootingWithTimeoutMills:(int)timeoutMills {
    [self startShootingWithTimeoutMills:timeoutMills withAudio:YES];
}

- (void) handleIntervalPhotoResponse:(AMBAResponse*)response {
    AMBAShootPhotoIntervalResponse* shootPhotoIntervalResponse = (AMBAShootPhotoIntervalResponse*) response;
    
    if (CameraModePhoto != self.connectingCamera.cameraMode || CameraSubmodePhotoInterval != self.connectingCamera.cameraSubMode || (shootPhotoIntervalResponse.time > 0 && shootPhotoIntervalResponse.time != self.connectingCamera.cameraSubModeParam))
    {
        [self.connectingCamera transactionWithBlock:^{
            self.connectingCamera.cameraMode = CameraModePhoto;
            self.connectingCamera.cameraSubMode = CameraSubmodePhotoInterval;
            if (shootPhotoIntervalResponse.time > 0)
            {
                self.connectingCamera.cameraSubModeParam = shootPhotoIntervalResponse.time;
            }
        }];
        self.connectingCamera = [self.connectingCamera save];
        [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
    }
    
    int count1 = [response.param intValue];
    if (count1 == -1)
    {
        //空闲时停止间隔拍照直接结束
        self.isShooting = NO;
        self.cameraWorkState = CameraWorkStateIdle;
        self.connectingCamera.capIntervalNum = 0;
        [self sendMessageToHandler:MSG_STOP_SHOOTING arg1:0 arg2:0 object:nil];
    }
    else if (count1 > -1)
    {
        self.isShooting = YES;
        self.cameraWorkState = CameraWorkStatePhotoingInterval;
        self.connectingCamera.capIntervalNum = count1;
        [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:count1 object:nil];
    }else
    {
        //忙的时候停止间隔拍照需要等到此时拍照结束才可以（文件存储成功）
        self.connectingCamera.capIntervalNum = count1;
    }
}

- (void) handleSurroundexpPhotoResponse:(AMBAResponse*)response {
    
    AMBAShootPhotoSurroundexpResponse * shootPhotoSurroundexpResponse = (AMBAShootPhotoSurroundexpResponse*) response;
    int sur_exp = [shootPhotoSurroundexpResponse.sur_exp intValue];
    if (CameraModePhoto != self.connectingCamera.cameraMode || CameraSubmodePhotoSurroundExp != self.connectingCamera.cameraSubMode || (sur_exp > 0 && sur_exp != self.connectingCamera.cameraSubModeParam))
    {
        [self.connectingCamera transactionWithBlock:^{
            self.connectingCamera.cameraMode = CameraModePhoto;
            self.connectingCamera.cameraSubMode = CameraSubmodePhotoSurroundExp;
            if (sur_exp > 0)
            {
                self.connectingCamera.cameraSubModeParam = sur_exp;
            }
        }];
        self.connectingCamera = [self.connectingCamera save];
        [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
    }
    
    int count1 = [response.param intValue];
    self.surroundExpNumberOfPhoto = count1;
    self.isShooting = YES;
    self.cameraWorkState = CameraWorkStatePhotoingSurroundExp;
    self.connectingCamera.capIntervalNum = count1;
    [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:count1 object:nil];
}

- (void) handleTimingPhotoResponse:(AMBAResponse*)response {
    self.cameraWorkState = CameraWorkStatePhotoingDelayed;
    
    int timingSeconds = [(NSNumber *)response.param intValue];
    if (CameraModePhoto != self.connectingCamera.cameraMode || CameraSubmodePhotoTiming != self.connectingCamera.cameraSubMode || (timingSeconds > 0 && timingSeconds != self.connectingCamera.cameraSubModeParam))
    {
        [self.connectingCamera transactionWithBlock:^{
            self.connectingCamera.cameraMode = CameraModePhoto;
            self.connectingCamera.cameraSubMode = CameraSubmodePhotoTiming;
            self.connectingCamera.cameraSubModeParam = timingSeconds;
        }];
        self.connectingCamera = [self.connectingCamera save];
        [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
    }
    
    self.isShooting = YES;
    [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
    [self startCountDown:(int)self.connectingCamera.cameraSubModeParam];
}

/** 启动摄像或拍照 */
-(void) startShootingWithTimeoutMills:(int)timeoutMills withAudio:(BOOL)withAudio
{NSLog(@"#Douin# startShooting begin");
    if (!self.connectingCamera || _isShooting)
    {
        return;
    }
    
    int msgID = -1;
    switch (self.connectingCamera.cameraMode)
    {
        case CameraModePhoto:
        {
//            if (self.isShooting)
//                return;
            Class responseClass = nil;
            switch (self.connectingCamera.cameraSubMode)
            {
                case CameraSubmodePhotoTiming:
                    msgID = AMBA_MSGID_SHOOT_PHOTO_TIMING;
                    break;
                case CameraSubmodePhotoInterval:
                    msgID = AMBA_MSGID_SHOOT_PHOTO_INTERVAL;
                    responseClass = AMBAShootPhotoIntervalResponse.class;
                    break;
                case CameraSubmodePhotoContinuous:
                    msgID = AMBA_MSGID_SHOOT_PHOTO_CONTINUOUS;
                    break;
                case CameraSubmodePhotoSurroundExp:
                    msgID = AMBA_MSGID_START_PHOTO_SURROUNDEXP;
                    responseClass = AMBAShootPhotoSurroundexpResponse.class;
                    break;
                default:
                    msgID = AMBA_MSGID_SHOOT_PHOTO_NORMAL;
                    break;
            }
            
            self.isShooting = YES;
            
            
            AMBARequest* takePhotoRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
                if (response.isRvalOK)
                {
                    //如果是停止间隔拍照就不需要再发这个状态了
                    if (msgID == AMBA_MSGID_SHOOT_PHOTO_INTERVAL)
                    {
                        [self handleIntervalPhotoResponse:response];
                    }
                    else if (msgID == AMBA_MSGID_SHOOT_PHOTO_TIMING)
                    {
                        [self handleTimingPhotoResponse:response];
                    }else if (msgID == AMBA_MSGID_START_PHOTO_SURROUNDEXP)
                    {
                        [self handleSurroundexpPhotoResponse:response];
                    }
                    else
                    {
                        [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
                    }
                }
                else
                {
                    self.isShooting = NO;
                    [self sendMessageToHandler:MSG_BEGIN_SHOOTING_ERROR arg1:response.rval arg2:0 object:nil];
                }
            } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
                self.isShooting = NO;
                NSLog(@"#Callback# MSG_BEGIN_SHOOTING on startShooting takePhotoRequest error");
                [self sendMessageToHandler:MSG_BEGIN_SHOOTING_ERROR arg1:error arg2:0 object:nil];
            } responseClass:responseClass];
            takePhotoRequest.token = self.sessionToken;
            takePhotoRequest.msgID = msgID;
            takePhotoRequest.timeout = timeoutMills;
            [[CMDConnectManager sharedInstance] sendRequest:takePhotoRequest];
        }
            break;
        case CameraModeVideo:
        {
            switch (self.connectingCamera.cameraSubMode)
            {
                case CameraSubmodeVideoTimelapse:
                    msgID = AMBA_MSGID_START_VIDEO_TIMELAPSE;
                    break;
                case CameraSubmodeVideoMicro:
                    msgID = AMBA_MSGID_START_VIDEO_MICRO;
//                    self.currentMicroParam = (int)connectingCamera.cameraSubModeParam;
                    break;
                case CameraSubmodeVideoSlowMotion:
                    msgID = AMBA_MSGID_START_VIDEO_SLOWMOTION;
                    break;
                default:
                    msgID = AMBA_MSGID_START_VIDEO_NORMAL;
                    break;
            }
            
            AMBARequest* startShootingRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
                NSLog(@"#Douin# startShooting response received");
                if (response.isRvalOK)
                {
//                    isVideoCapturing = YES;
                    self.isShooting = YES;
                    [self startTimer:0 delaySeconds:0];
                    NSLog(@"#Callback# MSG_BEGIN_SHOOTING on startShooting startShootingRequest OK");
                    [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
                }
                else
                {
                    self.isShooting = NO;
                    NSLog(@"#Callback# MSG_BEGIN_SHOOTING on startShooting startShootingRequest failed");
                    [self sendMessageToHandler:MSG_BEGIN_SHOOTING_ERROR arg1:response.rval arg2:0 object:nil];
                    
                    [[MVMediaManager sharedInstance] resumeAllDownloadings];
                }
            } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
                self.isShooting = NO;
                NSLog(@"#Callback# MSG_BEGIN_SHOOTING on startShooting startShootingRequest error");
                [self sendMessageToHandler:MSG_BEGIN_SHOOTING_ERROR arg1:error arg2:0 object:nil];
                
                [[MVMediaManager sharedInstance] resumeAllDownloadings];
            } responseClass:nil];
            
//            if (!isVideoCapturing) {
            if (!_isShooting) {
                _isShooting = YES;
#ifdef PAUSE_DOWNLOADING_WHILE_CAPTURING
                [[MVMediaManager sharedInstance] pauseAllDownloadings];
#endif
                startShootingRequest.token = self.sessionToken;
                startShootingRequest.msgID = msgID;
                startShootingRequest.timeout = timeoutMills;
                startShootingRequest.param = [@(withAudio ? 0:1) stringValue];
                [[CMDConnectManager sharedInstance] sendRequest:startShootingRequest];
                NSLog(@"#Douin# startShooting request sent");
            }
        }
            break;
        default:
            break;
    }
}

- (NSString *)remoteFilePathOfRTOSPath:(NSString *)rtosFilePath
{
    rtosFilePath = [rtosFilePath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    rtosFilePath = [rtosFilePath stringByReplacingOccurrencesOfString:@"C:/" withString:@"/tmp/SD0/"];
    return rtosFilePath;
}

/** 停止摄像或拍照(拍照主要是间隔拍照的停止) */
- (void)stopShooting
{NSLog(@"#Douyin# stopShooting begin");
    if (nil == connectingCamera || !_isShooting) {
        return;
    }
    
    switch (self.connectingCamera.cameraMode)
    {
        case CameraModePhoto:
        {
            
            int msgID = -1;
            Class responseClass = nil;
            switch (self.connectingCamera.cameraSubMode)
            {
                case CameraSubmodePhotoTiming:
                    msgID = AMBA_MSGID_SHOOT_PHOTO_TIMING;
                    break;
                case CameraSubmodePhotoInterval:
                    msgID = AMBA_MSGID_SHOOT_PHOTO_INTERVAL;
                    responseClass = AMBAShootPhotoIntervalResponse.class;
                    break;
                case CameraSubmodePhotoContinuous:
                    msgID = AMBA_MSGID_SHOOT_PHOTO_CONTINUOUS;
                    break;
                case CameraSubmodePhotoSurroundExp:
                    msgID = AMBA_MSGID_START_PHOTO_SURROUNDEXP;
                    responseClass = AMBAShootPhotoSurroundexpResponse.class;
                    break;
                default:
                    msgID = AMBA_MSGID_SHOOT_PHOTO_NORMAL;
                    break;
            }
            AMBARequest* takePhotoRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
                if (response.isRvalOK)
                {NSLog(@"#Callback# MSG_BEGIN_SHOOTING on startShooting takePhotoRequest OK");
                    if (self.connectingCamera.cameraSubMode == CameraSubmodePhotoInterval)
                    {
                        [self handleIntervalPhotoResponse:response];
                    }else
                    {
                        [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
                    }
                }
                else
                {
                    self.isShooting = YES;
                }
            } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
                self.isShooting = YES;
                NSLog(@"#Callback# MSG_BEGIN_SHOOTING on startShooting takePhotoRequest error");
            } responseClass:responseClass];
            takePhotoRequest.token = self.sessionToken;
            takePhotoRequest.msgID = msgID;
            [[CMDConnectManager sharedInstance] sendRequest:takePhotoRequest];
        }
            break;
        case CameraModeVideo:
        {
            AMBARequest* stopShootingRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
                NSLog(@"#Douyin# stopShooting response received");
                if (response.isRvalOK)
                {
                    self.isShooting = NO;
                    [self stopTimer];
                    [self sendMessageToHandler:MSG_STOP_SHOOTING arg1:0 arg2:0 object:response.param];
                }
                else
                {
                    [self sendMessageToHandler:MSG_STOP_SHOOTING arg1:response.rval arg2:0 object:response.param];
                }
            } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
                [self sendMessageToHandler:MSG_STOP_SHOOTING arg1:error arg2:0 object:msg];
            } responseClass:nil];
            
            stopShootingRequest.ambaRequestSent = ^() {
//                [self stopTimer];
            };
//            if (isVideoCapturing)
            if (_isShooting)
            {
//                _currentMicroParam = 0;
                stopShootingRequest.token = self.sessionToken;
                stopShootingRequest.msgID = AMBA_MSGID_STOP_VIDEO;
                [[CMDConnectManager sharedInstance] sendRequest:stopShootingRequest];
                NSLog(@"#Douyin# stopShooting request sent");
            }
        }
            break;
        default:
            break;
    }
}
/** 启动录剪，返回值表示是否成功 */
- (BOOL)cutClip
{
    return true;
}

- (void) setVideoSegmentSeconds:(int)seconds {
    AMBARequest* setVideoSegmentsSeconds = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        if (response.isRvalOK)
        {
            
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        
    }];
    setVideoSegmentsSeconds.token = self.sessionToken;
    setVideoSegmentsSeconds.msgID = AMBA_MSGID_SET_VIDEO_SEGMENT_SECONDS;
    setVideoSegmentsSeconds.param = [@(seconds) stringValue];
    [[CMDConnectManager sharedInstance] sendRequest:setVideoSegmentsSeconds];
}

- (void) setVideoRecordingSpeed:(VideoRecordingSpeed)speed {
    AMBARequest* setVideoRecordingSpeedRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        if (response.isRvalOK)
        {
            
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        
    }];
    setVideoRecordingSpeedRequest.token = self.sessionToken;
    setVideoRecordingSpeedRequest.msgID = AMBA_MSGID_SET_VIDEO_RECORDING_SPEED;
    setVideoRecordingSpeedRequest.param = [@(speed) stringValue];
    [[CMDConnectManager sharedInstance] sendRequest:setVideoRecordingSpeedRequest];
}

- (void) setLensUsageMode:(LensUsageMode)mode {
    AMBARequest* setLensUsageModeRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        if (response.isRvalOK)
        {
            
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        
    }];
    setLensUsageModeRequest.token = self.sessionToken;
    setLensUsageModeRequest.msgID = AMBA_MSGID_SET_LENS_USAGE;
    setLensUsageModeRequest.param = [@(mode) stringValue];
    [[CMDConnectManager sharedInstance] sendRequest:setLensUsageModeRequest];
}

- (void) setVideoRecordingMBPS:(int)Mbps {
    AMBARequest* setMbpsRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        if (response.isRvalOK)
        {
            
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        
    }];
    setMbpsRequest.token = self.sessionToken;
    setMbpsRequest.msgID = AMBA_MSGID_SET_VIDEO_MBPS;
    setMbpsRequest.param = [@(Mbps) stringValue];
    [[CMDConnectManager sharedInstance] sendRequest:setMbpsRequest];
}

- (void) setCurrentApp:(int)appID {
    AMBARequest* setAppRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        if (response.isRvalOK)
        {
            
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        
    }];
    setAppRequest.token = self.sessionToken;
    setAppRequest.msgID = AMBA_MSGID_SET_CURRENT_APP_ID;
    setAppRequest.param = [@(appID) stringValue];
    [[CMDConnectManager sharedInstance] sendRequest:setAppRequest];
}

- (void)setSettingOption:(int)optionUID paramUID:(int)paramUID
{
    SettingTreeNode * optionNode = [MVCameraDevice findOptionNodeByUID:optionUID];
    if (optionNode == nil)
    {
        return;
    }
    
    switch (optionNode.viewType)
    {
        case ViewTypeAction:
            [self doSettingAction:optionUID];
            break;
        case ViewTypeSingleSelection:
        case ViewTypeSliderSelection:
        {
            SettingTreeNode* paramNode = [optionNode findSubOptionByUID:paramUID];
            if (SettingNodeIDCameraPreviewMode == optionNode.uid)
            {
                [optionNode setSelectedSubOptionUID:paramUID];
                int previewMode = paramNode.msgID;
                if (connectingCamera)
                {
                    [connectingCamera transactionWithBlock:^{
                        connectingCamera.cameraPreviewMode = previewMode;
                    }];
                    [connectingCamera save];
                }
                [self sendMessageToHandler:MSG_SETTING_CHANGED arg1:optionUID arg2:paramUID object:nil];
            }else if (SettingNodeIDCameraGPS == optionNode.uid)
            {
                [optionNode setSelectedSubOptionUID:paramUID];
                [helper writeProfileString:GPSPARAM value:[NSString stringWithFormat:@"%d",paramNode.msgID]];
                [self sendMessageToHandler:MSG_SETTING_CHANGED arg1:optionUID arg2:paramUID object:nil];
            }
            else if (SettingNodeIDCameraTransportProtocol == optionNode.uid)
            {
                [optionNode setSelectedSubOptionUID:paramUID];
                [helper writeProfileString:TRANSPORTPROTOCOL value:[NSString stringWithFormat:@"%d",paramNode.msgID]];
                [self sendMessageToHandler:MSG_SETTING_CHANGED arg1:optionUID arg2:paramUID object:nil];
            }
            else
            {
                AMBARequest* settingRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
                    if (response.isRvalOK)
                    {
                        if (optionNode && paramNode)
                        {
                            [optionNode setSelectedSubOptionUID:paramUID];
                        }
                        
                        if (optionUID == SettingNodeIDVideoFrameRateSetting
                            || optionUID == SettingNodeIDPhotoResolutionSetting)
                        {
                            [self synchronizeWorkStateAndCameraMode];
                            [self synchronizeCameraStorageAllState];
                        }
                        else if (SettingNodeIDCameraLoopSetting == optionUID)
                        {
                            self.loopRecord = paramNode.msgID;
                        }
                        
                        if (SettingNodeIDVideoFrameRateSetting == optionUID)
                        {
                            SettingTreeNode* subNode = [optionNode findSubOptionByUID:paramUID];
                            self.connectingCamera.videoCaptureResolution = subNode.msgID;
                        }
                        
                        [self sendMessageToHandler:MSG_SETTING_CHANGED arg1:optionUID arg2:paramUID object:nil];
                    }
                    else
                    {
                        [self sendMessageToHandler:MSG_SETTING_CHANGED arg1:optionUID arg2:paramUID object:[NSString stringWithFormat:@"ResponseFail:%ld",(long)response.rval]];
                    }
                } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
                    [self sendMessageToHandler:MSG_SETTING_CHANGED arg1:error arg2:0 object:[NSString stringWithFormat:@"ResponseFail:%@",msg]];
                }];
                settingRequest.token = self.sessionToken;
                settingRequest.msgID = optionNode.msgID;
                int paramMsgID = paramNode.msgID;
                settingRequest.param = [@(paramMsgID) stringValue];
                [[CMDConnectManager sharedInstance] sendRequest:settingRequest];
            }
        }
            break;
        case ViewTypeReadOnly:
            break;
        default:
            break;
    }
}

- (int) cameraPreviewMode {
    if (connectingCamera)
        return connectingCamera.cameraPreviewMode;
    else
        return PanoramaDisplayModeStereoGraphic;
}

- (int) cameraGPSParam {
    NSString * gpsParam = [helper readProfileString:GPSPARAM];
    return [gpsParam intValue];
}
- (int)cameraTransportProtocol
{
    NSString * TransportProtocol = [helper readProfileString:TRANSPORTPROTOCOL];
    return [TransportProtocol intValue];
}
- (NSArray<ImageFilterBean *>*) imageFilters
{
    return [ImageFilterBean allImageFilters];
}

- (void)doSettingAction:(int)optionUID
{
    int msgID = -1;
    NSString* param = nil;
    switch (optionUID)
    {
        case SettingNodeIDFormatSD:
        {
            msgID = AMBA_MSGID_FORMAT_SD;
            param = @"c";
            break;
        }
        case SettingNodeIDCameraPowerOff:
            msgID = AMBA_MSGID_CLOSE_CAMERA;
            break;
        case SettingNodeIDResetToDefaultSettings:
        {
            msgID = AMBA_MSGID_RESET_DEFAULT_SETTINGS;
            break;
        }
            
        default:
            break;
    }
    if (msgID != -1)
    {
        AMBARequest* setParamRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
            if (AMBA_MSGID_FORMAT_SD == response.msgID)
            {
                if (response.isRvalOK)
                {
                    [self synchronizeCameraStorageAllState];
                    [self sendMessageToHandler:MSG_RECEIVE_NOTIFICATION arg1:AMBA_MSGID_FORMAT_SD arg2:0 object:nil];
                    [[MVMediaManager sharedInstance] cameraMedias:YES];
                }
                else if (response.rval == AMBA_RVAL_ERROR_NO_SDCARD)
                {
                    [self sendMessageToHandler:MSG_RECEIVE_NOTIFICATION arg1:AMBA_RVAL_ERROR_NO_SDCARD arg2:0 object:nil];
                }
                else if (response.rval == AMBA_RVAL_ERROR_BUSY)
                {
                    [self sendMessageToHandler:MSG_RECEIVE_NOTIFICATION arg1:AMBA_RVAL_ERROR_BUSY arg2:0 object:nil];
                }
            }
            else if (response.msgID == AMBA_MSGID_CLOSE_CAMERA)
            {
                [self disconnectCamera];
            }
        } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        }];
        setParamRequest.msgID = msgID;
        setParamRequest.token = self.sessionToken;
        setParamRequest.param = param;
        [[CMDConnectManager sharedInstance] sendRequest:setParamRequest];
    }
}

- (void) restartCameraWiFi {
    AMBARequest* restartWiFiRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        if (response.isRvalOK)
        {
            [self sendMessageToHandler:MSG_WIFI_RESTART arg1:0 arg2:0 object:nil];
        }
        else
        {
            [self sendMessageToHandler:MSG_WIFI_RESTART arg1:response.rval arg2:0 object:[NSString stringWithFormat:@"ResponseFail:%ld param:%@", (long)response.rval, response.param]];
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        [self sendMessageToHandler:MSG_WIFI_RESTART arg1:error arg2:0 object:msg];
    }];
    restartWiFiRequest.token = self.sessionToken;
    restartWiFiRequest.msgID = AMBA_MSGID_WIFI_RESTART;
    [[CMDConnectManager sharedInstance] sendRequest:restartWiFiRequest];
}

- (void)startSessionAndSyncCamera
{
    self.isLUTSynchronized = NO;
    self.isSettingsSynchronized = NO;
    self.isConnectedStateNotified = NO;
    __block AMBARequest * getSerialIDRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        //*
        if (response.isRvalOK) {
            NSString* UUID = [self.class formattedCameraUUID:(NSString*) response.param];
            NSString* SSID = [WiFiConnectManager wifiSSID];
            __block MVCameraDevice* device = [MVCameraDevice selectWithUUID:UUID];
            //*///!!!TO BE OPTIMIZED:
            MVCameraDevice* dbDevice = [MVCameraDevice create];///???
            [dbDevice transactionWithBlock:^{
                if (device)
                {
                    [dbDevice copy:device];
                }
                dbDevice.uuid = UUID;
                dbDevice.SSID = SSID;
                dbDevice.lastSyncTime = [NSDate date];
            }];
            dbDevice = [dbDevice save];
            device = dbDevice;
            /*/
            if (!device)
            {
                device = [MVCameraDevice create];
            }
            [device transactionWithBlock:^{
                device.uuid = UUID;
                device.SSID = SSID;
                device.lastSyncTime = [NSDate date];
            }];
            device = [device save];
            //*/
            
            AMBARequest* getWiFiSettingsRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
                if (response.isRvalOK)
                {
                    NSString* param = (NSString *)[response param];
                    NSArray* params = [param componentsSeparatedByString:@"\n"];
                    for (NSString * str in params)
                    {
                        if (!str) continue;
                        
                        if ([str containsString:PASSWORD_TAG])
                        {
                            NSArray* args = [str componentsSeparatedByString:@"="];
                            if (args.count >= 2)
                            {
                                device.password = args[1];
                            }
                        }
                        else if ([str containsString:APPUBLIC_TAG])
                        {
                            NSArray* args = [str componentsSeparatedByString:@"="];
                            if (args.count >= 2)
                            {
                                if ([[args[1] lowercaseString] isEqualToString:@"yes"])
                                {
                                    device.password = @"";
                                }
                            }
                        }
                        else if ([str containsString:SSID_TAG])
                        {
                            NSArray* args = [str componentsSeparatedByString:@"="];
                            if (args.count >= 2)
                            {
                                device.SSID = args[1];
                            }
                        }
                    }
                    
                    self.connectingCamera = device;
                    @try
                    {
                        self.connectingCamera = [self.connectingCamera save];
                        //                        MVCameraDevice * deviceTemp=[[MVCameraDevice alloc] init];
                        //                        [deviceTemp copy:device];
                        //                        device=deviceTemp;
                        ///!!!new Update(MVCameraDevice.class).set(MVCameraDevice.DB_KEY_SSID + " = '" + device.getSSID() + "'," + MVCameraDevice.DB_KEY_PASSWORD + " = '" + device.password + "'").where(MVCameraDevice.DB_KEY_UUID + " = '" + connectingCamera.getUUID() + "'").execute();
                    }
                    @catch (NSException *exception)
                    {
                    }
                    __block BOOL shouldSetWiFiPassword;
                    [[RealmSerialQueue shareRealmQueue] sync:^{
                        shouldSetWiFiPassword=[self.connectingCamera shouldSetWiFiPassword];
                    }];
                    if (shouldSetWiFiPassword)
                    {
                        MVCameraDevice* deviceTemp = [MVCameraDevice create];///???[[MVCameraDevice alloc] init];
                        [deviceTemp transactionWithBlock:^{
                            [deviceTemp copy:device];
                        }];
                        self.connectingCamera = deviceTemp;
                        [device delete];
                        
                        @synchronized (self)
                        {
                            if (!self.isConnectedStateNotified)
                            {
                                self.isConnectedStateNotified = YES;
                                [self setState:CameraClientStateConnected object:device];
                            }
                        }
                    }
                    else
                    {
                        //device=[device save];
                        
                        NSString * localIP = [WiFiConnectManager wifiClientIP];
                        AMBARequest* setClientInfoRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
                            if (response.isRvalOK)
                            {
                                AMBASetClientInfoResponse* setClientInfoResponse = (AMBASetClientInfoResponse*) response;
                                //device.firmwareUpdateState = (FirmwareUpdateState) setClientInfoResponse.update;
                                self.connectingCamera.firmwareUpdateState = (FirmwareUpdateState) setClientInfoResponse.update;
                                self.rtspSessionID = (uint32_t) setClientInfoResponse.session_id;
                                
                                ///!!![self checkAndSynchronizeLUT:connectingCamera.uuid md5:response.param];
                                // Synchronize Camera Work State & Mode:
                                [self synchronizeWorkStateAndCameraMode];
                                // Synchronize Time:
                                [self synchronizeCameraTime];
                                //                        // Synchronize BatteryState:
                                //                        [self synchronizeCameraBatteryState];
                                
                                // Synchronize storage:
                                self.storageState = StorageStateAvailable;
                                [self synchronizeCameraStorageAllState];
                                
#ifdef DEBUG_UPLOADING
                                NSString * fileName = @"VID_20170113_103846AA.MP4";
                                NSString * filePath = [z_Sandbox documentPath:fileName];
                                NSString* remotePath = @"/tmp/SD0/uploaded.mp4";
                                NSLog(@"filePath%@",filePath);
                                MVUploadCallback* callback = [[MVUploadCallback alloc] initWithCompletion:^{
                                    NSLog(@"MVUploadCallback complete");
                                } cancelation:^{
                                    NSLog(@"MVUploadCallback cancel");
                                } failure:^(MVUploadError error) {
                                    NSLog(@"MVUploadCallback failure : error = %d", error);
                                } progress:^(int progress) {
                                    NSLog(@"MVUploadCallback progress:%d", progress);
                                }];
                                UploadRCFirmwareTask* task = [[UploadRCFirmwareTask alloc] initWithLocalPath:filePath remotePath:remotePath callback:callback];
                                [[MVCameraUploadManager sharedInstance] uploadFirmware:task];
#endif
                                
                                // Synchronize Settings:
                                [self synchronizeCameraSettings];
                                
                                [self checkAndSynchronizeLUT:connectingCamera.uuid md5:response.param];
                            }
                            else
                            {
                                [self disconnectCamera];
                            }
                            
                        } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
                            [self disconnectCamera];
                            
                        } responseClass:AMBASetClientInfoResponse.class];
                        setClientInfoRequest.msgID = AMBA_MSGID_SET_CLNT_INFO;
                        setClientInfoRequest.type = AMBA_SESSION_TYPE;
                        setClientInfoRequest.token = self.sessionToken;
                        setClientInfoRequest.param = localIP;
                        CMDConnectManager * cmdConnectManager=[CMDConnectManager sharedInstance];
                        [cmdConnectManager sendRequest:setClientInfoRequest];
                    }
                }
                else
                {
                    [self disconnectCamera];
                }
            } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
                [self disconnectCamera];
            } responseClass:nil];
            
            getWiFiSettingsRequest.msgID = AMBA_MSGID_GET_WIFI_SETTING;
            getWiFiSettingsRequest.token = self.sessionToken;
            [[CMDConnectManager sharedInstance] sendRequest:getWiFiSettingsRequest];
        } else {
            [self disconnectCamera];
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        [self disconnectCamera];
    } responseClass:[AMBAGetWiFiStatusResponse class]];
    getSerialIDRequest.msgID = AMBA_MSGID_GET_SN;
    
    AMBARequest * startSessionRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        if (response.isRvalOK)
        {
            self.sessionToken = [(NSNumber *)response.param intValue];
            getSerialIDRequest.token = self.sessionToken;
            [[CMDConnectManager sharedInstance] sendRequest:getSerialIDRequest];
        }
        else if (AMBA_RVAL_START_SESSION_DENIED == response.rval)
        {
            self.sessionToken = AMBA_SESSION_TOKEN_INIT;
            [self disconnectCamera:CameraDisconnectReasonOtherClient];
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        [self disconnectCamera];
    } responseClass:nil];
    startSessionRequest.token = AMBA_SESSION_TOKEN_INIT;
    startSessionRequest.msgID = AMBA_MSGID_START_SESSION;
    [[CMDConnectManager sharedInstance] sendRequest:startSessionRequest];
    
}

- (void)synchronizeCameraSettings
{
    AMBARequest* getAllSettingRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        AMBAGetAllSettingParamResponse* paramResponse = (AMBAGetAllSettingParamResponse*) response;
        if (paramResponse.isRvalOK && self.connectingCamera)
        {
            self.connectingCamera.videoCaptureResolution = paramResponse.v_res;
            [self.connectingCamera transactionWithBlock:^{
                self.connectingCamera.jpgCaptured = paramResponse.cam_jpg;
                self.connectingCamera.mp4Captured = paramResponse.cam_mp4;
                NSLog(@"#cam_count# cam_jpg=%d, cam_mp4=%d", paramResponse.cam_jpg, paramResponse.cam_mp4);
            }];
            [self.connectingCamera save];
            self.loopRecord = paramResponse.loop;
            
            SettingTreeNode* paramNode;
            NSArray* settingGroups = [MVCameraDevice getCameraSettings];
            for(SettingTreeNode* groupNode in settingGroups)
            {
                for(SettingTreeNode* optionNode in groupNode.subOptions)
                {
                    switch (optionNode.uid)
                    {
                        case SettingNodeIDFirmwareVersion:
                        {
                            NSString* version = paramResponse.ver;
                            NSArray* components = [version componentsSeparatedByString:@";"];
                            NSString* cameraVersion = components[0];
                            NSString* rcVersion = components.lastObject;
                            paramNode = optionNode.subOptions[0];
                            paramNode.name = cameraVersion;
                            [optionNode setSelectedSubOptionUID:paramNode.uid];
                            
                            self.connectingCamera.fwVer = cameraVersion;
                            self.connectingCamera.rcFwVer = rcVersion;
                            [self.connectingCamera save];
                        }
                            break;
                        case SettingNodeIDSerialID:
                        {
                            paramNode = optionNode.subOptions[0];
                            paramNode.name = paramResponse.sn;
                            [optionNode setSelectedSubOptionUID:paramNode.uid];
                            
                            if (connectingCamera)
                            {
                                MVCameraDevice* deviceTemp = [MVCameraDevice create];///???[[MVCameraDevice alloc] init];
                                [deviceTemp copy:connectingCamera];
                                connectingCamera = deviceTemp;
                                [connectingCamera transactionWithBlock:^{
                                    connectingCamera.serialID = FGGetStringWithKeyFromTable(paramNode.name, nil);
                                }];
                                connectingCamera = [connectingCamera save];
                            }
                        }
                            break;
                        case SettingNodeIDCameraPreviewMode:
                        {
                            int previewMode = [self cameraPreviewMode];
                            paramNode = [optionNode findSubOptionByMsgID:previewMode];
                            [optionNode setSelectedSubOptionUID:paramNode.uid];
                        }
                            break;
                        case SettingNodeIDCameraGPS:
                        {
                            int previewMode = [self cameraGPSParam];//0 关闭 1=1s 3=3s 5=5s 10= 10s
                            paramNode = [optionNode findSubOptionByMsgID:previewMode];
                            [optionNode setSelectedSubOptionUID:paramNode.uid];
                        }
                            break;
                        case SettingNodeIDCameraTransportProtocol:
                        {
                            int previewMode = [self cameraTransportProtocol];//0 UDP 1tcp
                            paramNode = [optionNode findSubOptionByMsgID:previewMode];
                            [optionNode setSelectedSubOptionUID:paramNode.uid];
                        }
                            break;
                        case SettingNodeIDCameraProduceNameSetting:
                        {
                            paramNode = optionNode.subOptions[0];
                            paramNode.name = paramResponse.product;
                            [optionNode setSelectedSubOptionUID:paramNode.uid];
                        }
                            break;
                        default:
                        {
                            if (ViewTypeSingleSelection == optionNode.viewType || ViewTypeSliderSelection == optionNode.viewType)
                            {
                                NSString* jsonParamKey = optionNode.jsonParamKey;
                                if (jsonParamKey)
                                {
                                    int paramValue = [[paramResponse valueForKey:jsonParamKey] intValue];
                                    paramNode = [optionNode findSubOptionByMsgID:paramValue];
                                    [optionNode setSelectedSubOptionUID:paramNode.uid];
                                }
                            }
                        }
                            break;
                    }
                }
            }
            [self sendMessageToHandler:MSG_ALL_SETTING_RECEIVED arg1:0 arg2:0 object:nil];
            
            [self handleBatteryResponse:paramResponse.battery];
            
            @synchronized (self)
            {
                self.isSettingsSynchronized = YES;
                if (self.isLUTSynchronized)
                {
                    if (!self.isConnectedStateNotified)
                    {
                        self.isConnectedStateNotified = YES;
                        [self setState:CameraClientStateConnected object:self.connectingCamera];
                    }
                }
            }
        }
        else
        {
            [self disconnectCamera];
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        [self disconnectCamera];
    } responseClass:AMBAGetAllSettingParamResponse.class];
    getAllSettingRequest.token = self.sessionToken;
    getAllSettingRequest.msgID = AMBA_MSGID_GET_CAMERA_ALL_SETTING_PARAM;
    [[CMDConnectManager sharedInstance] sendRequest:getAllSettingRequest];
}

- (void)synchronizeCameraTime
{
    NSDate* date = [NSDate date];
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    comps = [calendar components:unitFlags fromDate:date];
    int weekDay= (int)[comps weekday];//星期日是数字1，星期一时数字2，以此类推。。。
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    
    NSString* dateDesc = [NSString stringWithFormat:@"%@-%d",[dateFormatter stringFromDate:date],weekDay];
    
    AMBARequest* rtcRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response)
                               {
                               } errorBlock:^(AMBARequest *response, int error, NSString *msg)
                               {
                               }];
    rtcRequest.msgID = AMBA_MSGID_RTC_SYNC;
    rtcRequest.token = self.sessionToken;
    rtcRequest.param = dateDesc;
    [[CMDConnectManager sharedInstance] sendRequest:rtcRequest];
}

- (void)synchronizeWorkStateAndCameraMode
{
    AMBARequest* getStateRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        AMBAGetAllModeParamResponse* allModeParamResponse = (AMBAGetAllModeParamResponse*) response;
        if (response.isRvalOK && self.connectingCamera)
        {
            self.connectingCamera.videoSegmentSeconds = allModeParamResponse.douyin_video_time;
            ///!!![self handleCameraWorkState:[(NSNumber *)response.param intValue] notifyChange:YES];
            self.cameraWorkState = (CameraWorkState) allModeParamResponse.status;
            int seconds = allModeParamResponse.rec_time;
            [self sendMessageToHandler:MSG_WORK_STATE_CHANGED arg1:self.cameraWorkState arg2:0 object:nil];
            switch (self.cameraWorkState)
            {
                case AMBA_PARAM_CAMERA_STATE_STORAGE:
                {
                    [self disconnectCamera:CameraDisconnectReasonInStorageMode];
                }
                    break;
                case AMBA_PARAM_CAMERA_STATE_STANDBY:
                    break;
                case AMBA_PARAM_CAMERA_STATE_IDLE:
                {
                    self.isShooting = NO;
                    [self stopTimer];
                    
                    int mode = allModeParamResponse.mode;
                    int subMode = allModeParamResponse.sub_mode;
                    [self.connectingCamera transactionWithBlock:^{
                        if (mode == CameraModeVideo)
                        {
                            self.connectingCamera.cameraMode = CameraModeVideo;
                            switch (subMode)
                            {
                                case 1:
                                    self.connectingCamera.cameraSubMode = CameraSubmodeVideoMicro;
                                    self.connectingCamera.cameraSubModeParam = allModeParamResponse.second;
                                    break;
                                case 2:
                                    self.connectingCamera.cameraSubMode = CameraSubmodeVideoTimelapse;
                                    self.connectingCamera.cameraSubModeParam = allModeParamResponse.lapse;
                                    break;
                                case 3:
                                    self.connectingCamera.cameraSubMode = CameraSubmodeVideoSlowMotion;
                                    self.connectingCamera.cameraSubModeParam = allModeParamResponse.speedx;
                                    break;
                                default:
                                    self.connectingCamera.cameraSubMode = CameraSubmodeVideoNormal;
                                    self.connectingCamera.cameraSubModeParam = 0;
                                    break;
                            }
                        }
                        else
                        {
                            self.connectingCamera.cameraMode = CameraModePhoto;
                            switch (subMode) {
                                case 1:
                                    self.connectingCamera.cameraSubMode = CameraSubmodePhotoTiming;
                                    self.connectingCamera.cameraSubModeParam = allModeParamResponse.timing;
                                    break;
                                case 2:
                                    self.connectingCamera.cameraSubMode = CameraSubmodePhotoInterval;
                                    self.connectingCamera.cameraSubModeParam = allModeParamResponse.cap_interval;
                                    break;
                                case 3:
                                    self.connectingCamera.cameraSubMode = CameraSubmodePhotoContinuous;
                                    self.connectingCamera.cameraSubModeParam = allModeParamResponse.burst_num;
                                    break;
                                case 4:
                                    self.connectingCamera.cameraSubMode = CameraSubmodePhotoSurroundExp;
                                    self.connectingCamera.cameraSubModeParam = allModeParamResponse.surroundexp;
                                    break;
                                default:
                                    self.connectingCamera.cameraSubMode = CameraSubmodePhotoNormal;
                                    self.connectingCamera.cameraSubModeParam = 0;
                                    break;
                            }
                        }
                        
                    }];
                    
                    self.connectingCamera = [self.connectingCamera save];
                    [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
                    [self sendMessageToHandler:MSG_END_SHOOTING arg1:0 arg2:0 object:nil];
                }
                    break;
                case AMBA_PARAM_CAMERA_STATE_CAPTURING:
                {
                    self.isShooting = YES;
                    [self.connectingCamera transactionWithBlock:^{
                        connectingCamera.cameraMode = CameraModeVideo;
                        connectingCamera.cameraSubMode = CameraSubmodeVideoNormal;
                        connectingCamera.cameraSubModeParam = 0;
                    }];
                    self.connectingCamera = [self.connectingCamera save];
                    [self startTimer:seconds delaySeconds:0.3f];
                    [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
                    NSLog(@"#Callback# MSG_BEGIN_SHOOTING on symchronizedWorkStateAndCameraMode #1");
                    [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
                }
                    break;
                case AMBA_PARAM_CAMERA_STATE_CAPTURING_MICRO:
                {
                    self.isShooting = YES;
                    [self.connectingCamera transactionWithBlock:^{
                        connectingCamera.cameraMode = CameraModeVideo;
                        connectingCamera.cameraSubMode = CameraSubmodeVideoMicro;
                        connectingCamera.cameraSubModeParam = allModeParamResponse.second;
                    }];
                    self.connectingCamera = [self.connectingCamera save];
                    
                    [self startTimer:seconds delaySeconds:0.3f];
                    [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
                    NSLog(@"#Callback# MSG_BEGIN_SHOOTING on symchronizedWorkStateAndCameraMode #2");
                    [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
                }
                    break;
                case AMBA_PARAM_CAMERA_STATE_CAPTURING_TIMELAPSE:
                {
                    self.isShooting = YES;
                    [self.connectingCamera transactionWithBlock:^{
                        connectingCamera.cameraMode = CameraModeVideo;
                        connectingCamera.cameraSubMode = CameraSubmodeVideoTimelapse;
                        connectingCamera.cameraSubModeParam = allModeParamResponse.lapse;
                    }];
                    self.connectingCamera = [self.connectingCamera save];
                    
                    [self startTimer:seconds delaySeconds:0.3f];
                    [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
                    NSLog(@"#Callback# MSG_BEGIN_SHOOTING on symchronizedWorkStateAndCameraMode #3");
                    [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
                }
                    break;
                case AMBA_PARAM_CAMERA_STATE_CAPTURING_SLOWMOTION:
                {
                    self.isShooting = YES;
                    [self.connectingCamera transactionWithBlock:^{
                        connectingCamera.cameraMode = CameraModeVideo;
                        connectingCamera.cameraSubMode = CameraSubmodeVideoSlowMotion;
                        connectingCamera.cameraSubModeParam = allModeParamResponse.speedx;
                    }];
                    self.connectingCamera = [self.connectingCamera save];
                    
                    [self startTimer:seconds delaySeconds:0.3f];
                    [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
                    NSLog(@"#Callback# MSG_BEGIN_SHOOTING on symchronizedWorkStateAndCameraMode #3.5");
                    [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
                }
                    break;
                case AMBA_PARAM_CAMERA_STATE_PHOTOING:
                {
                    self.isShooting = YES;
                    [self.connectingCamera transactionWithBlock:^{
                        connectingCamera.cameraMode = CameraModePhoto;
                        connectingCamera.cameraSubMode = CameraSubmodePhotoNormal;
                        connectingCamera.cameraSubModeParam = 0;
                    }];
                    self.connectingCamera = [self.connectingCamera save];
                    
                    [self startTimer:seconds delaySeconds:0.3f];
                    [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
                    NSLog(@"#Callback# MSG_BEGIN_SHOOTING on symchronizedWorkStateAndCameraMode #4");
                    [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
                }
                break;
                case AMBA_PARAM_CAMERA_STATE_PHOTOING_DELAYED:
                {
                    int timing = allModeParamResponse.timing;
                    int timing_c = allModeParamResponse.timing_c;
                    if (timing_c > 0 && timing_c < timing)
                    {
                        timing -= timing_c;
                    }
                    [self startCountDown:timing];
                    
                    self.isShooting = YES;
                    [self.connectingCamera transactionWithBlock:^{
                        connectingCamera.cameraMode = CameraModePhoto;
                        connectingCamera.cameraSubMode = CameraSubmodePhotoTiming;
                        connectingCamera.cameraSubModeParam = timing;
                    }];
                    self.connectingCamera = [self.connectingCamera save];
                
                    [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
                }
                break;
                case AMBA_PARAM_CAMERA_STATE_PHOTOING_INTERVAL:
                {
                    int capInterval = allModeParamResponse.cap_interval;
                    self.intervalPhotosNumber = allModeParamResponse.cap_interval_num;
                    
                    self.isShooting = YES;
                    [self.connectingCamera transactionWithBlock:^{
                        connectingCamera.cameraMode = CameraModePhoto;
                        connectingCamera.cameraSubMode = CameraSubmodePhotoInterval;
                        connectingCamera.cameraSubModeParam = capInterval;
                    }];
                    self.connectingCamera = [self.connectingCamera save];
                    
                    [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
                }
                    break;
                case AMBA_PARAM_CAMERA_STATE_CAPTURING_CONTINUOUS:
                {
                    //正在连续拍照
                    self.isShooting = YES;
                    self.cameraWorkState = CameraWorkStatePhotoingContinuous;
                    [self.connectingCamera transactionWithBlock:^{
                        connectingCamera.cameraMode = CameraModePhoto;
                        connectingCamera.cameraSubMode = CameraSubmodePhotoContinuous;
                        connectingCamera.cameraSubModeParam = allModeParamResponse.burst_num;
                    }];
                    self.connectingCamera = [self.connectingCamera save];
                    [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
                    [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
                    break;
                }
                case AMBA_PARAM_CAMERA_STATE_CAPTURING_SURROUNDEXP:
                {
                    //正在包围曝光拍照
                    self.isShooting = true;
                    self.surroundExpNumberOfPhoto = allModeParamResponse.surexp_c;
                    self.cameraWorkState = CameraWorkStatePhotoingSurroundExp;
                    [self.connectingCamera transactionWithBlock:^{
                        connectingCamera.cameraMode = CameraModePhoto;
                        connectingCamera.cameraSubMode = CameraSubmodePhotoSurroundExp;
                        connectingCamera.cameraSubModeParam = allModeParamResponse.surroundexp;
                    }];
                    self.connectingCamera = [self.connectingCamera save];
                    [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
                    [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
                    break;
                }
            }
        }
        else
        {
            self.isShooting = NO;
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        self.isShooting = NO;
    } responseClass:AMBAGetAllModeParamResponse.class];
    getStateRequest.msgID = AMBA_MSGID_GET_CAMERA_ALL_MODE_PARAM;
    getStateRequest.token = self.sessionToken;
    [[CMDConnectManager sharedInstance] sendRequest:getStateRequest];
}

NSString* formatSDStorageString(long free, long total) {
    //TODO:
    NSString* formatStr = @"0M/0M";
    if (total > 0)
    {
        NSString *formatTotal, *formatFree;
        if (total > 1024 * 1024)
        {
            double dTotal = ((double) total) / (1024 * 1024);
            formatTotal = [NSString stringWithFormat:@"%.2fG", dTotal];
        }
        else
        {
            double dTotal = ((double) total) / (1024);
            formatTotal = [NSString stringWithFormat:@"%.2fM", dTotal];
        }
        
        if (free > 1024 * 1024)
        {
            double dFree = ((double) free) / (1024 * 1024);
            formatFree = [NSString stringWithFormat:@"%.2fG", dFree];
        }
        else
        {
            double dFree = ((double) free) / (1024);
            formatFree = [NSString stringWithFormat:@"%.2fM", dFree];
        }
        
        formatStr = [NSString stringWithFormat:@"%@/%@", formatFree, formatTotal];
        return formatStr;
    }
    return formatStr;
}

- (void) synchronizeCameraBatteryState {
    AMBARequest* getBatteryRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        if (response.isRvalOK)
        {
            [self handleBatteryResponse:[response.param intValue]];
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
    }];
    getBatteryRequest.msgID = AMBA_MSGID_GET_BATTERY_VOLUME;
    getBatteryRequest.token = self.sessionToken;
    [[CMDConnectManager sharedInstance] sendRequest:getBatteryRequest];
}

NSString* formatSDStorage(int total, int free) {
    NSString* formatTotal = @"0M";
    NSString* formatFree = @"0M";
    if (total > 0) {
        if (total > 1024 * 1024) {
            double dTotal = ((double) total) / (1024 * 1024);
            formatTotal = [NSString stringWithFormat:@"%.2fG", dTotal];
        } else {
            double dTotal = ((double) total) / (1024);
            formatTotal = [NSString stringWithFormat:@"%.2fM", dTotal];
        }
        
        if (free > 1024 * 1024) {
            double dFree = ((double) free) / (1024 * 1024);
            formatFree = [NSString stringWithFormat:@"%.2fG", dFree];
        } else {
            double dFree = ((double) free) / (1024);
            formatFree = [NSString stringWithFormat:@"%.2fM", dFree];
        }
    }
    
    return [NSString stringWithFormat:@"%@：%@/%@：%@",FGGetStringWithKeyFromTable(AVAILABLE, nil), formatFree, FGGetStringWithKeyFromTable(TOTAL, nil),formatTotal];
}

- (void) synchronizeCameraStorageAllState {
    AMBARequest* storageAllStateRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        AMBASyncStorageAllStateResponse* allStateResponse = (AMBASyncStorageAllStateResponse*) response;
        int prevStorageState = self.storageState;
        int prevStorageMounted = self.storageMounted;
        self.sdOID = allStateResponse.sd_oid;
        self.sdMID = allStateResponse.sd_mid;
        self.sdPNM = allStateResponse.sd_pnm;
        self.storageState = (StorageState) allStateResponse.sd_full;
        if (allStateResponse.isRvalOK)
        {
            self.totalStorage = allStateResponse.sd_total;
            self.freeStorage = allStateResponse.sd_free;
            self.photoCapacity = allStateResponse.remain_jpg;
            self.videoCapacity = allStateResponse.remain_video;
            BOOL isInWhiteList = [MVCameraClient isSdWhiteSd_mid:self.sdMID sd_oid:self.sdOID sd_pnm:self.sdPNM];
            if (isInWhiteList)
            {
                self.storageMounted = StorageMountStateOK;
            }
            else
            {
                self.storageMounted = StorageMountStateUnsure;
            }
        }
        else if (allStateResponse.rval == AMBA_RVAL_ERROR_FAULT_SDCARD)
        {
            self.storageMounted = StorageMountStateFault;
            self.totalStorage = allStateResponse.sd_total;
            self.freeStorage = allStateResponse.sd_free;
            self.photoCapacity = allStateResponse.remain_jpg;
            self.videoCapacity = allStateResponse.remain_video;
        }
        else if (allStateResponse.rval == AMBA_RVAL_ERROR_NO_SDCARD)
        {
            self.storageMounted = StorageMountStateNO;//unmounted
            self.totalStorage = 0;
            self.freeStorage = 0;
            self.photoCapacity = -1;
            self.videoCapacity = -1;
        }
        else if (allStateResponse.rval == AMBA_RVAL_ERROR_WRONG_SDCARD)
        {
            self.storageMounted = StorageMountStateError;//unmounted
            self.totalStorage = 0;
            self.freeStorage = 0;
            self.photoCapacity = -1;
            self.videoCapacity = -1;
        }
        else
        {
            self.storageMounted = StorageMountStateOK;//mounted
            self.storageState = StorageStateAvailable;
            self.totalStorage = 0;
            self.freeStorage = 0;
            self.photoCapacity = -1;
            self.videoCapacity = -1;
        }
        
        NSLog(@"synchronizeCameraStorageAllState : SD card mounted = %d", (int)self.storageMounted);
        if (prevStorageMounted != self.storageMounted)
        {
            [self sendMessageToHandler:MSG_STORAGE_MOUNTED_STATE_CHANGED arg1:self.storageMounted arg2:0 object:nil];
        }
        [self sendMessageToHandler:MSG_STORAGE_STATE_CHANGED arg1:self.storageState arg2:prevStorageState object:nil];
        
        if (self.isShooting && 0 == self.storageMounted)
        {
            [self sendMessageToHandler:MSG_END_SHOOTING arg1:0 arg2:0 object:@""];
            self.isShooting = NO;
            //isVideoCapturing = NO;
//            self.currentMicroParam = 0;
            [self stopTimer];
        }
        
        SettingTreeNode* optionNode = [MVCameraDevice findOptionNodeByUID:SettingNodeIDFormatSD];
        if (optionNode && optionNode.subOptions.count > 0)
        {
            [optionNode setSelectedSubOptionUID:0];
            SettingTreeNode* subOptionNode = [optionNode findSubOptionByUID:0];
            if (subOptionNode)
            {
                subOptionNode.name = formatSDStorage(self.totalStorage, self.freeStorage);
            }
        }
        [self sendMessageToHandler:MSG_STORAGE_TOTAL_FREE_CHANGED arg1:self.totalStorage arg2:self.freeStorage object:nil];
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        
    } responseClass:AMBASyncStorageAllStateResponse.class];
    storageAllStateRequest.msgID = AMBA_MSGID_GET_STORAGE_ALL_STATE;
    storageAllStateRequest.token = self.sessionToken;
    [[CMDConnectManager sharedInstance] sendRequest:storageAllStateRequest];
}

- (void) startGPSInfoSynchronization:(BOOL)isGPSParamChange {
    if (_gpsSyncTimer)
    {
        if (isGPSParamChange) {
            [_gpsSyncTimer invalidate];
            _gpsSyncTimer = nil;
            [self notifyGPS];
            if ([NSTimer.class respondsToSelector:@selector(scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:)])
            {
                NSString * gpsParam = [helper readProfileString:GPSPARAM];
                _gpsSyncTimer = [NSTimer scheduledTimerWithTimeInterval:[gpsParam doubleValue] target:self selector:@selector(notifyGPS) userInfo:nil repeats:YES];
            }
            [[NSRunLoop currentRunLoop] addTimer:_gpsSyncTimer forMode:NSRunLoopCommonModes];
            return;
        }else
        {
            return;
        }
        
    }
    
    [self notifyGPS];
    
    if ([NSTimer.class respondsToSelector:@selector(scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:)])
    {
        NSString * gpsParam = [helper readProfileString:GPSPARAM];
        _gpsSyncTimer = [NSTimer scheduledTimerWithTimeInterval:[gpsParam doubleValue] target:self selector:@selector(notifyGPS) userInfo:nil repeats:YES];
    }
    [[NSRunLoop currentRunLoop] addTimer:_gpsSyncTimer forMode:NSRunLoopCommonModes];
}

- (void) notifyGPS {
    NSString* openGps = [helper readProfileString:GPSPARAM];
    if ([openGps isEqualToString:@"0"])
        return;
    
    if (([CLLocationManager locationServicesEnabled] &&
         ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)))
    {
        //这个时候你可以得到当前位置的经纬度
        NSString* latitude = [helper readProfileString:LATITUDE];//纬度
        NSString* longitude = [helper readProfileString:LONGITUDE];//经度
        NSString* altitude = [helper readProfileString:ALTITUDE];//经度
        
        AMBASetGPSInfoRequest* request = [[AMBASetGPSInfoRequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
            
        } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
            
        }];
        request.lat = latitude;
        request.lon = longitude;
        request.alt = altitude;
        request.token = [MVCameraClient sharedInstance].sessionToken;
        [[CMDConnectManager sharedInstance] sendRequest:request];
    }
    else
    {
        //当前用户没打开定位服务
    }
}

- (void) stopGPSInfoSynchronization {
    if (_gpsSyncTimer)
    {
        [_gpsSyncTimer invalidate];
        _gpsSyncTimer = nil;
    }
}
//相机陀螺仪校正
- (void)startAdjustCameraGyro
{
    AMBARequest * request = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        if (response.isRvalOK)
        {
            [self sendMessageToHandler:MSG_ADJUST_CAMERA_GYRO_DONE arg1:0 arg2:0 object:nil];
        }
        else
        {
            [self sendMessageToHandler:MSG_ADJUST_CAMERA_GYRO_DONE arg1:response.rval arg2:0 object:nil];
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        [self sendMessageToHandler:MSG_ADJUST_CAMERA_GYRO_DONE arg1:error arg2:0 object:nil];
    }];
    request.token = self.sessionToken;
    request.msgID = AMBA_MSGID_ADJUST_CAMERA_GYRO;
    [[CMDConnectManager sharedInstance] sendRequest:request];
}

- (void)handleCameraWorkState:(int)workState notifyChange:(bool)notifyChange
{
    self.cameraWorkState = (CameraWorkState)workState;
    if (notifyChange)
    {
        [self sendMessageToHandler:MSG_WORK_STATE_CHANGED arg1:self.cameraWorkState arg2:0 object:nil];
    }
    switch (self.cameraWorkState)
    {
        case AMBA_PARAM_CAMERA_STATE_STORAGE:
            [self disconnectCamera:CameraDisconnectReasonInStorageMode];
            break;
        case AMBA_PARAM_CAMERA_STATE_STANDBY:
            //[self disconnectCamera:CameraDisconnectReasonStandBy];
            break;
            /*
        case AMBA_PARAM_CAMERA_STATE_IDLE:
        {
            self.isShooting = NO;
            [self stopTimer];
            AMBARequest* getModeRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
                if (response.isRvalOK)
                {
                    self.connectingCamera.cameraMode = (CameraMode) [response.param integerValue];
                    if (self.connectingCamera.cameraMode == CameraModeVideo)
                    {
                        self.connectingCamera.cameraSubMode = CameraSubmodeVideoNormal;
                    }
                    else if (self.connectingCamera.cameraMode == CameraModePhoto)
                    {
                        self.connectingCamera.cameraSubMode = CameraSubmodePhotoNormal;
                    }
                    self.connectingCamera.cameraSubModeParam = 0;
                    self.connectingCamera=[self.connectingCamera save];
                    if(notifyChange)
                    {
                        [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
                        [self sendMessageToHandler:MSG_END_SHOOTING arg1:0 arg2:0 object:nil];
                    }
                }
            } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
            }];
            getModeRequest.msgID = AMBA_MSGID_SET_CAMERA_MODE;
            getModeRequest.token = self.sessionToken;
            [[CMDConnectManager sharedInstance] sendRequest:getModeRequest];
            break;
        }
             //*/
        default:
            break;
    }
}

- (void)startTimer:(int)startSeconds delaySeconds:(float)delaySeconds
{
    self.isTiming = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * delaySeconds), _timingQueue, ^() {
        int seconds = startSeconds - 1;
        NSDate* startTime = [NSDate date];
        
        while (self.isTiming)
        {
            NSTimeInterval timeInterval = -[startTime timeIntervalSinceNow];
            int nowSeconds = floorf(timeInterval) + startSeconds;
           // NSLog(@"startTimer: nowSeconds = %d, startSeconds = %d, seconds = %d, timeInterval = %f", nowSeconds, startSeconds, seconds, timeInterval);
            if (nowSeconds != seconds)
            {
                seconds = nowSeconds;
                
                if (CameraSubmodeVideoMicro == connectingCamera.cameraSubMode)
                {
                    if (seconds > connectingCamera.cameraSubModeParam)
                    {
                        seconds = (int) connectingCamera.cameraSubModeParam;
                    }
                }
                DoctorLog(@"#msg_id#Timer# seconds = %d", seconds);
                [self sendMessageToHandler:MSG_TIMER_TICKED arg1:seconds arg2:[self videoTimeOfShootingTime:seconds] object:nil];
            }
            
            [NSThread sleepForTimeInterval:0.1f];
        }
        //NSLog(@"startTimer: Exit");
    });
}

- (void) stopCountDown {
    self.downCounter = -1;
    self.isCountingDown = NO;
}

- (void) startCountDown:(int)startSeconds {
    if (startSeconds <= 0)
        return;

    [self stopTimer];
    self.isCountingDown = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0), _timingQueue, ^() {
        self.downCounter = startSeconds + 1;
        NSDate* startTime = [NSDate date];
        
        while (self.downCounter > 0 && self.isCountingDown)
        {
            NSTimeInterval timeInterval = -[startTime timeIntervalSinceNow];
            int nowSeconds = startSeconds - round(timeInterval);
            // NSLog(@"startTimer: nowSeconds = %d, startSeconds = %d, seconds = %d, timeInterval = %f", nowSeconds, startSeconds, seconds, timeInterval);
            if (nowSeconds < 0)
            {
                nowSeconds = 0;
            }
            
            if (nowSeconds != self.downCounter)
            {
                self.downCounter = nowSeconds;
                [self sendMessageToHandler:MSG_COUNT_DOWN_TICKED arg1:self.downCounter arg2:0 object:nil];
            }
            
            [NSThread sleepForTimeInterval:0.1f];
        }
        
        if (self.isCountingDown)
        {
            self.isCountingDown = NO;
        }
        else if (self.downCounter > 0)
        {
            [self sendMessageToHandler:MSG_COUNT_DOWN_TICKED arg1:0 arg2:0 object:nil];
        }
        //NSLog(@"startTimer: Exit");
    });
}

- (void)stopTimer
{
    NSLog(@"stopTimer");
    self.isTiming = NO;
}

- (CameraClientState) state {
    return _state;
}

- (void)setState:(CameraClientState)state
{
    [self setState:state object:nil];
}
- (void)setState:(CameraClientState)newState object:(id)object
{
    [_cond lock];
    NSInteger oldState = _state;
    _state = newState;
    if (_state == CameraClientStateNotConnected)
    {
        [self resetStates];
        self.connectingCamera = nil;
        self.sessionToken = AMBA_SESSION_TOKEN_INIT;
    }
    [_cond broadcast];
    [self notifyStateChanged:newState oldState:oldState object:object];
    [_cond unlock];
}

- (void) resetStates {
    self.cameraWorkState = CameraWorkStateIdle;
    self.connectingCamera = nil;
    self.currentFilter = nil;
    
    [self stopTimer];
    self.isShooting = NO;//Is camera busy capturing?
    self.storageMounted = StorageMountStateOK;
    self.storageState = StorageStateAvailable;
    self.totalStorage = -1;
    self.freeStorage = -1;
    self.videoCapacity = -1;
    self.photoCapacity = -1;
    self.loopRecord = 0;
    
    self.voltagePercent = 100;
    self.isCharging = NO;
}

- (CameraClientState) waitForState:(CameraClientState)stateCombo
{
    [_cond lock];
    while ((self.state != 0 || stateCombo != 0) && ((self.state & stateCombo) == 0))
    {
        [_cond wait];
    }
    [_cond unlock];
    return self.state;
}

- (void)notifyStateChanged:(NSInteger)newState oldState:(NSInteger)oldState object:(id)object
{
    [self sendMessageToHandler:MSG_STATE_CHANGED arg1:newState arg2:oldState object:object];
}

- (void)sendMessageToHandler:(int)what arg1:(NSInteger)arg1 arg2:(NSInteger)arg2 object:(id)object
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (what)
        {
            case MSG_STATE_CHANGED:
                [self onStateChanged:arg1 oldState:arg2 object:object];
                break;
            case MSG_WIFI_SET:
                [self onWiFiSet:(int)arg1 errMsg:(NSString *)object];
                break;
            case MSG_WIFI_RESTART:
                [self onWiFiRestart:(int)arg1 errMsg:(NSString *)object];
                break;
            case MSG_MODE_CHANGED:
                [self onCameraModeChanged:(int)arg1 errMsg:(NSString *)object];
                break;
            case MSG_BEGIN_SHOOTING:
                [self onShootingBegan:0 numberOfPhoto:(int)arg2];
                break;
            case MSG_BEGIN_SHOOTING_ERROR:
                [self onShootingBegan:(int)arg1 numberOfPhoto:(int)arg2];
                break;
            case MSG_STOP_SHOOTING:
                [self onShootingStop:(int)arg1];
                break;
            case MSG_END_SHOOTING:
                if (arg1 == 0)
                    [self onShootingEnded:(NSString *)object videoDurationMills:arg2 error:0 errMsg:nil];
                else
                    [self onShootingEnded:nil videoDurationMills:arg2 error:(int)arg1 errMsg:(NSString *)object];
                break;
            case MSG_TIMER_TICKED:
                [self onShootingTimerTicked:(int)arg1 videoTime:(int)arg2];
                break;
            case MSG_ALL_SETTING_RECEIVED:
                [self onAllSettingReceived:arg1];
                break;
            case MSG_SETTING_CHANGED:
                [self onSettingChanged:(int)arg1 param:(int)arg2 errMsg:(NSString *)object];
                break;
            case MSG_VOLTAGE_CHANGED:
                [self onVoltageChanged:(int)arg1 isCharging:(0 != arg2)];
                break;
            case MSG_WORK_STATE_CHANGED:
                [self onWorkStateChanged:(int)arg1];
                break;
            case MSG_STORAGE_MOUNTED_STATE_CHANGED:
                [self onStorageMountedStateChanged:(int)arg1];
                break;
            case MSG_STORAGE_STATE_CHANGED:
                [self onStorageStateChanged:(int)arg1 oldState:(int)arg2];
                break;
            case MSG_RECEIVE_NOTIFICATION:
                [self onReceiveNotification:(int)arg1];
                break;
            case MSG_STORAGE_TOTAL_FREE_CHANGED:
                [self onStorageTotalFreeChanged:(int)arg1 free:(int)arg2];
                break;
            case MSG_COUNT_DOWN_TICKED:
                [self onCountDownTicked:(int)arg1];
                break;
            case MSG_SDCARD_SLOWLY_WRITE:
                [self onSDCardSlowlyWrite];
                break;
            case MSG_DOUYIN_WILL_STOP_CAPTURING:
                [self onWillStopCapturing:object];
                break;
            case MSG_DOUYIN_WILL_START_CAPTURING:
                [self onWillStartCapturing:object];
                break;
            case MSG_ADJUST_CAMERA_GYRO_DONE:
                [self onAdjusted:(int)arg1];
                break;
            default:
                break;
        }
    });
}
- (void)onAdjusted:(int)errorCode
{
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didAdjustedCameraGyro:)])
        {
            [delegate didAdjustedCameraGyro:errorCode];
        }
    }
}
//delayMills 毫秒为单位
- (void)sendDelayedMessageToHandler:(int)what arg1:(NSInteger)arg1 arg2:(NSInteger)arg2 object:(id)object delayMills:(int)delayMills
{
    //NSEC_PER_SEC
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayMills*NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [self sendMessageToHandler:what arg1:arg1 arg2:arg2 object:object];
    });
}

- (void)onStateChanged:(NSInteger)newState oldState:(NSInteger)oldState object:(id)object
{
    if (newState == CameraClientStateNotConnected)
    {
        if (oldState == CameraClientStateConnecting)
        {
            
            NSLog(@"%@", [NSString stringWithFormat:@"QD:Callback---didConnectFail:%@",object]);
            
            NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
            for(id<MVCameraClientObserver> delegate in observers)
            {
                if (delegate && [delegate respondsToSelector:@selector(didConnectFail:)])
                {
                    [delegate didConnectFail:(NSString *)object];
                }
            }
        }
        else if (oldState == CameraClientStateDisconnecting || oldState == CameraClientStateConnected)
        {
            int reason = 0;
            if (object && [object isKindOfClass:NSNumber.class])
            {
                reason = [object intValue];
            }
            //BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didDisconnect:%d",reason]);
            NSLog(@"%@",[NSString stringWithFormat:@"QD:Callback---didDisconnect:%d",reason]);
            NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
            for(id<MVCameraClientObserver> delegate in observers)
            {
                if (delegate && [delegate respondsToSelector:@selector(didDisconnect:)])
                {
                    [delegate didDisconnect:(CameraDisconnectReason)reason];
                }
            }
        }
    }
    else if (newState == CameraClientStateConnected)
    {
        NSLog(@"%@",[NSThread currentThread]);
        [[RealmSerialQueue shareRealmQueue] sync:^{
            //BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didConnectSuccess:%@",(MVCameraDevice *)object]);
            NSLog(@"%@",[NSString stringWithFormat:@"QD:Callback---didConnectSuccess:%@",(MVCameraDevice *)object]);
        }];
        
        NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
        for(id<MVCameraClientObserver> delegate in observers)
        {
            if (delegate && [delegate respondsToSelector:@selector(didConnectSuccess:)])
            {
                [delegate didConnectSuccess:(MVCameraDevice *)object];
            }
        }
    }
    else if (newState == CameraClientStateConnecting)
    {
        NSLog(@"Callback : Call willConnect");
        NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
        for(id<MVCameraClientObserver> delegate in observers)
        {
            if (delegate && [delegate respondsToSelector:@selector(willConnect)])
            {
                [delegate willConnect];
            }
        }
    }
    else if (newState == CameraClientStateDisconnecting)
    {
        NSLog(@"Callback : Call willDisconnect");
        int reason = 0;
        if (object && [object isKindOfClass:NSNumber.class])
        {
            reason = [object intValue];
        }
        NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
        for(id<MVCameraClientObserver> delegate in observers)
        {
            if (delegate && [delegate respondsToSelector:@selector(willDisconnect:)])
            {
                [delegate willDisconnect:(CameraDisconnectReason)reason];
            }
        }
    }
}

- (void)onWiFiSet:(int)error errMsg:(NSString *)errMsg
{
    BOOL success = (error == 0);
    errMsg = (success? nil : errMsg);
    //BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didSetWifi:%d errMsg:%@",success,errMsg]);
    NSLog(@"%@",[NSString stringWithFormat:@"QD:Callback---didSetWifi:%d errMsg:%@",success,errMsg]);
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for (id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didSetWifi:errMsg:)])
        {
            [delegate didSetWifi:success errMsg:errMsg];
        }
    }
}

- (void)onWiFiRestart:(int)error errMsg:(NSString *)errMsg
{
    BOOL success = (error == 0);
    errMsg = (success? nil : errMsg);
    //BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didRestartWifi:%d errMsg:%@",success,errMsg]);
    NSLog(@"%@",[NSString stringWithFormat:@"QD:Callback---didRestartWifi:%d errMsg:%@",success,errMsg]);
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didRestartWifi:errMsg:)])
        {
            [delegate didRestartWifi:success errMsg:errMsg];
        }
    }
}

- (void)onCameraModeChanged:(int)error errMsg:(NSString *)errMsg
{
    if (!self.connectingCamera)
        return;
    
    if (error != 0 || errMsg != nil)
    {
        // BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didSwitchCameraModeFail:%@",errMsg]);
        NSLog(@"%@",[NSString stringWithFormat:@"QD:Callback---didSwitchCameraModeFail:%@",errMsg]);
        NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
        for(id<MVCameraClientObserver> delegate in observers)
        {
            if (delegate && [delegate respondsToSelector:@selector(didSwitchCameraModeFail:)])
            {
                [delegate didSwitchCameraModeFail:errMsg];
            }
        }
    }
    else
    {
        MVCameraDevice* camera = self.connectingCamera;
        if (camera == nil)
        {
            camera = [MVCameraDevice create];
        }
        //BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didCameraModeChange:%ld subMode:%ld param:%ld",(long)camera.cameraMode,(long)camera.cameraSubMode,(long)camera.cameraSubModeParam]);
        NSLog(@"%@",[NSString stringWithFormat:@"QD:Callback---didCameraModeChange:%ld subMode:%ld param:%ld",(long)camera.cameraMode,(long)camera.cameraSubMode,(long)camera.cameraSubModeParam]);
        
        NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
        for(id<MVCameraClientObserver> delegate in observers)
        {
            if (delegate && [delegate respondsToSelector:@selector(didCameraModeChange:subMode:param:)])
            {
                [delegate didCameraModeChange:camera.cameraMode subMode:camera.cameraSubMode param:camera.cameraSubModeParam];
            }
        }
    }
}

- (void)onShootingBegan:(int)error numberOfPhoto:(int)numberOfPhoto
{
    //BLYLogInfo(@"QD:Callback---didBeginShooting");
    NSLog(@"#Douyin# Callback---didBeginShooting");
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didBeginShooting:numberOfPhoto:)])
        {
            [delegate didBeginShooting:error numberOfPhoto:numberOfPhoto];
        }
    }
}
- (void)onShootingStop:(int)error;
{
    NSLog(@"#Douyin# Callback---didStopShooting");
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didStopShooting:)])
        {
            [delegate didStopShooting:error];
        }
    }
}
- (void)onShootingEnded:(NSString *)remoteFilePath videoDurationMills:(NSInteger)videoDurationMills error:(int)error errMsg:(NSString *)errMsg
{
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    //BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didEndShooting:%@ error:%d errMsg:%@",remoteFilePath,error,errMsg]);
    NSLog(@"#Douyin# Callback---didEndShooting:%@ error:%d errMsg:%@",remoteFilePath,error,errMsg);
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didEndShooting:videoDurationMills:error:errMsg:)])
        {
            [delegate didEndShooting:remoteFilePath videoDurationMills:videoDurationMills error:error errMsg:errMsg];
        }
    }
}

- (void)onShootingTimerTicked:(int)shootingTime videoTime:(int)videoTime
{
    if (nil == connectingCamera)
    {
        return;
    }
    
    //BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didShootingTimerTick:%d videoTime:%d",shootingTime,videoTime]);
    NSLog(@"%@",[NSString stringWithFormat:@"QD:Callback---didShootingTimerTick:%d videoTime:%d",shootingTime,videoTime]);
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didShootingTimerTick:videoTime:)])
        {
            [delegate didShootingTimerTick:shootingTime videoTime:videoTime];
        }
    }
}
    
- (void) onCountDownTicked:(int)second {
    NSLog(@"Callback: onCountDownTicked:%d", second);
    if (nil == connectingCamera)
    {
        return;
    }
    
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for (id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didCountDownTimerTick:)])
        {
            [delegate didCountDownTimerTick:second];
        }
    }
}
    
- (void) onSDCardSlowlyWrite {
    NSLog(@"Callback: onSDCardSlowlyWrite");
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for (id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didSDCardSlowlyWrite)])
        {
            [delegate didSDCardSlowlyWrite];
        }
    }
}

- (void) onWillStopCapturing:(id)param {
    NSLog(@"#Douyin#: Callback willStopCapturing");
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for (id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(willStopCapturing:)])
        {
            [delegate willStopCapturing:param];
        }
    }
}

- (void) onWillStartCapturing:(id)param {
    NSLog(@"#Douyin#: Callback willStartCapturing");
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for (id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(willStartCapturing:)])
        {
            [delegate willStartCapturing:param];
        }
    }
}

- (int)videoTimeOfShootingTime:(int)shootingTime
{
    if (self.connectingCamera == nil)
    {
        return shootingTime;
    }
    if (self.connectingCamera.cameraMode == CameraModeVideo && self.connectingCamera.cameraSubMode == CameraSubmodeVideoTimelapse)
    {
        SettingTreeNode* paramsNode = [MVCameraDevice getCameraModeParameters:connectingCamera.cameraMode cameraSubMode:connectingCamera.cameraSubMode];
        SettingTreeNode* paramNode = [paramsNode findSubOptionByMsgID:(int)connectingCamera.cameraSubModeParam];
        float interval = [[FGGetStringWithKeyFromTable(paramNode.name, nil) substringToIndex:paramNode.name.length-1] floatValue];
        SettingTreeNode* resolutionSettingNode = [MVCameraDevice findOptionNodeByUID:SettingNodeIDVideoFrameRateSetting];
        int resolutionSelectedUID = resolutionSettingNode.selectedSubOptionUID;
        float captureFPS = 30.f;
        switch (resolutionSelectedUID)
        {
            case FPS60_2304x1152:
                captureFPS = 60.f;
                break;
            case FPS120_TOP_1920x480:
            case FPS120_MIDDLE_1920x480:
            case FPS120_BOTTOM_1920x480:
                captureFPS = 120.f;
                break;
            default:
                captureFPS = 30.f;
                break;
        }
        return (connectingCamera.cameraSubModeParam == 0 ? 0 : (int) ((float) shootingTime / interval / captureFPS));
    }
    else if (self.connectingCamera.cameraMode == CameraModeVideo && self.connectingCamera.cameraSubMode == CameraSubmodeVideoSlowMotion)
    {
        if (self.connectingCamera.cameraSubModeParam > 0)
        {
            shootingTime *= self.connectingCamera.cameraSubModeParam;
            
            NSLog(@"&&&&&&&&&&&&&&&&&+++++ %d &&&&&&&&&& %ld",shootingTime,self.connectingCamera.cameraSubModeParam);
        }
    }
    return shootingTime;
}

- (void)onSettingChanged:(int)option param:(int)param errMsg:(NSString *)errMsg
{
    // BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didSettingsChange:%d paramUID:%d errMsg:%@",option,param,errMsg]);
    NSLog(@"%@",[NSString stringWithFormat:@"QD:Callback---didSettingsChange:%d paramUID:%d errMsg:%@",option,param,errMsg]);
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didSettingsChange:paramUID:errMsg:)])
        {
            [delegate didSettingsChange:option paramUID:param errMsg:errMsg];
        }
    }
}

- (void)onAllSettingReceived:(int)errorCode
{
    // BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didSettingsChange:%d paramUID:%d errMsg:%@",option,param,errMsg]);
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didReceiveAllSettingItems:)])
        {
            [delegate didReceiveAllSettingItems:errorCode];
        }
    }
}

- (void)onVoltageChanged:(int)percent isCharging:(BOOL)isCharging
{
    // BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didVoltagePercentChanged:%d isCharging:%d",percent,isCharging]);
    NSLog(@"%@",[NSString stringWithFormat:@"QD:Callback---didVoltagePercentChanged:%d isCharging:%d",percent,isCharging]);
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didVoltagePercentChanged:isCharging:)])
        {
            [delegate didVoltagePercentChanged:percent isCharging:isCharging];
        }
    }
}

- (void)onWorkStateChanged:(int)workState
{
    //BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didWorkStateChange:%d",workState]);
    NSLog(@"%@",[NSString stringWithFormat:@"QD:Callback---didWorkStateChange:%d",workState]);
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didWorkStateChange:)])
        {
            [delegate didWorkStateChange:(CameraWorkState)workState];
        }
    }
}

- (void)onStorageMountedStateChanged:(int)mountedState
{
    if (self.state == CameraClientStateConnected)
    {
        [[MVMediaManager sharedInstance] cameraMedias:YES];
    }
    
    //BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didStorageMountedStateChanged:%d",sdCardState]);
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didStorageMountedStateChanged:)])
        {
            [delegate didStorageMountedStateChanged:(StorageMountState)mountedState];
        }
    }
}

- (void) onStorageStateChanged:(int)newState oldState:(int)oldState {
    //BLYLogInfo([NSString stringWithFormat:@"QD:Callback---onStorageStateChanged:%d",total]);
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didStorageStateChanged:oldState:)])
        {
            [delegate didStorageStateChanged:(StorageState)newState oldState:(StorageState)oldState];
        }
    }
}

- (void) onStorageTotalFreeChanged:(int)total free:(int)free {
    //BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didStorageTotalFreeChanged:%d",total]);
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didStorageTotalFreeChanged:free:)])
        {
            [delegate didStorageTotalFreeChanged:total free:free];
        }
    }
}

- (void)onReceiveNotification:(int)notification
{
    NSString* notificationString = NotificationStringOfNotification(notification);
    //BLYLogInfo([NSString stringWithFormat:@"QD:Callback---didReceiveCameraNotification:%d",notification]);
    NSLog(@"%@",[NSString stringWithFormat:@"QD:Callback---didReceiveCameraNotification:%@",notificationString]);
    NSArray<id<MVCameraClientObserver>>* observers = [NSArray arrayWithArray:_observers];
    for(id<MVCameraClientObserver> delegate in observers)
    {
        if (delegate && [delegate respondsToSelector:@selector(didReceiveCameraNotification:)])
        {
            [delegate didReceiveCameraNotification:notificationString];
        }
    }
}

#pragma mark --CMDConnectionObserver代理方法的实现--
- (void)cmdConnectionStateChanged:(CmdSocketState)newState oldState:(CmdSocketState)oldState object:(id)object
{
    CameraDisconnectReason reason = CameraDisconnectReasonUnknown;
    if (object && [object isKindOfClass:NSNumber.class])
    {
        reason = (CameraDisconnectReason) [object intValue];
    }
    
    switch (self.state)
    {
        case CameraClientStateConnected:
            if (newState == CmdSocketStateNotReady)
            {
                [self disconnectCamera:reason];
            }
#ifdef RECONNECT_ON_BACK_FOREGROUND
            else if (newState == CmdSocketStateReady)
            {
                self.state = CameraClientStateConnecting;
                //[[CMDConnectManager sharedInstance] openConnection];
                [self startSessionAndSyncCamera];
            }
#endif
            break;
        case CameraClientStateConnecting:
            if (newState == CmdSocketStateReady)
            {
                [self startSessionAndSyncCamera];
            }
            else if (newState == CmdSocketStateNotReady)
            {
                [self disconnectCamera:reason];
            }
            break;
        case CameraClientStateDisconnecting:
            if (newState == CmdSocketStateNotReady)
            {
                [self setState:CameraClientStateNotConnected object:object];
            }
            break;
        case CameraClientStateNotConnected:
            break;
        default:
            break;
    }
}

- (void)cmdConnectionReceiveCameraResponse:(AMBAResponse *)response
{
    if (!response || !response.isRvalOK) {
        return;
    }
    switch (response.msgID) {
        case AMBA_MSGID_DOUYIN_WILL_BEGIN_SHOOTING:
            NSLog(@"#Douyin# willBeginRecording notification(6406) received");
            [self sendMessageToHandler:MSG_DOUYIN_WILL_START_CAPTURING arg1:0 arg2:0 object:response.param];
            break;
        case AMBA_MSGID_DOUYIN_WILL_STOP_CAPTURING:
            NSLog(@"#Douyin# willStopRecording notification received");
            [self sendMessageToHandler:MSG_DOUYIN_WILL_STOP_CAPTURING arg1:0 arg2:0 object:response.param];
            break;
        case AMBA_MSGID_QUERY_SESSION_HOLDER:
            if (self.state == CameraClientStateConnected)
            {
                NSLog(@"msg_id = AMBA_MSGID_QUERY_SESSION_HOLDER #0");
                AMBARequest* request = [[AMBARequest alloc] init];
                request.shouldWaitUntilPreviousResponded = NO;
                request.token = self.sessionToken;
                request.msgID = AMBA_MSGID_QUERY_SESSION_HOLDER;
                request.param = [@(self.sessionToken) stringValue];
                [[CMDConnectManager sharedInstance] sendRequest:request];
                NSLog(@"msg_id = AMBA_MSGID_QUERY_SESSION_HOLDER #1");
            }
            break;
        case AMBA_MSGID_GET_CAMERA_STATE:
            [self handleCameraWorkState:[(NSNumber *)response.param intValue] notifyChange:YES];
            break;
        case AMBA_MSGID_SET_CAMERA_MODE:
        {
            AMBASetCameraModeResponse* setCameraModeResponse = (AMBASetCameraModeResponse*) response;
            int mode = [setCameraModeResponse.param intValue];
            int sub_mode = setCameraModeResponse.sub_mode;
            int sub_mode_param = setCameraModeResponse.sub_mode_param;
            [self.connectingCamera transactionWithBlock:^{
                if (mode == CameraModeVideo) {
                    self.connectingCamera.cameraMode = CameraModeVideo;
                    switch (sub_mode) {
                        case 1:
                            self.connectingCamera.cameraSubMode = CameraSubmodeVideoMicro;
                            self.connectingCamera.cameraSubModeParam = sub_mode_param;
                            break;
                        case 2:
                            self.connectingCamera.cameraSubMode = CameraSubmodeVideoTimelapse;
                            self.connectingCamera.cameraSubModeParam = sub_mode_param;
                            break;
                        case 3:
                            self.connectingCamera.cameraSubMode = CameraSubmodeVideoSlowMotion;
                            self.connectingCamera.cameraSubModeParam = sub_mode_param;
                            break;
                        default:
                            self.connectingCamera.cameraSubMode = CameraSubmodeVideoNormal;
                            self.connectingCamera.cameraSubModeParam = 0;
                            break;
                    }
                } else {
                    self.connectingCamera.cameraMode = CameraModePhoto;
                    switch (sub_mode) {
                        case 1:
                            self.connectingCamera.cameraSubMode = CameraSubmodePhotoTiming;
                            self.connectingCamera.cameraSubModeParam = sub_mode_param;
                            break;
                        case 2:
                            self.connectingCamera.cameraSubMode = CameraSubmodePhotoInterval;
                            self.connectingCamera.cameraSubModeParam = sub_mode_param;
                            break;
                        case 3:
                            self.connectingCamera.cameraSubMode = CameraSubmodePhotoContinuous;
                            self.connectingCamera.cameraSubModeParam = sub_mode_param;
                            break;
                        case 4:
                            self.connectingCamera.cameraSubMode = CameraSubmodePhotoSurroundExp;
                            self.connectingCamera.cameraSubModeParam = sub_mode_param;
                            break;
                        default:
                            self.connectingCamera.cameraSubMode = CameraSubmodePhotoNormal;
                            self.connectingCamera.cameraSubModeParam = 0;
                            break;
                    }
                }
            }];
            self.connectingCamera = [self.connectingCamera save];
            self.isShooting = NO;
            self.cameraWorkState = CameraWorkStateIdle;
            [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
            break;
        }
        case AMBA_MSGID_IS_SDCARD_MOUNTED:
        {
            //sdcard storage
            [self synchronizeCameraStorageAllState];
            
            break;
        }
        case AMBA_MSGID_IS_SDCARD_FULL:
        {
            [self synchronizeCameraStorageAllState];
            break;
        }
        case AMBA_MSGID_SDCARD_SLOWLY_WRITE:
        {
            self.isShooting = NO;
            [self stopTimer];
            [self sendMessageToHandler:MSG_SDCARD_SLOWLY_WRITE arg1:0 arg2:0 object:nil];
        }
        break;
        case AMBA_MSGID_SAVE_VIDEO_DONE:
        case AMBA_MSGID_SAVE_PHOTO_DONE:
        {
            NSLog(@"#Douyin# didFinishRecording notification received");
            [self stopCountDown];
            [self stopTimer];
            
            if (!((self.connectingCamera.cameraSubMode == CameraSubmodePhotoInterval && -1 != self.intervalPhotosNumber) || (self.connectingCamera.cameraSubMode == CameraSubmodePhotoSurroundExp && self.surroundExpNumberOfPhoto != 3))) {
                self.isShooting = NO;
            }
            
            AMBASaveMediaFileDoneResponse* saveDoneResponse = (AMBASaveMediaFileDoneResponse*) response;
            NSString* remoteFilePath = [self remoteFilePathOfRTOSPath:((NSString*) saveDoneResponse.param)];
            [self sendMessageToHandler:MSG_END_SHOOTING arg1:0 arg2:saveDoneResponse.mp4_time object:remoteFilePath];
            if (self.connectingCamera.capIntervalNum == -2) {
                self.isShooting = NO;
                self.cameraWorkState = CameraWorkStateIdle;
                self.connectingCamera.capIntervalNum = 0;
                [self sendMessageToHandler:MSG_STOP_SHOOTING arg1:0 arg2:0 object:nil];
            }
            //self.isVideoCapturing = NO;
            
            //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5L), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                MVMedia* media = [[MVMediaManager sharedInstance] obtainCameraMedia:[self connectingCamera].uuid remotePath:remoteFilePath willRefreshCameraMediasSoon:NO];
                if (self.currentFilter != nil && media.mediaType == MVMediaTypePhoto)
                {
                    [media transactionWithBlock:^{
                        media.filterID = self.currentFilter.uuid;
                    }];
                    [media saveCommonFields];
                }
            //});
            
            //sdcard storage
            int prevStorageState = storageState;
            self.storageState = (StorageState) saveDoneResponse.sd_full;
            self.totalStorage = saveDoneResponse.sd_total;
            self.freeStorage = saveDoneResponse.sd_free;
            self.photoCapacity = saveDoneResponse.remain_jpg;
            self.videoCapacity = saveDoneResponse.remain_video;
            [self sendMessageToHandler:MSG_STORAGE_STATE_CHANGED arg1:self.storageState arg2:prevStorageState object:nil];
            SettingTreeNode* optionNode = [MVCameraDevice findOptionNodeByUID:SettingNodeIDFormatSD];
            if (nil != optionNode && optionNode.subOptions.count > 0)
            {
                SettingTreeNode* subOptionNode = [optionNode findSubOptionByUID:0];
                subOptionNode.name = formatSDStorage(self.totalStorage, self.freeStorage);
            }
            [self sendMessageToHandler:MSG_STORAGE_TOTAL_FREE_CHANGED arg1:self.totalStorage arg2:self.freeStorage object:nil];
            
            [[MVMediaManager sharedInstance] resumeAllDownloadings];
            
            break;
        }
        case AMBA_MSGID_MP4_FILE_SPLIT_DONE:
        {
            NSString* remoteFilePath = [self remoteFilePathOfRTOSPath:((NSString*) response.param)];
            if (remoteFilePath && remoteFilePath.length > 0)
            {
                [[MVMediaManager sharedInstance] obtainCameraMedia:[self connectingCamera].uuid remotePath:remoteFilePath willRefreshCameraMediasSoon:NO];
            }
            break;
        }
        case AMBA_MSGID_GET_BATTERY_VOLUME:
        {
            [self handleBatteryResponse:[response.param intValue]];
            break;
        }
        case AMBA_MSGID_START_VIDEO_NORMAL:
        {
            if (self.isShooting)
            {
                return;
            }
#ifdef PAUSE_DOWNLOADING_WHILE_CAPTURING
            [[MVMediaManager sharedInstance] pauseAllDownloadings];
#endif
            self.cameraWorkState = CameraWorkStateCapturing;
            [self.connectingCamera transactionWithBlock:^{
                self.connectingCamera.cameraMode = CameraModeVideo;
                self.connectingCamera.cameraSubMode = CameraSubmodeVideoNormal;
                self.connectingCamera.cameraSubModeParam = 0;
            }];
            self.connectingCamera = [self.connectingCamera save];
            [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
            
            self.isShooting = YES;
            //self.isVideoCapturing = YES;
            NSLog(@"#Douyin#Callback# startShooting notified by Camera");
            [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
            [self startTimer:0 delaySeconds:0];
            break;
        }
        case AMBA_MSGID_START_VIDEO_MICRO:
        {
#ifdef PAUSE_DOWNLOADING_WHILE_CAPTURING
            [[MVMediaManager sharedInstance] pauseAllDownloadings];
#endif
            self.cameraWorkState = CameraWorkStateCapturingMicro;
            [self.connectingCamera transactionWithBlock:^{
                self.connectingCamera.cameraMode = CameraModeVideo;
                self.connectingCamera.cameraSubMode = CameraSubmodeVideoMicro;
                self.connectingCamera.cameraSubModeParam = [response.param intValue];
            }];
            self.connectingCamera = [self.connectingCamera save];
            [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
            
            self.isShooting = YES;
            //self.isVideoCapturing = YES;
            NSLog(@"#Callback# MSG_BEGIN_SHOOTING(micro) on cmdConnectionReceiveCameraResponse");
            [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
            [self startTimer:0 delaySeconds:0];
        }
            break;
        case AMBA_MSGID_START_VIDEO_TIMELAPSE:
        {
#ifdef PAUSE_DOWNLOADING_WHILE_CAPTURING
            [[MVMediaManager sharedInstance] pauseAllDownloadings];
#endif
            self.cameraWorkState = CameraWorkStateCapturingTimeLapse;
            [self.connectingCamera transactionWithBlock:^{
                self.connectingCamera.cameraMode = CameraModeVideo;
                self.connectingCamera.cameraSubMode = CameraSubmodeVideoTimelapse;
                self.connectingCamera.cameraSubModeParam = [response.param intValue];
            }];
            self.connectingCamera = [self.connectingCamera save];
            [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
            
            self.isShooting = YES;
            //self.isVideoCapturing = YES;
            NSLog(@"#Callback# MSG_BEGIN_SHOOTING(TimeLapse) on cmdConnectionReceiveCameraResponse");
            [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
            [self startTimer:0 delaySeconds:0];
            break;
        }
        case AMBA_MSGID_START_VIDEO_SLOWMOTION:
        {
#ifdef PAUSE_DOWNLOADING_WHILE_CAPTURING
            [[MVMediaManager sharedInstance] pauseAllDownloadings];
#endif
            self.cameraWorkState = CameraWorkStateCapturingSlowMotion;
            [self.connectingCamera transactionWithBlock:^{
                self.connectingCamera.cameraMode = CameraModeVideo;
                self.connectingCamera.cameraSubMode = CameraSubmodeVideoSlowMotion;
                self.connectingCamera.cameraSubModeParam = [response.param intValue];
            }];
            self.connectingCamera = [self.connectingCamera save];
            [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
            
            self.isShooting = YES;
            //self.isVideoCapturing = YES;
            NSLog(@"#Callback# MSG_BEGIN_SHOOTING(SlowMotion) on cmdConnectionReceiveCameraResponse");
            [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
            [self startTimer:0 delaySeconds:0];
            break;
        }
        case AMBA_MSGID_STOP_VIDEO:
        {
            NSLog(@"#Douyin#Callback# stopShooting notified by Camera");
            [self stopTimer];
            [self sendMessageToHandler:MSG_STOP_SHOOTING arg1:0 arg2:0 object:response.param];
            self.isShooting = NO;
            //self.isVideoCapturing = NO;
            break;
        }
        case AMBA_MSGID_SHOOT_PHOTO_TIMING:
        {
            [self handleTimingPhotoResponse:response];
            break;
        }
        case AMBA_MSGID_SHOOT_PHOTO_NORMAL:
        {
            if (CameraModePhoto == self.connectingCamera.cameraMode
                && (CameraSubmodePhotoFilter == self.connectingCamera.cameraSubMode || CameraSubmodePhotoNormal == self.connectingCamera.cameraSubMode))
            {
                self.isShooting = YES;
                self.cameraWorkState = CameraWorkStatePhotoing;
                [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
            }
            else
            {
                self.cameraWorkState = CameraWorkStatePhotoing;
                [self.connectingCamera transactionWithBlock:^{
                    self.connectingCamera.cameraMode = CameraModePhoto;
                    self.connectingCamera.cameraSubMode = CameraSubmodePhotoNormal;
                    self.connectingCamera.cameraSubModeParam = 0;
                }];
                self.connectingCamera = [self.connectingCamera save];
                [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
                
                self.isShooting = YES;
                [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
            }
            break;
        }
        case AMBA_MSGID_SHOOT_PHOTO_INTERVAL:
        {
            [self handleIntervalPhotoResponse:response];
            break;
        }
            /*
        case AMBA_PARAM_CAMERA_STATE_PHOTOING_INTERVAL:
        {
            self.isShooting = YES;
            self.cameraWorkState = CameraWorkStatePhotoingInterval;
            int count = [response.param intValue];
            if (count > -1)
            {
                self.connectingCamera.capIntervalNum = count;
                [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:count object:nil];
            }
            else
            {
                self.connectingCamera.capIntervalNum = 0;
                [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
            }
        }
            break;
             //*/
        case AMBA_MSGID_SHOOT_PHOTO_CONTINUOUS:
        {
            self.cameraWorkState = CameraWorkStatePhotoingContinuous;
            [self.connectingCamera transactionWithBlock:^{
                self.connectingCamera.cameraMode = CameraModePhoto;
                self.connectingCamera.cameraSubMode = CameraSubmodePhotoContinuous;
                self.connectingCamera.cameraSubModeParam = [response.param intValue];
            }];
            self.connectingCamera = [self.connectingCamera save];
            [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
            
            self.isShooting = YES;
            [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
        }
            break;
        case AMBA_MSGID_START_PHOTO_SURROUNDEXP:
        {
            [self handleSurroundexpPhotoResponse:response];
            /*
            self.cameraWorkState = CameraWorkStatePhotoingSurroundExp;
            [self.connectingCamera transactionWithBlock:^{
                self.connectingCamera.cameraMode = CameraModePhoto;
                self.connectingCamera.cameraSubMode = CameraSubmodePhotoSurroundExp;
                self.connectingCamera.cameraSubModeParam = [response.param intValue];
            }];
            self.connectingCamera = [self.connectingCamera save];
            [self sendMessageToHandler:MSG_MODE_CHANGED arg1:0 arg2:0 object:nil];
            
            self.isShooting = true;
            [self sendMessageToHandler:MSG_BEGIN_SHOOTING arg1:0 arg2:0 object:nil];
             */
        }
            break;
        case AMBA_MSGID_CLOSE_CAMERA:
        {
            [self disconnectCamera];
        }
            break;
        case AMBA_MSGID_CAMERA_OVERHEATED:
        {
            [self sendMessageToHandler:MSG_RECEIVE_NOTIFICATION arg1:AMBA_MSGID_CAMERA_OVERHEATED arg2:0 object:nil];
        }
            break;
        case AMBA_MSGID_RECOVERY_MEDIA_FILE:
        {
            [self sendMessageToHandler:MSG_RECEIVE_NOTIFICATION arg1:AMBA_MSGID_RECOVERY_MEDIA_FILE arg2:0 object:nil];
        }
            break;
        case AMBA_MSGID_START_LOOP_FAIL:
        {
            [self sendMessageToHandler:MSG_RECEIVE_NOTIFICATION arg1:AMBA_MSGID_START_LOOP_FAIL arg2:0 object:nil];
        }
            break;
        default:
            break;
    }
}

- (void) cmdConnectionHeartbeatRequired {
    //*
    //NSLog(@"onHeartbeatRequired : isHeartbeatEnabled = %@", self.isHeartbeatEnabledForDemander);
    if (self.isHeartbeatEnabledForDemander.count > 0)
    {
        //NSLog(@"onHeartbeatRequired Wakeup");
        [self wakeupCamera];
    }
     //*/
}

- (void) setHeartbeatEnabled:(BOOL)enabled forDemander:(NSString*)demander {
    NSLog(@"setHeartbeatEnabled : %d", enabled);
    if (enabled)
    {
        if (![self.isHeartbeatEnabledForDemander containsObject:demander])
        {
            [self.isHeartbeatEnabledForDemander addObject:demander];
            [self wakeupCamera];
        }
    }
    else
    {
        [self.isHeartbeatEnabledForDemander removeObject:demander];
    }
}

- (void) handleBatteryResponse:(int)voltage {
    if (voltage == AMBA_PARAM_BATTERY_CHARGE_FULL)
    {
        self.isCharging = NO;
    }
    else
    {
        self.isCharging = (0 != (voltage & 0x80));
    }
    switch (voltage & 0x0f)
    {
        case AMBA_PARAM_BATTERY_PERCENT5:
            self.voltagePercent = 5;
            break;
        case AMBA_PARAM_BATTERY_PERCENT25:
            self.voltagePercent = 25;
            break;
        case AMBA_PARAM_BATTERY_PERCENT50:
            self.voltagePercent = 50;
            break;
        case AMBA_PARAM_BATTERY_PERCENT75:
            self.voltagePercent = 75;
            break;
        case AMBA_PARAM_BATTERY_PERCENT100:
            self.voltagePercent = 100;
            break;
    }
    [self sendMessageToHandler:MSG_VOLTAGE_CHANGED arg1:self.voltagePercent arg2:(_isCharging ? 1 : 0) object:nil];
}

- (void) checkAndSynchronizeLUT:(NSString*)cameraUUID md5:(NSString*)md5 {
    NSString* lutBinFilePath = [MVPanoRenderer cameraLUTFilePath:cameraUUID];
    NSString* lutDirStr = [lutBinFilePath stringByDeletingPathExtension];
    DoctorLog(@"#BadLUT# checkAndSynchronizeLUT: response MD5 = %@, lutBinFilePath = %@", md5, lutBinFilePath);
    NSFileManager* fm = [NSFileManager defaultManager];
    
    BOOL(^checkMD5AndReturn)(BOOL) = ^(BOOL isExit) {
        DoctorLog(@"#BadLUT# checkAndSynchronizeLUT: checkMD5AndReturn isExit=%d", isExit);
        BOOL isDirectory = YES;
        if (![fm fileExistsAtPath:lutDirStr isDirectory:&isDirectory] || !isDirectory)
        {
            [fm removeItemAtPath:lutDirStr error:nil];
            [fm createDirectoryAtPath:lutDirStr withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        isDirectory = YES;
        if ([fm fileExistsAtPath:lutBinFilePath isDirectory:&isDirectory] && !isDirectory)
        {
            NSData* fileData = [NSData dataWithContentsOfFile:lutBinFilePath];
            NSString* localLUTMD5 = md5sum((unsigned char*)fileData.bytes, (UInt32)fileData.length);
            DoctorLog(@"#BadLUT# checkAndSynchronizeLUT: lutBinFilePath exists, Local MD5 = %@", localLUTMD5);
            if ([localLUTMD5 isEqualToString:md5] || !md5) //有时相机会出现无查找表的情况，这时也应允许连接，让用户在设置里恢复厂设来修复问题
            {
                extractLUTFiles(lutDirStr.UTF8String, lutBinFilePath.UTF8String, 0);
                @synchronized (self)
                {
                    DoctorLog(@"#BadLUT# checkAndSynchronizeLUT: #A0 isLUTSynchronized=%d, isSettingsSynchronized=%d, isConnectedStateNotified=%d", self.isLUTSynchronized, self.isSettingsSynchronized, self.isConnectedStateNotified);
                    self.isLUTSynchronized = YES;
                    if (self.isSettingsSynchronized)
                    {
                        if (!self.isConnectedStateNotified)
                        {
                            self.isConnectedStateNotified = YES;
                            [self setState:CameraClientStateConnected object:self.connectingCamera];
                        }
                    }
                }
                return YES;
            }
            else
            {
                DoctorLog(@"#BadLUT# checkAndSynchronizeLUT: Remove bad lutBinFile @ %@", lutBinFilePath);
                [fm removeItemAtPath:lutBinFilePath error:nil];
            }
        }
        
        if (isExit)
        {
            @synchronized (self)
            {
                DoctorLog(@"#BadLUT# checkAndSynchronizeLUT: #B0 isLUTSynchronized=%d, isSettingsSynchronized=%d, isConnectedStateNotified=%d", self.isLUTSynchronized, self.isSettingsSynchronized, self.isConnectedStateNotified);
                self.isLUTSynchronized = YES;
                if (self.isSettingsSynchronized)
                {
                    if (!self.isConnectedStateNotified)
                    {
                        self.isConnectedStateNotified = YES;
                        if (!md5)
                        {//有时相机会出现无查找表的情况，这时也应允许连接，让用户在设置里恢复厂设来修复问题
                            [self setState:CameraClientStateConnected object:self.connectingCamera];
                        }
                        else
                        {
                            [self setState:CameraClientStateNotConnected object:self.connectingCamera];
                        }
                    }
                }
            }
        }
        return NO;
    };
    
    if (checkMD5AndReturn(NO))
    {
        return;
    }
    
    BOOL isDirectory = YES;
    if (![fm fileExistsAtPath:lutDirStr isDirectory:&isDirectory] || !isDirectory)
    {
        [fm createDirectoryAtPath:lutDirStr withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    ContinuousFileDownloadCallback* downloadCallback = [[ContinuousFileDownloadCallback alloc] init];
    downloadCallback.errorBlock = ^(int errorCode, MVDownloadTask* downloadTask) {
        DoctorLog(@"#BadLUT# checkAndSynchronizeLUT: Download error=%d, setState CameraClientStateConnected", errorCode);
        checkMD5AndReturn(YES);
    };
    downloadCallback.allCompletedBlock = ^(MVDownloadTask* downloadTask) {
        DoctorLog(@"#BadLUT# checkAndSynchronizeLUT: Download complete");
        checkMD5AndReturn(YES);
    };
    DownloadChunk* downloadChunk = [[DownloadChunk alloc] initWithCameraUUID:cameraUUID remoteFilePath:@"/tmp/FL0/lut/app_lut.bin" localFilePath:lutBinFilePath size:0 downloadedSize:0];
    [[MVCameraDownloadManager sharedInstance] addContinuousFileDownloading:downloadChunk priority:MVDownloadTaskPriorityEmergency callback:downloadCallback];
}

//private String remoterFWLocalPath = AppStorageManager.getDownloadDir() + "/" + UserAppConst.CACHE_DOWNLOAD_BIN + "/";
//private String remoterFWRemotePath = UserAppConst.REMOTER_UPDATE_PATH;

#pragma mark --DataConnectionObserver代理方法的实现--
- (void)onDataConnectionStateChanged:(int)newState oldState:(int)oldState object:(id)object
{
    switch (self.state)
    {
        case CameraClientStateConnected:
        {
            if (newState == CmdSocketStateNotReady && (oldState == CmdSocketStateReady || oldState == CmdSocketStateDisconnecting))
            {
                ///!!![self disconnectCamera];
            }
            break;
        }
        case CameraClientStateDisconnecting:
            break;
        case CameraClientStateNotConnected:
            break;
        default:
            break;
    }
}
- (void)onReceiverEmptied
{
}

- (SettingTreeNode *)selectedParamOfOption:(int)optionUID
{
    SettingTreeNode * optionNode=[MVCameraDevice findOptionNodeByUID:optionUID];
    if (optionNode) {
        return [optionNode findSubOptionByUID:optionNode.selectedSubOptionUID];
    }
    return nil;
}

- (void)dealloc
{
    [[CMDConnectManager sharedInstance] removeObserver:self];
    [[DATAConnectManager sharedInstance] removeObserver:self];
}

+ (instancetype) sharedInstance
{
    static dispatch_once_t once;
    static MVCameraClient* instance;
    dispatch_once(&once, ^{
        if (instance==nil) {
            instance = [[MVCameraClient alloc] init];
        }
    });
    
    return instance;
}
+ (BOOL)isSdWhiteSd_mid:(NSInteger)sd_mid sd_oid:(NSInteger)sd_oid sd_pnm:(NSString *)sd_pnm
{
    NSString* where = [NSString stringWithFormat:@"sd_mid == '%ld' AND sd_oid == '%ld' AND sd_pnm == '%@'", (long)sd_mid,(long)sd_oid,sd_pnm];
    RLMResults * results = [SdWhiteDetail objectsWhere:where];
    BOOL flag = false;
    if (results.count > 0) {
        flag = true;
    }
    return flag;
}

@end
