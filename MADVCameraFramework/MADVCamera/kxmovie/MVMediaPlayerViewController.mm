//
//  MVMediaPlayerViewController.m
//  Madv360_v1
//
//  Created by QiuDong on 16/4/12.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVMediaPlayerViewController.h"
#import "MVGLView.h"
#import "MadvGLRenderer_iOS.h"

#ifdef FOR_DOUYIN
#import "KxMovieDecoder_douyin.h"
#else //#ifdef FOR_DOUYIN
#import "KxMovieDecoder.h"
#endif //#ifdef FOR_DOUYIN

#import "KxAudioManager.h"
//#import "PostVideoViewController.h"
//#import "ALAsset+Extensions.h"
#import "UIViewController+MVExtensions.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
//#import "WXApi.h"
//#import "helper.h"
//#import "MVCloudMediaFavor.h"
//#import "DBHelper.h"
//#import <Masonry/Masonry.h>
#import "VideoExportView.h"
#import "z_Sandbox.h"
#import "helper.h"

@interface MVMediaPlayerViewController () <VideoExportViewDelegate>

//@property(nonatomic,weak)ProgressRateView * rateView;
@property(nonatomic,weak)VideoExportView * videoExportView;

@end

@implementation MVMediaPlayerViewController

@synthesize media;
@synthesize parameters;

#pragma mark    Ctor & Dtor

- (void) dealloc {
}

+ (instancetype) showFromViewController:(UIViewController*)fromViewController media:(MVMedia*)media parameters:(NSDictionary*)parameters {
    //用runtime去把NaviBar的一些设置保存起来
    [fromViewController saveNaviBarAppearance];
    
    //得到MVMediaPlayerViewController并设置参数
    //UIStoryboard* sb = [UIStoryboard storyboardWithName:@"MediaPlayerStoryboard" bundle:[NSBundle mainBundle]];
    //MVMediaPlayerViewController* ret = (MVMediaPlayerViewController*) [sb instantiateViewControllerWithIdentifier:@"MediaPlayer"];
    MVMediaPlayerViewController* ret = [[MVMediaPlayerViewController alloc] init];
    ret.isUsedAsEncoder = NO;
    
    NSMutableDictionary* params = [parameters mutableCopy];
    // disable deinterlacing for iPhone, because it's complex operation can cause stuttering ///???
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        params[KxMovieParameterDisableDeinterlacing] = @(YES);
    // disable buffering ///!!!
    //            parameters[KxMovieParameterMinBufferedDuration] = @(2.0f);
    //            parameters[KxMovieParameterMaxBufferedDuration] = @(4.0f);
    //        KxPlayerViewController *vc = [[KxPlayerViewController alloc] initWithContentPath:filePath parameters:parameters];
    
    ret.parameters = params;
    ret.media = media;
    ret.panoramaMode = PanoramaDisplayModeStereoGraphic;
    
//    UINavigationController* navigationVC;
//    if (fromViewController.navigationController)
//    {
//        navigationVC = fromViewController.navigationController;
//        [navigationVC pushViewController:ret animated:YES];
//    }
//    else
//    {
//        navigationVC = [[UINavigationController alloc] initWithRootViewController:ret];
//        [fromViewController presentViewController:navigationVC animated:YES completion:nil];
//    }
    [fromViewController presentViewController:ret animated:YES completion:nil];
    return ret;
}

#pragma mark    MVKxMovieViewController

- (void) didSetupPresentView:(UIView*)presentView {
    presentView.contentMode = UIViewContentModeScaleAspectFit;
    presentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:presentView];
    [self.view sendSubviewToBack:presentView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [backButton addTarget:self action:@selector(backTap:) forControlEvents:UIControlEventTouchUpInside];
    [backButton setTitle:@"Back" forState:UIControlStateNormal];
    [self.view addSubview:backButton];
    [backButton sizeToFit];
    backButton.frame = CGRectMake(12, 12, backButton.bounds.size.width, backButton.bounds.size.height);

    if (self.isUsedAsEncoder) {
        VideoExportView * videoExportView = [[VideoExportView alloc] init];
        [self.view addSubview:videoExportView];
        helper * helperInstance = [helper sharedInstance];
        CGFloat statusHeight = helperInstance.statusHeight;
        videoExportView.frame = CGRectMake(0, 44 + statusHeight, ScreenWidth, ScreenHeight-44 - statusHeight);
        [videoExportView loadVideoExportView];
        videoExportView.delegate = self;
        
        self.videoExportView = videoExportView;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* localFilePath = [self.media localFilePathSync:NO];
        [self setContentPath:localFilePath parameters:self.parameters];
    });
}

