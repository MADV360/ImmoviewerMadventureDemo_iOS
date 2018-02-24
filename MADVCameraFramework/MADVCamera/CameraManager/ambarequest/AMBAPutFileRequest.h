//
//  AMBAPutFileRequest.h
//  Madv360_v1
//
//  Created by QiuDong on 16/11/17.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBARequest.h"

@interface AMBAPutFileRequest : AMBARequest

- (instancetype) initWithReceiveBlock:(AMBAResponseReceivedBlock)receiveBlock errorBlock:(AMBAResponseErrorBlock)errorBlock;

@property (nonatomic, assign) NSInteger offset;

@property (nonatomic, assign) NSInteger size;

@property (nonatomic, copy) NSString* md5sum;

@property (nonatomic, assign) int fType;

@end
