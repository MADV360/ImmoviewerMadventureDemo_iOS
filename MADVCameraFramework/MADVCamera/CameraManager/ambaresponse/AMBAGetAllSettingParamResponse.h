//
//  AMBAGetAllSettingParamResponse.h
//  Madv360_v1
//
//  Created by QiuDong on 2016/11/26.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"

@interface AMBAGetAllSettingParamResponse : AMBAResponse


@property (nonatomic, assign) int v_res;


@property (nonatomic, assign) int video_wb;


@property (nonatomic, assign) int video_ev;


@property (nonatomic, assign) int video_iso;


@property (nonatomic, assign) int video_shutter;


@property (nonatomic, assign) int loop;


@property (nonatomic, assign) int p_res;


@property (nonatomic, assign) int still_wb;


@property (nonatomic, assign) int still_ev;


@property (nonatomic, assign) int still_iso;


@property (nonatomic, assign) int still_shutter;


@property (nonatomic, assign) int buzzer;


@property (nonatomic, assign) int standby_en;


@property (nonatomic, assign) int standby_time;


@property (nonatomic, assign) int poweroff_en;


@property (nonatomic, assign) int poweroff_time;


@property (nonatomic, assign) int led;


@property (nonatomic, assign) int battery;


@property (nonatomic, copy) NSString* product;


@property (nonatomic, copy) NSString* sn;


@property (nonatomic, copy) NSString* ver;


@property (nonatomic, copy) NSString* md5;

@property (nonatomic, assign) int cam_jpg;

@property (nonatomic, assign) int cam_mp4;

@end
