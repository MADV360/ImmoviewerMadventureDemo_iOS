//
//  MVCameraDevice.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/9.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVCameraDevice.h"
#import "XMLTool.h"
#import "helper.h"
#import "RealmSerialQueue.h"
#import "MVMedia.h"
#import "NSString+Extensions.h"
#import "MVCameraClient.h"
#ifdef MADVPANO_BY_SOURCE
#import "MadvGLRenderer.h"
#else
#import <MADVPano/MadvGLRenderer.h>
#endif

#define XmlTagGroup @"group"
#define XmlTagOption @"option"
#define XmlTagParam @"param"
#define XmlAttrUID @"uid"
#define XmlAttrMsgID @"msgID"
#define XmlAttrName @"name"
#define XmlAttrType @"type"
#define XmlAttrValue @"value"
#define XmlValueTypeReadOnly @"readonly"
#define XmlValueTypeSingle @"single"
#define XmlValueTypeSlider @"slider"
#define XmlValueTypeAction @"action"
#define XmlValueTypeJump @"jump"
static NSMutableArray<SettingTreeNode *> * deviceSettingsList;
@interface MVCameraDevice()


@end

@implementation MVCameraDevice

@synthesize recentMedia;
@synthesize isCharging;
@synthesize cameraPreviewMode;
@synthesize firmwareUpdateState;

+ (instancetype) create {
    __block MVCameraDevice* ret = nil;
    [[RealmSerialQueue shareRealmQueue] sync:^{
        ret = [[MVCameraDevice alloc] init];
        ret.cameraPreviewMode = PanoramaDisplayModeStereoGraphic;
    }];
    return ret;
}

- (void) initImpersistentMembers {
//    [self transactionWithBlock:^{
//        self.cameraPreviewMode = PanoramaDisplayModeStereoGraphic;
//    }];
}

- (instancetype) init {
    if (self = [super init])
    {
        [self initImpersistentMembers];
    }
    return self;
}

#pragma mark --set、get方法--
- (NSString *)SSID
{
    return [self dbValueForKeyPath:@"DBSSID"];
}

- (void) setSSID:(NSString *)SSID {
    self.DBSSID = SSID;
}

- (NSString *)password
{
    return [self dbValueForKeyPath:@"DBPassword"];
}

- (void) setPassword:(NSString *)password {
    self.DBPassword = password;
}

- (NSString *)uuid
{
    return [self dbValueForKeyPath:@"DBUuid"];
}

- (void) setUuid:(NSString *)uuid {
    self.DBUuid = [MVCameraClient formattedCameraUUID:uuid];
}

- (NSString *)fwVer
{
    return [self dbValueForKeyPath:@"DBFwVer"];
}

- (void) setFwVer:(NSString *)fwVer {
    self.DBFwVer = fwVer;
}

- (NSString *)rcFwVer
{
    return [self dbValueForKeyPath:@"DBRcFwVer"];
}

- (void) setRcFwVer:(NSString *)rcFwVer {
    self.DBRcFwVer = rcFwVer;
}

- (NSString *)serialID
{
    return [self dbValueForKeyPath:@"DBSerialID"];
}

- (void) setSerialID:(NSString *)serialID {
    self.DBSerialID = serialID;
}

- (NSDate *)lastSyncTime
{
    return [self dbValueForKeyPath:@"DBLastSyncTime"];
}

- (void) setLastSyncTime:(NSDate *)lastSyncTime {
    self.DBLastSyncTime = lastSyncTime;
}

- (int)jpgCaptured
{
    return [[self dbValueForKeyPath:@"DBJpgCaptured"] intValue];
}

- (void) setJpgCaptured:(int)jpgCaptured {
    self.DBJpgCaptured = jpgCaptured;
}

- (int)mp4Captured
{
    return [[self dbValueForKeyPath:@"DBMp4Captured"] intValue];
}

- (void) setMp4Captured:(int)mp4Captured {
    self.DBMp4Captured = mp4Captured;
}

/**
 * 获取相机全部设置项，以树状结构给出
 * 第一级列表：分组标题
 * 第二级列表：分组中的设置项
 * 第三级列表：分组中设置项下可选的全部设置值，如果该列表为空则说明是一个单一功能选项，比如当设置项为“格式化SD卡”时
 * @return
 */
