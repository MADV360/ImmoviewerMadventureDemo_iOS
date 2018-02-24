//
//  AMBAGetMediaInfoResponse.m
//  Madv360_v1
//
//  Created by QiuDong on 16/10/11.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAGetMediaInfoResponse.h"

@implementation AMBAGetMediaInfoResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    mergeJsonSerializablePropertyNames(array, @[@"duration", @"jsonSize", @"media_type", @"scene_type", @"gyro", @"res_id"]);
    return array;
}

+ (NSDictionary<NSString*, NSString* >*) propertyNameToJsonKeyMap {
    mergePropertyNameToJsonKeyMap(dict, @{@"jsonSize":@"size"});
    return dict;
}

- (NSInteger) size {
    if (self.jsonSize < 0)
        return (1L << 32) + self.jsonSize;
    else
        return self.jsonSize;
}

- (VideoCaptureResolution) videoCaptureResolution {
    return (VideoCaptureResolution) [self.res_id integerValue];
}

@end
