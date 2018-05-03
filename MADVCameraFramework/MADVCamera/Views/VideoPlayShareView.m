//
//  VideoPlayShareView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/24.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "VideoPlayShareView.h"
#import "Masonry.h"
#import "MyPageView.h"

@interface VideoPlayShareView()<UIScrollViewDelegate>
@property(nonatomic,weak)UIView * baseView;
@property(nonatomic,weak)UIScrollView * scrollView;
@property(nonatomic,weak)UIView * firstBaseView;
@property(nonatomic,weak)UIView * secBaseView;
@property(nonatomic,weak)MyPageView * pageView;
@end

@implementation VideoPlayShareView

- (void)loadVideoPlayShareView
{
    if (self.dataArr.count > 6) {
        
        UIView * baseView = [[UIView alloc] init];
        [self addSubview:baseView];
        baseView.frame = CGRectMake(0, 0, self.width, self.height);
//        [baseView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(@0);
//            make.left.equalTo(@0);
//            make.right.equalTo(@0);
//            make.bottom.equalTo(@0);
//        }];
        baseView.backgroundColor = [UIColor clearColor];
        self.baseView = baseView;
        
        UIScrollView * scrollView=[[UIScrollView alloc] init];
        [baseView addSubview:scrollView];
        scrollView.frame = CGRectMake(0, 0, self.width, self.height);
//        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(@0);
//            make.left.equalTo(@0);
//            make.right.equalTo(@0);
//            make.bottom.equalTo(@0);
//        }];
        scrollView.pagingEnabled=YES;
        scrollView.bounces=NO;
        scrollView.frame=self.bounds;
        scrollView.showsHorizontalScrollIndicator=NO;
        scrollView.showsVerticalScrollIndicator=NO;
        scrollView.contentSize=CGSizeMake(self.width*2, self.height);
        scrollView.delegate=self;
        scrollView.backgroundColor = [UIColor clearColor];
        self.scrollView = scrollView;
        
        UIView * firstBaseView = [[UIView alloc] init];
        [scrollView addSubview:firstBaseView];
        firstBaseView.frame = CGRectMake(0, 0, self.width, self.height);
        firstBaseView.backgroundColor = [UIColor clearColor];
        self.firstBaseView = firstBaseView;
        [self createShareBtnWithIndex:0 superview:firstBaseView];
        
        UIView * secBaseView = [[UIView alloc] init];
        [scrollView addSubview:secBaseView];
        secBaseView.frame = CGRectMake(self.width, 0, self.width, self.height);
        secBaseView.backgroundColor = [UIColor clearColor];
        self.secBaseView = secBaseView;
        [self createShareBtnWithIndex:6 superview:secBaseView];
        
        [self createMyPageView];
        
        
    }else
    {
        UIView * baseView = [[UIView alloc] init];
        [self addSubview:baseView];
        baseView.frame = CGRectMake(0, 0, self.width, self.height);
        baseView.backgroundColor = [UIColor clearColor];
        [self createShareBtnWithIndex:0 superview:baseView];
        self.baseView = baseView;
    }
    UILabel * shareLabel = [[UILabel alloc] init];
    [self addSubview:shareLabel];
    [shareLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_centerY).offset(-120);
        make.centerX.equalTo(self.mas_centerX);
        make.width.equalTo(@250);
        make.height.equalTo(@20);
    }];
    shareLabel.font = [UIFont systemFontOfSize:15];
    shareLabel.textAlignment = NSTextAlignmentCenter;
    shareLabel.textColor = [UIColor whiteColor];
    shareLabel.text = FGGetStringWithKeyFromTable(SHARE, nil);
    helper * helperInstance = [helper sharedInstance];
    CGFloat statusHeight = helperInstance.statusHeight;
    UIButton * closeBtn = [[UIButton alloc] init];
    [self addSubview:closeBtn];
    [closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@-30);
        make.top.equalTo(@(30 + statusHeight - 20));
        make.width.equalTo(@20);
        make.height.equalTo(@20);
    }];
    [closeBtn setImage:[UIImage imageNamed:@"cancel.png"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    
    
}
# pragma mark --添加页数控制条--
- (void)createMyPageView
{
    MyPageView * pageView = [[MyPageView alloc] init];
    [self addSubview:pageView];
    pageView.frame = CGRectMake(10, self.height * 0.5 + 125, 25 * 2 + 10, 10);
    pageView.center = CGPointMake(self.width*0.5, pageView.center.y);
    pageView.borderColor = [UIColor colorWithHexString:@"#FFFFFF"];
    pageView.currentBgColor = [UIColor colorWithRed:0.97f green:0.97f blue:0.97f alpha:1.00f];
    pageView.numberOfPages = 2;
    pageView.currentPage = 0;
    self.pageView = pageView;
}
- (void)refresh
{
    self.baseView.frame = CGRectMake(0, 0, self.width, self.height);
    self.scrollView.frame = CGRectMake(0, 0, self.width, self.height);
    self.scrollView.contentSize = CGSizeMake(self.width*2, self.height);
    self.firstBaseView.frame = CGRectMake(0, 0, self.width, self.height);
    self.secBaseView.frame = CGRectMake(self.width, 0, self.width, self.height);
    self.pageView.frame = CGRectMake(10, self.height * 0.5 + 125, 25 + 10, 10);
    self.pageView.center = CGPointMake(self.width*0.5, self.pageView.center.y);
}
- (void)createShareBtnWithIndex:(int)index superview:(UIView *)superview
{
    for (int i=index;i<self.dataArr.count && i < index + 6;i++)
    {
        UIButton * btn=[[UIButton alloc] init];
        [superview addSubview:btn];
        int divisible = 0;
        if (i > 5) {
            divisible = (i-6)/3;
        }else
        {
            divisible = i/3;
        }
        CGFloat yOffset = 0;
        if (divisible == 0) {
            yOffset = -45;
        }else
        {
            yOffset = 45;
        }
        int residue = i%3;
        NSLog(@"i=%d,residue = %d",i,residue);
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(superview.mas_centerY).offset(yOffset);
            make.centerX.equalTo(superview.mas_centerX).offset((residue -1) * 100);
            make.width.equalTo(@50);
            make.height.equalTo(@50);
        }];
        btn.tag=[self.indexArr[i] integerValue];
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [btn setImage:[UIImage imageNamed:self.dataArr[i]] forState:UIControlStateNormal];
        
        UILabel * nameLabel=[[UILabel alloc] init];
        [superview addSubview:nameLabel];
        [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btn.mas_bottom).offset(10);
            make.centerX.equalTo(btn.mas_centerX);
            make.width.equalTo(@130);
            make.height.equalTo(@15);
        }];
        nameLabel.textAlignment=NSTextAlignmentCenter;
        nameLabel.font=[UIFont systemFontOfSize:13];
        nameLabel.textColor=[UIColor colorWithHexString:@"#FFFFFF" alpha:0.7];
        nameLabel.text=self.nameDataArr[i];
    }
}
#pragma mark --关闭--
- (void)closBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(mediaShareViewQuit:)]) {
        [self.delegate mediaShareViewQuit:self];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
       
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
- (void)show
{
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)btnClick:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(mediaShareViewDidClick:andIndex:)]) {
        [self.delegate mediaShareViewDidClick:self andIndex:btn.tag];
    }
    if ([self.delegate respondsToSelector:@selector(mediaShareViewQuit:)]) {
        [self.delegate mediaShareViewQuit:self];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark --UIScrollViewDelegate代理方法--
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int index=scrollView.contentOffset.x/(ScreenWidth-40);
    
    self.pageView.currentPage=index;
    
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   

@end
