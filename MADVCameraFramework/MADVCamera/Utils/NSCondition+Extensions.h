//
//  NSCondition+Extensions.h
//  Madv360_v1
//
//  Created by QiuDong on 16/9/12.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCondition ()

- (void) lockAndLog;

- (void) unlockAndLog;

- (void) waitAndLog;

@end
