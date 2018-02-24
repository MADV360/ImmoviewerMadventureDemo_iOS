//
//  NetMusicCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/11.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "NetMusicCell.h"
#import "Masonry.h"

@interface NetMusicCell()
@property(nonatomic,weak)UILabel * contentLabel;
@property(nonatomic,weak)UILabel * downloadedLabel;
@property(nonatomic,weak)UIButton * downloadBtn;
@property(nonatomic,weak)UILabel * progressLabel;
@property(nonatomic,weak)UIView * progressView;
@end

@implementation NetMusicCell
- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self =[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        UIView * lineView=[[UIView alloc] init];
        [self.contentView addSubview:lineView];
        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@33);
            make.right.equalTo(@0);
            make.bottom.equalTo(@0);
            make.height.equalTo(@1);
        }];
        
        lineView.backgroundColor=[UIColor colorWithHexString:@"#131317" alpha:0.2];
        
        UIImageView * palyImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:palyImageView];
        [palyImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(lineView.mas_left);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@28);
            make.height.equalTo(@28);
        }];
        palyImageView.image=[UIImage imageNamed:@"iocn_play.png"];
        
        
        
        UILabel * contentLabel=[[UILabel alloc] init];
        [self.contentView addSubview:contentLabel];
        [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(palyImageView.mas_right).offset(10);
            make.right.equalTo(@-100);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@17);
        }];
        contentLabel.font=[UIFont systemFontOfSize:15];
        contentLabel.textColor=[UIColor blackColor];
        self.contentLabel=contentLabel;
        
        UILabel * downloadedLabel = [[UILabel alloc] init];
        [self.contentView addSubview:downloadedLabel];
        [downloadedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-15);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@15);
            make.width.equalTo(@50);
        }];
        downloadedLabel.font = [UIFont systemFontOfSize:13];
        downloadedLabel.textAlignment = NSTextAlignmentCenter;
        downloadedLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
        downloadedLabel.text = FGGetStringWithKeyFromTable(DOWNLOADED, nil);
        downloadedLabel.hidden = YES;
        self.downloadedLabel = downloadedLabel;
        
        
        UIButton * downloadBtn=[[UIButton alloc] init];
        [self.contentView addSubview:downloadBtn];
        [downloadBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.right.equalTo(@-15);
            make.width.equalTo(@50);
            make.height.equalTo(@30);
        }];
        [downloadBtn addTarget:self action:@selector(downloadBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [downloadBtn setTitleColor:[UIColor colorWithHexString:@"#0091dc"] forState:UIControlStateNormal];
        downloadBtn.backgroundColor=[UIColor whiteColor];
        [downloadBtn setTitle:FGGetStringWithKeyFromTable(DOWNLOAD, nil) forState:UIControlStateNormal];
        downloadBtn.titleLabel.font=[UIFont systemFontOfSize:13];
        downloadBtn.layer.borderColor=[UIColor colorWithRed:0.87f green:0.87f blue:0.87f alpha:1.00f].CGColor;
        downloadBtn.layer.borderWidth=1;
        downloadBtn.layer.masksToBounds=YES;
        downloadBtn.layer.cornerRadius=5;
        self.downloadBtn = downloadBtn;
        
        UIView * progressView = [[UIView alloc] init];
        [downloadBtn addSubview:progressView];
        progressView.frame = CGRectMake(0, 0, 0, 30);
        progressView.backgroundColor = [UIColor colorWithHexString:@"#0091dc"];
        progressView.hidden = YES;
        progressView.userInteractionEnabled = NO;
        self.progressView =progressView;
        
        UILabel * progressLabel = [[UILabel alloc] init];
        [self.contentView addSubview:progressLabel];
        [progressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(downloadBtn.mas_top);
            make.left.equalTo(downloadBtn.mas_left);
            make.right.equalTo(downloadBtn.mas_right);
            make.bottom.equalTo(downloadBtn.mas_bottom);
        }];
        progressLabel.font = [UIFont systemFontOfSize:13];
        progressLabel.textColor = [UIColor whiteColor];
        progressLabel.textAlignment = NSTextAlignmentCenter;
        progressLabel.hidden = YES;
        self.progressLabel = progressLabel;
        
        
    }
    return self;
}
- (void)downloadBtnClick:(UIButton *)btn
{
    btn.selected = !btn.selected;
    if (btn.selected) {
        self.progressLabel.hidden = NO;
        self.progressView.hidden =NO;
        btn.backgroundColor = [UIColor colorWithRed:0.80f green:0.80f blue:0.80f alpha:1.00f];
        [btn setTitle:@"" forState:UIControlStateNormal];
    }else
    {
        self.progressLabel.hidden = YES;
        self.progressView.hidden =YES;
        btn.backgroundColor = [UIColor whiteColor];
        [btn setTitle:FGGetStringWithKeyFromTable(DOWNLOAD, nil) forState:UIControlStateNormal];

    }
    if ([self.delegate respondsToSelector:@selector(netMusicCellDownload:isStart:)]) {
        self.progressLabel.hidden = NO;
        self.progressView.hidden =NO;
        [self.delegate netMusicCellDownload:self isStart:btn.selected];
    }
}

- (void)setMusicInfo:(MusicInfo *)musicInfo
{
    _musicInfo = musicInfo;
    self.contentLabel.text = musicInfo.name;
    if (musicInfo.isDownloaded) {
        self.downloadBtn.hidden = YES;
        self.progressView.hidden = YES;
        self.progressLabel.hidden = YES;
        self.downloadedLabel.hidden = NO;
    }else if (musicInfo.isDownloading)
    {
        self.downloadedLabel.hidden = YES;
        if (self.progressLabel.hidden) {
            self.downloadBtn.hidden = NO;
            self.downloadBtn.backgroundColor = [UIColor colorWithRed:0.80f green:0.80f blue:0.80f alpha:1.00f];
            [self.downloadBtn setTitle:@"" forState:UIControlStateNormal];
            self.progressView.hidden = NO;
            self.progressLabel.hidden = NO;
            
        }
        self.progressLabel.text = [NSString stringWithFormat:@"%d%@",(int)(musicInfo.downloadRate * 100),@"%"];
        self.progressView.width = musicInfo.downloadRate * 50;
    }else
    {
        self.downloadedLabel.hidden = YES;
        self.progressView.hidden = YES;
        self.progressLabel.hidden = YES;
        self.downloadBtn.hidden = NO;
        self.downloadBtn.backgroundColor = [UIColor whiteColor];
        [self.downloadBtn setTitle:FGGetStringWithKeyFromTable(DOWNLOAD, nil) forState:UIControlStateNormal];
        
        
        
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
