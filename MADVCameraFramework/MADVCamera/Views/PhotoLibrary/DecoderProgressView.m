//
//  DecoderProgressView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/8.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "DecoderProgressView.h"
#import "Masonry.h"

@interface DecoderProgressView()

@property(nonatomic,weak)UIImageView * selectImageView4;
@property(nonatomic,weak)UILabel * leftTagLabel4;
@property(nonatomic,weak)UIImageView * selectImageView1080;
@property(nonatomic,weak)UILabel * leftTagLabel1080;

@end
@implementation DecoderProgressView

- (void)loadDecoderProgressView
{
    UIView * decoderView=[[UIView alloc] init];
    [self addSubview:decoderView];
    [decoderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@10);
        make.right.equalTo(@-10);
        make.bottom.equalTo(@-10);
        make.height.equalTo(@150);
    }];
    decoderView.backgroundColor=[UIColor colorWithHexString:@"#F7F7F7"];
    decoderView.layer.masksToBounds=YES;
    decoderView.layer.cornerRadius=5;
    
    UIView * closeView = [[UIView alloc] init];
    [self addSubview:closeView];
    [closeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(decoderView.mas_top);
    }];
    closeView.backgroundColor=[UIColor clearColor];
    UITapGestureRecognizer * closeGes = [[UITapGestureRecognizer alloc] init];
    [closeGes addTarget:self action:@selector(closeGes:)];
    [closeView addGestureRecognizer:closeGes];
    
    UILabel * selectLabel=[[UILabel alloc] init];
    [decoderView addSubview:selectLabel];
    [selectLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@50);
    }];
    selectLabel.font=[UIFont systemFontOfSize:16];
    selectLabel.textAlignment=NSTextAlignmentCenter;
    selectLabel.textColor=[UIColor blackColor];
    selectLabel.text=FGGetStringWithKeyFromTable(SELECTUPLOADRATE, nil);
    
    UIView * fristLineView=[[UIView alloc] init];
    [decoderView addSubview:fristLineView];
    [fristLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.top.equalTo(selectLabel.mas_bottom);
        make.height.equalTo(@1);
    }];
    fristLineView.backgroundColor=[UIColor colorWithRed:0.96f green:0.95f blue:0.93f alpha:1.00f];
    
    UIView * qualityLevelView4 = [[UIView alloc] init];
    [decoderView addSubview:qualityLevelView4];
    [qualityLevelView4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.top.equalTo(fristLineView.mas_bottom);
        make.height.equalTo(@49);
    }];
    qualityLevelView4.tag=4;
    
    UITapGestureRecognizer * selectGes4 = [[UITapGestureRecognizer alloc] init];
    [selectGes4 addTarget:self action:@selector(selectGes:)];
    [qualityLevelView4 addGestureRecognizer:selectGes4];
    
    UIImageView * selectImageView4=[[UIImageView alloc] init];
    [qualityLevelView4 addSubview:selectImageView4];
    [selectImageView4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@15);
        make.centerY.equalTo(qualityLevelView4.mas_centerY);
        make.width.equalTo(@10);
        make.height.equalTo(@10);
    }];
    selectImageView4.image=[UIImage imageNamed:@"hint.png"];
    selectImageView4.hidden=YES;
    self.selectImageView4=selectImageView4;
    
    UILabel * leftTagLabel4=[[UILabel alloc] init];
    [qualityLevelView4 addSubview:leftTagLabel4];
    [leftTagLabel4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(selectImageView4.mas_right).offset(10);
        make.centerY.equalTo(qualityLevelView4.mas_centerY);
        make.height.equalTo(@20);
        make.width.equalTo(@50);
    }];
    leftTagLabel4.font=[UIFont systemFontOfSize:15];
    leftTagLabel4.textColor=[UIColor colorWithRed:0.22f green:0.18f blue:0.17f alpha:1.00f];
    leftTagLabel4.text=@"4K";
    self.leftTagLabel4=leftTagLabel4;
    
    UILabel * fileSizeLabel4=[[UILabel alloc] init];
    [qualityLevelView4 addSubview:fileSizeLabel4];
    [fileSizeLabel4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@-15);
        make.centerY.equalTo(qualityLevelView4.mas_centerY);
        make.height.equalTo(@20);
        make.width.equalTo(@200);
    }];
    fileSizeLabel4.textAlignment=NSTextAlignmentRight;
    fileSizeLabel4.font=[UIFont systemFontOfSize:15];
    fileSizeLabel4.textColor=[UIColor colorWithRed:0.22f green:0.18f blue:0.17f alpha:1.00f];
    self.fileSizeLabel4=fileSizeLabel4;
    
    UIView * secLineView=[[UIView alloc] init];
    [decoderView addSubview:secLineView];
    [secLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.top.equalTo(qualityLevelView4.mas_bottom);
        make.height.equalTo(@1);
    }];
    secLineView.backgroundColor=[UIColor colorWithRed:0.96f green:0.95f blue:0.93f alpha:1.00f];
    
    
    
    UIView * qualityLevelView1080 = [[UIView alloc] init];
    [decoderView addSubview:qualityLevelView1080];
    [qualityLevelView1080 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
        make.height.equalTo(@49);
    }];
    qualityLevelView1080.tag=1080;
    
    UITapGestureRecognizer * selectGes1080 = [[UITapGestureRecognizer alloc] init];
    [selectGes1080 addTarget:self action:@selector(selectGes:)];
    [qualityLevelView1080 addGestureRecognizer:selectGes1080];
    
    UIImageView * selectImageView1080=[[UIImageView alloc] init];
    [qualityLevelView1080 addSubview:selectImageView1080];
    [selectImageView1080 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@15);
        make.centerY.equalTo(qualityLevelView1080.mas_centerY);
        make.width.equalTo(@10);
        make.height.equalTo(@10);
    }];
    selectImageView1080.image=[UIImage imageNamed:@"hint.png"];
    self.selectImageView1080=selectImageView1080;
    
    UILabel * leftTagLabel1080=[[UILabel alloc] init];
    [qualityLevelView1080 addSubview:leftTagLabel1080];
    [leftTagLabel1080 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(selectImageView1080.mas_right).offset(10);
        make.centerY.equalTo(qualityLevelView1080.mas_centerY);
        make.height.equalTo(@20);
        make.width.equalTo(@50);
    }];
    leftTagLabel1080.font=[UIFont systemFontOfSize:15];
    leftTagLabel1080.textColor=[UIColor colorWithRed:0.12f green:0.59f blue:1.00f alpha:1.00f];
    leftTagLabel1080.text=@"1080";
    self.leftTagLabel1080=leftTagLabel1080;
    
    UILabel * fileSizeLabel1080=[[UILabel alloc] init];
    [qualityLevelView1080 addSubview:fileSizeLabel1080];
    [fileSizeLabel1080 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@-15);
        make.centerY.equalTo(qualityLevelView1080.mas_centerY);
        make.height.equalTo(@20);
        make.width.equalTo(@200);
    }];
    fileSizeLabel1080.textAlignment=NSTextAlignmentRight;
    fileSizeLabel1080.font=[UIFont systemFontOfSize:15];
    fileSizeLabel1080.textColor=[UIColor colorWithRed:0.12f green:0.59f blue:1.00f alpha:1.00f];
    self.fileSizeLabel1080=fileSizeLabel1080;
    
    
}

