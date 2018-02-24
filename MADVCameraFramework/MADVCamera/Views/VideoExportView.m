//
//  VideoExportView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/20.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "VideoExportView.h"
#import "KDGoalBar.h"
#import "UIColor+MVExtensions.h"

@interface VideoExportView()
@property(nonatomic,weak)UILabel * decLabel;
@property(nonatomic,weak)UIButton * bottomBtn;
@property(nonatomic,weak)UIImageView * resultImageView;
@property(nonatomic,weak)KDGoalBar * progressView;
@property(nonatomic,assign)BOOL isGetResult;//转码有结果
@property(nonatomic,weak)UIView * editBottomView;
@property(nonatomic,weak)UILabel * shareLabel;
@end

@implementation VideoExportView

- (void)loadVideoExportView
{
    self.backgroundColor = [UIColor colorWithRed:0.96f green:0.96f blue:0.97f alpha:1.00f];
    
    KDGoalBar * progressView = [[KDGoalBar alloc] initWithFrame:CGRectMake((ScreenWidth-187)*0.5, (ScreenHeight-187)*0.5-64, 187, 187)];
    progressView.textFont = [UIFont systemFontOfSize:25];
    progressView.textColor = [UIColor colorWithRed:0.33f green:0.64f blue:0.62f alpha:1.00f];
    progressView.isRateShow=YES;
    progressView.rightColor=[UIColor colorWithHexString:@"#46a4ea"];
    progressView.leftColor=[UIColor colorWithHexString:@"#000000" alpha:0.2];
    progressView.textColor = [UIColor colorWithHexString:@"#46a4ea"];
    [progressView setup];
    [self addSubview:progressView];
    self.progressView = progressView;
    
    UIImageView * resultImageView = [[UIImageView alloc] init];
    resultImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:resultImageView];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:resultImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:resultImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.f constant:-32.f]];
    [resultImageView addConstraint:[NSLayoutConstraint constraintWithItem:resultImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:35.f]];
    [resultImageView addConstraint:[NSLayoutConstraint constraintWithItem:resultImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:30.f]];
    resultImageView.hidden = YES;
    self.resultImageView = resultImageView;
    
    
    UILabel * decLabel = [[UILabel alloc] init];
    [self addSubview:decLabel];
    decLabel.frame = CGRectMake(25, CGRectGetMaxY(progressView.frame) + 30, ScreenWidth - 50, 15);
