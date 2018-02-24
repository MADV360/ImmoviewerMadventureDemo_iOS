//
//  CycordVideoRecorder.mm
//  HelloOGLES2
//
//  Created by FutureBoy on 12/18/14.
//  Copyright (c) 2014 RedShore. All rights reserved.
//
#ifdef TARGET_OS_IOS

#include "CycordVideoRecorder.h"
//#import "CycordNetworkManager.h"
//#include "GLRPlatform.h"
//#include "GLRec.h"
//#include "GLRCore.h"
#ifdef MADVPANO_BY_SOURCE
#import "OpenGLHelper.h"
#else
#import <MADVPano/OpenGLHelper.h>
#endif

#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAudioSession.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <Metal/Metal.h>
#import <sys/time.h>
#import "avUtils.h"
//#import "mathext.h"

#define OPENGL_PIXEL_FORMAT kCVPixelFormatType_32BGRA
#define VIDEO_PIXEL_FORMAT kCVPixelFormatType_32BGRA

#ifdef DEBUG_VIDEORECORDER_INTERRUPTED_BY_ERROR
static bool s_isFirstTime = true;
#endif

long getCurrentTimeMills()
{
    //#if (GLR_PLATFORM_IOS || GLR_PLATFORM_MACOS)
    struct timeval tv;
    gettimeofday(&tv,NULL);
    return tv.tv_sec * 1000 + tv.tv_usec / 1000;
    //#endif
}

@interface CycordVideoRecorder ()
{
    CAEAGLLayer* _eaglLayer;
    CGSize _viewSize;
    
    BOOL _takeSnapshotNextFrame;
    
    BOOL _isRecording;
    BOOL _isShareMode;
    
    int _recordedFrames;
    long _recordingStartTime;
    float _fps;
    
    id<CycordVideoRecorderDelegate> _delegate;
    
    long _renderingingStartTime;
    long _nextSnapshotTime;
    
    NSMutableDictionary* _snapshotDatas;
    
    BOOL _isViewSizeInvalid;

    // Size Dependent Members:
    AVAssetWriter* _videoWriter;
    AVAssetWriterInput* _videoWriterInput;
    AVAssetWriterInputPixelBufferAdaptor* _pixelBufferAdaptor;
    
    GLubyte* _pixelData;
    //    CGDataProviderRef _dataProvider;
    
    CVPixelBufferRef _pixelBuffer;
    
    CVOpenGLESTextureCacheRef _textureCache;
    CVOpenGLESTextureRef _renderTexture;
    // :Size Dependent Members
    
    GLint  _framebuffer;
    
    GLint _vertexArray;
    GLint _arrayBuffer;
    
    GLint _renderProgram;
    GLint _uniTexture;
    GLint _atrPosition;
    GLint _atrTextureCoord;
    
    //    AVAudioRecorder * _audioRecorder;
    
    NSString* _destVideoBaseName;
    
    CGFloat _lastWriteTimeStamp;
    CMTime _lastWriteCMTime;
}

- (void) startRecordingPrivate : (float)fps;

- (void) stopRecordingPrivate : (void(^)(NSError*, NSString*))handler;

- (BOOL) onRenderbufferStorage : (id)receiver
                           cmd : (SEL)cmd
                        target : (NSInteger)target
                      drawable : (id)drawable;

- (BOOL) onPresentRenderbuffer : (id)receiver
                           cmd : (SEL)cmd
                        target : (NSInteger)target;

//- (void) onCommandBufferComplete : (id<CAMetalDrawable>)metalDrawable;

- (void) setupVideoWriter : (CGSize)size;

//disable define property write by spy
#if 0
@property (retain, nonatomic) AVAssetWriter* videoWriter;
@property (retain, nonatomic) AVAssetWriterInput* videoWriterInput;
@property (retain, nonatomic) AVAssetWriterInputPixelBufferAdaptor* pixelBufferAdaptor;
#endif
@end

static CycordVideoRecorder* gSharedInstance = nil;

void FKC_hookOCClasses();
void FKC_restoreOCClasses();

typedef void (*ObjectiveCVoidMethod)(id, SEL, ...);
typedef id (*ObjectiveCIdMethod)(id, SEL, ...);

// If any function of IMP(=ObjectiveCIdMethod) type is to be hooked, ARC should be forbidden:
typedef id (*ObjectiveCIdMethod)(id, SEL, ...);

typedef BOOL (*RenderbufferStoragePrototype)(id, SEL, NSUInteger, id<EAGLDrawable>);
static RenderbufferStoragePrototype gSuperRenderBufferStorage = NULL;

typedef BOOL (*PresentRenderbufferPrototype)(id, SEL, NSUInteger);
static PresentRenderbufferPrototype gSuperPresentRenderBuffer = NULL;

typedef void (*PresentDrawablePrototype)(id, SEL, id<MTLDrawable>);
static PresentDrawablePrototype gSuperPresentDrawable = NULL;

typedef void (*PresentDrawableAtTimePrototype)(id, SEL, id <MTLDrawable>, CFTimeInterval);
static PresentDrawableAtTimePrototype gSuperPresentDrawableAtTime = NULL;

//typedef void (*AddCompletedHandlerPrototype)(id, SEL, MTLCommandBufferHandler);
//static AddCompletedHandlerPrototype gSuperAddCompletedHandler = NULL;

static bool g_isClassHooked = false;

BOOL FKC_RenderbufferStorage(id self, SEL _cmd, NSUInteger target, id drawable)
{
    //    NSLog(@"FKC_RenderbufferStorage $ self = %@, _cmd = %s, target = %ld, drawable = %@", self,_cmd,target,drawable);
    if (g_isClassHooked)
    return [[CycordVideoRecorder sharedInstance] onRenderbufferStorage:self cmd:_cmd target:target drawable:drawable];
    else
    return gSuperRenderBufferStorage(self, _cmd, target, drawable);
}

BOOL FKC_PresentRenderbuffer(id self, SEL _cmd, NSUInteger target)
{
    if (g_isClassHooked)
    return [[CycordVideoRecorder sharedInstance] onPresentRenderbuffer:self cmd:_cmd target:target];
    else
    return gSuperPresentRenderBuffer(self, _cmd, target);
}

//static id<CAMetalDrawable> gCurrentMetalDrawable = nil;

//void FKC_AddCompletedHandler(id self, SEL _cmd, MTLCommandBufferHandler handler) {
//    if (g_isClassHooked)
//        gSuperAddCompletedHandler(self, _cmd, handler);
//    else
//        gSuperAddCompletedHandler(self, _cmd, handler);
//}

void FKC_PresentDrawable(id self, SEL _cmd, id<MTLDrawable> drawable) {
    //    if (g_isClassHooked)
    //    {
    //        if ([drawable conformsToProtocol:@protocol(CAMetalDrawable)])
    //        {
    //            gCurrentMetalDrawable = (id<CAMetalDrawable>) drawable;
    //
    //            id <MTLCommandBuffer> commandBuffer = self;
    //            [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull) {
    //                [[CycordVideoRecorder sharedInstance] onCommandBufferComplete:gCurrentMetalDrawable];
    //
    //                gCurrentMetalDrawable = nil;
    //            }];
    //        }
    //        gSuperPresentDrawable(self, _cmd, drawable);
    //    }
    //    else
    //        gSuperPresentDrawable(self, _cmd, drawable);
}

void FKC_PresentDrawableAtTime(id self, SEL _cmd, id<MTLDrawable> drawable, CFTimeInterval time) {
    //    if (g_isClassHooked)
    //    {
    //        if ([drawable conformsToProtocol:@protocol(CAMetalDrawable)])
    //        {
    //            gCurrentMetalDrawable = (id<CAMetalDrawable>) drawable;
    //
    //            id <MTLCommandBuffer> commandBuffer = self;
    //            [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull) {
    //                [[CycordVideoRecorder sharedInstance] onCommandBufferComplete:gCurrentMetalDrawable];
    //
    //                gCurrentMetalDrawable = nil;
    //            }];
    //        }
    //        gSuperPresentDrawableAtTime(self, _cmd, drawable, time);
    //    }
    //    else
    //        gSuperPresentDrawableAtTime(self, _cmd, drawable, time);
}

