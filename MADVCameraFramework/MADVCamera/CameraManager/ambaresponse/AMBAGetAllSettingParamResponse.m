//
//  AMBAGetAllSettingParamResponse.m
//  Madv360_v1
//
//  Created by QiuDong on 2016/11/26.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAGetAllSettingParamResponse.h"

@implementation AMBAGetAllSettingParamResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    NSArray* myArray = @[
                         @"v_res",
                         @"video_wb",
                         @"video_ev",
                         @"video_iso",
                         @"video_shutter",
                         @"loop",
                         @"p_res",
                         @"still_wb",
                         @"still_ev",
                         @"still_iso",
                         @"still_shutter",
                         @"buzzer",
                         @"standby_en",
                         @"standby_time",
                         @"poweroff_en",
                         @"poweroff_time",
                         @"led",
                         @"battery",
                         @"product",
                         @"sn",
                         @"ver",
                         @"md5",
                         @"cam_jpg",
                         @"cam_mp4",
                         ];
    mergeJsonSerializablePropertyNames(array, myArray);
    return array;
}

@end
