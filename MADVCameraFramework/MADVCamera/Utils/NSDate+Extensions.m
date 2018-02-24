//
//  NSDate+Extensions.m
//  Madv360_v1
//
//  Created by QiuDong on 16/3/22.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "NSDate+Extensions.h"

@implementation NSDate (Extensions)

- (NSDate*) localDate {
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate:self];
    NSDate *localeDate = [self dateByAddingTimeInterval:interval];
    return localeDate;
}

@end
