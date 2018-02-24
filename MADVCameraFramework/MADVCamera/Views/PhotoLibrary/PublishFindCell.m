//
//  PublishFindCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/23.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "PublishFindCell.h"
#import "Masonry.h"
@implementation PublishFindCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UILabel * titleTagLabel = [[UILabel alloc] init];
        [self.contentView addSubview:titleTagLabel];
        titleTagLabel.frame = CGRectMake(15, 10, ScreenWidth - 85, 20);
        
        titleTagLabel.numberOfLines = 0;
        titleTagLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        titleTagLabel.font = [UIFont systemFontOfSize:15];
        titleTagLabel.text = FGGetStringWithKeyFromTable(SUBMJFIND, nil);
        [titleTagLabel sizeToFit];
        titleTagLabel.center = CGPointMake(titleTagLabel.center.x, self.contentView.center.y);
        
        UISwitch * syncSwitch=[[UISwitch alloc] init];
        [self.contentView addSubview:syncSwitch];
        [syncSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-15);
            make.top.equalTo(@8);
            make.width.equalTo(@50);
            make.height.equalTo(@20);
        }];
        syncSwitch.onTintColor=[UIColor colorWithHexString:@"#46a4ea"];
        self.syncSwitch = syncSwitch;
    }
    return self;
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
