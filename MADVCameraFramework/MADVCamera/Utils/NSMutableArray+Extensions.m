//
//  NSMutableArray+Extensions.m
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "NSMutableArray+Extensions.h"

@implementation NSMutableArray (Extensions)

- (id) poll {
    @synchronized (self)
    {
        id ret = [self firstObject];
        if (self.count > 0)
        {
            [self removeObjectAtIndex:0];
        }
        return ret;
    }
}

@end
