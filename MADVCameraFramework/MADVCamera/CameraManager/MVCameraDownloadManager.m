                                                                        //
//  MVCameraDownloadManager.m
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVCameraDownloadManager.h"
#import "NSRecursiveCondition.h"
#import "NSMutableArray+Extensions.h"
#import "DATAConnectManager.h"
#import "MVCameraClient.h"
#import "AMBARequest.h"
#import "AMBAGetThumbnailResponse.h"
#import "AMBAFileTransferResultResponse.h"
#import "AMBACancelFileTransferResponse.h"
#import "AMBAGetFileRequest.h"
#import "AMBAGetFileResponse.h"
#import "MVCameraClient.h"
#import "SocketHelper.h"
#import "z_Sandbox.h"
#import "AMBACommands.h"
#import <AFNetworking/AFNetworking.h>

const int DownloadInitChunkSize = 1024;
const int DownloadChunkSize = 1024*1024*2;

const int DefaultBufferSize = (DownloadInitChunkSize > DownloadChunkSize ? DownloadInitChunkSize : DownloadChunkSize);

@interface ThumbnailDownloadCallback ()
{
    ThumbnailDownloadCompletedBlock _completedBlock;
    ThumbnailDownloadErrorBlock _errorBlock;
}

@end

@implementation ThumbnailDownloadCallback

@synthesize completedBlock = _completedBlock;
@synthesize errorBlock = _errorBlock;

- (instancetype) initWithCompletedBlock:(ThumbnailDownloadCompletedBlock)completedBlock errorBlock:(ThumbnailDownloadErrorBlock)errorBlock {
    if (self = [super init])
    {
        _completedBlock = completedBlock;
        _errorBlock = errorBlock;
    }
    return self;
}

@end

@interface FileDownloadCallback ()
{
    FileDownloadGotSizeBlock _gotSizeBlock;
    FileDownloadCompletedBlock _completeBlock;
    FileDownloadCanceledBlock _canceledBlock;
    FileDownloadProgressUpdatedBlock _progressBlock;
    FileDownloadErrorBlock _errorBlock;
}
@end

@implementation FileDownloadCallback

@synthesize gotSizeBlock = _gotSizeBlock;
@synthesize completedBlock = _completedBlock;
@synthesize canceledBlock = _canceledBlock;
@synthesize progressBlock = _progressBlock;
@synthesize errorBlock = _errorBlock;

- (instancetype) initWithGotSizeBlock:(FileDownloadGotSizeBlock)gotSizeBlock completedBlock:(FileDownloadCompletedBlock)completedBlock canceledBlock:(FileDownloadCanceledBlock)canceledBlock progressBlock:(FileDownloadProgressUpdatedBlock)progressBlock errorBlock:(FileDownloadErrorBlock)errorBlock {
    if (self = [super init])
    {
        _gotSizeBlock = gotSizeBlock;
        _completedBlock = completedBlock;
        _canceledBlock = canceledBlock;
        _progressBlock = progressBlock;
        _errorBlock = errorBlock;
    }
    return self;
}

@end

@interface MVDownloadTask ()
{
    MVDownloadTaskPriority _priority;
}
@end

@implementation MVDownloadTask

@synthesize priority = _priority;

- (instancetype) init {
    if (self = [super init])
    {
        _priority = MVDownloadTaskPriorityHigh;
    }
    return self;
}

- (instancetype) initWithPriority:(MVDownloadTaskPriority)priority {
    if (self = [super init])
    {
        _priority = priority;
    }
    return self;
}

- (void) start {}

- (void) cancel {
    [self finish];
}

@end

@interface MVCameraDownloadManager ()
{
    NSMutableDictionary<NSNumber*, MVDownloadTask* >* _currentDownloadingTaskOfCategory;
    
    NSMutableArray<MVDownloadTask*>* _downloadTaskQueuesOfCategory[MVDownloadTaskCategories][MVDownloadTaskPriorities];
    
    Byte* _sharedBuffer;
    NSUInteger _sharedBufferSize;
    
    NSRecursiveCondition* _cond;
}
@end

@implementation MVCameraDownloadManager

+ (instancetype) sharedInstance {
    static dispatch_once_t once;
    static MVCameraDownloadManager* singleton = nil;
    _dispatch_once(&once, ^{
        singleton = [[MVCameraDownloadManager alloc] init];
    });
    return singleton;
}

- (void) dealloc {
//    [[DATAConnectManager sharedInstance] removeObserver:self];
    free(_sharedBuffer);
}

- (instancetype) init {
    if (self = [super init])
    {
        _cond = [[NSRecursiveCondition alloc] init];
        
        _sharedBuffer = (Byte*)malloc(DefaultBufferSize);
        _sharedBufferSize = DefaultBufferSize;
        
        _currentDownloadingTaskOfCategory = [[NSMutableDictionary alloc] init];
        for (int iCat=0; iCat<MVDownloadTaskCategories; ++iCat)
        {
            for (int i=0; i<MVDownloadTaskPriorities; ++i)
            {
                _downloadTaskQueuesOfCategory[iCat][i] = [[NSMutableArray alloc] init];
            }
        }
        
//        [[DATAConnectManager sharedInstance] addObserver:self];
    }
    return self;
}

#define DOWNLOADING_FILE_EXT @"down"
+ (NSString*) downloadingTempFilePath:(NSString*)downloadDestinationPath {
    NSString* fileName = [[downloadDestinationPath lastPathComponent] stringByAppendingPathExtension:DOWNLOADING_FILE_EXT];
    return [z_Sandbox cachesFilePath:fileName];
}

+ (MVDownloadTaskCategory) categoryOfTask:(MVDownloadTask*)task {
    if ([task isKindOfClass:HTTPDownloadTask.class] || [task isKindOfClass:AFHTTPDownloadTask.class])
        return MVDownloadTaskCategoryHTTP;
    else
        return MVDownloadTaskCategoryAMBATCP;
}

- (void) addTask:(MVDownloadTask*)task addAsFirst:(BOOL)addAsFirst {
    MVDownloadTaskCategory category = [self.class categoryOfTask:task];
    [self addTask:task category:category addAsFirst:addAsFirst];
}

- (void) addTask:(MVDownloadTask*)task category:(MVDownloadTaskCategory)category addAsFirst:(BOOL)addAsFirst {
    if (category < 0 || category >= MVDownloadTaskCategories) return;
    
    [_cond lock];
    
    [[DATAConnectManager sharedInstance] openConnection];
    
    MVDownloadTask* currentTask = _currentDownloadingTaskOfCategory[@(category)];
    if (!currentTask)
    {
        [_currentDownloadingTaskOfCategory setObject:task forKey:@(category)];
        NSLog(@"AFHTTPDownload#pause : addTask execute immediately : _currentDownloadingTaskOfCategory[%d] = %@, _currentDownloadingTaskOfCategory=%@", (int)category, task, _currentDownloadingTaskOfCategory);
        [self executeTask:task];
    }
    else
    {
        for (int i=MVDownloadTaskPriorities-1; i>=0; --i)
        {
            if ([_downloadTaskQueuesOfCategory[category][i] containsObject:task])
            {
                [_cond unlock];
                NSLog(@"AFHTTPDownload#pause : addTask In queue already : _downloadTaskQueuesOfCategory[%d][%d] = %@", (int)category, (int)i, task);
                return;
            }
        }
        
        if ([currentTask isEqual:task])
        {
            [_cond unlock];
            NSLog(@"AFHTTPDownload#pause : addTask Is downloading : _currentDownloadingTaskOfCategory[%d] = %@", (int)category, task);
            return;
        }
        
        if (addAsFirst)
        {
            [_downloadTaskQueuesOfCategory[category][task.priority] insertObject:task atIndex:0];
        }
        else
        {
            [_downloadTaskQueuesOfCategory[category][task.priority] addObject:task];
        }
        NSLog(@"AFHTTPDownload#pause : Queue : _downloadTaskQueuesOfCategory[%d][%d] = %@", (int)category, (int)task.priority, task);
        
        if ((MVDownloadTaskPriorityEmergency == task.priority ||
             MVDownloadTaskPriorityTrivial == currentTask.priority)
            && (currentTask.priority < task.priority))
        {
            NSLog(@"AFHTTPDownload#pause : Exchange with : _currentDownloadingTaskOfCategory[%d] = %@", (int)category, currentTask);
            [currentTask cancel];
            if (addAsFirst)
            {
                [_downloadTaskQueuesOfCategory[category][currentTask.priority] insertObject:currentTask atIndex:0];
            }
            else
            {
                [_downloadTaskQueuesOfCategory[category][currentTask.priority] addObject:currentTask];
            }
        }
    }
    
    [_cond unlock];
}

- (void) removeTask:(MVDownloadTask*)task {
    MVDownloadTaskCategory category = [self.class categoryOfTask:task];
    [self removeTask:task category:category];
}

