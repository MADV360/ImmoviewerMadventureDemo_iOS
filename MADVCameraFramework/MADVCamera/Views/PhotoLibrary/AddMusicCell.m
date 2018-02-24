//
//  AddMusicCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/11.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AddMusicCell.h"
#import "Masonry.h"

@interface AddMusicCell()
@property(nonatomic,weak)UIImageView * isSelectImage;
@property(nonatomic,weak)UILabel * contentLabel;
@property(nonatomic,weak)UILabel * typeLabel;
@end


@implementation AddMusicCell
- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self =[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UIImageView * isSelectImage=[[UIImageView alloc] init];
        [self.contentView addSubview:isSelectImage];
        [isSelectImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@10);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@12);
            make.height.equalTo(@9);
        }];
        isSelectImage.image=[UIImage imageNamed:@"icon_check_hig.png"];
        isSelectImage.hidden=YES;
        self.isSelectImage=isSelectImage;
        
        UILabel * contentLabel=[[UILabel alloc] init];
        [self.contentView addSubview:contentLabel];
        
        contentLabel.font=[UIFont systemFontOfSize:15];
        contentLabel.textColor=[UIColor blackColor];
        self.contentLabel=contentLabel;
        
        UILabel * typeLabel = [[UILabel alloc] init];
        [self.contentView addSubview:typeLabel];
        [typeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-20);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@15);
            make.width.equalTo(@50);
        }];
        typeLabel.font = [UIFont systemFontOfSize:13];
        typeLabel.textAlignment = NSTextAlignmentRight;
        typeLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
        self.typeLabel = typeLabel;
        
        [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(isSelectImage.mas_right).offset(6);
            make.right.equalTo(typeLabel.mas_left);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@17);
        }];
        
        
        
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

- (void)setMusicInfo:(MusicInfo *)musicInfo
{
    _musicInfo = musicInfo;
    self.contentLabel.text = musicInfo.name;
    self.typeLabel.text = musicInfo.type;
    self.isSelectImage.hidden = !musicInfo.isSelect;
    if (musicInfo.isSelect) {
        self.contentLabel.textColor = [UIColor colorWithHexString:@"#0091dc"];
    }else
    {
        self.contentLabel.textColor = [UIColor blackColor];
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
