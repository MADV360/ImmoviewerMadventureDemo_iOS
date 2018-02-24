//
//  CycordVideoRecorder.h
//  HelloOGLES2
//
//  Created by FutureBoy on 12/18/14.
//  Copyright (c) 2014 RedShore. All rights reserved.
//
#ifdef TARGET_OS_IOS

#ifndef __HelloOGLES2__CycordVideoRecorder__
#define __HelloOGLES2__CycordVideoRecorder__

#import "CycordVideoRecorderDelegate.h"
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif

    long getCurrentTimeMills();
    
#ifdef __cplusplus
}
#endif

@class CAEAGLLayer;
@protocol AVAudioRecorderDelegate;

@interface CycordVideoRecorder : NSObject <AVAudioRecorderDelegate>

@property (nonatomic, strong) id<CycordVideoRecorderDelegate> delegate;

@property (nonatomic, strong, readonly) NSMutableDictionary* snapshotDatas;

@property (nonatomic, assign) CVOpenGLESTextureRef renderTexture;

//+ (CycordVideoRecorder*) initVideoRecorder;
//+ (void) releaseVideoRecorder;

+ (CycordVideoRecorder*) sharedInstance;

- (instancetype) initWithOutputVideoBaseName:(NSString*)outputVideoBaseName;

//+ (void) startRecording;
//+ (void) startRecording : (float)fps;
- (void) startRecording;
- (void) startRecording : (float)fps;

- (void) setViewSize:(CGSize)size;
- (void) setShareMode;
- (void) setFPS:(float)fps;

- (void) setupVideoRecorder;

- (void) recordOneFrame:(CGFloat)videoTimeMillSeconds;

//+ (void) stopRecording;
//+ (void) stopRecordingWithCompletionHandler:(void(^)(void))handler;
- (void) stopRecording;
- (void) stopRecordingWithCompletionHandler:(void(^)(NSError*, NSString*))handler;

+ (void) startReplaying:(UIViewController*)parentVC;

@property (nonatomic, strong) NSError* encodingError;

- (NSString*) outputAudioTmpFileBaseName;

- (NSString*) outputVideoTmpFileBaseName;

- (NSString*) outputVideoFileBaseName;

- (NSString*) outputMovieFileBaseName;

+ (NSString*) outputAudioTmpFileBaseName:(NSString*)originalName;

+ (NSString*) outputVideoTmpFileBaseName:(NSString*)originalName;

+ (NSString*) outputVideoFileBaseName:(NSString*)originalName;

+ (NSString*) outputMovieFileBaseName:(NSString*)originalName;

@end

#endif /* defined(__HelloOGLES2__CycordVideoRecorder__) */

#endif //#ifdef TARGET_OS_IOS