- (void) removeTasks:(NSArray<MVDownloadTask* >*)tasks {
    [_cond lock];
    {
        BOOL found = NO;
        
        for (int iCat=0; iCat<MVDownloadTaskCategories; ++iCat)
        {
            for (int iPri=0; iPri<MVDownloadTaskPriorities; ++iPri)
            {
                NSUInteger prevCount = _downloadTaskQueuesOfCategory[iCat][iPri].count;
                [_downloadTaskQueuesOfCategory[iCat][iPri] removeObjectsInArray:tasks];
                if (_downloadTaskQueuesOfCategory[iCat][iPri].count != prevCount)
                {
                    found = YES;
                    //NSLog(@"#Bug3269#AFHTTPDownload#pause : removeTasks from queue OK : _downloadTaskQueuesOfCategory[%d][%d].count = %d, tasks = %@", (int)iCat, (int)iPri, (int)_downloadTaskQueuesOfCategory[iCat][iPri].count, tasks);
                }
            }
        }
        
        for (int iCat=0; iCat<MVDownloadTaskCategories; ++iCat)
        {
            MVDownloadTask* currentTask = [_currentDownloadingTaskOfCategory objectForKey:@(iCat)];
            //NSLog(@"#Bug3269#AFHTTPDownload#pause : removeTasks: category=%d, _currentDownloadingTaskOfCategory=%@", iCat, _currentDownloadingTaskOfCategory);
            if ([tasks containsObject:currentTask])
            {
                found = YES;
                //NSLog(@"#Bug3269#AFHTTPDownload#pause : removeTasks OK : _currentDownloadingTaskOfCategory[%d] will be nil, = %@", iCat, currentTask);
                [_currentDownloadingTaskOfCategory removeObjectForKey:@(iCat)];
                [currentTask cancel];
                //NSLog(@"#Bug3269#AFHTTPDownload#pause : removeTasks Done : _currentDownloadingTaskOfCategory = %@", _currentDownloadingTaskOfCategory);
            }
        }
    }
    [_cond unlock];
}

- (void) removeTask:(MVDownloadTask*)task category:(MVDownloadTaskCategory)category {
    [_cond lock];
    BOOL found = NO;
    
    for (int i=0; i<MVDownloadTaskPriorities; ++i)
    {
        NSUInteger prevCount = _downloadTaskQueuesOfCategory[category][i].count;
        [_downloadTaskQueuesOfCategory[category][i] removeObject:task];
        if (_downloadTaskQueuesOfCategory[category][i].count != prevCount)
        {
            found = YES;
            NSLog(@"AFHTTPDownload#pause : removeTask from queue OK : _downloadTaskQueuesOfCategory[%d][%d].count = %d, task = %@", (int)category, (int)i, (int)_downloadTaskQueuesOfCategory[category][i].count, task);
        }
    }
    
    MVDownloadTask* currentTask = [_currentDownloadingTaskOfCategory objectForKey:@(category)];
    NSLog(@"AFHTTPDownload#pause : removeTask: category=%d, task=%@, _currentDownloadingTaskOfCategory=%@", category, task, _currentDownloadingTaskOfCategory);
    if ([currentTask isEqual:task])
    {
        found = YES;
        NSLog(@"AFHTTPDownload#pause : removeTask OK : _currentDownloadingTaskOfCategory[%d] will be nil, = %@, task = %@", category, currentTask, task);
        [_currentDownloadingTaskOfCategory removeObjectForKey:@(category)];
        [task cancel];
        NSLog(@"AFHTTPDownload#pause : removeTask Done : _currentDownloadingTaskOfCategory = %@", _currentDownloadingTaskOfCategory);
    }
    
    if (!found)
    {
        NSLog(@"AFHTTPDownload#pause : removeTask Not found. _currentDownloadingTaskOfCategory[%d] = %@, _currentDownloadingTaskOfCategory=%@", (int)category, currentTask, _currentDownloadingTaskOfCategory);
    }
    
    [_cond unlock];
}

- (void) pollTaskOfCategory:(MVDownloadTaskCategory)category {
    MVDownloadTask* task = nil;
    [_cond lock];
    {
        for (int i=MVDownloadTaskPriorityEmergency; i>=MVDownloadTaskPriorityTrivial; --i)
        {
            
            if (0 < _downloadTaskQueuesOfCategory[category][i].count)
            {
                task = [_downloadTaskQueuesOfCategory[category][i] poll];
                NSLog(@"AFHTTPDownload# pollTaskOfCategory : task = _downloadTaskQueuesOfCategory[%d][%d] = %@", (int)category, (int)i, task);
                if (task)
                {
                    break;
                }
            }
        }
        
        if (task)
        {
            [_currentDownloadingTaskOfCategory setObject:task forKey:@(category)];
        }
        else
        {
            [_currentDownloadingTaskOfCategory removeObjectForKey:@(category)];
        }
        NSLog(@"AFHTTPDownload# pollTaskOfCategory : _currentDownloadingTaskOfCategory[%d] = %@, _currentDownloadingTaskOfCategory=%@", (int)category, _currentDownloadingTaskOfCategory[@(category)], _currentDownloadingTaskOfCategory);
    }
    [_cond unlock];
    
//    [_cond lock];
    {
        if (task)
        {
            [self executeTask:task];
        }
    }
//    [_cond unlock];
}

- (void) removeAllTasks {
    [_cond lock];
    {
        for (int category=0; category<MVDownloadTaskCategories; ++category)
        {
            [_currentDownloadingTaskOfCategory removeAllObjects];
            NSLog(@"AFHTTPDownload# removeAllTasks : _currentDownloadingTaskOfCategory = %@", _currentDownloadingTaskOfCategory);
            for (int i=MVDownloadTaskPriorityEmergency; i>=MVDownloadTaskPriorityTrivial; --i)
            {
                [_downloadTaskQueuesOfCategory[category][i] removeAllObjects];
            }
        }
    }
    [_cond unlock];
}

- (void) executeTask:(MVDownloadTask*)task {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![task isKindOfClass:HTTPDownloadTask.class] && ![task isKindOfClass:AFHTTPDownloadTask.class])
        {
            [[DATAConnectManager sharedInstance] waitForState:DataSocketStateReady];
            //[[MVCameraClient sharedInstance] waitForState:CameraClientStateConnected];
            [DATAConnectManager sharedInstance].dataReceiver = task;
        }
        [task start];
    });
}

- (Byte*) resizeSharedBufferIfNecessary:(NSUInteger)newSize {
    [_cond lock];
    if (newSize > _sharedBufferSize)
    {
        _sharedBufferSize = newSize;
        if (_sharedBuffer) free(_sharedBuffer);
        _sharedBuffer = (Byte*)malloc(newSize);
    }
    [_cond unlock];
    return _sharedBuffer;
}

- (Byte*) sharedBuffer {
    return _sharedBuffer;
}

- (NSInteger) sharedBufferSize {
    return _sharedBufferSize;
}

