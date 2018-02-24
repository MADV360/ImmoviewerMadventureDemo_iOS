//
//  NSCondition+Extensions.m
//  Madv360_v1
//
//  Created by QiuDong on 16/9/12.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "NSCondition+Extensions.h"

@implementation NSCondition (Extensions)

- (void) lockAndLog {
    NSLog(@"Before lock on (%@) at %s %s %d\n", self, __FILE__, __FUNCTION__, __LINE__);
    [self lock];
    NSLog(@"After lock on (%@) at %s %s %d\n", self, __FILE__, __FUNCTION__, __LINE__);
}

- (void) unlockAndLog {
//    NSLog(@"Before unlock on (%@) at %s %s %d\n", self, __FILE__, __FUNCTION__, __LINE__);
    [self unlock];
    NSLog(@"After unlock on (%@) at %s %s %d\n", self, __FILE__, __FUNCTION__, __LINE__);
}

- (void) waitAndLog {
    NSLog(@"Before wait on (%@) at %s %s %d\n", self, __FILE__, __FUNCTION__, __LINE__);
    [self wait];
    NSLog(@"After wait on (%@) at %s %s %d\n", self, __FILE__, __FUNCTION__, __LINE__);
}

@end
