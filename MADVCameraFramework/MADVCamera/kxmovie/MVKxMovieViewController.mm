//
//  ViewController.m
//  kxmovieapp
//
//  Created by Kolyvan on 11.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#import "MVKxMovieViewController.h"
//#import "SSZipArchive.h"
#import "MVGLView.h"
#import "MadvGLRenderer_iOS.h"
#import "NSRecursiveCondition.h"
#import "CycordVideoRecorder.h"
#include "AudioRingBuffer.h"

#import <Accelerate/Accelerate.h>
#ifdef USE_TWIRLING_VR_AUDIO

#include "AudioEngineApi.h"
#import "MVPanoCameraController.h"

void processAudioFrameWithTwirling(float* binauralOutput, const float* input, void* twirlingAudioPtr, AudioStreamBasicDescription format, const int frameSize, int inputAudioChannels) {
    if (NULL == twirlingAudioPtr)
        return;
    
    for (int framesLeft = frameSize; framesLeft > 0; )
    {
        int framesToProcess = (framesLeft > 512 ? 512 : framesLeft);
        
        kmVec3 eulerAngles = [MVPanoCameraController globalCurrentEulerAngles];
        ///eulerAngles = {0, 0, 0};
        int floatOffset = format.mChannelsPerFrame * framesToProcess;
        
        float maxMagI, maxMagO, minMagI, minMagO;
        if (inputAudioChannels >= 4)
        {
            audioProcess(twirlingAudioPtr, eulerAngles.x, -eulerAngles.y, -eulerAngles.z, input, binauralOutput, NULL, framesToProcess);
        }
        else
        {
            memcpy(binauralOutput, input, floatOffset * sizeof(float));
        }
        vDSP_maxmgv(input, 1, &maxMagI, floatOffset);
        vDSP_minmgv(input, 1, &minMagI, floatOffset);
        vDSP_maxmgv(binauralOutput, 1, &maxMagO, floatOffset);
        vDSP_minmgv(binauralOutput, 1, &minMagO, floatOffset);
//        ALOGE("#VRAudio# audioProcess() with {yaw, pitch, bank} = {%.5f, %.5f, %.5f}, framesToProcess=%d, maxMagI=%.5f, minMagI=%.5f, maxMagO=%.5f, minMagO=%.5f\n", -kmRadiansToDegrees(eulerAngles.x), kmRadiansToDegrees(eulerAngles.y), kmRadiansToDegrees(eulerAngles.z), framesToProcess, maxMagI, minMagI, maxMagO, minMagO);
        
        input += floatOffset;
        binauralOutput += floatOffset;
        
        framesLeft -= framesToProcess;
    }
}

#endif


//#define USE_KXGLVIEW
#define checkStatus(...) assert(0 == __VA_ARGS__)
NSString * const KxMovieParameterMinBufferedDuration = @"KxMovieParameterMinBufferedDuration";
NSString * const KxMovieParameterMaxBufferedDuration = @"KxMovieParameterMaxBufferedDuration";
NSString * const KxMovieParameterDisableDeinterlacing = @"KxMovieParameterDisableDeinterlacing";

////////////////////////////////////////////////////////////////////////////////
//cwq tcp 2018.03.05
BOOL gUseUDPPro = TRUE;
void SetGlobalUDPPro(BOOL UseUDPPro)
{
    gUseUDPPro = UseUDPPro;
}
BOOL GetGlobalUDPPro()
{
    return gUseUDPPro;
}
////

//FILE * pAACFile = NULL;

NSString* formatTimeInterval(CGFloat seconds, BOOL isLeft)
{
    seconds = MAX(0, seconds);
    
    NSInteger s = seconds;
    NSInteger m = s / 60;
    NSInteger h = m / 60;
    
    s = s % 60;
    m = m % 60;

    NSMutableString *format = [(isLeft && seconds >= 0.5 ? @"-" : @"") mutableCopy];
    if (h != 0) [format appendFormat:@"%0.2ld:%0.2ld", (long)h, (long)m];
    else        [format appendFormat:@"%0.2ld", (long)m];
//    [format appendFormat:@"%d:%0.2d", h, m];
    [format appendFormat:@":%0.2ld", (long)s];
//    [format appendFormat:@"%ld:%0.2ld", (long)h, (long)m];
//    [format appendFormat:@":%0.2ld", (long)s];

    return format;
}

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

//static NSMutableDictionary * gHistory;

#define LOCAL_MIN_BUFFERED_DURATION   0.2
#define LOCAL_MAX_BUFFERED_DURATION   0.4
//#define NETWORK_MIN_BUFFERED_DURATION 2.0
//#define NETWORK_MAX_BUFFERED_DURATION 4.0
#define NETWORK_MIN_BUFFERED_DURATION 0.3
#define NETWORK_MAX_BUFFERED_DURATION 2.0

#define RTSP_NETWORK_MIN_BUFFERED_DURATION 0.16
#define RTSP_NETWORK_MAX_BUFFERED_DURATION 0.5

#define GyroDataFrameNumberOffset 0

#ifdef ENCODING_WITHOUT_MYGLVIEW
@interface MVKxMovieViewController () <GLRenderLoopDelegate> {
#else
    @interface MVKxMovieViewController () {
#endif
    KxMovieDecoder      *_decoder;
    NSMutableArray      *_videoFrames;
    NSMutableArray      *_audioFrames;
    NSMutableArray      *_subtitles;
    NSData              *_currentAudioFrame;
        int                 _inputAudioChannels;
    NSUInteger          _currentAudioFramePos;
    CGFloat             _moviePosition;
    NSTimeInterval      _tickCorrectionTime;
    NSTimeInterval      _tickCorrectionPosition;
    NSUInteger          _tickCounter;
    
    BOOL                _disableUpdateHUD;
    BOOL                _fullscreen;
    BOOL                _fitMode;
    BOOL                _restoreIdleTimer;
    BOOL                _interrupted;
#ifdef USE_KXGLVIEW
    KxMovieGLView       *_glView;
#else
    MVGLView*           _glView;
#endif
#ifdef ENCODING_WITHOUT_MYGLVIEW
    GLRenderLoop*       _encoderRenderLoop;
#endif
    int _panoramaMode;
//    UIActivityIndicatorView* _activityIndicatorView;

    NSString*           _contentPath;
    NSString*           _audioOutputPath;
    //UIImageView         *_imageView;
    
    ExtAudioFileRef _audioFileRef;
    AudioStreamBasicDescription _audioFormat;

#ifdef USE_TWIRLING_VR_AUDIO
        void* _twirlingAudioPtr;
#endif
        
#ifdef DEBUG
    UILabel             *_messageLabel;
    NSTimeInterval      _debugStartTime;
    NSUInteger          _debugAudioStatus;
    NSDate              *_debugAudioStatusTS;
#endif

    CGFloat             _bufferedDuration;
    CGFloat             _minBufferedDuration;
    CGFloat             _maxBufferedDuration;
    CGFloat             _minBufferedDecodedDuration;
    CGFloat             _maxBufferedDecodedDuration;
    BOOL                _bufferring;
    
    BOOL                _savedIdleTimer;
    
    NSDictionary        *_parameters;
        
    //int                 _recordedAudioFrames;
    //int                 _decodedAudioFrames;
        
//    UIView* _presentView;
//    BOOL _isViewAppearing;
    
    AudioRingBuffer      _audioRingBuf;
        
    //double    preTimeInMs;
        
}

@property (readwrite) BOOL playing;
@property (readwrite) BOOL decoding;
@property (readwrite) BOOL packetsReading;
@property (readwrite) BOOL audioRecording;
@property (readwrite, strong) KxArtworkFrame *artworkFrame;

@property (nonatomic, strong) NSMutableArray* videoFrames;
//@property (nonatomic, strong) KxMovieDecoder* decoder;

@property (nonatomic, strong) NSMutableArray* subtitles;

@property (nonatomic, assign) CGFloat moviePosition;

@property (nonatomic, assign) float FPS;

@property (nonatomic, assign) int gyroDataBytesOffset;
@property (nonatomic, strong) NSData* gyroData;
@property (nonatomic, assign) int bytesPerGyroStringLine;
@property (nonatomic, assign) int gyroStringBytesSize;

@end

@implementation MVKxMovieViewController

@synthesize isUsedAsEncoder;
@synthesize isUsedAsCapturer;
@synthesize isFullScreenCapturer;
@synthesize isUsedAsVideoEditor;
@synthesize encoderQualityLevel;
@synthesize decoder = _decoder;
@synthesize moviePosition = _moviePosition;
@synthesize subtitles = _subtitles;
@synthesize glView = _glView;
@synthesize videoFrames = _videoFrames;

@synthesize isGlassMode;
@synthesize panoramaMode = _panoramaMode;

@synthesize isCameraGyroAdustEnabled;

@synthesize isLoadingViewVisible;

@synthesize encodingProgressChangedBlock;
@synthesize encodingDoneBlock;

@synthesize FPS;
@synthesize gyroDataBytesOffset;
@synthesize gyroData;
@synthesize bytesPerGyroStringLine;
@synthesize gyroStringBytesSize;
    
#ifdef ENCODING_WITHOUT_MYGLVIEW
@synthesize encoderRenderLoop = _encoderRenderLoop;
#endif
    
- (BOOL) isCameraGyroDataAvailable {
    return self.gyroStringBytesSize > 0;
}

- (void) setPanoramaMode:(int)panoramaMode {
    _panoramaMode = panoramaMode;
#ifdef ENCODING_WITHOUT_MYGLVIEW
    self.encoderRenderLoop.panoramaMode = panoramaMode;
#endif
    self.glView.panoramaMode = panoramaMode;
}

- (int) panoramaMode {
    return _panoramaMode;
}

- (void) setFOVRange:(int)initFOV maxFOV:(int)maxFOV minFOV:(int)minFOV {
    [self.glView.glRenderLoop setFOVRange:initFOV maxFOV:maxFOV minFOV:minFOV];
}
    
+ (void)initialize
{
    NSLog(@"initialize");
//    if (!gHistory)
//        gHistory = [NSMutableDictionary dictionary];
}

- (void) doInit {
    NSLog(@"doInit");
    self.isPresenting = YES;
    self.isGlassMode = NO;
//    self.displayMode = PanoramaDisplayModeStereoGraphic | PanoramaDisplayModeLUT;
    self.panoramaMode = PanoramaDisplayModeStereoGraphic;
    
    self.isCameraGyroAdustEnabled = NO;
    self.gyroDataBytesOffset = 0;
    self.gyroData = nil;
    self.bytesPerGyroStringLine = 36;
    self.gyroStringBytesSize = 0;
    self.FPS = 29.97f;
    _previousMoviePosition = 0;
    
    self.isLoadingViewVisible = YES;
    self.audioRecording = NO;
    NSLog(@"doInit audioRecording = NO");
    
    _audioRingBuf.Create(1024 * 1024);
    
    //preTimeInMs = 0;

//    _presentView = nil;
//    _isViewAppearing = NO;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    
    NSLog(@"initWithCoder");
    if (self = [super initWithCoder:aDecoder])
    {
        [self doInit];
    }
    return self;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    NSLog(@"initWithNibName %s", nibNameOrNil);
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        [self doInit];
    }
    return self;
}

- (id) initWithContentPath: (NSString *) path
                parameters: (NSDictionary *) parameters
{
    
    NSLog(@"initWithContentPath %f", path);
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self doInit];
        [self setContentPath:path parameters:parameters];
    }
    return self;
}

#ifdef DEBUG_VIDEOFRAME_LEAKING
//- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
//    if ([@"videoFrames.count" isEqualToString:keyPath])
//    {
//        NSLog(@"EAGLContext : MVKxMovieViewController $ observeValueForKeyPath : _videoFrames.count = %ld", (long)_videoFrames.count);
//    }
//}
#endif

static int s_liveObjects = 0;
static __weak id s_retainer = nil;

