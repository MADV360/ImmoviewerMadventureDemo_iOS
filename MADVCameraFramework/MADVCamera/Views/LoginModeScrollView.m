//
//  LoginModeScrollView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/5/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "LoginModeScrollView.h"
#import "MyPageView.h"
#import "Masonry.h"
#import "ImageTitleView.h"
#import "helper.h"

@interface LoginModeScrollView() <UIScrollViewDelegate,ImageTitleViewDelegate>
@property(nonatomic,weak)MyPageView * pageView;
@end

@implementation LoginModeScrollView
- (void)loadLoginModeScrollView
{
    NSString * location = [helper readProfileString:LOCATION];
    
    UIScrollView * scrollView = [[UIScrollView alloc] init];
    [self addSubview:scrollView];
    scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake(self.frame.size.width*2, self.frame.size.height);
    scrollView.showsHorizontalScrollIndicator = FALSE;
    scrollView.pagingEnabled=YES;
    scrollView.bounces=NO;
    
    UIView * mainView = [[UIView alloc] init];
    [scrollView addSubview:mainView];
    if ([location isEqualToString:@"local"] || [helper isNull:location]) {
        mainView.frame = CGRectMake(0, 0, self.width, self.height);
    }else
    {
        mainView.frame = CGRectMake(self.width, 0, self.width, self.height);
    }
    
    mainView.backgroundColor = [UIColor clearColor];
    
    
    
    ImageTitleView * imageTitleView = [[ImageTitleView alloc] init];
    [mainView addSubview:imageTitleView];
    imageTitleView.title = FGGetStringWithKeyFromTable(WEICHAT, nil);
    imageTitleView.imageName = @"wechat.png";
    imageTitleView.loginIndex = Wechat_Login;
    imageTitleView.delegate = self;
    [imageTitleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.right.equalTo(mainView.mas_centerX);
        make.width.equalTo(@80);
        make.height.equalTo(@70);
    }];
    [imageTitleView loadImageTitleView];
    
    ImageTitleView * qqView = [[ImageTitleView alloc] init];
    [mainView addSubview:qqView];
    qqView.title = @"QQ";
    qqView.imageName = @"new_qq.png";
    qqView.loginIndex = QQ_Login;
    qqView.delegate = self;
    [qqView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(mainView.mas_centerX);
        make.width.equalTo(@80);
        make.height.equalTo(@70);
    }];
    [qqView loadImageTitleView];
    
    ImageTitleView * miView = [[ImageTitleView alloc] init];
    [mainView addSubview:miView];
    miView.title = FGGetStringWithKeyFromTable(XIAOMI, nil);
    miView.imageName = @"xiaomi.png";
    miView.loginIndex = Mi_Login;
    miView.delegate = self;
    [miView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.right.equalTo(imageTitleView.mas_left);
        make.width.equalTo(@80);
        make.height.equalTo(@70);
    }];
    [miView loadImageTitleView];
    
    ImageTitleView * wbView = [[ImageTitleView alloc] init];
    [mainView addSubview:wbView];
    wbView.title = FGGetStringWithKeyFromTable(WEIBO, nil);
    wbView.imageName = @"new_webo.png";
    wbView.loginIndex = Webo_Login;
    wbView.delegate = self;
    [wbView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(qqView.mas_right);
        make.width.equalTo(@80);
        make.height.equalTo(@70);
    }];
    [wbView loadImageTitleView];
    
    
    UIView * outView = [[UIView alloc] init];
    [scrollView addSubview:outView];
    if ([location isEqualToString:@"local"] || [helper isNull:location])
    {
        outView.frame = CGRectMake(self.width, 0, self.width, self.height);
    }else
    {
        outView.frame = CGRectMake(0, 0, self.width, self.height);
    }
    
    outView.backgroundColor = [UIColor clearColor];
    
    ImageTitleView * googleView = [[ImageTitleView alloc] init];
    [outView addSubview:googleView];
    googleView.title = @"Google";
    googleView.imageName = @"google.png";
    googleView.loginIndex = Google_Login;
    googleView.delegate = self;
    [googleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.centerX.equalTo(outView.mas_centerX);
        make.width.equalTo(@80);
        make.height.equalTo(@70);
    }];
    [googleView loadImageTitleView];
    
    ImageTitleView * facebookView = [[ImageTitleView alloc] init];
    [outView addSubview:facebookView];
    facebookView.title = @"Facebook";
    facebookView.imageName = @"facebook.png";
    facebookView.loginIndex = Facebook_Login;
    facebookView.delegate = self;
    [facebookView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.right.equalTo(googleView.mas_left);
        make.width.equalTo(@80);
        make.height.equalTo(@70);
    }];
    [facebookView loadImageTitleView];
    
    ImageTitleView * twitterView = [[ImageTitleView alloc] init];
    [outView addSubview:twitterView];
    twitterView.title = @"Twitter";
    twitterView.imageName = @"new_Twitter.png";
    twitterView.loginIndex = Twitter_Login;
    twitterView.delegate = self;
    [twitterView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(googleView.mas_right);
        make.width.equalTo(@80);
        make.height.equalTo(@70);
    }];
    [twitterView loadImageTitleView];
    
    
    
    [self createMyPageView];
    
}

# pragma mark --添加页数控制条--
- (void)createMyPageView
{
    MyPageView * pageView = [[MyPageView alloc] init];
    [self addSubview:pageView];
    pageView.frame = CGRectMake(10, self.height-10, 25 * (2 -1) + 10, 10);
    pageView.center = CGPointMake(self.width*0.5, pageView.center.y);
    pageView.currentBgColor = [UIColor colorWithHexString:@"#46a4ea"];
    pageView.borderColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
    pageView.numberOfPages = 2;
    pageView.currentPage = 0;
    self.pageView = pageView;
}

#pragma mark --UIScrollViewDelegate代理方法的实现--
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int index=scrollView.contentOffset.x/self.frame.size.width;
    self.pageView.currentPage = index;
}

#pragma mark --ImageTitleViewDelegate代理方法的实现--
- (void)imageTitleViewClick:(ImageTitleView *)imageTitleView loginIndex:(NSInteger)loginIndex
{
    if ([self.delegate respondsToSelector:@selector(loginModeScrollViewClick:loginIndex:)]) {
        [self.delegate loginModeScrollViewClick:self loginIndex:loginIndex];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
