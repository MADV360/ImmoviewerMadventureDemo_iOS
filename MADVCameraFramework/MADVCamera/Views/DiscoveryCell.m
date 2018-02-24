//
//  DiscoveryCell.m
//  Madv360_v1
//
//  Created by QiuDong on 16/5/13.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "DiscoveryCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Masonry.h"


@interface DiscoveryCell()<DivisionButtonViewDelegate>
@property(nonatomic,weak)UIImageView * thumImageView;
@property(nonatomic,weak)UIImageView * authorImageView;
@property(nonatomic,weak)UILabel * keyWordLabel;
@property(nonatomic,weak)UILabel * titleLabel;
@property(nonatomic,weak)UILabel * favorLabel;
@property(nonatomic,weak)UIImageView * typeImageView;
@property(nonatomic,weak)UILabel * nameLabel;
@property(nonatomic,weak)UILabel * timeLabel;
@property(nonatomic,weak)UILabel * publishTimeLabel;
@property(nonatomic,weak)UIButton * handleBtn;
@property(nonatomic,weak)UIImageView * vipImageView;
@property(nonatomic,weak)UIImageView * inviteImageView;
@property(nonatomic,weak)UILabel * authorNameLabel;
@property(nonatomic,weak)UIImageView * centerImage;
@property(nonatomic,weak)DivisionButtonView * rightView;
@property(nonatomic,weak)DivisionButtonView * mineRightView;
@end

@implementation DiscoveryCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        [self setupSubviews];
    }
    return self;
}

- (void) setupSubviews {
    
    UIImageView * defaultImageView=[[UIImageView alloc] init];
    [self.contentView addSubview:defaultImageView];
    
    defaultImageView.image=[UIImage imageNamed:@"default_picture.png"];
    
    UIImageView * thumImageView=[[UIImageView alloc] init];
    [self.contentView addSubview:thumImageView];
    [thumImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@194);
    }];
    thumImageView.backgroundColor=[UIColor clearColor];
    self.thumImageView=thumImageView;
    
    [defaultImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView.mas_centerX);
        make.centerY.equalTo(thumImageView.mas_centerY);
        make.width.equalTo(@100);
        make.height.equalTo(@100);
    }];
    
    UIImageView * maskImageView=[[UIImageView alloc] init];
    [self.contentView addSubview:maskImageView];
    [maskImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@194);
    }];
    maskImageView.image=[UIImage imageNamed:@"Mask"];
    
    UIImageView * centerImage=[[UIImageView alloc] init];
    [self.contentView addSubview:centerImage];
    [centerImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(thumImageView.mas_centerX);
        make.centerY.equalTo(thumImageView.mas_centerY);
        make.width.equalTo(@50);
        make.height.equalTo(@50);
    }];
    centerImage.image=[UIImage imageNamed:@"play_discover.png"];
    self.centerImage=centerImage;
    
    UIView * bottomView = [[UIView alloc] init];
    [self.contentView addSubview:bottomView];
    [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(thumImageView.mas_bottom);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@65);
    }];
    bottomView.backgroundColor = [UIColor whiteColor];
    
    
    UIImageView * authorImageView=[[UIImageView alloc] init];
    [bottomView addSubview:authorImageView];
//    [authorImageView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(@15);
//        make.centerY.equalTo(bottomView.mas_centerY);
//        make.width.equalTo(@35);
//        make.height.equalTo(@35);
//    }];
    authorImageView.frame = CGRectMake(15, (65-35)*0.5, 35, 35);
    authorImageView.layer.masksToBounds=YES;
    authorImageView.layer.cornerRadius=17.5;
    
    authorImageView.layer.borderWidth=1;
    authorImageView.layer.borderColor=[UIColor whiteColor].CGColor;
    self.authorImageView=authorImageView;
    