+ (NSRecursiveCondition*) sharedCondition {
    static NSRecursiveCondition* s_cond;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        s_cond = [[NSRecursiveCondition alloc] init];
    });
    return s_cond;
}

+ (int) decreaseLiveObjectsCount {
    int ret;
    [[self.class sharedCondition] lock];
    {
        ret = --s_liveObjects;
        NSLog(@"#VideoLeak# MVMediaPlayerViewController $ -- : liveObjects = %d", s_liveObjects);
        [[self.class sharedCondition] broadcast];
    }
    [[self.class sharedCondition] unlock];
    return ret;
}

+ (int) increaseLiveObjectsCount:(id)retainer {
    int ret;
    [[self.class sharedCondition] lock];
    {
        if (retainer != s_retainer)
        {
            s_retainer = retainer;
#ifdef WAIT_UNTIL_PREVIOUS_MEDIAPLAYERVIEWCONTROLLER_DEALLOC
            while (s_liveObjects > 0)
            {
                NSLog(@"#VideoLeak# MVMediaPlayerViewController $ ++ Wait : liveObjects = %d", s_liveObjects);
                [[self.class sharedCondition] wait];
            }
#endif
            ret = ++s_liveObjects;
            NSLog(@"#VideoLeak# MVMediaPlayerViewController $ ++ : liveObjects = %d", s_liveObjects);
        }
        else
        {
            ret = s_liveObjects;
        }
    }
    [[self.class sharedCondition] unlock];
    return ret;
}

- (void) dealloc
{
#ifdef DEBUG_VIDEOFRAME_LEAKING
//    [self removeObserver:self forKeyPath:@"videoFrames.count"];
#endif
    
    //NSLog(@"#Codec# MVKxMovieViewController dealloc # pause @ %@", self);
    [self pause];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_dispatchQueue) {
        // Not needed as of ARC.
        //        dispatch_release(_dispatchQueue);
        _dispatchQueue = NULL;
    }
    if (_dispatchQueueAudioRecord) {
        _dispatchQueueAudioRecord = NULL;
    }
    if (_dispatchQueueReadPackets) {
        _dispatchQueueReadPackets = NULL;
    }
    [self freeBufferedFrames]; //2016.3.3 spy
    
    LoggerStream(1, @"%@ dealloc", self);
    
    if ([self isKindOfClass:NSClassFromString(@"MVMediaPlayerViewController")] && _contentPath && _contentPath.length)
    {
        NSLog(@"#VideoLeak# MVMediaPlayerViewController $ dealloc");
        [MVKxMovieViewController decreaseLiveObjectsCount];
    }
}

- (BOOL)prefersStatusBarHidden { return YES; }

- (void) setContentPath:(NSString*)path
             parameters:(NSDictionary*)parameters {
    _contentPath = path;
                 
    NSLog(@"setContentPath %s",path);
    NSAssert(path.length > 0, @"empty path");
    if (!isUsedAsEncoder) {
        id<KxAudioManager> audioManager = [KxAudioManager audioManager];
        [audioManager activateAudioSession];
    }
                 
    _moviePosition = 0;
    //        self.wantsFullScreenLayout = YES;
    
    _parameters = parameters;
    
    __weak MVKxMovieViewController *weakSelf = self;
    KxMovieDecoder *decoder = [[KxMovieDecoder alloc] init];
                 //NSLog(@"#Codec# MVKxMovieViewController setContentPath # decoder = %@, @ %@", decoder, self);
    
    if (isUsedAsEncoder || isUsedAsVideoEditor) {
        [decoder setUsedForEncoder];
        _outputVideoFrameCount = 0;
        _firstVideoTimestamp = 0;
    }
                 
    decoder.interruptCallback = ^BOOL(){
        __strong MVKxMovieViewController *strongSelf = weakSelf;
        return NO;
        //return strongSelf ? [strongSelf interruptDecoder] : YES;
    };
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong typeof(self) pSelf = weakSelf;
        if (!pSelf) return;
        
        if ([pSelf isKindOfClass:NSClassFromString(@"MVMediaPlayerViewController")] && ![[[path lastPathComponent] stringByDeletingPathExtension] isEqualToString:SPLASH_MEDIA_NAME])
        {
            [MVKxMovieViewController increaseLiveObjectsCount:pSelf];
        }
        
        NSError *error = nil;
        [decoder openFile:path error:&error];

        if (decoder.fps > 0)
        {
            pSelf.FPS = decoder.fps;
        }

        if (![path hasPrefix:RTSP_URL_SCHEME] && ![path hasPrefix:RTMP_URL_SCHEME])
        {
            //NSLog(@"#Gyro# _gyroStringBytesSize#0 = %d", pSelf.gyroStringBytesSize);
            pSelf.gyroStringBytesSize = decoder.getGyroSize;
            //NSLog(@"#Gyro# _gyroStringBytesSize#1 = %d", pSelf.gyroStringBytesSize);
            if (0 != pSelf.gyroStringBytesSize)
            {
                pSelf.gyroData = [NSData dataWithBytes:decoder.getGyroData length:pSelf.gyroStringBytesSize];
                //NSLog(@"#Gyro# _bytesPerGyroStringLine#0 = %d", pSelf.bytesPerGyroStringLine);
                pSelf.bytesPerGyroStringLine = decoder.getGyroSizePerFrame;
                //NSLog(@"#Gyro# _bytesPerGyroStringLine#1 = %d", pSelf.bytesPerGyroStringLine);
//                ///For Debug:
//                int frames = pSelf.gyroStringBytesSize / pSelf.bytesPerGyroStringLine;
//                float matrix[9];
//                for (int i=0; i<frames; ++i)
//                {
//                    if ([self getGyroMatrix:matrix frameNumber:i])
//                    {
//                        NSLog(@"#Gyro# VideoGyroData[%d]: {%0.3f,%0.3f,%0.3f; %0.3f,%0.3f,%0.3f; %0.3f,%0.3f,%0.3f}", i, matrix[0],matrix[1],matrix[2],matrix[3],matrix[4],matrix[5],matrix[6],matrix[7],matrix[8]);
//                    }
//                }
            }
        }
        
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (weakSelf.gyroStringBytesSize > 0) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:GYRODATAAVAILABLE object:nil];
                }
                
                [weakSelf setMovieDecoder:decoder withError:error];
            });
//        return;///!!!For Debug 0301
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(self) pSelf = weakSelf;
        [pSelf showWaitViewInView:pSelf.glView];
    });
    
}

- (void) viewDidLoad {
    
    NSLog(@"viewDidLoad");
     LoggerStream(1, @"loadView");
    CGRect bounds = [[UIScreen mainScreen] applicationFrame];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.view.tintColor = [UIColor blackColor];
    
//    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
//    _activityIndicatorView.center = self.view.center;
//    _activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
//    [self.view addSubview:_activityIndicatorView];
    
#ifdef DEBUG
    CGFloat width = bounds.size.width;
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,40,width-40,40)];
    _messageLabel.backgroundColor = [UIColor clearColor];
    _messageLabel.textColor = [UIColor redColor];
    _messageLabel.hidden = YES;
    _messageLabel.font = [UIFont systemFontOfSize:14];
    _messageLabel.numberOfLines = 2;
    _messageLabel.textAlignment = NSTextAlignmentCenter;
    _messageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_messageLabel];
#endif
    
    if (_decoder) {
        [self setupPresentView];
    }
}

- (void)didReceiveMemoryWarning
{
    //NSLog(@"#Codec# MVKxMovieViewController didReceiveMemoryWarning #0 @ %@", self);
    [super didReceiveMemoryWarning];
 
    if (self.playing) {
        
        //NSLog(@"#Codec# MVKxMovieViewController didReceiveMemoryWarning # pause @ %@", self);
        [self pause];
        [self freeBufferedFrames];
        
        if (_maxBufferedDuration > 0) {
            
            _minBufferedDuration = _maxBufferedDuration = 0;
            [self play];
            
            LoggerStream(0, @"didReceiveMemoryWarning, disable buffering and continue playing @ %@", self);
            
        } else {
            
            // force ffmpeg to free allocated memory
            
            //NSLog(@"#Codec# MVKxMovieViewController didReceiveMemoryWarning closeFile1 @ %@", self);
            [_decoder closeFile];
            ///!!![_decoder openFile:nil error:nil];
        }
        
    } else {
        //NSLog(@"#Codec# MVKxMovieViewController didReceiveMemoryWarning closeFile2 @ %@", self);
        [self freeBufferedFrames];
        [_decoder closeFile];
        ///???[_decoder openFile:nil error:nil];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.isPresenting = YES;
    /*
    do
    {
        @synchronized (self)
        {
            if (!_presentView || _isViewAppearing)
            {
                _isViewAppearing = YES;
                break;
            }
            _isViewAppearing = YES;
        }
        [self didSetupPresentView:_presentView];
    }
    while (false);
    //*/
    if(!self.isFinishEncoder)
    {
        //NSLog(@"#Codec# MVKxMovieViewController viewDidAppear @ %@", self);
        LoggerStream(1, @"viewDidAppear");
        
        NSLog(@"viewDidAppear %@ _interrupted = NO", self);
        _interrupted = NO;///!!!qiudong
        
        if (self.presentingViewController)
            [self fullscreenMode:NO];///!!!YES
        
        //_savedIdleTimer = [[UIApplication sharedApplication] isIdleTimerDisabled];
        
        if (_decoder) {
            
            //NSLog(@"#Codec# MVKxMovieViewController viewDidAppear # restorePlay @ %@", self);
            if(!self.isStopPlay)
            {
                [self restorePlay];
            }else
            {
                self.isStopPlay = NO;
            }
        }
        else {
            //        [self showWaitView];
            //        [_activityIndicatorView startAnimating];
        }
        DoctorLog(@"#GLRenderLoopState# MVKxMovieViewController $ viewDidAppear will call startRendering @%lx MVGLView@%lx MVKxMovieViewController@%lx", (long)self.glView.glRenderLoop.hash, (long)self.glView.hash, (long)self.hash);
//        [self.glView.glRenderLoop stopOtherRenderLoopIfAny];
        [MVPanoRenderer lutPathOfSourceURI:_contentPath forceLUTStitching:NO pMadvEXIFExtension:NULL];
        [self.glView.glRenderLoop startRendering];
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    //NSLog(@"#Codec# MVKxMovieViewController viewWillDisappear #0 @ %@", self);
    self.isPresenting = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];

    [self dismissWaitView];
//    [_activityIndicatorView stopAnimating];
    if (_decoder) {
        //NSLog(@"#Codec# MVKxMovieViewController viewWillDisappear # pause @ %@", self);
        [self pause];
        /*
        if (_moviePosition == 0 || _decoder.isEOF)
            [gHistory removeObjectForKey:_decoder.path];
        else if (!_decoder.isNetwork)
            [gHistory setValue:[NSNumber numberWithFloat:_moviePosition]
                        forKey:_decoder.path];
        //*/
    }
    
    if (_fullscreen)
        [self fullscreenMode:NO];
        
    //[[UIApplication sharedApplication] setIdleTimerDisabled:_savedIdleTimer];
    
    _bufferring = NO;
    _interrupted = YES;
    DoctorLog(@"#GLRenderLoopState# MVKxMovieViewController $ viewWillDisappear will call MVGLView.willDisappear @%lx MVGLView@%lx MVKxMovieViewController@%lx", (long)self.glView.glRenderLoop.hash, (long)self.glView.hash, (long)self.hash);
    
#ifdef ENCODING_WITHOUT_MYGLVIEW
    if (!self.isUsedAsEncoder) {
        [self.glView willDisappear];
        //[GLRenderLoop stopCurrentRenderLoop];
    }
#else
    [self.glView.glRenderLoop stopRendering];
    //[GLRenderLoop stopCurrentRenderLoop];
#endif
    ///self.glView = nil;
    
    LoggerStream(1, @"kxMovieViewController viewWillDisappear %@", self);
    //_isViewAppearing = NO;
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    NSLog(@"viewWillAppear %@ _interrupted = NO", self);
    _interrupted = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;///!!!(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - public

-(void) play
{
    
    //NSLog(@"#Codec# MVKxMovieViewController play #0 @ %@", self);
    if (self.playing)
    {
        //NSLog(@"#Codec# MVKxMovieViewController play # return because self.playing=YES @ %@", self);
        return;
    }
    
    if (!_decoder.validVideo &&
        !_decoder.validAudio) {
        //NSLog(@"#Codec# MVKxMovieViewController play # return because !_decoder.validVideo || !_decoder.validAudio @ %@", self);
        return;
    }
    
    if (_interrupted)
    {
        //NSLog(@"#Codec# MVKxMovieViewController play # return because _interrupted @ %@", self);
        return;
    }

    self.playing = YES;
    NSLog(@"play %@ _interrupted = NO", self);
    _interrupted = NO;
    _tickCorrectionTime = 0;
    _tickCounter = 0;

#ifdef DEBUG
    _debugStartTime = -1;
#endif
    //NSLog(@"#Codec# MVKxMovieViewController play # asyncDecodeFrames @ %@", self);
    [self asyncDecodeFrames];

    __weak typeof(self) wSelf = self;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!wSelf || !wSelf.playing) return;
        [wSelf tick];
    });

    if (_decoder.validAudio)
        [self enableAudio:YES];

    _disableUpdateHUD = NO;
    
    [self didPlay];
    //NSLog(@"#Codec# MVKxMovieViewController play # didPlay @ %@", self);
    LoggerStream(1, @"play movie");
}

