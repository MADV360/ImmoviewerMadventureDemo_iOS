//
//  AMBAGetFileResponse.h
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/16.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"

@interface AMBAGetFileResponse : AMBAResponse

@property (nonatomic, assign) NSInteger siRemSize;

@property (nonatomic, assign) NSInteger siSize;

- (NSInteger) size;

- (NSInteger) remSize;

@end
