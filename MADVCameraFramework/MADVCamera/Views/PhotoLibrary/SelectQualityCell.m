//
//  SelectQualityCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/24.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "SelectQualityCell.h"
#import "Masonry.h"
@implementation SelectQualityCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UIImageView * isSelectImage=[[UIImageView alloc] init];
        [self.contentView addSubview:isSelectImage];
        [isSelectImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@10);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@10);
            make.height.equalTo(@10);
        }];
        isSelectImage.image=[UIImage imageNamed:@"hint.png"];
        isSelectImage.hidden=YES;
        self.isSelectImage=isSelectImage;
        
        UILabel * contentLabel=[[UILabel alloc] init];
        [self.contentView addSubview:contentLabel];
        [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(isSelectImage.mas_right).offset(6);
            make.width.equalTo(@200);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@17);
        }];
        contentLabel.font=[UIFont systemFontOfSize:15];
        contentLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.8];
        self.contentLabel=contentLabel;
        
        UILabel * fileSizeLabel=[[UILabel alloc] init];
        [self.contentView addSubview:fileSizeLabel];
        [fileSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-15);
            make.width.equalTo(@200);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@17);
        }];
        fileSizeLabel.font=[UIFont systemFontOfSize:14];
        fileSizeLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.8];
        fileSizeLabel.textAlignment = NSTextAlignmentRight;
        self.fileSizeLabel=fileSizeLabel;
        
        UIView * lineView=[[UIView alloc] init];
        [self.contentView addSubview:lineView];
        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(contentLabel.mas_left);
            make.right.equalTo(@0);
            make.bottom.equalTo(@0);
            make.height.equalTo(@1);
        }];
        
        lineView.backgroundColor=[UIColor colorWithRed:0.84f green:0.84f blue:0.85f alpha:1.00f];
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
