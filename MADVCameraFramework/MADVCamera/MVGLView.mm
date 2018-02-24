//
//  MVGLView.m
//  OpenGLESShader
//
//  Created by FutureBoy on 10/27/15.
//  Copyright © 2015 Cyllenge. All rights reserved.
//

#ifdef TARGET_OS_IOS

#import "MVGLView.h"

#ifdef MADVPANO_BY_SOURCE

#import "JPEGUtils.h"
#import "PNGUtils.h"
#import "EXIFParser.h"
#import "OpenGLHelper.h"
#import "GLRenderTexture.h"
#import "GLFilterCache.h"
#import "MVPanoCameraController.h"
#import "CycordVideoRecorder.h"

#else //#ifdef MADVPANO_BY_SOURCE

#import <MADVPano/JPEGUtils.h>
#import <MADVPano/PNGUtils.h>
#import <MADVPano/EXIFParser.h>
#import <MADVPano/OpenGLHelper.h>
#import <MADVPano/GLRenderTexture.h>
#import <MADVPano/GLFilterCache.h>
#import <MADVPano/MVPanoCameraController.h>
#import <MADVPano/CycordVideoRecorder.h>

#endif //#ifdef MADVPANO_BY_SOURCE

#import "NSRecursiveCondition.h"
#import "MadvGLRenderer_iOS.h"

#ifdef FOR_DOUYIN
#import "KxMovieDecoder_douyin.h"
#else //#ifdef FOR_DOUYIN
#import "KxMovieDecoder.h"
#endif //#ifdef FOR_DOUYIN

#import "NSString+Extensions.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/EAGL.h>
#import <CoreMotion/CoreMotion.h>

#ifdef USE_FACEPP
#import "FaceppManager.h"
#endif

#import "z_Sandbox.h"

#define MAX_FOCAL_LENGTH    30.f
#define MIN_FOCAL_LENGTH    3.f

#define FlingVelocityScaleX  0.002f
#define FlingVelocityScaleY  0.002f
#define Deceleration  8
#define FLING_VELOCITY_THRESHOLD 300.f

#define FOVReferenceWidthInInch  2.4409482f

#define MAX_FOV  100
#define MAX_FOV_STEREOGRAPHIC  180
#define MAX_FOV_PLANET  155
#define MIN_FOV  30
#define INIT_FOV  100

#define LOGO_REFERENCE_HEIGHT_LANDSCAPE 21
#define LOGO_REFERENCE_HEIGHT 20

#define LOGO_CONTAINER_REFERENCE_WIDTH_LANDSCAPE 1335
#define LOGO_CONTAINER_REFERENCE_WIDTH 745
#define LOGO_CONTAINER_REFERENCE_HEIGHT_LANDSCAPE 750
#define LOGO_CONTAINER_REFERENCE_HEIGHT 420

#define LOGO_REFERENCE_LEFTMARGIN_LANDSCAPE 50
#define LOGO_REFERENCE_LEFTMARGIN 30

#define LOGO_REFERENCE_BOTTOMMARGIN_LANDSCAPE 29
#define LOGO_REFERENCE_BOTTOMMARGIN 20

static const int MaxBufferBytes = 32 * 1048576;

//#define USE_MSAA
//#define NO_RENDERTEXTURE

//#define DEBUG_GYRO_VIDEO

#ifdef DEBUG_GYRO_VIDEO

#define DEBUG_OUTPUT_DIR @"debug_output"

#endif //#ifdef DEBUG_GYRO_VIDEO

NSString* kNotificationGLRenderLoopWillResignActive = @"kNotificationGLRenderLoopWillResignActive";
NSString* kNotificationGLRenderLoopDidEnterBackground = @"kNotificationGLRenderLoopDidEnterBackground";
NSString* kNotificationGLRenderLoopDidBecomeActive = @"kNotificationGLRenderLoopDidBecomeActive";

#pragma mark    GLRenderLoop

@interface GLRenderLoop () <CycordVideoRecorderDelegate>
{
    GLRenderLoopState _state;
    BOOL _notificationObserverRegistered;
    
    EAGLContext* _eaglContext;
    //    CADisplayLink* _displayLink;
    id _nextRenderSource;
    id _previewRenderSource;
    BOOL _hasPreviewShown;
    BOOL _hasSetRenderSource;
    BOOL _willRebindGLCanvas;
    BOOL _isGyroEnabled;
    BOOL _isShareMode;
    NSRecursiveCondition* _renderCond;
    BOOL _readyToRenderNextFrame;
    
    NSString* _snapshotDestPath;
    dispatch_block_t _snapshotCompletionHandler;
    
    CycordVideoRecorder* _videoRecorder;
    
    GLint _width;
    GLint _height;
    GLint _inputWidth;
    GLint _inputHeight;
    
    GLuint _framebuffer;
    GLuint _renderbuffer;
    GLuint _depthRenderbuffer;
    
    GLuint _msaaFramebuffer;
    GLuint _msaaRenderbuffer;
    //    GLuint _msaaDepthbuffer;
    
    MVPanoRenderer* _renderer;
    MVPanoCameraController* _panoController;
    
    AutoRef<GLRenderTexture> _recorderRenderTexture;
    CGSize _outputVideoSize;
    
    GLuint _recorderLogoTexture;
    float _recorderLogoAspect;
    
    AutoRef<GLRenderTexture> _renderTexture0;
    AutoRef<GLRenderTexture> _renderTexture1;
    ///MVPanoRenderer* _renderer1;
    float _gyroMatrix[16];
    int _gyroMatrixRank;
    AutoRef<GLFilterCache> _filterCache;
    GLuint _capsTexture;
    
    //缩放值
    float _prevFOV;
    float _FOV;
    float _minFOV;
    float _maxFOV;
    
    BOOL _isRenderThreadRunning;
    
    BOOL _recording;
    BOOL _capturing;
    BOOL _inCapturing;
    long _startTimeMills;
    long _currentFrameTimestamp;
    CGFloat _inputVideoFrameTimeStamp;
    int  _inputVideoFrameNumber;
    
    BOOL _withLUTStitching;
    NSString* _lutPath;
    NSString* _prevLutPath;
    CGSize _lutSrcSizeL;
    CGSize _lutSrcSizeR;
#ifdef USE_FACEPP
    /// For Face Detection:
    AutoRef<GLRenderTexture> _faceppCubemapTexture;
    GLuint _faceppCubemapFacePBOs[6];
    GLubyte* _faceppCubempaFacePixelDatas;
    long _prevFaceppDetectFrameNumber;
#endif
    __weak id<GLRenderLoopDelegate> _delegate;
}

@property (nonatomic, strong) NSRecursiveCondition* renderCond;

@property (nonatomic, assign) BOOL recording;
@property (nonatomic, assign) BOOL capturing;

@end

//static GLRenderLoop* s_currentRenderLoop = nil;
//static BOOL s_willStopCurrentRenderLoop = NO;

@implementation GLRenderLoop

@synthesize delegate = _delegate;
@synthesize isGlassMode;
@synthesize encoderQualityLevel;
@synthesize encodingDoneBlock;
@synthesize encodingFrameBlock;
@synthesize encodingError;
@synthesize panoramaMode;
@synthesize renderCond = _renderCond;
@synthesize recording = _recording;
@synthesize capturing = _capturing;
@synthesize isFullScreenCapturing;
@synthesize FPS;
@synthesize videoCaptureResolution;
@synthesize illusionVideoCaptureResolution;
@synthesize videoCaptureResolution4Thumbnail;
@synthesize illusionVideoCaptureResolution4Thumbnail;
//@synthesize isScrolling = _isScrolling;
//@synthesize isFlinging = _isFlinging;
//@synthesize isUsingGyro = _isUsingGyro;

+ (NSString*) stringOfGLRenderLoopState:(GLRenderLoopState)state {
    switch (state) {
        case GLRenderLoopPaused:
            return @"GLRenderLoopPaused";
        case GLRenderLoopPausing:
            return @"GLRenderLoopPausing";
        case GLRenderLoopNotReady:
            return @"GLRenderLoopNotReady";
        case GLRenderLoopTerminated:
            return @"GLRenderLoopTerminated";
        case GLRenderLoopTerminating:
            return @"GLRenderLoopTerminating";
        case GLRenderLoopRunning:
            return @"GLRenderLoopRunning";
        default:
            return @"N/A";
    }
}

- (void) setInCapturing:(BOOL)inCapturing {
    @synchronized (self)
    {
        if (_inCapturing == inCapturing)
            return;
        
        if (inCapturing)
        {
            _startTimeMills = getCurrentTimeMills();
            if (-1 == _currentFrameTimestamp)
            {
                _currentFrameTimestamp = 0;
            }
        }
        else
        {
            long tmp = _startTimeMills;
            _startTimeMills = -1;
            _currentFrameTimestamp += (getCurrentTimeMills() - tmp);
        }
        
        _inCapturing = inCapturing;
    }
}

- (BOOL) inCapturing {
    return _inCapturing;
}
//*
+ (dispatch_queue_t) sharedRenderingQueue {
    static dispatch_once_t once;
    static dispatch_queue_t s_renderingQueue = nil;
    dispatch_once(&once, ^{
        s_renderingQueue = dispatch_queue_create("Rendering", DISPATCH_QUEUE_SERIAL);
    });
    return s_renderingQueue;
}
//*/
+ (void) notifyApplicationWillResignActive:(id)object {
    DoctorLog(@"#BackgroundCrash#GLRenderLoopState# GLRenderLoop notifyApplicationWillResignActive");
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationGLRenderLoopWillResignActive object:object];
}

+ (void) notifyApplicationDidEnterBackground:(id)object {
    DoctorLog(@"#BackgroundCrash#GLRenderLoopState# GLRenderLoop notifyApplicationDidEnterBackground");
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationGLRenderLoopDidEnterBackground object:object];
}

+ (void) notifyApplicationDidBecomeActive:(id)object {
    DoctorLog(@"#BackgroundCrash#GLRenderLoopState# GLRenderLoop notifyApplicationDidBecomeActive");
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationGLRenderLoopDidBecomeActive object:object];
}

- (void) dealloc {
    DoctorLog(@"#GLRenderLoopState# dealloc @%lx", (long)self.hash);
}

//+ (void) stopCurrentRenderLoop {
//    @synchronized (self)
//    {
//        NSLog(@"EAGLContext : GLRenderLoop stopCurrentRenderLoop # Before stopCurrentRenderLoop @ %lx : s_willStopCurrentRenderLoop = %d, s_currentRenderLoop = %lx",  self.hash, s_willStopCurrentRenderLoop, s_currentRenderLoop.hash);
//        if (s_currentRenderLoop)
//        {
//            s_willStopCurrentRenderLoop = NO;
//            [s_currentRenderLoop stopRendering];
//        }
//        else
//        {
//            s_willStopCurrentRenderLoop = YES;
//        }
//        NSLog(@"EAGLContext : GLRenderLoop stopCurrentRenderLoop # After stopCurrentRenderLoop @ %lx : s_willStopCurrentRenderLoop = %d, s_currentRenderLoop = %lx",  self.hash, s_willStopCurrentRenderLoop, s_currentRenderLoop.hash);
//    }
//}
//
//- (void) stopOtherRenderLoopIfAny {
//    @synchronized (self.class)
//    {
//        if (!s_currentRenderLoop || s_currentRenderLoop == self)
//        {
//            return;
//        }
//    }
//    [GLRenderLoop stopCurrentRenderLoop];
//}

- (MVPanoRenderer*) renderer {
    return _renderer;
}

- (void) setIsYUVColorSpace:(BOOL)isYUVColorSpace {
    [_renderCond lock];
    if (self.isRendererReady)
    {
        [_renderer setIsYUVColorSpace:isYUVColorSpace];
    }
    [_renderCond unlock];
}

- (BOOL) isYUVColorSpace {
    BOOL ret = NO;
    [_renderCond lock];
    if (self.isRendererReady)
    {
        ret = _renderer.isYUVColorSpace;
    }
    [_renderCond unlock];
    return ret;
}

