//
//  MVMediaManager.h
//  Madv360_v1
//  封装了与相机相册、本地相册有关的方法，包括获取文件列表、下载文件和缩略图等
//  Created by 张巧隔 on 16/8/10.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVCameraClient.h"
#import "MVMedia.h"

typedef enum : int {
    DataSetEventAddNew,
    DataSetEventDeletes,
    DataSetEventRefresh,
    DataSetEventReplace,
} DataSetEvent;

/** 错误代码枚举 */
typedef enum : NSInteger {
    MVMediaManagerErrorNotAllDeleted = 1,
} MVMediaManagerErrorCode;

//通用的进度回调block类型定义
typedef void(^ProgressiveActionBlock)(int completedCount, int totalCount, BOOL* cancel);

/** 媒体文件摘要信息 */
@interface MediaThummaryResult : NSObject
//缩略图
    @property (nonatomic, strong) UIImage* thumbnail;
//缩略图本地路径
//@property (nonatomic, copy) NSString* thumbnailPath;

@property (nonatomic, strong) UIImage* snapshot;
//@property (nonatomic, copy) NSString* snapshotPath;

//对应的MVMedia对象中包含的其它MediaInfo（如视频时长、分辨率、文件大小等）是否已获取到了。如果是则直接通过MVMedia对象的属性即可查询到相应属性值，否则会在#didFetchMediaInfo#回调中异步获得
    @property (nonatomic, assign) BOOL isMediaInfoAvailable;
    
@end

/** 媒体列表数据源监听者 */
@protocol MVMediaDataSourceObserver <NSObject>

/**
 * 相机媒体列表有更新
 * @param medias : 发生变化的相机媒体对象列表
 * @param dataSetEvent : 见#DataSetEvent#枚举，表示发生变化的对象列表是新增抑或删除抑或替换抑或全部刷新
 * @param errorCode : 错误代码
 */
-(void)didCameraMediasReloaded:(NSArray<MVMedia *> *) medias dataSetEvent:(DataSetEvent)dataSetEvent errorCode:(int)errorCode;

/**
 * 本地媒体列表有更新
 * @param medias : 发生变化的本地媒体对象列表
 * @param dataSetEvent : 见#DataSetEvent#枚举，表示发生变化的对象列表是新增抑或删除抑或替换抑或全部刷新
 */
-(void) didLocalMediasReloaded:(NSArray<MVMedia *> *) medias dataSetEvent:(DataSetEvent)dataSetEvent;

/** 异步获取媒体缩略图的回调
 * media: 需要获取缩略图的媒体对象对象
 * image: 缩略图
 */
-(void)didFetchThumbnailImage:(UIImage *)image ofMedia:(MVMedia*)media error:(int)error;

/**
 * 异步获取媒体信息的回调
 * @param media 获取到媒体信息的媒体对象，可以从其中用get方法读取视频时长等信息
 */
-(void)didFetchMediaInfo:(MVMedia *)media error:(int)error;

/** 异步获取到最近拍摄的一个媒体文件的缩略图
 * @param media 获取到媒体信息的媒体对象，可以从其中用get方法读取视频时长等信息
 * @param image 缩略图UIImage对象
 */
- (void) didFetchRecentMediaThumbnail:(MVMedia*)media image:(UIImage*)image error:(int)error;

@end

/** 媒体对象下载状态监听者 */
@protocol MVMediaDownloadStatusObserver <NSObject>
/** 下载状态发生变化
 * 注意：当某一项已下载完成变成MVMediaDownloadStatusFinished状态时，该项会被从下载队列列表中移动到本地媒体列表中，因此这两处UI此时都应更新
 * media: 发生下载状态变化的媒体对象
 * downloadStatus: 当前该媒体对象的下载状态，是MVMedia对象中定义的枚举值
 * errorMessage: 发生错误时的错误提示信息
 */
