//
//  PersonalHomeCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/8/21.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "PersonalHomeCell.h"
#import "Masonry.h"
#import <SDWebImage/UIImageView+WebCache.h>


@interface PersonalHomeCell()
@property(nonatomic,weak)UIImageView * thumImageView;
@property(nonatomic,weak)UIImageView * favorImageView;
@property(nonatomic,weak)UILabel * favorLabel;
@property(nonatomic,weak)UIImageView * centerImage;
@end


@implementation PersonalHomeCell
- (id)initWithFrame:(CGRect)frame
{
    if (self=[super initWithFrame:frame]) {
        UIImageView * defaultImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:defaultImageView];
        [defaultImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@40);
            make.height.equalTo(@40);
        }];
        self.contentView.clipsToBounds=YES;
        defaultImageView.image=[UIImage imageNamed:@"default_picture.png"];
        
        UIImageView * thumImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:thumImageView];
        [thumImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.bottom.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
        }];
        thumImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.thumImageView = thumImageView;
        
        UIImageView * centerImage=[[UIImageView alloc] init];
        [self.contentView addSubview:centerImage];
        [centerImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(thumImageView.mas_centerX);
            make.centerY.equalTo(thumImageView.mas_centerY);
            make.width.equalTo(@40);
            make.height.equalTo(@40);
        }];
        centerImage.image=[UIImage imageNamed:@"play_discover.png"];
        self.centerImage=centerImage;
        
        UIView * bottomView = [[UIView alloc] init];
        [self.contentView addSubview:bottomView];
        [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@30);
            make.bottom.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
        }];
        bottomView.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.3];
       
        
        
        UIImageView * favorImageView = [[UIImageView alloc] init];
        [bottomView addSubview:favorImageView];
        [favorImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@12);
            make.left.equalTo(@10);
            make.centerY.equalTo(bottomView.mas_centerY);
            make.width.equalTo(@14);
        }];
        favorImageView.image = [UIImage imageNamed:@"personalHome_favor.png"];
        self.favorImageView = favorImageView;
        
        UILabel * favorLabel = [[UILabel alloc] init];
        [bottomView addSubview:favorLabel];
        [favorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@15);
            make.centerY.equalTo(bottomView.mas_centerY);
            make.left.equalTo(favorImageView.mas_right).offset(5);
            make.width.equalTo(@80);
        }];
        favorLabel.textColor = [UIColor colorWithHexString:@"#ffffff"];
        favorLabel.font = [UIFont systemFontOfSize:12];
        self.favorLabel = favorLabel;
        
        
        
        
        
        
    }
    return self;
}

- (void)setCloudMedia:(MVCloudMedia *)cloudMedia
{
    _cloudMedia = cloudMedia;
    [self.thumImageView sd_setImageWithURL:[NSURL URLWithString:cloudMedia.thumbnail]];
    if ([cloudMedia.favored isEqualToString:@"0"]) {
        self.favorImageView.image = [UIImage imageNamed:@"personalHome_favor.png"];
    }else
    {
        self.favorImageView.image = [UIImage imageNamed:@"love_discover-click.png"];
    }
    if ([cloudMedia.type isEqualToString:@"0"]) {
        self.centerImage.hidden = YES;
    }else
    {
        self.centerImage.hidden = NO;
    }
    self.favorLabel.text = cloudMedia.favor;
}

@end
