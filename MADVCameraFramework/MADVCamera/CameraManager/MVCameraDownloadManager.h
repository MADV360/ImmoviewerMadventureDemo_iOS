//
//  MVCameraDownloadManager.h
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "DATAConnectManager.h"
#import "CMDConnectManager.h"
#import "MVMedia.h"

extern const int DownloadInitChunkSize;
extern const int DownloadChunkSize;
extern const int DefaultBufferSize;

typedef enum : NSInteger {
    MVDownloadTaskPriorityEmergency = 3,
    MVDownloadTaskPriorityHigh = 2,
    MVDownloadTaskPriorityLow = 1,
    MVDownloadTaskPriorityTrivial = 0,
    
    MVDownloadTaskPriorities = 4
} MVDownloadTaskPriority;

typedef enum : int {
    MVDownloadTaskCategoryAMBATCP = 0,
    MVDownloadTaskCategoryHTTP = 1,
    
    MVDownloadTaskCategories = 2
} MVDownloadTaskCategory;

@interface MVDownloadTask : DataReceiver

- (instancetype) initWithPriority:(MVDownloadTaskPriority)priority;

- (void) start;

- (void) cancel;

@property (nonatomic, assign) MVDownloadTaskPriority priority;

@end


typedef void(^ThumbnailDownloadCompletedBlock)(Byte* data, int bytesReceived, BOOL isNotStitched, MVDownloadTask* downloadTask);

typedef void(^ThumbnailDownloadErrorBlock)(NSString* errMsg, MVDownloadTask* downloadTask);

typedef void(^FileDownloadGotSizeBlock)(NSInteger remSize, NSInteger totalSize, MVDownloadTask* downloadTask);

typedef void(^FileDownloadCompletedBlock)(NSInteger bytesReceived, MVDownloadTask* downloadTask);

typedef void(^FileDownloadCanceledBlock)(NSInteger bytesReceived, MVDownloadTask* downloadTask);

typedef void(^FileDownloadErrorBlock)(int errorCode, MVDownloadTask* downloadTask);

typedef void(^FileDownloadProgressUpdatedBlock)(NSInteger totalBytes, NSInteger downloadedBytes, MVDownloadTask* downloadTask);

typedef void(^FileDownloadAllCompletedBlock)(MVDownloadTask* downloadTask);


@interface DownloadChunk : NSObject

@property (nonatomic, assign) NSInteger size;
@property (nonatomic, assign) NSInteger downloadedSize;

@property (nonatomic, copy) NSString* cameraUUID;
@property (nonatomic, copy) NSString* remoteFilePath;
@property (nonatomic, copy) NSString* localFilePath;

- (instancetype) initWithCameraUUID:(NSString*)cameraUUID remoteFilePath:(NSString*)remoteFilePath localFilePath:(NSString*)localFilePath size:(NSInteger)size downloadedSize:(NSInteger)downloadedSize;

@end


@interface ThumbnailDownloadCallback : NSObject

@property (nonatomic, strong) ThumbnailDownloadCompletedBlock completedBlock;
@property (nonatomic, strong) ThumbnailDownloadErrorBlock errorBlock;

- (instancetype) initWithCompletedBlock:(ThumbnailDownloadCompletedBlock)completedBlock errorBlock:(ThumbnailDownloadErrorBlock)errorBlock;

@end

typedef enum : NSInteger {
    FileDownloadErrorMD5CheckFailed = 1,
    FileDownloadErrorNoSuchRemoteFile = 2,
    FileDownloadErrorTransferring = 3,
    FileDownloadErrorReceiving = 4,
    FileDownloadErrorTimeout = 5,
    FileDownloadErrorCanceled = 6,
    FileDownloadErrorOtherRequestFailure = 7,
    FileDownloadErrorCameraBusy = 8,
    FileDownloadErrorWriteFileFailure = 9,
} FileDownloadError;

@interface FileDownloadCallback : NSObject

@property (nonatomic, strong) FileDownloadGotSizeBlock gotSizeBlock;
@property (nonatomic, strong) FileDownloadCompletedBlock completedBlock;
@property (nonatomic, strong) FileDownloadCanceledBlock canceledBlock;
@property (nonatomic, strong) FileDownloadProgressUpdatedBlock progressBlock;
@property (nonatomic, strong) FileDownloadErrorBlock errorBlock;

- (instancetype) initWithGotSizeBlock:(FileDownloadGotSizeBlock)gotSizeBlock completedBlock:(FileDownloadCompletedBlock)completedBlock canceledBlock:(FileDownloadCanceledBlock)canceledBlock progressBlock:(FileDownloadProgressUpdatedBlock)progressBlock errorBlock:(FileDownloadErrorBlock)errorBlock;

@end


@interface ContinuousFileDownloadCallback : FileDownloadCallback

//@property (nonatomic, strong) FileDownloadGotSizeBlock gotSizeBlock;
//@property (nonatomic, strong) FileDownloadCompletedBlock completedBlock;
//@property (nonatomic, strong) FileDownloadCanceledBlock canceledBlock;
//@property (nonatomic, strong) FileDownloadProgressUpdatedBlock progressBlock;
//@property (nonatomic, strong) FileDownloadErrorBlock errorBlock;

