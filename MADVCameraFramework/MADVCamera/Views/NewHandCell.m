//
//  NewHandCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/3/21.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "NewHandCell.h"
#import "Masonry.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface NewHandCell()
@property(nonatomic,weak)UIImageView * thumImageView;
@property(nonatomic,weak)UIImageView * typeImageView;
@property(nonatomic,weak)UILabel * titleLabel;
@property(nonatomic,weak)UILabel * desLabel;
@end

@implementation NewHandCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UIImageView * defaultImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:defaultImageView];
        
        defaultImageView.image=[UIImage imageNamed:@"default_picture.png"];
        
        UIImageView * thumImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:thumImageView];
        [thumImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.height.equalTo(@200);
        }];
        thumImageView.backgroundColor=[UIColor clearColor];
        self.thumImageView=thumImageView;
        
        [defaultImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.centerY.equalTo(thumImageView.mas_centerY);
            make.width.equalTo(@100);
            make.height.equalTo(@100);
        }];
        
//        UIImageView * maskImageView=[[UIImageView alloc] init];
//        [self.contentView addSubview:maskImageView];
//        [maskImageView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(@0);
//            make.left.equalTo(@0);
//            make.right.equalTo(@0);
//            make.height.equalTo(@200);
//        }];
//        maskImageView.image=[UIImage imageNamed:@"Mask"];
        
        UIImageView * typeImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:typeImageView];
        [typeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.centerY.equalTo(thumImageView.mas_centerY);
            make.height.equalTo(@50);
            make.width.equalTo(@50);
        }];
        typeImageView.image = [UIImage imageNamed:@"new_play.png"];
        typeImageView.hidden = YES;
        self.typeImageView = typeImageView;
        
        UIView * bottomView = [[UIView alloc] init];
        [self.contentView addSubview:bottomView];
        [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(thumImageView.mas_bottom);
            make.bottom.equalTo(@-10);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
        }];
        bottomView.backgroundColor = [UIColor whiteColor];
        
        UILabel * titleLabel = [[UILabel alloc] init];
        [bottomView addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@15);
            make.left.equalTo(@15);
            make.right.equalTo(@-15);
            make.height.equalTo(@20);
        }];
        titleLabel.font = [UIFont systemFontOfSize:16];
        titleLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        self.titleLabel = titleLabel;
        
        UILabel * desLabel = [[UILabel alloc] init];
        [bottomView addSubview:desLabel];
        desLabel.frame = CGRectMake(15, 45, ScreenWidth-30, 20);
        desLabel.font = [UIFont systemFontOfSize:12];
        desLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
        desLabel.numberOfLines = 2;
        self.desLabel = desLabel;
        
        
        UIView * lineView=[[UIView alloc] init];
        [self.contentView addSubview:lineView];
        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.height.equalTo(@10);
        }];
        lineView.backgroundColor=[UIColor colorWithRed:0.93f green:0.93f blue:0.93f alpha:1.00f];
        
    }
    return self;
}
- (void)setHand:(NewHand *)hand
{
    _hand = hand;
    if ([hand.thumbnail_ios hasPrefix:@"http"]) {
        [self.thumImageView sd_setImageWithURL:[NSURL URLWithString:hand.thumbnail_ios]];
    }else
    {
        self.thumImageView.image = [UIImage imageNamed:hand.thumbnail_ios];
    }
    
    self.titleLabel.text = hand.title;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:hand.des];
    self.desLabel.attributedText = attributedString;
    [self.desLabel sizeToFit];
    hand.desHeight = self.desLabel.height;
    if ([hand.type isEqualToString:@"1"]) {
        self.typeImageView.hidden = YES;
    }else
    {
        self.typeImageView.hidden = NO;
    }
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