- (void) releaseGL {
    NSLog(@"EAGLContext : GLRenderLoop Begin releaseGL %lx",  self.hash);
    [EAGLContext setCurrentContext:_eaglContext];
    
    NSLog(@"EAGLContext : GLRenderLoop renderLoop # glClear, _eaglContext = %lx @ %lx",  _eaglContext.hash, self.hash);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    glViewport(0, 0, _width, _height);
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    //    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glFlush();
    [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
    
    if (_framebuffer)
    {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_msaaFramebuffer)
    {
        glDeleteFramebuffers(1, &_msaaFramebuffer);
        _msaaFramebuffer = 0;
    }
    //    if (_msaaDepthbuffer)
    //    {
    //        glDeleteRenderbuffers(1, &_msaaDepthbuffer);
    //    }
    if (_msaaRenderbuffer)
    {
        glDeleteRenderbuffers(1, &_msaaRenderbuffer);
        _msaaRenderbuffer = 0;
    }
    
    if (_renderbuffer)
    {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    
    if (_depthRenderbuffer)
    {
        glDeleteRenderbuffers(1, &_depthRenderbuffer);
        _depthRenderbuffer = 0;
    }
    
    _eaglContext = nil;
    
    _renderer = nil;
    _panoController = nil;
    
    _recorderRenderTexture = NULL;
    
    glDeleteTextures(1, &_recorderLogoTexture);
    _recorderLogoTexture = 0;
    
    if (_renderTexture0) _renderTexture0->releaseGLObjects();
    _renderTexture0 = NULL;
    if (_renderTexture1) _renderTexture1->releaseGLObjects();
    _renderTexture1 = NULL;
    
    ///_renderer1 = nil;
    
    if (_filterCache) _filterCache->releaseGLObjects();
    _filterCache = NULL;
    
    if (_capsTexture)
    {
        glDeleteTextures(1, &_capsTexture);
        _capsTexture = 0;
    }
#ifdef USE_FACEPP
    if (_faceppCubemapTexture)
    {
        _faceppCubemapTexture = NULL;
    }
    if (_faceppCubemapFacePBOs)
    {
        glDeleteBuffers(6, _faceppCubemapFacePBOs);
        memset(_faceppCubemapFacePBOs, 0, sizeof(_faceppCubemapFacePBOs));
    }
    if (_faceppCubempaFacePixelDatas)
    {
        free(_faceppCubempaFacePixelDatas);
        _faceppCubempaFacePixelDatas = NULL;
    }
    _prevFaceppDetectFrameNumber = 0;
#endif
    glFinish();
    [EAGLContext setCurrentContext:nil];
    NSLog(@"EAGLContext : GLRenderLoop End releaseGL %lx",  self.hash);
}

- (instancetype) initWithDelegate:(id<GLRenderLoopDelegate>)delegate lutPath:(NSString*)lutPath lutSrcSizeL:(CGSize)lutSrcSizeL lutSrcSizeR:(CGSize)lutSrcSizeR inputFrameSize:(CGSize)inputFrameSize outputVideoBaseName:(NSString*)outputVideoBaseName encoderQualityLevel:(MVQualityLevel)qualityLevel forCapturing:(BOOL)forCapturing {
    if (self = [super init])
    {
        _delegate = delegate;
        _notificationObserverRegistered = NO;
        
        FPS = 29.97;
        
        _startTimeMills = -1;
        _currentFrameTimestamp = -1;
        _inputVideoFrameTimeStamp = -1.f;
        _inputVideoFrameNumber = -1;
        
        [self setVideoRecorder:outputVideoBaseName qualityLevel:qualityLevel forCapturing:forCapturing];
        
        _inputWidth = inputFrameSize.width;
        _inputHeight = inputFrameSize.height;
        
        _withLUTStitching = NO;
        [self setLUTPath:lutPath lutSrcSizeL:lutSrcSizeL lutSrcSizeR:lutSrcSizeR];
        
        _prevFOV = INIT_FOV;
        _FOV = INIT_FOV;
        _maxFOV = -1;
        _minFOV = -1;
        
        _state = GLRenderLoopNotReady;
        DoctorLog(@"#GLRenderLoopState# initWithDelegate : _state = GLRenderLoopNotReady @%lx", (long)self.hash);
        
        _readyToRenderNextFrame = YES;
        
        _isGyroEnabled = NO;
        
        _snapshotDestPath = nil;
        //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ////            _isRendererRunning = NO;
        ////            _isGLReady = NO;
        //            [self startRendering];
        //            [_renderCond lock];
        //            {
        //                while (!_isGLReady)
        //                {
        //                    [_renderCond wait];
        //                }
        //            }
        //            [_renderCond unlock];
        //        });
        _gyroMatrixRank = 0;
#ifdef USE_FACEPP
        memset(_faceppCubemapFacePBOs, 0, sizeof(_faceppCubemapFacePBOs));
        _faceppCubemapTexture = NULL;
        _faceppCubempaFacePixelDatas = NULL;
        _prevFaceppDetectFrameNumber = 0;
#endif
        self.videoCaptureResolution = FPS30_3456x1728;
        self.illusionVideoCaptureResolution = FPS30_3456x1728;
        self.videoCaptureResolution4Thumbnail = FPS30_3456x1728;
        self.illusionVideoCaptureResolution4Thumbnail = FPS30_3456x1728;
    }
    return self;
}

- (void) invalidateRenderbuffer {
    NSLog(@"EAGLContext : invalidateRenderbuffer");
    _willRebindGLCanvas = YES;
}

- (void) setIsGyroEnabled:(BOOL)enabled {
    _isGyroEnabled = enabled;
    if (self.renderer && _panoController)
    {
        [_panoController setEnablePitchDragging:!enabled];
        [self lookAt:{0.f,0.f,0.f}];///!!!#Bug3487#
    }
}

- (void) setEnablePitchDragging:(BOOL)enabled {
    if (self.renderer && _panoController)
    {
        [_panoController setEnablePitchDragging:enabled];
    }
}

- (void) onGyroQuaternionChanged:(CMAttitude*)attitude orientation:(UIInterfaceOrientation)orientation startOrientation:(UIInterfaceOrientation)startOrientation {
    @synchronized (self)
    {
        [self.renderCond lock];
        if (self.isRendererReady)
        {
            if (NULL != _panoController)
            {
                [_panoController setGyroRotationQuaternion:attitude orientation:orientation startOrientation:startOrientation];
            }
        }
        [self.renderCond unlock];
    }
    //            NSLog(@"Attitude:<%f,%f,%f> at %f", attitude.yaw, attitude.pitch, attitude.roll, motion.timestamp);
    //if ([pSelf.mediaAsset isKindOfClass:UIImage.class])
    {
        [self requestRedraw];
    }
}
/*
+ (kmVec2) draggingPointFromScreenPoint:(CGPoint)point screenSize:(CGSize)screenSize {
    return {(float)point.x / (float)screenSize.width - 0.5f, 0.5f - (float)point.y / (float)screenSize.height};
}

+ (kmVec2) screenPointFromDraggingPoint:(kmVec2)draggingPoint screenSize:(CGSize)screenSize {
    return {(draggingPoint.x + 0.5f) * (float)screenSize.width, (float)screenSize.height * (0.5f - draggingPoint.y)};
}
//*/
- (void) onPanRecognized : (UIPanGestureRecognizer*)panRecognizer {
    CGPoint velocityVector = [panRecognizer velocityInView:panRecognizer.view];
//    float velocityScalar = sqrtf(velocityVector.x * velocityVector.x + velocityVector.y * velocityVector.y);
//    NSLog(@"#Fling# velocity = %f", velocityScalar);
    CGPoint pointInView = [panRecognizer locationInView:panRecognizer.view];
    CGSize frameSize = panRecognizer.view.frame.size;
    //kmVec2 touchVec2f = [self.class draggingPointFromScreenPoint:touchPoint screenSize:frameSize];
    //kmVec2 normalizedVelocity = {(float)(velocityVector.x / frameSize.width), (float)(velocityVector.y / frameSize.height)};
    
    @synchronized (self)
    {
        switch (panRecognizer.state) {
            case UIGestureRecognizerStateBegan:
                {
                    if (nil != _renderer && NULL != _panoController)
                    {
                        //_panoController->startTouchControl(touchVec2f);
                        [_panoController startDragging:pointInView viewSize:frameSize];
                    }
//                    _isScrolling = YES;
//                    _isFlinging = NO;
//                    _isUsingGyro = NO;
//                    _flingVelocityX = _flingVelocityY = 0;
                }
                break;
            case UIGestureRecognizerStateChanged:
                {
                    if (nil != _renderer && NULL != _panoController)
                    {
                        //_panoController->setDragPoint(touchVec2f);
                        [_panoController dragTo:pointInView viewSize:frameSize];
                    }
                }
                break;
            case UIGestureRecognizerStateCancelled:
            case UIGestureRecognizerStateEnded:
                if (nil != _renderer && NULL != _panoController)
                {
                    //_panoController->stopTouchControl(normalizedVelocity);
                    [_panoController stopDraggingAndFling:velocityVector viewSize:frameSize];
                }
                break;
            default:
                break;
        }
        [self requestRedraw];
    }
}

- (void) onPinchRecognized:(UIPinchGestureRecognizer*)pinchRecognizer {
    if (nil != _renderer)
    {
        switch (pinchRecognizer.state) {
            case UIGestureRecognizerStateBegan:
                _prevFOV = _FOV;
                break;
            case UIGestureRecognizerStateChanged:
                {
                    _FOV = (float) (_prevFOV / pinchRecognizer.scale);
                    [self requestRedraw];
                }
                break;
            default:
                break;
        }
    }
}

- (void) lookAt:(kmVec3)eularAngleDegrees {
    [_renderCond lock];
    if (self.isRendererReady)
    {
        if (nil != _renderer && NULL != _panoController)
        {
            
            [_panoController lookAtYaw:eularAngleDegrees.x pitch:eularAngleDegrees.y bank:eularAngleDegrees.z];
            [self requestRedraw];
        }
    }
    [_renderCond unlock];
}

- (void) onDoubleTapRecognized:(UITapGestureRecognizer*)tapRecognizer {
    [self lookAt:{0.f,0.f,0.f}];
}

- (void) setLUTPath:(NSString*)lutPath lutSrcSizeL:(CGSize)lutSrcSizeL lutSrcSizeR:(CGSize)lutSrcSizeR {
    _lutPath = lutPath;
    _lutSrcSizeL = lutSrcSizeL;
    _lutSrcSizeR = lutSrcSizeR;
}

+ (NSString*) outputVideoBaseName:(NSString*)originalVideoName qualityLevel:(MVQualityLevel)qualityLevel {
    NSString* outputVideoBaseName = originalVideoName;
    switch (qualityLevel)
    {
        case MVQualityLevel4K:
            outputVideoBaseName = [outputVideoBaseName stringByAppendingString:@"4K"];
            break;
        case MVQualityLevel1080:
            outputVideoBaseName = [outputVideoBaseName stringByAppendingString:@"1080"];
            break;
        default:
            break;
    }
    if (!outputVideoBaseName || outputVideoBaseName.length <= 0)
    {
        outputVideoBaseName = @"image_snapshot";
    }
    return outputVideoBaseName;
}

- (void) setVideoRecorder:(NSString*)outputVideoBaseName qualityLevel:(MVQualityLevel)qualityLevel forCapturing:(BOOL)forCapturing {
    _capturing = forCapturing;
    if (!_capturing)
    {
        _recording = (outputVideoBaseName && outputVideoBaseName.length > 0);
    }
    else
    {
        _recording = NO;
    }
    self.encoderQualityLevel = qualityLevel;
    if (!_capturing)
    {
        outputVideoBaseName = [self.class outputVideoBaseName:outputVideoBaseName qualityLevel:qualityLevel];
    }
    if (!_videoRecorder || !_capturing)
        _videoRecorder = [[CycordVideoRecorder alloc] initWithOutputVideoBaseName:outputVideoBaseName];
    _videoRecorder.delegate = self;
}

#define RenderTextureScale 1.0f

- (void) resizeFilterRenderTexture:(CGSize)size {
    ///!!!    if (_renderTexture0)
    //    {
    //        _renderTexture0->resizeIfNecessary(size.width * RenderTextureScale, size.height * RenderTextureScale);
    //    }
    //    else
    //    {
    //        _renderTexture0 = new GLRenderTexture(size.width * RenderTextureScale, size.height * RenderTextureScale);
    //        NSLog(@"_filterRenderTexture = %d", _renderTexture0->getTexture());
    //    }
}

- (void) resizeVideoRecorder:(CGSize)outputVideoSize {
    _inputWidth = outputVideoSize.width;
    _inputHeight = outputVideoSize.height;
    
    if (!_recording && !_capturing)
        return;
    
    if (_capturing)
    {//*
        if (self.isFullScreenCapturing)
        {
            outputVideoSize = CGSizeMake(_width, _height);
        }
        else
      //*/
        {
            outputVideoSize = CGSizeMake(1920, 1080);
        }
    }
    else if (_recording)
    {
        switch (self.encoderQualityLevel) {
            case MVQualityLevel4K:
                outputVideoSize = CGSizeMake(outputVideoSize.width, outputVideoSize.height);
                break;
            case MVQualityLevel1080:
                outputVideoSize = CGSizeMake(2304, 1152);
                break;
            default:
                outputVideoSize = CGSizeMake(outputVideoSize.width, outputVideoSize.height);
                break;
        }
    }
    
    //    outputVideoSize = CGSizeMake(_width, _height);///!!!For Debug
    //    [self resizeFilterRenderTexture:CGSizeMake(_width, _height)];///!!!For Debug
    [self resizeFilterRenderTexture:outputVideoSize];
    
    if (outputVideoSize.width > 0 && outputVideoSize.height > 0)
    {
        _outputVideoSize = outputVideoSize;
        if (_videoRecorder)
        {
            [_videoRecorder setViewSize:outputVideoSize];
            if (_isShareMode) {
                [_videoRecorder setShareMode];
            }
            [_videoRecorder setFPS:FPS];
            [_videoRecorder setupVideoRecorder];
            
            if (_videoRecorder)
            {
                if (NULL == _recorderRenderTexture || outputVideoSize.width != _recorderRenderTexture->getWidth() || outputVideoSize.height != _recorderRenderTexture->getHeight())
                {
                    CVOpenGLESTextureRef cvTexture = _videoRecorder.renderTexture;
                    _recorderRenderTexture = new GLRenderTexture(CVOpenGLESTextureGetName(cvTexture), CVOpenGLESTextureGetTarget(cvTexture), outputVideoSize.width, outputVideoSize.height);
                    NSLog(@"_recorderRenderTexture = %d", _recorderRenderTexture->getTexture());
                }
            }
        }
    }
    //    }///!!!For Debug
}

#pragma mark    CycordVideoRecorderDelegate

- (void) cycordVideoRecorderDidRenderOneFrame:(int)elapsedMillseconds {
    
}

- (void) cycordVideoRecorderDidRecordOneFrame:(int)recordedMillseconds {
    
}

- (void) cycordVideoRecorderFailedWhileRecording:(NSError *)error {
    self.encodingError = error;
    [self stopRendering];
    //[self stopEncoding:nil];
}

- (void) onApplicationWillResignActive:(id)object {
    [self pauseRendering];
}

- (void) onApplicationDidEnterBackground:(id)object {
    
}

- (void) onApplicationDidBecomeActive:(id)object {
    [self resumeRendering];
}

- (void) renderLoop:(id)object {
    if (!_notificationObserverRegistered)
    {
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(onApplicationWillResignActive:) name:kNotificationGLRenderLoopWillResignActive object:nil];
        [nc addObserver:self selector:@selector(onApplicationDidEnterBackground:) name:kNotificationGLRenderLoopDidEnterBackground object:nil];
        [nc addObserver:self selector:@selector(onApplicationDidBecomeActive:) name:kNotificationGLRenderLoopDidBecomeActive object:nil];
        
        _notificationObserverRegistered = YES;
    }
    
    // Init GL and GL objects:
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:_eaglContext];
    NSLog(@"EAGLContext : GLRenderLoop renderLoop begin, _eaglContext = %lx @ %lx",  _eaglContext.hash, (long)self.hash);
    
    //    NSLog(@"EAGLContext : GLRenderLoop renderLoop # glClear, _eaglContext = %lx @ %lx",  _eaglContext.hash, self.hash);
    //    glViewport(0, 0, _width, _height);
    //    glClearColor(0, 0, 0, 1);
    //    glClear(GL_COLOR_BUFFER_BIT);
    //    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    //    [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
    
#ifdef USE_MSAA
    //        _supportDiscardFramebuffer = NO;
    //        char* glExtensions = (char*)glGetString(GL_EXTENSIONS);
    //        if (glExtensions && strstr(glExtensions, "GL_EXT_discard_framebuffer"))
    //        {
    //            _supportDiscardFramebuffer = YES;
    //        }
    //        NSLog(@"GLExt : %s\n", glExtensions);
    
    glGenFramebuffers(1, &_msaaFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _msaaFramebuffer);
    glGenRenderbuffers(1, &_msaaRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _msaaRenderbuffer);
    //        glGenRenderbuffers(1, &_msaaDepthbuffer);
    CHECK_GL_ERROR();
#endif
    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glGenRenderbuffers(1, &_depthRenderbuffer);
    glGenRenderbuffers(1, &_renderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    CHECK_GL_ERROR();
    //    CAEAGLLayer* layer = (CAEAGLLayer*) self.layer;
    //    layer.opaque = YES;
    //    layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
    //                                //If use glReadPixels to get pixel data after presentRenderbuffer, RetainedBacking should be set to YES:
    //                                [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
    //                                kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    CHECK_GL_ERROR();
    [self rebindGLCanvas];
    
    _renderer = [[MVPanoRenderer alloc] initWithLUTPath:_lutPath leftSrcSize:_lutSrcSizeL rightSrcSize:_lutSrcSizeR];
    _panoController = [[MVPanoCameraController alloc] initWithPanoRenderer:_renderer];
    
    _prevLutPath = _lutPath;
#ifdef ENABLE_OPENGL_DEBUG
    _renderer->setEnableDebug(true);
#endif
    [self setIsGyroEnabled:_isGyroEnabled];
    /*
    NSString* capLogoPath = [[NSBundle mainBundle] pathForResource:@"shot_by_madv_en" ofType:@"png"];
    _capsTexture = createTextureFromPNG(capLogoPath.UTF8String);
    ////    _capsTexture = createTextureFromImage([UIImage imageNamed:@"madv_cap_logo"]);
    [_renderer setNeedDrawCaps:YES];
    [_renderer setCapsTexture:_capsTexture];
    //*/
    //    ///!!!:For Debug
    NSString* resourcePath = [[NSBundle mainBundle] pathForResource:@"lookup" ofType:@"png"];
    resourcePath = [resourcePath stringByDeletingLastPathComponent];
    _filterCache = new GLFilterCache(resourcePath.UTF8String);
    
    if (_capturing)
    {
        NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
        NSString* language = [NSString getAppLessLanguage];
        NSString* logoPNGPath = nil;
        if ([language isEqualToString:@"zh-Hans"] || [language isEqualToString:@"zh-Hant"])
        {
            if ([bundleID isEqualToString:@"com.madventure360.madv"])
                logoPNGPath = @"shot_by_madv_landscape_en";
            else
                logoPNGPath = @"shot_by_mi_landscape_cn";
        }
        else
        {
            if ([bundleID isEqualToString:@"com.madventure360.madv"])
                logoPNGPath = @"shot_by_madv_landscape_en";
            else
                logoPNGPath = @"shot_by_mi_landscape_en";
        }
        logoPNGPath = [[NSBundle mainBundle] pathForResource:logoPNGPath ofType:@"png"];
        UIImage* logoImage = [UIImage imageWithContentsOfFile:logoPNGPath];
        _recorderLogoTexture = createTextureFromImage(logoImage, logoImage.size);
        _recorderLogoAspect = logoImage.size.width / logoImage.size.height;
        logoImage = nil;
    }
    
    [_renderCond lock];
    {
        if (GLRenderLoopNotReady == _state || GLRenderLoopTerminated == _state)
        {
            _state = GLRenderLoopRunning;
            DoctorLog(@"#GLRenderLoopState# renderLoop : _state = GLRenderLoopRunning #0 @renderLoop: @%lx", (long)self.hash);
            [_renderCond broadcast];
        }
    }
    [_renderCond unlock];
    // Main Loop:
    id prevRenderSource = nil;
    while (GLRenderLoopTerminating != _state)
    {
        @autoreleasepool //write by spy
        {
            [_renderCond lock];
            {
                //BOOL waited = NO;
                while (GLRenderLoopPausing == _state || GLRenderLoopPaused == _state)
                {
                    //waited = YES;
                    if (GLRenderLoopPausing == _state)
                    {
                        glFinish();
                        _state = GLRenderLoopPaused;
                        DoctorLog(@"#GLRenderLoopState# renderLoop : _state = GLRenderLoopPaused @%lx", (long)self.hash);
                        [_renderCond broadcast];
                    }
                    
                    [_renderCond wait];
                }
                //if (waited)
                //{
                //    NSLog(@"EAGLContext : GLRenderLoop renderLoop wakeup @ %x", (int)self.hash);
                //}
            }
            [_renderCond unlock];
            if (GLRenderLoopTerminating == _state)
            {NSLog(@"EAGLContext : GLRenderLoop renderLoop !_isRendererRunning @ %x", (int)self.hash);
                break;
            }
            
            long loopStart = [[NSDate date] timeIntervalSince1970] * 1000.f;
            // Rendering one frame:
            if (_willRebindGLCanvas)
            {
                _willRebindGLCanvas = NO;
                [self rebindGLCanvas];
            }
            
            if (_lutPath && ![_lutPath isEqualToString:_prevLutPath])
            {
                [_renderer prepareLUT:_lutPath leftSrcSize:_lutSrcSizeL rightSrcSize:_lutSrcSizeR];
                _prevLutPath = _lutPath;
            }
            
            //        id renderSource = [self readRenderSource];
            id renderSource = nil;
            @synchronized (self)
            {
                if (_previewRenderSource && !_hasPreviewShown)
                {
                    _hasPreviewShown = YES;
                    renderSource = _previewRenderSource;
                    _previewRenderSource = nil;
                }
                else
                {
                    renderSource = _nextRenderSource;
                    _nextRenderSource = nil;
                }
            }
            //        renderSource = nil;
            ///!!!For Debug #VideoLeak#
            
            if (renderSource && renderSource != prevRenderSource)
            {//NSLog(@"VideoLeak : new renderSource coming : %@", renderSource);
                prevRenderSource = renderSource;
                
                if ([renderSource isKindOfClass:NSString.class])
                {NSLog(@"#MVGLView# Rendering JPEG");
                    NSString* filePath = (NSString*) renderSource;
                    //    [self resizeVideoRecorder:image.size];
                    
                    kmScalar textureMatrixData[] = {
                        1.f, 0.f, 0.f, 0.f,
                        0.f, -1.f, 0.f, 0.f,
                        0.f, 0.f, 1.f, 0.f,
                        0.f, 1.f, 0.f, 1.f,
                    };
                    kmMat4 textureMatrix;
                    kmMat4Fill(&textureMatrix, textureMatrixData);
                    [_renderer setTextureMatrix:&textureMatrix];
                    [_renderer setIllusionTextureMatrix:&textureMatrix];
                    
                    [_renderer setRenderSource:(__bridge_retained void*)filePath];
                    _hasSetRenderSource = YES;
                }
                else if ([renderSource isKindOfClass:UIImage.class])
                {NSLog(@"#MVGLView# Rendering UIImage");
                    kmScalar textureMatrixData[] = {
                        1.f, 0.f, 0.f, 0.f,
                        0.f, -1.f, 0.f, 0.f,
                        0.f, 0.f, 1.f, 0.f,
                        0.f, 1.f, 0.f, 1.f,
                    };
                    kmMat4 textureMatrix;
                    kmMat4Fill(&textureMatrix, textureMatrixData);
                    [_renderer setTextureMatrix:&textureMatrix videoCaptureResolution:videoCaptureResolution4Thumbnail];
                    [_renderer setIllusionTextureMatrix:&textureMatrix videoCaptureResolution:illusionVideoCaptureResolution4Thumbnail];
                    
                    UIImage* image = (UIImage*) renderSource;
                    //[self resizeVideoRecorder:image.size];
                    
                    [_renderer setRenderSource:(__bridge_retained void*)image];
                    _hasSetRenderSource = YES;
                }
                else if ([renderSource isKindOfClass:NSClassFromString(@"KxVideoFrame")])
                {
                    kmScalar textureMatrixData[] = {
                        1.f, 0.f, 0.f, 0.f,
                        0.f, -1.f, 0.f, 0.f,
                        0.f, 0.f, 1.f, 0.f,
                        0.f, 1.f, 0.f, 1.f,
                    };
                    kmMat4 textureMatrix;
                    kmMat4Fill(&textureMatrix, textureMatrixData);
                    [_renderer setTextureMatrix:&textureMatrix videoCaptureResolution:self.videoCaptureResolution];
                    [_renderer setIllusionTextureMatrix:&textureMatrix videoCaptureResolution:self.illusionVideoCaptureResolution];
                    
                    //KxVideoFrame* frame = (KxVideoFrame*) renderSource;
                    static SEL widthSelector = NSSelectorFromString(@"width");
                    static IMP widthImp = [renderSource methodForSelector:widthSelector];
                    static NSUInteger (*widthFunc)(id, SEL) = (NSUInteger(*)(id,SEL)) widthImp;
                    NSUInteger frameWidth = widthFunc(renderSource, widthSelector);
                    
                    static SEL heightSelector = NSSelectorFromString(@"height");
                    static IMP heightImp = [renderSource methodForSelector:heightSelector];
                    static NSUInteger (*heightFunc)(id, SEL) = (NSUInteger(*)(id,SEL)) heightImp;
                    NSUInteger frameHeight = heightFunc(renderSource, heightSelector);
                    
                    [self resizeVideoRecorder:CGSizeMake(frameWidth, frameHeight)];
                    /*
                    static SEL frameNumberSelector = NSSelectorFromString(@"frameNumber");
                    static IMP frameNumberImp = [renderSource methodForSelector:frameNumberSelector];
                    static NSInteger (*frameNumberFunc)(id, SEL) = (NSInteger(*)(id,SEL)) frameNumberImp;
                    NSInteger frameNumber = frameNumberFunc(renderSource, frameNumberSelector);
                    //*/
                    static SEL gyroDataSelector = NSSelectorFromString(@"gyroData");
                    static IMP gyroDataImp = [renderSource methodForSelector:gyroDataSelector];
                    static NSData* (*gyroDataFunc)(id, SEL) = (NSData*(*)(id, SEL)) gyroDataImp;
                    NSData* gyroData = gyroDataFunc(renderSource, gyroDataSelector);
                    if (gyroData)
                    {
                        float* matrix = (float*)gyroData.bytes;
                        //printf("\n#Gyro#        renderLoop: KxVideoFrameCVBuffer=%lx, frame=#%ld, matrix={%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f}\n", (NSInteger)renderSource.hash, (long)frameNumber, matrix[0],matrix[1],matrix[2],matrix[3],matrix[4],matrix[5],matrix[6],matrix[7],matrix[8]);
                        [self setGyroMatrix:matrix rank:3];
                    }
#ifdef USE_FACEPP
                    /*
                    if ([renderSource isKindOfClass:KxVideoFrameCVBuffer.class])
                    {
                        CMSampleBufferRef sampleBuffer = NULL;
                        KxVideoFrameCVBuffer* videoFrame = (KxVideoFrameCVBuffer*) renderSource;
                        CMVideoFormatDescriptionRef descriptor = NULL;
                        CMVideoFormatDescriptionCreateForImageBuffer(NULL, videoFrame.cvBufferRef, &descriptor);
                        CMSampleTimingInfo sampleTiming = kCMTimingInfoInvalid;
                        OSStatus status = CMSampleBufferCreateReadyWithImageBuffer(NULL, videoFrame.cvBufferRef, descriptor, &sampleTiming, &sampleBuffer);
                        if (0 == status)
                        {
                            [[FaceppManager sharedInstance] detectFaceInSampleBuffer:sampleBuffer];
                        }
                        CFRelease(descriptor);
                        CFRelease(sampleBuffer);
                    }
                    //*/
#endif
                    [_renderer setRenderSource:(__bridge_retained void*)renderSource];
#ifdef DEBUG_GYRO_VIDEO
                    NSString* outputDir = [z_Sandbox documentPath:DEBUG_OUTPUT_DIR];
                    NSFileManager* fm = [NSFileManager defaultManager];
                    BOOL isDirectory = YES;
                    if (![fm fileExistsAtPath:outputDir isDirectory:&isDirectory] || !isDirectory)
                    {
                        [fm createDirectoryAtPath:outputDir withIntermediateDirectories:YES attributes:nil error:nil];
                    }
                    
                    KxVideoFrame* frame = (KxVideoFrame*) renderSource;
                    NSString* snapshotJPEGPath = [NSString stringWithFormat:@"%@/%ld.jpg", outputDir, (long)roundf(frame.timestamp)];
                    [self takeSnapShot:snapshotJPEGPath completion:nil];
#endif //#ifdef DEBUG_GYRO_VIDEO
                    _hasSetRenderSource = YES;
                }
                
                CGSize sourceSize = _renderer.renderSourceSize;
                _inputHeight = sourceSize.height;
                _inputWidth = sourceSize.width;
            }
            
            if (self.inCapturing)
            {//Bug#3763
                [self resizeVideoRecorder:CGSizeMake(1600, 900)];
            }
            
            if (_hasSetRenderSource)
            {
                [self draw];
                if ([renderSource isKindOfClass:NSClassFromString(@"KxVideoFrameCVBuffer")])
                {
                    SEL releasePixelBufferSelector = NSSelectorFromString(@"releasePixelBuffer");
                    IMP releasePixelBufferImp = [renderSource methodForSelector:releasePixelBufferSelector];
                    void (*releasePixelBufferFunc)(id,SEL) = (void(*)(id,SEL)) releasePixelBufferImp;
                    releasePixelBufferFunc(renderSource, releasePixelBufferSelector);
                    //KxVideoFrameCVBuffer* cvbFrame = (KxVideoFrameCVBuffer*) frame;
                    //[cvbFrame releasePixelBuffer];
                }
            }
            renderSource = nil;
            
            @synchronized (self)
            {
                //NSLog(@"_readyToRenderNextFrame:YES");
                _readyToRenderNextFrame = YES;
            }
            
            // Targeting 60 fps, no need for faster
            long timeInterval = 16;
            [_panoController update:((float)timeInterval / 1000.f)];
            
            long waitDelta = timeInterval - ([[NSDate date] timeIntervalSince1970] * 1000.f - loopStart);
            waitDelta = (waitDelta > 0 ? waitDelta : 0);
            if (self.delegate && [self.delegate respondsToSelector:@selector(glRenderLoop:frameTimeTicked:)])
            {
                [self.delegate glRenderLoop:self frameTimeTicked:(int)waitDelta];
            }
            if (waitDelta > 0)
            {
                [NSThread sleepForTimeInterval:waitDelta/1000.f];
            }
        }
    }
    NSLog(@"EAGLContext : GLRenderLoop renderLoop Begin Finishing @ %lx",  self.hash);
    
    _nextRenderSource = nil;
    _previewRenderSource = nil;
    _hasPreviewShown = NO;
    _hasSetRenderSource = NO;
    //调整顺序 write by spy
    if (_recording || _capturing) {
        [self stopEncoding];
    }
    [self releaseGL];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _notificationObserverRegistered = NO;
    
    [_renderCond lock];
    {
        _state = GLRenderLoopTerminated;
        DoctorLog(@"#GLRenderLoopState# renderLoop : _state = GLRenderLoopTerminated @%lx", (long)self.hash);
        [_renderCond broadcast];
    }
    [_renderCond unlock];
}

- (BOOL) isRendererReady {
    return GLRenderLoopRunning == _state || GLRenderLoopPausing == _state || GLRenderLoopPaused == _state;
}

- (BOOL) pauseRendering {
    [_renderCond lock];
    {DoctorLog(@"#GLRenderLoopState# pauseRendering#0 : _state = %@ @%lx", [GLRenderLoop stringOfGLRenderLoopState:_state], (long)self.hash);
        if (GLRenderLoopRunning != _state)
        {
            [_renderCond unlock];
            return NO;
        }
        _state = GLRenderLoopPausing;
        DoctorLog(@"#GLRenderLoopState# pauseRendering#1 : _state = GLRenderLoopPausing @%lx", (long)self.hash);
        //[_renderCond broadcast];///!!!
        
        while (GLRenderLoopPausing == _state)
        {
            [_renderCond wait];
        }
    }
    [_renderCond unlock];
    return YES;
}

- (BOOL) resumeRendering {
    [_renderCond lock];
    {DoctorLog(@"#GLRenderLoopState# resumeRendering#0 : _state = %@ @%lx", [GLRenderLoop stringOfGLRenderLoopState:_state], (long)self.hash);
        if (GLRenderLoopPaused != _state)
        {
            [_renderCond unlock];
            return NO;
        }
        _state = GLRenderLoopRunning;
        DoctorLog(@"#GLRenderLoopState# resumeRendering#1 : _state = GLRenderLoopRunning @%lx", (long)self.hash);
        [_renderCond broadcast];
    }
    [_renderCond unlock];
    return YES;
}

- (BOOL) stopRendering {
    DoctorLog(@"#GLRenderLoopState# stopRendering#0 _state = %@ @%lx", [GLRenderLoop stringOfGLRenderLoopState:_state], (long)self.hash);
//    _isScrolling = NO;
//    _isFlinging = NO;
//    _isUsingGyro = NO;
    [_renderCond lock];
    {
        if (GLRenderLoopRunning != _state && GLRenderLoopPausing != _state && GLRenderLoopPaused != _state && GLRenderLoopNotReady != _state)
        {
            [_renderCond unlock];
            return NO;
        }
        _state = GLRenderLoopTerminating;
        DoctorLog(@"#GLRenderLoopState# stopRendering#1 _state = GLRenderLoopTerminating @%lx", (long)self.hash);
        [_renderCond broadcast];
        
        while (GLRenderLoopTerminating == _state)
        {
            [_renderCond wait];
        }
    }
    [_renderCond unlock];
    return YES;
}

- (BOOL) startRendering {
    @synchronized (self)
    {
        if (!_renderCond)
        {
            _renderCond = [[NSRecursiveCondition alloc] init];
        }
    }
    
    [_renderCond lock];
    {
        DoctorLog(@"#GLRenderLoopState# startRendering : _state=%@ @%lx", [GLRenderLoop stringOfGLRenderLoopState:_state], (long)self.hash);
        if (GLRenderLoopNotReady != _state && GLRenderLoopTerminated != _state && GLRenderLoopPaused != _state)
        {
            if (GLRenderLoopTerminating == _state)
            {
                _state = GLRenderLoopTerminated;
                [_renderCond broadcast];
            }
            [_renderCond unlock];
            return NO;
        }
        
        if (GLRenderLoopPaused == _state)
        {
            _state = GLRenderLoopRunning;
            DoctorLog(@"#GLRenderLoopState# startRendering#1 : _state = GLRenderLoopRunning @%lx", (long)self.hash);
            [_renderCond broadcast];
            [_renderCond unlock];
            return YES;
        }
        
        _state = GLRenderLoopNotReady;
    }
    [_renderCond unlock];
    
//    _isScrolling = NO;
//    _isFlinging = NO;
//    _isUsingGyro = NO;
    _hasPreviewShown = NO;
    _hasSetRenderSource = NO;
    _madVdata = nil;
#ifdef USE_FACEPP
    [[FaceppManager sharedInstance] reset];
    ///[[FaceppManager sharedInstance] testImageDetect:2048];
#endif
    dispatch_async([self.class sharedRenderingQueue], ^{
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        DoctorLog(@"#GLRenderLoopState# startRendering#1 : _state=%@ @%lx", [GLRenderLoop stringOfGLRenderLoopState:_state], (long)self.hash);
        [self renderLoop:nil];
    });
    DoctorLog(@"#GLRenderLoopState# startRendering#N : _state=%@ @%lx", [GLRenderLoop stringOfGLRenderLoopState:_state], (long)self.hash);
    [_renderCond lock];
    {
        while (GLRenderLoopNotReady == _state)
        {
            [_renderCond wait];
        }
    }
    [_renderCond unlock];
    return YES;
}

- (void) setShareMode {
    _isShareMode = YES;
}

- (void)setMadVdata:(NSData*) MadVData
{
    _madVdata = MadVData;
}

- (void) stopEncoding {
    @synchronized (self)
    {
        if (_recording || _capturing)
        {
            _recording = NO;
            
            __weak __typeof(self) wSelf = self;
            if (self.encodingError)
            {
                _videoRecorder.encodingError = self.encodingError;
            }
            [_videoRecorder stopRecordingWithCompletionHandler:^(NSError* error, NSString* outputFilePath){
                if (wSelf.encodingDoneBlock)
                {
                    if (!error && wSelf.encodingError)
                    {
                        error = wSelf.encodingError;
                    }
                    
                    if (!wSelf.capturing)
                    {
                        if (!error)
                        {
                            [wSelf write360VideoMetaData:outputFilePath];
                        }
                        if (!error && _madVdata != nil) {
                            NSFileHandle* fh=[NSFileHandle fileHandleForWritingAtPath:outputFilePath];
                            [fh seekToEndOfFile];
                            [fh writeData:_madVdata];
                            [fh closeFile];
                        }
                    }
                    NSLog(@"#Bug2880# stopEncoding #3");

                    wSelf.encodingDoneBlock(outputFilePath, error);
                }
            }];
        }
    }
}

- (BOOL) readyToRenderNextFrame {
    @synchronized (self) {
        return _readyToRenderNextFrame;
    }
}

- (void) write360VideoMetaData:(NSString*) outputFilePath {
    NSError *perror = [[NSError alloc] init];
    KxMovieDecoder *aDecoder = [[KxMovieDecoder alloc] init];
    if (aDecoder) {
        [aDecoder openFile:outputFilePath error:&perror];
        _moovBoxSizeOffset = aDecoder.getMoovBoxSizeOffset;
        _videoTrakBoxSizeOffset = aDecoder.getVideoTrakBoxSizeOffset;
        _videoTrakBoxEndOffset = aDecoder.getVideoTrakBoxEndOffset - 1 ;
        [aDecoder closeFile];
    }
    aDecoder = nil;
    
    if( _moovBoxSizeOffset > 0 && _videoTrakBoxSizeOffset > 0 && _videoTrakBoxEndOffset > 0) {
        NSFileHandle* fh=[NSFileHandle fileHandleForUpdatingAtPath:outputFilePath];
        NSData* sizeBufferMoovSize;
        NSData* sizeBufferVideoTrakSize;
        NSData* moovBoxSizeData;
        NSData* videoTrakBoxSizeData;
        NSData* tmp;
        NSData* videoMetaData;
        
        [fh seekToFileOffset:_moovBoxSizeOffset];
        sizeBufferMoovSize = [fh readDataOfLength:4];
        Byte *dataBytesMoovSize = (Byte *)[sizeBufferMoovSize bytes];
        int moovBoxSize = ((dataBytesMoovSize[0] << 24) & 0xff000000)
                             | ((dataBytesMoovSize[1] << 16) & 0x00ff0000)
                             | ((dataBytesMoovSize[2] << 8) & 0x0000ff00)
                             | (dataBytesMoovSize[3] & 0x000000ff);
        moovBoxSize += 454;
        dataBytesMoovSize[0] = (moovBoxSize & 0xff000000) >> 24;
        dataBytesMoovSize[1] = (moovBoxSize & 0x00ff0000) >> 16;
        dataBytesMoovSize[2] = (moovBoxSize & 0x0000ff00) >> 8;
        dataBytesMoovSize[3] = (moovBoxSize & 0x000000ff);
        moovBoxSizeData = [[NSData alloc] initWithBytes:dataBytesMoovSize length:4];
        [fh seekToFileOffset:_moovBoxSizeOffset];
        [fh writeData:moovBoxSizeData];
        
        [fh seekToFileOffset:_videoTrakBoxSizeOffset];
        sizeBufferVideoTrakSize = [fh readDataOfLength:4];
        Byte *dataBytesVideoTrakSize = (Byte *)[sizeBufferVideoTrakSize bytes];
        int videoTrakBoxSize = ((dataBytesVideoTrakSize[0] << 24) & 0xff000000)
                               | ((dataBytesVideoTrakSize[1] << 16) & 0x00ff0000)
                               | ((dataBytesVideoTrakSize[2] << 8) & 0x0000ff00)
                               | (dataBytesVideoTrakSize[3] & 0x000000ff);
        videoTrakBoxSize += 454;
        dataBytesVideoTrakSize[0] = (videoTrakBoxSize & 0xff000000) >> 24;
        dataBytesVideoTrakSize[1] = (videoTrakBoxSize & 0x00ff0000) >> 16;
        dataBytesVideoTrakSize[2] = (videoTrakBoxSize & 0x0000ff00) >> 8;
        dataBytesVideoTrakSize[3] = (videoTrakBoxSize & 0x000000ff);
        videoTrakBoxSizeData = [[NSData alloc] initWithBytes:dataBytesVideoTrakSize length:4];
        [fh seekToFileOffset:_videoTrakBoxSizeOffset];
        [fh writeData:videoTrakBoxSizeData];

        [fh seekToFileOffset:_videoTrakBoxEndOffset+1];
        tmp = [fh readDataToEndOfFile];
        
        Byte videoMetaDataBytes[] ={
            0x00, 0x00, 0x01, 0xC6, 0x75, 0x75, 0x69, 0x64, 0xFF, 0xCC, 0x82, 0x63, 0xF8, 0x55, 0x4A, 0x93, 0x88, 0x14, 0x58, 0x7A, 0x02, 0x52, 0x1F, 0xDD, 0x3C, 0x3F, 0x78, 0x6D, 0x6C, 0x20, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x3D, 0x22, 0x31, 0x2E, 0x30, 0x22, 0x3F, 0x3E, 0x3C, 0x72, 0x64, 0x66, 0x3A, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x56, 0x69, 0x64, 0x65, 0x6F, 0x0A, 0x78, 0x6D, 0x6C, 0x6E, 0x73, 0x3A, 0x72, 0x64, 0x66, 0x3D, 0x22, 0x68, 0x74, 0x74, 0x70, 0x3A, 0x2F, 0x2F, 0x77, 0x77, 0x77, 0x2E, 0x77, 0x33, 0x2E, 0x6F, 0x72, 0x67, 0x2F, 0x31, 0x39, 0x39, 0x39, 0x2F, 0x30, 0x32, 0x2F, 0x32, 0x32, 0x2D, 0x72, 0x64, 0x66, 0x2D, 0x73, 0x79, 0x6E, 0x74, 0x61, 0x78, 0x2D, 0x6E, 0x73, 0x23, 0x22, 0x0A, 0x78, 0x6D, 0x6C, 0x6E, 0x73, 0x3A, 0x47, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x3D, 0x22, 0x68, 0x74, 0x74, 0x70, 0x3A, 0x2F, 0x2F, 0x6E, 0x73, 0x2E, 0x67, 0x6F, 0x6F, 0x67, 0x6C, 0x65, 0x2E, 0x63, 0x6F, 0x6D, 0x2F, 0x76, 0x69, 0x64, 0x65, 0x6F, 0x73, 0x2F, 0x31, 0x2E, 0x30, 0x2F, 0x73, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x2F, 0x22, 0x3E, 0x3C, 0x47, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x3A, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x3E, 0x74, 0x72, 0x75, 0x65, 0x3C, 0x2F, 0x47, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x3A, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x3E, 0x3C, 0x47, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x3A, 0x53, 0x74, 0x69, 0x74, 0x63, 0x68, 0x65, 0x64, 0x3E, 0x74, 0x72, 0x75, 0x65, 0x3C, 0x2F, 0x47, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x3A, 0x53, 0x74, 0x69, 0x74, 0x63, 0x68, 0x65, 0x64, 0x3E, 0x3C, 0x47, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x3A, 0x53, 0x74, 0x69, 0x74, 0x63, 0x68, 0x69, 0x6E, 0x67, 0x53, 0x6F, 0x66, 0x74, 0x77, 0x61, 0x72, 0x65, 0x3E, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x20, 0x4D, 0x65, 0x74, 0x61, 0x64, 0x61, 0x74, 0x61, 0x20, 0x54, 0x6F, 0x6F, 0x6C, 0x3C, 0x2F, 0x47, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x3A, 0x53, 0x74, 0x69, 0x74, 0x63, 0x68, 0x69, 0x6E, 0x67, 0x53, 0x6F, 0x66, 0x74, 0x77, 0x61, 0x72, 0x65, 0x3E, 0x3C, 0x47, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x3A, 0x50, 0x72, 0x6F, 0x6A, 0x65, 0x63, 0x74, 0x69, 0x6F, 0x6E, 0x54, 0x79, 0x70, 0x65, 0x3E, 0x65, 0x71, 0x75, 0x69, 0x72, 0x65, 0x63, 0x74, 0x61, 0x6E, 0x67, 0x75, 0x6C, 0x61, 0x72, 0x3C, 0x2F, 0x47, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x3A, 0x50, 0x72, 0x6F, 0x6A, 0x65, 0x63, 0x74, 0x69, 0x6F, 0x6E, 0x54, 0x79, 0x70, 0x65, 0x3E, 0x3C, 0x2F, 0x72, 0x64, 0x66, 0x3A, 0x53, 0x70, 0x68, 0x65, 0x72, 0x69, 0x63, 0x61, 0x6C, 0x56, 0x69, 0x64, 0x65, 0x6F, 0x3E};

        videoMetaData = [[NSData alloc] initWithBytes:videoMetaDataBytes length:454];
        [fh seekToFileOffset:_videoTrakBoxEndOffset+1];
        [fh writeData:videoMetaData];
        [fh seekToFileOffset:_videoTrakBoxEndOffset+454+1];
        [fh writeData:tmp];
        
        [fh closeFile];
    }
}

- (void) setFOVRange:(int)initFOV maxFOV:(int)maxFOV minFOV:(int)minFOV {
    _prevFOV = initFOV;
    _FOV = initFOV;
    _maxFOV = maxFOV;
    _minFOV = minFOV;
}

- (void) adustAndSetFOV {
    [_renderCond lock];
    if (self.isRendererReady && NULL != _panoController)
    {
        int maxFOV = _maxFOV;
        if (maxFOV <= 0)
        {
            switch (self.panoramaMode)
            {
                case PanoramaDisplayModeStereoGraphic:
                    maxFOV = MAX_FOV_STEREOGRAPHIC;
                    break;
                case PanoramaDisplayModeLittlePlanet:
                    maxFOV = MAX_FOV_PLANET;
                    break;
                default:
                    maxFOV = MAX_FOV;
                    break;
            }
        }
        int minFOV = _minFOV;
        if (minFOV <= 0)
        {
            minFOV = MIN_FOV;
        }
        
        if (_FOV < minFOV) {
            _FOV = minFOV;
        }
        else if (_FOV > maxFOV) {
            _FOV = maxFOV;
        }
        //NSLog(@"adustAndSetFOV : %f", _FOV);
        //float widthInInch = mSurfaceTextureWidth / mDisplayMetrics.xdpi;
        //Log.e(TAG, "mSurfaceTextureWidth = " + mSurfaceTextureWidth + ", mSurfaceTextureHeight = " + mSurfaceTextureHeight);
        //float adustedFOV = (float) Math.toDegrees(Math.atan(Math.tan(Math.toRadians(FOV) / 2.f) * widthInInch / FOVReferenceWidthInInch)) * 2.f;
        //Log.e(TAG, "FOV = " + FOV + ", adustedFOV = " + adustedFOV);
        //if (null != mRenderer) {
        [_panoController setFOVDegree:(int)_FOV];
        //}
    }
    [_renderCond unlock];
}

- (void) rebindGLCanvas {
    [EAGLContext setCurrentContext:_eaglContext];
    CHECK_GL_ERROR();
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    if (self.delegate && [self.delegate respondsToSelector:@selector(glRenderLoopSetupGLRenderbuffer:)])
    {
        [self.delegate glRenderLoopSetupGLRenderbuffer:self];
    }
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_height);
    CHECK_GL_ERROR();
    
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _width, _height);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSLog(@"status = %d, width = %d, height = %d", status, _width, _height);
    CHECK_GL_ERROR();
    
    
    if (!_recording)
    {
        [self resizeFilterRenderTexture:CGSizeMake(_width, _height)];
    }
    
    
    //    glViewport(0, 0, _width, _height);