- (void) didPlay {
}

- (void) pause
{
    //NSLog(@"#Codec# MVKxMovieViewController pause #0 @ %@", self);
    if (!self.playing)
    {
        //NSLog(@"#Codec# MVKxMovieViewController pause # return because self.playing=NO @ %@", self);
        return;
    }

    self.playing = NO;
    //self.packetsReading = NO;
    //_interrupted = YES;
    if (self.isUsedAsEncoder && _decoder.validAudio) {
        while(_audioFrames.count > 0)
            usleep(1000);
        NSLog(@"close the audio recorded file");
    }
    [self enableAudio:NO];
    [self didPause];
    LoggerStream(1, @"pause movie");
    //NSLog(@"#Codec# MVKxMovieViewController pause # didPause @ %@", self);
}

- (void) stop {
    NSLog(@"#Codec# MVKxMovieViewController stop # pause @ %@", self);
    [self pause];
    NSLog(@"#Codec# MVKxMovieViewController stop freeBufferedFrames @ %@", self);
    [self freeBufferedFrames];
    //[_decoder closeFile];
}
    
//cwq 2016/03/16
- (void) changePlaySpeed:(EnumChangePlaySpeed)eChangePlaySpeed
{
    if(_decoder)
    {
        [_decoder changePlaySpeed:eChangePlaySpeed];
        //[self freeBufferedFrames];
        
 
        if (_decoder.validAudio)
        {
            @synchronized(_audioFrames)
            {
                    NSLog(@"CWQSPE dropAudioFrame = %ld", _audioFrames.count);
                [_audioFrames removeAllObjects];
                //_currentAudioFrame = nil;
            }
        }
  
        

    }
    
}
- (BOOL) isCanDoublePlaySpeed
{
    BOOL bCanDouble = FALSE;
    if(_decoder)
    {
        bCanDouble = [_decoder isCanDoublePlaySpeed];
    }
    return bCanDouble;
}
////
- (void) cancelEncoding {
    [self pause];
    NSLog(@"EAGLContext : ShotController viewWillDisappear freeBufferedFrames, glRenderLoop = %lx", self.glView.glRenderLoop.hash);
    [self freeBufferedFrames]; //2016.3.3 spy
    //[self.decoder closeFile];
    self.decoder = nil;
    
#ifdef ENCODING_WITHOUT_MYGLVIEW
    self.encoderRenderLoop.encodingError = [NSError errorWithDomain:@"MadvErrorEncodingCanceled" code:-2 userInfo:@{}];
    NSLog(@"#Bug2880# cancelEncoding : self.encoderRenderLoop.encodingError = %@", self.encoderRenderLoop.encodingError);
    [self.encoderRenderLoop stopRendering];
    NSLog(@"#Bug2880# cancelEncoding : 2");
    //[self.encoderRenderLoop stopEncoding:nil];
    NSLog(@"#Bug2880# cancelEncoding : 3");
    self.encoderRenderLoop = nil;
#endif

}

- (void) restartEncoding:(QualityLevel)encoderQuaLevel{
    self.encoderQualityLevel = encoderQuaLevel;
    NSLog(@"#BUG4875#TimeStamp# MVkxMovieViewController(0x%lx) $ restartEncoding # setContentPath, _decoder=0x%lx", (long)self.hash, (long)_decoder.hash);
    _decoder = nil;
    [self setContentPath:_contentPath parameters:_parameters];
    NSLog(@"#BUG4875#TimeStamp# MVkxMovieViewController(0x%lx) $ restartEncoding # play, _decoder=0x%lx", (long)self.hash, (long)_decoder.hash);
    [self play];
}

- (void) didPause {
    
}

- (void) setMoviePosition: (CGFloat) position
{
    
    NSLog(@"setMoviePosition position:%f", position);
    BOOL playMode = self.playing;
    
    self.playing = NO;
    [self enableAudio:NO];
    
    __weak typeof(self) wSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [wSelf updatePosition:position playMode:playMode];
    });
    
    _disableUpdateHUD = YES;
}

#pragma mark - private

- (void) setMovieDecoder: (KxMovieDecoder *) decoder
               withError: (NSError *) error
{
    
    NSLog(@"#BUG4875#TimeStamp# MVKxMovieViewController@0x%lx $ setMovieDecoder # decoder=0x%lx, prevDecoder=0x%lx, error=%@", (long)self.hash, (long)decoder.hash, (long)_decoder.hash, error);
    LoggerStream(2, @"setMovieDecoder");
            
    if (!error && decoder) {
        
        _decoder        = decoder;
        if(_dispatchQueue == nil) {
           _dispatchQueue  = dispatch_queue_create("KxMovie", DISPATCH_QUEUE_SERIAL);
           NSLog(@"_dispatchQueue created _dispatchQueue %@", _dispatchQueue);
        }
        if(_dispatchQueueAudioRecord == nil) {
            _dispatchQueueAudioRecord  = dispatch_queue_create("AudioRecord", DISPATCH_QUEUE_SERIAL);
            NSLog(@"_dispatchQueueAudioRecord created _dispatchQueueAudioRecord %@", _dispatchQueueAudioRecord);
        }
        if(_dispatchQueueReadPackets == nil) {
            _dispatchQueueReadPackets  = dispatch_queue_create("ReadPackets", DISPATCH_QUEUE_SERIAL);
            NSLog(@"_dispatchQueueReadPackets created _dispatchQueueReadPackets %@", _dispatchQueueReadPackets);
        }
        //dispatch_set_target_queue(_dispatchQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        _bufferedDuration = 0;
        _videoFrames    = [NSMutableArray array];
#ifdef DEBUG_VIDEOFRAME_LEAKING
//        [self addObserver:self forKeyPath:@"videoFrames.count" options:0 context:nil];
#endif
        _audioFrames    = [NSMutableArray array];
        
        if (_decoder.subtitleStreamsCount) {
            _subtitles = [NSMutableArray array];
        }
    
        if (_decoder.isNetwork) {
            if (_decoder.isRTSPLive) {
                NSLog(@"rtsp live buffer");
                _minBufferedDuration = RTSP_NETWORK_MIN_BUFFERED_DURATION;
                _maxBufferedDuration = RTSP_NETWORK_MAX_BUFFERED_DURATION;
            } else {
                NSLog(@"network buffer");
                _minBufferedDuration = NETWORK_MIN_BUFFERED_DURATION;
                _maxBufferedDuration = NETWORK_MAX_BUFFERED_DURATION;
                if (_decoder.frameHeight > 1152) {
                    _maxBufferedDuration = 0.6;
                }
            }
            
        } else {
            if (isUsedAsVideoEditor || isUsedAsEncoder) {
                _minBufferedDuration = 0;
                _maxBufferedDuration = LOCAL_MAX_BUFFERED_DURATION;
            } else {
                _minBufferedDuration = LOCAL_MIN_BUFFERED_DURATION;
                _maxBufferedDuration = LOCAL_MAX_BUFFERED_DURATION;
            }
        }
        
        if (!_decoder.validVideo)
            _minBufferedDuration *= 10.0; // increase for audio
        
        if (self.isUsedAsVideoEditor || self.isUsedAsEncoder) {
            _minBufferedDecodedDuration = 0.03;
            _maxBufferedDecodedDuration = 0.03; //buffer max 1 decoded frame when 30fps
        } else {
            _minBufferedDecodedDuration = 0.05;
            _maxBufferedDecodedDuration = 0.14; //buffer max 5 decoded frames when 30fps
        }
        
        // allow to tweak some parameters at runtime
        if (_parameters.count) {
            
            id val;
            
            val = [_parameters valueForKey: KxMovieParameterMinBufferedDuration];
            if ([val isKindOfClass:[NSNumber class]])
                _minBufferedDuration = [val floatValue];
            
            val = [_parameters valueForKey: KxMovieParameterMaxBufferedDuration];
            if ([val isKindOfClass:[NSNumber class]])
                _maxBufferedDuration = [val floatValue];
            
            val = [_parameters valueForKey: KxMovieParameterDisableDeinterlacing];
            if ([val isKindOfClass:[NSNumber class]])
                _decoder.disableDeinterlacing = [val boolValue];
            
            if (_maxBufferedDuration < _minBufferedDuration)
                _maxBufferedDuration = _minBufferedDuration * 2;
        }
        
        [_decoder setBufferDuration:_minBufferedDuration maxDuration:_maxBufferedDuration];
        
        LoggerStream(2, @"buffered limit: %.1f - %.1f", _minBufferedDuration, _maxBufferedDuration);
        
        if (self.isViewLoaded) {
            [self setupPresentView];
            
            [self dismissWaitView];
            /*
            if (_activityIndicatorView.isAnimating) {
                [_activityIndicatorView stopAnimating];
            }
             //*/
        }
        
    } else {
         if (self.isViewLoaded && self.view.window) {
             //[_activityIndicatorView stopAnimating];
             [self dismissWaitView];
             
             if (!_interrupted)
                 [self handleDecoderMovieError: error];
         }
    }
    
    [self didSetMovieDecoder:_decoder withError:error];
}

- (void) didSetMovieDecoder:(KxMovieDecoder*)decoder withError:(NSError*)error {
    
    NSLog(@"didSetMovieDecoder");
    if (!error && decoder)
    {
        if (self.isViewLoaded) {
            if(!self.isStopPlay)
            {
                [self restorePlay];
            }
        }
    }
}

