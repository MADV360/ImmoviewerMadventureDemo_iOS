//
//  MineHeadView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/6/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MineHeadView.h"
#import "Masonry.h"
#import "UIColor+MVExtensions.h"
#import "LXInfoView.h"
#import "UIImageView+WebCache.h"
#import "UIView+Frame.h"
#import "UIImage+Blur.h"
#import "SDWebImageManager.h"

@interface MineHeadView()<LXInfoViewDelegate>

@property(nonatomic,weak)UIImageView * headImage;
@property(nonatomic,weak)UIButton * loginBtn;
@property(nonatomic,weak)LXInfoView * infoView;
//用户名称
@property(nonatomic,weak)UILabel * nameLabel;
@property(nonatomic,weak)UIButton * quitBtn;
@property(nonatomic,weak)UIButton * backBtn;
@property(nonatomic,weak)UIImageView * vipImageView;
@end

@implementation MineHeadView
- (void)loadHeadView
{
    UIImageView * imageView=[[UIImageView alloc] init];
    [self addSubview:imageView];
    helper * helperInstance = [helper sharedInstance];
    CGFloat statusHeight = helperInstance.statusHeight;
    imageView.frame=CGRectMake(0, 0, ScreenWidth, 211 + (statusHeight - 20));
    imageView.backgroundColor=[UIColor colorWithHexString:@"#46a4ea"];
    imageView.userInteractionEnabled=YES;
    self.imageView=imageView;
    
    UILabel * tapLabel=[[UILabel alloc] init];
    [self addSubview:tapLabel];
    [tapLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(imageView.mas_centerX);
        make.centerY.equalTo(imageView.mas_centerY);
        make.width.equalTo(@150);
        make.height.equalTo(@150);
    }];
    tapLabel.userInteractionEnabled=YES;
    
    UIImageView * headImage=[[UIImageView alloc] init];
    [tapLabel addSubview:headImage];
    [headImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(imageView.mas_centerX);
        make.centerY.equalTo(imageView.mas_centerY);
        make.width.equalTo(@74);
        make.height.equalTo(@74);
    }];
    headImage.layer.cornerRadius=37;
    headImage.layer.masksToBounds=YES;
    headImage.userInteractionEnabled=YES;
    self.headImage=headImage;
    
    //头像点击事件
    UITapGestureRecognizer * headTap=[[UITapGestureRecognizer alloc] init];
    [headTap addTarget:self action:@selector(headTap:)];
    [tapLabel addGestureRecognizer:headTap];
    
    UIImageView * vipImageView = [[UIImageView alloc] init];
    [tapLabel addSubview:vipImageView];
    [vipImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(headImage.mas_bottom).offset(-10);
        make.right.equalTo(headImage.mas_right).offset(-10);
        make.width.equalTo(@15);
        make.height.equalTo(@15);
    }];
    vipImageView.image = [UIImage imageNamed:@"vip.png"];
    vipImageView.hidden = YES;
    self.vipImageView = vipImageView;
    
    //返回
    UIButton * backBtn=[[UIButton alloc] init];
    [self addSubview:backBtn];

