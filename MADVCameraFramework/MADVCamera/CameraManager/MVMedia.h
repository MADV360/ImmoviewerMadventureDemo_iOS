//
//  MVMedia.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/10.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLModel.h"
#import <Photos/Photos.h>
#import "MVKxMovieViewController.h"
#import "AMBACommands.h"

// 下载状态枚举值：
typedef enum : NSInteger {
    MVMediaDownloadStatusNone = 0,//不在下载队列中,
    MVMediaDownloadStatusDownloading = 0x02,//正在下载,
    MVMediaDownloadStatusPending = 0x04,//排队中未下载,
    MVMediaDownloadStatusStopped = 0x08,//停止,
    MVMediaDownloadStatusFinished = 0x10,//已下载完成,
    MVMediaDownloadStatusError = 0x20,//发生错误而中止,
} MVMediaDownloadStatus;

typedef enum : NSInteger {
        MVMediaTypePhoto = 0,
        MVMediaTypeVideo = 1,
} MVMediaType;

typedef enum : NSInteger {
    FPS30_3456x1728 = 0,
    FPS30_2304x1152 = 1,
    FPS60_2304x1152 = 2,
    FPS30_3840x1920 = 6,
    FPS120_TOP_1920x480 = 7,
    FPS120_MIDDLE_1920x480 = 8,
    FPS120_BOTTOM_1920x480 = 9,
} VideoCaptureResolution;

@interface MVMedia : RLModel <NSCopying>
/**
 * 获得该媒体文件的下载状态
 */
@property(nonatomic,assign) MVMediaDownloadStatus downloadStatus;

/**
 * 获得该媒体文件的类型
 */
@property(nonatomic,assign) MVMediaType mediaType;
@property(nonatomic,assign) MVMediaType dbMediaType;

/**
 * 如果该媒体文件来自相机，则返回该相机的唯一ID；否则若该媒体纯粹来自手机本地，则返回null
 */
@property(nonatomic,copy)NSString * cameraUUID;
@property(nonatomic,copy)NSString * dbCameraUUID;

/**
 * 如果该媒体文件来自相机，则返回其在相机上的相对路径（相对于存储卡根目录）；否则若该媒体纯粹来自手机本地，则返回null
 */
@property(nonatomic,copy)NSString * remotePath;
@property(nonatomic,copy)NSString * dbRemotePath;

/**
 * 若该媒体纯粹来自手机本地，返回自本地存储根目录(Documents目录)的相对路径
 */
@property(nonatomic,copy)NSString * localPath;
@property(nonatomic,copy)NSString * dbLocalPath;

/**
 * 返回该媒体文件的缩略图文件的本地路径（.png格式）
 */
@property(nonatomic,copy)NSString * thumbnailImagePath;
@property(nonatomic,copy)NSString * dbThumbnailImagePath;

@property(nonatomic,copy)NSString * snapshotImagePath;
@property(nonatomic,copy)NSString * dbSnapshotImagePath;

/**
 * 获得该媒体文件的创建日期
 */
@property(nonatomic,strong) NSDate * createDate;
@property(nonatomic,strong) NSDate * dbCreateDate;

/**
 * 获得该媒体文件的最后修改日期
 */
@property(nonatomic,strong)NSDate * modifyDate;
@property(nonatomic,strong)NSDate * dbModifyDate;

/**
 * 获得该媒体文件的总大小（字节数）
 */
@property(nonatomic,assign) NSInteger size;
@property(nonatomic,assign) NSInteger dbSize;

/**
 * 获得该媒体文件已下载到本地的大小（字节数）
 */
@property(nonatomic,assign) NSInteger downloadedSize;
@property(nonatomic,assign) NSInteger dbDownloadedSize;

@property (nonatomic, copy) NSData* downloadResumeData;
@property (nonatomic, copy) NSData* dbDownloadResumeData;

/**
 * 获得视频时长
 */
@property(nonatomic,assign) CGFloat videoDuration;
@property(nonatomic,assign) CGFloat dbVideoDuration;

/**
 * 获得该媒体文件所应用的图像滤镜ID（目前仅针对图片）
 */
@property(nonatomic,assign) NSInteger filterID;
@property(nonatomic,assign) NSInteger dbFilterID;

/**
 * 图片是否是已拼接好的
 */
@property(nonatomic,assign) BOOL isStitched;
@property(nonatomic,assign) BOOL dbIsStitched;

@property(nonatomic,copy) NSString* gyroMatrixString;
@property(nonatomic,copy) NSString* dbGyroMatrixString;

@property(nonatomic,assign) VideoCaptureResolution videoCaptureResolution;
@property(nonatomic,assign) VideoCaptureResolution dbVideoCaptureResolution;

/** 可唯一标识一个媒体对象的字符串，可以用作字典的key使用 */
- (NSString *)storageKey;

