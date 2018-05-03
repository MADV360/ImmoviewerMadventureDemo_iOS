//
//  SelectNetView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/22.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "SelectNetView.h"
#import "Masonry.h"

@implementation SelectNetView
- (void)loadSelectNetView
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
        make.width.equalTo(@300);
        make.height.equalTo(@144);
    }];
    imageView.image=[UIImage imageNamed:@"mxjx_rectangular.png"];
    
    UILabel * subDescLabel=[[UILabel alloc] init];
    [self addSubview:subDescLabel];
    subDescLabel.frame = CGRectMake(20, ScreenHeight * 0.5 - 72 - 20 -13, ScreenWidth-40, 13);
    subDescLabel.font=[UIFont systemFontOfSize:13];
    subDescLabel.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    subDescLabel.textAlignment=NSTextAlignmentCenter;
    subDescLabel.numberOfLines = 0;
    NSMutableAttributedString * subDescAttributed = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(PWDDEFAULT, nil)];
    subDescLabel.attributedText = subDescAttributed;
    [subDescLabel sizeToFit];
    subDescLabel.y = ScreenHeight * 0.5 - 72 - 20 - subDescLabel.height;
    subDescLabel.x = (ScreenWidth - subDescLabel.width)*0.5;
    
    UILabel * descLabel=[[UILabel alloc] init];
    [self addSubview:descLabel];
    descLabel.frame = CGRectMake(20, CGRectGetMaxY(subDescLabel.frame)-subDescLabel.height-5 -13, ScreenWidth-40, 13);
//    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(subDescLabel.mas_top).offset(-5);
//        make.centerX.equalTo(imageView.mas_centerX);
//        make.width.equalTo(@(ScreenWidth-40));
//        make.height.equalTo(@13);
//    }];
    descLabel.font=[UIFont systemFontOfSize:13];
    descLabel.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    descLabel.textAlignment=NSTextAlignmentCenter;
    descLabel.numberOfLines = 0;
    NSMutableAttributedString * descAttributed = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(SELECTSV1NET, nil)];
    descLabel.attributedText = descAttributed;
    [descLabel sizeToFit];
    descLabel.y = CGRectGetMaxY(subDescLabel.frame)-subDescLabel.height-5 -descLabel.height;
    descLabel.x = (ScreenWidth - descLabel.width)*0.5;
    
    UILabel * titleLabe=[[UILabel alloc] init];
    [self addSubview:titleLabe];
    [titleLabe mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(descLabel.mas_top).offset(-10);
        make.centerX.equalTo(self.mas_centerX);
        make.width.equalTo(@200);
        make.height.equalTo(@20);
    }];
    titleLabe.textAlignment=NSTextAlignmentCenter;
    titleLabe.font=[UIFont systemFontOfSize:20];
    titleLabe.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    titleLabe.text=FGGetStringWithKeyFromTable(SELECTNET, nil);
    
    helper * helperInstance = [helper sharedInstance];
    CGFloat statusHeight = helperInstance.statusHeight;
    CGFloat bottomSafearea = 20;
    if (statusHeight > 20) {
        bottomSafearea = 34;
    }
    UIButton * selectBtn=[[UIButton alloc] init];
    [self addSubview:selectBtn];
    [selectBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@(-bottomSafearea));
        make.left.equalTo(@15);
        make.right.equalTo(@-15);
        make.height.equalTo(@44);
    }];
    selectBtn.backgroundColor=[UIColor clearColor];
    selectBtn.layer.borderColor=[UIColor colorWithRed:0.50f green:0.50f blue:0.51f alpha:1.00f].CGColor;
    selectBtn.layer.borderWidth=1;
    selectBtn.layer.masksToBounds=YES;
    selectBtn.layer.cornerRadius=15;
    [selectBtn addTarget:self action:@selector(selectBtn:) forControlEvents:UIControlEventTouchUpInside];
    [selectBtn setTitle:FGGetStringWithKeyFromTable(CONNECTNET, nil) forState:UIControlStateNormal];
    selectBtn.titleLabel.font=[UIFont systemFontOfSize:15];
    [selectBtn setTitleColor:[UIColor colorWithHexString:@"#FFFFFF" alpha:0.9] forState:UIControlStateNormal];
    
}

- (void)selectBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(selectNetViewSelected:)]) {
        [self.delegate selectNetViewSelected:self];
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