//    UIImageView * vipImageView = [[UIImageView alloc] init];
//    [self.contentView addSubview:vipImageView];
//    [vipImageView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(authorImageView.mas_bottom).offset(-10);
//        make.right.equalTo(authorImageView.mas_right);
//        make.width.equalTo(@15);
//        make.height.equalTo(@15);
//    }];
//    vipImageView.image = [UIImage imageNamed:@"vip.png"];
//    vipImageView.hidden = YES;
//    self.vipImageView = vipImageView;
    
    UILabel * titleLabel = [[UILabel alloc] init];
    [bottomView addSubview:titleLabel];
    titleLabel.frame = CGRectMake(60, (65-35)*0.5, ScreenWidth-110-60, 16);
    titleLabel.font = [UIFont systemFontOfSize:15];
    titleLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.9];
    self.titleLabel = titleLabel;
    
    UIView * authorImageClickView = [[UIView alloc] init];
    [bottomView addSubview:authorImageClickView];
    [authorImageClickView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.right.equalTo(titleLabel.mas_left);
        make.left.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    authorImageClickView.backgroundColor = [UIColor clearColor];
    authorImageClickView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer * authorClickGes = [[UITapGestureRecognizer alloc] init];
    [authorClickGes addTarget:self action:@selector(authorClickGes:)];
    [authorImageClickView addGestureRecognizer:authorClickGes];
    
    
    
    
//    UIImageView * inviteImageView = [[UIImageView alloc] init];
//    [self.contentView addSubview:inviteImageView];
//    
//    inviteImageView.image = [UIImage imageNamed:@"invite.png"];
//    inviteImageView.hidden = YES;
//    self.inviteImageView = inviteImageView;
    
    UILabel * authorNameLabel=[[UILabel alloc] init];
    [bottomView addSubview:authorNameLabel];
    [authorNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@(-(65-35)*0.5));
        make.left.equalTo(@60);
        make.width.equalTo(@(ScreenWidth-110-60));
        make.height.equalTo(@17);
    }];
    authorNameLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.6];
    authorNameLabel.font=[UIFont systemFontOfSize:12];
    self.authorNameLabel=authorNameLabel;
    
    
    DivisionButtonView * rightView = [[DivisionButtonView alloc] init];
    [bottomView addSubview:rightView];
    rightView.frame = CGRectMake(ScreenWidth - 110, 0 , 110, 65);
    rightView.imageArray = @[@"look_discover.png",@"love_discover.png"];
    rightView.nameArray = @[@"",@""];
    [rightView loadDivisionButtonView];
    rightView.delegate = self;
    self.rightView = rightView;
    
    
    DivisionButtonView * mineRightView = [[DivisionButtonView alloc] init];
    [bottomView addSubview:mineRightView];
    mineRightView.frame = CGRectMake(ScreenWidth - 175, 0 , 175, 65);
    mineRightView.imageArray = @[@"look_discover.png",@"love_discover.png",@"more_discover.png"];
    mineRightView.nameArray = @[@"",@"",FGGetStringWithKeyFromTable(MORE, nil)];
    [mineRightView loadDivisionButtonView];
    mineRightView.delegate = self;
    mineRightView.hidden = YES;
    self.mineRightView = mineRightView;
    
    
    
    /*
    UILabel * publishTimeLabel = [[UILabel alloc] init];
    [bottomView addSubview:publishTimeLabel];
    [publishTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@-15);
        make.centerY.equalTo(bottomView.mas_centerY);
        make.height.equalTo(@13);
        make.width.equalTo(@85);
    }];
    publishTimeLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
    publishTimeLabel.font = [UIFont systemFontOfSize:12];
    publishTimeLabel.textAlignment = NSTextAlignmentRight;
    self.publishTimeLabel = publishTimeLabel;
    
    UIButton * handleBtn = [[UIButton alloc] init];
    [bottomView addSubview:handleBtn];
    [handleBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@-15);
        make.centerY.equalTo(bottomView.mas_centerY);
        make.width.equalTo(@30);
        make.height.equalTo(@60);
    }];
    [handleBtn setImage:[UIImage imageNamed:@"more-hui.png"] forState:UIControlStateNormal];
    [handleBtn addTarget:self action:@selector(handleBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    handleBtn.hidden = YES;
    self.handleBtn = handleBtn;*/
    
    
//    UIImageView * favorImageView=[[UIImageView alloc] init];
//    [self.contentView addSubview:favorImageView];
//    favorImageView.layer.cornerRadius=5;
//    favorImageView.layer.masksToBounds=YES;
//    favorImageView.image=[UIImage imageNamed:@"collect_unselected_white.png"];
//    favorImageView.userInteractionEnabled=YES;
//    self.favorImageView=favorImageView;
    
#pragma mark --目前先不要--
    
    
    
//    UILabel * favorLabel=[[UILabel alloc] init];
//    [self.contentView addSubview:favorLabel];
//    favorLabel.font=[UIFont systemFontOfSize:15];
//    favorLabel.textColor=[UIColor whiteColor];
//    self.favorLabel=favorLabel;
    
    UIView * lineView=[[UIView alloc] init];
    [self.contentView addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@10);
    }];
    lineView.backgroundColor=[UIColor colorWithRed:0.93f green:0.93f blue:0.93f alpha:1.00f];
}
#pragma mark --DivisionButtonViewDelegate代理方法的实现--
- (void)divisionButtonViewClick:(DivisionButtonView *)divisionButtonView index:(int)index
{
    if (index == 1) {
        if ([self.delegate respondsToSelector:@selector(discoveryCellDidFavor:andIsFavor:andFileName:andImageView:andFavorNum:title:)]) {
            DivisionButtonView * rightView;
            if (!self.rightView.hidden) {
                rightView = self.rightView;
            }
            if (!self.mineRightView.hidden) {
                rightView = self.mineRightView;
            }
            [self.delegate discoveryCellDidFavor:self andIsFavor:self.cloudMedia.favored andFileName:self.cloudMedia.filename andImageView:rightView andFavorNum:[self.cloudMedia.favor intValue] title:self.cloudMedia.title];
        }
    }else if (index == 2)
    {
        if ([self.delegate respondsToSelector:@selector(discoveryCellClick:)]) {
            [self.delegate discoveryCellClick:self];
        }
    }
}
//点击收藏的事件  目前先不要
- (void)favorTap:(UITapGestureRecognizer *)tap
{
    
    if ([self.delegate respondsToSelector:@selector(discoveryCellDidFavor:andIsFavor:andFileName:andImageView:andFavorLabel:title:)]) {
//        [self.delegate discoveryCellDidFavor:self andIsFavor:self.cloudMedia.favored andFileName:self.cloudMedia.filename andImageView:self.favorImageView andFavorLabel:self.favorLabel title:self.cloudMedia.title];
    }
}

