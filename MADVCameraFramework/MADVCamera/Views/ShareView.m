//
//  ShareView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/6/27.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "ShareView.h"
#import "Masonry.h"
#import "MyPageView.h"

@interface ShareView()<UIScrollViewDelegate>
@property(nonatomic,weak)UILabel * shareLabel;
@property(nonatomic,weak)UIView * baseView;
@property(nonatomic,weak)MyPageView * pageView;
@end


@implementation ShareView

- (void)loadShareView
{
    UIView * baseView=[[UIView alloc] init];
    [self addSubview:baseView];
    if (self.dataArr.count > 6) {
        baseView.frame = CGRectMake(10, ScreenHeight, ScreenWidth - 20, 358);
    }else
    {
        baseView.frame = CGRectMake(10, ScreenHeight, ScreenWidth - 20, 328);
    }
    baseView.backgroundColor=[UIColor colorWithHexString:@"#F7F7F7"];
    baseView.layer.masksToBounds=YES;
    baseView.layer.cornerRadius=5;
    self.baseView=baseView;
    
    if (self.dataArr.count > 6) {
        UIScrollView * scrollView=[[UIScrollView alloc] init];
        [baseView addSubview:scrollView];
        scrollView.frame = CGRectMake(0, 0, baseView.width, baseView.height - 49);
        scrollView.pagingEnabled=YES;
        scrollView.bounces=NO;
        scrollView.frame=self.bounds;
        scrollView.showsHorizontalScrollIndicator=NO;
        scrollView.showsVerticalScrollIndicator=NO;
        scrollView.contentSize=CGSizeMake((ScreenWidth - 20)*2, baseView.height - 49);
        scrollView.delegate=self;
        
        
        UIView * firstBaseView = [[UIView alloc] init];
        [scrollView addSubview:firstBaseView];
        firstBaseView.frame = CGRectMake(0, 0, ScreenWidth - 20, baseView.height - 49);
        firstBaseView.backgroundColor = [UIColor colorWithHexString:@"#F7F7F7"];
        [self createShareBtnWithIndex:0 superview:firstBaseView];
        
        UIView * secBaseView = [[UIView alloc] init];
        [scrollView addSubview:secBaseView];
        secBaseView.frame = CGRectMake(ScreenWidth - 20, 0, ScreenWidth - 20, baseView.height - 49);
        secBaseView.backgroundColor = [UIColor colorWithHexString:@"#F7F7F7"];;
        [self createShareBtnWithIndex:6 superview:secBaseView];
        
        [self createMyPageView];
        
    }else
    {
        [self createShareBtnWithIndex:0 superview:self.baseView];
    }
    
    UILabel * shareLabel=[[UILabel alloc] init];
    [baseView addSubview:shareLabel];
    [shareLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@20);
        make.centerX.equalTo(baseView.mas_centerX);
        make.height.equalTo(@15);
        make.width.equalTo(@100);
    }];
    shareLabel.font=[UIFont systemFontOfSize:15];
    shareLabel.textColor=[UIColor colorWithHexString:@"#000000"];
    shareLabel.text=FGGetStringWithKeyFromTable(SHARE, nil);
    shareLabel.textAlignment=NSTextAlignmentCenter;
    self.shareLabel=shareLabel;
    
    UIView * lineView=[[UIView alloc] init];
    [baseView addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@-49);
        make.height.equalTo(@1);
    }];
    lineView.backgroundColor=[UIColor colorWithRed:0.78f green:0.78f blue:0.78f alpha:1.00f];
    
    UILabel * closeImageView=[[UILabel alloc] init];
    [baseView addSubview:closeImageView];
    [closeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@49);
    }];
//    closeImageView.image=[UIImage imageNamed:@"icon_x_white.png"];
    closeImageView.backgroundColor=[UIColor colorWithHexString:@"#F2F2F2"];
    closeImageView.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.8];
    closeImageView.font=[UIFont systemFontOfSize:15];
    closeImageView.text=FGGetStringWithKeyFromTable(NOUPLOAD, nil);
    closeImageView.textAlignment=NSTextAlignmentCenter;
    closeImageView.userInteractionEnabled=YES;
    
    UITapGestureRecognizer * closeTap=[[UITapGestureRecognizer alloc] init];
    [closeTap addTarget:self action:@selector(closeTap:)];
    [closeImageView addGestureRecognizer:closeTap];
   
}

- (void)createShareBtnWithIndex:(int)index superview:(UIView *)superview
{
    CGFloat leftFloat=(ScreenWidth-20-50*5)*0.5;
    
    for (int i=index;i<self.dataArr.count && i < index + 6;i++) {
        UIButton * btn=[[UIButton alloc] init];
        [superview addSubview:btn];
        CGFloat y = 35 + 25 + (i/3)*100;
        if (i >= 6) {
            y = 35 + 25 + ((i-6)/3)*100;
        }
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(y));
            make.left.equalTo(@(leftFloat+100*(i%3)));
            make.width.equalTo(@50);
            make.height.equalTo(@50);
        }];
        btn.tag=[self.indexArr[i] integerValue];
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [btn setImage:[UIImage imageNamed:self.dataArr[i]] forState:UIControlStateNormal];
        
        
        UILabel * nameLabel=[[UILabel alloc] init];
        [superview addSubview:nameLabel];
        [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(btn.mas_bottom).offset(15);
            make.centerX.equalTo(btn.mas_centerX);
            make.width.equalTo(@100);
            make.height.equalTo(@15);
        }];
        nameLabel.textAlignment=NSTextAlignmentCenter;
        nameLabel.font=[UIFont systemFontOfSize:13];
        nameLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.5];
        nameLabel.text=self.nameDataArr[i];
    }
}

- (void)show
{
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        self.baseView.y = ScreenHeight - self.baseView.height;
    } completion:^(BOOL finished) {
        
    }];
}

# pragma mark --添加页数控制条--
- (void)createMyPageView
{
    MyPageView * pageView = [[MyPageView alloc] init];
    [self.baseView addSubview:pageView];
    pageView.frame = CGRectMake(10, self.baseView.height - 50 - 30, 25 * 2 + 10, 10);
    pageView.center = CGPointMake(self.center.x, pageView.center.y);
    pageView.borderColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
    pageView.currentBgColor = [UIColor colorWithRed:0.30f green:0.30f blue:0.30f alpha:1.00f];
    pageView.numberOfPages = 2;
    pageView.currentPage = 0;
    self.pageView = pageView;
}
#pragma mark --关闭--
- (void)closeTap:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(shareViewDidQuit:)]) {
        [self.delegate shareViewDidQuit:self];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0];
        self.baseView.y = ScreenHeight;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self.delegate respondsToSelector:@selector(shareViewDidQuit:)]) {
        [self.delegate shareViewDidQuit:self];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0];
        self.baseView.y = ScreenHeight;
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
- (void)setDataArr:(NSArray *)dataArr
{
    _dataArr=dataArr;
    
}

- (void)btnClick:(UIButton *)btn
{
    btn.selected=YES;
    
    if ([self.delegate respondsToSelector:@selector(shareViewDidClick:andIndex:)]) {
        [self.delegate shareViewDidClick:self andIndex:btn.tag];
    }
    if ([self.delegate respondsToSelector:@selector(shareViewDidQuit:)]) {
        [self.delegate shareViewDidQuit:self];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0];
        self.baseView.y = ScreenHeight;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
    
}

@end