@implementation CycordVideoRecorder

@synthesize delegate = _delegate;

@synthesize snapshotDatas = _snapshotDatas;

//disable define property write by spy
#if 0
@synthesize videoWriter = _videoWriter;
@synthesize videoWriterInput = _videoWriterInput;
@synthesize pixelBufferAdaptor = _pixelBufferAdaptor;
#endif
@synthesize renderTexture = _renderTexture;
@synthesize encodingError;

- (void) dealloc
{
    [_snapshotDatas removeAllObjects];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //    [self stopRecordingPrivate:nil];
    [self releaseOffscreenGLVariables];
    NSLog(@"CycordVideoRecorder dealloc");
}

- (instancetype) initWithOutputVideoBaseName:(NSString*)outputVideoBaseName {
    if (self = [super init])
    {
        _isRecording = NO;
        
        _isViewSizeInvalid = YES;
        
        _renderingingStartTime = -1;
        _nextSnapshotTime = -1;
        
        _snapshotDatas = [[NSMutableDictionary alloc] init];
        
        //        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUploadSuccess:) name:@kNotificationUploadSuccess object:nil];
        //        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUploadFailed:) name:@kNotificationUploadFailed object:nil];
        _destVideoBaseName = [NSString stringWithString:outputVideoBaseName];
        //[self refreshTmpName:outputVideoBaseName];
        //_baseVidName = [NSString stringWithString:outputVideoBaseName];
        _isShareMode = NO;
    }
    return self;
}

- (id) init
{
    return [self initWithOutputVideoBaseName:@"video.mov"];
}

- (void) onUploadSuccess : (NSNotification*)notification {
    //    NSDictionary* userInfo = notification.userInfo;
    //    NSNumber* snapshotTime = [userInfo objectForKey:@kKeySnapshotTime];
    //    if (snapshotTime)
    //    {
    //        [_snapshotDatas removeObjectForKey:snapshotTime];
    //        NSLog(@"Snapshot data of time %d removed. %d data(s) left.", [snapshotTime intValue], _snapshotDatas.count);
    //    }
}

- (void) onUploadFailed : (NSNotification*)notification {
}

//- (NSUInteger) retainCount {
//    return UINT_MAX;
//}

//+ (id) allocWithZone:(struct _NSZone *)zone {
//    if (!gSharedInstance)
//    {
//        gSharedInstance = [super allocWithZone:nil];
//    }
//    return gSharedInstance;
//}

//+ (id) copyWithZone:(struct _NSZone *)zone {
//    return nil;
//}

+ (id) initVideoRecorder {
    @synchronized (self)
    {
        if (nil == gSharedInstance)
        {
            gSharedInstance = [CycordVideoRecorder sharedInstance];
            [gSharedInstance initOffscreenGLVariables];
            [gSharedInstance releaseSizeDependentMembers];
            FKC_hookOCClasses();
        }
    }
    return gSharedInstance;
}

+ (void) releaseVideoRecorder {
    @synchronized (self)
    {
        if (gSharedInstance)
        {
            [gSharedInstance releaseSizeDependentMembers];
            [gSharedInstance releaseOffscreenGLVariables];
            gSharedInstance = nil;
            FKC_restoreOCClasses();
        }
    }
}

+ (CycordVideoRecorder*) sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        if (nil == gSharedInstance)
        {
            gSharedInstance = [[CycordVideoRecorder alloc] init];
        }
    });
    return gSharedInstance;
}

+ (void) startRecording
{
    [CycordVideoRecorder startRecording:30.0f];
}

+ (void) startRecording : (float)fps
{
    [[CycordVideoRecorder sharedInstance] startRecordingPrivate : fps];
}

- (void) startRecording
{
    [self startRecording:30.0f];
}

- (void) startRecording : (float)fps
{
    [self startRecordingPrivate : fps];
}

+ (void) stopRecording
{
    [[CycordVideoRecorder sharedInstance] stopRecordingPrivate:nil];
}

+ (void) stopRecordingWithCompletionHandler:(void (^)(NSError*, NSString*))handler {
    [[CycordVideoRecorder sharedInstance] stopRecordingPrivate:handler];
}

- (void) stopRecording
{
    [self stopRecordingPrivate:nil];
}

- (void) stopRecordingWithCompletionHandler:(void (^)(NSError*, NSString*))handler {
    [self stopRecordingPrivate:handler];
}

+ (void) startReplaying:(UIViewController*)parentVC
{
    NSString* fileOutputPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* filename = [fileOutputPath stringByAppendingPathComponent:@"video.mp4"];
    dispatch_async(dispatch_get_main_queue(), ^{
        MPMoviePlayerViewController* playerVC = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:filename]];
        [playerVC.moviePlayer prepareToPlay];
        [parentVC presentMoviePlayerViewControllerAnimated:playerVC];
        playerVC.moviePlayer.view.frame = parentVC.view.bounds;
        playerVC.moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
        [playerVC.moviePlayer play];
    });
}

- (void) startRecordingPrivate : (float)fps
{
    @synchronized(self)
    {
        if (_isRecording) return;
        _isRecording = YES;
    }
    
    _takeSnapshotNextFrame = NO;
    
    _recordedFrames = 0;
    _recordingStartTime = -1;
    _fps = (fps <= 0 ? 30.0f : fps);
    
    //    [self prepareToRecordAudio];
    //    [_audioRecorder record];
}

- (void) stopRecordingPrivate:(void(^)(NSError*, NSString*))handler
{
    @synchronized(self)
    {
        if (!_isRecording)
        {
            [self releaseSizeDependentMembers];
            return;
        }
        _isRecording = NO;
    }
    
    //    [_audioRecorder stop];
    //    _audioRecorder = nil;
    
    //    __weak __typeof(self) wSelf = self;
    
    //write by spy when stop writer call
    [_videoWriter endSessionAtSourceTime:_lastWriteCMTime];
    [_videoWriter finishWritingWithCompletionHandler:^() {
        //        //        NSError* error = nil;///!!!For Debug
        //        //        [[NSFileManager defaultManager] removeItemAtURL:_videoWriter.outputURL error:&error];
        //
        
        //
        //        CVOpenGLESTextureCacheFlush(_textureCache, 0);
        //        _textureCache = NULL;
        //
        //NSLog(@"VideoEncoding: _videoWriter.status = %d, .error = %@", (int)_videoWriter.status, _videoWriter.error);
        [self compileAudioAndVideoToMovie:handler];
        [self releaseSizeDependentMembers];
    }];
}

- (void) releaseSizeDependentMembers {
    //        NSError* error = nil;///!!!For Debug
    //        [[NSFileManager defaultManager] removeItemAtURL:_videoWriter.outputURL error:&error];
    
    _videoWriter = nil;
    _videoWriterInput = nil;
    _pixelBufferAdaptor = nil;
    
    NSLog(@"pixelBuffer release before");
    if (_pixelBuffer)
        CVPixelBufferRelease(_pixelBuffer);
    NSLog(@"pixelBuffer release after");
    _pixelBuffer = NULL;
    
    if (_textureCache) {
        CVOpenGLESTextureCacheFlush(_textureCache, 0);
        CFRelease(_textureCache);
    }
    _textureCache = NULL;
    
    if (_renderTexture) {
//        GLuint texture = CVOpenGLESTextureGetName(_renderTexture);
//        glDeleteTextures(1, &texture);///!!!
        CFRelease(_renderTexture);
    }
    _renderTexture = NULL;
    
    if (_pixelData)
        free(_pixelData);
    _pixelData = NULL;
    
    _lastWriteTimeStamp = -1.f;
    
    NSLog(@"releaseSizeDependentMembers");
}

