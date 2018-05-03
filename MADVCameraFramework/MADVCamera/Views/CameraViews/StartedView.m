//
//  StartedView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/19.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "StartedView.h"
#import "Masonry.h"

@implementation StartedView
- (void)loadStartedView
{
    UIImageView * backgroundView=[[UIImageView alloc] init];
    [self addSubview:backgroundView];
    [backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    backgroundView.image=[UIImage imageNamed:@"backimage.png"];
    
    UIView * backView=[[UIView alloc] init];
    [self addSubview:backView];
    [backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    backView.backgroundColor=[UIColor colorWithHexString:@"#414347" alpha:0.85];
    
    UIImageView * imageView=[[UIImageView alloc] init];
    [self addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
        make.width.equalTo(@150);
        make.height.equalTo(@144);
    }];
    imageView.image=[UIImage imageNamed:@"icon_camera_hig.png"];
    
    UILabel * subDescLabel=[[UILabel alloc] init];
    [self addSubview:subDescLabel];
//    [subDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(imageView.mas_top).offset(-20);
//        make.centerX.equalTo(imageView.mas_centerX);
//        make.width.equalTo(@(ScreenWidth));
//        make.height.equalTo(@13);
//    }];
    subDescLabel.frame = CGRectMake(20, ScreenHeight * 0.5 - 72 - 20 -13, ScreenWidth-40, 13);
    subDescLabel.numberOfLines = 0;
    subDescLabel.font=[UIFont systemFontOfSize:13];
    subDescLabel.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    subDescLabel.textAlignment=NSTextAlignmentCenter;
    subDescLabel.text=FGGetStringWithKeyFromTable(SHORTWIFI, nil);
    [subDescLabel sizeToFit];
    subDescLabel.y = ScreenHeight * 0.5 - 72 - 20 - subDescLabel.height;
    subDescLabel.x = (ScreenWidth - subDescLabel.width)*0.5;
    
    UILabel * descLabel=[[UILabel alloc] init];
    [self addSubview:descLabel];
    descLabel.frame = CGRectMake(20, CGRectGetMaxY(subDescLabel.frame)-subDescLabel.height-5 -13, ScreenWidth-40, 13);
//    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(subDescLabel.mas_top).offset(-5);
//        make.left.equalTo(@15);
//        make.right.equalTo(@-15);
//        make.height.equalTo(@13);
//    }];
    descLabel.font=[UIFont systemFontOfSize:13];
    descLabel.numberOfLines = 0;
    descLabel.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    descLabel.textAlignment=NSTextAlignmentCenter;
    descLabel.text=FGGetStringWithKeyFromTable(SURECAMERASTARTING, nil);
    [descLabel sizeToFit];
    descLabel.y = CGRectGetMaxY(subDescLabel.frame)-subDescLabel.height-5 -descLabel.height;
    descLabel.x = (ScreenWidth - descLabel.width)*0.5;
    
    UILabel * titleLabe=[[UILabel alloc] init];
    [self addSubview:titleLabe];
    [titleLabe mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(descLabel.mas_top).offset(-10);
        make.centerX.equalTo(self.mas_centerX);
        make.width.equalTo(@150);
        make.height.equalTo(@20);
    }];
    titleLabe.textAlignment=NSTextAlignmentCenter;
    titleLabe.font=[UIFont systemFontOfSize:20];
    titleLabe.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    titleLabe.text=FGGetStringWithKeyFromTable(OPENWIFI, nil);
    
    UILabel * buyLabel = [[UILabel alloc] init];
    [self addSubview:buyLabel];
    [buyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(imageView.mas_bottom).offset(82);
        make.centerX.equalTo(self.mas_centerX);
        make.width.equalTo(@300);
        make.height.equalTo(@20);
    }];
    buyLabel.textAlignment=NSTextAlignmentCenter;
    buyLabel.font=[UIFont systemFontOfSize:13];
    buyLabel.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    NSMutableAttributedString * agreement = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(BUYCAMERA, nil)];
    NSString * language = [NSString getAppLanguage];
    if ([language isEqualToString:@"zh-Hans"] || [language isEqualToString:@"zh-Hant"]) {
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#2fd5fe"] range:NSMakeRange(FGGetStringWithKeyFromTable(BUYCAMERA, nil).length - 4, 4)];
    }else if ([language isEqualToString:@"es"])
    {
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#2fd5fe"] range:NSMakeRange(FGGetStringWithKeyFromTable(BUYCAMERA, nil).length - 13, 13)];
    }else if ([language isEqualToString:@"ru"])
    {
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#2fd5fe"] range:NSMakeRange(FGGetStringWithKeyFromTable(BUYCAMERA, nil).length - 14, 14)];
    }else
    {
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#2fd5fe"] range:NSMakeRange(FGGetStringWithKeyFromTable(BUYCAMERA, nil).length - 8, 8)];
    }
    
    buyLabel.attributedText=agreement;
    
    UIView * buyView = [[UIView alloc] init];
    [self addSubview:buyView];
    [buyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(buyLabel.mas_centerY);
        make.centerX.equalTo(self.mas_centerX);
        make.width.equalTo(@150);
        make.height.equalTo(@35);
    }];
    buyView.backgroundColor = [UIColor clearColor];
    
    UITapGestureRecognizer * buyTapGes = [[UITapGestureRecognizer alloc] init];
    [buyTapGes addTarget:self action:@selector(buyTapGes:)];
    [buyView addGestureRecognizer:buyTapGes];
    
    helper * helperInstance = [helper sharedInstance];
    CGFloat statusHeight = helperInstance.statusHeight;
    CGFloat bottomSafearea = 20;
    if (statusHeight > 20) {
        bottomSafearea = 34;
    }
    UIButton * startBtn=[[UIButton alloc] init];
    [self addSubview:startBtn];
    [startBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@(-bottomSafearea));
        make.left.equalTo(@15);
        make.right.equalTo(@-15);
        make.height.equalTo(@44);
    }];
    startBtn.backgroundColor=[UIColor clearColor];
    startBtn.layer.borderColor=[UIColor colorWithRed:0.50f green:0.50f blue:0.51f alpha:1.00f].CGColor;
    startBtn.layer.borderWidth=1;
    startBtn.layer.masksToBounds=YES;
    startBtn.layer.cornerRadius=15;
    [startBtn addTarget:self action:@selector(startBtn:) forControlEvents:UIControlEventTouchUpInside];
    [startBtn setTitle:FGGetStringWithKeyFromTable(STARTED, nil) forState:UIControlStateNormal];
    startBtn.titleLabel.font=[UIFont systemFontOfSize:15];
    [startBtn setTitleColor:[UIColor colorWithHexString:@"#FFFFFF" alpha:0.9] forState:UIControlStateNormal];
    
}

- (void)buyTapGes:(UITapGestureRecognizer *)tap
{
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"https://www.mi.com/mj-panorama-camera/"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.mi.com/mj-panorama-camera/"]];
    }
}

#pragma mark --启动--
- (void)startBtn:(UIButton *)btn
{
    NSLog(@"已启动");
    if ([self.delegate respondsToSelector:@selector(startedViewStarted:)]) {
        [self.delegate startedViewStarted:self];
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