//    [decLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(progressView.mas_bottom).offset(30);
//        make.centerX.equalTo(self.mas_centerX);
//        make.height.equalTo(@15);
//        make.width.equalTo(@300);
//    }];
    decLabel.textAlignment = NSTextAlignmentCenter;
    decLabel.font = [UIFont systemFontOfSize:13];
    decLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
    if (self.isEdit) {
        
        decLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(EDITING, nil)];
    }else if (self.isSystemShare)
    {
        decLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(TRANSCODINGNOQUIT, nil)];
    }else
    {
        decLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(EXPORTPRE, nil)];
    }
    [decLabel sizeToFit];
    if (decLabel.frame.size.width < ScreenWidth - 50) {
        CGRect prevFrame = decLabel.frame;
        [decLabel setFrame:CGRectMake(prevFrame.origin.x, prevFrame.origin.y, ScreenWidth - 50, prevFrame.size.height)];
    }
    
    self.decLabel = decLabel;
    UIButton * bottomBtn = [[UIButton alloc] init];
    bottomBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:bottomBtn];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:bottomBtn attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:40.f]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:bottomBtn attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.f constant:25.f]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:bottomBtn attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.f constant:-25.f]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:bottomBtn attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.f constant:-30.f]];
    bottomBtn.layer.masksToBounds = YES;
    bottomBtn.layer.borderColor = [UIColor colorWithHexString:@"#000000" alpha:0.2].CGColor;
    bottomBtn.layer.borderWidth = 1;
    bottomBtn.layer.cornerRadius = 20;
    bottomBtn.backgroundColor = [UIColor whiteColor];
    bottomBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [bottomBtn setTitleColor:[UIColor colorWithHexString:@"#000000" alpha:0.8] forState:UIControlStateNormal];
    [bottomBtn addTarget:self action:@selector(bottomBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [bottomBtn setTitle:FGGetStringWithKeyFromTable(CANCELNOSPACE, nil) forState:UIControlStateNormal];
    self.bottomBtn = bottomBtn;
    if (self.isEdit || self.isSystemShare) {
        if (self.isEdit) {
            bottomBtn.hidden = YES;
        }
        UIView * editBottomView = [[UIView alloc] init];
        [self addSubview:editBottomView];
        editBottomView.frame = CGRectMake(25, ScreenHeight-64-70, ScreenWidth-50, 40);
        
        editBottomView.layer.masksToBounds = YES;
        editBottomView.layer.borderColor = [UIColor colorWithHexString:@"#000000" alpha:0.2].CGColor;
        editBottomView.layer.borderWidth = 1;
        editBottomView.layer.cornerRadius = 20;
        editBottomView.backgroundColor = [UIColor whiteColor];
        editBottomView.hidden = YES;
        self.editBottomView = editBottomView;
        
        UIView * lineView = [[UIView alloc] init];
        lineView.translatesAutoresizingMaskIntoConstraints = NO;
        [editBottomView addSubview:lineView];
        [lineView addConstraint:[NSLayoutConstraint constraintWithItem:lineView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:1.f]];
        [editBottomView addConstraint:[NSLayoutConstraint constraintWithItem:lineView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:editBottomView attribute:NSLayoutAttributeTop multiplier:1.f constant:0.f]];
        [editBottomView addConstraint:[NSLayoutConstraint constraintWithItem:lineView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:editBottomView attribute:NSLayoutAttributeBottom multiplier:1.f constant:0.f]];
        [editBottomView addConstraint:[NSLayoutConstraint constraintWithItem:lineView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:editBottomView attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
        lineView.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.2];
        
        
        UILabel * finishLabel = [[UILabel alloc] init];
        [editBottomView addSubview:finishLabel];
        finishLabel.frame = CGRectMake(0, 0, (ScreenWidth - 50 -1)*0.5, 40);
        
        finishLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        finishLabel.textAlignment = NSTextAlignmentCenter;
        finishLabel.font = [UIFont systemFontOfSize:16];
        finishLabel.text = FGGetStringWithKeyFromTable(FINISH, nil);
        finishLabel.userInteractionEnabled = YES;
      
        
        UITapGestureRecognizer * finishTap = [[UITapGestureRecognizer alloc] init];
        [finishTap addTarget:self action:@selector(finishTap:)];
        [finishLabel addGestureRecognizer:finishTap];
        
        
        UILabel * shareLabel = [[UILabel alloc] init];
        [editBottomView addSubview:shareLabel];
        shareLabel.frame = CGRectMake((ScreenWidth - 50 -1)*0.5 + 1, 0, (ScreenWidth - 50 -1)*0.5, 40);
//        [finishLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.right.equalTo(@0);
//            make.top.equalTo(@0);
//            make.bottom.equalTo(@0);
//            make.left.equalTo(lineView.mas_right);
//        }];
        shareLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        shareLabel.textAlignment = NSTextAlignmentCenter;
        shareLabel.font = [UIFont systemFontOfSize:16];
        shareLabel.text = FGGetStringWithKeyFromTable(FINISHANDSHARE, nil);
        shareLabel.userInteractionEnabled = YES;
        self.shareLabel = shareLabel;
        
        UITapGestureRecognizer * shareTap = [[UITapGestureRecognizer alloc] init];
        [shareTap addTarget:self action:@selector(shareTap:)];
        [shareLabel addGestureRecognizer:shareTap];
        
        
        
    }
    
    if (self.isBatchExport) {
        UILabel * sumLabel = [[UILabel alloc] init];
        [self addSubview:sumLabel];
        sumLabel.frame = CGRectMake(25, CGRectGetMaxY(decLabel.frame) + 20, ScreenWidth - 50, 25);
        sumLabel.textColor = [UIColor colorWithHexString:@"#333333"];
        sumLabel.font = [UIFont systemFontOfSize:18];
        sumLabel.textAlignment = NSTextAlignmentCenter;
        sumLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:FGGetStringWithKeyFromTable(BATCHEXPORT, nil),self.totalNum,self.finishNum]];
        [sumLabel sizeToFit];
        if (sumLabel.frame.size.width < ScreenWidth - 50) {
            CGRect prevFrame = sumLabel.frame;
            [sumLabel setFrame:CGRectMake(prevFrame.origin.x, prevFrame.origin.y, ScreenWidth - 50, prevFrame.size.height)];
        }
        self.sumLabel = sumLabel;
    }
    
}
#pragma mark --完成--
- (void)finishTap:(UITapGestureRecognizer *)tap
{
    NSLog(@"完成");
    if ([self.delegate respondsToSelector:@selector(videoExportView:clickType:)]) {
        [self.delegate videoExportView:self clickType:EditFinish];
    }
}
- (void)shareTap:(UITapGestureRecognizer *)tap
{
    NSLog(@"分享并完成");
    if ([self.delegate respondsToSelector:@selector(videoExportView:clickType:)]) {
        [self.delegate videoExportView:self clickType:EditShare];
    }
}
- (void)setIsSuc:(BOOL)isSuc
{
    _isSuc = isSuc;
    self.isGetResult = YES;
    self.sumLabel.hidden = YES;
    if (isSuc) {
        if (self.isEdit) {
            self.bottomBtn.hidden = YES;
            self.editBottomView.hidden = NO;
            self.decLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(EDITSUC, nil)];
        }else if (self.isSystemShare)
        {
            self.shareLabel.text = FGGetStringWithKeyFromTable(SHARE, nil);
            self.bottomBtn.hidden = YES;
            self.editBottomView.hidden = NO;
            self.decLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(TRANSCODINGSUC, nil)];
        }else
        {
            [self.bottomBtn setTitle:FGGetStringWithKeyFromTable(FINISH, nil) forState:UIControlStateNormal];
            self.decLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(EXPORTSUC, nil)];
        }
        
        self.progressView.isRateShow = NO;
        self.resultImageView.hidden = NO;
        self.resultImageView.image = [UIImage imageNamed:@"success.png"];
        
    }else
    {
        self.bottomBtn.hidden = NO;
        [self.bottomBtn setTitle:FGGetStringWithKeyFromTable(RETRY, nil) forState:UIControlStateNormal];
        if (self.isEdit) {
            self.decLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(EDITFAIL, nil)];
        }else
        {
            self.decLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(EXPORTFAIL, nil)];
        }
        self.progressView.isRateShow = NO;
        [self.progressView setPercent:100 animated:NO];
        self.resultImageView.hidden = NO;
        self.resultImageView.image = [UIImage imageNamed:@"failed.png"];
    }
    [self.decLabel sizeToFit];
    if (self.decLabel.frame.size.width < ScreenWidth - 50) {
        CGRect prevFrame = self.decLabel.frame;
        [self.decLabel setFrame:CGRectMake(prevFrame.origin.x, prevFrame.origin.y, ScreenWidth - 50, prevFrame.size.height)];
    }
}

- (void)bottomBtnClick:(UIButton *)btn
{
    ClickType clikType;
    if (self.isGetResult) {
        if (self.isSuc) {
            clikType = Finish;
        }else
        {
            self.isGetResult = NO;
            clikType = Retry;
            [self.bottomBtn setTitle:FGGetStringWithKeyFromTable(CANCELNOSPACE, nil) forState:UIControlStateNormal];
            self.decLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(EXPORTPRE, nil)];
            self.progressView.isRateShow = YES;
            [self.progressView setPercent:0 animated:NO];
            self.resultImageView.hidden = YES;
            [self.decLabel sizeToFit];
            if (self.decLabel.frame.size.width < ScreenWidth - 50) {
                CGRect prevFrame = self.decLabel.frame;
                [self.decLabel setFrame:CGRectMake(prevFrame.origin.x, prevFrame.origin.y, ScreenWidth - 50, prevFrame.size.height)];
            }
        }
    }else
    {
        clikType = Cancel;
    }
    if ([self.delegate respondsToSelector:@selector(videoExportView:clickType:)]) {
        [self.delegate videoExportView:self clickType:clikType];
    }
}

- (void)setPercent:(int)percent animated:(BOOL)animated
{
    [self.progressView setPercent:percent animated:animated];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
