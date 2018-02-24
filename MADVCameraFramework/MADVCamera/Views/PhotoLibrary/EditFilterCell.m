//
//  EditFilterCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "EditFilterCell.h"
#import "Masonry.h"
@implementation EditFilterCell
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        UIImageView * filterImageview = [[UIImageView alloc] init];
        [self.contentView addSubview:filterImageview];
        [filterImageview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.top.equalTo(@10);
            make.width.equalTo(@48);
            make.height.equalTo(@48);
        }];
        filterImageview.layer.masksToBounds = YES;
        filterImageview.layer.cornerRadius = 24;
        filterImageview.layer.borderColor = [UIColor clearColor].CGColor;
        filterImageview.layer.borderWidth = 2;
        filterImageview.alpha = 0.5;
        filterImageview.userInteractionEnabled = YES;
        self.filterImageview = filterImageview;
        
        UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] init];
        [tapGes addTarget:self action:@selector(tapGes:)];
        [filterImageview addGestureRecognizer:tapGes];
        
        UILabel * titleLabel = [[UILabel alloc] init];
        [self.contentView addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(filterImageview.mas_bottom).offset(8);
            make.left.equalTo(@2);
            make.right.equalTo(@-2);
            make.height.equalTo(@12);
        }];
        titleLabel.font = [UIFont systemFontOfSize:11];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.alpha = 0.5;
        self.titleLabel = titleLabel;
        
    }
    return self;
}

- (void)tapGes:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(editFilterCellClick:)]) {
        [self.delegate editFilterCellClick:self];
    }
}
@end
