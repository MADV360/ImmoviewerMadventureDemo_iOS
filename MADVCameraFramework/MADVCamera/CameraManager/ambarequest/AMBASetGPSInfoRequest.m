//
//  AMBASetGPSInfoRequest.m
//  Madv360_v1
//
//  Created by QiuDong on 2017/7/17.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AMBASetGPSInfoRequest.h"
#import "AMBACommands.h"

@implementation AMBASetGPSInfoRequest

- (instancetype) initWithReceiveBlock:(AMBAResponseReceivedBlock)receiveBlock errorBlock:(AMBAResponseErrorBlock)errorBlock responseClass:(Class)responseClass {
    if (self = [super initWithReceiveBlock:receiveBlock errorBlock:errorBlock responseClass:responseClass])
    {
        self.msgID = AMBA_MSGID_SET_GPS_INFO;
    }
    return self;
}

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    mergeJsonSerializablePropertyNames(array, @[@"lon", @"lat", @"alt"]);
    return array;
}

@end
