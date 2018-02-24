//
//  EditProgressView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "EditProgressView.h"
#import "Masonry.h"

@implementation EditProgressView
- (void)loadEditProgressView
{
    UILabel * startLabel = [[UILabel alloc] init];
    [self addSubview:startLabel];
    [startLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@15);
        make.centerY.equalTo(self.mas_centerY);
        make.height.equalTo(@10);
        make.width.equalTo(@30);
    }];
    startLabel.font = [UIFont systemFontOfSize:9];
    startLabel.textColor = [UIColor colorWithHexString:@"#FFFFFF" alpha:0.7];
    startLabel.text = @"00:00";
    
    UILabel * durationLabel = [[UILabel alloc] init];
    [self addSubview:durationLabel];
    [durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@-15);
        make.centerY.equalTo(self.mas_centerY);
        make.height.equalTo(@10);
        make.width.equalTo(@30);
    }];
    durationLabel.font = [UIFont systemFontOfSize:9];
    durationLabel.textColor = [UIColor colorWithHexString:@"#FFFFFF" alpha:0.7];
    durationLabel.textAlignment = NSTextAlignmentRight;
    self.durationLabel = durationLabel;
    
    UISlider * progressSlider = [[UISlider alloc] init];
    [self addSubview:progressSlider];
    [progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.left.equalTo(startLabel.mas_right).offset(10);
        make.right.equalTo(durationLabel.mas_left).offset(-10);
        make.height.equalTo(@30);
    }];
    UIImage* sliderThumbImage = [UIImage imageNamed:@"progress bar3.png"];
    //注意这里要加UIControlStateHightlighted的状态，否则当拖动滑块时滑块将变成原生的控件
    [progressSlider setThumbImage:sliderThumbImage forState:UIControlStateNormal];
    [progressSlider setThumbImage:sliderThumbImage forState:UIControlStateHighlighted];
    
    [progressSlider setMaximumTrackTintColor:[UIColor colorWithHexString:@"#FFFFFF" alpha:0.25]];
    [progressSlider setMinimumTrackTintColor:[UIColor colorWithRed:0.01f green:0.59f blue:0.89f alpha:1.00f]];
    progressSlider.continuous=NO;
    self.progressSlider = progressSlider;
    
    
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