//    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(@31);
////        make.right.equalTo(imageView.mas_centerX).offset(-ScreenWidth*0.5+15+34);
//        make.left.equalTo(@15);
//        make.width.equalTo(@34);
//        make.height.equalTo(@34);
//    }];
    backBtn.frame=CGRectMake(15, statusHeight + 5, 34, 34);
    [backBtn setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
    backBtn.imageEdgeInsets=UIEdgeInsetsMake(0, 0, 0, 0);
    self.backBtn=backBtn;
    
//    UIButton * loginBtn=[[UIButton alloc] init];
//    [tapLabel addSubview:loginBtn];
//    [loginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(headImage.mas_bottom).offset(10);
//        make.centerX.equalTo(imageView.mas_centerX);
//        make.width.equalTo(@60);
//        make.height.equalTo(@20);
//    }];
//    [loginBtn setTitle:@"登录／注册" forState:UIControlStateNormal];
//    [loginBtn setTitleColor:[UIColor colorWithHexString:@"#FFFFFF"] forState:UIControlStateNormal];
//    loginBtn.titleLabel.font=[UIFont systemFontOfSize:15];
//    
////    [loginBtn addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
//    self.loginBtn=loginBtn;
    
    //退出
//    UIButton * quitBtn=[[UIButton alloc] init];
//    [imageView addSubview:quitBtn];
//    [quitBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(@31);
////        make.right.equalTo(@-15);
//        make.left.equalTo(imageView.mas_centerX).offset(ScreenWidth*0.5-15-80);
//        make.width.equalTo(@80);
//        make.height.equalTo(@34);
//    }];
//    [quitBtn setTitle:@"退出" forState:UIControlStateNormal];
//    [quitBtn setTitleColor:[UIColor colorWithHexString:@"#FFFFFF"] forState:UIControlStateNormal];
//    [quitBtn addTarget:self action:@selector(quitBtnClick) forControlEvents:UIControlEventTouchUpInside];
//    quitBtn.titleLabel.font=[UIFont systemFontOfSize:15];
//    quitBtn.titleEdgeInsets=UIEdgeInsetsMake(8, 50, 8, 0);
//    self.quitBtn=quitBtn;
    
    //用户名称
    UILabel * nameLabel=[[UILabel alloc] init];
    [tapLabel addSubview:nameLabel];
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(headImage.mas_bottom).offset(10);
        make.centerX.equalTo(imageView.mas_centerX);
        make.width.equalTo(@200);
        make.height.equalTo(@20);
    }];
    nameLabel.textColor=[UIColor colorWithHexString:@"#FFFFFF" alpha:0.95];
    nameLabel.textAlignment=NSTextAlignmentCenter;
    nameLabel.font=[UIFont systemFontOfSize:13];
    nameLabel.userInteractionEnabled=YES;
    self.nameLabel=nameLabel;
    
    LXInfoView * infoView=[[LXInfoView alloc] init];
    [self addSubview:infoView];
    infoView.frame=CGRectMake(0, 211 + (statusHeight - 20), [UIScreen mainScreen].bounds.size.width, 60);
    [infoView loadInfoView];
    infoView.delegate=self;
    infoView.backgroundColor=[UIColor whiteColor];
    self.infoView=infoView;
    
    UIView * lineView=[[UIView alloc] init];
    [self addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@1);
    }];
    
    lineView.backgroundColor=[UIColor colorWithRed:0.93f green:0.93f blue:0.94f alpha:1.00f];
    
}
#pragma mark --LXInfoViewDelegate代理方法的实现--
- (void)infoViewDidTouch:(LXInfoView *)infoView andIndex:(NSInteger)index
{
    if ([self.delegate respondsToSelector:@selector(mineHeadViewInfoDidTouch:andIndex:)]) {
        [self.delegate mineHeadViewInfoDidTouch:self andIndex:index];
    }
}

- (void)setInfoWithIsLogin:(BOOL)isLogin andHeadImage:(NSString *)headUrl andInfoArr:(NSArray *)infoArr andName:(NSString *)name level:(NSString *)level
{
    if (isLogin) {
        self.quitBtn.hidden=NO;
        self.loginBtn.hidden=YES;
        NSURL * imageUrl=[NSURL URLWithString:headUrl];
        if (headUrl.length!=0) {
            [[SDWebImageManager sharedManager] downloadImageWithURL:imageUrl options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                // 下载进度block
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                // 下载完成block
                if (image!=nil) {
                    self.imageView.image=[UIImage boxblurImage:image withBlurNumber:1 andIsNet:YES];
                }
                
            }];
            [self.headImage sd_setImageWithURL:imageUrl];
        }else
        {
            self.headImage.image=[UIImage imageNamed:@"mine_avatar.png"];
        }
        if ([level isEqualToString:@"0"]) {
            self.vipImageView.hidden = YES;
        }else if ([level isEqualToString:@"1"])
        {
            self.vipImageView.hidden = NO;
        }
        self.nameLabel.text=name;
        
    }else
    {
        self.vipImageView.hidden = YES;
        self.nameLabel.text=name;
        self.quitBtn.hidden=YES;
        self.loginBtn.hidden=NO;
        self.imageView.image=nil;
        self.headImage.image=[UIImage imageNamed:@"mine_avatar.png"];
    }
    self.infoView.infoArr=infoArr;
}


#pragma mark --返回事件--
- (void)backClick
{
    if ([self.delegate respondsToSelector:@selector(mineHeadViewBack:)]) {
        [self.delegate mineHeadViewBack:self];
    }
}
#pragma mark --点击头像事件--
- (void)headTap:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(mineHeadViewInfo:)]) {
        [self.delegate mineHeadViewInfo:self];
    }
}
- (void)updateFrameWithOffsety:(CGFloat)y
{
    helper * helperInstance = [helper sharedInstance];
    CGFloat statusHeight = helperInstance.statusHeight;
    self.imageView.frame=CGRectMake(y*0.5, y, ScreenWidth-y, 211 + (statusHeight - 20)-y);
    self.backBtn.y=statusHeight + 5 + y;
    self.quitBtn.y=30+y;
    
}

@end
