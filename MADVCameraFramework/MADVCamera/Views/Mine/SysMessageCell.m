//
//  SysMessageCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/25.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "SysMessageCell.h"
#import "Masonry.h"

@interface SysMessageCell()
@property(nonatomic,weak)UIImageView * tagImageView;
@property(nonatomic,weak)UILabel * titleLabel;
@property(nonatomic,weak)UILabel * descLabel;
@property(nonatomic,weak)UIImageView * updateImageView;
@property(nonatomic,weak)UILabel * creatTimeLabel;
@end
@implementation SysMessageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UIImageView * tagImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:tagImageView];
        [tagImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@15);
            make.top.equalTo(@20);
            make.width.equalTo(@19);
            make.height.equalTo(@19);
        }];
        self.tagImageView = tagImageView;
        
        UILabel * titleLabel = [[UILabel alloc] init];
        [self.contentView addSubview:titleLabel];
        titleLabel.frame =CGRectMake(49, 20, ScreenWidth - 49 - 17 - 80, 19);
        titleLabel.font = [UIFont systemFontOfSize:16];
        titleLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        titleLabel.numberOfLines = 0;
        self.titleLabel = titleLabel;
        
        UILabel * creatTimeLabel = [[UILabel alloc] init];
        [self.contentView addSubview:creatTimeLabel];
        [creatTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@17);
            make.centerY.equalTo(titleLabel.mas_centerY);
            make.height.equalTo(@19);
            make.width.equalTo(@150);
        }];
        creatTimeLabel.font = [UIFont systemFontOfSize:12];
        creatTimeLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
        creatTimeLabel.textAlignment = NSTextAlignmentRight;
        self.creatTimeLabel = creatTimeLabel;
        
        UIImageView * updateImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:updateImageView];
        [updateImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(titleLabel.mas_right).offset(5);
            make.centerY.equalTo(titleLabel.mas_centerY);
            make.width.equalTo(@9);
            make.height.equalTo(@9);
        }];
        updateImageView.image = [UIImage imageNamed:@"sys_circle.png"];
        self.updateImageView = updateImageView;
        
        UILabel * descLabel = [[UILabel alloc] init];
        [self.contentView addSubview:descLabel];
        [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(titleLabel.mas_bottom).offset(15);
            make.left.equalTo(titleLabel.mas_left);
            make.right.equalTo(@-15);
            make.height.equalTo(@40);
        }];
        descLabel.font = [UIFont systemFontOfSize:13];
        descLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
        descLabel.numberOfLines = 2;
        self.descLabel = descLabel;
        
    }
    return self;
}
- (void)setSysMesDetail:(SysMesDetail *)sysMesDetail
{
    _sysMesDetail = sysMesDetail;
    if ([sysMesDetail.sys isEqualToString:@"3"]) {
        self.tagImageView.image = [UIImage imageNamed:@"hardware.png"];
    }else
    {
        self.tagImageView.image = [UIImage imageNamed:@"sorftware.png"];
    }
    if (sysMesDetail.isUpdate) {
        self.updateImageView.hidden = NO;
    }else
    {
        self.updateImageView.hidden = YES;
    }
    NSAttributedString * titleStr = [[NSAttributedString alloc] initWithString:sysMesDetail.title];
    self.titleLabel.attributedText = titleStr;
    [self.titleLabel sizeToFit];
    self.descLabel.text = sysMesDetail.sysinfo;
    self.creatTimeLabel.text = sysMesDetail.createtime;
    
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
