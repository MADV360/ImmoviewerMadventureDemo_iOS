//
//  FilterCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/29.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "FilterCell.h"
#import "Masonry.h"

@interface FilterCell()
@property(nonatomic,weak)UIImageView * filterImageView;
@property(nonatomic,weak)UILabel * nameLabel;
@property(nonatomic,weak)UIView * maskView;
@property(nonatomic,weak)UIImageView * selectImageView;
@end

@implementation FilterCell
- (id)initWithFrame:(CGRect)frame
{
    if (self=[super initWithFrame:frame]) {
        UIImageView * filterImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:filterImageView];
        [filterImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.bottom.equalTo(@0);
        }];
        self.filterImageView=filterImageView;
        
        
        UILabel * nameLabel=[[UILabel alloc] init];
        [self.contentView addSubview:nameLabel];
        [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.height.equalTo(@20);
        }];
        nameLabel.textAlignment=NSTextAlignmentCenter;
        nameLabel.font=[UIFont systemFontOfSize:12];
        nameLabel.textColor=[UIColor colorWithHexString:@"#FFFFFF"];
        nameLabel.backgroundColor=[UIColor colorWithHexString:@"#000000" alpha:0.5];
        self.nameLabel=nameLabel;
        
        UIView * maskView=[[UIView alloc] init];
        [self.contentView addSubview:maskView];
        [maskView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.bottom.equalTo(@0);
        }];
        maskView.backgroundColor=[UIColor colorWithHexString:@"#00a8ff" alpha:0.6];
        maskView.hidden=YES;
        self.maskView=maskView;
        
        UIImageView * selectImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:selectImageView];
        [selectImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.centerY.equalTo(self.contentView.mas_centerY).offset(-10);
            make.width.equalTo(@23);
            make.height.equalTo(@23);
        }];
        selectImageView.image=[UIImage imageNamed:@"choose.png"];
        selectImageView.hidden=YES;
        self.selectImageView=selectImageView;
        
        
    }
    return self;
}

- (void)setIsSelect:(BOOL)isSelect
{
    _isSelect=isSelect;
    if (isSelect) {
        self.maskView.hidden=NO;
        self.selectImageView.hidden=NO;
    }else
    {
        self.maskView.hidden=YES;
        self.selectImageView.hidden=YES;
    }
}

- (void)setImageFilter:(ImageFilterBean *)imageFilter
{
    _imageFilter=imageFilter;
    self.filterImageView.image=[UIImage imageNamed:imageFilter.iconPNGPath];
    
    self.nameLabel.text = FGGetStringWithKeyFromTable(imageFilter.name, nil);
    
}
@end