- (void) restorePlay
{
    //NSLog(@"#Codec# MVKxMovieViewController restorePlay #0 @ %@", self);
    if (!_decoder)
    {
        //NSLog(@"#Codec# MVKxMovieViewController restorePlay # return0 @ %@", self);
        return;
    }
    else if (_decoder.isEOF && !self.isNewEditTime)
    {
        
        //NSLog(@"#Codec# MVKxMovieViewController restorePlay # EOF @ %@", self);
        [self updatePosition:0.f playMode:YES];
        /*if (_moviePosition >= _decoder.duration)
            [self updatePosition:0.f playMode:YES];
        else
            [self updatePosition:_moviePosition playMode:YES];*/
    }
    else
    {
         /*NSNumber *n = [gHistory valueForKey:_decoder.path];
         if (n)
         [self updatePosition:n.floatValue playMode:YES];
         else*/
        if (self.previousMoviePosition) {
            NSLog(@"#Codec# MVKxMovieViewController restorePlay with previousMoviePosition @ %@", self);
            [self updatePosition:self.previousMoviePosition playMode:YES];
            self.previousMoviePosition = 0;
        }
        else if (self.editStartTime >= 0 && self.isNewEditTime) {
            NSLog(@"#Codec# MVKxMovieViewController restorePlay # updatePosition starttime: %f @ %@", self.editStartTime, self);
            [self updatePosition:self.editStartTime playMode:YES];
            self.isNewEditTime = FALSE;
            //self.editStartTime = 0;
        }
        else
        {
            NSLog(@"#Codec# MVKxMovieViewController restorePlay # play @ %@", self);
            [self play];
        }
        
        //[self updatePosition:_moviePosition playMode:YES];
    }
}

    + (NSString*) outputVideoFileBaseName:(NSString*)contentPath qualityLevel:(QualityLevel)qualityLevel forExport:(BOOL)forExport {
        NSString* suffix = forExport ? @"_export" : @"_output";
        return [[[contentPath stringByDeletingPathExtension] lastPathComponent] stringByAppendingString:suffix];
    }
    
    + (NSString*) editorOutputVideoFileBaseName:(NSString*)contentPath {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:@"YYYYMMddHHmmss"];
        NSString* dateStr = [formatter stringFromDate:[NSDate date]];
        return [[[[contentPath stringByDeletingPathExtension] lastPathComponent] stringByAppendingString:@"_"] stringByAppendingString:dateStr];
    }
    
    + (NSString*) screenCaptureVideoFileBaseName:(NSString*)contentPath {
        NSString* baseName = [[contentPath stringByDeletingPathExtension] lastPathComponent];
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:@"YYYYMMddHHmmss"];
        NSString* dateStr = [formatter stringFromDate:[NSDate date]];
        return [NSString stringWithFormat:@"%@%@_%@", SCREEN_CAPTURE_FILENAME_PREFIX, baseName, dateStr];
    }
    
    + (NSString*) encodedFileBaseName:(NSString*)contentPath qualityLevel:(QualityLevel)qualityLevel forExport:(BOOL)forExport {
        NSString* outputVideoBaseName = [self.class outputVideoFileBaseName:contentPath qualityLevel:qualityLevel forExport:forExport];
        outputVideoBaseName = [GLRenderLoop outputVideoBaseName:outputVideoBaseName qualityLevel:(MVQualityLevel)qualityLevel];
        return [CycordVideoRecorder outputMovieFileBaseName:outputVideoBaseName];
    }
    
- (void) setupPresentView
{
    NSLog(@"EAGLContext : MVKxMovieViewController $ setupPresentView");
    MVGLView* presentView = _glView;
    CGRect bounds = self.view.bounds;
    NSString* lutPath = [MVPanoRenderer lutPathOfSourceURI:_contentPath forceLUTStitching:NO pMadvEXIFExtension:NULL];
    //DoctorLog(@"#3840x1920# lutPathOfSourceURI '%@' = '%@'", _contentPath, lutPath);
    VideoCaptureResolution videoCaptureResolution = (VideoCaptureResolution)_decoder.getVideoCaptureResolutionID;
    
    if (_decoder.validVideo) {
        [_decoder setupVideoFrameFormat:KxVideoFrameFormatYUV];
#ifdef USE_KXGLVIEW
        presentView = [[KxMovieGLView alloc] initWithFrame:bounds decoder:_decoder];
#else
        NSString* outputVideoBaseName = nil;
        if (self.isUsedAsVideoEditor)
        {
            outputVideoBaseName = [self.class editorOutputVideoFileBaseName:_contentPath];
        }
        else if (self.isUsedAsCapturer)
        {
            outputVideoBaseName = [self.class screenCaptureVideoFileBaseName:_contentPath];
        }
        else if (self.isUsedAsEncoder)
        {
            outputVideoBaseName = [self.class outputVideoFileBaseName:_contentPath qualityLevel:self.encoderQualityLevel forExport:self.isExport];
        }
#ifdef ENCODING_WITHOUT_MYGLVIEW
        if (self.isUsedAsEncoder)
        {
            if (self.encoderRenderLoop)
            {
                [self.encoderRenderLoop setLUTPath:lutPath lutSrcSizeL:CGSizeMake(DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT) lutSrcSizeR:CGSizeMake(DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT)];
                [self.encoderRenderLoop setVideoRecorder:outputVideoBaseName qualityLevel:(MVQualityLevel)self.encoderQualityLevel forCapturing:NO];
            }
            else
            {
                NSLog(@"EAGLContext : MVKxMovieViewController $ setupPresentView # self.encoderRenderLoop = %lx", self.encoderRenderLoop.hash);
                self.encoderRenderLoop = [[GLRenderLoop alloc] initWithDelegate:self lutPath:lutPath lutSrcSizeL:CGSizeMake(DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT) lutSrcSizeR:CGSizeMake(DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT) inputFrameSize:CGSizeMake(bounds.size.width * self.view.contentScaleFactor, bounds.size.height * self.view.contentScaleFactor) outputVideoBaseName:outputVideoBaseName encoderQualityLevel:(MVQualityLevel)self.encoderQualityLevel forCapturing:NO];
                self.encoderRenderLoop.encodingDoneBlock = self.encodingDoneBlock;
                self.encoderRenderLoop.encodingFrameBlock = self.encodingFrameBlock;
            }
            self.encoderRenderLoop.isFullScreenCapturing = self.isFullScreenCapturer;
            self.encoderRenderLoop.encodingError = nil;
            
            self.encoderRenderLoop.videoCaptureResolution = videoCaptureResolution;
            self.encoderRenderLoop.illusionVideoCaptureResolution = videoCaptureResolution;
        }
        else
#endif
        {
            if (presentView)
            {
                [presentView.glRenderLoop setLUTPath:lutPath lutSrcSizeL:CGSizeMake(DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT) lutSrcSizeR:CGSizeMake(DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT)];
                [presentView.glRenderLoop setVideoRecorder:outputVideoBaseName qualityLevel:(MVQualityLevel)self.encoderQualityLevel forCapturing:self.isUsedAsCapturer];
            }
            else
            {
                presentView = [[MVGLView alloc] initWithFrame:bounds lutPath:lutPath lutSrcSizeL:CGSizeMake(DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT) lutSrcSizeR:CGSizeMake(DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT) outputVideoBaseName:outputVideoBaseName encoderQualityLevel:(MVQualityLevel)self.encoderQualityLevel forCapturing:self.isUsedAsCapturer];
                DoctorLog(@"#GLRenderLoopState# MVKxMovieViewController $ setupPresentView#0 : @glRenderLoop%lx  @MVGLView%lx  @MVKxMovieViewController%lx", (long)presentView.glRenderLoop.hash, (long)presentView.hash, (long)self.hash);
            }
            presentView.glRenderLoop.isFullScreenCapturing = self.isFullScreenCapturer;
            presentView.glRenderLoop.encodingDoneBlock = self.encodingDoneBlock;
            presentView.glRenderLoop.encodingFrameBlock = self.encodingFrameBlock;
            if(self.isUsedAsCapturer)
                presentView.glRenderLoop.FPS = 29.97;
            else
                presentView.glRenderLoop.FPS = self.FPS;
            
            presentView.glRenderLoop.videoCaptureResolution = videoCaptureResolution;
            presentView.glRenderLoop.illusionVideoCaptureResolution = videoCaptureResolution;
            if (self.isViewLoaded && self.view.window && self.isPresenting)
            {DoctorLog(@"#GLRenderLoopState# MVKxMovieViewController $ setupPresentView will call startRendering @%lx presentView@%lx MVKxMovieViewController@%lx", (long)presentView.glRenderLoop.hash, (long)presentView.hash, (long)self.hash);
                [presentView.glRenderLoop startRendering];
            }
        }
        
        if (self.isUsedAsEncoder && _decoder.validAudio) {
            //*
            outputVideoBaseName = [GLRenderLoop outputVideoBaseName:outputVideoBaseName qualityLevel:(MVQualityLevel)self.encoderQualityLevel];
            outputVideoBaseName = [CycordVideoRecorder outputAudioTmpFileBaseName:outputVideoBaseName];
            /*/
            if (self.encoderQualityLevel == QualityLevel4K)
                outputVideoBaseName = [outputVideoBaseName stringByAppendingString:@"4K"];
            else if (self.encoderQualityLevel == QualityLevel1080)
                outputVideoBaseName = [outputVideoBaseName stringByAppendingString:@"1080"];
            outputVideoBaseName = [outputVideoBaseName stringByAppendingPathExtension:@"aac"]; write by spy change audio file name
            //*/
            _audioOutputPath = [NSString stringWithFormat:@"%@/%@", [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], outputVideoBaseName] ;
            
            if([_decoder getOriAudioChannel] == 4)
            {
                if([_decoder getAACFilePointer] == NULL)
                {
                    [_decoder createAACFilePointer:_audioOutputPath];
                }
            }
            else
            {
                // Describe format
                int kChannels = 2;
                unsigned int bytesPerSample = sizeof(float) * kChannels;
                
                memset(&_audioFormat, 0, sizeof(_audioFormat));
                _audioFormat.mFormatID = kAudioFormatMPEG4AAC;
                _audioFormat.mFormatFlags = kMPEG4Object_AAC_LC;
                //_audioFormat.mFormatID = kAudioFormatLinearPCM;
                //_audioFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat;
                _audioFormat.mSampleRate = 48000.00;
                _audioFormat.mFramesPerPacket = 1024;
                _audioFormat.mChannelsPerFrame = kChannels;
                //_audioFormat.mFramesPerPacket  = 1;
                //_audioFormat.mBytesPerFrame    = bytesPerSample;
                //_audioFormat.mBytesPerPacket   = bytesPerSample * _audioFormat.mFramesPerPacket;
                //_audioFormat.mBitsPerChannel    = 8 * sizeof(float);
                
                
                CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)_audioOutputPath, kCFURLPOSIXPathStyle, false);
                OSStatus status = ExtAudioFileCreateWithURL(destinationURL, kAudioFileAAC_ADTSType, &_audioFormat, NULL, kAudioFileFlags_EraseFile, &_audioFileRef); //kAudioFileCAFType //write by spy aac file
                //OSStatus status = ExtAudioFileCreateWithURL(destinationURL, kAudioFileCAFType, &_audioFormat, NULL, kAudioFileFlags_EraseFile, &_audioFileRef); //kAudioFileCAFType //write by spy aac file
                
                checkStatus(status);
                CFRelease(destinationURL);
                
                UInt32 size;
                AudioStreamBasicDescription clientFormat;
                clientFormat.mFormatID          = kAudioFormatLinearPCM;
                clientFormat.mFormatFlags       = kAudioFormatFlagIsFloat;
                clientFormat.mFramesPerPacket   = 1;
                clientFormat.mBytesPerFrame     = bytesPerSample;
                clientFormat.mBytesPerPacket    = clientFormat.mBytesPerFrame * clientFormat.mFramesPerPacket;
                clientFormat.mChannelsPerFrame  = kChannels;  // 1 indicates mono
                clientFormat.mBitsPerChannel    = 8 * sizeof(float);
                clientFormat.mSampleRate        = 48000.00;
                
                size = sizeof( clientFormat );
                status = ExtAudioFileSetProperty( _audioFileRef, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat ); //write by spy setting input format
                checkStatus(status);
            }
            
        }