#pragma mark --返回--
#pragma mark --返回--
- (void)backTap:(id)tap
{
    [self finishGLView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) finishGLView {
    ///[[MVCameraClient sharedInstance] setHeartbeatEnabled:NO forDemander:PlayerHeartbeatDemander];
    [self stop];
    DoctorLog(@"#GLRenderLoopState# MVMediaPlayerViewController $ finishGLView will call MVGLView.willDisappear @%lx MVGLView@%lx MVMediaPlayerViewController@%lx", (long)self.glView.glRenderLoop.hash, (long)self.glView.hash, (long)self.hash);
    [self.glView willDisappear];
    self.glView = nil;
#ifdef ENCODING_WITHOUT_MYGLVIEW
    if (self.isUsedAsEncoder) {
        self.encoderRenderLoop.encodingError = [NSError errorWithDomain:@"MadvErrorEncodingCanceled" code:-2 userInfo:@{}];
        //[self.encoderRenderLoop stopEncoding:nil];
    }
    [self.encoderRenderLoop stopRendering];
    [self.encoderRenderLoop stopEncoding];
    self.encoderRenderLoop = nil;
#endif
    NSLog(@"EAGLContext : MVKxMovieViewController $ finishGLView");
}

///////////////////////////

+ (instancetype) showEncoderControllerFrom:(UIViewController*)fromViewController media:(MVMedia*)media qualityLevel:(QualityLevel)qualityLevel progressBlock:(void(^)(int))progressBlock doneBlock:(void(^)(NSString*,NSError*))doneBlock {
    //用runtime去把NaviBar的一些设置保存起来
    [fromViewController saveNaviBarAppearance];
    
    
    //得到MVMediaPlayerViewController并设置参数
    UIStoryboard* sb = [UIStoryboard storyboardWithName:@"MediaPlayerStoryboard" bundle:[NSBundle mainBundle]];
    MVMediaPlayerViewController* ret = (MVMediaPlayerViewController*) [sb instantiateViewControllerWithIdentifier:@"MediaPlayer"];
    __weak __typeof(ret) wRet = ret;
    ret.isUsedAsEncoder = YES;
    ret.encoderQualityLevel = qualityLevel;
    ret.encodingDoneBlock = ^(NSString* outputFilePath, NSError* error) {
        NSLog(@"#Bug2880# MVMediaPlayerViewController : encodingDoneBlock #0");
        [wRet pause];
        NSLog(@"#Bug2880# MVMediaPlayerViewController : encodingDoneBlock #1");
        [wRet freeBufferedFrames]; //2016.3.3 spy
        wRet.decoder = nil;
        
//        [[MVMediaManager sharedInstance] removeMediaDownloadStatusObserver:wRet];
//        [[MVCameraClient sharedInstance] removeObserver:wRet];
        
        if (doneBlock)
        {
            doneBlock(outputFilePath, error);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                ///#VideoExport# [wRet.videoExportView setPercent:100 animated:YES];
                NSString * filename;
/////#VideoExport#                 if (wRet.encoderQualityLevel == QualityLevel4K || wRet.encoderQualityLevel == QualityLevel1080 || QualityLevelOther)
//                {
//                    filename = [[MVKxMovieViewController encodedFileBaseName:wRet.media.localPath qualityLevel:wRet.encoderQualityLevel forExport:YES] lastPathComponent];
//                }
//                else
                {
                    filename = wRet.media.localPath;
                }
                
                ///#VideoExport# [wRet saveVideoFilename:filename];
                if (wRet.isUsedAsEncoder)
                {
                    wRet.videoExportView.isSuc = YES;
                }
                else
                {
//                    [UIView animateWithDuration:0 animations:^{
//                        [MMProgressHUD showWithStatus:@""];
//                    } completion:^(BOOL finished) {
//                        [MMProgressHUD dismissWithSuccess:FGGetStringWithKeyFromTable(EXPORTSUC, nil)];
//                    }];
                }
                
            }else
            {
                ///#VideoExport# wRet.navigationItem.leftBarButtonItem = wRet.exportBackItem;
                wRet.videoExportView.isSuc = NO;
            }
        });
        
    };
    ret.encodingProgressChangedBlock = progressBlock;
    //#VideoExport#ret.fromViewController = fromViewController;
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    // disable deinterlacing for iPhone, because it's complex operation can cause stuttering ///???
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        params[KxMovieParameterDisableDeinterlacing] = @(YES);
    // disable buffering ///!!!
    //            parameters[KxMovieParameterMinBufferedDuration] = @(2.0f);
    //            parameters[KxMovieParameterMaxBufferedDuration] = @(4.0f);
    //        KxPlayerViewController *vc = [[KxPlayerViewController alloc] initWithContentPath:filePath parameters:parameters];
    
    ret.parameters = params;
    ret.media = media;
    ret.panoramaMode = PanoramaDisplayModeStereoGraphic;
    ///#VideoExport# ret.isLocal = YES;
    //    if (MVMediaTypePhoto == media.mediaType) {
    //        ret.panoramaMode = PanoramaDisplayModeStereoGraphic;
    //    }
    //    else {
    //        NSString* videoURI = [ret videoURI];
    //        NSString* lutPath = MadvGLRenderer_iOS::lutPathOfSourceURI(videoURI, NO);
    //        if (lutPath) {
    //            ret.displayMode = PanoramaDisplayModeStereoGraphic | PanoramaDisplayModeLUT;
    //        }
    //        else {
    //            ret.displayMode = PanoramaDisplayModeStereoGraphic;
    //        }
    //    }
    ret.providesPresentationContextTransitionStyle = YES;
    ret.definesPresentationContext = YES;
    ret.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