#ifdef USE_MSAA
    //    if (_msaaFramebuffer)
    //    {
    //        glDeleteFramebuffers(1, &_msaaFramebuffer);
    //        glGenFramebuffers(1, &_msaaFramebuffer);
    //    }
    glBindFramebuffer(GL_FRAMEBUFFER, _msaaFramebuffer);
    
    //    if (_msaaDepthbuffer)
    //    {
    //        glDeleteRenderbuffers(1, &_msaaDepthbuffer);
    //        glGenRenderbuffers(1, &_msaaDepthbuffer);
    //        CHECK_GL_ERROR();
    //    }
    //    if (_msaaRenderbuffer)
    //    {
    //        glDeleteRenderbuffers(1, &_msaaRenderbuffer);
    //        glGenRenderbuffers(1, &_msaaRenderbuffer);
    //        CHECK_GL_ERROR();
    //    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _msaaRenderbuffer);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_RGBA8_OES, _width, _height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _msaaRenderbuffer);
    CHECK_GL_ERROR();
    //    glBindRenderbuffer(GL_RENDERBUFFER, _msaaDepthbuffer);
    //    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_DEPTH_COMPONENT16, _width, _height);
    //    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _msaaDepthbuffer);
    //    CHECK_GL_ERROR();
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
#endif
}

