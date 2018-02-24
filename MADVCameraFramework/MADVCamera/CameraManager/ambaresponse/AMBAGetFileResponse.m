//
//  AMBAGetFileResponse.m
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/16.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAGetFileResponse.h"

@implementation AMBAGetFileResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    mergeJsonSerializablePropertyNames(array, @[@"siRemSize", @"siSize"]);
    return array;
}

+ (NSDictionary<NSString*, NSString* >*) propertyNameToJsonKeyMap {
    mergePropertyNameToJsonKeyMap(dict, @{@"siRemSize":@"rem_size", @"siSize":@"size"});
    return dict;
}

- (NSInteger) remSize {
    if (self.siRemSize < 0)
        return (1L << 32) + self.siRemSize;
    else
        return self.siRemSize;
}

- (NSInteger) size {
    if (self.siSize < 0)
        return (1L << 32) + self.siSize;
    else
        return self.siSize;
}

@end