- (void) createSizeDependentMembers : (CGSize)size {
    [self setupVideoWriter : size];
    
    // Set up our background texture and foreground framebuffer:
    NSLog(@"freePixelBuffer before");
    CVPixelBufferRelease(_pixelBuffer);
    NSLog(@"freePixelBuffer after");
    
    NSLog(@"createPixelBuffer before");
    _pixelBuffer = [self createPixelBuffer:size];///!!! For Retina???
    NSLog(@"createPixelBuffer after");
    
    //    APPLY_LOGBIT(LOG_RESIZE_GLVIEW) {NSLog(@"CycordVideoRecorder$createSizeDependentMembers: size = (%d,%d)", (int)size.width, (int)size.height);}
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [EAGLContext currentContext], NULL, &_textureCache );
    
    // create a texture from our renderTarget
    // textureCache will be what you previously made with CVOpenGLESTextureCacheCreate
    NSLog(@"fillPixelBuffer before");
    err = CVOpenGLESTextureCacheCreateTextureFromImage(
                                                       kCFAllocatorDefault,
                                                       _textureCache,
                                                       _pixelBuffer,
                                                       NULL, // texture attributes
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA, // opengl format
                                                       size.width,
                                                       size.height,
                                                       GL_BGRA, // native iOS format
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &_renderTexture);
    NSLog(@"fillPixelBuffer after");

    // check err value
    
    // set the texture up like any other texture
    GLint bindingTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &bindingTexture);
    
    glBindTexture(CVOpenGLESTextureGetTarget(_renderTexture),
                  CVOpenGLESTextureGetName(_renderTexture));
    //*
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    /*/
     glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
     glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
     glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
     glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
     //*/
    glBindTexture(GL_TEXTURE_2D, bindingTexture);
    
    if (NULL != _pixelData) free(_pixelData);
    _pixelData = (GLubyte*)malloc(size.width * size.height * 8);
    
    NSLog(@"createSizeDependentMembers");
}

- (void) initOffscreenGLVariables {
    _framebuffer = -1;
    
    _renderProgram = -1;
    _vertexArray = -1;
    _arrayBuffer = -1;
}

- (void) createOffscreenGLVariables {
    if (-1 == _framebuffer)
    {
        glGenFramebuffersOES(1, (GLuint*)&_framebuffer);
    }
    
    if (-1 == _renderProgram)
    {
        const char* vertexShaderSource =
#include "postex_vert.h"
        ;
        const char* fragmentShaderSource =
#include "tex_frag.h"
        ;
        _renderProgram = compileAndLinkShaderProgram(&vertexShaderSource, 1, &fragmentShaderSource, 1);
        _uniTexture = glGetUniformLocation(_renderProgram, "u_texture0");
        _atrPosition = glGetAttribLocation(_renderProgram, "a_position");
        _atrTextureCoord = glGetAttribLocation(_renderProgram, "a_texCoord");
    }
    
    //    static GLfloat gVertices[] = {
    //        -1, -1,
    //        -1, 1,
    //        1, 1,
    //        1, -1,
    //    };
    //
    //    static GLfloat gTexCoord[] = {
    //        0, 0,
    //        0, 1,
    //        1, 1,
    //        1, 0,
    //    };
    static GLfloat VBO[] = {
        //Position, Texcoord
        -1, -1, 0, 0,
        -1, 1, 0, 1,
        1, 1, 1, 1,
        1, -1, 1, 0,
    };
    
    if (-1 == _vertexArray)
    {
        glGenVertexArraysOES(1, (GLuint*)&_vertexArray);
    }
    
    if (-1 == _arrayBuffer)
    {
        GLint vertexArrayBinding;
        glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &vertexArrayBinding);
        GLint bufferBinding;
        glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &bufferBinding);
        
        glBindVertexArrayOES(_vertexArray);
        glGenBuffers(1, (GLuint*)&_arrayBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, _arrayBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(VBO), VBO, GL_STATIC_DRAW);
        
        glBindVertexArrayOES(vertexArrayBinding);
        glBindBuffer(GL_ARRAY_BUFFER, bufferBinding);
    }
}

- (void) releaseOffscreenGLVariables {
    if (-1 != _renderProgram)
    {
        glDeleteProgram(_renderProgram);
        _renderProgram = -1;
    }
    
    if (-1 != _vertexArray)
    {
        glDeleteVertexArraysOES(1, (GLuint*)&_vertexArray);
        _vertexArray = -1;
    }
    
    if (-1 != _arrayBuffer)
    {
        glDeleteBuffers(1, (GLuint*)&_arrayBuffer);
    }
    
    if (-1 != _framebuffer)
    {
        glDeleteFramebuffersOES(1, (GLuint*)&_framebuffer);
        _framebuffer = -1;
    }
}

- (UIImage*) snapshotImage {
    if (!_pixelData) return nil;
    
    for (int i=4*_viewSize.width*_viewSize.height-4; i>=0; i-=4)
    {
        _pixelData[i+0] ^= _pixelData[i+2];
        _pixelData[i+2] ^= _pixelData[i+0];
        _pixelData[i+0] ^= _pixelData[i+2];
    }
    for (int iRow=0; iRow<_viewSize.height/2; iRow++)
    {
        GLubyte* p0 = _pixelData + 4 * (int)_viewSize.width * iRow;
        GLubyte* p1 = _pixelData + 4 * (int)_viewSize.width * ((int)_viewSize.height-1 - iRow);
        for (int iCol=4*_viewSize.width-1; iCol>=0; iCol--)
        {
            p0[iCol] ^= p1[iCol];
            p1[iCol] ^= p0[iCol];
            p0[iCol] ^= p1[iCol];
        }
    }
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, _pixelData, 4 * _viewSize.width * _viewSize.height, NULL);
    // make data provider with data.
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    
    CGColorSpaceRef colorSpaceRef    = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref                    = CGImageCreate(_viewSize.width, _viewSize.height,
                                                       8, 32, 4 * _viewSize.width,
                                                       colorSpaceRef, bitmapInfo, dataProvider,
                                                       NULL, false,
                                                       kCGRenderingIntentDefault);
    
    CGContextRef bitmapContext;
    bitmapContext = CGBitmapContextCreate(NULL, _viewSize.width, _viewSize.height, CGImageGetBitsPerComponent(iref), CGImageGetBytesPerRow(iref), colorSpaceRef, bitmapInfo);
    CGContextScaleCTM(bitmapContext, 1.0f, -1.0f);
    
    //    CGImageRef transformedImageRef = CGBitmapContextCreateImage(bitmapContext);
    UIImage* image                    = [[UIImage alloc] initWithCGImage:iref];
    CGContextRelease(bitmapContext);
    CGImageRelease(iref);
    //    CGImageRelease(transformedImageRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    CGDataProviderRelease(dataProvider);
    
    return image;
}

- (void) takeSnapshotData {
    NSLog(@"lock pixelBuffer before");
    CVPixelBufferLockBaseAddress(_pixelBuffer, 0);
    NSLog(@"take pixelBuffer snapshot before");
    GLubyte* pixelBytes = (GLubyte*) CVPixelBufferGetBaseAddress(_pixelBuffer);
    memcpy(_pixelData, pixelBytes, 4 * _viewSize.width * _viewSize.height);
    NSLog(@"take pixelBuffer snapshot after");
    CVPixelBufferUnlockBaseAddress(_pixelBuffer, 0);
    NSLog(@"lock pixelBuffer after");
}

- (void) setShareMode {
    _isShareMode = YES;
}

- (void) setFPS:(float)fps {
    _fps = fps;
}

- (void) setViewSize:(CGSize)size {
    if (size.width != _viewSize.width || size.height != _viewSize.height)
    {
        _isViewSizeInvalid = YES;
    }
    _viewSize = size;///_eaglLayer.frame.size;
}

