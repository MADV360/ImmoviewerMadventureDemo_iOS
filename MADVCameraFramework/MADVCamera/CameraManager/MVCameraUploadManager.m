//
//  MVCameraUploadManager.m
//  Madv360_v1
//
//  Created by QiuDong on 16/11/17.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVCameraUploadManager.h"
#import "DATAConnectManager.h"
#import "AMBAPutFileRequest.h"
#import "AMBAPutFileResponse.h"
#import "AMBAFileTransferResultResponse.h"
#import "AMBACommands.h"
#import "MVCameraClient.h"
#import "SocketHelper.h"
#import <sys/socket.h>

static const int BUFFER_SIZE = 1024 * 1024;
static const int PROGRESS_MIN_STEP = 3;

@implementation MVUploadCallback

@synthesize onProgress;
@synthesize onCancel;
@synthesize onFailed;
@synthesize onComplete;

- (instancetype) initWithCompletion:(dispatch_block_t)completion cancelation:(dispatch_block_t)cancelation failure:(void(^)(MVUploadError))failure progress:(MVUploadProgressBlock)progress {
    if (self = [super init])
    {
        self.onComplete = completion;
        self.onCancel = cancelation;
        self.onFailed = failure;
        self.onProgress = progress;
    }
    return self;
}

@end


@interface MVUploadTask () <CMDConnectionObserver, MVCameraClientObserver>

@property (nonatomic, strong) MVUploadCallback* callback;
@property (nonatomic, assign) BOOL finalCallbackInvoked;
@property (nonatomic, assign) int currentProgress;
@property (nonatomic, assign) BOOL cancelUpdate;

@end

@implementation MVUploadTask

@synthesize callback;
@synthesize finalCallbackInvoked;
@synthesize currentProgress;
@synthesize cancelUpdate;

- (instancetype) initWithLocalPath:(NSString *)localPath remotePath:(NSString *)remotePath callback:(MVUploadCallback *)callback {
    if (self = [super init])
    {
        self.localPath = localPath;
        self.remotePath = remotePath;
        self.callback = callback;
        self.finalCallbackInvoked = NO;
    }
    return self;
}

- (void) cancel {
    self.cancelUpdate = YES;
}

- (void) completeCallback {
    @synchronized (self)
    {
        if (self.finalCallbackInvoked)
        {
            return;
        }
        self.finalCallbackInvoked = YES;
    }
    
    [[MVCameraClient sharedInstance] removeObserver:self];
    [[CMDConnectManager sharedInstance] removeObserver:self];
    if (self.callback && self.callback.onComplete)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.callback.onComplete();
        });
    }
}

- (void) cancelationCallback {
    @synchronized (self)
    {
        if (self.finalCallbackInvoked)
        {
            return;
        }
        self.finalCallbackInvoked = YES;
    }
    
    [[MVCameraClient sharedInstance] removeObserver:self];
    [[CMDConnectManager sharedInstance] removeObserver:self];
    if (self.callback && self.callback.onCancel)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.callback.onCancel();
        });
    }
}

- (void) failureCallback:(MVUploadError)error {
    @synchronized (self)
    {
        if (self.finalCallbackInvoked)
        {
            return;
        }
        self.finalCallbackInvoked = YES;
    }
    
    [[MVCameraClient sharedInstance] removeObserver:self];
    [[CMDConnectManager sharedInstance] removeObserver:self];
    if (self.callback && self.callback.onFailed)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.callback.onFailed(error);
        });
    }
}

- (void) progressCallback {
    if (self.callback && self.callback.onProgress)
    {
        __weak __typeof(self) wSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            wSelf.callback.onProgress(wSelf.currentProgress);
        });
    }
}

-(void) didStorageMountedStateChanged:(StorageMountState)mounted {
    if (mounted != StorageMountStateOK)
    {
        [self failureCallback:MVUploadErrorNoSDCard];
    }
}

@end


@interface MVCameraUploadManager ()
{
    dispatch_queue_t _workerQueue;
}

@property (nonatomic, strong) dispatch_queue_t workerQueue;

@end


@interface UploadFirmwareTask ()
{
    
}

@property (nonatomic, strong) AMBAPutFileRequest* putFileRequest;

@end

