//
//  MVCameraUploadManager.h
//  Madv360_v1
//
//  Created by QiuDong on 16/11/17.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMDConnectManager.h"

typedef enum :NSInteger {
    MVUploadErrorNoSDCard = -1,
    MVUploadErrorTransferFailure = -2,
    MVUploadErrorResponseNG = -3,
} MVUploadError;

typedef void(^MVUploadProgressBlock)(int progress);

@interface MVUploadCallback : NSObject

@property (nonatomic, strong) dispatch_block_t onComplete;
@property (nonatomic, strong) dispatch_block_t onCancel;
@property (nonatomic, strong) void(^onFailed)(MVUploadError) ;
@property (nonatomic, strong) MVUploadProgressBlock onProgress;

- (instancetype) initWithCompletion:(dispatch_block_t)completion cancelation:(dispatch_block_t)cancelation failure:(void(^)(MVUploadError))failure progress:(MVUploadProgressBlock)progress;

@end


@interface MVUploadTask : NSObject

@property (nonatomic, copy) NSString* localPath;
@property (nonatomic, copy) NSString* remotePath;

- (instancetype) initWithLocalPath:(NSString*)localPath remotePath:(NSString*)remotePath callback:(MVUploadCallback*)callback;

- (void) cancel;

@end


@interface UploadFirmwareTask : MVUploadTask

@end

@interface UploadRCFirmwareTask : UploadFirmwareTask

@end

@interface MVCameraUploadManager : NSObject

+ (instancetype) sharedInstance;

- (void) uploadFirmware:(UploadFirmwareTask*)uploadFirmwareTask;

- (void) uploadRCFirmware:(UploadRCFirmwareTask*)uploadRCFirmwareTask;

@end
