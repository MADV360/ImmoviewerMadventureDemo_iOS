//
//  MediaPlayContentInfo.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/8/28.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "MediaPlayContentInfoView.h"
#import "Masonry.h"
#import "TagScroView.h"
#import "MediaPlayContentInfo.h"

@interface MediaPlayContentInfoView()<UITableViewDelegate,UITableViewDataSource,TagScroViewDelegate>
@property(nonatomic,weak)UITableView * tabelView;
@property(nonatomic,weak)UILabel * titleLabel;
@property(nonatomic,weak)UILabel * detailLabel;
@property(nonatomic,weak)TagScroView * tagView;
@property(nonatomic,weak)UIView * tableHeaderView;
@end

@implementation MediaPlayContentInfoView

- (void)loadMediaPlayContentInfoView
{
    UIView * topView = [[UIView alloc] init];
    [self addSubview:topView];
    [topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@40);
    }];
    topView.backgroundColor = [UIColor clearColor];
    
    UILabel * contentLabel = [[UILabel alloc] init];
    [topView addSubview:contentLabel];
    [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@15);
        make.left.equalTo(@15);
        make.bottom.equalTo(@0);
        make.width.equalTo(@100);
    }];
    contentLabel.font = [UIFont systemFontOfSize:15];
    contentLabel.textColor = [UIColor colorWithHexString:@"#ffffff"];
    contentLabel.text = FGGetStringWithKeyFromTable(CONTENTINFO, nil);
    
    UIImageView * closeImageView = [[UIImageView alloc] init];
    [topView addSubview:closeImageView];
    [closeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@-15);
        make.height.equalTo(@13);
        make.width.equalTo(@13);
        make.centerY.equalTo(contentLabel.mas_centerY);
    }];
    closeImageView.image = [UIImage imageNamed:@"mistake-click.png"];
    
    UIView * closeView = [[UIView alloc] init];
    [topView addSubview:closeView];
    [closeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
        make.width.equalTo(@50);
    }];
    closeView.backgroundColor = [UIColor clearColor];
    
    UITapGestureRecognizer * closeTapGes = [[UITapGestureRecognizer alloc] init];
    [closeTapGes addTarget:self action:@selector(closeTapGes:)];
    [closeView addGestureRecognizer:closeTapGes];
    
    UITableView * tabelView = [[UITableView alloc] init];
    [self addSubview:tabelView];
    [tabelView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topView.mas_bottom);
        make.right.equalTo(@0);
        make.left.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    tabelView.dataSource = self;
    tabelView.delegate = self;
    tabelView.backgroundColor = [UIColor clearColor];
    tabelView.separatorColor = [UIColor colorWithHexString:@"#FFFFFF" alpha:0.2];
    tabelView.indicatorStyle=UIScrollViewIndicatorStyleWhite;
    tabelView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tabelView = tabelView;
    if (!self.isLocal) {
        UIView * tableHeaderView = [[UIView alloc] init];
        tableHeaderView.frame = CGRectMake(0, 0, self.width, 100);
        tableHeaderView.backgroundColor = [UIColor clearColor];
        self.tableHeaderView = tableHeaderView;
        
        UILabel * titleLabel = [[UILabel alloc] init];
        [tableHeaderView addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@15);
            make.right.equalTo(@-15);
            make.left.equalTo(@15);
            make.height.equalTo(@20);
        }];
        titleLabel.font = [UIFont systemFontOfSize:16];
        titleLabel.textColor = [UIColor colorWithHexString:@"#ffffff"];
        titleLabel.text = @"复古电话机更好的好几个电话";
        self.titleLabel = titleLabel;
        
        TagScroView * tagView=[[TagScroView alloc] init];
        tagView.delegate=self;
        [tableHeaderView addSubview:tagView];
        tagView.titleColor = [UIColor colorWithHexString:@"#c7c5c5"];
        tagView.titleFont = 10;
        tagView.borderColor = [UIColor colorWithHexString:@"#534947"];
        tagView.contentBackgroundColor = [UIColor clearColor];
        tagView.titleColor = [UIColor colorWithHexString:@"#c7c5c5"];
        tagView.width=self.width-30;
        self.tagView=tagView;
        
        UILabel * detailLabel = [[UILabel alloc] init];
        [tableHeaderView addSubview:detailLabel];
        detailLabel.frame = CGRectMake(15, CGRectGetMaxY(tagView.frame)+15, self.width - 30, 20);
        detailLabel.font = [UIFont systemFontOfSize:13];
        detailLabel.textColor = [UIColor colorWithHexString:@"#e2e1e1"];
        detailLabel.numberOfLines = 0;
        self.detailLabel = detailLabel;
        
        UIView * lineView = [[UIView alloc] init];
        [tableHeaderView addSubview:lineView];
        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@0);
            make.right.equalTo(@0);
            make.left.equalTo(@15);
            make.height.equalTo(@1);
        }];
        lineView.backgroundColor = [UIColor colorWithHexString:@"#FFFFFF" alpha:0.2];
        
        
        tabelView.tableHeaderView = tableHeaderView;
    }else
    {
        UIView * tableHeaderView = [[UIView alloc] init];
        tableHeaderView.frame = CGRectMake(0, 0, self.width, 15);
        tableHeaderView.backgroundColor = [UIColor clearColor];
        self.tableHeaderView = tableHeaderView;
        UIView * lineView = [[UIView alloc] init];
        [tableHeaderView addSubview:lineView];
        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@0);
            make.right.equalTo(@0);
            make.left.equalTo(@15);
            make.height.equalTo(@1);
        }];
        lineView.backgroundColor = [UIColor colorWithHexString:@"#FFFFFF" alpha:0.2];
        tabelView.tableHeaderView = tableHeaderView;
    }
    
    
}
- (void)closeTapGes:(UITapGestureRecognizer *)ges
{
    if ([self.delegate respondsToSelector:@selector(mediaPlayContentInfoViewClose:)]) {
        [self.delegate mediaPlayContentInfoViewClose:self];
    }
}

