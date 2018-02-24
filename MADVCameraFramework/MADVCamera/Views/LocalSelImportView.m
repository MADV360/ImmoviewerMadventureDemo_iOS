//
//  LocalSelImportView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/28.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "LocalSelImportView.h"
#import "Masonry.h"

@implementation LocalSelImportView
- (void)loadLocalSelImportView
{
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] init];
    [tap addTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tap];
    
    UIView * baseView = [[UIView alloc] init];
    [self addSubview:baseView];
    [baseView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@(44*(self.titleArr.count+1) + (self.titleArr.count-1)*1 + 20));
    }];
    baseView.backgroundColor = [UIColor whiteColor];
    UIButton * cancelBtn = [[UIButton alloc] init];
    [baseView addSubview:cancelBtn];
    [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@35);
        make.right.equalTo(@-15);
        make.width.equalTo(@15);
        make.height.equalTo(@15);
    }];
    [cancelBtn setBackgroundImage:[UIImage imageNamed:@"black_cancel.png"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    for (int i=(int)self.titleArr.count-1; i>=0; i--) {
        if (i == (int)self.titleArr.count-1) {
            UIView * backGroView = [[UIView alloc] init];
            [baseView addSubview:backGroView];
            [backGroView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(@0);
                make.left.equalTo(@0);
                make.right.equalTo(@0);
                make.height.equalTo(@44);
            }];
            backGroView.backgroundColor = [UIColor clearColor];
            backGroView.tag = i;
            
            UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] init];
            [tapGes addTarget:self action:@selector(tapGes:)];
            [backGroView addGestureRecognizer:tapGes];
            
            UILabel * titleLabel = [[UILabel alloc] init];
            [backGroView addSubview:titleLabel];
            [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(@15);
                make.top.equalTo(@0);
                make.bottom.equalTo(@0);
                make.right.equalTo(@0);
            }];
            titleLabel.font = [UIFont systemFontOfSize:15];
            titleLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.7];
            titleLabel.text = self.titleArr[i];
        }else
        {
            UIView * lineView = [[UIView alloc] init];
            [baseView addSubview:lineView];
            [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(@(-44));
                make.left.equalTo(@0);
                make.right.equalTo(@0);
                make.height.equalTo(@1);
            }];
            lineView.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.15];
            
            UIView * backGroView = [[UIView alloc] init];
            [baseView addSubview:backGroView];
            [backGroView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(lineView.mas_top);
                make.left.equalTo(@0);
                make.right.equalTo(@0);
                make.height.equalTo(@44);
            }];
            backGroView.backgroundColor = [UIColor clearColor];
            backGroView.tag = i;
            
            UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] init];
            [tapGes addTarget:self action:@selector(tapGes:)];
            [backGroView addGestureRecognizer:tapGes];
            
            UILabel * titleLabel = [[UILabel alloc] init];
            [backGroView addSubview:titleLabel];
            [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(@15);
                make.top.equalTo(@0);
                make.bottom.equalTo(@0);
                make.right.equalTo(@0);
            }];
            titleLabel.font = [UIFont systemFontOfSize:15];
            titleLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.7];
            titleLabel.text = self.titleArr[i];
            
        }
    }
}
- (void)cancelBtn:(UIButton *)btn
{
    [self disMiss];
}
- (void)tap:(UITapGestureRecognizer *)tap
{
    [self disMiss];
}
- (void)tapGes:(UITapGestureRecognizer *)tap
{
    [self disMiss];
    if ([self.delegate respondsToSelector:@selector(localSelImportViewDidClick:index:)]) {
        [self.delegate localSelImportViewDidClick:self index:tap.view.tag];
    }
}
- (void)show
{
    self.frame = CGRectMake(0, -ScreenHeight, ScreenWidth, ScreenHeight);
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [UIView animateWithDuration:0.3 animations:^{
        self.y=0;
    }];
    
}

- (void)disMiss
{
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [self removeFromSuperview];
}

@end
