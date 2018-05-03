//
//  ViewController.h
//  kxmovieapp
//
//  Created by Kolyvan on 11.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#ifndef MADVCAMERA_EXPORT
#import "BaseViewController.h"
#endif

#import <Foundation/Foundation.h>
#import <AudioToolBox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>


#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>

#ifdef FOR_DOUYIN
#import "KxMovieDecoder_douyin.h"
#else //#ifdef FOR_DOUYIN
#import "KxMovieDecoder.h"
#endif //#ifdef FOR_DOUYIN

#import "KxAudioManager.h"
//#import "KxMovieGLView.h"
#import "KxLogger.h"

typedef enum : NSInteger {
    QualityLevel4K = 0,//4k,
    QualityLevel1080 = 1,
    QualityLevelOther = 2,
} QualityLevel;

@class KxMovieDecoder;
@class MVGLView;

extern NSString * const KxMovieParameterMinBufferedDuration;    // Float
extern NSString * const KxMovieParameterMaxBufferedDuration;    // Float
extern NSString * const KxMovieParameterDisableDeinterlacing;   // BOOL

#ifdef __cplusplus
extern "C" {
#endif

NSString * formatTimeInterval(CGFloat seconds, BOOL isLeft);

#ifdef __cplusplus
}
#endif

#ifdef ENCODING_WITHOUT_MYGLVIEW
@class GLRenderLoop;
#endif

#ifndef MADVCAMERA_EXPORT
@interface MVKxMovieViewController : BaseViewController
#else
@interface MVKxMovieViewController : UIViewController
#endif
- (id) initWithContentPath: (NSString *) path
                parameters: (NSDictionary *) parameters;

- (void) setContentPath:(NSString*)path
             parameters:(NSDictionary*)parameters;

@property (nonatomic, strong) MVGLView* glView;

@property (nonatomic,assign) BOOL isPresenting;

@property (readonly) BOOL playing;
@property(nonatomic,assign)BOOL isStopPlay;

@property (nonatomic, assign) BOOL isUsedAsEncoder;
@property (nonatomic, assign) BOOL isUsedAsCapturer;
@property (nonatomic, assign) BOOL isFullScreenCapturer;
@property (nonatomic, assign) BOOL isUsedAsVideoEditor;
@property (nonatomic, assign) QualityLevel encoderQualityLevel;
#ifdef ENCODING_WITHOUT_MYGLVIEW
@property (nonatomic, strong) GLRenderLoop* encoderRenderLoop;
#endif
@property (nonatomic, assign) int panoramaMode;
@property (nonatomic, assign) BOOL isGlassMode;
@property(nonatomic,assign)BOOL isExport;//是否是导出转码
@property(nonatomic,assign)BOOL isShareEncoder;//也就是用它来判断是否要转成低码率

- (void) setFOVRange:(int)initFOV maxFOV:(int)maxFOV minFOV:(int)minFOV;

@property (nonatomic, assign, readonly) BOOL isCameraGyroDataAvailable;
@property (nonatomic, assign) BOOL isCameraGyroAdustEnabled;

@property (nonatomic, assign) BOOL isLoadingViewVisible;

@property(nonatomic,strong) void(^encodingProgressChangedBlock)(int percent);
@property(nonatomic,strong) void(^encodingFrameBlock)(float seconds);
@property(nonatomic,strong) void(^encodingDoneBlock)(NSString*, NSError*);

@property (nonatomic, strong) KxMovieDecoder* decoder;
@property (nonatomic, assign) CGFloat previousMoviePosition;
@property(nonatomic,assign)BOOL isFinishEncoder;
@property(nonatomic,assign)CGFloat editStartTime;
@property(nonatomic,assign)CGFloat editEndTime;
@property(nonatomic,assign)BOOL isNewEditTime;
@property (nonatomic, assign) int filterID;
@property(nonatomic,assign)CGFloat firstVideoTimestamp;
@property(nonatomic,assign)CGFloat outputVideoFrameCount;
@property(nonatomic,assign)BOOL isShare;

#ifdef ENCODING_WITHOUT_MYGLVIEW
- (void) cancelEncoding;
- (void) restartEncoding:(QualityLevel)encoderQuaLevel;
#endif

+ (NSString*) encodedFileBaseName:(NSString*)contentPath qualityLevel:(QualityLevel)qualityLevel forExport:(BOOL)forExport;

@property (nonatomic, strong) dispatch_queue_t    dispatchQueue;
@property (nonatomic, strong) dispatch_queue_t    dispatchQueueAudioRecord;
@property (nonatomic, strong) dispatch_queue_t    dispatchQueueReadPackets;

- (void) play;
- (void) pause;
- (void) stop;
- (void) restorePlay;
//cwq 2018/03/16
- (void) changePlaySpeed:(EnumChangePlaySpeed)eChangePlaySpeed;
- (BOOL) isCanDoublePlaySpeed;
////
- (void) dismissWaitView;
- (void) showWaitViewInView:(UIView *)view;//分享的时候需要显示这个，这时不一定是在这个屏幕的中间
- (void) freeBufferedFrames;

#pragma mark    Protected

- (UIView *) frameView;

- (void) didPlayOver;

- (void) didPlayProgressChanged:(int)percent;

+ (int) increaseLiveObjectsCount:(id)retainer;
+ (int) decreaseLiveObjectsCount;

+ (NSString*) editorOutputVideoFileBaseName:(NSString*)contentPath;
+ (NSString*) screenCaptureVideoFileBaseName:(NSString*)contentPath;

- (NSInteger) frameNumberOfVideoTime:(float)seconds maxFrameNumber:(int)maxFrameNumber;
- (NSData*) gyroDataOfFrameNumber:(NSInteger)frameNumber;
- (void)setUDPPro:(BOOL)UseUDPPro;

@end