+ (NSString*) localFilePathWithRemotePath:(NSString*)remotePath cameraUUID:(NSString*)cameraUUID {
    remotePath = [remotePath stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    cameraUUID = [MVCameraClient formattedCameraUUID:cameraUUID];
    return [[@"" stringByAppendingString:cameraUUID] stringByAppendingString:remotePath];
}

- (BOOL) addContinuousFileDownloading:(DownloadChunk *)chunk priority:(MVDownloadTaskPriority)priority initChunkSize:(NSInteger)initChunkSize normalChunkSize:(NSInteger)normalChunkSize callback:(ContinuousFileDownloadCallback *)callback {
    if (!chunk)
        return NO;
    
    MVCameraDevice* connectingDevice = [MVCameraClient sharedInstance].connectingCamera;
    if (!connectingDevice || ![connectingDevice.uuid isEqualToString:chunk.cameraUUID])
        return NO;
    
    NSInteger rangeStart, rangeLength;
    if (0 == chunk.size)
    {
        rangeStart = 0;
        rangeLength = initChunkSize;
    }
    else
    {
        rangeStart = chunk.downloadedSize;
        rangeLength = chunk.size - chunk.downloadedSize;
        if (rangeLength > normalChunkSize)
            rangeLength = normalChunkSize;
        else if (0 == rangeLength)
            return YES;
    }
    
    if (!chunk.localFilePath || chunk.localFilePath.length == 0)
    {
        chunk.localFilePath = [self.class localFilePathWithRemotePath:chunk.remoteFilePath cameraUUID:chunk.cameraUUID];
    }
    
    FileDownloadTask* downloadTask = [[FileDownloadTask alloc] initWithPriority:priority remotePath:chunk.remoteFilePath fileOffset:rangeStart chunkSize:(int)rangeLength localFilePath:chunk.localFilePath callback:nil];
    
    if (!callback)
    {
        callback = [[ContinuousFileDownloadCallback alloc] initWithPriority:priority initChunkSize:initChunkSize normalChunkSize:normalChunkSize];
    }
    callback.chunk = chunk;
    downloadTask.callback = callback;
    
    [[MVCameraDownloadManager sharedInstance] addTask:downloadTask addAsFirst:YES];
    
    return YES;
}

- (BOOL) addContinuousFileDownloading:(DownloadChunk *)chunk priority:(MVDownloadTaskPriority)priority callback:(ContinuousFileDownloadCallback *)callback {
    return [self addContinuousFileDownloading:chunk priority:priority initChunkSize:DownloadInitChunkSize normalChunkSize:DownloadChunkSize callback:callback];
}

- (BOOL) addContinuousFileDownloading:(DownloadChunk *)chunk callback:(ContinuousFileDownloadCallback *)callback {
    return [self addContinuousFileDownloading:chunk priority:MVDownloadTaskPriorityHigh callback:callback];
}

- (BOOL) addContinuousFileDownloading:(DownloadChunk *)chunk priority:(MVDownloadTaskPriority)priority {
    return [self addContinuousFileDownloading:chunk priority:priority initChunkSize:DownloadInitChunkSize normalChunkSize:DownloadChunkSize callback:nil];
}

- (BOOL) addContinuousFileDownloading:(DownloadChunk *)chunk {
    return [self addContinuousFileDownloading:chunk priority:MVDownloadTaskPriorityHigh callback:nil];
}

@end

#pragma mark    ThumbnailDownloadTask

@interface ThumbnailDownloadTask ()
{
    NSString* _remotePath;
    BOOL _isVideo;
    ThumbnailDownloadCallback* _callback;
    
    NSInteger _bytesToReceive;
    NSInteger _bytesReceived;
    
    NSString* _remoteMD5;
    NSString* _localMD5;
    
    BOOL _callbackInvoked;
}

@property (nonatomic, copy) NSString* remotePath;
@property (nonatomic, assign) BOOL isVideo;
@property (nonatomic, assign) BOOL isNotStitched;

@end

@implementation ThumbnailDownloadTask

@synthesize remotePath = _remotePath;
@synthesize isVideo = _isVideo;
@synthesize isNotStitched;

static const NSUInteger ThumbnailDownloadBufferSize = 1024 * 2048;

- (instancetype) initWithPriority:(MVDownloadTaskPriority)priority remotePath:(NSString *)remotePath isVideo:(BOOL)isVideo callback:(ThumbnailDownloadCallback*)callback {
    if (self = [super initWithPriority:priority])
    {
        if ([[remotePath uppercaseString] hasSuffix:@"AA.MP4"])
        {
            remotePath = [[remotePath substringToIndex:(remotePath.length - @"AA.MP4".length)] stringByAppendingString:@"AB.MP4"];
        }
        _remotePath = remotePath;
        _isVideo = isVideo;
        _callback = callback;
        
        _bytesReceived = 0;
        _bytesReceived = 0;
        
        _callbackInvoked = NO;
    }
    return self;
}

- (void) start {
    [[MVCameraDownloadManager sharedInstance] resizeSharedBufferIfNecessary:ThumbnailDownloadBufferSize];
//    [[CMDConnectManager sharedInstance] addObserver:self];
    
    AMBARequest* getThumbRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        AMBAGetThumbnailResponse* getThumbResponse = (AMBAGetThumbnailResponse*) response;
        if (!getThumbResponse) return;
        
        if (!getThumbResponse.isRvalOK)
        {
            [self invokeCallbackAndExit:@"RequestFailed"];
            return;
        }
        
        _bytesToReceive = getThumbResponse.size;
        _remoteMD5 = getThumbResponse.md5sum;
        //NSLog(@"Get Thumbnail Response: _bytesToReceive=%ld, _bytesReceived=%ld, LocalMD5=%@, RemoteMD5=%@", _bytesToReceive, _bytesReceived, _localMD5, _remoteMD5);
        ///!!!For Debug
#ifdef LUT_STITCH_PICTURE
        self.isNotStitched = YES;
#else
        self.isNotStitched = NO;
#endif
        
        if ([self isFinished])
        {
            @synchronized (self)
            {
                if (!_localMD5)
                {
                    _localMD5 = md5sum([[MVCameraDownloadManager sharedInstance] sharedBuffer], (int)_bytesToReceive);
                }
            }
            
            if ([_localMD5 isEqualToString:_remoteMD5])
            {
                //NSLog(@"Get Thumbnail DONE #0: _bytesToReceive=%ld, _bytesReceived=%ld, LocalMD5=%@, RemoteMD5=%@", _bytesToReceive, _bytesReceived, _localMD5, _remoteMD5);
                [self invokeCallbackAndExit:nil];
            }
            else
            {
                //NSLog(@"Get Thumbnail Error #0: _bytesToReceive=%ld, _bytesReceived=%ld, LocalMD5=%@, RemoteMD5=%@", _bytesToReceive, _bytesReceived, _localMD5, _remoteMD5);
                [self invokeCallbackAndExit:[NSString stringWithFormat:@"Thumbnail MD5 check#0 Failed: Local=%@, Remote=%@", _localMD5, _remoteMD5]];
            }
        }
        
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        [self invokeCallbackAndExit:@"Request Failed Or Timeout"];
    } responseClass:NSClassFromString(@"AMBAGetThumbnailResponse")];
    getThumbRequest.msgID = AMBA_MSGID_GET_THUMB;
    getThumbRequest.token = [[MVCameraClient sharedInstance] sessionToken];
    getThumbRequest.type = (_isVideo ? @"idr":@"thumb");
    getThumbRequest.param = _remotePath;
    [[CMDConnectManager sharedInstance] sendRequest:getThumbRequest];
}

- (int) onReceiveData:(UInt8 *)data offset:(int)offset length:(int)length {
    if (!data) return 0;
    
    memcpy([[MVCameraDownloadManager sharedInstance] sharedBuffer] + _bytesReceived, data + offset, length);
    _bytesReceived += length;
    
    if ([self isFinished])
    {
        @synchronized (self)
        {
            if (!_localMD5)
            {
                ///!!!For Debug 20161123: _localMD5 = md5sum([[MVCameraDownloadManager sharedInstance] sharedBuffer], (int)_bytesToReceive);
            }
        }
        //NSLog(@"Get Thumbnail onReceiveData: _bytesToReceive=%ld, _bytesReceived=%ld, LocalMD5=%@, RemoteMD5=%@", _bytesToReceive, _bytesReceived, _localMD5, _remoteMD5);
        if (_remoteMD5)
        {
            ///!!!For Debug 20161123: if ([_localMD5 isEqualToString:_remoteMD5])
            {
                //NSLog(@"Get Thumbnail DONE #1: _bytesToReceive=%ld, _bytesReceived=%ld, LocalMD5=%@, RemoteMD5=%@", _bytesToReceive, _bytesReceived, _localMD5, _remoteMD5);
                [self invokeCallbackAndExit:nil];
            }/*///!!!For Debug 20161123:
            else
            {
                [self invokeCallbackAndExit:[NSString stringWithFormat:@"Thumbnail MD5 check#1 Failed: Local=%@, Remote=%@", _localMD5, _remoteMD5]];
            }
              //*/
        }
    }
    
    return (int)_bytesReceived;
}

- (BOOL) isFinished {
    return (_bytesToReceive > 0 && _bytesToReceive <= _bytesReceived);
}

- (void) onError:(int)error errMsg:(NSString *)errMsg {
    [self invokeCallbackAndExit:errMsg];
}

- (BOOL) checkCallbackInvoked {
    @synchronized (self)
    {
        if (_callbackInvoked)
            return YES;
        
        _callbackInvoked = YES;
        return NO;
    }
}

- (void) invokeCallbackAndExit:(NSString*)errMsg {
    if ([self checkCallbackInvoked])
    {
        //NSLog(@"Get Thumbnail invokeCallbackAndExit return");
        return;
    }

    [[CMDConnectManager sharedInstance] removeObserver:self];
    
    if (errMsg)
    {
        if (_callback.errorBlock)
        {
            _callback.errorBlock(errMsg, self);
        }
    }
    else if (_callback.completedBlock)
    {
        _callback.completedBlock([[MVCameraDownloadManager sharedInstance] sharedBuffer], (int)_bytesReceived, self.isNotStitched, self);
    }
    
    [[DATAConnectManager sharedInstance] removeDataReceiver:self];
    [[MVCameraDownloadManager sharedInstance] pollTaskOfCategory:MVDownloadTaskCategoryAMBATCP];
}

- (BOOL) isEqual:(id)object {
    if (![object isKindOfClass:ThumbnailDownloadTask.class])
        return NO;
    
    ThumbnailDownloadTask* other = (ThumbnailDownloadTask*) object;
    if (!_remotePath)
        return (!other.remotePath || other.remotePath.length == 0);
    else
        return ([_remotePath isEqualToString:other.remotePath] && _isVideo == other.isVideo);
}

