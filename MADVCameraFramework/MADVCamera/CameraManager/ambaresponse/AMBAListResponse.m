//
//  AMBAListResponse.m
//  Madv360_v1
//
//  Created by QiuDong on 16/10/12.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAListResponse.h"

@implementation AMBAListResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    mergeJsonSerializablePropertyNames(array, @[@"listing"]);
    return array;
}

@end