#ifdef OPENNEWPUBLISH
    UINavigationController* navigationVC;
    if (fromViewController.navigationController)
    {
        navigationVC = fromViewController.navigationController;
        [navigationVC pushViewController:ret animated:YES];
    }
    else
    {
        navigationVC = [[UINavigationController alloc] initWithRootViewController:ret];
        [fromViewController presentViewController:navigationVC animated:YES completion:nil];
    }
#else
    [fromViewController presentViewController:ret animated:YES completion:nil];
#endif
    return ret;
}

- (NSData*)createMadVData:(BOOL)writeGyroData
{
    NSData* MadVData = nil;
    if (self.decoder) {
        int64_t gyro_size = self.decoder.getGyroSize;
        int frameSize = 36;
        int firstFrame = (int)((self.firstVideoTimestamp + 1) * self.decoder.fps / 1000.0);
        int effective_gyro_data_offset = firstFrame * frameSize;
        
        uint8_t dispMode = self.panoramaMode; // fill this value for real dispmode to record/export
        int64_t disp_size = 1;
        
        int64_t  gyro_box_size;
        if(writeGyroData) {
            if (gyro_size > 0) {
                gyro_box_size = ((effective_gyro_data_offset + self.outputVideoFrameCount * frameSize) > gyro_size) ?
                (gyro_size - effective_gyro_data_offset + 8) : self.outputVideoFrameCount * frameSize + 8;
            }
            else
                gyro_box_size = 0;
        } else {
            gyro_box_size = 0;
        }
        int64_t  disp_box_size = disp_size + 8;
        int64_t  madv_box_size = gyro_box_size + disp_box_size + 8;
        
        uint8_t madv_data[madv_box_size];
        
        madv_data[0] = (madv_box_size >> 24) & 0xFF;
        madv_data[1] = (madv_box_size >> 16) & 0xFF;
        madv_data[2] = (madv_box_size >> 8) & 0xFF;
        madv_data[3] = madv_box_size & 0xFF;
        madv_data[4] = 'm';
        madv_data[5] = 'a';
        madv_data[6] = 'd';
        madv_data[7] = 'v';
        
        if(gyro_box_size > 0) {
            madv_data[8] = (gyro_box_size >> 24) & 0xFF;
            madv_data[9] = (gyro_box_size >> 16) & 0xFF;
            madv_data[10] = (gyro_box_size >> 8) & 0xFF;
            madv_data[11] = gyro_box_size & 0xFF;
            madv_data[12] = 'G';
            madv_data[13] = 'Y';
            madv_data[14] = 'R';
            madv_data[15] = 'A';
            
            uint8_t* gyro_data = self.decoder.getGyroData;
            memcpy(madv_data+16, gyro_data + effective_gyro_data_offset, gyro_box_size - 8);
        }
        
        madv_data[8 + gyro_box_size] = (disp_box_size >> 24) & 0xFF;
        madv_data[8 + gyro_box_size + 1] = (disp_box_size >> 16) & 0xFF;
        madv_data[8 + gyro_box_size + 2] = (disp_box_size >> 8) & 0xFF;
        madv_data[8 + gyro_box_size + 3] = disp_box_size & 0xFF;
        madv_data[8 + gyro_box_size + 4] = 'D';
        madv_data[8 + gyro_box_size + 5] = 'I';
        madv_data[8 + gyro_box_size + 6] = 'S';
        madv_data[8 + gyro_box_size + 7] = 'P';
        madv_data[8 + gyro_box_size + 8] = dispMode;
        
        MadVData = [NSData dataWithBytes:madv_data length:madv_box_size];
    }
    return MadVData;
}