- (void) assignNextRenderSource:(id)nextRenderSource {
    @synchronized (self)
    {//NSLog(@"EAGLContext : assignNextRenderSource : %@", nextRenderSource);
        // NSLog(@"_readyToRenderNextFrame:NO");
        _readyToRenderNextFrame = NO;
        
        if ([_nextRenderSource isKindOfClass:KxVideoFrameCVBuffer.class])
        {
            KxVideoFrameCVBuffer* cvbFrame = (KxVideoFrameCVBuffer*) _nextRenderSource;
            //NSLog(@"cvbFrame->timestamp %f",cvbFrame.timestamp);
            [cvbFrame releasePixelBuffer];
        }
        else if ([_nextRenderSource isKindOfClass:KxVideoFrameRGB.class])
        {
            KxVideoFrameRGB* rgbFrame = (KxVideoFrameRGB*) _nextRenderSource;
            rgbFrame.rgb = nil;
        }
        _nextRenderSource = nil;
        _nextRenderSource = nextRenderSource;
        
        if ([_nextRenderSource isKindOfClass:KxVideoFrame.class])
        {
            KxVideoFrame* videoFrame = (KxVideoFrame*) _nextRenderSource;
            //NSLog(@"#FrameLoss#3 assignNextRenderSource videoFrame->timestamp=%f", videoFrame.timestamp);
            _inputVideoFrameTimeStamp = videoFrame.timestamp;
            _inputVideoFrameNumber = (int)videoFrame.frameNumber;
        }
        else
        {
            NSLog(@"_inputVideoFrameTimeStamp -1");
            _inputVideoFrameTimeStamp = -1.f;
            _inputVideoFrameNumber = -1;
        }
        //NSLog(@"#VideoEncoding#: assignNextRenderSource : _inputVideoFrameTimeStamp = %d", (int)_inputVideoFrameTimeStamp);
        
        if (!_previewRenderSource && [_nextRenderSource isKindOfClass:UIImage.class])
        {
            _previewRenderSource = _nextRenderSource;
        }
    }
}