@implementation UploadFirmwareTask

- (instancetype) initWithLocalPath:(NSString *)localPath remotePath:(NSString *)remotePath callback:(MVUploadCallback *)callback {
    if (self = [super initWithLocalPath:localPath remotePath:remotePath callback:callback])
    {
        self.cancelUpdate = NO;
        self.currentProgress = 0;
        
        self.putFileRequest = [[AMBAPutFileRequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
            AMBAPutFileResponse* putFileResponse = (AMBAPutFileResponse*) response;
            if (putFileResponse && putFileResponse.isRvalOK)
            {
                [self putFileToRemote];
            }
            else
            {
                [self failureCallback:MVUploadErrorResponseNG];
            }
        } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
            [self failureCallback:MVUploadErrorResponseNG];
        }];
        
        self.putFileRequest.msgID = AMBA_MSGID_PUT_FILE;
//        self.putFileRequest.token = [MVCameraClient sharedInstance].sessionToken;
        self.putFileRequest.param = self.remotePath;
        self.putFileRequest.offset = 0;
    }
    return self;
}

- (void) execute {
    if (!self.localPath || 0 == self.localPath || !self.remotePath || 0 == self.remotePath)
    {
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.localPath])
    {
        return;
    }

    [[CMDConnectManager sharedInstance] addObserver:self];
    [[MVCameraClient sharedInstance] addObserver:self];
    
    NSData* fileData = [NSData dataWithContentsOfFile:self.localPath];
    self.putFileRequest.size = fileData.length;
    self.putFileRequest.md5sum = md5sum((unsigned char*) fileData.bytes, (int) fileData.length);
    self.putFileRequest.fType = AMBA_UPLOAD_FILE_TYPE_FW;
    self.putFileRequest.token = [MVCameraClient sharedInstance].sessionToken;
    
    [[CMDConnectManager sharedInstance] sendRequest:self.putFileRequest];
}

- (void) putFileToRemote {
    dispatch_async([[MVCameraUploadManager sharedInstance] workerQueue], ^{
        int socket = [[DATAConnectManager sharedInstance] socket];
        [NSThread sleepForTimeInterval:0.8f];
        [self putFile:self.localPath toSocket:socket];
    });
}

- (void) putFile:(NSString*)localPath toSocket:(int)socket {
    NSInteger totalSentBytes = 0;
    NSInteger prev = 0;
    
    @try
    {
        NSData* fileData = [NSData dataWithContentsOfFile:localPath];
        NSInteger size = fileData.length;
        
        unsigned char* data = (unsigned char*) fileData.bytes;
        
        long sentBytes = 0;
        while (!self.cancelUpdate)
        {
            sentBytes = send(socket, data + totalSentBytes, MIN(size - totalSentBytes, BUFFER_SIZE), 0);
            if (sentBytes > 0)
            {
                totalSentBytes += sentBytes;
            }
            else
            {
                break;
            }
            
            self.currentProgress = (int) ((totalSentBytes * 100) / size);
            if ((self.currentProgress == 100) || (self.currentProgress - prev >= PROGRESS_MIN_STEP))
            {
                [self progressCallback];
                prev = self.currentProgress;
            }
        }
        
        if (self.cancelUpdate)
        {
            AMBARequest* cancelRequest = [[AMBARequest alloc] init];
            cancelRequest.msgID = AMBA_MSGID_CANCEL_FILE_TRANSFER;
            cancelRequest.token = [MVCameraClient sharedInstance].sessionToken;
            cancelRequest.param = self.putFileRequest.param;
            [[CMDConnectManager sharedInstance] sendRequest:cancelRequest];
            [self cancelationCallback];
        }
        else if (0 > sentBytes)
        {
            [self failureCallback:MVUploadErrorTransferFailure];
        }
    }
    @catch (id exception)
    {
        NSLog(@"Exception : %@", exception);
        [self failureCallback:MVUploadErrorTransferFailure];
    }
}

