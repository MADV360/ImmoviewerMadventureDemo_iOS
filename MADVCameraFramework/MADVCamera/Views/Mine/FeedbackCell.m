//
//  FeedbackCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/7/4.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "FeedbackCell.h"
#import "Masonry.h"

@interface FeedbackCell()
@property(nonatomic,weak)UIImageView * isSelectImage;
@property(nonatomic,weak)UILabel * contentLabel;
@end

@implementation FeedbackCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self =[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UIImageView * isSelectImage=[[UIImageView alloc] init];
        [self.contentView addSubview:isSelectImage];
        [isSelectImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@15);
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
            make.left.equalTo(isSelectImage.mas_right).offset(7);
            make.right.equalTo(@-15);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@17);
        }];
        contentLabel.font=[UIFont systemFontOfSize:15];
        contentLabel.textColor=[UIColor colorWithHexString:@"#000000"];
        self.contentLabel=contentLabel;
        
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
-(void)setFeedBack:(FeedBack *)feedBack
{
    _feedBack=feedBack;
    self.contentLabel.text=feedBack.content;
    self.isSelectImage.hidden=!feedBack.isSelect;
    if (feedBack.isSelect) {
        self.contentLabel.textColor=[UIColor colorWithHexString:@"#2DACE1"];
    }else
    {
        self.contentLabel.textColor=[UIColor colorWithHexString:@"#000000"];
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