#pragma mark --UITableViewDataSource代理方法的实现--
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sourceArr.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaPlayContentInfo * contentInfo = self.sourceArr[indexPath.row];
    NSString * identifier=@"ContentInfo";
    UITableViewCell * cell=[tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell==nil) {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.text = contentInfo.title;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
    cell.detailTextLabel.textColor = [UIColor colorWithHexString:@"#ffffff" alpha:0.5];
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
    cell.detailTextLabel.text = contentInfo.value;
    return cell;
}
- (void)setCloudMedia:(MVCloudMedia *)cloudMedia
{
    _cloudMedia = cloudMedia;
    self.titleLabel.text = cloudMedia.title;
    self.tagView.frame = CGRectMake(15, 45, self.width - 30, 25);
    self.tagView.dataArr = cloudMedia.keywords;
    self.detailLabel.width = self.width - 30;
    self.detailLabel.text = cloudMedia.descr;
    [self.detailLabel sizeToFit];
    self.detailLabel.frame = CGRectMake(15, CGRectGetMaxY(self.tagView.frame)+15, self.detailLabel.width, self.detailLabel.height);
    self.tableHeaderView.height = 35 + 10 + 15 + 25 + self.tagView.height + self.detailLabel.height;
    self.tabelView.tableHeaderView = self.tableHeaderView;
    
    
}

- (void)setSourceArr:(NSArray *)sourceArr
{
    _sourceArr = sourceArr;
    
    [UIView animateWithDuration:0 animations:^{
        [self.tabelView reloadData];
    } completion:^(BOOL finished) {
        if (self.isPortrait) {
            if (sourceArr.count == 0) {
                if (self.tableHeaderView.height + 40 < self.height) {
                    CGFloat height = self.tableHeaderView.height + 40;
                    self.frame = CGRectMake(0, ScreenHeight - height, ScreenWidth, height);
                    //self.tabelView.bounces = NO;
                }
                
            }else
            {
                if (40 + self.tabelView.contentSize.height < self.height) {
                    CGFloat height = 40 + self.tabelView.contentSize.height;
                    self.frame = CGRectMake(0, ScreenHeight - height, ScreenWidth, height);
                    //self.tabelView.bounces = NO;
                }
            }
        }
        
        
    }];
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