@property (nonatomic, strong) FileDownloadAllCompletedBlock allCompletedBlock;

- (instancetype) initWithPriority:(MVDownloadTaskPriority)priority initChunkSize:(NSInteger)initChunkSize normalChunkSize:(NSInteger)normalChunkSize;

@property (nonatomic, strong) DownloadChunk* chunk;

@end


@interface HTTPDownloadCallback : FileDownloadCallback

@property (nonatomic, strong) FileDownloadAllCompletedBlock allCompletedBlock;

- (instancetype) initWithGotSizeBlock:(FileDownloadGotSizeBlock)gotSizeBlock completedBlock:(FileDownloadCompletedBlock)completedBlock allCompletedBlock:(FileDownloadAllCompletedBlock)allCompletedBlock canceledBlock:(FileDownloadCanceledBlock)canceledBlock progressBlock:(FileDownloadProgressUpdatedBlock)progressBlock errorBlock:(FileDownloadErrorBlock)errorBlock;

@end


@interface ThumbnailDownloadTask : MVDownloadTask <CMDConnectionObserver>

- (instancetype) initWithPriority:(MVDownloadTaskPriority)priority remotePath:(NSString*)remotePath isVideo:(BOOL)isVideo callback:(ThumbnailDownloadCallback*)callback;

@end


@interface FileDownloadTask : MVDownloadTask <CMDConnectionObserver>

- (instancetype) initWithPriority:(MVDownloadTaskPriority)priority remotePath:(NSString*)remotePath fileOffset:(NSInteger)fileOffset chunkSize:(NSInteger)chunkSize localFilePath:(NSString*)localFilePath callback:(FileDownloadCallback*)callback;

@property (nonatomic, strong) FileDownloadCallback* callback;

@property (nonatomic, copy, readonly) NSString* remoteFilePath;

@property (nonatomic, copy, readonly) NSString* localFilePath;

@end


@interface HTTPDownloadTask : MVDownloadTask

- (instancetype) initWithPriority:(MVDownloadTaskPriority)priority remoteFilePath:(NSString*)remoteFilePath offset:(NSInteger)offset resumeData:(NSData*)resumeData localFilePath:(NSString*)localFilePath chunkSize:(int)chunkSize callback:(HTTPDownloadCallback*)callback;

@property (nonatomic, strong) HTTPDownloadCallback* callback;

@property (nonatomic, copy, readonly) NSString* remoteFilePath;

@property (nonatomic, copy, readonly) NSData* resumeData;

@property (nonatomic, copy, readonly) NSString* localFilePath;

@property (nonatomic, assign, readonly) int chunkSize;

@end


@interface AFHTTPDownloadTask : MVDownloadTask

- (instancetype) initWithPriority:(MVDownloadTaskPriority)priority remoteFilePath:(NSString*)remoteFilePath offset:(NSInteger)offset length:(NSInteger)length localFilePath:(NSString*)localFilePath callback:(HTTPDownloadCallback*)callback;

@property (nonatomic, strong) HTTPDownloadCallback* callback;

@property (nonatomic, copy, readonly) NSString* remoteFilePath;

@property (nonatomic, copy, readonly) NSString* localFilePath;

@end


@interface MVCameraDownloadManager : NSObject

+ (NSString*) downloadingTempFilePath:(NSString*)downloadDestinationPath;

+ (instancetype) sharedInstance;

- (void) addTask:(MVDownloadTask*)task addAsFirst:(BOOL)addAsFirst;
- (void) addTask:(MVDownloadTask*)task category:(MVDownloadTaskCategory)category addAsFirst:(BOOL)addAsFirst;

- (void) removeTask:(MVDownloadTask*)task;
- (void) removeTask:(MVDownloadTask*)task category:(MVDownloadTaskCategory)category;
- (void) removeTasks:(NSArray<MVDownloadTask* >*)tasks;
- (void) removeAllTasks;

- (void) pollTaskOfategory:(MVDownloadTaskCategory)category;

- (BOOL) addContinuousFileDownloading:(DownloadChunk*)chunk;

- (BOOL) addContinuousFileDownloading:(DownloadChunk*)chunk priority:(MVDownloadTaskPriority)priority;

- (BOOL) addContinuousFileDownloading:(DownloadChunk*)chunk priority:(MVDownloadTaskPriority)priority callback:(ContinuousFileDownloadCallback*)callback;

- (BOOL) addContinuousFileDownloading:(DownloadChunk*)chunk callback:(ContinuousFileDownloadCallback*)callback;

- (BOOL) addContinuousFileDownloading:(DownloadChunk*)chunk priority:(MVDownloadTaskPriority)priority initChunkSize:(NSInteger)initChunkSize normalChunkSize:(NSInteger)normalChunkSize callback:(ContinuousFileDownloadCallback*)callback;

+ (NSString*) localFilePathWithRemotePath:(NSString*)remotePath cameraUUID:(NSString*)cameraUUID;

@end
