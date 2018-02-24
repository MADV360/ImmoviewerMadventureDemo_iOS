//
//  AMBASaveMediaFileDoneResponse.m
//  Madv360_v1
//
//  Created by QiuDong on 2016/11/26.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBASaveMediaFileDoneResponse.h"

@implementation AMBASaveMediaFileDoneResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    mergeJsonSerializablePropertyNames(array, @[@"remain_video", @"remain_jpg", @"total_mp4", @"sd_total", @"sd_free", @"sd_full", @"mp4_time"]);
    return array;
}

@end