#ifdef ENCODING_WITHOUT_MYGLVIEW
        if (self.isUsedAsEncoder)
        {
            self.encoderRenderLoop.panoramaMode = self.panoramaMode;
            
            KxVideoFrameFormat format = [_decoder getVideoFrameFormat];
            if (format == KxVideoFrameFormatYUV)
                self.encoderRenderLoop.isYUVColorSpace = YES;
            else
                self.encoderRenderLoop.isYUVColorSpace = NO;
            
            self.encoderRenderLoop.isGlassMode = self.isGlassMode;
            self.encoderRenderLoop.panoramaMode = self.panoramaMode;
            self.encoderRenderLoop.FPS = self.FPS;
            [self.encoderRenderLoop invalidateRenderbuffer];
            
//            [self.encoderRenderLoop stopOtherRenderLoopIfAny];
            //是否转成低码率
            if (self.isShareEncoder) {
                [self.encoderRenderLoop setShareMode];
            }
            //if (!_decoder.isShareBitrateContent) {
                [self.encoderRenderLoop startRendering];
            //}
        }
        else
#endif
        {
            presentView.panoramaMode = self.panoramaMode;
            
            KxVideoFrameFormat format = [_decoder getVideoFrameFormat];
            if (format == KxVideoFrameFormatYUV)
                presentView.isYUVColorSpace = YES;
            else
                presentView.isYUVColorSpace = NO;
        }
        
#endif
    }
#ifdef ENCODING_WITHOUT_MYGLVIEW
    if (self.isUsedAsEncoder)
    {
        if (!self.encoderRenderLoop) {
            LoggerVideo(0, @"fallback to use RGB video frame and UIKit");
            [_decoder setupVideoFrameFormat:KxVideoFrameFormatRGB];
            //_imageView = [[UIImageView alloc] initWithFrame:bounds];
            //_imageView.backgroundColor = [UIColor blackColor];
            self.encoderRenderLoop = [[GLRenderLoop alloc] initWithDelegate:self lutPath:lutPath lutSrcSizeL:CGSizeMake(DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT) lutSrcSizeR:CGSizeMake(DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT) inputFrameSize:CGSizeMake(bounds.size.width * self.view.contentScaleFactor, bounds.size.height * self.view.contentScaleFactor) outputVideoBaseName:nil encoderQualityLevel:(MVQualityLevel)self.encoderQualityLevel forCapturing:NO];
            self.encoderRenderLoop.isFullScreenCapturing = self.isFullScreenCapturer;
            self.encoderRenderLoop.encodingDoneBlock = self.encodingDoneBlock;
            self.encoderRenderLoop.encodingFrameBlock = self.encodingFrameBlock;
            self.encoderRenderLoop.panoramaMode = self.panoramaMode;
            self.encoderRenderLoop.isYUVColorSpace = NO;
            
            KxVideoFrameFormat format = [_decoder getVideoFrameFormat];
            if (format == KxVideoFrameFormatYUV)
                self.encoderRenderLoop.isYUVColorSpace = YES;
            else
                self.encoderRenderLoop.isYUVColorSpace = NO;
        }
        if(self.isUsedAsVideoEditor)
        {
            self.encoderRenderLoop.filterID = self.filterID;
        }
        
    }
    else
#endif
    {
        if (!presentView) {
            LoggerVideo(0, @"fallback to use RGB video frame and UIKit");
            [_decoder setupVideoFrameFormat:KxVideoFrameFormatRGB];
            //_imageView = [[UIImageView alloc] initWithFrame:bounds];
            //_imageView.backgroundColor = [UIColor blackColor];
            presentView = [[MVGLView alloc] initWithFrame:bounds lutPath:lutPath lutSrcSizeL:CGSizeMake(DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT) lutSrcSizeR:CGSizeMake(DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT) outputVideoBaseName:nil encoderQualityLevel:(MVQualityLevel)self.encoderQualityLevel forCapturing:self.isUsedAsCapturer];
            DoctorLog(@"#GLRenderLoopState# MVKxMovieViewController $ setupPresentView#1 : @glRenderLoop%lx  @MVGLView%lx  @MVKxMovieViewController%lx", (long)presentView.glRenderLoop.hash, (long)presentView.hash, (long)self.hash);
            presentView.glRenderLoop.isFullScreenCapturing = self.isFullScreenCapturer;
            presentView.glRenderLoop.encodingDoneBlock = self.encodingDoneBlock;
            presentView.glRenderLoop.encodingFrameBlock = self.encodingFrameBlock;
            presentView.panoramaMode = self.panoramaMode;
            presentView.isYUVColorSpace = NO;
            
            KxVideoFrameFormat format = [_decoder getVideoFrameFormat];
            if (format == KxVideoFrameFormatYUV)
                presentView.isYUVColorSpace = YES;
            else
                presentView.isYUVColorSpace = NO;
        }
    }
    
    if (_decoder.validVideo) {
        [self setupUserInteraction];
    } else {
        //_imageView.image = [UIImage imageNamed:@"kxmovie.bundle/music_icon.png"];
        //_imageView.contentMode = UIViewContentModeCenter;
    }
    
    self.view.backgroundColor = [UIColor blackColor];
    
    if (_glView != presentView)
    {
        if (_glView)
        {
            DoctorLog(@"#GLRenderLoopState# MVKxMovieViewController $ finishGLView will call _glView.willDisappear @%lx _glView@%lx presentView@%lx MVKxMovieViewController@%lx", (long)_glView.glRenderLoop.hash, (long)_glView.hash, (long)presentView.hash, (long)self.hash);
            [_glView willDisappear];
            _glView = nil;
        }
        _glView = (MVGLView*) presentView;
        _glView.isGlassMode = self.isGlassMode;
        _glView.panoramaMode = self.panoramaMode;
    }
    /*
    do
    {
        @synchronized (self)
        {
            if (_presentView || !_isViewAppearing)
            {
                _presentView = presentView;
                break;
            }
            _presentView = presentView;
        }
        [self didSetupPresentView:_presentView];
    }
    while (false);
     /*/
    if (presentView)
        [self didSetupPresentView:presentView];
     //*/
}

- (void) didSetupPresentView:(UIView*)presentView {
    
}

- (void) setupUserInteraction
{
    UIView * view = self.glView;
    view.userInteractionEnabled = YES;
    [self didSetupUserInteraction];
}

- (void) didSetupUserInteraction {
    
}

- (void) audioCallbackFillData:(float *) outData
                     numFrames:(UInt32) numFrames
//                   numChannels:(UInt32) numChannels
                        format:(AudioStreamBasicDescription)format
{
    UInt32 numChannels = format.mChannelsPerFrame;
    //NSLog(@"audioCallbackFillData numFrames:%d numChannels:%d", numFrames, numChannels);
    //fillSignalF(outData,numFrames,numChannels);
    //return;
    if (_bufferring) {
        memset(outData, 0, numFrames * numChannels * sizeof(float));
        return;
    }

    @autoreleasepool {
#ifdef USE_TWIRLING_VR_AUDIO
        if (NULL == _twirlingAudioPtr)
        {
//            ALOGE("#VRAudio# Will audioInit with (profileID, frameLength, channels, sampleRate) = (%d, %d, %d, %f)\n", 13, 512, numChannels, format.mSampleRate);
            _twirlingAudioPtr = audioInit(13, 512, numChannels, format.mSampleRate, false, false);
            audioSet(_twirlingAudioPtr, false, 0, false, true, 1.0);
        }
#endif
        KxAudioFrame* frame = nil;
        while (numFrames > 0) {
            
            if (!_currentAudioFrame) {
                
                @synchronized(_audioFrames) {
                    
                    NSUInteger count = _audioFrames.count;
                    
                    if (count > 0) {
                        
                        frame = _audioFrames[0];
                       
#ifdef DUMP_AUDIO_DATA
                        LoggerAudio(2, @"Audio frame position: %f", frame.position);
#endif
                        if (_decoder.validVideo) {
                        
                            const CGFloat delta = _moviePosition - frame.position;
                            
                            if (delta < -0.1 && !(_videoFrames.count == 0 && _decoder.isEOF)) {
                                
                                memset(outData, 0, numFrames * numChannels * sizeof(float));
#ifdef DEBUG
//                                LoggerStream(0, @"desync audio (outrun) wait %.4f %.4f", _moviePosition, frame.position);
                                _debugAudioStatus = 1;
                                _debugAudioStatusTS = [NSDate date];
#endif
                                break; // silence and exit
                            }
                            
                            [_audioFrames removeObjectAtIndex:0];
                            if (delta > 0.1 && count > 1)
                            {
#ifdef DEBUG
//                                LoggerStream(0, @"desync audio (lags) skip %.4f %.4f", _moviePosition, frame.position);
                                _debugAudioStatus = 2;
                                _debugAudioStatusTS = [NSDate date];
#endif
                                continue;
                            }
                        }
                        else
                        {
                            [_audioFrames removeObjectAtIndex:0];
                            _moviePosition = frame.position;
                            _bufferedDuration -= frame.duration;
                        }

                        _currentAudioFramePos = 0;
                        _currentAudioFrame = frame.samples;
                        _inputAudioChannels = frame.channels;
                    }
                }
            }
            
            if (_currentAudioFrame) {
                const void *bytes = (Byte *)_currentAudioFrame.bytes + _currentAudioFramePos;
                const NSUInteger bytesLeft = (_currentAudioFrame.length - _currentAudioFramePos);
                const NSUInteger frameSizeOf = numChannels * sizeof(float);
                const NSUInteger framesToCopy = MIN(numFrames * frameSizeOf, bytesLeft) / frameSizeOf;
                const NSUInteger bytesToCopy = framesToCopy * frameSizeOf;
#ifdef USE_TWIRLING_VR_AUDIO
                processAudioFrameWithTwirling(outData, (const float*)bytes, _twirlingAudioPtr, format, (int)framesToCopy, _inputAudioChannels);
                //memcpy(outData, bytes, bytesToCopy);
#else
                memcpy(outData, bytes, bytesToCopy);
#endif
                numFrames -= framesToCopy;
                outData += framesToCopy * numChannels;
                
                if (bytesToCopy < bytesLeft)
                    _currentAudioFramePos += bytesToCopy;
                else
                    _currentAudioFrame = nil;                
                
            } else {
                
                memset(outData, 0, numFrames * numChannels * sizeof(float));
                //LoggerStream(1, @"silence audio");
#ifdef DEBUG
                _debugAudioStatus = 3;
                _debugAudioStatusTS = [NSDate date];
#endif
                break;
            }
        }
    }
}

    - (void) audioCallbackFillDataRecord
    {
        
        //NSLog(@"audioCallbackFillDataRecord");
        //fillSignalF(outData,numFrames,numChannels);
        //return;
        UInt32 numFrames = 0;
        UInt32 numChannels = 2;
        //UInt32 numChannels = 4;
        
        if (_bufferring) {
            return;
        }
        
        @autoreleasepool {
            
            while (!(_audioFrames.count == 0 && _videoFrames.count == 0 && _decoder.isEOF) && _audioRecording) {
                
                //NSLog(@"numFrames %d ac: %lu vc:%lu eof:%d audioRecording:%d", numFrames, (unsigned long)_audioFrames.count, (unsigned long)_videoFrames.count, _decoder.isEOF, _audioRecording);
                if (!_currentAudioFrame) {
                    
                    @synchronized(_audioFrames) {
                        
                        NSUInteger count = _audioFrames.count;
                        
                        if (count > 0) {
                            
                            KxAudioFrame *frame = _audioFrames[0];
                            
#ifdef DUMP_AUDIO_DATA
                            LoggerAudio(2, @"Audio frame position: %f", frame.position);
#endif
                            if (_decoder.validVideo) {
                                
                                [_audioFrames removeObjectAtIndex:0];
                                //NSLog(@"audioFrames--: %lu", _audioFrames.count);
                            } else {
                                
                                [_audioFrames removeObjectAtIndex:0];
                                _moviePosition = frame.position;
                                _bufferedDuration -= frame.duration;
                            }
                            frame.timestamp = frame.position;
                            if (self.isUsedAsVideoEditor && (_editEndTime - _editStartTime) > 0) {
                                //NSLog(@"audiorecord timestamp(before adjust) = %f", frame.timestamp);
                                frame.timestamp -= _editStartTime;
                            }
                            
                            NSLog(@"audiorecord timestamp = %f", frame.timestamp);
                            
                            _currentAudioFrame = frame.samples;
                            numFrames = frame.samples.length / (sizeof(float) * numChannels);
                            
                            //write by spy
                            _audioRingBuf.Write((unsigned char*)_currentAudioFrame.bytes, (unsigned int)_currentAudioFrame.length);
                        }
                    }
                }
                
                if (_currentAudioFrame && numFrames > 0) {
                    //wrtie by spy
                    int audioframesize = numFrames * numChannels  * sizeof(float);
                    //int audioframesize = numFrames * numChannels  * sizeof(int16_t);
                    
                    float pcm[numFrames * numChannels];
                    //int16_t pcm[numFrames * numChannels];
                    
                    if (_audioRingBuf.GetReadSize() < audioframesize) {
                        NSLog(@"getReadSize %d",_audioRingBuf.GetReadSize());
                    }
                    // while (_audioRingBuf.GetReadSize() > 0)
                    if (_audioRingBuf.GetReadSize() > 0)
                    {
                        _audioRingBuf.Read((unsigned char*)&pcm[0], audioframesize);
                        [self recordAudioFrame: numFrames channels: numChannels buf: (float*)&pcm[0]];
                        //[self recordAudioFrame: numFrames channels: numChannels buf: (int16_t*)&pcm[0]];
                        //NSLog(@"_recordedAudioFrames: %d", ++_recordedAudioFrames);
                    }
                    _currentAudioFrame = nil;
                    numFrames = 0;
                }
            }
            NSLog(@"exited the loop: numFrames %d ac: %lu vc:%lu eof:%d audioRecording:%d", numFrames, (unsigned long)_audioFrames.count, (unsigned long)_videoFrames.count, _decoder.isEOF, _audioRecording);
        }
    }

