//
//  AMBASyncStorageAllStateResponse.m
//  Madv360_v1
//
//  Created by QiuDong on 16/11/7.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBASyncStorageAllStateResponse.h"

@implementation AMBASyncStorageAllStateResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    mergeJsonSerializablePropertyNames(array, @[@"remain_video", @"remain_jpg", @"sd_total", @"sd_free", @"sd_full", @"sd_mid", @"sd_oid", @"sd_pnm"]);
    return array;
}

@end