- (BOOL) onRenderbufferStorage : (id)receiver
                           cmd : (SEL)cmd
                        target : (NSInteger)target
                      drawable : (id)drawable
{
    BOOL ret = gSuperRenderBufferStorage(receiver, cmd, target, drawable);
    
    if (drawable != _eaglLayer)
    {
        _eaglLayer = (CAEAGLLayer*) drawable;
        //        _eaglLayer.affineTransform = CGAffineTransformScale(_eaglLayer.affineTransform, -1.0f, -1.0f);
    }
    
    GLint width, height;
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &width);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &height);
    
    [self setViewSize:CGSizeMake(width, height)];
    //    APPLY_LOGBIT(LOG_RESIZE_GLVIEW) {NSLog(@"CycordVideoRecorder$onRenderbufferStorage : _viewSize = (%d,%d)", width,height);}
    return ret;
}
/*
 - (void) onCommandBufferComplete : (id<CAMetalDrawable>)metalDrawable {
 if (-1 == _renderingingStartTime)
 {
 _renderingingStartTime = getCurrentTimeMills();
 _nextSnapshotTime = 2000;
 }
 
 id<MTLTexture> texture = metalDrawable.texture;
 
 CVPixelBufferLockBaseAddress(_pixelBuffer, 0);必须锁定内存
 
 MTLRegion region = MTLRegionMake2D(0, 0, metalDrawable.layer.drawableSize.width, metalDrawable.layer.drawableSize.height);
 
 int bytesPerPixel = 4;
 int bytesPerRow = bytesPerPixel * metalDrawable.layer.drawableSize.width;
 
 NSLog(@"drawable.layer.drawableSize.width = %f, drawable.layer.drawableSize.height = %f", metalDrawable.layer.drawableSize.width, metalDrawable.layer.drawableSize.height);
 NSLog(@"textureType = %lu, width = %lu, height = %lu, depth = %lu, arrayLength = %lu， mipmapLevelCount = %lu, sampleCount = %lu", texture.textureType, texture.width, texture.height, texture.depth, texture.arrayLength, texture.mipmapLevelCount, texture.sampleCount);
 
 void *tmpBuffer = CVPixelBufferGetBaseAddress(_pixelBuffer);
 
 [texture getBytes:tmpBuffer bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
 
 [_iv setImage:[self imageFromPixelBuffer:_pixelBuffer]];
 int renderingTime = getCurrentTimeMills() - _renderingingStartTime;
 if (-1 == _recordingStartTime)
 {
 _recordingStartTime = getCurrentTimeMills();
 }
 int elapsedTime = (int)(getCurrentTimeMills() - _recordingStartTime);
 
 int numFrames = (int)(elapsedTime * _fps / 1000.0f);
 NSLog(@"One new frame to record. numFrames = %d, elapsedTime = %d", numFrames, elapsedTime);
 if (0 == elapsedTime || numFrames > _recordedFrames)
 {
 BOOL append_ok = NO;
 int j = 0;
 while (!append_ok && j < 30)
 {
 if (_pixelBufferAdaptor.assetWriterInput.readyForMoreMediaData)
 {
 printf("appending %d attemp %d\n", _frameCounter, j);
 
 CMTime frameTime = CMTimeMake(elapsedTime, 1000);
 float frameSeconds = CMTimeGetSeconds(frameTime);
 NSLog(@"frameSeconds:%f", frameSeconds);
 append_ok = [_pixelBufferAdaptor appendPixelBuffer:_pixelBuffer withPresentationTime:frameTime];
 if (!append_ok)
 {
 NSLog(@"AVAssetWriterStatus = %d", _videoWriter.status);
 if (AVAssetWriterStatusFailed == _videoWriter.status)
 {
 NSLog(@"videoWriter.error = %@", _videoWriter.error);
 }
 }
 if(buffer)
 [NSThread sleepForTimeInterval:0.05];
 }
 else
 {
 printf("adaptor not ready %d, %d\n", _frameCounter, j);
 [NSThread sleepForTimeInterval:0.1];
 }
 j++;
 }
 if (!append_ok) {
 NSLog(@"error appending image %d times %d ms = %d\n", _recordedFrames, j, elapsedTime);
 }
 else {
 NSLog(@"SUCCESSFULLY appending image %d times %d ms = %d\n", _recordedFrames, j, elapsedTime);
 }
 /!!!    CVPixelBufferRelease(buffer);
 
 NSData* data;
 NSString* filename;
 if (UIImagePNGRepresentation(image) == nil)
 {
 data = UIImageJPEGRepresentation(image, 1);
 filename = [NSString stringWithFormat:@"%@/%d%@", _fileOutputPath,_frameCounter,@".jpg"];
 }
 else
 {
 data = UIImagePNGRepresentation(image);
 filename = [NSString stringWithFormat:@"%@/%d%@", _fileOutputPath,_frameCounter,@".png"];
 }
 NSFileManager* fileManager = [NSFileManager defaultManager];
 [fileManager createDirectoryAtPath:_fileOutputPath withIntermediateDirectories:YES attributes:nil error:nil];
 [fileManager createFileAtPath:filename contents:data attributes:nil];
 把截图保存到相册里
 UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
 _recordedFrames = numFrames;
 
 if (self.delegate)
 {
 [self.delegate didRecordOneFrame:(getCurrentTimeMills() - _recordingStartTime)];
 }
 }
 
 CVPixelBufferUnlockBaseAddress(_pixelBuffer, 0);解锁内存
 }
 //*/
- (void) setupVideoRecorder {
    if (_isViewSizeInvalid)
    {
        [self releaseSizeDependentMembers];
        if (_viewSize.width > 0 && _viewSize.height > 0)
        {
            [self createSizeDependentMembers:_viewSize];
        }
        _isViewSizeInvalid = NO;
    }
    CHECK_GL_ERROR();
}

