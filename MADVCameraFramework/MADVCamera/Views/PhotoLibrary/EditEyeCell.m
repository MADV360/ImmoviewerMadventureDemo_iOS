//
//  EditEyeCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "EditEyeCell.h"
#import "Masonry.h"
@implementation EditEyeCell
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        UIImageView * editImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:editImageView];
        [editImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.centerY.equalTo(self.contentView.mas_centerY).offset(-10);
            make.width.equalTo(@20);
            make.height.equalTo(@20);
        }];
        self.editImageView = editImageView;
        
        UILabel * titleLabel = [[UILabel alloc] init];
        [self.contentView addSubview:titleLabel];
        titleLabel.frame = CGRectMake(5, self.contentView.frame.size.height * 0.5 + 10, self.contentView.frame.size.width - 10, 12);
        titleLabel.numberOfLines = 0;
        
//        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(editImageView.mas_bottom).offset(10);
//            make.left.equalTo(@5);
//            make.right.equalTo(@-5);
//            make.height.equalTo(@12);
//        }];
        titleLabel.font = [UIFont systemFontOfSize:11];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        
        self.titleLabel = titleLabel;
        
        UIView * lineView = [[UIView alloc] init];
        [self.contentView addSubview:lineView];
        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(@0);
            make.bottom.equalTo(@0);
            make.width.equalTo(@1);
        }];
        lineView.backgroundColor= [UIColor colorWithHexString:@"#FFFFFF" alpha:0.2];
        self.lineView = lineView;
        
        UIView * backView = [[UIView alloc] init];
        [self.contentView addSubview:backView];
        [backView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
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
    if ([self.delegate respondsToSelector:@selector(editEyeCellClick:)]) {
        [self.delegate editEyeCellClick:self];
    }
}
@end
