//
//  MVGLView.h
//  OpenGLESShader
//
//  Created by FutureBoy on 10/27/15.
//  Copyright © 2015 Cyllenge. All rights reserved.
//

#ifdef TARGET_OS_IOS

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

#ifdef MADVPANO_BY_SOURCE
#import "kazmath.h"
#else //#ifdef MADVPANO_BY_SOURCE
#import <MADVPano/kazmath.h>
#endif //#ifdef MADVPANO_BY_SOURCE
//#import "MVKxMovieViewController.h"
#import "MVMedia.h"

typedef enum : NSInteger {
    MVQualityLevel4K = 0,//4k,
    MVQualityLevel1080 = 1,
    MVQualityLevelOther = 2,
} MVQualityLevel;

typedef enum : int {
    GLRenderLoopNotReady = 0,
    GLRenderLoopPreparing = 1,
    GLRenderLoopRunning = 2,
    GLRenderLoopPausing = 3,
    GLRenderLoopPaused = 4,
    GLRenderLoopTerminating = 5,
    GLRenderLoopTerminated = 6,
} GLRenderLoopState;

extern NSString* kNotificationGLRenderLoopWillResignActive;
extern NSString* kNotificationGLRenderLoopDidEnterBackground;
extern NSString* kNotificationGLRenderLoopDidBecomeActive;

@class KxVideoFrame;
@class GLRenderLoop;

//void convertTexCoordWithLUT(P4C4T2f* vertices, GLsizei vertexCount);

@protocol GLRenderLoopDelegate <NSObject>

@required

- (void) glRenderLoopSetupGLRenderbuffer:(GLRenderLoop*)renderLoop;

@optional

- (void) glRenderLoop:(GLRenderLoop*)renderLoop frameTimeTicked:(int)millseconds;

@end


@interface GLRenderLoop : NSObject

//+ (void) stopCurrentRenderLoop;
//
//- (void) stopOtherRenderLoopIfAny;

+ (NSString*) stringOfGLRenderLoopState:(GLRenderLoopState)state;

+ (void) notifyApplicationWillResignActive:(id)object;
+ (void) notifyApplicationDidEnterBackground:(id)object;
+ (void) notifyApplicationDidBecomeActive:(id)object;

- (instancetype) initWithDelegate:(id<GLRenderLoopDelegate>)delegate lutPath:(NSString*)lutPath lutSrcSizeL:(CGSize)lutSrcSizeL lutSrcSizeR:(CGSize)lutSrcSizeR inputFrameSize:(CGSize)inputFrameSize outputVideoBaseName:(NSString*)outputVideoBaseName encoderQualityLevel:(MVQualityLevel)qualityLevel forCapturing:(BOOL)forCapturing;

+ (NSString*) outputVideoBaseName:(NSString*)originalVideoName qualityLevel:(MVQualityLevel)qualityLevel;

- (void) invalidateRenderbuffer;

- (void) onGyroQuaternionChanged:(CMAttitude*)attitude orientation:(UIInterfaceOrientation)orientation startOrientation:(UIInterfaceOrientation)startOrientation;
- (void) onPanRecognized:(UIPanGestureRecognizer*)panRecognizer;
- (void) onPinchRecognized:(UIPinchGestureRecognizer*)pinchRecognizer;
- (void) onDoubleTapRecognized:(UITapGestureRecognizer*)doubleTapRecognizer;

- (void) setFOVRange:(int)initFOV maxFOV:(int)maxFOV minFOV:(int)minFOV;

- (void) setIsGyroEnabled:(BOOL)enabled;
- (void) setEnablePitchDragging:(BOOL)enabled;

- (void) setVideoRecorder:(NSString*)outputVideoBaseName qualityLevel:(MVQualityLevel)qualityLevel forCapturing:(BOOL)forCapturing;

- (void) setLUTPath:(NSString*)lutPath lutSrcSizeL:(CGSize)lutSrcSizeL lutSrcSizeR:(CGSize)lutSrcSizeR;

- (void) releaseGL;

