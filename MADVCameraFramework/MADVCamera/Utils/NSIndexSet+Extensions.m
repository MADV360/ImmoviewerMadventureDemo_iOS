//
//  NSIndexSet+Extensions.m
//  Madv360_v1
//
//  Created by QiuDong on 15/12/21.
//  Copyright © 2015年 Cyllenge. All rights reserved.
//

#import "NSIndexSet+Extensions.h"
#import <UIKit/UIKit.h>

@implementation NSIndexSet (Extensions)

- (NSArray*) indexPathsWithSection:(NSUInteger)section {
    NSMutableArray* indexPaths = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return [NSArray arrayWithArray:indexPaths];
}

@end
