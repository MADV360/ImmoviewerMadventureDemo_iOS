//
//  PublishQualityCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/23.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "PublishQualityCell.h"
#import "Masonry.h"
@implementation PublishQualityCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UILabel * titleTagLabel = [[UILabel alloc] init];
        [self.contentView addSubview:titleTagLabel];
        [titleTagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@15);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@100);
            make.height.equalTo(@20);
        }];
        titleTagLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        titleTagLabel.font = [UIFont systemFontOfSize:15];
        titleTagLabel.text = FGGetStringWithKeyFromTable(SELECTQUALITY, nil);
        
        UILabel * qualityLabel = [[UILabel alloc] init];
        [self.contentView addSubview:qualityLabel];
        [qualityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-15);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@20);
            make.width.equalTo(@100);
        }];
        qualityLabel.textAlignment = NSTextAlignmentRight;
        qualityLabel.font = [UIFont systemFontOfSize:14];
        qualityLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
        self.qualityLabel = qualityLabel;
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
