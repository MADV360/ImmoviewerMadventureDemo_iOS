//
//  LoadProgressView.m
//
//  Created by MS on 15-12-17.
//  Copyright (c) 2015年 MS. All rights reserved.
//

#import "LoadProgressView.h"
@interface LoadProgressView()
@property(nonatomic,weak)UIView * progressLabel;
@end
@implementation LoadProgressView
- (void)startLoadData
{
    UIView * progressLabel=[[UIView alloc] init];
    [self addSubview:progressLabel];
    progressLabel.frame=CGRectMake(0, 0, 0, 2);
    progressLabel.backgroundColor=[UIColor colorWithHexString:@"#008040"];
    self.progressLabel=progressLabel;
    
    [UIView animateWithDuration:1 animations:^{
        self.progressLabel.frame=CGRectMake(0, 0, ScreenWidth-30,self.frame.size.height);
    } completion:^(BOOL finished) {
    }];
    
}
- (void)finishLoadData
{
    [UIView animateWithDuration:0.5 animations:^{
        self.progressLabel.frame=CGRectMake(0, 0, ScreenWidth, self.frame.size.height);
    } completion:^(BOOL finished) {
        [self.progressLabel removeFromSuperview];
    }];
}

@end
