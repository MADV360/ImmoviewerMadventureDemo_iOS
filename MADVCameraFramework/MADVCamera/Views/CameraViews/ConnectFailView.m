//
//  ConnectFailView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/23.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "ConnectFailView.h"
#import "Masonry.h"

@interface ConnectFailView()
@property(nonatomic,weak)UILabel * subDescLabel;
@end

@implementation ConnectFailView
- (void)loadConnectFailView
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
        make.width.equalTo(@97);
        make.height.equalTo(@97);
    }];
    imageView.image=[UIImage imageNamed:@"icon_wifi.png"];
    
    UILabel * subDescLabel=[[UILabel alloc] init];
    [self addSubview:subDescLabel];
    [subDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(imageView.mas_top).offset(-20);
        make.left.equalTo(@15);
        make.right.equalTo(@-15);
        make.height.equalTo(@13);
    }];
    subDescLabel.font=[UIFont systemFontOfSize:13];
    subDescLabel.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    subDescLabel.textAlignment=NSTextAlignmentCenter;
    self.subDescLabel=subDescLabel;
    
    UILabel * descLabel=[[UILabel alloc] init];
    [self addSubview:descLabel];
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(subDescLabel.mas_top).offset(-5);
        make.left.equalTo(@15);
        make.right.equalTo(@-15);
        make.height.equalTo(@13);
    }];
    descLabel.font=[UIFont systemFontOfSize:13];
    descLabel.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    descLabel.textAlignment=NSTextAlignmentCenter;
    descLabel.text=FGGetStringWithKeyFromTable(PLEASECONNECTWIFI, nil);
    
    UILabel * titleLabe=[[UILabel alloc] init];
    [self addSubview:titleLabe];
    [titleLabe mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(descLabel.mas_top).offset(-10);
        make.left.equalTo(@15);
        make.right.equalTo(@-15);
        make.height.equalTo(@20);
    }];
    titleLabe.textAlignment=NSTextAlignmentCenter;
    titleLabe.font=[UIFont systemFontOfSize:20];
    titleLabe.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    titleLabe.text=FGGetStringWithKeyFromTable(CONNECTFAIL, nil);
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
    [startBtn setTitle:FGGetStringWithKeyFromTable(GOCONNECTWIFI, nil) forState:UIControlStateNormal];
    startBtn.titleLabel.font=[UIFont systemFontOfSize:15];
    [startBtn setTitleColor:[UIColor colorWithHexString:@"#FFFFFF" alpha:0.9] forState:UIControlStateNormal];
    
    
    UILabel * forgetPwdLabel=[[UILabel alloc] init];
    [self addSubview:forgetPwdLabel];
    forgetPwdLabel.frame = CGRectMake(ScreenWidth*0.5-50, ScreenHeight - 74 -13 - (bottomSafearea - 20), 100, 13);
//    [forgetPwdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(startBtn.mas_top).offset(-10);
//        make.centerX.equalTo(self.mas_centerX);
//        make.width.equalTo(@100);
//        make.height.equalTo(@13);
//    }];
    forgetPwdLabel.font=[UIFont systemFontOfSize:13];
    forgetPwdLabel.textColor=[UIColor colorWithHexString:@"#FFFFFF" alpha:0.6];
    forgetPwdLabel.textAlignment=NSTextAlignmentCenter;
    
//    NSMutableAttributedString * protocol=[[NSMutableAttributedString alloc] initWithString:@"忘记密码"];
//    [protocol addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(0, 4)];
    
    NSMutableAttributedString * forgetPwdAttributed = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(FORGETPWD, nil)];
    forgetPwdLabel.attributedText = forgetPwdAttributed;
    forgetPwdLabel.userInteractionEnabled=YES;
    [forgetPwdLabel sizeToFit];
    forgetPwdLabel.x = (ScreenWidth - forgetPwdLabel.width)*0.5;
    
    UIView * lineView = [[UIView alloc] init];
    [self addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(forgetPwdLabel.mas_bottom);
        make.height.equalTo(@1);
        make.centerX.equalTo(forgetPwdLabel.mas_centerX);
        make.width.equalTo(@(forgetPwdLabel.width));
    }];
    lineView.backgroundColor=[UIColor colorWithHexString:@"#FFFFFF" alpha:0.6];
    
    
    UITapGestureRecognizer * forgetTap=[[UITapGestureRecognizer alloc] init];
    [forgetTap addTarget:self action:@selector(forgetTap:)];
    [forgetPwdLabel addGestureRecognizer:forgetTap];
    
}

- (void)setSsid:(NSString *)ssid
{
    _ssid=ssid;
    self.subDescLabel.text=[NSString stringWithFormat:@"“%@”,%@",ssid,FGGetStringWithKeyFromTable(INPUTRIGHTPWD, nil)];
}
- (void)startBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(connectFailView:)]) {
        [self.delegate connectFailView:self];
    }
}

- (void)forgetTap:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(connectFailViewForgetPwd:)]) {
        [self.delegate connectFailViewForgetPwd:self];
    }
}

@end
