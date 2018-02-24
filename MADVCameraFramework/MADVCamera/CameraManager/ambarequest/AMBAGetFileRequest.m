//
//  AMBAGetFileRequest.m
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/16.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAGetFileRequest.h"
#import "AMBAGetFileResponse.h"

@implementation AMBAGetFileRequest

- (instancetype) initWithReceiveBlock:(AMBAResponseReceivedBlock)receiveBlock errorBlock:(AMBAResponseErrorBlock)errorBlock {
    if (self = [super initWithReceiveBlock:receiveBlock errorBlock:errorBlock responseClass:AMBAGetFileResponse.class])
    {
        
    }
    return self;
}

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    mergeJsonSerializablePropertyNames(array, @[@"offset", @"fetchSize"]);
    return array;
}

+ (NSDictionary<NSString*, NSString* >*) propertyNameToJsonKeyMap {
    mergePropertyNameToJsonKeyMap(dict, @{@"fetchSize":@"fetch_size"});
    return dict;
}

@end
