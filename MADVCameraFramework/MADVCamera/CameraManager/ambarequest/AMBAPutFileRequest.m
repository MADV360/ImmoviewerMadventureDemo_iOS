//
//  AMBAPutFileRequest.m
//  Madv360_v1
//
//  Created by QiuDong on 16/11/17.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAPutFileRequest.h"
#import "AMBAPutFileResponse.h"

@implementation AMBAPutFileRequest

- (instancetype) initWithReceiveBlock:(AMBAResponseReceivedBlock)receiveBlock errorBlock:(AMBAResponseErrorBlock)errorBlock {
    if (self = [super initWithReceiveBlock:receiveBlock errorBlock:errorBlock responseClass:AMBAPutFileResponse.class])
    {
        
    }
    return self;
}

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    mergeJsonSerializablePropertyNames(array, @[@"offset", @"size", @"md5sum", @"fType"]);
    return array;
}

@end
