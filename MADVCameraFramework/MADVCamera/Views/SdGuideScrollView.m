//
//  SdGuideScrollView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/3/20.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "SdGuideScrollView.h"
#import "Masonry.h"
#import "PlayScrollModel.h"
#import "MyPageView.h"

@interface SdGuideScrollView()<UIScrollViewDelegate>
@property(nonatomic,weak)MyPageView * pageControl;
@end

@implementation SdGuideScrollView
- (void)setDataSource:(NSArray *)dataSource
{
    _dataSource = dataSource;
    [self createMyPageView];
    UIScrollView * scrollView = [[UIScrollView alloc] init];
    [self addSubview:scrollView];
    scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake(self.frame.size.width*dataSource.count, self.frame.size.height);
    scrollView.showsHorizontalScrollIndicator = FALSE;
    scrollView.pagingEnabled=YES;
    scrollView.bounces=NO;
    
    for (int i = 0; i<self.dataSource.count; i++) {
        PlayScrollModel * playScrollModel = self.dataSource[i];
        
        UIView * baseView = [[UIView alloc] init];
        [scrollView addSubview:baseView];
        baseView.frame = CGRectMake(scrollView.width * i, 0, scrollView.width, scrollView.height);
        
        
        UILabel * titleLabel = [[UILabel alloc] init];
        [baseView addSubview:titleLabel];
        titleLabel.frame = CGRectMake((baseView.width - 250)*0.5, self.height-40-10 - 15 - 20, 250, 20);
//        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.bottom.equalTo(self.pageControl.mas_top).offset(-15);
//            make.centerX.equalTo(baseView.mas_centerX);
//            make.width.equalTo(@250);
//            make.height.equalTo(@20);
//        }];
        titleLabel.numberOfLines = 0;
        titleLabel.font = [UIFont systemFontOfSize:17];
        titleLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.text = playScrollModel.title;
        [titleLabel sizeToFit];
        titleLabel.y = self.height-40-10 - 15 - titleLabel.height;
        if (titleLabel.width < 250) {
            titleLabel.width = 250;
        }
        
        UIImageView * imageView = [[UIImageView alloc] init];
        [baseView addSubview:imageView];
        if (ScreenWidth > 320) {
            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(@50);
                make.left.equalTo(@0);
                make.right.equalTo(@-30);
                make.bottom.equalTo(titleLabel.mas_top).offset(-50);
            }];
        }else
        {
            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(@50);
                make.left.equalTo(@0);
                make.right.equalTo(@-100);
                make.bottom.equalTo(titleLabel.mas_top).offset(-50);
            }];
        }
        
        imageView.image = [UIImage imageNamed:playScrollModel.filename];
    }
    
}
# pragma mark --添加页数控制条--
- (void)createMyPageView
{
    MyPageView * pageView = [[MyPageView alloc] init];
    [self addSubview:pageView];
    pageView.frame = CGRectMake(10, self.height-40-10, 25 * (self.dataSource.count -1) + 10, 10);
    pageView.center = CGPointMake(self.width*0.5, pageView.center.y);
    pageView.numberOfPages = self.dataSource.count;
    pageView.currentPage = 0;
    self.pageControl = pageView;
//    UIPageControl * pageControl = [[UIPageControl alloc] init];
//    [self addSubview:pageControl];
//    [pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(@-50);
//        make.centerX.equalTo(self.mas_centerX);
//        make.width.equalTo(@100);
//        make.height.equalTo(@30);
//    }];
//    pageControl.numberOfPages = self.dataSource.count;
//    pageControl.currentPage = 0;
//    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
//    pageControl.pageIndicatorTintColor = [UIColor grayColor];
//    self.pageControl = pageControl;
}
#pragma mark --UIScrollViewDelegate代理方法的实现--
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int index=scrollView.contentOffset.x/self.frame.size.width;
    self.pageControl.currentPage = index;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
