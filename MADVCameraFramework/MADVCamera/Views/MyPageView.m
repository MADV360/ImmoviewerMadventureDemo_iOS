//
//  MyPageView.m
//  DasBank
//
//  Created by 张巧隔 on 16/4/7.
//  Copyright © 2016年 LXWT. All rights reserved.
//

#import "MyPageView.h"
#import "UIView+Frame.h"
#define PAGEVIEWSPACE 15
#define WIDTH self.frame.size.width
#define HEIGHT self.frame.size.height

@interface MyPageView()
@property(nonatomic,weak)UIView * lineView;

@end

@implementation MyPageView
- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    _numberOfPages=numberOfPages;
    for(UIView * view in self.subviews)
    {
        [view removeFromSuperview];
    }
    
    for (int i=0; i<numberOfPages; i++) {
        UIView * baseView=[[UIView alloc] init];
        [self addSubview:baseView];
        baseView.frame=CGRectMake((10+PAGEVIEWSPACE)*i, 0, 10, 10);
        baseView.backgroundColor=[UIColor clearColor];
        baseView.tag=i;
        baseView.layer.masksToBounds =YES;
        baseView.layer.borderWidth = 1;
        if (!self.borderColor) {
            self.borderColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
        }
        baseView.layer.borderColor = self.borderColor.CGColor;
        baseView.layer.cornerRadius=5;
    }
    
    UIView * lineView=[[UIView alloc] init];
    [self addSubview:lineView];
    lineView.frame=CGRectMake(0, 0, 10, 10);
    if (!self.currentBgColor) {
        self.currentBgColor = [UIColor colorWithRed:0.37f green:0.36f blue:0.36f alpha:1.00f];
    }
    lineView.backgroundColor=self.currentBgColor;
    lineView.layer.cornerRadius=5;
    self.lineView=lineView;
    
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    _currentPage=currentPage;
   [UIView animateWithDuration:0.5 animations:^{
       self.lineView.x=25*currentPage;
   }];
    
}

@end
