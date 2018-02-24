//
//  MediaLibraryCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/9/12.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MediaLibraryCell.h"
#import "Masonry.h"
#import "KDGoalBar.h"
#import "CycleView.h"

@implementation MediaLibraryCell
- (id)initWithFrame:(CGRect)frame
{
    if (self=[super initWithFrame:frame]) {
        UIImageView * defaultImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:defaultImageView];
        [defaultImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@40);
            make.height.equalTo(@40);
        }];
        self.contentView.clipsToBounds=YES;
        defaultImageView.image=[UIImage imageNamed:@"default_picture.png"];
        self.defaultImageView = defaultImageView;
        
        UIImageView * thumbnailImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:thumbnailImageView];
        [thumbnailImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.bottom.equalTo(@0);
        }];
        thumbnailImageView.backgroundColor=[UIColor clearColor];
        thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        thumbnailImageView.layer.masksToBounds = YES;
        self.thumbnailImageView=thumbnailImageView;
        
        UIImageView * playImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:playImageView];
        [playImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@5);
            make.bottom.equalTo(@-5);
            make.width.equalTo(@8);
            make.height.equalTo(@11);
        }];
        playImageView.image=[UIImage imageNamed:@"icon_play.png"];
        self.playImageView=playImageView;
        
        UILabel * durationLabel=[[UILabel alloc] init];
        [self.contentView addSubview:durationLabel];
        [durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(playImageView.mas_right).offset(7);
            make.centerY.equalTo(playImageView.mas_centerY);
            make.height.equalTo(@14);
            make.width.equalTo(@60);
        }];
        durationLabel.font=[UIFont systemFontOfSize:13];
        durationLabel.textColor=[UIColor colorWithHexString:@"#E6EFEE"];
        self.durationLabel=durationLabel;
        
        UIImageView * downloadIconImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:downloadIconImageView];
        [downloadIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-5);
            make.bottom.equalTo(@-5);
            make.width.equalTo(@12);
            make.height.equalTo(@12);
        }];
        downloadIconImageView.image=[UIImage imageNamed:@"downloadIcon.png"];
        downloadIconImageView.hidden=YES;
        self.downloadIconImageView=downloadIconImageView;
        
        UIView * downloadView = [[UIView alloc] init];
        [self.contentView addSubview:downloadView];
        [downloadView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@0);
            make.bottom.equalTo(@0);
            make.width.equalTo(@40);
            make.height.equalTo(@40);
        }];
        downloadView.hidden = YES;
        downloadView.backgroundColor = [UIColor clearColor];
        self.downloadView = downloadView;
        
        UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] init];
        [tapGes addTarget:self action:@selector(download:)];
        [downloadView addGestureRecognizer:tapGes];
        
        UIImageView * stitchImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:stitchImageView];
        [stitchImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@5);
            make.left.equalTo(@5);
            make.width.equalTo(@16);
            make.height.equalTo(@11);
        }];
        stitchImageView.image = [UIImage imageNamed:@"stitched.png"];
        stitchImageView.hidden = YES;
        self.stitchImageView = stitchImageView;
        
        UIView * maskView=[[UIView alloc] init];
        [self.contentView addSubview:maskView];
        [maskView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.bottom.equalTo(@0);
        }];
        maskView.backgroundColor=[UIColor colorWithHexString:@"#000000" alpha:0.6];
        self.maskView=maskView;
        
        UIImageView * selectImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:selectImageView];
        
        self.selectImageView=selectImageView;
        
        CycleView * progressView = [[CycleView alloc] initWithFrame:CGRectMake(self.contentView.width*0.5-25, self.contentView.height*0.5-25, 50, 50)];
        progressView.isRateShow=YES;
        progressView.textFont = [UIFont systemFontOfSize:12];
        progressView.textColor = [UIColor whiteColor];
        progressView.rightColor=[UIColor whiteColor];
        progressView.leftColor=[UIColor colorWithHexString:@"#FFFFFF" alpha:0.2];
        [progressView loadCycleView];
        progressView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:progressView];
        self.progressView=progressView;
        
        UIImageView * downloadImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:downloadImageView];
        [downloadImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@40);
            make.height.equalTo(@40);
        }];
        downloadImageView.hidden=YES;
        self.downloadImageView=downloadImageView;
        
        
        
    }
    return self;
}
- (void)setIsLocal:(BOOL)isLocal
{
    _isLocal=isLocal;
    if (isLocal) {
        [self.selectImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-3);
            make.bottom.equalTo(@-3);
            make.width.equalTo(@21);
            make.height.equalTo(@21);
        }];
    }else
    {
        [self.selectImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-3);
            make.top.equalTo(@3);
            make.width.equalTo(@21);
            make.height.equalTo(@21);
        }];
    }
}

- (void)download:(UITapGestureRecognizer *)tap
{
    if (self.selectImageView.hidden) {
        if ([self.delegate respondsToSelector:@selector(mediaLibraryCell:downloadIndexPath:)]) {
            [self.delegate mediaLibraryCell:self downloadIndexPath:self.indexPath];
        }
    }
    
}
@end
