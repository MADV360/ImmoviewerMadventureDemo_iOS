//
//  CenterButton.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/7.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "CenterButton.h"

@implementation CenterButton

-(void)layoutSubviews {
    [super layoutSubviews];
    
    // Center image
    CGPoint center = self.imageView.center;
    center.x = self.frame.size.width/2;
    if (self.isTop) {
        center.y = self.height * 0.5 -5 - self.imageView.frame.size.height + 5;
    }else
    {
        center.y = self.height * 0.5 -5 - self.imageView.frame.size.height + 15;
    }
    
    self.imageView.center = center;
    
    //Center text
    CGRect newFrame = [self titleLabel].frame;
    newFrame.origin.x = 0;
    newFrame.origin.y = CGRectGetMaxY(self.imageView.frame) + 8;
    newFrame.size.width = self.frame.size.width;
    
    self.titleLabel.frame = newFrame;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
