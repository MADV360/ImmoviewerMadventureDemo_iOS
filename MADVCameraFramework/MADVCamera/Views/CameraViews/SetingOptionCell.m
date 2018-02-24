//
//  SetingOptionCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/31.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "SetingOptionCell.h"
#import "Masonry.h"

@interface SetingOptionCell()
@property(nonatomic,weak)UIImageView * imgeView;
@end

@implementation SetingOptionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UIImageView * imageView=[[UIImageView alloc] init];
        [self.contentView addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.left.equalTo(@5);
            make.width.equalTo(@6);
            make.height.equalTo(@10);
        }];
        imageView.image=[UIImage imageNamed:@"iocn_hint_blue.png"];
        imageView.hidden=YES;
        self.imgeView=imageView;
    }
    return self;
}

- (void)setIsSelect:(BOOL)isSelect
{
    _isSelect=isSelect;
    if (isSelect) {
        self.imgeView.hidden=NO;
        self.textLabel.textColor=[UIColor colorWithHexString:@"#33B4FF"];
    }else
    {
        self.imgeView.hidden=YES;
        self.textLabel.textColor=[UIColor colorWithHexString:@"#000000"];
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