- (void) cmdConnectionReceiveCameraResponse:(AMBAResponse *)response {
    if ([response isKindOfClass:AMBAFileTransferResultResponse.class])
    {
        AMBAFileTransferResultResponse* resultResponse = (AMBAFileTransferResultResponse*) response;
        if ([response.type isEqualToString:PUT_FILE_COMPLETE_TYPE])
        {
            long bytesReceived = resultResponse.bytesReceived;
            NSString* md5sum = resultResponse.md5;
            if (self.putFileRequest.size == bytesReceived && [self.putFileRequest.md5sum isEqualToString:md5sum])
            {
                /*
#ifndef DEBUG_UPLOADING
                //update hardware
                AMBARequest* upgradeRequest = [[AMBARequest alloc] initWithReceiveBlock:^(AMBAResponse *response) {
                    if (response.isRvalOK)
                    {
                        [self completeCallback];
                    }
                    else
                    {
                        [self failureCallback:MVUploadErrorResponseNG];
                    }
                } errorBlock:^(AMBARequest *response, int error, NSString *msg) {
                    [self failureCallback:MVUploadErrorResponseNG];
                }];
                upgradeRequest.msgID = AMBA_MSGID_UPDATE_FIRMWARE;
                upgradeRequest.token = [MVCameraClient sharedInstance].sessionToken;
                [[CMDConnectManager sharedInstance] sendRequest:upgradeRequest];
#endif
                 /*/
                [self completeCallback];
                //*/
            }
            else
            {
                [self failureCallback:MVUploadErrorResponseNG];
            }
        }
        else if ([response.type isEqualToString:PUT_FILE_FAIL_TYPE])
        {
            [self failureCallback:MVUploadErrorResponseNG];
        }
    }
}

- (void)cmdConnectionStateChanged:(CmdSocketState)newState oldState:(CmdSocketState)oldState object:(id)object {
    
}

- (void)cmdConnectionHeartbeatRequired {
    
}

@end

@implementation UploadRCFirmwareTask

- (void) execute {
    if (!self.localPath || 0 == self.localPath || !self.remotePath || 0 == self.remotePath)
    {
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.localPath])
    {
        return;
    }
    
    [[CMDConnectManager sharedInstance] addObserver:self];
    [[MVCameraClient sharedInstance] addObserver:self];
    
    NSData* fileData = [NSData dataWithContentsOfFile:self.localPath];
    self.putFileRequest.size = fileData.length;
    self.putFileRequest.md5sum = md5sum((unsigned char*) fileData.bytes, (int) fileData.length);
    self.putFileRequest.fType = AMBA_UPLOAD_FILE_TYPE_RC_FW;
    self.putFileRequest.token = [MVCameraClient sharedInstance].sessionToken;
    
    [[CMDConnectManager sharedInstance] sendRequest:self.putFileRequest];
}

- (void) cmdConnectionReceiveCameraResponse:(AMBAResponse *)response {
    if ([response isKindOfClass:AMBAFileTransferResultResponse.class])
    {
        AMBAFileTransferResultResponse* resultResponse = (AMBAFileTransferResultResponse*) response;
        if ([response.type isEqualToString:PUT_FILE_COMPLETE_TYPE])
        {
            long bytesReceived = resultResponse.bytesReceived;
            NSString* md5sum = resultResponse.md5;
            if (self.putFileRequest.size == bytesReceived && [self.putFileRequest.md5sum isEqualToString:md5sum])
            {
                [self completeCallback];
            }
            else
            {
                [self failureCallback:MVUploadErrorResponseNG];
            }
        }
        else if ([response.type isEqualToString:PUT_FILE_FAIL_TYPE])
        {
            [self failureCallback:MVUploadErrorResponseNG];
        }
    }
}

@end


@implementation MVCameraUploadManager

@synthesize workerQueue = _workerQueue;

+ (instancetype) sharedInstance {
    static MVCameraUploadManager* singleton = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        singleton = [[super allocWithZone:nil] init];
    });
    return singleton;
}

- (instancetype) init {
    if (self = [super init])
    {
        _workerQueue = dispatch_queue_create("Uploading", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void) uploadFirmware:(UploadFirmwareTask*)uploadFirmwareTask {
    dispatch_async(_workerQueue, ^{
        [uploadFirmwareTask execute];
    });
}

- (void) uploadRCFirmware:(UploadRCFirmwareTask*)uploadRCFirmwareTask {
    dispatch_async(_workerQueue, ^{
        [uploadRCFirmwareTask execute];
    });
}

@end