/** 判断该MVMedia对象与other是否源自同一个相机媒体文件 */
- (BOOL)isEqualRemoteMedia:(MVMedia *)other;

/**
 * 根据指定的(cameraUUID, remotePath, localPath)三元组查询MVMedia
 * */
+ (instancetype) querySavedMediaWithCameraUUID:(NSString *)cameraUUID remotePath:(NSString *)remotePath localPath:(NSString *)localPath;

/**
 * 查询包含指定的(cameraUUID, remotePath)二元组的所有MVMedia。
 * 如果没有(cameraUUID, remotePath)二元组，表示是纯本地媒体，则只按localPath查询
 * @param cameraUUID
 * @param remotePath
 * @param localPath
 * @return
 */
+ (NSArray<MVMedia *> *)querySavedMediasWithCameraUUID:(NSString *)cameraUUID remotePath:(NSString *)remotePath localPath:(NSString *)localPath;

#pragma mark    Protected

/**
 * 保存到手机相册后标示用;分割开
 */
@property(nonatomic,copy)NSString * localIdentifier;

@property(nonatomic,copy)NSString * dbLocalIdentifier;

@property(nonatomic,assign)NSInteger finishDownloadedSize;
@property(nonatomic,assign)int error;

@property(nonatomic,copy)NSString * shotDateTime;//拍照时间
@property(nonatomic,copy)NSString * dbShotDateTime;
//@property(nonatomic,copy)NSString * maker;
@property(nonatomic,copy)NSString * model;//设备型号
@property(nonatomic,copy)NSString * dbModel;
@property(nonatomic,assign)int xResolution;
@property(nonatomic,assign)int dbXResolution;
@property(nonatomic,assign)int yResolution;
@property(nonatomic,assign)int dbYResolution;
@property(nonatomic,copy)NSString * exposureTime;//快门时间
@property(nonatomic,copy)NSString * dbExposureTime;
@property(nonatomic,assign)long ISO;
@property(nonatomic,assign)long dbISO;
@property(nonatomic,assign)int whiteBalance;//白平衡
@property(nonatomic,assign)int dbWhiteBalance;
@property(nonatomic,assign)float longitude;//经度
@property(nonatomic,assign)float dbLongitude;
@property(nonatomic,assign)float latitude;//纬度
@property(nonatomic,assign)float dbLatitude;
@property(nonatomic,assign)float altitude;//高度
@property(nonatomic,assign)float dbAltitude;
@property(nonatomic,copy)NSString * resolution;
@property(nonatomic,copy)NSString * exposureBiasValue;//曝光补偿
@property(nonatomic,copy)NSString * dbExposureBiasValue;
@property(nonatomic,copy)NSString * location;//位置
@property(nonatomic,assign)BOOL isLocationHandled;

@property(nonatomic,strong)AVAsset * avAsset;
@property(nonatomic,copy)NSString * videoPath;

@property(nonatomic,assign)BOOL isTimeElapsedVideo;
@property(nonatomic,assign)BOOL isDbTimeElapsedVideo;

@property(nonatomic,assign)CGFloat fps;
@property(nonatomic,assign)CGFloat dbFps;

@property(nonatomic,assign)QualityLevel encoderQualityLevel;


+ (NSString *)storageKeyWithCameraUUID:(NSString *)cameraUUID remotePath:(NSString *)remotePath localPath:(NSString *)localPath;

+ (NSString*) uniqueLocalPathWithCameraUUID:(NSString*)cameraUUID remotePath:(NSString*)remotePath;

+ (instancetype) create;

+ (instancetype) createWithCameraUUID:(NSString *)cameraUUID remoteFullPath:(NSString *)remoteFullPath;

+ (NSArray<MVMedia *> *)queryDownloadedMedias;

+ (NSDictionary<NSString*, MVMedia* >*) querySavedMediasWithCameraUUID:(NSString*)cameraUUID;

+ (instancetype) querySavedMediaWithRemotePath:(NSString*)remotePath localPath:(NSString*)localPath;

//获取已经下载好的media
+ (MVMedia *)obtainDownloadedMedia:(MVMedia *)media;

+ (NSString *)StringOfDownloadStatus:(int)status;

+ (NSDate*) dateFromFileName:(NSString*)lowerFileName;

- (MVMedia *) obtainDownloadedOrThisMedia;

- (NSString*) requestLocalFilePath:(void(^)(NSString* localPath))completionHandler;

- (id) localFilePathSync;

- (void)saveCommonFields;
- (void)copyCommonFields:(MVMedia *)media;

- (void)update;

- (id) copy:(id)obj;

+ (void) test;
- (BOOL)isLocalMediaExistence;
- (PHAsset*)getSystemAlbumAsset;
@end