- (NSString*) description {
    return [NSString stringWithFormat:@"ThumbnailDownloadTask(%lx) : remotePath='%@', isVideo=%d", (unsigned long)self.hash, _remotePath, _isVideo];
}

@end


static NSString* ErrorMD5CheckFailed = @"ErrorMD5CheckFailed";
static NSString* ErrorRequestFailed = @"ErrorRequestFailed";
static NSString* ErrorTransferring = @"ErrorTransferring";
static NSString* ErrorReceiving = @"ErrorReceiving";
static NSString* ErrorTimeout = @"ErrorTimeout";
static NSString* ErrorCanceled = @"ErrorCanceled";
static NSString* ErrorWriteFileFailure = @"ErrorWriteFileFailure";

@interface FileDownloadTask ()
{
    NSInteger _bytesToReceive;
    NSInteger _bytesReceived;
    
    NSString* _remoteMD5;
    NSString* _localMD5;
    
    int _errorCode;
    
    BOOL _canceled;
    BOOL _callbackInvoked;
    
    NSString* _remoteFilePath;
    NSString* _localFilePath;
    NSInteger _fileOffset;
    NSInteger _chunkSize;
    
    FileDownloadCallback* _callback;
}

@property (nonatomic, copy) NSString* remoteFilePath;
@property (nonatomic, copy) NSString* localFilePath;
@property (nonatomic, assign) NSInteger fileOffset;
@property (nonatomic, assign) NSInteger chunkSize;

@end


@implementation FileDownloadTask

@synthesize remoteFilePath = _remoteFilePath;
@synthesize localFilePath = _localFilePath;
@synthesize fileOffset = _fileOffset;
@synthesize chunkSize = _chunkSize;

@synthesize callback = _callback;

- (instancetype) initWithPriority:(MVDownloadTaskPriority)priority remotePath:(NSString *)remotePath fileOffset:(NSInteger)fileOffset chunkSize:(NSInteger)chunkSize localFilePath:(NSString *)localFilePath callback:(FileDownloadCallback*)callback {
    if (self = [super initWithPriority:priority])
    {
        _remoteFilePath = remotePath;
        _localFilePath = localFilePath;
        _fileOffset = fileOffset;
        _chunkSize = chunkSize;
        
        _bytesToReceive = chunkSize;
        _bytesReceived = 0;
        
        _localMD5 = nil;
        _remoteMD5 = nil;
        _errorCode = 0;
        
        _canceled = NO;
        
        _callbackInvoked = NO;
        _callback = callback;
    }
    return self;
}

- (void) cmdConnectionStateChanged:(CmdSocketState)newState oldState:(CmdSocketState)oldState object:(id)object {
    
}

- (void) cmdConnectionReceiveCameraResponse:(AMBAResponse *)response {
    if ([response isKindOfClass:AMBAFileTransferResultResponse.class])
    {
        AMBAFileTransferResultResponse* resultResponse = (AMBAFileTransferResultResponse*) response;
        _bytesToReceive = [resultResponse bytesSent];
        _remoteMD5 = [resultResponse md5];
        
        if ([resultResponse.type isEqualToString:@"get_file_complete"])
        {
            if (_localMD5)
            {
                if ([_localMD5 isEqualToString:_remoteMD5])
                {
                    [self invokeCallbackAndExit:0];
                }
                else
                {
                    [self invokeCallbackAndExit:FileDownloadErrorMD5CheckFailed];
                }
            }
            else
            {
                if ([self isFinished])
                {
                    @synchronized (self)
                    {
                        if (!_localMD5)
                        {
                            ///!!!For Debug 20161123: _localMD5 = md5sum([[MVCameraDownloadManager sharedInstance] sharedBuffer], (UInt32)_bytesToReceive);
                        }
                    }
                    
                    ///!!!For Debug 20161123: if ([_localMD5 isEqualToString:_remoteMD5])
                    {
                        [self invokeCallbackAndExit:0];
                    }/*///!!!For Debug 20161123:
                    else
                    {
                        [self invokeCallbackAndExit:ErrorMD5CheckFailed];
                    }*/
                }
            }
        }
        else if ([resultResponse.type isEqualToString:@"get_file_fail"])
        {
            if (_localMD5)
            {
                if ([_localMD5 isEqualToString:_remoteMD5])
                {
                    [self invokeCallbackAndExit:FileDownloadErrorTransferring];
                }
                else
                {
                    [self invokeCallbackAndExit:FileDownloadErrorMD5CheckFailed];
                }
            }
            else
            {
                _errorCode = FileDownloadErrorTransferring;
                if ([self isFinished])
                {
                    @synchronized (self)
                    {
                        if (!_localMD5)
                        {
                            ///!!!For Debug 20161123: _localMD5 = md5sum([[MVCameraDownloadManager sharedInstance] sharedBuffer], (UInt32)_bytesToReceive);
                        }
                    }
                    
                    ///!!!For Debug 20161123: if ([_localMD5 isEqualToString:_remoteMD5])
                    {
                        [self invokeCallbackAndExit:_errorCode];
                    }/*///!!!For Debug 20161123:
                    else
                    {
                        [self invokeCallbackAndExit:ErrorMD5CheckFailed];
                    }*/
                }
            }
        }
    }
    else if ([response isKindOfClass:AMBACancelFileTransferResponse.class])
    {
        AMBACancelFileTransferResponse* cancelResponse = (AMBACancelFileTransferResponse*) response;
        _bytesToReceive = [cancelResponse bytesSent];
        _remoteMD5 = [cancelResponse md5];
        
        if (_localMD5)
        {
            if ([_localMD5 isEqualToString:_remoteMD5])
            {
                [self invokeCallbackAndExit:FileDownloadErrorCanceled];
            }
            else
            {
                [self invokeCallbackAndExit:FileDownloadErrorMD5CheckFailed];
            }
        }
        else
        {
            _errorCode = FileDownloadErrorCanceled;
            if ([self isFinished])
            {
                @synchronized (self)
                {
                    if (!_localMD5)
                    {
                        ///!!!For Debug 20161123: _localMD5 = md5sum([[MVCameraDownloadManager sharedInstance] sharedBuffer], (UInt32)_bytesToReceive);
                    }
                }
                
                ///!!!For Debug 20161123: if ([_localMD5 isEqualToString:_remoteMD5])
                {
                    [self invokeCallbackAndExit:_errorCode];
                }/*///!!!For Debug 20161123:
                else
                {
                    [self invokeCallbackAndExit:ErrorMD5CheckFailed];
                }*/
            }
        }
    }
}

- (void) start {
    [[MVCameraDownloadManager sharedInstance] resizeSharedBufferIfNecessary:(_bytesToReceive <= 0 ? DownloadChunkSize : _bytesToReceive)];
    
    [[CMDConnectManager sharedInstance] addObserver:self];
    
    AMBAGetFileRequest* getFileRequest = [[AMBAGetFileRequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
        AMBAGetFileResponse* getFileResponse = (AMBAGetFileResponse*) response;
        if (getFileResponse)
        {
            if (!getFileResponse.isRvalOK)
            {
                switch (getFileResponse.rval)
                {
                    case AMBA_RVAL_ERROR_INVALID_FILE_PATH:
                        [self invokeCallbackAndExit:FileDownloadErrorNoSuchRemoteFile];
                        break;
                    case AMBA_RVAL_ERROR_BUSY:
                        [self invokeCallbackAndExit:FileDownloadErrorCameraBusy];
                        break;
                    default:
                        [self invokeCallbackAndExit:FileDownloadErrorOtherRequestFailure];
                        break;
                }
            }
            else if (self.callback && self.callback.gotSizeBlock && !_canceled)
            {
                self.callback.gotSizeBlock(getFileResponse.remSize, getFileResponse.size, self);
            }
        }
    } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
        [self invokeCallbackAndExit:FileDownloadErrorOtherRequestFailure];
    } responseClass:AMBAGetFileResponse.class];
    getFileRequest.msgID = AMBA_MSGID_GET_FILE;
    getFileRequest.token = [[MVCameraClient sharedInstance] sessionToken];
    getFileRequest.param = _remoteFilePath;
    getFileRequest.offset = [@(_fileOffset) stringValue];
    getFileRequest.fetchSize = _chunkSize;
    [[CMDConnectManager sharedInstance] sendRequest:getFileRequest];
}

- (BOOL) checkCallbackInvoked {
    @synchronized (self)
    {
        if (_callbackInvoked)
            return YES;
        
        _callbackInvoked = YES;
        return NO;
    }
}

