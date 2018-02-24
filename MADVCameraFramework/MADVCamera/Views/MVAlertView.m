//
//  MVAlertView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/18.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVAlertView.h"
#import "Masonry.h"

@implementation MVAlertView

-(void)loadWithTitle:(NSString *)title message:(NSString *)message delegate:(id<MVAlertViewDelegate>)delegate otherButtonTitles:(NSArray *)otherButtonTitles
{
    self.delegate=delegate;
    UIView * backView = [[UIView alloc] init];
    [self addSubview:backView];
    backView.backgroundColor=[UIColor whiteColor];
    backView.layer.masksToBounds=YES;
    backView.layer.cornerRadius=15;
    
    UILabel * titleLabel = [[UILabel alloc] init];
    [backView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@20);
        make.left.equalTo(@10);
        make.right.equalTo(@-10);
        make.height.equalTo(@20);
    }];
    titleLabel.font=[UIFont systemFontOfSize:16];
    titleLabel.textColor=[UIColor blackColor];
    titleLabel.textAlignment=NSTextAlignmentCenter;
    titleLabel.text=title;
    
    UILabel * messageLabel = [[UILabel alloc] init];
    [backView addSubview:messageLabel];
//    CGSize size=CGSizeMake(ScreenWidth-140,MAXFLOAT);
//    NSString * str=message;
//    size=[message boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes: @{NSFontAttributeName:[UIFont systemFontOfSize:15]} context:nil].size;
//    [messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(titleLabel.mas_bottom).offset(15);
//        make.left.equalTo(@20);
//        make.right.equalTo(@-20);
//        make.height.equalTo([NSNumber numberWithFloat:size.height]);
//    }];
    messageLabel.frame = CGRectMake(20, 55, self.width - 140, 20);
    messageLabel.font=[UIFont systemFontOfSize:15];
    messageLabel.textColor=[UIColor colorWithRed:0.46f green:0.46f blue:0.46f alpha:1.00f];
    messageLabel.textAlignment=NSTextAlignmentCenter;
    messageLabel.numberOfLines=0;
    NSMutableAttributedString * agreement=[[NSMutableAttributedString alloc] initWithString:message];
    if ([message hasSuffix:[NSString stringWithFormat:@"【%@】",FGGetStringWithKeyFromTable(DETAIL, nil)]]) {
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.71f green:0.74f blue:0.88f alpha:1.00f] range:NSMakeRange(message.length-FGGetStringWithKeyFromTable(DETAIL, nil).length-2, FGGetStringWithKeyFromTable(DETAIL, nil).length+2)];
    }
    NSString * lookSupportList = FGGetStringWithKeyFromTable(LOOK_SUPPORT_LIST, nil);
    if ([message hasSuffix:[NSString stringWithFormat:@"%@",lookSupportList]]) {
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.71f green:0.74f blue:0.88f alpha:1.00f] range:NSMakeRange(message.length-lookSupportList.length, lookSupportList.length)];
    }
    
    messageLabel.attributedText=agreement;
    [messageLabel sizeToFit];
    if (messageLabel.width < self.width - 140) {
        messageLabel.width = self.width - 140;
    }
    messageLabel.userInteractionEnabled=YES;
    
    UITapGestureRecognizer * tap =[[UITapGestureRecognizer alloc] init];
    [tap addTarget:self action:@selector(tap:)];
    [messageLabel addGestureRecognizer:tap];
    
    [backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.left.equalTo(@50);
        make.right.equalTo(@-50);
        make.height.equalTo(@(70+messageLabel.height+50));
    }];
    
    
    UIView * lineView=[[UIView alloc] init];
    [backView addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@-49);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@1);
    }];
    lineView.backgroundColor=[UIColor colorWithRed:0.95f green:0.96f blue:0.96f alpha:1.00f];
    if (otherButtonTitles.count > 1) {
        UIView * poLineView = [[UIView alloc] init];
        [backView addSubview:poLineView];
        [poLineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lineView.mas_bottom);
            make.centerX.equalTo(backView.mas_centerX);
            make.width.equalTo(@1);
            make.bottom.equalTo(@0);
        }];
        poLineView.backgroundColor=[UIColor colorWithRed:0.95f green:0.96f blue:0.96f alpha:1.00f];
        
        UIButton * cancelBtn = [[UIButton alloc] init];
        [backView addSubview:cancelBtn];
        [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@0);
            make.bottom.equalTo(@0);
            make.right.equalTo(poLineView.mas_left);
            make.top.equalTo(lineView.mas_bottom);
        }];
        [cancelBtn setTitle:otherButtonTitles[0] forState:UIControlStateNormal];
        cancelBtn.titleLabel.font=[UIFont systemFontOfSize:14];
        [cancelBtn setTitleColor:[UIColor colorWithRed:0.30f green:0.30f blue:0.30f alpha:1.00f] forState:UIControlStateNormal];
        cancelBtn.tag=5000;
        [cancelBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton * downloadBtn =[[UIButton alloc] init];
        [backView addSubview:downloadBtn];
        [downloadBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@0);
            make.top.equalTo(lineView.mas_top);
            make.bottom.equalTo(@0);
            make.left.equalTo(poLineView.mas_right);
        }];
        [downloadBtn setTitle:otherButtonTitles[1] forState:UIControlStateNormal];
        downloadBtn.titleLabel.font=[UIFont systemFontOfSize:15];
        [downloadBtn setTitleColor:[UIColor colorWithRed:0.30f green:0.30f blue:0.30f alpha:1.00f] forState:UIControlStateNormal];
        downloadBtn.tag=5001;
        [downloadBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    }else
    {
        UIButton * cancelBtn = [[UIButton alloc] init];
        [backView addSubview:cancelBtn];
        [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@0);
            make.bottom.equalTo(@0);
            make.right.equalTo(@0);
            make.top.equalTo(lineView.mas_bottom);
        }];
        [cancelBtn setTitle:otherButtonTitles[0] forState:UIControlStateNormal];
        cancelBtn.titleLabel.font=[UIFont systemFontOfSize:14];
        [cancelBtn setTitleColor:[UIColor colorWithRed:0.30f green:0.30f blue:0.30f alpha:1.00f] forState:UIControlStateNormal];
        cancelBtn.tag=5000;
        [cancelBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    
}

- (void)btnClick:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(mvAlertViewClick:index:)]) {
        [self.delegate mvAlertViewClick:self index:btn.tag];
    }
}
- (void)tap:(UITapGestureRecognizer *)ges
{
    if ([self.delegate respondsToSelector:@selector(mvAlertViewDetail:)]) {
        [self.delegate mvAlertViewDetail:self];
    }
}



@end
