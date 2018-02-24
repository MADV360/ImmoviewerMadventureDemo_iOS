//
//  PlayerMoreCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "PlayerMoreCell.h"
#import "Masonry.h"

@interface PlayerMoreCell()
@property(nonatomic,weak)UIImageView * imagView;
@property(nonatomic,weak)UILabel * titleLabel;
@property(nonatomic,weak)UILabel * decLabel;
@property(nonatomic,weak)UISwitch * syncSwitch;
@end

@implementation PlayerMoreCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UIImageView * imagView = [[UIImageView alloc] init];
        [self.contentView addSubview:imagView];
        [imagView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@15);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@17);
            make.height.equalTo(@17);
        }];
        self.imagView = imagView;
        
        UILabel * titleLabel = [[UILabel alloc] init];
        [self.contentView addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(imagView.mas_right).offset(15);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@200);
            make.height.equalTo(@17);
        }];
        titleLabel.font = [UIFont systemFontOfSize:15];
        titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel = titleLabel;
        
        UILabel * decLabel = [[UILabel alloc] init];
        [self.contentView addSubview:decLabel];
        [decLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-15);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@15);
            make.width.equalTo(@150);
        }];
        decLabel.font = [UIFont systemFontOfSize:11];
        decLabel.textColor = [UIColor colorWithHexString:@"#FFFFFF" alpha:0.5];
        decLabel.textAlignment = NSTextAlignmentRight;
        decLabel.text = FGGetStringWithKeyFromTable(EXPORTED, nil);
        decLabel.hidden = YES;
        self.decLabel = decLabel;
        
        UISwitch * syncSwitch=[[UISwitch alloc] init];
        [self.contentView addSubview:syncSwitch];
        [syncSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-15);
            make.centerY.equalTo(self.contentView.mas_centerY).offset(-5);
            make.width.equalTo(@50);
            make.height.equalTo(@20);
        }];
        syncSwitch.onTintColor=[UIColor colorWithHexString:@"#46a4ea"];
        syncSwitch.hidden = YES;
        [syncSwitch addTarget:self action:@selector(syncSwitchClick:) forControlEvents:UIControlEventValueChanged];
        self.syncSwitch = syncSwitch;
        
        
        
        
        
    }
    return self;
}
- (void)syncSwitchClick:(UISwitch *)syncSwitch
{
    self.playerMoreModel.isCorrecting = syncSwitch.on;
    if ([self.delegate respondsToSelector:@selector(playerMoreCell:switchOn:)]) {
        [self.delegate playerMoreCell:self switchOn:syncSwitch.on];
    }
}

- (void)setPlayerMoreModel:(PlayerMoreModel *)playerMoreModel
{
    _playerMoreModel = playerMoreModel;
    self.imagView.image = [UIImage imageNamed:playerMoreModel.imageName];
    self.titleLabel.text = playerMoreModel.title;
    if (playerMoreModel.isExported) {
        self.decLabel.hidden = NO;
    }else
    {
        self.decLabel.hidden = YES;
    }
    if (playerMoreModel.isGyroscope) {
        self.syncSwitch.hidden = NO;
        self.syncSwitch.on = playerMoreModel.isCorrecting;
    }else
    {
        self.syncSwitch.hidden = YES;
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