- (void)playingDoneWhileEncoding
{
    //NSLog(@"VideoEncoding: MVMediaPlayerViewController $ playingDoneWhileEncoding");
    if (self.isUsedAsEncoder) {
        NSData* MadVData = [self createMadVData:!self.isCameraGyroAdustEnabled];
#ifdef ENCODING_WITHOUT_MYGLVIEW
        [self.encoderRenderLoop setMadVdata:MadVData];
        [self.encoderRenderLoop stopRendering];
#else
        [self.glView.glRenderLoop setMadVdata:MadVData];
        [self.glView.glRenderLoop stopRendering];
#endif
    }
}

- (void) didPlayProgressChanged:(int)percent {
    //NSLog(@"VideoEncoding: MVMediaPlayerViewController $ didPlayProgressChanged : percent = %d", percent);
    [super didPlayProgressChanged:percent];
    ///#VideoExport# [self.rateView updateRate:percent];
    ///#VideoExport# if (self.isExport) {
        [self.videoExportView setPercent:percent animated:YES];
    ///#VideoExport#}
    //编辑转码
    ///#VideoExport#if (self.isUsedAsEncoder && self.isEdit) {
    ///#VideoExport#    [self.videoExportView setPercent:percent animated:YES];
    ///#VideoExport#}
#ifdef OPENNEWPUBLISH
    ///#VideoExport#self.shareLabel.text = [NSString stringWithFormat:@"%@%@%d%@",FGGetStringWithKeyFromTable(TRANSCODINGWAIT, nil),@"...",percent,@"%"];
    ///#VideoExport#self.publishProgressView.width = (ScreenWidth-50)*((float)percent/100);
#endif
    if (self.isUsedAsEncoder) {
        if (self.encodingProgressChangedBlock) {
            self.encodingProgressChangedBlock(percent);
        }
    }
}

- (void) didPlayOver {
    [super didPlayOver];
//    float endValue;
//    if (self.isEditPreview && self.editEndTime > 0)
//        endValue = self.editEndTime / self.decoder.duration;
//    else
//        endValue = 1;
//    if (_progressSlider.state == UIControlStateNormal)
//        _progressSlider.value = endValue;
//    if (_libraryProgressSlider.state == UIControlStateNormal)
//        _libraryProgressSlider.value = endValue;
//    if (_localHorProgreSlider.state == UIControlStateNormal)
//        _localHorProgreSlider.value = endValue;
//    if (_cameraHorProgreSlider.state == UIControlStateNormal)
//        _cameraHorProgreSlider.value = endValue;
//    self.imageSlider.value = endValue;
//    if (self.editProgressView.progressSlider.state == UIControlStateNormal) {
//        self.editProgressView.progressSlider.value = 1;
//    }
//    
//    self.timePositionLabel.text = formatTimeInterval(self.decoder.duration, NO);
//    self.localTimePosiLabel.text = formatTimeInterval(self.decoder.duration, NO);
//    self.playDurationLabel.text = formatTimeInterval(self.decoder.duration - self.decoder.duration * self.imageSlider.leftValue - self.decoder.duration * (1- self.imageSlider.rightValue), NO);
    if (self.isUsedAsEncoder) {
        [self performSelector:@selector(playingDoneWhileEncoding) withObject:nil afterDelay:0];
    }
    else
    {
        [self restorePlay];
    }
}

@end