- (void) invokeCallbackAndExit:(int)errorCode {
    if ([self checkCallbackInvoked])
        return;
    
    MVCameraDownloadManager* downloadMgr = [MVCameraDownloadManager sharedInstance];
    if (!saveFileChunk(self.localFilePath, (int)self.fileOffset, (const char*)[downloadMgr sharedBuffer], [downloadMgr sharedBufferSize], 0, (int)_bytesToReceive))
    {
        errorCode = FileDownloadErrorWriteFileFailure;
    }
    //NSLog(@"GetFile : Save file chunk, localMD5 = %@, remoteMD5 = %@, _errMsg = %@, _canceled = %d", _localMD5, _remoteMD5, _errMsg, _canceled);
    
    [[CMDConnectManager sharedInstance] removeObserver:self];
    
    if (0 != errorCode)
    {
        if (self.callback && self.callback.errorBlock)
        {
            self.callback.errorBlock(errorCode, self);
        }
    }
    else if (_canceled)
    {
        if (self.callback && self.callback.canceledBlock)
        {
            self.callback.canceledBlock(_bytesReceived, self);
        }
    }
    else
    {
        if (self.callback && self.callback.completedBlock)
        {
            self.callback.completedBlock(_bytesReceived, self);
        }
    }
    
    [[DATAConnectManager sharedInstance] removeDataReceiver:self];
    [[MVCameraDownloadManager sharedInstance] pollTaskOfCategory:MVDownloadTaskCategoryAMBATCP];
}

- (int) onReceiveData:(UInt8 *)data offset:(int)offset length:(int)length {
    if (length + _bytesReceived > DefaultBufferSize) length = (int)(DefaultBufferSize - _bytesReceived);
    memcpy([[MVCameraDownloadManager sharedInstance] sharedBuffer] + _bytesReceived, data + offset, length);
    _bytesReceived += length;
    
    if (self.callback && self.callback.progressBlock && !_canceled)
    {
        self.callback.progressBlock(self.chunkSize, _bytesReceived, self);
    }
    
    if ([self isFinished])
    {
        @synchronized (self)
        {
            if (!_localMD5)
            {
                ///!!!For Debug 20161123: _localMD5 = md5sum([[MVCameraDownloadManager sharedInstance] sharedBuffer], (UInt32)_bytesToReceive);
            }
        }
        
        if (_remoteMD5)
        {
            ///!!!For Debug 20161123: if ([_localMD5 isEqualToString:_remoteMD5])
            {
                [self invokeCallbackAndExit:_errorCode];
            }/*///!!!For Debug 20161123:
            else
            {
                [self invokeCallbackAndExit:ErrorMD5CheckFailed];
            }*/
        }
    }
    return length;
}

- (void) onError:(int)error errMsg:(NSString *)errMsg {
    if (error == DataSocketErrorTimeout)
    {
        [self invokeCallbackAndExit:FileDownloadErrorTimeout];
    }
    else if (error == DataSocketErrorException)
    {
        [self invokeCallbackAndExit:FileDownloadErrorReceiving];
    }
}

- (BOOL) isFinished {
    return (_bytesToReceive > 0 && _bytesToReceive <= _bytesReceived);
}

- (void) cancel {
    _canceled = YES;
}

- (BOOL) isEqual:(id)object {
    if (![object isKindOfClass:FileDownloadTask.class])
        return NO;
    
    FileDownloadTask* other = (FileDownloadTask*) object;
    if (!self.remoteFilePath)
    {
        return (!other.remoteFilePath || other.remoteFilePath.length == 0) && self.fileOffset == other.fileOffset && self.chunkSize == other.chunkSize && [self.localFilePath isEqualToString:other.localFilePath];
    }
    
    return [self.remoteFilePath isEqualToString:other.remoteFilePath] && self.fileOffset == other.fileOffset && self.chunkSize == other.chunkSize && [self.localFilePath isEqualToString:other.localFilePath];
}

@end

@interface ContinuousFileDownloadCallback ()
{
    BOOL _gotFileSize;
    BOOL _transferCompleted;
    
    MVDownloadTaskPriority _priority;
    int _initChunkSize;
    int _normalChunkSize;
    
    FileDownloadGotSizeBlock _thisGotSizeBlock;
    FileDownloadCompletedBlock _thisCompletedBlock;
    FileDownloadCanceledBlock _thisCanceledBlock;
    FileDownloadProgressUpdatedBlock _thisProgressBlock;
    FileDownloadErrorBlock _thisErrorBlock;
}

@property (nonatomic, strong) FileDownloadGotSizeBlock thisGotSizeBlock;
@property (nonatomic, strong) FileDownloadCompletedBlock thisCompletedBlock;
@property (nonatomic, strong) FileDownloadCanceledBlock thisCanceledBlock;
@property (nonatomic, strong) FileDownloadProgressUpdatedBlock thisProgressBlock;
@property (nonatomic, strong) FileDownloadErrorBlock thisErrorBlock;

@property (nonatomic, assign) BOOL gotFileSize;
@property (nonatomic, assign) BOOL transferCompleted;
@property (nonatomic, assign) int initChunkSize;
@property (nonatomic, assign) int normalChunkSize;
@property (nonatomic, assign) MVDownloadTaskPriority priority;

@end

@implementation ContinuousFileDownloadCallback

@dynamic gotSizeBlock;
@dynamic completedBlock;
@dynamic canceledBlock;
@dynamic progressBlock;
@dynamic errorBlock;

@synthesize thisGotSizeBlock = _thisGotSizeBlock;
@synthesize thisCompletedBlock = _thisCompletedBlock;
@synthesize thisCanceledBlock = _thisCanceledBlock;
@synthesize thisProgressBlock = _thisProgressBlock;
@synthesize thisErrorBlock = _thisErrorBlock;

@synthesize allCompletedBlock;

@synthesize gotFileSize = _gotFileSize;
@synthesize transferCompleted = _transferCompleted;
@synthesize initChunkSize = _initChunkSize;
@synthesize normalChunkSize = _normalChunkSize;
@synthesize priority = _priority;

@synthesize chunk;

- (void) setGotSizeBlock:(FileDownloadGotSizeBlock)gotSizeBlock {
    _thisGotSizeBlock = gotSizeBlock;
}

- (void) setCompletedBlock:(FileDownloadCompletedBlock)completedBlock {
    _thisCompletedBlock = completedBlock;
}

- (void) setCanceledBlock:(FileDownloadCanceledBlock)canceledBlock {
    _thisCanceledBlock = canceledBlock;
}

- (void) setProgressBlock:(FileDownloadProgressUpdatedBlock)progressBlock {
    _thisProgressBlock = progressBlock;
}

- (void) setErrorBlock:(FileDownloadErrorBlock)errorBlock {
    _thisErrorBlock = errorBlock;
}

- (instancetype) init {
    if (self = [super init])
    {
        _priority = MVDownloadTaskPriorityHigh;
        _initChunkSize = DownloadInitChunkSize;
        _normalChunkSize = DownloadChunkSize;
        
        _gotFileSize = NO;
        _transferCompleted = NO;
        
        __weak __typeof(self) wSelf = self;
        super.gotSizeBlock = ^(NSInteger remSize, NSInteger totalSize, MVDownloadTask* downloadTask) {
            __strong __typeof(self) pSelf = wSelf;
            @try
            {
                if (totalSize >= self.chunk.size)
                {
                    pSelf.chunk.size = totalSize;
                }
                
                @synchronized (pSelf)
                {
                    pSelf.gotFileSize = YES;
                    if (!pSelf.transferCompleted)
                        return;
                }
                
                if (pSelf.chunk.size > pSelf.chunk.downloadedSize)
                {
                    [[MVCameraDownloadManager sharedInstance] addContinuousFileDownloading:pSelf.chunk priority:pSelf.priority initChunkSize:pSelf.initChunkSize normalChunkSize:pSelf.normalChunkSize callback:pSelf];
                }
            }
            @finally
            {
                if (pSelf.thisGotSizeBlock)
                {
                    pSelf.thisGotSizeBlock(remSize, totalSize, downloadTask);
                }
            }
        };
        super.completedBlock = ^(NSInteger bytesReceived, MVDownloadTask* downloadTask) {
            __strong __typeof(self) pSelf = wSelf;
            @try
            {
                [pSelf onCompletedOrCanceled:bytesReceived canceled:NO downloadTask:downloadTask];
            }
            @finally
            {
                if (pSelf.thisCompletedBlock)
                {
                    pSelf.thisCompletedBlock(bytesReceived, downloadTask);
                }
            }
        };
        super.canceledBlock = ^(NSInteger bytesReceived, MVDownloadTask* downloadTask) {
            __strong __typeof(self) pSelf = wSelf;
            @try
            {
                [pSelf onCompletedOrCanceled:bytesReceived canceled:YES downloadTask:downloadTask];
            }
            @finally
            {
                if (pSelf.thisCanceledBlock)
                {
                    pSelf.thisCanceledBlock(bytesReceived, downloadTask);
                }
            }
        };
        super.errorBlock = ^(int errorCode, MVDownloadTask* downloadTask) {
            __strong __typeof(self) pSelf = wSelf;
            if (pSelf.thisErrorBlock)
            {
                pSelf.thisErrorBlock(errorCode, downloadTask);
            }
        };
        super.progressBlock = ^(NSInteger totalBytes, NSInteger downloadedBytes, MVDownloadTask* downloadTask) {
            __strong __typeof(self) pSelf = wSelf;
            if (pSelf.thisProgressBlock)
            {
                pSelf.thisProgressBlock(totalBytes, downloadedBytes, downloadTask);
            }
        };
    }
    return self;
}

