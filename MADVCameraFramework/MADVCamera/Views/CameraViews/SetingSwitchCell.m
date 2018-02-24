//
//  SetingSwitchCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/7/11.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "SetingSwitchCell.h"
#import "Masonry.h"

@interface SetingSwitchCell()
@property(nonatomic,weak)UISwitch * openSwitch;
@end

@implementation SetingSwitchCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        UILabel * descLabel = [[UILabel alloc] init];
        [self.contentView addSubview:descLabel];
        descLabel.textColor = self.textLabel.textColor;
        descLabel.numberOfLines = 0;
        self.descLabel = descLabel;
        
        UISwitch * openSwitch = [[UISwitch alloc] init];
        [self.contentView addSubview:openSwitch];
        [openSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-15);
            make.centerY.equalTo(self.contentView.mas_centerY).offset(-5);
            make.width.equalTo(@50);
            make.height.equalTo(@20);
        }];
        [openSwitch addTarget:self action:@selector(openSwitch:) forControlEvents:UIControlEventValueChanged];
        openSwitch.onTintColor=[UIColor colorWithHexString:@"#46a4ea"];
        self.openSwitch = openSwitch;
    }
    return self;
}
- (void)openSwitch:(UISwitch *)openSwitch
{
    if ([self.delegate respondsToSelector:@selector(setingSwitchCell:switchValueChange:)]) {
        [self.delegate setingSwitchCell:self switchValueChange:openSwitch.on];
    }
}
- (void)setOpenSwitchValue:(BOOL)on
{
    self.openSwitch.on = on;
}
- (BOOL)getOpenSwitchValue
{
    return self.openSwitch.on;
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