- (void)setCloudMedia:(MVCloudMedia *)cloudMedia
{
    _cloudMedia=cloudMedia;
    
    
    [self.thumImageView sd_setImageWithURL:[NSURL URLWithString:cloudMedia.thumbnail]];
    if ([cloudMedia.type isEqualToString:@"0"]) {
        self.centerImage.hidden = YES;
        
    }else
    {
        self.centerImage.hidden = NO;
        
    }
    
    
    [self.authorImageView sd_setImageWithURL:[NSURL URLWithString:cloudMedia.author_avatar] placeholderImage:[UIImage imageNamed:@"head.png"]];
    
    self.authorNameLabel.text=cloudMedia.author_name;
    
//    NSMutableAttributedString * authorNameAttributed = [[NSMutableAttributedString alloc] initWithString:cloudMedia.title];
    self.titleLabel.text=cloudMedia.title;
//    [self.titleLabel sizeToFit];
    
    
    
    
    
    
    
    int viewCount = [cloudMedia.view_count intValue];
    NSString * viewCountStr = @"";
    if (viewCount >= 10000) {
        viewCountStr = [self formatInt:viewCount];
    }else
    {
        viewCountStr = [NSString stringWithFormat:@"%d",viewCount];
    }
    
    int favor = [cloudMedia.favor intValue];
    NSString * favorStr = @"";
    if (favor >= 10000) {
        favorStr = [self formatInt:favor];
    }else
    {
        favorStr = cloudMedia.favor;
    }
    
    if (self.isMine) {
        self.rightView.hidden = YES;
        self.mineRightView.hidden = NO;
        self.titleLabel.frame = CGRectMake(60, (65-35)*0.5, ScreenWidth-175-60, 16);
        [self.authorNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@(-(65-35)*0.5));
            make.left.equalTo(@60);
            make.width.equalTo(@(ScreenWidth-175-60));
            make.height.equalTo(@17);
        }];
        [self.mineRightView setNameIndex:0 name:viewCountStr];
        [self.mineRightView setNameIndex:1 name:favorStr];
        if ([cloudMedia.favored isEqualToString:@"0"]) {
            [self.mineRightView setImageIndex:1 imageName:@"love_discover.png"];
        }else
        {
            [self.mineRightView setImageIndex:1 imageName:@"love_discover-click.png"];
        }
    }else
    {
        self.rightView.hidden = NO;
        self.mineRightView.hidden = YES;
        [self.rightView setNameIndex:0 name:viewCountStr];
        [self.rightView setNameIndex:1 name:favorStr];
        if ([cloudMedia.favored isEqualToString:@"0"]) {
            [self.rightView setImageIndex:1 imageName:@"love_discover.png"];
        }else
        {
            [self.rightView setImageIndex:1 imageName:@"love_discover-click.png"];
        }
        
    }
    
    
    
}

- (void)authorClickGes:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(discoveryCellAuthorClick:)]) {
        [self.delegate discoveryCellAuthorClick:self];
    }
}

- (void)handleBtnClick:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(discoveryCellClick:)]) {
        [self.delegate discoveryCellClick:self];
    }
}

- (NSString *)formatInt:(int)num
{
    int thethousand = num/10000;
    int thousand = (num - thethousand * 10000)/1000;
    if (thousand > 0) {
        return [NSString stringWithFormat:@"%d.%d万",thethousand,thousand];
    }
    return [NSString stringWithFormat:@"%d万",thethousand];
}

- (NSString *)formatFloat:(float)f
{
    if (fmodf(f, 1)==0) {//如果有一位小数点
        return [NSString stringWithFormat:@"%.2f",f];
    } else if (fmodf(f*10, 1)==0) {//如果有两位小数点
        return [NSString stringWithFormat:@"%.2f",f];
    } else {
        return [NSString stringWithFormat:@"%.2f",f];
    }
}

-(NSString*) formatTimeInterval:(CGFloat)seconds isLeft:(BOOL) isLeft
{
    seconds = MAX(0, seconds);
    
    NSInteger s = seconds;
    NSInteger m = s / 60;
    NSInteger h = m / 60;
    
    s = s % 60;
    m = m % 60;
    
    NSMutableString *format = [(isLeft && seconds >= 0.5 ? @"-" : @"") mutableCopy];
    if (h != 0) [format appendFormat:@"%0.2ld:%0.2ld", (long)h, (long)m];
    else        [format appendFormat:@"%0.2ld′", (long)m];
    [format appendFormat:@"%0.2ld″", (long)s];
    //    [format appendFormat:@"%ld:%0.2ld", (long)h, (long)m];
    //    [format appendFormat:@":%0.2ld", (long)s];
    
    return format;
}



@end