- (id) readRenderSource {
    id ret = nil;
    @synchronized (self)
    {
        if (_previewRenderSource && !_hasPreviewShown)
        {
            _hasPreviewShown = YES;
            ret = _previewRenderSource;
            _previewRenderSource = nil;
        }
        else
        {
            ret = _nextRenderSource;
            _nextRenderSource = nil;
        }
    }
    return ret;
}

- (void) draw:(UIImage*)image withLUTStitching:(BOOL)withLUTStitching gyroMatrix:(NSData*)gyroMatrix videoCaptureResolution:(VideoCaptureResolution)videoCaptureResolution {
    _withLUTStitching = withLUTStitching;
    self.videoCaptureResolution4Thumbnail = videoCaptureResolution;
    self.illusionVideoCaptureResolution4Thumbnail = videoCaptureResolution;
    [self assignNextRenderSource:image];
    if (gyroMatrix && gyroMatrix.length > 0 && NULL != gyroMatrix.bytes)
    {
        [self setGyroMatrix:(float*)gyroMatrix.bytes rank:3];
    }
    NSLog(@"#MVGLView# draw:image");
}

- (void) drawJPEG:(NSString*)filePath {
    MadvEXIFExtension madvExt = readMadvEXIFExtensionFromJPEG(filePath.UTF8String);
    [self setGyroMatrix:madvExt.cameraParams.gyroMatrix rank:(madvExt.gyroMatrixBytes > 0 ? 3 : 0)];
    NSLog(@"#MVGLView# drawJPEG");
    _lutPath = [MVPanoRenderer lutPathOfSourceURI:filePath forceLUTStitching:NO pMadvEXIFExtension:&madvExt];
    _withLUTStitching = (nil != _lutPath);
    
    [self assignNextRenderSource:filePath];
}

- (void) render: (KxVideoFrame *) frame
{
    //NSLog(@"#FrameLoss#2 : Begin rendering video frame : %f", frame.timestamp);
    _withLUTStitching = YES;
    [self assignNextRenderSource:frame];
}

- (void) setGyroMatrix:(float*)matrix rank:(int)rank {
    int length = rank * rank;
    memcpy(_gyroMatrix, matrix, sizeof(float) * length);
    _gyroMatrixRank = rank;
    [_renderCond lock];
    if (self.isRendererReady)
    {
        //printf("\n#Gyro#     setGyroMatrix:                                                     {%0.3f, %0.3f, %0.3f, %0.3f, %0.3f, %0.3f, %0.3f, %0.3f, %0.3f}\n", _gyroMatrix[0], _gyroMatrix[1], _gyroMatrix[2], _gyroMatrix[3], _gyroMatrix[4], _gyroMatrix[5], _gyroMatrix[6], _gyroMatrix[7], _gyroMatrix[8]);
        [_renderer setGyroMatrix:matrix rank:rank];
    }
    [_renderCond unlock];
}