- (void) didDownloadStatusChange:(int)downloadStatus errorCode:(int)errorCode ofMedia:(MVMedia*)media;

/** 多项媒体文件的下载状态发生批量变化（发生在下载管理页面用户批量操作时）
 *
 */
- (void) didBatchDownloadStatusChange:(int)downloadStatus ofMedias:(NSArray<MVMedia *>*)medias;

/** 下载进度通知回调
 * media: 发生下载进度变化的媒体对象
 */
- (void) didDownloadProgressChange:(NSInteger)downloadedBytes totalBytes:(NSInteger)totalBytes ofMedia:(MVMedia*)media;

/**
 * 因相机开始录像而主动暂停下载时，回调到此方法
 */
- (void) didDownloadingsHung;

- (void) didReceiveStorageWarning;

@end

#define ThumbnailWidth 400
#define ThumbnailHeight 200
#define SnapshotWidth 720
#define SnapshotHeight 360

/** 媒体库管理器（包括相机和本地）*/
@interface MVMediaManager : NSObject <MVCameraClientObserver>

- (void)addMediaDataSourceObserver:(id<MVMediaDataSourceObserver>)observer;
- (void)removeMediaDataSourceObserver:(id<MVMediaDataSourceObserver>)observer;

- (void)addMediaDownloadStatusObserver:(id<MVMediaDownloadStatusObserver>)observer;
- (void)removeMediaDownloadStatusObserver:(id<MVMediaDownloadStatusObserver>)observer;

/** 相机媒体库是否可以访问。亦即当前是否有连接的相机（实际上直接用MVCameraClient单例的connectingCamera()是否为nil判断也一样） */
- (BOOL)isCameraMediaLibraryAvailable;

/** 同步或异步获取当前连接相机上的所有媒体对象，以MVMedia对象数组的形式给出
 * forceRefresh: 是否强制更新
 * @return: 当直接返回非空数组时，表示相机媒体列表无需刷新，直接使用返回数组即可，
 * 否则若返回null，表示需刷新，随后会通过回调MediaDataSourceObserver的didCameraMediasReloaded方法给出最新列表
 * */
-(NSArray<MVMedia*>*) cameraMedias:(BOOL)forceRefresh;

- (BOOL) continueCameraFilesIterating;
- (BOOL) pauseCameraFilesIterating;

/** 同步或异步获取当前手机本地的所有媒体对象，以MVMedia对象数组的形式给出
 * forceRefresh: 是否强制更新
 * @return: 当直接返回非空数组时，表示本地媒体列表无需刷新，直接使用返回数组即可，
 * 否则若返回null，表示需刷新，随后会通过回调MediaDataSourceObserver的didLocalMediasReloaded方法给出最新列表
 * */
- (NSArray<MVMedia*>*) localMedias:(BOOL)forceRefresh;
- (NSArray<MVMedia*>*) localMedias;

/** 获取指定媒体对象的缩略图，如果缓存里有则直接返回Bitmap，否则异步回调给所有注册的MediaDataSourceObserver */
//-(UIImage *) getThumbnailImage:(MVMedia *) media;

//-(NSString *) getThumbnailLocalPath:(MVMedia *) media;

/** 获取指定媒体对象的媒体信息，包括视频时长等等。
 * @return: 如果MVMedia对象中已经可以get到正确结果，则返回true；否则返回false，在MediaDataSourceObserver的didFetchMediaInfo()回调中返回结果
 * */
//-(BOOL) getMediaInfo:(MVMedia*)media;

/** 获取媒体文件摘要信息(缩略图、MediaInfo各属性值)。如果其中有任一个部分未获取到，则会去异步获取，在有关回调中获得 */
- (MediaThummaryResult*) getMediaThummary:(MVMedia*)media;

- (MediaThummaryResult*) getMediaThummary:(MVMedia *)media findInCache:(BOOL)findInCache;

- (UIImage*) getSnapshotOfMedia:(MVMedia*)media pShouldStitch:(BOOL*)pShouldStitch;