- (void) requestRedraw;

- (void) draw;

- (void) draw:(UIImage*)image withLUTStitching:(BOOL)withLUTStitching gyroMatrix:(NSData*)gyroMatrix videoCaptureResolution:(VideoCaptureResolution)videoCaptureResolution;
- (void) drawJPEG:(NSString*)filePath;
- (void) render: (KxVideoFrame *) frame;
- (void) drawStichedImageWithLeftImage:(UIImage*)leftImage rightImage:(UIImage*)rightImage;
- (void) renderImmediately: (KxVideoFrame *) frame;

- (void) setGyroMatrix:(float*)matrix rank:(int)rank;

- (void) setModelPostRotationFrom:(kmVec3)fromVector to:(kmVec3)toVector;

- (BOOL) pauseRendering;
- (BOOL) resumeRendering;
- (BOOL) stopRendering;
- (BOOL) stopRendering:(BOOL)waitForDone;
- (BOOL) startRendering;
- (BOOL) startRendering:(BOOL)waitForPrepared;

- (void) setShareMode;

- (void) stopEncoding;
- (void) setMadVData:(NSData*) MadVData;

- (BOOL) readyToRenderNextFrame;
- (void) takeSnapShot:(NSString*)destPath completion:(dispatch_block_t)completion;

- (void) startCapturing:(CGSize)videoSize;
- (void) stopCapturing;

@property (nonatomic, weak) id<GLRenderLoopDelegate> delegate;

@property (nonatomic, assign) int panoramaMode;

@property (nonatomic, assign) int filterID;

@property (nonatomic, assign) BOOL isGlassMode;

@property (nonatomic, assign) BOOL isYUVColorSpace;

@property (nonatomic, assign) MVQualityLevel encoderQualityLevel;

@property (nonatomic, assign) BOOL isFullScreenCapturing;

@property(nonatomic,strong) void(^encodingDoneBlock)(NSString*, NSError*);
@property(nonatomic,strong) void(^encodingFrameBlock)(float);
@property(nonatomic,strong) NSError* encodingError;

@property (nonatomic, strong) NSData* madVdata;
@property (nonatomic, assign) int64_t moovBoxSizeOffset;
@property (nonatomic, assign) int64_t videoTrakBoxSizeOffset;
@property (nonatomic, assign) int64_t videoTrakBoxEndOffset;

@property (nonatomic, assign) float FPS;

@property (nonatomic, assign) VideoCaptureResolution videoCaptureResolution;
@property (nonatomic, assign) VideoCaptureResolution illusionVideoCaptureResolution;//For preview

@property (nonatomic, assign) VideoCaptureResolution videoCaptureResolution4Thumbnail;
@property (nonatomic, assign) VideoCaptureResolution illusionVideoCaptureResolution4Thumbnail;//For preview

@property (nonatomic, assign) BOOL enableWatermark2D;

@end


@interface MVGLView : UIView

- (instancetype) initWithFrame:(CGRect)frame lutPath:(NSString*)lutPath lutSrcSizeL:(CGSize)lutSrcSizeL lutSrcSizeR:(CGSize)lutSrcSizeR outputVideoBaseName:(NSString*)outputVideoBaseName encoderQualityLevel:(MVQualityLevel)qualityLevel forCapturing:(BOOL)forCapturing;

@property (nonatomic, assign) BOOL enableWatermark2D;

@property (nonatomic, assign) int panoramaMode;

@property (nonatomic, assign) int filterID;

@property (nonatomic, assign) BOOL isGlassMode;

@property (nonatomic, assign) BOOL isYUVColorSpace;

//- (void) willAppear;
- (void) willDisappear;

@property (nonatomic, readonly, strong) GLRenderLoop* glRenderLoop;

@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

- (void) lookAt:(kmVec3)eularAngleDegrees;

- (void) startMotionManager;
- (void) stopMotionManager;

- (void) takeSnapShot:(NSString*)destPath completion:(dispatch_block_t)completion;

@end

#endif //#ifdef TARGET_OS_IOS
