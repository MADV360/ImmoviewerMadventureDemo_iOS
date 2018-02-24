//
//  AMBASetCameraModeResponse.m
//  Madv360_v1
//
//  Created by QiuDong on 2017/8/28.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AMBASetCameraModeResponse.h"

@implementation AMBASetCameraModeResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    NSArray* myArray = @[@"sub_mode", @"sub_mode_param"];
    mergeJsonSerializablePropertyNames(array, myArray);
    return array;
}

@end
