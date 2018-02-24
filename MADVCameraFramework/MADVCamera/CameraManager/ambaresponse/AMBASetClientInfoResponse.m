//
//  AMBASetClientInfoResponse.m
//  Madv360_v1
//
//  Created by QiuDong on 2017/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AMBASetClientInfoResponse.h"

@implementation AMBASetClientInfoResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    NSArray* myArray = @[@"update", @"session_id"];
    mergeJsonSerializablePropertyNames(array, myArray);
    return array;
}

@end
