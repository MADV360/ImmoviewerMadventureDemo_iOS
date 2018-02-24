//
//  EditMusicView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "EditMusicView.h"
#import "Masonry.h"
@implementation EditMusicView
- (void)loadEditMusicView
{
    UIView * topLineView = [[UIView alloc] init];
    [self addSubview:topLineView];
    [topLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@1);
    }];
    topLineView.backgroundColor = [UIColor colorWithHexString:@"#FFFFFF" alpha:0.2];
    
    UIImageView * voiceImageView = [[UIImageView alloc] init];
    [self addSubview:voiceImageView];
    [voiceImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@16);
        make.left.equalTo(@20);
        make.width.equalTo(@15);
        make.height.equalTo(@22);
    }];
    voiceImageView.image = [UIImage imageNamed:@"src_volume_add.png"];
    self.voiceImageView = voiceImageView;
    
    UIView * lineView = [[UIView alloc] init];
    [self addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(voiceImageView.mas_top);
        make.bottom.equalTo(@-15);
        make.right.equalTo(@-70);
        make.width.equalTo(@1);
    }];
    lineView.backgroundColor = [UIColor colorWithHexString:@"#FFFFFF" alpha:0.2];
    
    UISlider * voiceSlider = [[UISlider alloc] init];
    [self addSubview:voiceSlider];
    [voiceSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@55);
        make.right.equalTo(lineView.mas_left).offset(-10);
        make.top.equalTo(voiceImageView.mas_top);
        make.bottom.equalTo(voiceImageView.mas_bottom);
    }];
    UIImage* sliderThumbImage = [UIImage imageNamed:@"progress bar3.png"];
    //注意这里要加UIControlStateHightlighted的状态，否则当拖动滑块时滑块将变成原生的控件
    [voiceSlider setThumbImage:sliderThumbImage forState:UIControlStateNormal];
    [voiceSlider setThumbImage:sliderThumbImage forState:UIControlStateHighlighted];
    
    [voiceSlider setMaximumTrackTintColor:[UIColor colorWithHexString:@"#FFFFFF" alpha:0.25]];
    [voiceSlider setMinimumTrackTintColor:[UIColor colorWithRed:0.01f green:0.59f blue:0.89f alpha:1.00f]];
    voiceSlider.continuous=NO;
    voiceSlider.value = 0.5;
    [voiceSlider addTarget:self
                        action:@selector(progressDidChange:)
              forControlEvents:UIControlEventValueChanged];
    voiceSlider.userInteractionEnabled = NO;
    self.voiceSlider = voiceSlider;
    
    UIImageView * musicImageView = [[UIImageView alloc] init];
    [self addSubview:musicImageView];
    [musicImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(voiceImageView.mas_left);
        make.bottom.equalTo(lineView.mas_bottom);
        make.width.equalTo(@15);
        make.height.equalTo(@22);
    }];
    musicImageView.image = [UIImage imageNamed:@"music_volume_reduce.png"];
    self.musicImageView = musicImageView;
    
    UISlider * musicSlider = [[UISlider alloc] init];
    [self addSubview:musicSlider];
    [musicSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@55);
        make.right.equalTo(lineView.mas_left).offset(-10);
        make.top.equalTo(musicImageView.mas_top);
        make.bottom.equalTo(musicImageView.mas_bottom);
    }];
    //注意这里要加UIControlStateHightlighted的状态，否则当拖动滑块时滑块将变成原生的控件
    [musicSlider setThumbImage:sliderThumbImage forState:UIControlStateNormal];
    [musicSlider setThumbImage:sliderThumbImage forState:UIControlStateHighlighted];
    
    [musicSlider setMaximumTrackTintColor:[UIColor colorWithHexString:@"#FFFFFF" alpha:0.25]];
    [musicSlider setMinimumTrackTintColor:[UIColor colorWithRed:0.01f green:0.59f blue:0.89f alpha:1.00f]];
    musicSlider.continuous=NO;
    musicSlider.value = 0;
    [musicSlider addTarget:self
                        action:@selector(progressDidChange:)
              forControlEvents:UIControlEventValueChanged];
    musicSlider.userInteractionEnabled = NO;
    self.musicSlider = musicSlider;
    
    UIImageView * switchImageView = [[UIImageView alloc] init];
    [self addSubview:switchImageView];
    [switchImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@-26);
        make.centerY.equalTo(self.mas_centerY).offset(-10);
        make.width.equalTo(@18);
        make.height.equalTo(@18);
    }];
    switchImageView.image = [UIImage imageNamed:@"icon_switch.png"];
    
    UILabel * addLabel = [[UILabel alloc] init];
    [self addSubview:addLabel];
    [addLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(switchImageView.mas_bottom).offset(10);
        make.centerX.equalTo(switchImageView.mas_centerX);
        make.width.equalTo(@70);
        make.height.equalTo(@13);
    }];
    addLabel.textColor = [UIColor colorWithHexString:@"#FFFFFF" alpha:0.7];
    addLabel.textAlignment = NSTextAlignmentCenter;
    addLabel.font = [UIFont systemFontOfSize:10];
    addLabel.text = FGGetStringWithKeyFromTable(ADDMUSIC, nil);
    self.addLabel = addLabel;
    
    UIView * switchView = [[UIView alloc] init];
    [self addSubview:switchView];
    [switchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lineView.mas_top);
        make.bottom.equalTo(lineView.mas_bottom);
        make.left.equalTo(lineView.mas_right);
        make.right.equalTo(@0);
    }];
    switchView.backgroundColor = [UIColor clearColor];
    
    UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] init];
    [tapGes addTarget:self action:@selector(tapGes:)];
    [switchView addGestureRecognizer:tapGes];
    
    
}

- (void)tapGes:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(editMusicViewAddMusic:)]) {
        [self.delegate editMusicViewAddMusic:self];
    }
}

- (void)progressDidChange:(UISlider *)slider
{
    if (slider == self.voiceSlider) {
        if (slider.value ==0) {
            self.voiceImageView.image = [UIImage imageNamed:@"icon_mute.png"];
        }else
        {
            self.voiceImageView.image = [UIImage imageNamed:@"src_volume_add.png"];
        }
        if ([self.delegate respondsToSelector:@selector(editMusicViewSliderValueChange:isMusicVoice:)]) {
            [self.delegate editMusicViewSliderValueChange:self isMusicVoice:NO];
        }
    }else
    {
        if (slider.value == 0) {
            self.musicImageView.image = [UIImage imageNamed:@"music_volume_reduce.png"];
        }else
        {
            self.musicImageView.image = [UIImage imageNamed:@"icon_music.png"];
        }
        if ([self.delegate respondsToSelector:@selector(editMusicViewSliderValueChange:isMusicVoice:)]) {
            [self.delegate editMusicViewSliderValueChange:self isMusicVoice:YES];
        }
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