- (void)selectGes:(UITapGestureRecognizer *)tap
{
    UIView * view =tap.view;
    if ([self.delegate respondsToSelector:@selector(decoderProgressViewClick:selectTag:)]) {
        [self.delegate decoderProgressViewClick:self selectTag:view.tag];
    }
    if (view.tag == 4) {
        self.selectImageView4.hidden=NO;
        self.leftTagLabel4.textColor=[UIColor colorWithRed:0.12f green:0.59f blue:1.00f alpha:1.00f];
        self.fileSizeLabel4.textColor=[UIColor colorWithRed:0.12f green:0.59f blue:1.00f alpha:1.00f];
        self.selectImageView1080.hidden=YES;
        self.leftTagLabel1080.textColor=[UIColor colorWithRed:0.22f green:0.18f blue:0.17f alpha:1.00f];
        self.fileSizeLabel1080.textColor=[UIColor colorWithRed:0.22f green:0.18f blue:0.17f alpha:1.00f];
    }else if (view.tag==1080)
    {
        self.selectImageView1080.hidden=NO;
        self.leftTagLabel1080.textColor=[UIColor colorWithRed:0.12f green:0.59f blue:1.00f alpha:1.00f];
        self.fileSizeLabel1080.textColor=[UIColor colorWithRed:0.12f green:0.59f blue:1.00f alpha:1.00f];
        self.selectImageView4.hidden=YES;
        self.leftTagLabel4.textColor=[UIColor colorWithRed:0.22f green:0.18f blue:0.17f alpha:1.00f];
        self.fileSizeLabel4.textColor=[UIColor colorWithRed:0.22f green:0.18f blue:0.17f alpha:1.00f];
    }
}
- (void)closeGes:(UITapGestureRecognizer *)ges
{
    [UIView animateWithDuration:0.5 animations:^{
        self.y=ScreenHeight;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
