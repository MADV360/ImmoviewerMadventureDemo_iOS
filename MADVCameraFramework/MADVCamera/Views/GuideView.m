//
//  GuideView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/28.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "GuideView.h"
#import "Masonry.h"
#import "GuideScrollView.h"
@implementation GuideView
- (void)loadGuideView
{
    UIImageView * backImageView = [[UIImageView alloc] init];
    [self addSubview:backImageView];
    [backImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    backImageView.image = [UIImage imageNamed:@"openBackground.png"];
    backImageView.userInteractionEnabled = YES;
    
    UILabel * titleLabel = [[UILabel alloc] init];
    [backImageView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@130);
        make.centerX.equalTo(backImageView.mas_centerX);
        make.height.equalTo(@30);
        make.width.equalTo(@200);
    }];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:24];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = FGGetStringWithKeyFromTable(MICAMERA, nil);
    
    helper * helperInstance = [helper sharedInstance];
    CGFloat statusHeight = helperInstance.statusHeight;
    CGFloat bottomSafeArea = 0;
    CGFloat topSafeArea = 0;
    if (statusHeight > 20) {
        bottomSafeArea = 34;
        topSafeArea = 44;
    }
    UIButton * goBtn = [[UIButton alloc] init];
    [backImageView addSubview:goBtn];
    [goBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@(-50 - bottomSafeArea));
        make.left.equalTo(@30);
        make.right.equalTo(@-30);
        make.height.equalTo(@40);
    }];
    goBtn.layer.masksToBounds = YES;
    goBtn.layer.cornerRadius = 5;
    goBtn.layer.borderColor = [UIColor colorWithRed:0.82f green:0.82f blue:0.78f alpha:1.00f].CGColor;
    goBtn.layer.borderWidth = 1;
    [goBtn setTitle:@"GO" forState:UIControlStateNormal];
    [goBtn addTarget:self action:@selector(goBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    GuideScrollView * scrollView = [[GuideScrollView alloc] init];
    [backImageView addSubview:scrollView];
    scrollView.frame = CGRectMake(0, 0, ScreenWidth, self.height - 90 - bottomSafeArea);
    [scrollView loadGuideScrollView];
    scrollView.dataArr = @[@[FGGetStringWithKeyFromTable(ADVENTURE, nil)],@[FGGetStringWithKeyFromTable(NEWMEMORY, nil)],@[FGGetStringWithKeyFromTable(MICAMERA, nil),FGGetStringWithKeyFromTable(FINDNEW, nil)]];
    
}
- (void)goBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(guideViewGoto:)]) {
        [self.delegate guideViewGoto:self];
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
