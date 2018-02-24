//
//  AMBAGetAllModeParamResponse.h
//  Madv360_v1
//
//  Created by QiuDong on 2017/2/7.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"

@interface AMBAGetAllModeParamResponse : AMBAResponse

@property (nonatomic, assign) int status;
@property (nonatomic, assign) int mode;
@property (nonatomic, assign) int sub_mode;
@property (nonatomic, assign) int rec_time;
@property (nonatomic, assign) int second;
@property (nonatomic, assign) int lapse;
@property (nonatomic, assign) int timing;
@property (nonatomic, assign) int timing_c;

@property (nonatomic, assign) int cap_interval;
@property (nonatomic, assign) int cap_interval_num;

@property (nonatomic, assign) int speedx;

@property (nonatomic, assign) int sensor_num;
@property (nonatomic, assign) int burst_num;

@property (nonatomic, assign) int surroundexp;

@property (nonatomic,assign) int surexp_c;

@property (nonatomic, assign) int douyin_video_time;
@property (nonatomic, assign) int douyin_speedx;
@property (nonatomic, assign) int douyin_sensor_num;
@property (nonatomic, assign) float douyin_bitrate;

@end
