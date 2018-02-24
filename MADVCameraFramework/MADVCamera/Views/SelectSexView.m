//
//  SelectSexView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/18.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "SelectSexView.h"
#import "Masonry.h"

@interface SelectSexView()
@property(nonatomic,weak)UIImageView * selectImage;
@property(nonatomic,weak)UILabel * maleLabel;
@property(nonatomic,weak)UIImageView * selectFemaleImage;
@property(nonatomic,weak)UILabel * femaleLabel;
@end

@implementation SelectSexView

- (void)loadSelectSexView
{
    UIView * topView=[[UIView alloc] init];
    [self addSubview:topView];
    [topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@(ScreenHeight-152));
    }];
    topView.backgroundColor=RGBCOLORA(0, 0, 0, 0.3);
    
    UITapGestureRecognizer * hideTap=[[UITapGestureRecognizer alloc] init];
    [hideTap addTarget:self action:@selector(hideTap:)];
    [topView addGestureRecognizer:hideTap];
    
    UIImageView * contentView=[[UIImageView alloc] init];
    [self addSubview:contentView];
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@152);
    }];
    contentView.backgroundColor=[UIColor whiteColor];
    contentView.userInteractionEnabled=YES;
    
    UILabel * titleLabel=[[UILabel alloc] init];
    [contentView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@50);
    }];
    titleLabel.textAlignment=NSTextAlignmentCenter;
    titleLabel.textColor=[UIColor colorWithHexString:@"#000000"];
    titleLabel.font=[UIFont systemFontOfSize:15];
    titleLabel.text=FGGetStringWithKeyFromTable(SEX, nil);
    
    UIView * topLineView=[[UIView alloc] init];
    [contentView addSubview:topLineView];
    [topLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@1);
    }];
    topLineView.backgroundColor=RGBCOLOR(241, 241, 241);
    
    UIImageView * midView=[[UIImageView alloc] init];
    [contentView addSubview:midView];
    [midView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topLineView.mas_bottom);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@50);
    }];
    midView.backgroundColor=[UIColor whiteColor];
    midView.userInteractionEnabled=YES;
    
    UITapGestureRecognizer * maleTap=[[UITapGestureRecognizer alloc] init];
    [maleTap addTarget:self action:@selector(maleTap:)];
    [midView addGestureRecognizer:maleTap];
    
    UIImageView * selectImage=[[UIImageView alloc] init];
    [midView addSubview:selectImage];
    [selectImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@15);
        make.centerY.equalTo(midView.mas_centerY);
        make.width.equalTo(@10);
        make.height.equalTo(@10);
    }];
    selectImage.image=[UIImage imageNamed:@"hint.png"];
    selectImage.hidden=YES;
    self.selectImage=selectImage;
    
    UILabel * maleLabel=[[UILabel alloc] init];
    [midView addSubview:maleLabel];
    [maleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(selectImage.mas_right).offset(7);
        make.centerY.equalTo(midView.mas_centerY);
        make.width.equalTo(@150);
        make.height.equalTo(@15);
    }];
    maleLabel.font=[UIFont systemFontOfSize:15];
    maleLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.6];
    maleLabel.text=FGGetStringWithKeyFromTable(MALE, nil);
    self.maleLabel=maleLabel;
    
    UIView * bottomLineView=[[UIView alloc] init];
    [contentView addSubview:bottomLineView];
    [bottomLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(midView.mas_bottom);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@1);
    }];
    bottomLineView.backgroundColor=RGBCOLOR(241, 241, 241);
    
    
    UIImageView * bottomView=[[UIImageView alloc] init];
    [contentView addSubview:bottomView];
    [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@50);
    }];
    bottomView.backgroundColor=[UIColor whiteColor];
    bottomView.userInteractionEnabled=YES;
    
    UITapGestureRecognizer * femaleTap=[[UITapGestureRecognizer alloc] init];
    [femaleTap addTarget:self action:@selector(femaleTap:)];
    [bottomView addGestureRecognizer:femaleTap];
    
    
    UIImageView * selectFemaleImage=[[UIImageView alloc] init];
    [bottomView addSubview:selectFemaleImage];
    [selectFemaleImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@15);
        make.centerY.equalTo(bottomView.mas_centerY);
        make.width.equalTo(@10);
        make.height.equalTo(@10);
    }];
    selectFemaleImage.image=[UIImage imageNamed:@"hint.png"];
    selectFemaleImage.hidden=YES;
    self.selectFemaleImage=selectFemaleImage;
    
    UILabel * femaleLabel=[[UILabel alloc] init];
    [bottomView addSubview:femaleLabel];
    [femaleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(selectFemaleImage.mas_right).offset(7);
        make.centerY.equalTo(bottomView.mas_centerY);
        make.width.equalTo(@150);
        make.height.equalTo(@15);
    }];
    femaleLabel.font=[UIFont systemFontOfSize:15];
    femaleLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.6];
    femaleLabel.text=FGGetStringWithKeyFromTable(FEMALE, nil);
    self.femaleLabel=femaleLabel;
}
- (void)maleTap:(UITapGestureRecognizer *)tap
{
    self.selectFemaleImage.hidden=YES;
    self.femaleLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.6];
    self.selectImage.hidden=NO;
    self.maleLabel.textColor=[UIColor colorWithHexString:@"#1F96FF"];
    if ([self.delegate respondsToSelector:@selector(selectSexView:sex:)]) {
        [self.delegate selectSexView:self sex:@"1"];
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.y=ScreenHeight;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)femaleTap:(UITapGestureRecognizer *)tap
{
    self.selectImage.hidden=YES;
    self.maleLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.6];
    self.selectFemaleImage.hidden=NO;
    self.femaleLabel.textColor=[UIColor colorWithHexString:@"#1F96FF"];
    if ([self.delegate respondsToSelector:@selector(selectSexView:sex:)]) {
        [self.delegate selectSexView:self sex:@"2"];
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.y=ScreenHeight;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
- (void)selectSex:(NSString *)sex
{
    if ([sex isEqualToString:@"1"]) {
        self.selectImage.hidden=NO;
        self.maleLabel.textColor=[UIColor colorWithHexString:@"#1F96FF"];
    }else
    {
        self.selectFemaleImage.hidden=NO;
        self.femaleLabel.textColor=[UIColor colorWithHexString:@"#1F96FF"];
    }
}

- (void)hideTap:(UITapGestureRecognizer *)tap
{
    [UIView animateWithDuration:0.2 animations:^{
        self.y=ScreenHeight;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