- (instancetype) initWithPriority:(MVDownloadTaskPriority)priority initChunkSize:(NSInteger)initChunkSize normalChunkSize:(NSInteger)normalChunkSize {
    if (self = [self init])
    {
        _priority = priority;
        _initChunkSize = (int)initChunkSize;
        _normalChunkSize = (int)normalChunkSize;
        
        _gotFileSize = NO;
        _transferCompleted = NO;
    }
    return self;
}

- (void) onCompletedOrCanceled:(NSInteger)bytesReceived canceled:(BOOL)canceled downloadTask:(MVDownloadTask*)downloadTask {
    NSUInteger downloadedSize = bytesReceived + self.chunk.downloadedSize;
    if (downloadedSize > self.chunk.size && self.chunk.size > 0)
    {
        downloadedSize = self.chunk.size;
    }
    self.chunk.downloadedSize = downloadedSize;
    
    @synchronized (self)
    {
        _transferCompleted = YES;
        if (!_gotFileSize)
            return;
    }
    
    if (self.chunk.size <= self.chunk.downloadedSize)
    {
        if (self.allCompletedBlock)
        {
            self.allCompletedBlock(downloadTask);
        }
    }
    else if (!canceled)
    {
        [[MVCameraDownloadManager sharedInstance] addContinuousFileDownloading:self.chunk priority:_priority initChunkSize:_initChunkSize normalChunkSize:_normalChunkSize callback:self];
    }
}

@end

#pragma mark    HTTPDownloadCallback
@interface HTTPDownloadCallback ()
{
    FileDownloadAllCompletedBlock _allCompletedBlock;
}
@end

@implementation HTTPDownloadCallback

@synthesize allCompletedBlock = _allCompletedBlock;

- (instancetype) initWithGotSizeBlock:(FileDownloadGotSizeBlock)gotSizeBlock completedBlock:(FileDownloadCompletedBlock)completedBlock allCompletedBlock:(FileDownloadAllCompletedBlock)allCompletedBlock canceledBlock:(FileDownloadCanceledBlock)canceledBlock progressBlock:(FileDownloadProgressUpdatedBlock)progressBlock errorBlock:(FileDownloadErrorBlock)errorBlock {
    if (self = [super initWithGotSizeBlock:gotSizeBlock completedBlock:completedBlock canceledBlock:canceledBlock progressBlock:progressBlock errorBlock:errorBlock])
    {
        _allCompletedBlock = allCompletedBlock;
    }
    return self;
}

@end

#pragma mark HTTPDownloadTask

//#define EXIT_CHUNK_COMPLETED 0
#define EXIT_ENTIRE_COMPLETED 1
#define EXIT_CANCELED -1
#define EXIT_ERROR -2

@interface HTTPDownloadTask () <NSURLSessionDownloadDelegate>
{
    NSString* _remoteFilePath;
    NSString* _localFilePath;
    int _chunkSize;
    HTTPDownloadCallback* _callback;
    
    NSUInteger _bytesReceived;
    NSInteger _offset;
//*
    NSData* _resumeData;
    NSURLSession* _urlSession;
    NSURLSessionDownloadTask* _urlSessionDownloadTask;
/*/
    AFHTTPRequestOperation* _afOperation;
    //*/
    BOOL _gotFileSizeBlockInvoked;
    BOOL _finalCallbackInvoked;
}

@property (nonatomic, copy) NSString* remoteFilePath;
@property (nonatomic, copy) NSString* localFilePath;
//*
@property (nonatomic, copy) NSData* resumeData;
@property (nonatomic, strong) NSURLSessionDownloadTask* urlSessionDownloadTask;
//*/
@property (nonatomic, assign) NSUInteger bytesReceived;

@end


@implementation HTTPDownloadTask

@synthesize remoteFilePath = _remoteFilePath;
@synthesize localFilePath = _localFilePath;
@synthesize chunkSize = _chunkSize;
@synthesize callback = _callback;
//*
@synthesize resumeData = _resumeData;
@synthesize urlSessionDownloadTask = _urlSessionDownloadTask;
//*/
@synthesize bytesReceived = _bytesReceived;

- (instancetype) initWithPriority:(MVDownloadTaskPriority)priority remoteFilePath:(NSString*)remoteFilePath offset:(NSInteger)offset resumeData:(NSData*)resumeData localFilePath:(NSString*)localFilePath chunkSize:(int)chunkSize callback:(HTTPDownloadCallback*)callback {
    if (self = [super initWithPriority:priority])
    {
        _callback = callback;
        _remoteFilePath = remoteFilePath;
        _resumeData = resumeData;
        _localFilePath = localFilePath;
        _chunkSize = chunkSize;
        _offset = offset;
    }
    return self;
}

NSInteger cutFile(NSString* path, NSInteger cutSize) {
    NSInteger fileSize = fileSizeAtPath(path);
    NSLog(@"HTTPDownloadTask : cutFile : fileSize = %d, cutSize = %d", (int)fileSize, (int)cutSize);
    if (fileSize > cutSize)
    {
        const NSInteger bufferSize = 1048576 * 2;
        NSString* copyFilePath = [path stringByAppendingPathExtension:@"cut"];
        uint8_t* buffer = (uint8_t*) malloc(bufferSize);
        NSInteger writtenBytes = 0;
        while (writtenBytes < cutSize)
        {
            int readBytes = loadFileChunk(buffer, 0, path, (int)writtenBytes, bufferSize);
            if (readBytes > cutSize - writtenBytes)
            {
                readBytes = (int)(cutSize - writtenBytes);
            }
            saveFileChunk(copyFilePath, (int)writtenBytes, (const char*)buffer, bufferSize, 0, readBytes);
            writtenBytes += readBytes;
        }
        NSError* error = nil;
        NSFileManager* fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:path error:&error];
        NSLog(@"HTTPDownloadTask: cutFile error#0 : %@", error);
        [fm moveItemAtPath:copyFilePath toPath:path error:&error];
        NSLog(@"HTTPDownloadTask: cutFile error#1 : %@", error);
        free(buffer);
        return cutSize;
    }
    else if (fileSize < cutSize)
    {
        /*
        @throw [NSException exceptionWithName:@"MadvDebugException" reason:@"fileSize < cutSize should never happen" userInfo:nil];
        const NSInteger bufferSize = 1048576 * 2;
        uint8_t* buffer = (uint8_t*) malloc(bufferSize);
        while (fileSize < cutSize)
        {
            int bytesToWrite = (int) (cutSize - fileSize);
            bytesToWrite = (bytesToWrite > bufferSize) ? bufferSize : bytesToWrite;
            saveFileChunk(path, (int)fileSize, (const char*)buffer, (int)bufferSize, 0, bytesToWrite);
        }
        free(buffer);
        /*/
        return fileSize;
        //*/
    }
    return cutSize;
}

- (void) start {
    _bytesReceived = 0;
    _gotFileSizeBlockInvoked = NO;
    _finalCallbackInvoked = NO;
    //*
    NSURLSessionConfiguration* cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
    _urlSession = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue mainQueue]];
/*
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_remoteFilePath]];
    NSString* range = [NSString stringWithFormat:@"bytes=%zd-", _offset];
    [request setValue:range forHTTPHeaderField:@"Range"];
//*/
    if (_resumeData)
    {
        const int BUFFER_SIZE = 1048576;
        NSDictionary* resumeInfo = [NSPropertyListSerialization propertyListWithData:_resumeData options:NSPropertyListImmutable format:nil error:nil];
        NSString* tempFileName = resumeInfo[@"NSURLSessionResumeInfoTempFileName"];
        NSString* tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];
        NSFileManager* fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:tempFilePath])
        {
            //NSInteger tempFileSize = (NSInteger) [[fm attributesOfItemAtPath:tempFilePath error:nil] fileSize];
            cutFile(tempFilePath, _offset);
        }
        else
        {
            //TODO:
            @throw [NSException exceptionWithName:@"MadvException" reason:@"ResumeDownloadingWithNoTempFile" userInfo:nil];
        }
        _urlSessionDownloadTask = [_urlSession downloadTaskWithResumeData:_resumeData];
        _resumeData = nil;
    }
    else
    {
        _urlSessionDownloadTask = [_urlSession downloadTaskWithURL:[NSURL URLWithString:_remoteFilePath]];
    }
    [_urlSessionDownloadTask resume];
     //*/
}