+ (NSArray<SettingTreeNode *> *)getCameraSettings
{
    if (deviceSettingsList==nil) {
        
        deviceSettingsList=[[NSMutableArray alloc] init];
        NSString * path = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle]pathForResource:@"en" ofType:@"lproj"],@"device_settings.txt"];
        NSData * xmlData= [NSData dataWithContentsOfFile:path];
        
        NSArray * arr = [XMLTool xmlToolWithXMLData:xmlData];
        for(NSDictionary * nodeDict in arr)
        {
            SettingTreeNode* treeNode = [SettingTreeNode settingTreeNodeWithDict:nodeDict];
            [deviceSettingsList addObject:treeNode];
        }
    }
    return deviceSettingsList;
}

+ (SettingTreeNode *)findOptionNodeByUID:(int)optionUID
{
    SettingTreeNode * setTreeNode;
    for(SettingTreeNode * treeNode in deviceSettingsList)
    {
        for(SettingTreeNode * optionNode in treeNode.subOptions)
        {
            if (optionNode.uid==optionUID) {
                setTreeNode=optionNode;
                break;
            }
        }
        if (setTreeNode) {
            break;
        }
    }
    return setTreeNode;
}

+(SettingTreeNode *)getCameraModeParameters:(CameraMode)cameraMode cameraSubMode:(CameraSubMode)cameraSubMode
{
    NSString * path = @"";
    path = [[FGLanguageTool sharedInstance] getFilePath:@"camera_mode_params.txt"];
    NSData * xmlData= [NSData dataWithContentsOfFile:path];
    
    NSArray * arr = [XMLTool xmlToolWithXMLData:xmlData];
    SettingTreeNode * treeNode;
    if (cameraMode==CameraModePhoto&&cameraSubMode==CameraSubmodePhotoTiming) {
        treeNode=[SettingTreeNode cameraModeParamNodeWithDict:arr[0] modeName:FGGetStringWithKeyFromTable(PHOTO, nil) subModeName:FGGetStringWithKeyFromTable(PHOTOTIMING, nil)];
    }
    if (cameraMode==CameraModePhoto && cameraSubMode==CameraSubmodePhotoInterval) {
        treeNode=[SettingTreeNode cameraModeParamNodeWithDict:arr[0] modeUid:1 subModeUid:4];
    }
    if (cameraMode==CameraModePhoto && cameraSubMode==CameraSubmodePhotoSurroundExp) {
        treeNode=[SettingTreeNode cameraModeParamNodeWithDict:arr[0] modeUid:1 subModeUid:5];
    }
    if (cameraMode==CameraModeVideo && cameraSubMode==CameraSubmodeVideoTimelapse)
    {
        treeNode=[SettingTreeNode cameraModeParamNodeWithDict:arr[0] modeName:FGGetStringWithKeyFromTable(CAMERASHOOT, nil) subModeName:FGGetStringWithKeyFromTable(VIDEOTIMELAPSE, nil)];
    }
    if (cameraMode==CameraModeVideo&&cameraSubMode==CameraSubmodeVideoMicro)
    {
        treeNode=[SettingTreeNode cameraModeParamNodeWithDict:arr[0] modeName:FGGetStringWithKeyFromTable(CAMERASHOOT, nil) subModeName:FGGetStringWithKeyFromTable(VIDEOMICRO, nil)];
    }
    if (cameraMode==CameraModeVideo&&cameraSubMode==CameraSubmodeVideoSlowMotion)
    {
        treeNode=[SettingTreeNode cameraModeParamNodeWithDict:arr[0] modeName:FGGetStringWithKeyFromTable(CAMERASHOOT, nil) subModeName:FGGetStringWithKeyFromTable(VIDEOSLOWMOTION, nil)];
    }
    if (cameraMode == CameraModeVideo && cameraSubMode==CameraSubmodeVideoSlowMotion) {
        treeNode=[SettingTreeNode cameraModeParamNodeWithDict:arr[0] modeUid:0 subModeUid:5];
    }
    return treeNode;
}
- (MVCameraDevice *)save
{
    NSLog(@"%@",[NSThread currentThread]);
    __block MVCameraDevice * deviceTemp = nil;
    MVCameraDevice* device= [MVCameraDevice selectWithUUID:self.uuid];
    if (device) {
        [device copy:self];
    }
    else
    {
        [self insert];
    }
    
    deviceTemp = [MVCameraDevice create];
    [deviceTemp copy:self];
    return deviceTemp;
}

