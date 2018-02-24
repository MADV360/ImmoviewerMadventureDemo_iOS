//
//  AMBAGetAllModeParamResponse.m
//  Madv360_v1
//
//  Created by QiuDong on 2017/2/7.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AMBAGetAllModeParamResponse.h"

@implementation AMBAGetAllModeParamResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    NSArray* myArray = @[@"status",
                         @"mode",
                         @"sub_mode",
                         @"rec_time",
                         @"second",
                         @"lapse",
                         @"timing",
                         @"timing_c",
                         
                         @"cap_interval",
                         @"cap_interval_num",
                         
                         @"speedx", 
                         
                         @"sensor_num", 
                         @"burst_num", 
                         
                         @"surroundexp",
                         
                         @"surexp_c",
                         
                         @"douyin_video_time", 
                         @"douyin_speedx", 
                         @"douyin_sensor_num", 
                         @"douyin_bitrate"
                         ];
    mergeJsonSerializablePropertyNames(array, myArray);
    return array;
}

@end