- (void) enableAudio: (BOOL) on
{
    NSLog(@"enableAudio %d", on);
    
    if (!isUsedAsEncoder) {
        id<KxAudioManager> audioManager = [KxAudioManager audioManager];
                
        if (on && _decoder.validAudio) {
            __weak typeof(self) wSelf = self;
            audioManager.outputBlock = ^(float *outData, UInt32 numFrames, /*UInt32 numChannels, */AudioStreamBasicDescription format) {
                [wSelf audioCallbackFillData: outData numFrames:numFrames /*numChannels:numChannels */format:format];
            };
                    
            [audioManager play];
            LoggerAudio(2, @"audio device smr: %d fmt: %d chn: %d",
                            (int)audioManager.samplingRate,
                            (int)audioManager.numBytesPerSample,
                            (int)audioManager.numOutputChannels);
                
        } else {
            [audioManager pause];
            audioManager.outputBlock = nil;
#ifdef USE_TWIRLING_VR_AUDIO
            audioRelease(_twirlingAudioPtr);
            _twirlingAudioPtr = NULL;
//            ALOGE("#VRAudio# Did audioRelease()\n");
#endif
        }
    } else {
        
        __weak MVKxMovieViewController *weakSelf = self;
        __weak KxMovieDecoder *weakDecoder = _decoder;
        
        if (on && _decoder.validAudio && !weakSelf.audioRecording) {
            weakSelf.audioRecording = YES;
            dispatch_async(_dispatchQueueAudioRecord, ^{
                NSLog(@"usedAsRecorder enableAudio : In _dispatchQueue");
                
                __strong MVKxMovieViewController *strongSelf = weakSelf;
                if (!strongSelf || !strongSelf.playing)
                {
                    NSLog(@"usedAsRecorder enableAudio : Exit #1");
                    return;
                }
                
                while (strongSelf.audioRecording) {
                    @autoreleasepool {
                         [strongSelf audioCallbackFillDataRecord];
                    }
                }
                ExtAudioFileDispose(_audioFileRef);
                NSLog(@"usedAsRecorder exit enableAudio loop");
            });
        } else {
            weakSelf.audioRecording = NO;
            NSLog(@"usedAsRecorder enableAudio No: audioRecording = No");
        }
    }
}

- (BOOL) addFrames: (NSArray *)frames
{
    //NSLog(@"addFrames");
    if (_decoder.validVideo) {
        
        @synchronized(_videoFrames) {
            if (!self.playing)
            {
                [((NSMutableArray*) frames) removeAllObjects];
                return NO;
            }
            
            for (KxMovieFrame *frame in frames)
                if (frame.type == KxMovieFrameTypeVideo) {
                    [_videoFrames addObject:frame];
#ifdef DEBUG_VIDEOFRAME_LEAKING
                    //NSLog(@"VideoLeak : _videoFrames addObject, count = %d", (int)_videoFrames.count);
#endif
                    _bufferedDuration += frame.duration;
                }
        }
    }
    
    if (_decoder.validAudio) {
        
        @synchronized(_audioFrames) {
            
            for (KxMovieFrame *frame in frames)
                if (frame.type == KxMovieFrameTypeAudio) {
                    [_audioFrames addObject:frame];
                    //if (self.isUsedAsEncoder) {
                        //NSLog(@"audioFrames++: %lu", _audioFrames.count);
                        //NSLog(@"_decodedAudioFrames: %d", ++_decodedAudioFrames);
                    //}
                    if (!_decoder.validVideo)
                    {
                        _bufferedDuration += frame.duration;
                    }
                }
        }
        
        if (!_decoder.validVideo) {
            
            for (KxMovieFrame *frame in frames)
                if (frame.type == KxMovieFrameTypeArtwork)
                    self.artworkFrame = (KxArtworkFrame *)frame;
        }
    }
    
    if (_decoder.validSubtitles) {
        
        @synchronized(_subtitles) {
            
            for (KxMovieFrame *frame in frames)
                if (frame.type == KxMovieFrameTypeSubtitle) {
                    [_subtitles addObject:frame];
                }
        }
    }
    
    return self.playing && _bufferedDuration < _maxBufferedDecodedDuration;
}

- (BOOL) decodeFrames
{
    
    //NSLog(@"decodeFrames");
    //NSAssert(dispatch_get_current_queue() == _dispatchQueue, @"bugcheck");
    
    NSArray *frames = nil;
    
    if (_decoder.validVideo ||
        _decoder.validAudio) {
        
        frames = [_decoder decodeFrames:0];
    }
    
    if (frames.count) {
        return [self addFrames: frames];
    }
    return NO;
}

- (void) asyncReadPackets
{
    //NSLog(@"asyncReadPackets");
    if (self.packetsReading || _decoder.isEOF)
    {
        NSLog(@"asyncReadPackets : Exit #0 packetsReading:%d EOF:%d",self.packetsReading,_decoder.isEOF);
        return;
    }
    
    __weak MVKxMovieViewController *weakSelf = self;
    __weak KxMovieDecoder *weakDecoder = _decoder;
    
    const CGFloat duration = _decoder.isNetwork ? .0f : 0.1f;///!!!
    
    self.packetsReading = YES;
    //NSLog(@"asyncReadPackets : Set packetsReading = YES");
    dispatch_async(_dispatchQueueReadPackets, ^{
        //NSLog(@"asyncReadPackets : In _dispatchQueue");
        {
            __strong MVKxMovieViewController *strongSelf = weakSelf;
            if (!strongSelf || !strongSelf.playing)
            {
                NSLog(@"asyncReadPackets : Exit #1");
                return;
            }
        }
        
        BOOL good = YES;
        while (good) {
            good = NO;
            @autoreleasepool {
                __strong KxMovieDecoder *decoder = weakDecoder;
                if (decoder && (decoder.validVideo || decoder.validAudio)) {
                    good = [decoder readPackets:duration];
                    //NSLog(@"asyncReadPackets result: %d", good);
                } else {
                    NSLog(@"KxMovieViewController :: asyncReadPackets : decoder no");
                }
                
                if (decoder.getBufferedPacketDuration >= _maxBufferedDuration || !self.playing)
                    good = NO;
                //NSLog(@"KxMovieViewController :: asyncReadPackets : playing%d",self.playing);
            }
        }
        //NSLog(@"exit asyncReadPackets loop");
        {
            __strong MVKxMovieViewController *strongSelf = weakSelf;
            if (strongSelf)
            {
                //NSLog(@"asyncReadPackets : Set packetsReading = NO");
                strongSelf.packetsReading = NO;
            }
        }
    });
}
    
- (void) asyncDecodeFrames
{
    //NSLog(@"asyncDecodeFrames");
    if (self.decoding)
    {
        //NSLog(@"asyncDecodeFrames : Exit #0");
        return;
    }
    
    __weak MVKxMovieViewController *weakSelf = self;
    __weak KxMovieDecoder *weakDecoder = _decoder;
    
    const CGFloat duration = (self.isUsedAsEncoder || self.isUsedAsVideoEditor)? .0f : _decoder.isNetwork ? .0f : 0.1f;///!!!
    
    self.decoding = YES;
    dispatch_async(_dispatchQueue, ^{
        //NSLog(@"asyncDecodeFrames : In _dispatchQueue");
        {
            __strong MVKxMovieViewController *strongSelf = weakSelf;
            if (!strongSelf || !strongSelf.playing)
            {
                //NSLog(@"asyncDecodeFrames : Exit #1");
                return;
            }
        }
        
        BOOL good = YES;
        while (good) {
            good = NO;
            
            @autoreleasepool {
                __strong KxMovieDecoder *decoder = weakDecoder;
                if (decoder && (decoder.validVideo || decoder.validAudio)) {
                    /*if (!_decoder.isNetwork) {
                        if ((self.isUsedAsVideoEditor || self.isUsedAsEncoder) &&
                            (_videoFrames.count >= 1 * self.FPS/29.0 || _audioFrames.count >= 4)) {
                            NSLog(@"skip dec rec");
                            continue;
                        } else if ([[UIDevice currentDevice] systemVersion].floatValue == 11 && (
                                    _videoFrames.count >= 5 * self.FPS/29.0 )){
                            NSLog(@"iOS 11 skip dec");
                            continue;
                        }
                    }*/
                        
                    NSArray *frames = [decoder decodeFrames:duration];
                    //NSLog(@"asyncDecodeFrames : frames.count = %ld", frames.count);
                    if (frames.count) {
                        __strong MVKxMovieViewController *strongSelf = weakSelf;
                        if (strongSelf)
                        {
                            //NSLog(@"MVKxMovieViewController :: asyncDecodeFrames : addFrames");
                            good = [strongSelf addFrames:frames];
                            //NSLog(@"MVKxMovieViewController :: asyncDecodeFrames : addFrames good=%d", good);
                        } else {
                            //NSLog(@"MVKxMovieViewController :: asyncDecodeFrames : addFrames no");
                        }
                    }
                } else {
                    //NSLog(@"MVKxMovieViewController :: asyncDecodeFrames : decoder no");
                }
            }
        }
        //NSLog(@"exit asyncdecode loop");
                
        {
            __strong MVKxMovieViewController *strongSelf = weakSelf;
            if (strongSelf)
            {
                //NSLog(@"asyncDecodeFrames : Set decoding = NO");
                strongSelf.decoding = NO;
            }
        }
    });
}

- (void) didPlayOver {
    if (self.isUsedAsEncoder && _decoder.validAudio) {
        while(_audioFrames.count > 0)
            usleep(1000);
        [self enableAudio:NO];
        NSLog(@"close the audio recorded file");
    }
}