//- (void) update
//{
//    RLMRealm* realm = [RLMRealm defaultRealm];
//    [realm transactionWithBlock:^{
//        [realm commitWriteTransaction];
//    }];
//}

- (void)copy:(id)sender
{
    MVCameraDevice * device=(MVCameraDevice *)sender;
    [self transactionWithBlock:^{
        self.uuid=device.uuid;
        //self.DBUuid=device.DBUuid;
        self.SSID=device.SSID;
        //self.DBSSID=device.DBSSID;
        self.password=device.password;
        //self.DBPassword=device.DBPassword;
        self.lastSyncTime=device.lastSyncTime;
        //self.DBLastSyncTime=device.DBLastSyncTime;
        self.fwVer=device.fwVer;
        //self.DBFwVer=device.DBFwVer;
        self.rcFwVer=device.rcFwVer;
        self.serialID=device.serialID;
        //self.DBSerialID=device.DBSerialID;
        self.jpgCaptured = device.jpgCaptured;
        self.mp4Captured = device.mp4Captured;
        self.isConnect=device.isConnect;
        self.voltagePercent=device.voltagePercent;
        self.isWifiConnect=device.isWifiConnect;
        self.thumbnailImage=device.thumbnailImage;
        self.isConnecting=device.isConnecting;
        self.connectionState=device.connectionState;
        self.cameraMode=device.cameraMode;
        self.cameraSubMode=device.cameraSubMode;
        self.cameraSubModeParam=device.cameraSubModeParam;
        self.recentMedia = device.recentMedia;
        self.videoSegmentSeconds = device.videoSegmentSeconds;
        self.videoCaptureResolution = device.videoCaptureResolution;
        self.cameraPreviewMode = device.cameraPreviewMode;
//        self.isCharging = device.isCharging;
    }];
    self.firmwareUpdateState = device.firmwareUpdateState;
//    self.cameraPreviewMode = device.cameraPreviewMode;
    self.isCharging = device.isCharging;
}

- (void)delete
{
        [self remove];
}

+ (MVCameraDevice *)selectWithUUID:(NSString *)uuid
{
    __block MVCameraDevice * device = nil;
    if (![helper isNull:uuid]) {
        [[RealmSerialQueue shareRealmQueue] sync:^{
            RLMRealm* realm = [RLMRealm defaultRealm];
            [realm transactionWithBlock:^{
                RLMResults * results=[MVCameraDevice objectsWhere:[NSString stringWithFormat:@"DBUuid == '%@'",uuid]];
                if (results.count > 0) {
                    device = results[0];
                }
                [realm commitWriteTransaction];
            }];
        }];
    }
    [device initImpersistentMembers];
    return device;
}


- (BOOL) shouldSetWiFiPassword {
    __block BOOL isShouldSetWiFiPassword;
    [[RealmSerialQueue shareRealmQueue] sync:^{
        isShouldSetWiFiPassword = (!self.password || self.password.length == 0);
    }];
    return isShouldSetWiFiPassword;
}

- (BOOL) isEqual:(id)object {
    //TODO:
    return [super isEqual:object];
}

- (NSString*) description {
    //TODO:
    return [super description];
}

- (NSUInteger) hash {
    //TODO:
    return [super hash];
}


//数据库忽略该属性 不操作该属性
+ (NSArray *)ignoredProperties {
    return @[@"SSID",@"password",@"uuid",@"fwVer",@"rcFwVer",@"serialID",@"lastSyncTime",@"isConnect",@"voltagePercent",@"isWifiConnect",@"thumbnailImage",@"isConnecting",@"connectionState",@"cameraMode",@"cameraSubMode",@"cameraSubModeParam",@"recentMedia",@"isCharging", @"firmwareUpdateState", @"jpgCaptured", @"mp4Captured", @"videoSegmentSeconds", @"capIntervalNum", @"videoCaptureResolution"];
}

//属性的默认值
+ (NSDictionary *)defaultPropertyValues {
    //return @{@"DBUuid":@""};
    return @{@"uuid":@""};
}


@end