- (void) recordOneFrame:(CGFloat)videoTimeMillSeconds {
    if (!_isRecording)
        return;
    NSLog(@"#FrameLoss#4 : End rendering video frame#0 : %f", videoTimeMillSeconds);
    [self setupVideoRecorder];
    
    //wrtie by spy drop the same of videoTimeMillSeconds frame
    if (_lastWriteTimeStamp < 0.f)
        _lastWriteTimeStamp = videoTimeMillSeconds;
    else if (_lastWriteTimeStamp != videoTimeMillSeconds)
        _lastWriteTimeStamp = videoTimeMillSeconds;
    else
    {NSLog(@"#FrameLoss#N recordOneFrame return#0 _lastWriteTimeStamp=%f, videoTimeMillSeconds=%f\n", _lastWriteTimeStamp, videoTimeMillSeconds);
        return;
    }
    
    int numFrames = round(videoTimeMillSeconds * _fps / 1000.0f);
    //NSLog(@"One new frame to record. numFrames = %d, elapsedTime = %d", numFrames, elapsedTime);
    if (0 == videoTimeMillSeconds || numFrames > _recordedFrames)
    {NSLog(@"#FrameLoss#5 : End rendering video frame : %f", videoTimeMillSeconds);
        BOOL append_ok = NO;
        int j = 0;
        NSError* appendError;
        float frameSeconds;
        while (!append_ok && j < 10)//0)
        {
            if (_pixelBufferAdaptor.assetWriterInput.readyForMoreMediaData)
            {
                //            printf("appending %d attemp %d\n", _frameCounter, j);
                
                CMTime frameTime = CMTimeMake(videoTimeMillSeconds, 1000);
                frameSeconds =(float)CMTimeGetSeconds(frameTime);
                append_ok = [_pixelBufferAdaptor appendPixelBuffer:_pixelBuffer withPresentationTime:frameTime];
                appendError = _videoWriter.error;
                NSLog(@"#FrameLoss#6 recordOneFrame error=%d, timestamp=%f", (!append_ok || nil != appendError), videoTimeMillSeconds);
#ifdef DEBUG_VIDEORECORDER_INTERRUPTED_BY_ERROR
                if (s_isFirstTime)
                {
                    s_isFirstTime = false;
                    appendError = [NSError errorWithDomain:@"CycordVideoRecorder" code:-2 userInfo:@{@"status":@(_videoWriter.status)}];
                }
#endif
                _lastWriteCMTime = frameTime;
                /*  if (!append_ok || appendError || AVAssetWriterStatusFailed == _videoWriter.status || AVAssetWriterStatusCancelled == _videoWriter.status)
                 {
                 NSLog(@"#CycordVideoRecorder#Bug2880# AVAssetWriterStatus = %ld, videoWriter.error = %@", (long)_videoWriter.status, appendError);
                 if (self.delegate && [self.delegate respondsToSelector:@selector(cycordVideoRecorderFailedWhileRecording:)])
                 {
                 [self.delegate cycordVideoRecorderFailedWhileRecording:appendError];
                 }
                 }*/
                //            if(buffer)
                if (!append_ok || appendError || AVAssetWriterStatusFailed == _videoWriter.status || AVAssetWriterStatusCancelled == _videoWriter.status)
                {
                    NSLog(@"#appendPixelBuffer error AVAssetWriterStatus = %ld, videoWriter.error = %@", (long)_videoWriter.status, appendError);
                    [NSThread sleepForTimeInterval:0.1];
                }
                //            if(buffer)
                //                [NSThread sleepForTimeInterval:0.05];
            }
            else
            {
                NSLog(@"appendPixelBuffer adaptor not ready  %d\n",  j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        if (!append_ok || AVAssetWriterStatusFailed == _videoWriter.status || AVAssetWriterStatusCancelled == _videoWriter.status) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(cycordVideoRecorderFailedWhileRecording:)])
            {
                [self.delegate cycordVideoRecorderFailedWhileRecording:appendError];
            }
        }
        else {
            NSLog(@"SUCCESSFULLY appending image %d times %d ms=%f\n", _recordedFrames, j, frameSeconds);
        }
        ///!!!    CVPixelBufferRelease(buffer);
        
        //    NSData* data;
        //    NSString* filename;
        //    if (UIImagePNGRepresentation(image) == nil)
        //    {
        //        data = UIImageJPEGRepresentation(image, 1);
        //        filename = [NSString stringWithFormat:@"%@/%d%@", _fileOutputPath,_frameCounter,@".jpg"];
        //    }
        //    else
        //    {
        //        data = UIImagePNGRepresentation(image);
        //        filename = [NSString stringWithFormat:@"%@/%d%@", _fileOutputPath,_frameCounter,@".png"];
        //    }
        //    NSFileManager* fileManager = [NSFileManager defaultManager];
        //    [fileManager createDirectoryAtPath:_fileOutputPath withIntermediateDirectories:YES attributes:nil error:nil];
        //    [fileManager createFileAtPath:filename contents:data attributes:nil];
        //    //把截图保存到相册里
        //    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        _recordedFrames = numFrames;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cycordVideoRecorderDidRecordOneFrame:)])
        {
            [self.delegate cycordVideoRecorderDidRecordOneFrame:videoTimeMillSeconds];///(int)(getCurrentTimeMills() - _recordingStartTime)];
        }
    }
}

- (BOOL) onPresentRenderbuffer : (id)receiver
                           cmd : (SEL)cmd
                        target : (NSInteger)target
{
    BOOL ret;
    [self createOffscreenGLVariables];
    CHECK_GL_ERROR();
    
    if (-1 == _renderingingStartTime)
    {
        _renderingingStartTime = getCurrentTimeMills();
        _nextSnapshotTime = 2000;
    }
    
    static GLubyte gIndices[] = {
        0, 1, 2,
        3, 0, 2,
    };
    
    /*
     Check if our offscreen texture2D object is attached to color attachment of the Framebuffer currently binding, if not, goto a, else b.
     a) Use glReadPixels to get pixel data. Do the ordinary work of presentRenderbuffer. Attach our offscreen Texture2D object to the Framebuffer currently binding, and attach current binding Renderbuffer to our foreground Framebuffer;
     b) Get pixel data from our Texture2D. Render the texture to our foreground Framebuffer. Then do presentRenderbuffer. Bind the background Framebuffer again;
     */
    GLint defaultFramebuffer, defaultRenderbuffer;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, &defaultFramebuffer);
    glGetIntegerv(GL_RENDERBUFFER_BINDING_OES, &defaultRenderbuffer);
    GLint attachedObjectType, attachedObjectID;
    glGetFramebufferAttachmentParameterivOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE_OES, &attachedObjectType);
    glGetFramebufferAttachmentParameterivOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME_OES, &attachedObjectID);
    
    BOOL renderNextFrame2Offscreen = NO;
    
    if (GL_TEXTURE == attachedObjectType)
    {
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
        CHECK_GL_ERROR();
        // Get previous OpenGL states:
        GLint activeTexture;
        glGetIntegerv(GL_ACTIVE_TEXTURE, &activeTexture);
        glActiveTexture(GL_TEXTURE0);
        CHECK_GL_ERROR();
        GLint bindingTexture;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &bindingTexture);
        glBindTexture(GL_TEXTURE_2D, attachedObjectID);
        CHECK_GL_ERROR();
        
        bool gles1 = ([EAGLContext currentContext].API == kEAGLRenderingAPIOpenGLES1);
        
        if (!gles1)
        {
            GLint currentProgram;
            glGetIntegerv(GL_CURRENT_PROGRAM, &currentProgram);
            
            GLint maxVertexAttribs;
            glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &maxVertexAttribs);
            GLint* isVAAEnabled = new GLint[maxVertexAttribs];
            for (int i=maxVertexAttribs-1; i>=0; i--)
            {
                glGetVertexAttribiv(i, GL_VERTEX_ATTRIB_ARRAY_ENABLED, isVAAEnabled+i);
                glDisableVertexAttribArray(i);
            }
            CHECK_GL_ERROR();
            GLint prevElementArrayBuffer, prevArrayBuffer;
            glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &prevElementArrayBuffer);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &prevArrayBuffer);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
            CHECK_GL_ERROR();
            GLint vertexArrayBinding;
            glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &vertexArrayBinding);
            glBindVertexArrayOES(_vertexArray);
            // :Get previous OpenGL states
            CHECK_GL_ERROR();
            glUseProgram(_renderProgram);
            glEnableVertexAttribArray(_atrTextureCoord);
            glEnableVertexAttribArray(_atrPosition);
            glUniform1i(_uniTexture, 0);
            glBindBuffer(GL_ARRAY_BUFFER, _arrayBuffer);
            glVertexAttribPointer(_atrPosition, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*4, 0);
            glVertexAttribPointer(_atrTextureCoord, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*4, (GLvoid*)(sizeof(GLfloat)*2));
            CHECK_GL_ERROR();
            
            glEnable(GL_BLEND);
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            glDrawElements(GL_TRIANGLES, sizeof(gIndices)/sizeof(gIndices[0]), GL_UNSIGNED_BYTE, gIndices);
            
            // Restore all GL states:
            glBindVertexArrayOES(vertexArrayBinding);
            glBindBuffer(GL_ARRAY_BUFFER, prevArrayBuffer);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, prevElementArrayBuffer);
            for (int i=maxVertexAttribs-1; i>=0; i--)
            {
                if (0 != isVAAEnabled[i])
                glEnableVertexAttribArray(i);
                else
                glDisableVertexAttribArray(i);
            }
            delete[] isVAAEnabled;
            glUseProgram(currentProgram);
        }
        else
        {
            static GLfloat VBO[] = {
                //Position, Texcoord
                -1, -1, 0, 0,
                -1, 1, 0, 1,
                1, 1, 1, 1,
                1, -1, 1, 0,
            };
            
            glMatrixMode(GL_PROJECTION);
            glPushMatrix();
            glLoadIdentity();
            glMatrixMode(GL_MODELVIEW);
            glPushMatrix();
            glLoadIdentity();
            
            // Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
            GLboolean isTextureEnabled = glIsEnabled(GL_TEXTURE_2D);
            GLboolean isTexCoordEnabled = glIsEnabled(GL_TEXTURE_COORD_ARRAY);
            GLboolean isVertexEnabled = glIsEnabled(GL_VERTEX_ARRAY);
            GLboolean isColorEnabled = glIsEnabled(GL_COLOR_ARRAY);
            GLboolean isNormalEnabled = glIsEnabled(GL_NORMAL_ARRAY);
            
            glEnable(GL_TEXTURE_2D);
            glEnableClientState(GL_VERTEX_ARRAY);
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            
            glVertexPointer(2, GL_FLOAT, sizeof(GLfloat)*4, VBO);
            glTexCoordPointer(2, GL_FLOAT, sizeof(GLfloat)*4, (GLvoid*)(&VBO[2]));
            
            glDrawElements(GL_TRIANGLES, sizeof(gIndices)/sizeof(gIndices[0]), GL_UNSIGNED_BYTE, gIndices);
            
            if (isTextureEnabled)
            glEnable(GL_TEXTURE_2D);
            else
            glDisable(GL_TEXTURE_2D);
            if (isVertexEnabled)
            glEnableClientState(GL_VERTEX_ARRAY);
            else
            glDisableClientState(GL_VERTEX_ARRAY);
            if (isTexCoordEnabled)
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            else
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
            if (isColorEnabled)
            glEnableClientState(GL_COLOR_ARRAY);
            else
            glDisableClientState(GL_COLOR_ARRAY);
            if (isNormalEnabled)
            glEnableClientState(GL_NORMAL_ARRAY);
            else
            glDisableClientState(GL_NORMAL_ARRAY);
            
            glMatrixMode(GL_PROJECTION);
            glPopMatrix();
            glMatrixMode(GL_MODELVIEW);
            glPopMatrix();
        }
        CHECK_GL_ERROR();
        
        glBindTexture(GL_TEXTURE_2D, bindingTexture);
        glActiveTexture(activeTexture);
        CHECK_GL_ERROR();
        ret = gSuperPresentRenderBuffer(receiver, cmd, target);
    }
    else
    {
        //TODO: Use glReadPixels to get pixel data
        ret = gSuperPresentRenderBuffer(receiver, cmd, target);
    }
    
    int renderingTime = (int)(getCurrentTimeMills() - _renderingingStartTime);
    //*
    @synchronized(self)
    {
        if (_isRecording)
        {
            if (_takeSnapshotNextFrame)
            {
                _takeSnapshotNextFrame = NO;
                _nextSnapshotTime += 2000;
                
                __weak CycordVideoRecorder* wSelf = self;
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^() {
                    if (_isRecording)
                    {
                        [wSelf takeSnapshotData];
                        UIImage* image = nil;
                        image = [wSelf snapshotImage];
                        
                        if (image)
                        {
                            NSData* snapshotData = UIImagePNGRepresentation(image);
                            [_snapshotDatas setObject:snapshotData forKey:[NSNumber numberWithInt:renderingTime]];
                            NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                            NSString* documentsDirectory = [paths objectAtIndex:0];
                            [snapshotData writeToFile:[NSString stringWithFormat:@"%s/%u.png", [documentsDirectory UTF8String], renderingTime] atomically:YES];
                            //                NSLog(@"Took one snapshot");
                        }
                        /*
                         float proportion;
                         do
                         {
                         proportion = (float)randomInt(0, 1000) / 1000.0f;
                         } while (0 == proportion);
                         _nextSnapshotTime = _nextSnapshotTime / proportion;
                         /*/
                        
                        //*/
                    }
                });
            }
            
            // Decide whether to render offscreen next frame:
            if (renderingTime > _nextSnapshotTime)
            {
                _takeSnapshotNextFrame = YES;
                //        renderNextFrame2Offscreen = YES;
            }
            
            if (-1 == _recordingStartTime)
            {
                _recordingStartTime = getCurrentTimeMills();
            }
            float elapsedTime = (float)(getCurrentTimeMills() - _recordingStartTime);
            [self recordOneFrame:elapsedTime];
            
            renderNextFrame2Offscreen = YES;
        }
    }
    //*/
    
    //    if (self.delegate)
    //    {
    //        [self.delegate didRenderOneFrame:renderingTime];
    //    }
    
    GLint renderTextureID = CVOpenGLESTextureGetName(_renderTexture);
    if (renderNextFrame2Offscreen)
    {
        if (GL_TEXTURE != attachedObjectType || renderTextureID != attachedObjectID)
        {
            glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
            CHECK_GL_ERROR();
            glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, renderTextureID, 0);
            CHECK_GL_ERROR();
            glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
            CHECK_GL_ERROR();
            glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, defaultRenderbuffer);
            CHECK_GL_ERROR();
        }
    }
    else if (GL_TEXTURE == attachedObjectType)
    {
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
        CHECK_GL_ERROR();
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, defaultRenderbuffer);
        CHECK_GL_ERROR();
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
        CHECK_GL_ERROR();
        glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, renderTextureID, 0);
        CHECK_GL_ERROR();
    }
    ///!!!For Debug:
    GLint renderbufferWidth, renderbufferHeight;
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &renderbufferWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &renderbufferHeight);
    CHECK_GL_ERROR();
    //    APPLY_LOGBIT(LOG_RESIZE_GLVIEW) {NSLog(@"CycordVideoRecorder: renderbuffer.(width, height) = (%d, %d)", renderbufferWidth, renderbufferHeight);}
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    CHECK_GL_ERROR();
    return ret;
}

