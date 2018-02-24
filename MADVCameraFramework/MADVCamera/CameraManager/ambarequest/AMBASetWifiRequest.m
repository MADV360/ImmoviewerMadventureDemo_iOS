//
//  AMBASetWifiRequest.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/9/7.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBASetWifiRequest.h"

@implementation AMBASetWifiRequest

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    mergeJsonSerializablePropertyNames(array, @[@"ssid", @"passwd"]);
    return array;
}

@end