- (void) tick
{
    //NSLog(@"KxMovieViewController :: tick");
    
    //for buffered packets
    //NSLog(@"buffered packet duration: %f, count:%d",_decoder.getBufferedPacketDuration,_decoder.getBufferedPacketCount);
    if (_bufferring && (( _decoder.getBufferedPacketDuration > _minBufferedDuration) || _decoder.isEOF)) {
        
        _tickCorrectionTime = 0;
        _bufferring = NO;
        [self dismissWaitView];
    }
    
    if (self.playing) {
        NSUInteger leftPackets = _decoder.getBufferedPacketCount;
        
        if (0 == leftPackets && !_decoder.isEOF) {
            
            if (_minBufferedDuration > 0 && !_bufferring) {
                _bufferring = YES;
                NSLog(@"tick showWaitView");
                [self showWaitViewInView:self.glView];
            }
        }
        
        //for video-edit
        //NSLog(@"_decoder position %f editStartTime %f editEndTime %f", _decoder.position, _editStartTime, _editEndTime);
        if( _editEndTime > 0 && _decoder.position >= (_editEndTime - 0.1) //){
           && (!_decoder.validAudio || (_decoder.validAudio && _decoder.positionAudio >= (_editEndTime - 0.1)))) {
            NSLog(@"tick play over 2");
            [self pause];
            [self updateHUD];
            if ([self respondsToSelector:@selector(didPlayOver)]) {
                [self didPlayOver];
            }
            return;
        }
        
        if (!leftPackets ||
            !((_decoder.getBufferedPacketDuration) > _minBufferedDuration)) {
            // //NSLog(@"#Codec# MVKxMovieViewController tick # asyncDecodeFrames @ %@", self);
            [self asyncReadPackets];
        }
    }
    
    
    //for decoded frames
    //NSLog(@"decoded vc: %d, ac:%d", _videoFrames.count, _audioFrames.count);

    
    CGFloat interval = 0;
    if (!_bufferring)
        interval = [self presentFrame];
    
    if (self.playing) {
        NSUInteger leftFrames =
        (_decoder.validVideo ? _videoFrames.count : 0) +
        (_decoder.validAudio ? _audioFrames.count : 0) +
        (_decoder.getBufferedPacketCount);
        
        if (0 == leftFrames) {
            if (_decoder.isEOF) {
                //NSLog(@"MVKxMovieViewController tick pause");
                
                [self pause];
                [self updateHUD];
                if ([self respondsToSelector:@selector(didPlayOver)]) {
                    NSLog(@"tick play over 1");
                    [self didPlayOver];
                }
                return;
            }
        }
        
        //for video-edit
        //NSLog(@"_decoder position %f editStartTime %f editEndTime %f", _decoder.position, _editStartTime, _editEndTime);
        if( _editEndTime > 0 && _decoder.position >= (_editEndTime - 0.1) //){
            && (!_decoder.validAudio || (_decoder.validAudio && _decoder.positionAudio >= (_editEndTime - 0.1)))) {
            NSLog(@"tick play over 2");
            [self pause];
            [self updateHUD];
            if ([self respondsToSelector:@selector(didPlayOver)]) {
                [self didPlayOver];
            }
            return;
        }
        
        if (!leftFrames ||
            //!(_bufferedDuration > _minBufferedDuration)) {
            !(_bufferedDuration > _minBufferedDecodedDuration)) {
            //NSLog(@"#Codec# KxMovieViewController tick # asyncDecodeFrames @ %@", self);
            [self asyncDecodeFrames];
        }
        
        const NSTimeInterval correction = [self tickCorrection];
        const NSTimeInterval time = MAX(interval + correction, 0.01);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        __weak typeof(self) wSelf = self;
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (!wSelf || !wSelf.playing) return;
            [wSelf tick];
        });
    }
    
    if ((_tickCounter++ % 3) == 0) {
        [self updateHUD];
    }
    
    int percent = 0;
    if ((_editEndTime - _editStartTime) > 0) {
        percent = roundf((_decoder.position - _editStartTime) * 100 / (_editEndTime - _editStartTime));
    }
    else {
        percent = roundf(_decoder.position * 100 / _decoder.duration);
    }
    [self didPlayProgressChanged:percent];
}

- (void) dismissWaitView {
    NSLog(@"dismissWaitView");
    [self dismissActivityIndicatorView];
}

- (void) showWaitViewInView:(UIView *)view {
    if (!self.isLoadingViewVisible)
    {
        NSLog(@"showWaitView bypassed!");
        return;
    }
    NSLog(@"showWaitView");
    if (!self.isUsedAsEncoder || self.isShare) {
        [self showActivityIndicatorViewInView:view];
    }
    
    //[_activityIndicatorView startAnimating];
}

- (CGFloat) tickCorrection
{
    
    //NSLog(@"tickCorrection");
    if (_bufferring)
        return 0;
    
    const NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    if (!_tickCorrectionTime) {
        
        _tickCorrectionTime = now;
        _tickCorrectionPosition = _moviePosition;
        return 0;
    }
    
    NSTimeInterval dPosition = _moviePosition - _tickCorrectionPosition;
    NSTimeInterval dTime = now - _tickCorrectionTime;
    NSTimeInterval correction = dPosition - dTime;
    
    if ((_tickCounter % 200) == 0)
        LoggerStream(1, @"tick correction %.4f", correction);
    
    if (correction > 1.f || correction < -1.f) {
        
        LoggerStream(1, @"tick correction reset %.2f", correction);
        correction = 0;
        _tickCorrectionTime = 0;
    }
    
    return correction;
}

- (CGFloat) presentFrame
{
    
   // NSLog(@"presentFrame");
    CGFloat interval = 0;
    
    if (_decoder.validVideo) {
        
        KxVideoFrame *frame;
        //NSLog(@"isUsedAsEncoder %d isUsedAsCapturer %d", self.isUsedAsEncoder, self.isUsedAsCapturer);
        if (self.isUsedAsEncoder && !self.isUsedAsCapturer && self.encoderRenderLoop && !self.encoderRenderLoop.readyToRenderNextFrame)
        {
            NSLog(@"rendering loop busy, skip to wait");
        }
        else
        {
            @synchronized(_videoFrames) {
                if (_videoFrames.count > 0)
                {
                
                    frame = _videoFrames[0];
                    if (self.isUsedAsVideoEditor && (_editEndTime - _editStartTime) > 0)
                        frame.timestamp -= _editStartTime * 1000;
                    [_videoFrames removeObjectAtIndex:0];
                    if (self.isUsedAsVideoEditor)
                    {
                        NSLog(@"#FrameLoss#0 video present timestamp: %f", frame.timestamp);
                    }
#ifdef DEBUG_VIDEOFRAME_LEAKING
                    //NSLog(@"VideoLeak : _videoFrames removeObject, count = %d", (int)_videoFrames.count);
#endif
                    _bufferedDuration -= frame.duration;
                }
            }
        
            if (frame)
                interval = [self presentVideoFrame:frame];
        }
        
    } else if (_decoder.validAudio) {

        //interval = _bufferedDuration * 0.5;
                
        if (self.artworkFrame) {
#ifdef ENCODING_WITHOUT_MYGLVIEW
            if (self.isUsedAsEncoder)
                [self.encoderRenderLoop draw:[self.artworkFrame asImage] withLUTStitching:NO gyroMatrix:nil videoCaptureResolution:FPS30_3456x1728];
            else
#endif
                [_glView.glRenderLoop draw:[self.artworkFrame asImage] withLUTStitching:NO gyroMatrix:nil videoCaptureResolution:FPS30_3456x1728];
            //_imageView.image = [self.artworkFrame asImage];
            self.artworkFrame = nil;
        }
    }

    if (_decoder.validSubtitles)
        [self presentSubtitles];
    
#ifdef DEBUG
    if (self.playing && _debugStartTime < 0)
        _debugStartTime = [NSDate timeIntervalSinceReferenceDate] - _moviePosition;
#endif

    return interval;
}

#ifdef DEBUG_GYRO
static FILE* gyroFile = NULL;
static int frameCount = 0;
#endif

    - (NSInteger) frameNumberOfVideoTime:(float)seconds maxFrameNumber:(int)maxFrameNumber {
        NSInteger frameNumber = roundf(seconds * self.FPS);
        if (self.gyroStringBytesSize > 0)
        {
            frameNumber += GyroDataFrameNumberOffset;
            if (frameNumber < 0)
                frameNumber = 0;
            if (frameNumber * self.bytesPerGyroStringLine + self.gyroDataBytesOffset >= self.gyroData.length)
            {
                frameNumber = (int) ((self.gyroData.length - self.gyroDataBytesOffset) / self.bytesPerGyroStringLine - 1);
                if (frameNumber < 0)
                    return -1;
            }
            if (maxFrameNumber > 0 && frameNumber > maxFrameNumber)
                return -1;
            
            if (frameNumber >= 0)
            {
                frameNumber += GyroDataFrameNumberOffset;
                if (frameNumber < 0)
                    frameNumber = 0;
                if (frameNumber * self.bytesPerGyroStringLine + self.gyroDataBytesOffset >= self.gyroData.length)
                {
                    frameNumber = (int)((self.gyroData.length - self.gyroDataBytesOffset) / self.bytesPerGyroStringLine - 1);
                    if (frameNumber < 0)
                        return -1;
                }
                
                return frameNumber;
            }
        }
        return -1;
    }
    
    - (NSData*) gyroDataOfFrameNumber:(NSInteger)frameNumber {
        if (frameNumber < 0)
            return nil;
        
        float matrix[9];
        BOOL succ = [self getGyroMatrix:matrix frameNumber:frameNumber];
        if (succ)
        {
            NSData* gyroData = [[NSData alloc] initWithBytes:matrix length:sizeof(matrix)];
            return gyroData;
        }
        
        return nil;
    }

- (CGFloat) presentVideoFrame: (KxVideoFrame *) frame
{
    NSInteger frameNumber = [self frameNumberOfVideoTime:(frame.timestamp / 1000.f + _editStartTime) maxFrameNumber:-1];
    frame.frameNumber = frameNumber;
    if ((self.isUsedAsEncoder || self.isUsedAsVideoEditor) && self.decoder.getOriAudioChannel >= 4)
    {
        self.isCameraGyroAdustEnabled = NO;
    }
    if (self.isCameraGyroAdustEnabled)
    {
        NSData* gyroData = [self gyroDataOfFrameNumber:frameNumber];
        frame.gyroData = gyroData;
        //float* pMatrix = (float*) gyroData.bytes;
        //printf("\n#Gyro# presentVideoFrame: KxVideoFrameCVBuffer=%lx, frame=#%d, frame.timestamp=%f, matrix={%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f}\n", (long)frame.hash, (int)frameNumber, frame.timestamp, pMatrix[0],pMatrix[1],pMatrix[2],pMatrix[3],pMatrix[4],pMatrix[5],pMatrix[6],pMatrix[7],pMatrix[8]);
    }
    
#ifdef ENCODING_WITHOUT_MYGLVIEW
    if (self.isUsedAsEncoder)
    {
        if (self.encoderRenderLoop) {
            [self.encoderRenderLoop render:frame];///!!!For Debug #VideoLeak# by QD 20170124
            if(_outputVideoFrameCount == 0) {
                _firstVideoTimestamp = frame.position * 1000;
            }
            _outputVideoFrameCount++;
#ifdef DEBUG_GYRO
            if (NULL == gyroFile)
            {
                NSString* gyroFilePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:[NSString stringWithUTF8String:GyroFileName]];
                gyroFile = fopen(gyroFilePath.UTF8String, "r+");
            }
            if (NULL != gyroFile)
            {
                float matrix[9];
                fscanf(gyroFile, "%f,%f,%f,%f,%f,%f,%f,%f,%f", &matrix[0], &matrix[1], &matrix[2], &matrix[3], &matrix[4], &matrix[5], &matrix[6], &matrix[7], &matrix[8]);
                //NSLog(@"GyroMatrix : %f,%f,%f,%f,%f,%f,%f,%f,%f", matrix[0], matrix[1], matrix[2], matrix[3], matrix[4], matrix[5], matrix[6], matrix[7], matrix[8]);
                [self.encoderRenderLoop setGyroMatrix:matrix rank:3];
            }
#endif
        }
    }
    else
