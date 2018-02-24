//
//  MessageHeaderView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/11.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MessageHeaderView.h"
#import "Masonry.h"

@interface MessageHeaderView()
@property(nonatomic,weak)UIImageView * msgImageView;
@property(nonatomic,weak)UILabel * titleLabel;
@property(nonatomic,weak)UIButton * expandBtn;
@property(nonatomic,weak)UIImageView * lineImageView;
@end
@implementation MessageHeaderView
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super initWithReuseIdentifier:reuseIdentifier])
    {
        UIImageView * msgImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:msgImageView];
        [msgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.left.equalTo(@15);
            make.width.equalTo(@18);
            make.height.equalTo(@18);
        }];
        msgImageView.image=[UIImage imageNamed:@"news.png"];
        self.msgImageView=msgImageView;
        
        UIButton * expandBtn=[[UIButton alloc] init];
        [self.contentView addSubview:expandBtn];
        [expandBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-15);
            make.width.equalTo(@18);
            make.height.equalTo(@18);
            make.centerY.equalTo(msgImageView.mas_centerY);
        }];
        [expandBtn setBackgroundImage:[UIImage imageNamed:@"img_arrow_down.png"] forState:UIControlStateNormal];
        [expandBtn setBackgroundImage:[UIImage imageNamed:@"img_arrow_up.png"] forState:UIControlStateSelected];
//        [expandBtn addTarget:self action:@selector(expandBtn:) forControlEvents:UIControlEventTouchUpInside];
        self.expandBtn=expandBtn;
        
        UIView * expandView=[[UIView alloc] init];
        [self.contentView addSubview:expandView];
        [expandView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.right.equalTo(@0);
            make.bottom.equalTo(@0);
            make.width.equalTo(@40);
        }];
        
        UITapGestureRecognizer * tapGes=[[UITapGestureRecognizer alloc] init];
        [tapGes addTarget:self action:@selector(tapGes:)];
        [expandView addGestureRecognizer:tapGes];
        
        UILabel * titleLabel=[[UILabel alloc] init];
        [self.contentView addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(msgImageView.mas_right).offset(5);
            make.centerY.equalTo(msgImageView.mas_centerY);
            make.right.equalTo(@-15);
            make.height.equalTo(@15);
        }];
        titleLabel.font=[UIFont systemFontOfSize:15];
        titleLabel.textColor=[UIColor blackColor];
        self.titleLabel=titleLabel;
        
        UIImageView * lineImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:lineImageView];
        [lineImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@0);
            make.right.equalTo(@-15);
            make.bottom.equalTo(@0);
            make.height.equalTo(@1);
        }];
        lineImageView.image = [UIImage imageNamed:@"bg_xuxian.png"];
        lineImageView.hidden = self.expandBtn.selected;
        self.lineImageView = lineImageView;
    }
    return self;
}
- (void)setMsgDetail:(MessageDetail *)msgDetail
{
    _msgDetail=msgDetail;
    self.titleLabel.text=msgDetail.title;
    self.expandBtn.selected=msgDetail.expand;
    self.lineImageView.hidden = self.expandBtn.selected;
}

- (void)expandBtn:(UIButton *)btn
{
    self.lineImageView.hidden = btn.selected;
    btn.selected = !btn.selected;
    self.msgDetail.expand=btn.selected;
    
    if ([self.delegate respondsToSelector:@selector(messageHeaderView:)]) {
        [self.delegate messageHeaderView:self];
    }
}
- (void)tapGes:(UITapGestureRecognizer *)tap
{
    
    self.expandBtn.selected = !self.expandBtn.selected;
    self.lineImageView.hidden = self.expandBtn.selected;
    self.msgDetail.expand=self.expandBtn.selected;
    if ([self.delegate respondsToSelector:@selector(messageHeaderView:)]) {
        [self.delegate messageHeaderView:self];
    }
}

@end
