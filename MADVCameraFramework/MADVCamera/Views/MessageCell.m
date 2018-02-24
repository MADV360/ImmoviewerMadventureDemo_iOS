//
//  MessageCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/10/14.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MessageCell.h"
#import "Masonry.h"

@interface MessageCell()
//@property(nonatomic,weak)UIImageView * msgImageView;
//@property(nonatomic,weak)UILabel * titleLabel;
@property(nonatomic,weak)UILabel * contentLabel;
@end

@implementation MessageCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
//        UIImageView * msgImageView=[[UIImageView alloc] init];
//        [self.contentView addSubview:msgImageView];
//        [msgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(@15);
//            make.left.equalTo(@15);
//            make.width.equalTo(@18);
//            make.height.equalTo(@18);
//        }];
//        msgImageView.image=[UIImage imageNamed:@"news.png"];
//        self.msgImageView=msgImageView;
//        
//        UILabel * titleLabel=[[UILabel alloc] init];
//        [self.contentView addSubview:titleLabel];
//        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.left.equalTo(msgImageView.mas_right).offset(12);
//            make.centerY.equalTo(msgImageView.mas_centerY);
//            make.right.equalTo(@-15);
//            make.height.equalTo(@15);
//        }];
//        titleLabel.font=[UIFont systemFontOfSize:15];
//        titleLabel.textColor=[UIColor blackColor];
//        self.titleLabel=titleLabel;
        
        UILabel * contentLabel=[[UILabel alloc] init];
        [self.contentView addSubview:contentLabel];
        contentLabel.font=[UIFont systemFontOfSize:12];
        contentLabel.numberOfLines=0;
        contentLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.5];
        self.contentLabel=contentLabel;
        
        UIImageView * lineImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:lineImageView];
        [lineImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@0);
            make.right.equalTo(@-15);
            make.bottom.equalTo(@0);
            make.height.equalTo(@1);
        }];
        lineImageView.image = [UIImage imageNamed:@"bg_xuxian.png"];
    }
    return self;
}
- (void)setMsgDetail:(MessageDetail *)msgDetail
{
    _msgDetail=msgDetail;
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@10);
        make.left.equalTo(@38);
        make.right.equalTo(@-15);
        make.height.equalTo(@(msgDetail.contentHeight));
    }];
    self.contentLabel.text=msgDetail.content;
    
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