void FKC_hookOCClasses()
{
    if (!g_isClassHooked)
    {
        Class clsEAGLContext = objc_getClass("EAGLContext");
        
        gSuperPresentRenderBuffer = (PresentRenderbufferPrototype)class_getMethodImplementation(clsEAGLContext, @selector(presentRenderbuffer:));
        Method mtdPresentRenderBuffer = class_getInstanceMethod(clsEAGLContext, @selector(presentRenderbuffer:));
        class_replaceMethod(clsEAGLContext, @selector(presentRenderbuffer:), IMP(FKC_PresentRenderbuffer), method_getTypeEncoding(mtdPresentRenderBuffer));
        
        gSuperRenderBufferStorage = (RenderbufferStoragePrototype)class_getMethodImplementation(clsEAGLContext, @selector(renderbufferStorage:fromDrawable:));
        Method mtdRenderBufferStorage = class_getInstanceMethod(clsEAGLContext, @selector(renderbufferStorage:fromDrawable:));
        class_replaceMethod(clsEAGLContext, @selector(renderbufferStorage:fromDrawable:), IMP(FKC_RenderbufferStorage), method_getTypeEncoding(mtdRenderBufferStorage));
        objc_registerClassPair(clsEAGLContext);
        /*
         Class clsMTLDebugCommandBuffer = objc_getClass("MTLDebugCommandBuffer");
         //        gSuperAddCompletedHandler = (AddCompletedHandlerPrototype) class_getMethodImplementation(clsMTLDebugCommandBuffer, @selector(addCompletedHandler:));
         //        Method mtdAddCompleteHandler = class_getInstanceMethod(clsMTLDebugCommandBuffer, @selector(addCompletedHandler:));
         //        class_replaceMethod(clsMTLDebugCommandBuffer, @selector(addCompletedHandler:), IMP(FKC_AddCompletedHandler), method_getTypeEncoding(mtdAddCompleteHandler));
         //
         gSuperPresentDrawable = (PresentDrawablePrototype) class_getMethodImplementation(clsMTLDebugCommandBuffer, @selector(presentDrawable:));
         Method mtdPresentDrawable = class_getInstanceMethod(clsMTLDebugCommandBuffer, @selector(presentDrawable:));
         class_replaceMethod(clsMTLDebugCommandBuffer, @selector(presentDrawable:), IMP(FKC_PresentDrawable), method_getTypeEncoding(mtdPresentDrawable));
         
         gSuperPresentDrawableAtTime = (PresentDrawableAtTimePrototype) class_getMethodImplementation(clsMTLDebugCommandBuffer, @selector(presentDrawable:atTime:));
         Method mtdPresentDrawableAtTime = class_getInstanceMethod(clsMTLDebugCommandBuffer, @selector(presentDrawable:atTime:));
         class_replaceMethod(clsMTLDebugCommandBuffer, @selector(presentDrawable:atTime:), IMP(FKC_PresentDrawableAtTime), method_getTypeEncoding(mtdPresentDrawableAtTime));
         
         objc_registerClassPair(clsMTLDebugCommandBuffer);
         //*/
        g_isClassHooked = true;
    }
}

