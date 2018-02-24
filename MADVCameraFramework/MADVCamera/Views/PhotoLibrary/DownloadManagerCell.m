//
//  DownloadManagerCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/9/20.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "DownloadManagerCell.h"
#import "Masonry.h"

@implementation DownloadManagerCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UIImageView * defaultImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:defaultImageView];
        defaultImageView.image=[UIImage imageNamed:@"default_picture.png"];
        
        UIImageView * thumbnailImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:thumbnailImageView];
        [thumbnailImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@15);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@70);
            make.height.equalTo(@50);
        }];
        [defaultImageView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.centerY.equalTo(thumbnailImageView.mas_centerY);
//            make.centerX.equalTo(thumbnailImageView.mas_centerX);
//            make.width.equalTo(@30);
//            make.height.equalTo(@30);
            make.top.equalTo(thumbnailImageView.mas_top);
            make.bottom.equalTo(thumbnailImageView.mas_bottom);
            make.left.equalTo(thumbnailImageView.mas_left);
            make.right.equalTo(thumbnailImageView.mas_right);
        }];
        self.thumbnailImageView=thumbnailImageView;
        
        UIImageView * playImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:playImageView];
        [playImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(thumbnailImageView.mas_centerX);
            make.centerY.equalTo(thumbnailImageView.mas_centerY);
            make.width.equalTo(@17);
            make.height.equalTo(@17);
        }];
        playImageView.image=[UIImage imageNamed:@"download_play.png"];
        self.playImageView=playImageView;
        
        UILabel * filenameLabel=[[UILabel alloc] init];
        [self.contentView addSubview:filenameLabel];
        
        filenameLabel.font=[UIFont systemFontOfSize:15];
        filenameLabel.textColor=[UIColor colorWithHexString:@"#000000"];
        self.filenameLabel=filenameLabel;
        
        UILabel * downloadBtyeLabel=[[UILabel alloc] init];
        [self.contentView addSubview:downloadBtyeLabel];
        [downloadBtyeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(filenameLabel.mas_bottom).offset(10);
            make.left.equalTo(filenameLabel.mas_left);
            make.width.equalTo(@150);
            make.height.equalTo(@14);
        }];
        downloadBtyeLabel.font=[UIFont systemFontOfSize:13];
        downloadBtyeLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.7];
        self.downloadBtyeLabel=downloadBtyeLabel;
        
        UIImageView * statusImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:statusImageView];
        [statusImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-15);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@31);
            make.height.equalTo(@31);
        }];
        self.statusImageView=statusImageView;
        
        [filenameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(thumbnailImageView.mas_right).offset(10);
            make.right.equalTo(statusImageView.mas_left);
            make.top.equalTo(thumbnailImageView.mas_top);
            make.height.equalTo(@17);
        }];
        
        UIImageView * selectImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:selectImageView];
        [selectImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(statusImageView.mas_centerY);
            make.centerX.equalTo(statusImageView.mas_centerX);
            make.width.equalTo(@20);
            make.height.equalTo(@20);
        }];
        self.selectImageView=selectImageView;
        
        UIView * defaultView=[[UIView alloc] init];
        [self.contentView addSubview:defaultView];
        [defaultView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(filenameLabel.mas_left);
            make.top.equalTo(downloadBtyeLabel.mas_bottom).offset(5);
            make.right.equalTo(statusImageView.mas_left).offset(-25);
            make.height.equalTo(@2);
        }];
        defaultView.backgroundColor=[UIColor colorWithRed:0.86f green:0.86f blue:0.86f alpha:1.00f];
        
        self.defaultDownWidth=ScreenWidth-166;
        
        UIView * progressView=[[UIView alloc] init];
        [defaultView addSubview:progressView];
        progressView.frame=CGRectMake(0, 0, 0, 2);
        progressView.backgroundColor=[UIColor colorWithRed:0.18f green:0.67f blue:0.88f alpha:1.00f];
        self.progressView=progressView;
        
        UIView * backView = [[UIView alloc] init];
        [self.contentView addSubview:backView];
        [backView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(defaultView.mas_right);
            make.bottom.equalTo(@0);
        }];
        backView.backgroundColor = [UIColor clearColor];
        
        UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] init];
        [tapGes addTarget:self action:@selector(tapGes:)];
        [backView addGestureRecognizer:tapGes];
        
    }
    return self;
}
- (void)tapGes:(UITapGestureRecognizer *)tap
{
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
