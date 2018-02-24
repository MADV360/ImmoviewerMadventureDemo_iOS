//
//  ImageTitleView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/5/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "ImageTitleView.h"
#import "Masonry.h"
@implementation ImageTitleView
- (void)loadImageTitleView
{
    UIImageView * imageView = [[UIImageView alloc] init];
    [self addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.centerX.equalTo(self.mas_centerX);
        make.width.equalTo(@40);
        make.height.equalTo(@40);
    }];
    imageView.image = [UIImage imageNamed:self.imageName];
    imageView.userInteractionEnabled = NO;
    
    UILabel * titleLabel = [[UILabel alloc] init];
    [self addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imageView.mas_bottom).offset(10);
        make.height.equalTo(@15);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
    }];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:12];
    titleLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
    titleLabel.text = self.title;
    titleLabel.userInteractionEnabled = NO;
    
    UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] init];
    [tapGes addTarget:self action:@selector(tapGes:)];
    [self addGestureRecognizer:tapGes];
}
- (void)tapGes:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(imageTitleViewClick:loginIndex:)]) {
        [self.delegate imageTitleViewClick:self loginIndex:self.loginIndex];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