- (void) setModelPostRotationFrom:(kmVec3)fromVector to:(kmVec3)toVector {
    [_renderCond lock];
    if (self.isRendererReady)
    {
        [_renderer setModelPostRotationFrom:fromVector to:toVector];
    }
    [_renderCond unlock];
}

- (void) drawStichedImageWithLeftImage:(UIImage*)leftImage rightImage:(UIImage*)rightImage {
    NSArray* images = @[leftImage, rightImage];
    [EAGLContext setCurrentContext:_eaglContext];
    [_renderer setRenderSource:(__bridge_retained void*)images];
}

- (void) renderImmediately: (KxVideoFrame *) frame
{
    [EAGLContext setCurrentContext:_eaglContext];
    [self resizeVideoRecorder:CGSizeMake(frame.width, frame.height)];
    
    [_renderer setRenderSource:(__bridge_retained void*)frame];
    [self draw];
}

- (void) draw {
    if (!_eaglContext) return;
    [EAGLContext setCurrentContext:_eaglContext];
    glEnable(GL_BLEND);
    CHECK_GL_ERROR();
#ifdef USE_MSAA
    glBindFramebuffer(GL_FRAMEBUFFER, _msaaFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _msaaRenderbuffer);
    CHECK_GL_ERROR();
#else
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
#endif
    //    glClearColor((rand() % 256)/255.f, (rand() % 256)/255.f, (rand() % 256)/255.f, 1);///!!!
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    CHECK_GL_ERROR();
    GLint currentSourceTextureL = _renderer.leftSourceTexture;
    GLint currentSourceTextureR = _renderer.rightSourceTexture;
    GLenum currentSourceTextureTarget = _renderer.sourceTextureTarget;
    int currentFilterID = self.filterID;
    int currentPanoramaMode = self.panoramaMode;
    float displayWidth = _width;
    float displayHeight = _height;
    float inputWidth = _inputWidth;
    float inputHeight = _inputHeight;
    BOOL currentIsGlassMode = self.isGlassMode;
    BOOL isInCapturing = self.inCapturing;
    //NSLog(@"#3840x1920# MVGLView$draw : currentPanoramaMode=%d, _withLUTStitching=%d, _lutPath='%@'", currentPanoramaMode, _withLUTStitching, _lutPath);
    int currentLUTStitchingMode = 0;
    BOOL withLUTStithing = (_withLUTStitching && _lutPath);
    if (withLUTStithing)
    {
        currentLUTStitchingMode = PanoramaDisplayModeLUTInMesh;
    }
    
    int currentRenderMode = currentLUTStitchingMode | currentPanoramaMode;
#ifdef DEBUG_CUBEMAP
    float boundWidth = displayWidth, boundHeight = displayHeight;
    if (displayWidth * 0.75 > displayHeight)
    {
        boundWidth = displayHeight * 4.0 / 3.0;
    }
    else
    {
        boundHeight = displayWidth * 0.75;
    }
    float gridWidth = roundf(boundWidth / 4.f);
    float gridHeight = roundf(boundHeight / 3.f);
    
    int offsetX = roundf((displayWidth - boundWidth) / 2.f);
    int offsetY = roundf((displayHeight - boundHeight) / 2.f);
    [_renderer drawCubeMapFace:GL_TEXTURE_CUBE_MAP_NEGATIVE_X x:offsetX y:offsetY+gridHeight width:gridWidth height:gridHeight];
    [_renderer drawCubeMapFace:GL_TEXTURE_CUBE_MAP_NEGATIVE_Z x:offsetX+gridWidth y:offsetY+gridHeight width:gridWidth height:gridHeight];
    [_renderer drawCubeMapFace:GL_TEXTURE_CUBE_MAP_POSITIVE_X x:offsetX+gridWidth*2.f y:offsetY+gridHeight width:gridWidth height:gridHeight];
    [_renderer drawCubeMapFace:GL_TEXTURE_CUBE_MAP_POSITIVE_Z x:offsetX+gridWidth*3.f y:offsetY+gridHeight width:gridWidth height:gridHeight];
    [_renderer drawCubeMapFace:GL_TEXTURE_CUBE_MAP_POSITIVE_Y x:offsetX+gridWidth y:offsetY+gridHeight*2.f width:gridWidth height:gridHeight];
    [_renderer drawCubeMapFace:GL_TEXTURE_CUBE_MAP_NEGATIVE_Y x:offsetX+gridWidth y:offsetY width:gridWidth height:gridHeight];
    
#else //#ifdef DEBUG_CUBEMAP
    NSString* currentSnapshotDestPath = _snapshotDestPath;
    
    [self adustAndSetFOV];
#ifdef USE_FACEPP
    const int FaceppDetectFramePeriod = 1;
    if (0 == _prevFaceppDetectFrameNumber)
    {
        const int FaceppCubemapFaceSize = 256;
        if (NULL == _faceppCubempaFacePixelDatas)
        {
            _faceppCubempaFacePixelDatas = (GLubyte*)malloc(FaceppCubemapFaceSize * FaceppCubemapFaceSize * 4 * 6);
        }
        _faceppCubemapTexture = [_renderer drawCubemapToBuffers:_faceppCubempaFacePixelDatas PBOs:_faceppCubemapFacePBOs cubemapFaceTexture:_faceppCubemapTexture cubemapFaceSize:FaceppCubemapFaceSize];
        /*
         [[FaceppManager sharedInstance] testImageDetect:0];
         /*/
        for (int iFace=0; iFace<6; ++iFace)
        {
            //*
            CMSampleBufferRef sampleBuffer = createCMSampleBuffer(FaceppCubemapFaceSize, FaceppCubemapFaceSize, _faceppCubempaFacePixelDatas + (FaceppCubemapFaceSize * FaceppCubemapFaceSize * 4) * iFace);
            [[FaceppManager sharedInstance] detectFaceInSampleBuffer:sampleBuffer];
            CFRelease(sampleBuffer);
            /*/
             CGDataProviderRef cgProvider = CGDataProviderCreateWithData(NULL, _faceppCubempaFacePixelDatas + (FaceppCubemapFaceSize * FaceppCubemapFaceSize * 4) * iFace, FaceppCubemapFaceSize * FaceppCubemapFaceSize * 4, NULL);
             CGColorSpaceRef cgColorSpace = CGColorSpaceCreateDeviceRGB();
             CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
             CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
             CGImageRef cgImage = CGImageCreate(FaceppCubemapFaceSize, FaceppCubemapFaceSize, 8, 32, 4 * FaceppCubemapFaceSize, cgColorSpace, bitmapInfo, cgProvider, NULL, false, renderingIntent);
             UIImage* cubemapFaceImage = [UIImage imageWithCGImage:cgImage];
             [[FaceppManager sharedInstance] detectFaceInUIImage:cubemapFaceImage];
             CGImageRelease(cgImage);
             CGDataProviderRelease(cgProvider);
             CGColorSpaceRelease(cgColorSpace);
             //*/
        }
        //*/
    }
    _prevFaceppDetectFrameNumber = (_prevFaceppDetectFrameNumber + 1) % FaceppDetectFramePeriod;
#endif
    if (_recording && NULL != _recorderRenderTexture)
    {
        int cubemapFaceSize = roundf(inputHeight * 0.57735);
        if (withLUTStithing)
        {
            [_renderer setDisplayMode:PanoramaDisplayModeLUTInMesh];
        }
        else
        {
            [_renderer setDisplayMode:0];///PanoramaDisplayModeReFlatten];
        }
        [_renderer setEnableDebug:NO];
        [_renderer setFlipY:YES];
        
        glViewport(0, 0, _outputVideoSize.width, _outputVideoSize.height);
        
        if (currentFilterID > 0)
        {
            if (NULL == _renderTexture0)
            {
                _renderTexture0 = new GLRenderTexture(_recorderRenderTexture->getWidth(), _recorderRenderTexture->getHeight());
            }
            else
            {
                _renderTexture0->resizeIfNecessary(_recorderRenderTexture->getWidth(), _recorderRenderTexture->getHeight());
            }
        }
        
        if (withLUTStithing)
        {
            if (currentFilterID > 0)
            {
                _renderTexture0->blit();
                glClear(GL_COLOR_BUFFER_BIT);
                [_renderer drawRemappedPanoramaWithRect:CGRectMake(0, 0, _renderTexture0->getWidth(), _renderTexture0->getHeight()) cubemapFaceSize:cubemapFaceSize];// Stitch & Rotate
                _renderTexture0->unblit();
                _recorderRenderTexture->blit();
                _filterCache->render(currentFilterID, 0, 0, _recorderRenderTexture->getWidth(), _recorderRenderTexture->getHeight(), _renderTexture0->getTexture(), _renderTexture0->getTextureTarget(), OrientationNormal, Vec2f{0.f, 0.f}, Vec2f {1.f, 1.f});//Filter
                _recorderRenderTexture->unblit();
            }
            else
            {
                _recorderRenderTexture->blit();
                [_renderer drawRemappedPanoramaWithRect:CGRectMake(0, 0, _recorderRenderTexture->getWidth(), _recorderRenderTexture->getHeight()) cubemapFaceSize:cubemapFaceSize];// Stitch & Rotate
                _recorderRenderTexture->unblit();
            }
        }
        else if (currentFilterID > 0)
        {
            _renderTexture0->blit();
            glClear(GL_COLOR_BUFFER_BIT);
            [_renderer drawRemappedPanoramaWithRect:CGRectMake(0, 0, _renderTexture0->getWidth(), _renderTexture0->getHeight()) cubemapFaceSize:cubemapFaceSize];// Rotate
            _renderTexture0->unblit();
            
            _recorderRenderTexture->blit();
            _filterCache->render(currentFilterID, 0, 0, _recorderRenderTexture->getWidth(), _recorderRenderTexture->getHeight(), _renderTexture0->getTexture(), _renderTexture0->getTextureTarget(), OrientationNormal, Vec2f{0.f, 0.f}, Vec2f {1.f, 1.f});//Filter
            _recorderRenderTexture->unblit();
        }
        else
        {
            _recorderRenderTexture->blit();
            [_renderer drawRemappedPanoramaWithRect:CGRectMake(0, 0, _recorderRenderTexture->getWidth(), _recorderRenderTexture->getHeight()) cubemapFaceSize:cubemapFaceSize];// Rotate
            _recorderRenderTexture->unblit();
        }
        
        [_videoRecorder startRecording:FPS];
        //        if (_startTimeMills <= 0)
        //        {
        //            _startTimeMills = getCurrentTimeMills();
        //        }
        //        int timelapse = (int)(getCurrentTimeMills() - _startTimeMills);
        //        [_videoRecorder recordOneFrame:(_currentFrameTimestamp >= 0 ? (int)_currentFrameTimestamp : timelapse)];
        //glFlush();
        glFinish();
        if (_inputVideoFrameTimeStamp >= 0.f)
        {
            [_videoRecorder recordOneFrame:_inputVideoFrameTimeStamp];
        }
        
        //NSLog(@"VideoEncoding: recordOneFrame:%d", (int)_currentFrameTimestamp);
        
        //        _renderer->setFlipY(false);
        //        _renderer->setDisplayMode(currentRenderMode & (~PanoramaDisplayModeLUT));
//        _renderer->setDisplayMode(currentPanoramaMode);
//        _renderer->setSourceTextures(NO, _recorderRenderTexture->getTexture(), _recorderRenderTexture->getTexture(), _recorderRenderTexture->getTextureTarget(), NO);///!!!
//        if (self.isGlassMode)
//        {
//            _renderer->draw(0,0, _width/2,_height);
//            _renderer->draw(_width/2,0, _width/2,_height);
//        }
//        else
//        {
//            _renderer->draw(0,0, _width,_height);
//        }
//        //        _renderer->setFlipY(false);
//        _renderer->setSourceTextures(NO, currentSourceTextureL, currentSourceTextureR, currentSourceTextureTarget, NO);///!!!
    }
    else
    {
        float outputWidth, outputHeight;
        
        // Take snapshot if necessary:
        AutoRef<GLRenderTexture> snapshotRenderTexture = NULL;
        if (currentSnapshotDestPath)
        {
            switch (currentPanoramaMode & PanoramaDisplayModeExclusiveMask)
            {
                case PanoramaDisplayModePlain:
                case PanoramaDisplayModeFromCubeMap:
                    outputWidth = inputWidth;
                    outputHeight = inputHeight;
                    break;
                default:
                {
                    outputWidth = roundf((float)inputHeight * displayWidth / displayHeight);
                    if (outputWidth >= inputWidth)
                    {
                        outputHeight = inputHeight;
                    }
                    else
                    {
                        outputWidth = inputWidth;
                        outputHeight = roundf((float)inputWidth * displayHeight / displayWidth);
                    }
                }
                    break;
            }
            GLint maxTextureSize = 0;
            glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
            if (maxTextureSize > 0)
            {
                if (outputWidth > maxTextureSize)
                {
                    outputHeight = roundf((float)maxTextureSize * (float)outputHeight / (float)outputWidth);
                    outputWidth = maxTextureSize;
                }
                if (outputHeight > maxTextureSize)
                {
                    outputWidth = roundf((float)maxTextureSize * (float)outputWidth / (float)outputHeight);
                    outputHeight = maxTextureSize;
                }
            }
            snapshotRenderTexture = new GLRenderTexture(outputWidth, outputHeight);
        }
        else if (_capturing && isInCapturing)
        {
            outputWidth = _outputVideoSize.width;
            outputHeight = _outputVideoSize.height;
        }
        else
        {
            outputWidth = displayWidth;
            outputHeight = displayHeight;
        }
        int outBoundWidth = outputWidth;
        int outBoundHeight = outputHeight;
        
        if (currentIsGlassMode)
        {
            if (outputWidth > outputHeight)
            {
                outBoundWidth /= 2;
            }
            else
            {
                outBoundHeight /= 2;
            }
        }
        int destRectWidth = outBoundWidth;
        int destRectHeight = outBoundHeight;
        if (PanoramaDisplayModePlain == currentPanoramaMode || PanoramaDisplayModeFromCubeMap == currentPanoramaMode) /// || PanoramaDisplayModeReFlatten == currentPanoramaMode || PanoramaDisplayModeReFlattenInPixel == currentPanoramaMode)
        {
            if (inputWidth <= 0 || inputHeight <= 0)
            {
                inputWidth = outputWidth;
                inputHeight = outputHeight;
            }
            if (destRectHeight * inputWidth / inputHeight > destRectWidth)
            {
                destRectHeight = destRectWidth * inputHeight / inputWidth;
            }
            else if (destRectWidth * inputHeight / inputWidth > destRectHeight)
            {
                destRectWidth = destRectHeight * inputWidth / inputHeight;
            }
        }
        //#ifdef DEBUGGING_FILTERS
        //        if (true || currentIsGlassMode)
        //        {
        //#else
        if (0 != currentFilterID || currentIsGlassMode)
        {
            //#endif
            if (NULL == _renderTexture0)
            {
                _renderTexture0 = new GLRenderTexture(outBoundWidth * RenderTextureScale, outBoundHeight * RenderTextureScale);
                //                _renderTexture0 = new GLRenderTexture(_outputVideoSize.width, _outputVideoSize.height);
            }
            else
            {
                _renderTexture0->resizeIfNecessary(outBoundWidth * RenderTextureScale, outBoundHeight * RenderTextureScale);
            }
            CHECK_GL_ERROR();
            //#ifdef DEBUGGING_FILTERS
            //                if (true && currentIsGlassMode)
            //#else
            if (0 != currentFilterID && currentIsGlassMode)
            //#endif
            {
                if (NULL == _renderTexture1)
                {
                    _renderTexture1 = new GLRenderTexture(outBoundWidth * RenderTextureScale, outBoundHeight * RenderTextureScale);
                }
                else
                {
                    _renderTexture1->resizeIfNecessary(outBoundWidth * RenderTextureScale, outBoundHeight * RenderTextureScale);
                }
            }
            CHECK_GL_ERROR();
        }
        
        Orientation2D renderOrientation = OrientationNormal;
        if (currentSnapshotDestPath)
        {
            snapshotRenderTexture->blit();
        }
        else if (_capturing && NULL != _recorderRenderTexture && isInCapturing)
        {
            _recorderRenderTexture->blit();
            renderOrientation = OrientationRotate180DegreeMirror;
        }
        
        glViewport(0, 0, outputWidth, outputHeight);
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        //        glClearColor((rand() % 256)/255.f, (rand() % 256)/255.f, (rand() % 256)/255.f, 1);///!!!
        glClear(GL_COLOR_BUFFER_BIT);
        CHECK_GL_ERROR();
        //            NSLog(@"MVGLView draw : (0, 0, %d, %d)", outputWidth, outputHeight);
        //#ifdef DEBUGGING_FILTERS
        //            if (true)
        //#else
        if (0 != currentFilterID)
        //#endif
        {
            if (currentIsGlassMode)
            {
                _renderTexture0->blit();
                glClear(GL_COLOR_BUFFER_BIT);
                if (PanoramaDisplayModeFromCubeMap == currentPanoramaMode)
                {
                    int cubemapFaceSize = roundf(destRectHeight * 0.57735);
                    [_renderer drawRemappedPanoramaWithRect:CGRectMake(0, 0, _renderTexture0->getWidth(), _renderTexture0->getHeight()) cubemapFaceSize:cubemapFaceSize];
                }
                else
                {
                    [_renderer drawWithDisplayMode:currentRenderMode x:0 y:0 width:_renderTexture0->getWidth() height:_renderTexture0->getHeight() /*separateSourceTextures:NO */srcTextureType:currentSourceTextureTarget leftSrcTexture:currentSourceTextureL rightSrcTexture:currentSourceTextureR];
                }
                _renderTexture0->unblit();
                
                _renderTexture1->blit();
                _filterCache->render(currentFilterID, 0, 0, _renderTexture1->getWidth(), _renderTexture1->getHeight(), _renderTexture0->getTexture(), GL_TEXTURE_2D, OrientationNormal, Vec2f{0.f, 0.f}, Vec2f{1.0f, 1.0f});
                _renderTexture1->unblit();
                
                if (outputWidth > outputHeight)
                {
                    _filterCache->render(0, (outBoundWidth - destRectWidth) / 2, (outBoundHeight - destRectHeight) / 2, destRectWidth, destRectHeight, _renderTexture1->getTexture(), GL_TEXTURE_2D, renderOrientation, Vec2f{0.f, 0.f}, Vec2f{1.0f, 1.0f});
                    _filterCache->render(0, outBoundWidth + (outBoundWidth - destRectWidth) / 2, (outBoundHeight - destRectHeight) / 2, destRectWidth, destRectHeight, _renderTexture1->getTexture(), GL_TEXTURE_2D, renderOrientation, Vec2f{0.f, 0.f}, Vec2f{1.0f, 1.0f});
                }
                else
                {
                    _filterCache->render(0, (outBoundWidth - destRectWidth) / 2, (outBoundHeight - destRectHeight) / 2, destRectWidth, destRectHeight, _renderTexture1->getTexture(), GL_TEXTURE_2D, renderOrientation, Vec2f{0.f, 0.f}, Vec2f{1.0f, 1.0f});
                    _filterCache->render(0, (outBoundWidth - destRectWidth) / 2, outBoundHeight + (outBoundHeight - destRectHeight) / 2, destRectWidth, destRectHeight, _renderTexture1->getTexture(), GL_TEXTURE_2D, renderOrientation, Vec2f{0.f, 0.f}, Vec2f{1.0f, 1.0f});
                }
            }
            else
            {
                _renderTexture0->blit();
                glClear(GL_COLOR_BUFFER_BIT);
                if (PanoramaDisplayModeFromCubeMap == currentPanoramaMode)
                {
                    int cubemapFaceSize = roundf(destRectHeight * 0.57735);
                    [_renderer drawRemappedPanoramaWithRect:CGRectMake(0, 0, _renderTexture0->getWidth(), _renderTexture0->getHeight()) cubemapFaceSize:cubemapFaceSize];
                }
                else
                {
                    [_renderer drawWithDisplayMode:currentRenderMode x:0 y:0 width:_renderTexture0->getWidth() height:_renderTexture0->getHeight() /*separateSourceTextures:NO */srcTextureType:currentSourceTextureTarget leftSrcTexture:currentSourceTextureL rightSrcTexture:currentSourceTextureR];
                }
                _renderTexture0->unblit();
                
                _filterCache->render(currentFilterID, (outBoundWidth - destRectWidth) / 2, (outBoundHeight - destRectHeight) / 2, destRectWidth, destRectHeight, _renderTexture0->getTexture(), GL_TEXTURE_2D, renderOrientation, Vec2f{0.f, 0.f}, Vec2f{1.0f, 1.0f});
            }
        }
        else if (currentIsGlassMode)
        {
            _renderTexture0->blit();
            glClear(GL_COLOR_BUFFER_BIT);
            if (PanoramaDisplayModeFromCubeMap == currentPanoramaMode)
            {
                int cubemapFaceSize = roundf(destRectHeight * 0.57735);
                [_renderer drawRemappedPanoramaWithRect:CGRectMake(0, 0, _renderTexture0->getWidth(), _renderTexture0->getHeight()) cubemapFaceSize:cubemapFaceSize];
            }
            else
            {
                [_renderer drawWithDisplayMode:currentRenderMode x:0 y:0 width:_renderTexture0->getWidth() height:_renderTexture0->getHeight() /*separateSourceTextures:NO */srcTextureType:currentSourceTextureTarget leftSrcTexture:currentSourceTextureL rightSrcTexture:currentSourceTextureR];
            }
            _renderTexture0->unblit();
            
            if (outputWidth > outputHeight)
            {
                _filterCache->render(0, (outBoundWidth - destRectWidth) / 2, (outBoundHeight - destRectHeight) / 2, destRectWidth, destRectHeight, _renderTexture0->getTexture(), GL_TEXTURE_2D, renderOrientation, Vec2f{0.f, 0.f}, Vec2f{1.0f, 1.0f});
                _filterCache->render(0, outBoundWidth + (outBoundWidth - destRectWidth) / 2, (outBoundHeight - destRectHeight) / 2, destRectWidth, destRectHeight, _renderTexture0->getTexture(), GL_TEXTURE_2D, renderOrientation, Vec2f{0.f, 0.f}, Vec2f{1.0f, 1.0f});
            }
            else
            {
                _filterCache->render(0, (outBoundWidth - destRectWidth) / 2, (outBoundHeight - destRectHeight) / 2, destRectWidth, destRectHeight, _renderTexture0->getTexture(), GL_TEXTURE_2D, renderOrientation, Vec2f{0.f, 0.f}, Vec2f{1.0f, 1.0f});
                _filterCache->render(0, (outBoundWidth - destRectWidth) / 2, outBoundHeight + (outBoundHeight - destRectHeight) / 2, destRectWidth, destRectHeight, _renderTexture0->getTexture(), GL_TEXTURE_2D, renderOrientation, Vec2f{0.f, 0.f}, Vec2f{1.0f, 1.0f});
            }
        }
        else
        {
            if (OrientationRotate180DegreeMirror == renderOrientation)
            {
                [_renderer setFlipY:YES];
            }
            
            if (PanoramaDisplayModeFromCubeMap == currentPanoramaMode)
            {
                int cubemapFaceSize = roundf(destRectHeight * 0.57735);
                [_renderer drawRemappedPanoramaWithRect:CGRectMake((outBoundWidth - destRectWidth) / 2, (outBoundHeight - destRectHeight) / 2, destRectWidth, destRectHeight) cubemapFaceSize:cubemapFaceSize];
            }
            else
            {
                [_renderer drawWithDisplayMode:currentRenderMode x:((outBoundWidth - destRectWidth) / 2) y:((outBoundHeight - destRectHeight) / 2) width:destRectWidth height:destRectHeight /*separateSourceTextures:NO */srcTextureType:currentSourceTextureTarget leftSrcTexture:currentSourceTextureL rightSrcTexture:currentSourceTextureR];
            }
            
            if (OrientationRotate180DegreeMirror == renderOrientation)
            {
                [_renderer setFlipY:NO];
            }
        }
        
        if (_capturing && self.enableWatermark2D && _recorderLogoTexture > 0)
        {
            //NSLog(@"#Logo# _capturing=%d, _recorderLogoTexture=%d, _outputVideoSize.height=%f, outputHeight=%f", _capturing, _recorderLogoTexture, _outputVideoSize.height, outputHeight);
            float logoContainerWidth, logoContainerHeight;
            if (isInCapturing)
            {
                logoContainerWidth = _outputVideoSize.width;
                logoContainerHeight = _outputVideoSize.height;
            }
            else
            {
                logoContainerWidth = outputWidth;
                logoContainerHeight = outputHeight;
            }
            
            int logoX, logoY, logoW, logoH;
            if (logoContainerHeight > logoContainerWidth)
            {
                logoX = logoContainerWidth * LOGO_REFERENCE_LEFTMARGIN_LANDSCAPE / LOGO_CONTAINER_REFERENCE_WIDTH_LANDSCAPE;
                logoY = logoContainerHeight * LOGO_REFERENCE_BOTTOMMARGIN_LANDSCAPE / LOGO_CONTAINER_REFERENCE_HEIGHT_LANDSCAPE;
                logoH = LOGO_REFERENCE_HEIGHT_LANDSCAPE * logoContainerHeight / LOGO_CONTAINER_REFERENCE_HEIGHT_LANDSCAPE;
            }
            else
            {
                logoX = logoContainerWidth * LOGO_REFERENCE_LEFTMARGIN / LOGO_CONTAINER_REFERENCE_WIDTH;
                logoY = logoContainerHeight * LOGO_REFERENCE_BOTTOMMARGIN / LOGO_CONTAINER_REFERENCE_HEIGHT;
                logoH = LOGO_REFERENCE_HEIGHT * logoContainerHeight / LOGO_CONTAINER_REFERENCE_HEIGHT;
            }
            logoW = logoH * _recorderLogoAspect;
            
            if (isInCapturing)
            {
                logoY = logoContainerHeight - logoY - logoH;
                _filterCache->render(0, logoX, logoY, logoW, logoH, _recorderLogoTexture, GL_TEXTURE_2D);
            }
            else
            {
                _filterCache->render(0, logoX, logoY, logoW, logoH, _recorderLogoTexture, GL_TEXTURE_2D, OrientationRotate180DegreeMirror, Vec2f{0.f,0.f}, Vec2f{1.f,1.f});
            }
        }
        
        if (currentSnapshotDestPath)
        {
            int blockLines = MaxBufferBytes / 4 / outputWidth;
            if (blockLines > outputHeight)
            {
                blockLines = outputHeight;
            }
            
            JPEGCompressOutput* imageOutput = startWritingImageToJPEG(currentSnapshotDestPath.UTF8String, GL_RGBA, GL_UNSIGNED_BYTE, 100, outputWidth, outputHeight);
            GLubyte* pixelData = (GLubyte*) malloc(4 * outputWidth * blockLines);
            
            bool finishedAppending = false;
            for (int iLine = outputHeight-blockLines; iLine >= 0; iLine -= blockLines)
            {
                glReadPixels(0, iLine, outputWidth, blockLines, GL_RGBA, GL_UNSIGNED_BYTE, pixelData);
                glFinish();
                if (!appendImageStrideToJPEG(imageOutput, pixelData, blockLines, true))
                {
                    finishedAppending = true;
                    break;
                }
                if (iLine < blockLines && iLine > 0)
                {
                    blockLines = iLine;
                }
            }
            
            if (!finishedAppending)
            {
                delete imageOutput;
            }
            free(pixelData);
            
            _snapshotDestPath = nil;
            currentSnapshotDestPath = nil;
            if (_snapshotCompletionHandler)
            {
                _snapshotCompletionHandler();
            }
            
            snapshotRenderTexture->unblit();
            glViewport(0, 0, displayWidth, displayHeight);
            _filterCache->render(0, 0,0,displayWidth,displayHeight, snapshotRenderTexture->getTexture(), snapshotRenderTexture->getTextureTarget(), renderOrientation, Vec2f{0.f, 0.f}, Vec2f{1.0f, 1.0f});
            snapshotRenderTexture = NULL;
        }
        else if (_capturing && NULL != _recorderRenderTexture && isInCapturing)
        {
            _recorderRenderTexture->unblit();
            
            [_videoRecorder startRecording:FPS];
            if (_currentFrameTimestamp >= 0)
            {
                long timeMills = _currentFrameTimestamp;
                if (_startTimeMills >= 0)
                {
                    timeMills += (getCurrentTimeMills() - _startTimeMills);
                }
                
                if (timeMills < 1000)
                {
                    glFlush();
                }
                //NSLog(@"#VideoCapture# recordOneFrame at time: %d, _currentFrameTimestamp=%ld, _startTimeMills=%ld, videoFrameTime = %d", (int)timeMills, _currentFrameTimestamp, _startTimeMills, (int)_inputVideoFrameTimeStamp);
                [_videoRecorder recordOneFrame:(float)timeMills];
                if (self.encodingFrameBlock)
                {
                    self.encodingFrameBlock((float)timeMills / 1000.f);
                }
            }
            
            glViewport(0, 0, displayWidth, displayHeight);
            _filterCache->render(0, 0,0,displayWidth,displayHeight, _recorderRenderTexture->getTexture(), _recorderRenderTexture->getTextureTarget(), renderOrientation, Vec2f{0.f, 0.f}, Vec2f{1.0f, 1.0f});
        }
    }
#endif //#ifdef DEBUG_CUBEMAP
    [_renderer setDisplayMode:currentRenderMode];
    //*/
#ifdef USE_MSAA
    CHECK_GL_ERROR();
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, _framebuffer);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, _msaaFramebuffer);
    CHECK_GL_ERROR();
    //    glResolveMultisampleFramebufferAPPLE();
    //    CHECK_GL_ERROR();
    //    GLenum attachments[] = {GL_DEPTH_ATTACHMENT};
    //    glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 1, attachments);
    glInvalidateFramebuffer(GL_READ_FRAMEBUFFER, 1, (GLenum[]){GL_DEPTH_ATTACHMENT});
    glBlitFramebuffer(0, 0, _width, _height, 0, 0, _width, _height, GL_COLOR_BUFFER_BIT, GL_LINEAR);
    glInvalidateFramebuffer(GL_READ_FRAMEBUFFER, 1, (GLenum[]){GL_COLOR_ATTACHMENT0});
    CHECK_GL_ERROR();
