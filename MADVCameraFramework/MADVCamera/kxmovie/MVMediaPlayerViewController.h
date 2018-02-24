//
//  MVMediaPlayerViewController.h
//  Madv360_v1
//
//  Created by QiuDong on 16/4/12.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MVKxMovieViewController.h"
//#import "CloudMediaDetail.h"
//#import "DistinguishRate.h"
#import "MVMedia.h"
#import "MVMediaManager.h"
#import "MVCameraClient.h"
//#import "GuideView.h"
//#import "ConnectCourseController.h"


@interface MVMediaPlayerViewController : MVKxMovieViewController

@property (nonatomic, strong) NSDictionary* parameters;

@property (nonatomic, strong) MVMedia* media;

+ (instancetype __nullable) showFromViewController:(UIViewController* __nullable)fromViewController media:(MVMedia* __nullable)media parameters:(NSDictionary* __nullable)parameters;

+ (instancetype __nullable) showEncoderControllerFrom:(UIViewController* __nullable)fromViewController media:(MVMedia* _Nonnull)media qualityLevel:(QualityLevel)qualityLevel progressBlock:(void(^ __nullable)(int))progressBlock doneBlock:(void(^ __nullable)(NSString* __nullable, NSError* __nullable))doneBlock;

@end