- (UIImage*) getCachedMediaThumbnail:(NSString*)cacheKey;

+ (NSString*) getMediaThumbnailPath:(MVMedia*)media;

/** 删除相机上的媒体文件 */
-(void) deleteCameraMedias:(NSArray *)medias progressBlock:(void(^)(MVMedia* currentDeletedMedia, int deletedCount, int totalCount, BOOL* stop))progressBlock;

/** 删除本地的媒体文件 */
- (void) deleteLocalMedias:(NSArray *) medias;
/** 删除存在系统相册里本地的媒体文件 */
- (void) deleteLocalSystemAlbumMedias:(NSArray *) medias phassets:(NSArray *)assets completionHandler:(nullable void(^)(BOOL success, NSError *__nullable error))completionHandler;

/** 将媒体对象添加到下载队列，返回是否成功（不成功原因就是当前未连接到对应相机） */
-(BOOL) addDownloading:(MVMedia *) media;

- (void) addDownloadingOfMedias:(NSArray<MVMedia* >*)medias completion:(dispatch_block_t)completion progressBlock:(ProgressiveActionBlock)progressBlock;

/** 从下载队列中移除媒体对象 */
-(void) removeDownloading:(MVMedia *) media;

/** 继续下载（断点续传），返回是否成功（不成功原因就是当前未连接到对应相机） */
//-(BOOL) restartDownloading:(MVMedia *) media;

/** 停止（暂停）下载 */
-(void) stopDownloading:(MVMedia *) media;

- (void) stopDownloadingOfMedias:(NSArray<MVMedia* >*)medias;

/** 暂停全部下载任务（在相机正在摄像时） */
- (void) pauseAllDownloadings;
/** 恢复全部下载任务（在相机停止摄像时）*/
- (void) resumeAllDownloadings;

/** 获取当前下载队列中的所有媒体对象
 * 当上述addDownloading或removeDownloading方法
 * 被调用，使得下载队列发生变化时，应该通过getMediasInDownloader获得下载队列列表，
 * 给显示下载列表的ListView更新数据源。
 * 而下载列表中某一项的下载状态发生变化时，则是通过回调MediaDownloadStatusObserver接口的方式进行通知
 */
-(NSArray<MVMedia *> *) mediasInDownloader;

/** 是否有处于下载队列中的文件 */
- (BOOL) hasDownloadingTasks;

/** 导入媒体文件
 *  @param medias 媒体文件对象。要么全是视频要么全是图片
 *  @param isVideo paths所包含的媒体文件是视频还是图片
 */
- (void) importMedias:(NSArray<MVMedia *> *) medias isVideo:(BOOL)isVideo;

@property (nonatomic, assign) BOOL downloadMediasIntoDocuments;

#pragma mark    Protected

- (MVMedia *)obtainCameraMedia:(NSString *)cameraUUID remotePath:(NSString *)remotePath willRefreshCameraMediasSoon:(BOOL)willRefreshCameraMediasSoon;

- (MVMedia*) obtainCameraMediaInMedias:(NSDictionary<NSString*, MVMedia* >*)medias cameraUUID:(NSString*)cameraUUID remotePath:(NSString *)remotePath willRefreshCameraMediasSoon:(BOOL)willRefreshCameraMediasSoon;

+ (id)sharedInstance;
+ (void) writeEXIFDataFromJPEG:(NSString*)jpegPath toMedia:(MVMedia*)media;
//导出的时候调用这个 用来刷新是否拼接
- (void) onCameraDataSourceUpdated:(NSArray<MVMedia* >*)medias dataSetEvent:(DataSetEvent)dataSetEvent errorCode:(int)errorCode;
//导出的时候调用这个 用来刷新是否拼接
- (void) onLocalDataSourceUpdated:(NSArray<MVMedia* >*)medias dataSetEvent:(DataSetEvent)dataSetEvent;
@end