#endif
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    //Ref: https://developer.apple.com/library/content/documentation/3DDrawing/Conceptual/OpenGLES_ProgrammingGuide/ImplementingaMultitasking-awareOpenGLESApplication/ImplementingaMultitasking-awareOpenGLESApplication.html#//apple_ref/doc/uid/TP40008793-CH5-SW1
    [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
    CHECK_GL_ERROR();
}

void runAsynchronouslyOnGLQueue(void(^block)()) {
    /*
     #pragma clang diagnostic push
     #pragma clang diagnostic ignored "-Wdeprecated-declarations"
     if (dispatch_get_current_queue() == sharedOpenGLQueue())
     #pragma clang diagnostic pop
     {
     block();
     }
     else
     {
     dispatch_async(sharedOpenGLQueue(), block);
     }
     /*/
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == dispatch_get_main_queue())
#pragma clang diagnostic pop
    {
        block();
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), block);
    }
    //    block();
    //*/
}

- (void) requestRedraw {
}

- (void) takeSnapShot:(NSString*)destPath completion:(dispatch_block_t)completion {
    _snapshotDestPath = destPath;
    _snapshotCompletionHandler = completion;
}

@end

#pragma mark    MVGLView
@interface MVGLView () <GLRenderLoopDelegate>
{
    GLRenderLoop* _glRenderLoop;
}