- (void) invokeCallbackAndExit:(int)exitStatus error:(nullable NSError*)error {
    @synchronized (self)
    {
        if (_finalCallbackInvoked)
            return;
        
        _finalCallbackInvoked = YES;
    }
    
    switch (exitStatus)
    {
        case EXIT_ENTIRE_COMPLETED:
        {
            if (_callback && _callback.allCompletedBlock)
            {
                _callback.allCompletedBlock(self);
            }
        }
            break;
        case EXIT_CANCELED:
        {
            if (_callback && _callback.canceledBlock)
            {
                _callback.canceledBlock(self.bytesReceived, self);
            }
        }
            break;
        case EXIT_ERROR:
        {
            if (_callback && _callback.errorBlock)
            {
                _callback.errorBlock(FileDownloadErrorTransferring, self);
            }
        }
            break;
        default:
            break;
    }
    
    [[MVCameraDownloadManager sharedInstance] pollTaskOfCategory:MVDownloadTaskCategoryHTTP];
}

- (void) cancel {
    //*
    NSLog(@"HTTPDownloadTask::cancel");
    __weak __typeof(self) wSelf = self;
    [_urlSessionDownloadTask cancelByProducingResumeData:^(NSData* resumeData) {
        __strong __typeof(self) pSelf = wSelf;
        // 保存下载点，里面包括暂停信息，下载的URL信息等
        pSelf.urlSessionDownloadTask = nil;
        NSMutableDictionary* resumeInfo = [[NSPropertyListSerialization propertyListWithData:resumeData options:NSPropertyListImmutable format:nil error:nil] mutableCopy];
        NSLog(@"HTTPDownloadTask::canceled : _bytesReceived=%ld, resumeDataDict = %@", (long)_bytesReceived, resumeInfo);
        /// NSURLSessionResumeInfoTempFileName !!!
        for (NSString* key in resumeInfo.allKeys)
        {
            NSLog(@"HTTPDownloadTask::canceled : resumeDataDict[%@] = %@", key, [resumeInfo objectForKey:key]);
        }
        [resumeInfo removeObjectForKey:@"NSURLSessionResumeEntityTag"];
        pSelf.resumeData = [NSPropertyListSerialization dataWithPropertyList:resumeInfo format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListImmutable error:nil];
        //NSString* tmpFilePath = resumeInfo[@"NSURLSessionResumeInfoTempFileName"];
        //NSInteger bytesReceived = [resumeInfo[@"NSURLSessionResumeBytesReceived"] integerValue];
        [pSelf invokeCallbackAndExit:EXIT_CANCELED error:nil];
    }];
     //*/
}

- (void) invokeGotFileSizeBlockWithRemSize:(NSInteger)remSize totalSize:(NSInteger)totalSize {
    @synchronized (self)
    {
        if (_gotFileSizeBlockInvoked)
            return;
        
        if (self.callback && self.callback.gotSizeBlock)
        {
            self.callback.gotSizeBlock(remSize, totalSize, self);
        }
        
        _gotFileSizeBlockInvoked = YES;
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* filePath = _localFilePath;
    [fm moveItemAtPath:location.path toPath:filePath error:nil];
    NSLog(@"HTTPDownloadTask::didFinishDownloadingToURL : location=%@, localPath=%@", location, filePath);

    [self invokeCallbackAndExit:EXIT_ENTIRE_COMPLETED error:nil];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    _bytesReceived += (NSUInteger) bytesWritten;
    NSLog(@"HTTPDownloadTask::didWriteData : %ld/%ld = %0.2f%%, bytesWritten=%ld, _bytesReceived=%ld, _chunkSize=%d", (long)totalBytesWritten, (long)totalBytesExpectedToWrite, (float)totalBytesWritten/(float)totalBytesExpectedToWrite * 100.f, (long)bytesWritten, (long)_bytesReceived, (int)_chunkSize);
    if (_callback && _callback.progressBlock)
    {
        _callback.progressBlock((NSUInteger) totalBytesExpectedToWrite, (NSUInteger) _bytesReceived, self);
    }
    
    [self invokeGotFileSizeBlockWithRemSize:(NSInteger)(totalBytesExpectedToWrite - totalBytesWritten) totalSize:(NSInteger)totalBytesExpectedToWrite];
    //*
    if (_bytesReceived >= 1048576 * 2)
    {
        __weak __typeof(self) wSelf = self;
        [_urlSessionDownloadTask cancelByProducingResumeData:^(NSData* resumeData) {
            __strong __typeof(self) pSelf = wSelf;
            //保存下载点，里面包括暂停信息，下载的URL信息等
            pSelf.resumeData = resumeData;
            pSelf.urlSessionDownloadTask = nil;
            NSMutableDictionary* resumeInfo = [[NSPropertyListSerialization propertyListWithData:resumeData options:NSPropertyListImmutable format:nil error:nil] mutableCopy];
            NSLog(@"HTTPDownloadTask::block : _bytesReceived=%ld, resumeDataDict = %@", (long)_bytesReceived, resumeInfo);
            /// NSURLSessionResumeInfoTempFileName !!!
            for (NSString* key in resumeInfo.allKeys)
            {
                NSLog(@"HTTPDownloadTask::block : resumeDataDict[%@] = %@", key, [resumeInfo objectForKey:key]);
            }
            [resumeInfo removeObjectForKey:@"NSURLSessionResumeEntityTag"];
            pSelf.resumeData = [NSPropertyListSerialization dataWithPropertyList:resumeInfo format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListImmutable error:nil];
            //NSString* tmpFilePath = resumeInfo[@"NSURLSessionResumeInfoTempFileName"];
            //NSInteger bytesReceived = [resumeInfo[@"NSURLSessionResumeBytesReceived"] integerValue];
            if (pSelf.callback && pSelf.callback.completedBlock)
            {
                pSelf.callback.completedBlock(pSelf.bytesReceived, pSelf);
            }
            
            _offset += _bytesReceived;
            [pSelf start];
        }];
    }
    //*/
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"HTTPDownloadTask::didResumeAtOffset:%ld expectedTotalBytes:%ld", (long)fileOffset, (long)expectedTotalBytes);
    [self invokeGotFileSizeBlockWithRemSize:(NSInteger)(expectedTotalBytes - fileOffset) totalSize:(NSInteger)expectedTotalBytes];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    NSLog(@"HTTPDownloadTask::didCompleteWithError : %@", error);
    //[self invokeCallbackAndExit:(error ? EXIT_ERROR : EXIT_ENTIRE_COMPLETED) error:error];
}

@end

@interface AFHTTPDownloadTask ()
{
    NSString* _remoteFilePath;
    NSString* _localFilePath;
    HTTPDownloadCallback* _callback;
    
    NSUInteger _bytesReceived;
    NSInteger _offset;
    NSInteger _length;
    NSInteger _totalBytes;
    
    BOOL _gotFileSizeBlockInvoked;
    BOOL _finalCallbackInvoked;
}

@property (nonatomic, copy) NSString* remoteFilePath;
@property (nonatomic, copy) NSString* localFilePath;
@property (nonatomic, assign) NSUInteger bytesReceived;
@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, assign) NSInteger length;
@property (nonatomic, assign) NSInteger totalBytes;

@property (nonatomic,strong) AFHTTPRequestOperation* downloadOperation;

@end

@implementation AFHTTPDownloadTask

@synthesize remoteFilePath = _remoteFilePath;
@synthesize localFilePath = _localFilePath;
@synthesize bytesReceived = _bytesReceived;
@synthesize offset = _offset;
@synthesize length = _length;
@synthesize totalBytes = _totalBytes;

@synthesize downloadOperation;

- (void) invokeGotFileSizeBlockWithRemSize:(NSInteger)remSize totalSize:(NSInteger)totalSize {
    @synchronized (self)
    {
        if (_gotFileSizeBlockInvoked)
            return;
        NSLog(@"AFHTTPDownloadTask $ invokeGotFileSizeBlockWithRemSize : remSize=%ld, totalSize=%ld @ %@", (long)remSize, (long)totalSize, self);
        if (0 == totalSize)
        {
            _totalBytes = _bytesReceived + _offset;
        }
        else
        {
            _totalBytes = totalSize;
        }
        if (self.callback && self.callback.gotSizeBlock)
        {
            self.callback.gotSizeBlock(remSize, totalSize, self);
        }
        
        _gotFileSizeBlockInvoked = YES;
    }
}

- (void) invokeCallbackAndExit:(int)exitStatus error:(nullable NSError*)error {
    @synchronized (self)
    {
        if (_finalCallbackInvoked)
            return;
        
        _finalCallbackInvoked = YES;
    }
    NSLog(@"AFHTTPDownloadTask $ invokeCallbackAndExit : exitStatus=%d, error=%@ @ %@", exitStatus, error, self);
    switch (exitStatus)
    {
        case EXIT_ENTIRE_COMPLETED:
        {
            NSFileManager* fm = [NSFileManager defaultManager];
            NSError* error = nil;
            [fm moveItemAtPath:[MVCameraDownloadManager downloadingTempFilePath:_localFilePath] toPath:_localFilePath error:&error];
            
            if (_callback && _callback.allCompletedBlock)
            {
                _callback.allCompletedBlock(self);
            }
        }
            break;
        case EXIT_CANCELED:
        {
            if (_callback && _callback.canceledBlock)
            {
                _callback.canceledBlock(self.bytesReceived, self);
            }
        }
            break;
        case EXIT_ERROR:
        {
            if (_callback && _callback.errorBlock)
            {
                _callback.errorBlock(FileDownloadErrorTransferring, self);
            }
        }
            break;
        default:
            break;
    }
    
    [[MVCameraDownloadManager sharedInstance] pollTaskOfCategory:MVDownloadTaskCategoryHTTP];
}

