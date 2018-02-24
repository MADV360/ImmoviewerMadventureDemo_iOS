//
//  OutboundsTouchableView.m
//  Madv360_v1
//
//  Created by QiuDong on 16/3/31.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "OutboundsTouchableView.h"

@implementation OutboundsTouchableView

- (UIView*) hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.clipsToBounds && !self.hidden && self.alpha > 0.f)
    {
        for (UIView* view in self.subviews.reverseObjectEnumerator)
        {
            CGPoint subPoint = [view convertPoint:point fromView:self];
            UIView* result = [view hitTest:subPoint withEvent:event];
            if (result)
            {
                return result;
            }
        }
    }
    return nil;
}

@end