@property (nonatomic, strong) GLRenderLoop* glRenderLoop;

@property (nonatomic, strong) CMMotionManager* motionManager;

@end

@implementation MVGLView

@synthesize interfaceOrientation;
@synthesize glRenderLoop = _glRenderLoop;

- (void) setEnableWatermark2D:(BOOL)enable {
    self.glRenderLoop.enableWatermark2D = enable;
}

- (int) panoramaMode {
    return self.glRenderLoop.panoramaMode;
}
- (void) setPanoramaMode:(int)panoramaMode {
    self.glRenderLoop.panoramaMode = panoramaMode;
}

- (int) filterID {
    return self.glRenderLoop.filterID;
}
- (void) setFilterID:(int)filterID {
    self.glRenderLoop.filterID = filterID;
}

- (BOOL) isGlassMode {
    return self.glRenderLoop.isGlassMode;
}
- (void) setIsGlassMode:(BOOL)isGlassMode {
    self.glRenderLoop.isGlassMode = isGlassMode;
}

- (BOOL) isYUVColorSpace {
    return self.glRenderLoop.isYUVColorSpace;
}
- (void) setIsYUVColorSpace:(BOOL)isYUVColorSpace {
    self.glRenderLoop.isYUVColorSpace = isYUVColorSpace;
}

+ (Class) layerClass {
    return CAEAGLLayer.class;
}

- (void) dealloc {
    DoctorLog(@"#GLRenderLoopState# : MVGLView dealloc %lx, glRenderLoop = %lx",  self.hash, self.glRenderLoop.hash);
}

- (void) glRenderLoopSetupGLRenderbuffer:(GLRenderLoop *)renderLoop {
    [[EAGLContext currentContext] renderbufferStorage:GL_RENDERBUFFER fromDrawable:((CAEAGLLayer*)self.layer)];
}

- (void) glRenderLoop:(GLRenderLoop *)renderLoop frameTimeTicked:(int)millseconds {
    
}

- (instancetype) initWithFrame:(CGRect)frame lutPath:(NSString*)lutPath lutSrcSizeL:(CGSize)lutSrcSizeL lutSrcSizeR:(CGSize)lutSrcSizeR outputVideoBaseName:(NSString*)outputVideoBaseName encoderQualityLevel:(MVQualityLevel)qualityLevel forCapturing:(BOOL)forCapturing {
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor clearColor];
        self.layer.backgroundColor = [UIColor clearColor].CGColor;
        
        self.interfaceOrientation = UIInterfaceOrientationPortrait;
        
        CAEAGLLayer* layer = (CAEAGLLayer*) self.layer;
        layer.opaque = YES;
        layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    //If use glReadPixels to get pixel data after presentRenderbuffer, RetainedBacking should be set to YES:
                                    [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        self.contentScaleFactor = [UIScreen mainScreen].scale;
        self.layer.contentsScale = [UIScreen mainScreen].scale;
        
        self.motionManager = nil;
        
        UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanRecognized:)];
        [self addGestureRecognizer:panRecognizer];
        
        UIPinchGestureRecognizer* pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinchRecognized:)];
        [self addGestureRecognizer:pinchRecognizer];
        
        UITapGestureRecognizer* doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTapRecognized:)];
        doubleTapRecognizer.numberOfTapsRequired = 2;
        doubleTapRecognizer.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:doubleTapRecognizer];
        
        self.glRenderLoop = [[GLRenderLoop alloc] initWithDelegate:self lutPath:lutPath lutSrcSizeL:lutSrcSizeL lutSrcSizeR:lutSrcSizeR inputFrameSize:CGSizeMake(frame.size.width * self.contentScaleFactor, frame.size.height * self.contentScaleFactor) outputVideoBaseName:outputVideoBaseName encoderQualityLevel:qualityLevel forCapturing:forCapturing];
    }
    return self;
}

//- (void) pause {
//    [self stopMotionManager];
//    [self.glRenderLoop pauseRendering];
//}

//- (void) resume {
//    [self.glRenderLoop resumeRendering];
//    [self startMotionManager];
//}

- (void) willDisappear {
    DoctorLog(@"#GLRenderLoopState# MVGLView $ willDisappear will call stopRendering @%lx MVGLView@%lx", (long)self.glRenderLoop.hash, (long)self.hash);
    ///!!![self stopMotionManager];
    [self.glRenderLoop stopRendering];
    ///!!![self removeFromSuperview];
    //self.glRenderLoop = nil;
    //[self.glRenderLoop stopEncoding:nil];
}

- (void) willAppear {
    DoctorLog(@"#GLRenderLoopState# MVGLView $ willAppear will call startRendering @%lx MVGLView@%lx", (long)self.glRenderLoop.hash, (long)self.hash);
//    [self.glRenderLoop stopOtherRenderLoopIfAny];
    ///[self.glRenderLoop startRendering];
    ///!!![self startMotionManager];
}

- (void) stopMotionManager {
    @synchronized (self)
    {
        if (!self.motionManager)
        {
            return;
        }
        [self.motionManager stopDeviceMotionUpdates];
        self.motionManager = nil;
        
        [self.glRenderLoop setIsGyroEnabled:NO];
    }
}

- (void) startMotionManager {
    @synchronized (self)
    {
        if (self.motionManager)
        {
            return;
        }
        self.motionManager = [[CMMotionManager alloc] init];
        if (self.motionManager.deviceMotionAvailable)
        {
            [self.motionManager stopDeviceMotionUpdates];
            //        self.motionManager.accelerometerUpdateInterval = .2;
            //        self.motionManager.gyroUpdateInterval = .2;
            self.motionManager.deviceMotionUpdateInterval = 1.f / 30.f;
            
            __weak __typeof(self) wSelf = self;
            UIInterfaceOrientation startOrientation = self.interfaceOrientation;
            [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
                __strong __typeof(self) pSelf = wSelf;
                if (!pSelf) return;
                
                CMAttitude* attitude = motion.attitude;
                [pSelf.glRenderLoop onGyroQuaternionChanged:attitude orientation:pSelf.interfaceOrientation startOrientation:startOrientation];
            }];
            
            [self.glRenderLoop setIsGyroEnabled:YES];
        }
    }
}
/*
- (void) willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview == nil)
    {
        NSLog(@"EAGLContext#BackgroundCrash# : MVGLView willMoveToSuperview (nil) @ %lx, glRenderLoop = %lx",  self.hash, self.glRenderLoop.hash);
        [self willDisappear];
    }
    else
    {
        NSLog(@"EAGLContext#BackgroundCrash# : MVGLView willMoveToSuperview @ %lx, glRenderLoop = %lx",  self.hash, self.glRenderLoop.hash);
    }
}

- (void) didMoveToSuperview {
    if (self.superview)
    {
        NSLog(@"EAGLContext#BackgroundCrash# : MVGLView didMoveToSuperview @ %lx, glRenderLoop = %lx",  self.hash, self.glRenderLoop.hash);
        [self willAppear];
    }
    else
    {
        NSLog(@"EAGLContext#BackgroundCrash# : MVGLView didMoveToSuperview (nil) @ %lx, glRenderLoop = %lx",  self.hash, self.glRenderLoop.hash);
    }
}
//*/
- (void)layoutSubviews {
    CHECK_GL_ERROR();
    [self.glRenderLoop invalidateRenderbuffer];
}

- (void) onPanRecognized : (UIPanGestureRecognizer*)panRecognizer {
    [self.glRenderLoop onPanRecognized:panRecognizer];
}

- (void) onPinchRecognized:(UIPinchGestureRecognizer*)pinchRecognizer {
    [self.glRenderLoop onPinchRecognized:pinchRecognizer];
}

- (void) onDoubleTapRecognized:(UITapGestureRecognizer*)tapRecognizer {
    [self.glRenderLoop onDoubleTapRecognized:tapRecognizer];
}

- (void) lookAt:(kmVec3)eularAngleDegrees {
    [self.glRenderLoop lookAt:eularAngleDegrees];
}

- (void) takeSnapShot:(NSString*)destPath completion:(dispatch_block_t)completion {
    [self.glRenderLoop takeSnapShot:destPath completion:completion];
}

@end

#endif //#ifdef TARGET_OS_IOS
