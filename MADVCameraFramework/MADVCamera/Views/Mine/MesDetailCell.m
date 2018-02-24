//
//  MesDetailCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/3/2.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "MesDetailCell.h"
#import "Masonry.h"

@interface MesDetailCell()
@property(nonatomic,weak)UILabel * versionLabel;
@property(nonatomic,weak)UILabel * createTimeLabel;
@property(nonatomic,weak)UILabel * contentLabel;
@property(nonatomic,weak)UILabel * historyLabel;
@property(nonatomic,weak)UIButton * updateBtn;

@end

@implementation MesDetailCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UILabel * historyLabel = [[UILabel alloc] init];
        [self.contentView addSubview:historyLabel];
        historyLabel.frame = CGRectMake(15, 25, 250, 20);
        historyLabel.font = [UIFont systemFontOfSize:16];
        historyLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        historyLabel.text = FGGetStringWithKeyFromTable(HISTORYNOTICE, nil);
        historyLabel.hidden = YES;
        self.historyLabel = historyLabel;
        
        
        
        UILabel * versionLabel = [[UILabel alloc] init];
        [self.contentView addSubview:versionLabel];
        versionLabel.frame = CGRectMake(15, 25, 300, 20);
        versionLabel.font = [UIFont systemFontOfSize:16];
        versionLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        self.versionLabel = versionLabel;
        
        UILabel * createTimeLabel = [[UILabel alloc] init];
        [self.contentView addSubview:createTimeLabel];
        createTimeLabel.frame = CGRectMake(15, CGRectGetMaxY(versionLabel.frame)+10, 100, 15);
        createTimeLabel.font = [UIFont systemFontOfSize:12];
        createTimeLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
        self.createTimeLabel = createTimeLabel;
        
        UILabel * contentLabel = [[UILabel alloc] init];
        [self.contentView addSubview:contentLabel];
        contentLabel.frame = CGRectMake(15, CGRectGetMaxY(createTimeLabel.frame)+25, ScreenWidth-30, 20);
        contentLabel.font = [UIFont systemFontOfSize:16];
        contentLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
        contentLabel.numberOfLines = 0;
        self.contentLabel = contentLabel;
        
        UIButton * updateBtn = [[UIButton alloc] init];
        [self.contentView addSubview:updateBtn];
        updateBtn.frame = CGRectMake(70, CGRectGetMaxY(contentLabel.frame) + 25, ScreenWidth - 140, 40);
        updateBtn.backgroundColor = [UIColor colorWithRed:0.67f green:0.67f blue:0.67f alpha:1.00f];
        [updateBtn setTitle:FGGetStringWithKeyFromTable(DOWNLOADUPDATE, nil) forState:UIControlStateNormal];
        [updateBtn setTitleColor:[UIColor colorWithHexString:@"#ffffff"] forState:UIControlStateNormal];
        [updateBtn addTarget:self action:@selector(updateBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        updateBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        updateBtn.layer.masksToBounds = YES;
        updateBtn.layer.cornerRadius = 5;
        updateBtn.hidden = YES;
        self.updateBtn = updateBtn;

        
        
    }
    return self;
}
- (void)setSysMesDetail:(SysMesDetail *)sysMesDetail
{
    _sysMesDetail = sysMesDetail;
    if (sysMesDetail.isOld) {
        self.historyLabel.hidden = NO;
        self.versionLabel.y = CGRectGetMaxY(self.historyLabel.frame) + 15;
    }else
    {
        self.historyLabel.hidden = YES;
        self.versionLabel.y = 25;
    }
    if (sysMesDetail.isUpdate) {
        self.updateBtn.hidden = NO;
    }else
    {
        self.updateBtn.hidden = YES;
    }
    self.createTimeLabel.y = CGRectGetMaxY(self.versionLabel.frame)+10;
    self.contentLabel.y = CGRectGetMaxY(self.createTimeLabel.frame)+25;
    self.updateBtn.y = CGRectGetMaxY(self.contentLabel.frame) + 25;
    self.versionLabel.text = [NSString stringWithFormat:@"%@: V%@",FGGetStringWithKeyFromTable(NEWVERSION, nil),sysMesDetail.version];
    self.createTimeLabel.text = sysMesDetail.createtime;
    sysMesDetail.sysinfo = [sysMesDetail.sysinfo stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:sysMesDetail.sysinfo];
    self.contentLabel.attributedText = attributedString;
    [self.contentLabel sizeToFit];
    if (self.contentLabel.width < ScreenWidth - 30) {
        self.contentLabel.width = ScreenWidth - 30;
    }
    
    sysMesDetail.sysinfoHeight = self.contentLabel.height;
    //self.contentLabel.text = sysMesDetail.sysinfo;
    self.updateBtn.frame = CGRectMake(70, CGRectGetMaxY(self.contentLabel.frame) + 25, ScreenWidth - 140, 40);
    
    
}
#pragma mark --下载更新--
- (void)updateBtnClick:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(mesDetailCellUpdate:)]) {
        [self.delegate mesDetailCellUpdate:self];
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