void FKC_restoreOCClasses()
{
    if (g_isClassHooked)
    {
        Class clsEAGLContext = objc_getClass("EAGLContext");
        
        //gSuperPresentRenderBuffer = class_getMethodImplementation(clsEAGLContext, @selector(presentRenderbuffer:));
        Method mtdPresentRenderBuffer = class_getInstanceMethod(clsEAGLContext, @selector(presentRenderbuffer:));
        class_replaceMethod(clsEAGLContext, @selector(presentRenderbuffer:), (IMP)gSuperPresentRenderBuffer, method_getTypeEncoding(mtdPresentRenderBuffer));
        
        //gSuperRenderBufferStorage = class_getMethodImplementation(clsEAGLContext, @selector(renderbufferStorage:fromDrawable:));
        Method mtdRenderBufferStorage = class_getInstanceMethod(clsEAGLContext, @selector(renderbufferStorage:fromDrawable:));
        class_replaceMethod(clsEAGLContext, @selector(renderbufferStorage:fromDrawable:), (IMP)gSuperRenderBufferStorage, method_getTypeEncoding(mtdRenderBufferStorage));
        
        objc_registerClassPair(clsEAGLContext);
        
        Class clsMTLDebugCommandBuffer = objc_getClass("MTLDebugCommandBuffer");
        //        Method mtdAddCompleteHandler = class_getInstanceMethod(clsMTLDebugCommandBuffer, @selector(addCompletedHandler:));
        //        class_replaceMethod(clsMTLDebugCommandBuffer, @selector(addCompletedHandler:), IMP(gSuperAddCompletedHandler), method_getTypeEncoding(mtdAddCompleteHandler));
        //
        Method mtdPresentDrawable = class_getInstanceMethod(clsMTLDebugCommandBuffer, @selector(presentDrawable:));
        class_replaceMethod(clsMTLDebugCommandBuffer, @selector(presentDrawable:), IMP(gSuperPresentDrawable), method_getTypeEncoding(mtdPresentDrawable));
        
        Method mtdPresentDrawableAtTime = class_getInstanceMethod(clsMTLDebugCommandBuffer, @selector(presentDrawable:atTime:));
        class_replaceMethod(clsMTLDebugCommandBuffer, @selector(presentDrawable:atTime:), IMP(gSuperPresentDrawableAtTime), method_getTypeEncoding(mtdPresentDrawableAtTime));
        
        objc_registerClassPair(clsMTLDebugCommandBuffer);
        
        g_isClassHooked = false;
    }
}

- (void) setupVideoWriter : (CGSize)size
{
    //write by spy
    _videoWriter = nil;
    _videoWriterInput = nil;
    _pixelBufferAdaptor = nil;
    
    NSString* fileOutputPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    NSString* baseFilename = [self outputVideoTmpFileBaseName];
    NSString* filename = [fileOutputPath stringByAppendingPathComponent:baseFilename];
    //Delete file if it already exists
    NSURL* fileURL = [NSURL fileURLWithPath:filename];
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
    
    _videoWriter = [[AVAssetWriter alloc] initWithURL:fileURL
                                             fileType:AVFileTypeAppleM4V
                                                error:&error];
    NSParameterAssert(_videoWriter);
    
    /*double bitRate;
    if (_isShareMode)
        bitRate = (5 * 1024.0 * 1024.0 * size.width * size.height) / (2304.0 * 1152.0);
    else
        bitRate = (16 * 1024.0 * 1024.0 * size.width * size.height) / (2304.0 * 1152.0);
    */
    double bitRate = [avUtils getEstimatedVideoEncodedBitrateInBps:size.width height:size.height fps:_fps qualityMode:_isShareMode];
    
    NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithDouble:bitRate], AVVideoAverageBitRateKey,
                                           nil];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   videoCompressionProps, AVVideoCompressionPropertiesKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    _videoWriterInput = [AVAssetWriterInput
                         assetWriterInputWithMediaType:AVMediaTypeVideo
                         outputSettings:videoSettings];// retain];
    _videoWriterInput.expectsMediaDataInRealTime = YES;
    _videoWriterInput.transform = CGAffineTransformMakeScale(1, -1);
    
    //BGRA seems to be much faster than RGBA
    NSDictionary* sourcePixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 [NSNumber numberWithInt:VIDEO_PIXEL_FORMAT], kCVPixelBufferPixelFormatTypeKey,
                                                 [NSNumber numberWithInt:size.width], kCVPixelBufferWidthKey,
                                                 [NSNumber numberWithInt:size.height], kCVPixelBufferHeightKey,
                                                 (id)kCFBooleanTrue, (id)kCVPixelFormatOpenGLESCompatibility,//write by spy 兼容opengl纹理
                                                 nil];
    
    _pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor
                           assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoWriterInput
                           sourcePixelBufferAttributes:sourcePixelBufferAttributes];// retain];
    NSParameterAssert(_videoWriterInput);
    NSParameterAssert([_videoWriter canAddInput:_videoWriterInput]);
    if ([_videoWriter canAddInput:_videoWriterInput])
    [_videoWriter addInput:_videoWriterInput];
    else{
        NSLog(@"setupVideoWriter error");
        return;
    }
    
    sourcePixelBufferAttributes = nil;
    //Start a session:
    if ([_videoWriter startWriting]){
        [_videoWriter startSessionAtSourceTime:kCMTimeZero];
        NSLog(@"setupVideoWriter ok");
    }
    else{
        NSLog(@"setupVideoWriter status:%ld,error:%@",_videoWriter.status,_videoWriter.error);
    }
}

- (CVPixelBufferRef) createPixelBuffer:(CGSize)size {
    /*
     NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
     [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
     [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLESCompatibilityKey,
     nil];
     /*/
    
#if 0
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef options;
    empty = CFDictionaryCreate(kCFAllocatorDefault, // our empty IOSurface properties dictionary
                               NULL,
                               NULL,
                               0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks);
    options = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                        1,
                                        &kCFTypeDictionaryKeyCallBacks,
                                        &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(options,
                         kCVPixelBufferIOSurfacePropertiesKey,
                         empty);
    
    CFDictionarySetValue(options,
                         kCVPixelBufferOpenGLESCompatibilityKey,//kCVPixelBufferCGBitmapContextCompatibilityKey,//kCVPixelBufferCGImageCompatibilityKey,//
                         (const void*)[NSNumber numberWithBool:YES]);
    
    //*/
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, OPENGL_PIXEL_FORMAT, (CFMutableDictionaryRef) options,
                                          &pxbuffer);