#endif
    {
        if (_glView) {
            //DoctorLog(@"#GLRenderLoopState# presentVideoFrame");
            [_glView.glRenderLoop render:frame];///!!!For Debug #VideoLeak# by QD 20170124
            
            //NSTimeInterval time=[[NSDate date] timeIntervalSince1970]*1000;
            //double timeInMs = time;      //NSTimeInterval返回的是double类型
            //double drawTimeInMs = 0;
            //if(preTimeInMs != 0) {
            //    drawTimeInMs = timeInMs - preTimeInMs;
            //    NSLog(@"render %f", drawTimeInMs);
            //}
            //preTimeInMs = timeInMs;
 
#ifdef DEBUG_GYRO
            if (NULL == gyroFile)
            {
                NSString* gyroFilePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:[NSString stringWithUTF8String:GyroFileName]];
                gyroFile = fopen(gyroFilePath.UTF8String, "r+");
            }
            if (NULL != gyroFile)
            {
                float matrix[9];
                fscanf(gyroFile, "%f,%f,%f,%f,%f,%f,%f,%f,%f", &matrix[0], &matrix[1], &matrix[2], &matrix[3], &matrix[4], &matrix[5], &matrix[6], &matrix[7], &matrix[8]);
                NSLog(@"GyroMatrix : %f,%f,%f,%f,%f,%f,%f,%f,%f", matrix[0], matrix[1], matrix[2], matrix[3], matrix[4], matrix[5], matrix[6], matrix[7], matrix[8]);
                [_glView setGyroMatrix:matrix rank:3];
            }
#endif
        }/* else if ([frame isKindOfClass:KxVideoFrameRGB.class]) {
            KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB *)frame;
            //_imageView.image = [rgbFrame asImage];
            [_glView.glRenderLoop draw:[rgbFrame asImage] withLUTStitching:YES gyroMatrix:nil videoCaptureResolution:FPS30_3456x1728];
        } else if ([frame isKindOfClass:KxVideoFrameCVBuffer.class]) {
            KxVideoFrameCVBuffer* cvbFrame = (KxVideoFrameCVBuffer*)frame;
            [_glView.glRenderLoop render:cvbFrame];
        }*/
    }
    
    _moviePosition = frame.position;
    return frame.duration;
}

- (void) presentSubtitles
{
    
    NSLog(@"presentSubtitles");
    NSArray *actual, *outdated;
    
    if ([self subtitleForPosition:_moviePosition
                           actual:&actual
                         outdated:&outdated]){
        
        if (outdated.count) {
            @synchronized(_subtitles) {
                [_subtitles removeObjectsInArray:outdated];
            }
        }
        
        if (actual.count) {
            
            NSMutableString *ms = [NSMutableString string];
            for (KxSubtitleFrame *subtitle in actual.reverseObjectEnumerator) {
                if (ms.length) [ms appendString:@"\n"];
                [ms appendString:subtitle.text];
            }
            
            [self showSubtitleText:ms];
        } else {
            [self showSubtitleText:nil];
        }
    }
}

- (void) recordAudioFrame:  (UInt32) inNumberFrames
                         channels: (int) channels
                         buf:  (float*) buf
{
    AudioBufferList bufferList;
    UInt16 numSamples = inNumberFrames*channels;
    
    //NSLog(@"recordAudioFrame %d ", numSamples);
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = buf;
    bufferList.mBuffers[0].mNumberChannels = channels;
    bufferList.mBuffers[0].mDataByteSize = numSamples*sizeof(float);

    
    //OSStatus status = ExtAudioFileWriteAsync(_audioFileRef, inNumberFrames, &bufferList);
    if([_decoder getOriAudioChannel] != 4)
    {
        OSStatus status = ExtAudioFileWrite(_audioFileRef, inNumberFrames, &bufferList);
        if(status != 0)
            NSLog(@"Audio write fail ret=%d",status);
        //NSLog(@"record audio frame samples:%d channel:%d", numSamples, channels);
        ///!!!#Bug2880# It crashes after back to foreground! checkStatus(status);
    }
}

- (void) showSubtitleText:(NSString*)text {
    // Subclass Implements
}

- (BOOL) subtitleForPosition: (CGFloat) position
                      actual: (NSArray **) pActual
                    outdated: (NSArray **) pOutdated
{
    
    NSLog(@"subtitleForPosition %f", position);
    
    if (!_subtitles.count)
        return NO;
    
    NSMutableArray *actual = nil;
    NSMutableArray *outdated = nil;
    
    for (KxSubtitleFrame *subtitle in _subtitles) {
        
        if (position < subtitle.position) {
            
            break; // assume what subtitles sorted by position
            
        } else if (position >= (subtitle.position + subtitle.duration)) {
            
            if (pOutdated) {
                if (!outdated)
                    outdated = [NSMutableArray array];
                [outdated addObject:subtitle];
            }
            
        } else {
            
            if (pActual) {
                if (!actual)
                    actual = [NSMutableArray array];
                [actual addObject:subtitle];
            }
        }
    }
    
    if (pActual) *pActual = actual;
    if (pOutdated) *pOutdated = outdated;
    
    return actual.count || outdated.count;
}

- (void) updateHUD
{
    
    //NSLog(@"updateHUD");
    
    if (_disableUpdateHUD)
        return;
    [self updatePositionView];

#if 0
#ifdef DEBUG
    const NSTimeInterval timeSinceStart = [NSDate timeIntervalSinceReferenceDate] - _debugStartTime;
    NSString *subinfo = self.decoder.validSubtitles ? [NSString stringWithFormat: @" %d",_subtitles.count] : @"";
    
    NSString *audioStatus;
    
    if (_debugAudioStatus) {
        
        if (NSOrderedAscending == [_debugAudioStatusTS compare: [NSDate dateWithTimeIntervalSinceNow:-0.5]]) {
            _debugAudioStatus = 0;
        }
    }
    
    if      (_debugAudioStatus == 1) audioStatus = @"\n(audio outrun)";
    else if (_debugAudioStatus == 2) audioStatus = @"\n(audio lags)";
    else if (_debugAudioStatus == 3) audioStatus = @"\n(audio silence)";
    else audioStatus = @"";
    
    _messageLabel.text = [NSString stringWithFormat:@"%d %d%@ %c - %@ %@ %@\n%@",
                          _videoFrames.count,
                          _audioFrames.count,
                          subinfo,
                          self.decoding ? 'D' : ' ',
                          formatTimeInterval(timeSinceStart, NO),
                          //timeSinceStart > self.moviePosition + 0.5 ? @" (lags)" : @"",
                          self.decoder.isEOF ? @"- END" : @"",
                          audioStatus,
                          _buffered ? [NSString stringWithFormat:@"buffering %.1f%%", _bufferedDuration / _minBufferedDuration * 100] : @""];
#endif
#endif
}

- (void) updatePositionView {
}

- (void) fullscreenMode: (BOOL) on
{
    
    NSLog(@"fullscreenMode %d", on);
    _fullscreen = on;
    UIApplication *app = [UIApplication sharedApplication];
    [app setStatusBarHidden:on withAnimation:UIStatusBarAnimationNone];
    // if (!self.presentingViewController) {
    //[self.navigationController setNavigationBarHidden:on animated:YES];
    //[self.tabBarController setTabBarHidden:on animated:YES];
    // }
}

- (void) setMoviePositionFromDecoder
{
    
    NSLog(@"setMoviePositionFromDecoder %f", _decoder.position);
    _moviePosition = _decoder.position;
}

- (void) setDecoderPosition: (CGFloat) position
{
    
    NSLog(@"setDecoderPosition %f", position);
    _decoder.position = position;
}

- (void) enableUpdateHUD
{
    
    //NSLog(@"enableUpdateHUD");
    _disableUpdateHUD = NO;
}

- (void) updatePosition: (CGFloat) position
               playMode: (BOOL) playMode
{
    
    NSLog(@"updatePosition position:%f playmode:%d", position, playMode);
    [self freeBufferedFrames];
    
    position = MIN(_decoder.duration - 1, MAX(0, position));
    
    __weak MVKxMovieViewController *weakSelf = self;

    dispatch_async(_dispatchQueue, ^{
        if (playMode) {
            {
                __strong MVKxMovieViewController *strongSelf = weakSelf;
                if (!strongSelf) return;
                [strongSelf setDecoderPosition: position];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MVKxMovieViewController *strongSelf = weakSelf;
                if (strongSelf) {
                    [strongSelf setMoviePositionFromDecoder];
                    [strongSelf play];
                }
            });
        } else {
            {
                __strong MVKxMovieViewController *strongSelf = weakSelf;
                if (!strongSelf) return;
                [strongSelf setDecoderPosition: position];
                [strongSelf decodeFrames];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MVKxMovieViewController *strongSelf = weakSelf;
                if (strongSelf) {
                    [strongSelf setMoviePositionFromDecoder];
                    [strongSelf presentFrame];
                    [strongSelf enableUpdateHUD];
                    [strongSelf updateHUD];
                }
            });
        }        
    });
}

- (void) didPlayProgressChanged:(int)percent {
}

- (void) freeBufferedFrames
{
    @synchronized(_videoFrames) {
#ifdef DEBUG_VIDEOFRAME_LEAKING
        //NSLog(@"VideoLeak : freeBufferedFrames @ [%@]", [[NSThread callStackSymbols] description]);// stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]);
        //NSLog(@"VideoLeak : Before _videoFrames removeAllObjects, count = %d", (int)_videoFrames.count);
#endif
        [_videoFrames removeAllObjects];
#ifdef DEBUG_VIDEOFRAME_LEAKING
        //NSLog(@"VideoLeak : After _videoFrames removeAllObjects, count = %d", (int)_videoFrames.count);
#endif
    }
    
    @synchronized(_audioFrames) {
        
        [_audioFrames removeAllObjects];
        _currentAudioFrame = nil;
    }
    
    if (_subtitles) {
        @synchronized(_subtitles) {
            [_subtitles removeAllObjects];
        }
    }
    
    _bufferedDuration = 0;
}

- (void) handleDecoderMovieError: (NSError *) error
{
    NSLog(@"handleDecoderMovieError : %@", error);
    /*
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                              otherButtonTitles:nil];
    
    [alertView show];
    //*/
}

- (BOOL) interruptDecoder
{
    //if (!_decoder)
    //    return NO;
    NSLog(@"interruptDecoder %d", _interrupted);
    return _interrupted;
}
- (void)setUDPPro:(BOOL)UseUDPPro
{
    SetGlobalUDPPro(UseUDPPro);
}

-(BOOL) getGyroMatrix:(float*)pMatrix frameNumber:(NSInteger)frameNumber {
    @try {
        if (!self.gyroData)
            return NO;
        
        NSInteger iSrcByte = frameNumber * self.bytesPerGyroStringLine + self.gyroDataBytesOffset;
        Byte* bytes = (Byte*) self.gyroData.bytes;
        for (int j=0; j<9; ++j) {
            int b0 = bytes[iSrcByte++];
            int b1 = bytes[iSrcByte++];
            int b2 = bytes[iSrcByte++];
            int b3 = bytes[iSrcByte++];
            int intValue = (b0 & 0xff) | ((b1 & 0xff) << 8) | ((b2 & 0xff) << 16) | ((b3 & 0xff) << 24);
            pMatrix[j] = *((float*) (int*) &intValue);
        }
        //NSLog(@"getGyroMatrix : frame#%d {%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f}", (int)frameNumber, pMatrix[0],pMatrix[1],pMatrix[2],pMatrix[3],pMatrix[4],pMatrix[5],pMatrix[6],pMatrix[7],pMatrix[8]);
        return YES;
    }
    @catch (id ex) {
        return NO;
    }
    @finally {
    }
}

#ifdef ENCODING_WITHOUT_MYGLVIEW
#pragma mark    GLRenderLoopDelegate
- (void) glRenderLoopSetupGLRenderbuffer:(GLRenderLoop*)renderLoop {
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, 32, 32);
}
#endif
    
@end