- (void) invokeChunkCompleteBlock {
    NSLog(@"AFHTTPDownloadTask $ invokeChunkCompleteBlock @ %@", self);
    @synchronized (self)
    {
        if (self.callback && self.callback.completedBlock)
        {
            self.callback.completedBlock(self.bytesReceived, self);
        }
    }
}

- (instancetype) initWithPriority:(MVDownloadTaskPriority)priority remoteFilePath:(NSString *)remoteFilePath offset:(NSInteger)offset length:(NSInteger)length localFilePath:(NSString *)localFilePath callback:(HTTPDownloadCallback *)callback {
    if (self = [super initWithPriority:priority])
    {
        _remoteFilePath = remoteFilePath;
        _localFilePath = localFilePath;
        _callback = callback;
        _offset = offset;
        _length = length;
    }
    return self;
}
//*
- (void) start {
    NSLog(@"AFHTTPDownloadTask : start : _offset=%d, _length=%d @ %@", (int)_offset, (int)_length, self);
    _bytesReceived = 0;
    _gotFileSizeBlockInvoked = NO;
    _finalCallbackInvoked = NO;
    
    //_offset = cutFile(_localFilePath, _offset);
    NSString* downloadingTempFilePath = [MVCameraDownloadManager downloadingTempFilePath:_localFilePath];
    _offset = fileSizeAtPath(downloadingTempFilePath);
    NSLog(@"AFHTTPDownloadTask : start #1 : _offset=%d, _length=%d @ %@", (int)_offset, (int)_length, self);
    
    NSURLRequest* downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:_remoteFilePath]];
    NSMutableURLRequest* mutableURLRequest = [downloadRequest mutableCopy];
    //NSString* requestRange = _length > 0 ? [NSString stringWithFormat:@"bytes=%ld-%ld", _offset, _offset + _length - 1] : [NSString stringWithFormat:@"bytes=%ld-", _offset];
    NSString* requestRange = [NSString stringWithFormat:@"bytes=%ld-", (long)_offset];
    [mutableURLRequest setValue:requestRange forHTTPHeaderField:@"Range"];
    [mutableURLRequest setValue:nil forHTTPHeaderField:@"If-Range"];
    [mutableURLRequest setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    NSLog(@"#AFHTTPDownloadTask# allHTTPHeaderFields : %@", [mutableURLRequest allHTTPHeaderFields]);
    downloadRequest = mutableURLRequest;
    //不使用缓存，避免断点续传出现问题
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:downloadRequest];
    
    AFHTTPRequestOperation* downloadOp = [[AFHTTPRequestOperation alloc] initWithRequest:downloadRequest];
    self.downloadOperation = downloadOp;
    downloadOp.outputStream = [NSOutputStream outputStreamToFileAtPath:downloadingTempFilePath append:YES];
    __weak typeof(self) wSelf = self;
    [downloadOp setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        __strong typeof(self) pSelf = wSelf;
        if (!pSelf)
        {
            NSLog(@"AFHTTPDownloadTask : Invalid self, downloadURL = %@", [downloadRequest.URL.absoluteString lastPathComponent]);
            return;
        }
        pSelf.bytesReceived += (NSUInteger) bytesRead;
        //NSLog(@"AFHTTPDownloadTask : pSelf.bytesReceived=%d, pSelf.length=%d, bytesRead=%d, totalBytesRead=%d, totalBytesExpectedToRead=%d. remSize=%d, _offset=%d @ %@", (int)pSelf.bytesReceived, (int)pSelf.length, (int)bytesRead, (int)totalBytesRead, (int)(int)totalBytesExpectedToRead, (int)(totalBytesExpectedToRead - totalBytesRead), (int)pSelf.offset, pSelf);
        if (pSelf.callback && pSelf.callback.progressBlock)
        {
            pSelf.callback.progressBlock((NSUInteger) totalBytesExpectedToRead, (NSUInteger) pSelf.bytesReceived, pSelf);
        }
        //[pSelf invokeGotFileSizeBlockWithRemSize:((NSInteger)(totalBytesExpectedToRead - totalBytesRead)) totalSize:(NSInteger)totalBytesExpectedToRead];
        [pSelf invokeGotFileSizeBlockWithRemSize:(NSInteger)(totalBytesExpectedToRead) totalSize:(NSInteger)(totalBytesExpectedToRead + pSelf.offset)];
        
        if (pSelf.bytesReceived >= pSelf.length)
        {
            //NSLog(@"#RLMDeadLock# invokeChunkCompleteBlock : pSelf.bytesReceived=%ld, pSelf.length=%ld", (long)pSelf.bytesReceived, (long)pSelf.length);
            [pSelf invokeChunkCompleteBlock];
            pSelf.bytesReceived = 0;
        }
    }];
    [downloadOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong typeof(self) pSelf = wSelf;
        if (!pSelf)
        {
            NSLog(@"AFHTTPDownloadTask : Invalid self");
            return;
        }
        [pSelf invokeGotFileSizeBlockWithRemSize:0 totalSize:pSelf.bytesReceived + pSelf.offset];
        pSelf.offset += pSelf.bytesReceived;
        if (pSelf.length + pSelf.offset > pSelf.totalBytes && pSelf.totalBytes > 0)
        {
            pSelf.length = pSelf.totalBytes - pSelf.offset;
        }
        NSLog(@"AFHTTPDownloadTask : complete pSelf.offset=%ld, pSelf.bytesReceived=%ld, pSelf.length=%ld, pSelf.bytesReceived=%ld @ %@", (long)pSelf.offset, (long)pSelf.bytesReceived, (long)pSelf.length, (long)pSelf.bytesReceived, pSelf);
        if (pSelf.bytesReceived >= pSelf.length)
        {
            [pSelf invokeChunkCompleteBlock];
        }
        
        [pSelf invokeCallbackAndExit:EXIT_ENTIRE_COMPLETED error:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        __strong typeof(self) pSelf = wSelf;
        if (!pSelf)
        {
            NSLog(@"AFHTTPDownloadTask : Invalid self");
            return;
        }
        NSLog(@"AFHTTPDownloadTask : @ %@, Error %@", pSelf, error);
        [pSelf invokeCallbackAndExit:EXIT_ERROR error:error];
    }];
    [downloadOp start];
}

- (void) cancel {
    NSLog(@"AFHTTPDownloadTask : cancel @ %@", self);
    [self.downloadOperation pause];
    [self invokeCallbackAndExit:EXIT_CANCELED error:nil];
}

- (BOOL) isEqual:(id)object {
    if (![object isKindOfClass:AFHTTPDownloadTask.class])
        return NO;
    
    AFHTTPDownloadTask* other = (AFHTTPDownloadTask*) object;
    if (!self.remoteFilePath)
    {
        return (!other.remoteFilePath || other.remoteFilePath.length == 0) && [self.localFilePath isEqualToString:other.localFilePath];
    }
    
    return [self.remoteFilePath isEqualToString:other.remoteFilePath] && [self.localFilePath isEqualToString:other.localFilePath];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"AFHTTPDownloadTask(%lx):%@, priority=%d", (long)self.hash, [self.remoteFilePath lastPathComponent], (int)self.priority];
}
//*/
@end


#undef EXIT_COMPLETED
#undef EXIT_CANCELED
#undef EXIT_ERROR

#pragma mark    DownloadChunk

@interface DownloadChunk ()
{
    NSString* _cameraUUID;
    NSString* _remoteFilePath;
    NSString* _localFilePath;
    NSInteger _size;
    NSInteger _downloadedSize;
}
@end

@implementation DownloadChunk

@synthesize size = _size;
@synthesize downloadedSize = _downloadedSize;
@synthesize cameraUUID = _cameraUUID;
@synthesize remoteFilePath = _remoteFilePath;
@synthesize localFilePath = _localFilePath;

- (instancetype) initWithCameraUUID:(NSString *)cameraUUID remoteFilePath:(NSString *)remoteFilePath localFilePath:(NSString *)localFilePath size:(NSInteger)size downloadedSize:(NSInteger)downloadedSize {
    if (self = [super init])
    {
        _cameraUUID = cameraUUID;
        _remoteFilePath = remoteFilePath;
        _localFilePath = localFilePath;
        _size = size;
        _downloadedSize = downloadedSize;
    }
    return self;
}

@end
