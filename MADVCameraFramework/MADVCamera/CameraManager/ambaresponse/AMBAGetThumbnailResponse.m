//
//  AMBAGetThumbnailResponse.m
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/16.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAGetThumbnailResponse.h"

@implementation AMBAGetThumbnailResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    mergeJsonSerializablePropertyNames(array, @[@"md5sum", @"size"]);
    return array;
}

@end
