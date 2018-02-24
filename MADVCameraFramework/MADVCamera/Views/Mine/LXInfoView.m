//
//  LXInfoView.m
//  DasBank
//
//  Created by 张巧隔 on 16/3/31.
//  Copyright © 2016年 LXWT. All rights reserved.
//

#import "LXInfoView.h"
#import "Masonry.h"

@interface LXInfoView()
@property(nonatomic,weak)UILabel * leftTop;
@property(nonatomic,weak)UILabel * rightTop;
@property(nonatomic,weak)UILabel * midTop;
@end
@implementation LXInfoView
- (void)loadInfoView
{
    CGFloat width=([UIScreen mainScreen].bounds.size.width)/2;
    NSNumber * widthNum=[NSNumber numberWithFloat:width];
    
    UIView * leftView=[[UIView alloc] init];
    [self addSubview:leftView];
    [leftView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.width.equalTo(widthNum);
        make.bottom.equalTo(@0);
    }];
    
    UIView * leftLineView=[[UIView alloc] init];
    [leftView addSubview:leftLineView];
    [leftLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@10);
        make.right.equalTo(@0);
        make.width.equalTo(@0.5);
        make.bottom.equalTo(@-10);
    }];
    leftLineView.backgroundColor=[UIColor colorWithRed:0.91f green:0.91f blue:0.91f alpha:1.00f];
    
    UILabel * leftTop=[[UILabel alloc] init];
    [leftView addSubview:leftTop];
    [leftTop mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@10);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(leftView.mas_centerY);
    }];
    leftTop.font=[UIFont systemFontOfSize:15];
    leftTop.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.8];
    leftTop.textAlignment=NSTextAlignmentCenter;
    self.leftTop=leftTop;
    
    UILabel * leftBottom=[[UILabel alloc] init];
    [leftView addSubview:leftBottom];
    [leftBottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(leftView.mas_centerY);
        make.right.equalTo(@0);
        make.left.equalTo(@0);
        make.bottom.equalTo(@-10);
    }];
    leftBottom.font=[UIFont systemFontOfSize:12];
    leftBottom.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.5];
    leftBottom.textAlignment=NSTextAlignmentCenter;
    leftBottom.text=FGGetStringWithKeyFromTable(WORKS, nil);
    
    UITapGestureRecognizer * leftTap=[[UITapGestureRecognizer alloc] init];
    [leftTap addTarget:self action:@selector(leftTap:)];
    [leftView addGestureRecognizer:leftTap];
    
    /*
    UIView * rightView=[[UIView alloc] init];
    [self addSubview:rightView];
    [rightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.right.equalTo(@0);
        make.width.equalTo(widthNum);
        make.bottom.equalTo(@0);
    }];
    
   
    
    UILabel * rightTop=[[UILabel alloc] init];
    [rightView addSubview:rightTop];
    [rightTop mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@10);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(rightView.mas_centerY);
    }];
    rightTop.font=[UIFont systemFontOfSize:15];
    rightTop.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.8];
    rightTop.textAlignment=NSTextAlignmentCenter;
    self.rightTop=rightTop;
    
    UILabel * rightBottom=[[UILabel alloc] init];
    [rightView addSubview:rightBottom];
    [rightBottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(rightView.mas_centerY);
        make.right.equalTo(@0);
        make.left.equalTo(@0);
        make.bottom.equalTo(@-10);
    }];
    rightBottom.font=[UIFont systemFontOfSize:12];
    rightBottom.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.5];
    rightBottom.textAlignment=NSTextAlignmentCenter;
    rightBottom.text=FGGetStringWithKeyFromTable(FAVOR, nil);
    
    UITapGestureRecognizer * rightTap=[[UITapGestureRecognizer alloc] init];
    [rightTap addTarget:self action:@selector(rightTap:)];
    [rightView addGestureRecognizer:rightTap];*/
    
    
    
    UIView * midView=[[UIView alloc] init];
    [self addSubview:midView];
    [midView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(leftView.mas_right);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    
    UIView * midLineView=[[UIView alloc] init];
    [midView addSubview:midLineView];
    [midLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@10);
        make.right.equalTo(@0);
        make.width.equalTo(@0.5);
        make.bottom.equalTo(@-10);
    }];
    midLineView.backgroundColor=[UIColor colorWithRed:0.91f green:0.91f blue:0.91f alpha:1.00f];
    
    UILabel * midTop=[[UILabel alloc] init];
    [midView addSubview:midTop];
    [midTop mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@10);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(midView.mas_centerY);
    }];
    midTop.font=[UIFont systemFontOfSize:15];
    midTop.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.8];
    midTop.textAlignment=NSTextAlignmentCenter;
    self.midTop=midTop;
    
    UILabel * midBottom=[[UILabel alloc] init];
    [midView addSubview:midBottom];
    [midBottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(midView.mas_centerY);
        make.right.equalTo(@0);
        make.left.equalTo(@0);
        make.bottom.equalTo(@-10);
    }];
    midBottom.font=[UIFont systemFontOfSize:12];
    midBottom.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.5];
    midBottom.textAlignment=NSTextAlignmentCenter;
    midBottom.text=FGGetStringWithKeyFromTable(LIKE, nil);
    
    UITapGestureRecognizer * midTap=[[UITapGestureRecognizer alloc] init];
    [midTap addTarget:self action:@selector(midTap:)];
    [midView addGestureRecognizer:midTap];
}

- (void)leftTap:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(infoViewDidTouch:andIndex:)]) {
        [self.delegate infoViewDidTouch:self andIndex:0];
    }
}

- (void)midTap:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(infoViewDidTouch:andIndex:)]) {
        [self.delegate infoViewDidTouch:self andIndex:1];
    }
}
- (void)rightTap:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(infoViewDidTouch:andIndex:)]) {
        [self.delegate infoViewDidTouch:self andIndex:2];
    }
}

- (void)setInfoArr:(NSArray *)infoArr
{
    _infoArr=infoArr;
    self.leftTop.text=infoArr[0];
    self.midTop.text=infoArr[1];
    //self.rightTop.text=infoArr[2];
}

@end
