//
//  GuideScrollView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/28.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "GuideScrollView.h"
#import "Masonry.h"
#import "MyPageView.h"
@interface GuideScrollView()<UIScrollViewDelegate>
@property(nonatomic,weak)UIScrollView * scrollView;
@property(nonatomic,weak)MyPageView * pageControl;
@end

@implementation GuideScrollView
- (void)loadGuideScrollView
{
    [self createScrollView];
    [self createMyPageView];
}
#pragma mark --创建ScrollView--
- (void)createScrollView
{
    UIScrollView * scrollView=[[UIScrollView alloc] init];
    [self addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    scrollView.pagingEnabled=YES;
    scrollView.bounces=NO;
    scrollView.frame=self.bounds;
    scrollView.showsHorizontalScrollIndicator=NO;
    scrollView.showsVerticalScrollIndicator=NO;
    scrollView.contentSize=CGSizeMake(ScreenWidth*3, self.height);
    scrollView.delegate=self;
    self.scrollView = scrollView;
    
}
# pragma mark --添加页数控制条--
- (void)createMyPageView
{
    MyPageView * pageView = [[MyPageView alloc] init];
    [self addSubview:pageView];
    pageView.frame = CGRectMake(10, self.height-10 - 35, 25 * 2 + 10, 10);
    pageView.center = CGPointMake(self.center.x, pageView.center.y);
    pageView.borderColor = [UIColor whiteColor];
    pageView.currentBgColor = [UIColor whiteColor];
    pageView.numberOfPages = 3;
    pageView.currentPage = 0;
    self.pageControl = pageView;
//    UIPageControl * pageControl = [[UIPageControl alloc] init];
//    [self addSubview:pageControl];
//    [pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(@-35);
//        make.centerX.equalTo(self.mas_centerX);
//        make.width.equalTo(@100);
//        make.height.equalTo(@30);
//    }];
//    pageControl.numberOfPages = 3;
//    pageControl.currentPage = 0;
//    pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
//    self.pageControl = pageControl;
}
- (void)setDataArr:(NSArray *)dataArr
{
    _dataArr = dataArr;
    for (int i = 0; i < dataArr.count; i++) {
        UIView * baseView = [[UIView alloc] init];
        [self.scrollView addSubview:baseView];
        baseView.frame = CGRectMake(ScreenWidth * i, 0, ScreenWidth, self.height);
        baseView.backgroundColor = [UIColor clearColor];
        
        NSArray * arr = self.dataArr[i];
        if (arr.count == 1) {
            UILabel * titleLabel = [[UILabel alloc] init];
            [baseView addSubview:titleLabel];
//            [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//                make.bottom.equalTo(@-120);
//                make.centerX.equalTo(baseView.mas_centerX);
//                make.height.equalTo(@17);
//                make.width.equalTo(@300);
//            }];
            titleLabel.frame = CGRectMake(15, baseView.height - 120 - 17, baseView.width - 30, 17);
            titleLabel.numberOfLines = 0;
            titleLabel.font = [UIFont systemFontOfSize:16];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.text = arr[0];
            [titleLabel sizeToFit];
            if (titleLabel.width < baseView.width - 30) {
                titleLabel.width = baseView.width - 30;
            }
            //titleLabel.y = baseView.height - 120 - titleLabel.height;
        }else
        {
            UILabel * titleLabel = [[UILabel alloc] init];
            [baseView addSubview:titleLabel];
            [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(@-120);
                make.centerX.equalTo(baseView.mas_centerX);
                make.height.equalTo(@17);
                make.width.equalTo(@150);
            }];
            titleLabel.font = [UIFont systemFontOfSize:16];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.text = arr[0];
            
            UILabel * descLabel = [[UILabel alloc] init];
            [baseView addSubview:descLabel];
            [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(titleLabel.mas_bottom).offset(2);
                make.centerX.equalTo(baseView.mas_centerX);
                make.height.equalTo(@17);
                make.width.equalTo(@250);
            }];
            descLabel.font = [UIFont systemFontOfSize:16];
            descLabel.textColor = [UIColor whiteColor];
            descLabel.textAlignment = NSTextAlignmentCenter;
            descLabel.text = arr[1];
        }
    }
}
#pragma mark --UIScrollViewDelegate代理方法--
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int index=scrollView.contentOffset.x/ScreenWidth;
   
    self.pageControl.currentPage=index;
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
