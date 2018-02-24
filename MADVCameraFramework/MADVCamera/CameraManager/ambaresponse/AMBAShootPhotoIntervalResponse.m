//
//  AMBAShootPhotoIntervalResponse.m
//  Madv360_v1
//
//  Created by QiuDong on 2017/8/28.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AMBAShootPhotoIntervalResponse.h"

@implementation AMBAShootPhotoIntervalResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    NSArray* myArray = @[@"time"];
    mergeJsonSerializablePropertyNames(array, myArray);
    return array;
}

@end