#endif
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferPoolCreatePixelBuffer (kCFAllocatorDefault, [_pixelBufferAdaptor pixelBufferPool], &pxbuffer);
    
    assert(status == kCVReturnSuccess && pxbuffer != NULL);
    //NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    return pxbuffer;
}
/*
 - (void) prepareToRecordAudio
 {
 AVAudioSession *audioSession = [AVAudioSession sharedInstance];
 NSError *err = nil;
 [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];//!!!It matters AVAudioSessionCategoryAmbient
 if (err)
 {
 NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
 return;
 }
 
 err = nil;
 [audioSession setActive:YES error:&err];
 if (err)
 {
 NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
 return;
 }
 
 NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
 [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
 [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
 [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
 [recordSetting setValue :[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
 [recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
 [recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
 
 Create a new dated file
 NSString * recorderFilePath = [NSString stringWithFormat:@"%@/%@", [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], _originalAudioOutputPath]; retain];
 NSURL *url = [NSURL fileURLWithPath:recorderFilePath];
 err = nil;
 _audioRecorder = [[ AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:&err];
 if (!_audioRecorder)
 {
 NSLog(@"recorder: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
 UIAlertView *alert =
 [[UIAlertView alloc] initWithTitle: @"Warning"
 message: [err localizedDescription]
 delegate: nil
 cancelButtonTitle:@"OK"
 otherButtonTitles:nil];
 [alert show];
 [alert release];
 return;
 }
 prepare to record
 [_audioRecorder setDelegate:self];
 [_audioRecorder prepareToRecord];
 _audioRecorder.meteringEnabled = YES;
 BOOL audioHWAvailable = audioSession.inputIsAvailable;
 if (! audioHWAvailable)
 {
 UIAlertView *cantRecordAlert =
 [[UIAlertView alloc] initWithTitle: @"Warning"
 message: @"Audio input hardware not available"
 delegate: nil
 cancelButtonTitle:@"OK"
 otherButtonTitles:nil];
 [cantRecordAlert show];
 [cantRecordAlert release];
 return;
 }
 }
 
 
 //代理 这里可以监听录音成功
 - (void)audioRecorderDidFinishRecording:(AVAudioRecorder *) aRecorder successfully:(BOOL)flag
 {
 //    NSLog(@"recorder successfully");
 //    UIAlertView *recorderSuccessful = [[UIAlertView alloc] initWithTitle:@"" message:@"录音成功"
 //                                                                delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
 //    [recorderSuccessful show];
 //    [recorderSuccessful release];
 }
 
 
 //代理 这里可以监听录音失败
 - (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)arecorder error:(NSError *)error
 {
 
 //    UIAlertView *recorderFailed = [[UIAlertView alloc] initWithTitle:@"" message:@"发生错误"
 //                                                            delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
 //    [recorderFailed show];
 //    [recorderFailed release];
 }
 //*/

+ (NSString*) outputAudioTmpFileBaseName:(NSString*)originalName {
    return originalName ? [originalName stringByAppendingPathExtension:@"aac"] : @"sound.aac";
}

+ (NSString*) outputAudioTmpFileBaseNameCapture:(NSString*)originalName {
    return originalName ? [originalName stringByAppendingPathExtension:@"caf"] : @"sound.caf";
}

+ (NSString*) outputVideoTmpFileBaseName:(NSString*)originalName {
    return [NSString stringWithFormat:@"%@.mp4.tmp", (originalName ? originalName : @"video")];
}

+ (NSString*) outputVideoFileBaseName:(NSString*)originalName {
    return [NSString stringWithFormat:@"%@.mp4", (originalName ? originalName : @"video")];
}

+ (NSString*) outputMovieFileBaseName:(NSString*)originalName {
    NSString* destVideoBaseName = [[originalName lastPathComponent] stringByDeletingPathExtension];
    return [NSString stringWithFormat:@"%@.mov", (destVideoBaseName ? destVideoBaseName : @"video")];
}

- (NSString*) outputAudioTmpFileBaseName {
    //if (!_isRecording && !_isShareMode) //capturing
        //return [self.class outputAudioTmpFileBaseNameCapture:_destVideoBaseName];
    //    return @"capture_sound.caf";
    //else
        return [self.class outputAudioTmpFileBaseName:_destVideoBaseName];
}

- (NSString*) outputVideoTmpFileBaseName {
    return [self.class outputVideoTmpFileBaseName:_destVideoBaseName];
}

- (NSString*) outputVideoFileBaseName {
    return [self.class outputVideoFileBaseName:_destVideoBaseName];
}

- (NSString*) outputMovieFileBaseName {
    return [self.class outputMovieFileBaseName:_destVideoBaseName];
}

- (BOOL) compileAudioAndVideoToMovie:(void(^)(NSError*, NSString*))handler
{
    //这个方法在沙盒中把视频与录制的声音合并成一个新视频
    NSString* DocumentDirectory = [NSString stringWithFormat:@"%@", [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
    NSString* audio_inputFilePath = [DocumentDirectory stringByAppendingPathComponent:[self outputAudioTmpFileBaseName]];
    NSURL*    audio_inputFileUrl = [NSURL fileURLWithPath:audio_inputFilePath];
    //*/
    NSString* video_tmpFilePath = [DocumentDirectory stringByAppendingPathComponent:[self outputVideoTmpFileBaseName]];
    NSString* video_inputFilePath = [DocumentDirectory stringByAppendingPathComponent:[self outputVideoFileBaseName]];
    [[NSFileManager defaultManager] moveItemAtPath:video_tmpFilePath toPath:video_inputFilePath error:nil];
    NSURL*    video_inputFileUrl = [NSURL fileURLWithPath:video_inputFilePath];
    
    NSString* outputFilePath = [DocumentDirectory stringByAppendingPathComponent:[self outputMovieFileBaseName]];
    NSURL*    outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    
    if (_videoWriter.status != AVAssetWriterStatusCompleted || self.encodingError)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:video_inputFilePath])
            [[NSFileManager defaultManager] removeItemAtPath:video_inputFilePath error:nil];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:audio_inputFilePath])
            [[NSFileManager defaultManager] removeItemAtPath:audio_inputFilePath error:nil];
        
        if (handler)
        {
            NSLog(@"#Bug2880# compileAudioAndVideoToMovie: _videoWriter.error=%@, self.encodingError=%@", _videoWriter.error, self.encodingError);
            handler(_videoWriter.error ? _videoWriter.error : self.encodingError, video_tmpFilePath);
        }
        return NO;
    }
    
    //Finish the session:
    NSLog(@"stopRecordingPrivate _videoWriterInput markAsFinished before");
    [_videoWriterInput markAsFinished];
    NSLog(@"stopRecordingPrivate _videoWriterInput markAsFinished after");
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    
    CMTime nextClipStartTime = kCMTimeZero;
    
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:video_inputFileUrl options:nil];
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    NSArray* tracks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[tracks objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:audio_inputFilePath]) {
        AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audio_inputFileUrl options:nil];
        if (audioAsset.duration.value > 0) {
            CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
            AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [b_compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:nextClipStartTime error:nil];
        } else {
            NSLog(@"audio length = 0, not exporting audio");
        }
    }
    
    //AVAssetExportPresetHighestQuality write by spy change to AVAssetExportPresetPassthrough
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];
    _assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    _assetExport.outputURL = outputFileUrl;
    _assetExport.shouldOptimizeForNetworkUse = NO;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         switch (_assetExport.status) {
             case AVAssetExportSessionStatusFailed:
                 NSLog(@"exporting failed %@",[_assetExport error]);
                 if ([[NSFileManager defaultManager] fileExistsAtPath:video_inputFilePath])
                     [[NSFileManager defaultManager] removeItemAtPath: video_inputFilePath error:nil];
                 if ([[NSFileManager defaultManager] fileExistsAtPath:audio_inputFilePath])
                     [[NSFileManager defaultManager] removeItemAtPath: audio_inputFilePath error:nil];
                 
                 handler([NSError errorWithDomain:@"MadvVideoCodecCreatingFileFailed" code:-3 userInfo:nil], video_tmpFilePath);
    
                 break;
             case AVAssetExportSessionStatusCompleted:
                 NSLog(@"exporting completed");
                 if ([[NSFileManager defaultManager] fileExistsAtPath:video_inputFilePath])
                     [[NSFileManager defaultManager] removeItemAtPath: video_inputFilePath error:nil];
                 if ([[NSFileManager defaultManager] fileExistsAtPath:audio_inputFilePath])
                     [[NSFileManager defaultManager] removeItemAtPath: audio_inputFilePath error:nil];
                 if (handler)
                 {
                     if (![[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
                     {
                         handler([NSError errorWithDomain:@"MadvVideoCodecCreatingFileFailed" code:-3 userInfo:nil], outputFilePath);
                     }
                     else
                     {
                         handler(_videoWriter.error, outputFilePath);
                     }
                 }
                 break;
             case AVAssetExportSessionStatusCancelled:
                 NSLog(@"export cancelled");
                 break;
             default:
                 break;
         }
     }];
    
    videoAsset = nil;
    _assetExport = nil;
    mixComposition = nil;
    
    return YES;
}

@end

#endif //#ifdef TARGET_OS_IOS
