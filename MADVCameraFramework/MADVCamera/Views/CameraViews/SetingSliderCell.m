//
//  SetingSliderCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/31.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "SetingSliderCell.h"
#import "Masonry.h"
#import "UISlider+touch.h"

@interface SetingSliderCell()

@end

@implementation SetingSliderCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self =[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UILabel * titleLabel=[[UILabel alloc] init];
        [self.contentView addSubview:titleLabel];
        CGFloat leftFloat;
        if (ScreenWidth > 375) {
            leftFloat = 20.0f;
        }else
        {
            leftFloat = 15.0f;
        }
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@20);
            make.left.equalTo(@(leftFloat));
            make.width.equalTo(@250);
            make.height.equalTo(@17);
        }];
        titleLabel.font=[UIFont systemFontOfSize:14];
        self.titleLabel=titleLabel;
        
        UILabel * rightLabel=[[UILabel alloc] init];
        [self.contentView addSubview:rightLabel];
        [rightLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(titleLabel.mas_bottom);
            make.right.equalTo(@-15);
            make.width.equalTo(@25);
            make.height.equalTo(@17);
        }];
        rightLabel.font=[UIFont systemFontOfSize:13];
        rightLabel.textAlignment=NSTextAlignmentRight;
        rightLabel.textColor=[UIColor colorWithHexString:@"#8E8E93"];
        self.rightLabel=rightLabel;
        
        UISlider * slider=[[UISlider alloc] init];
        [self.contentView addSubview:slider];
        [slider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(titleLabel.mas_bottom).offset(3);
            make.left.equalTo(@(leftFloat));
            make.right.equalTo(@-15);
            make.height.equalTo(@20);
        }];
        slider.minimumValue=0;
        slider.continuous=NO;
        [slider setThumbImage:[UIImage imageNamed:@"blue_circle.png"] forState:UIControlStateNormal];
        [slider setMinimumTrackTintColor:[UIColor colorWithRed:0.01f green:0.57f blue:0.86f alpha:1.00f]];
        [slider addTapGestureWithTarget:self action:@selector(sliderClick:)];
        [slider addTarget:self action:@selector(sliderClick:) forControlEvents:UIControlEventValueChanged];
        [slider addTarget:self action:@selector(sliderClick:) forControlEvents:UIControlEventTouchUpInside];
        self.slider=slider;
        
        
    }
    return self;
}


- (void)sliderClick:(UISlider *)slider
{
    slider.value=(int)round(slider.value);
    SettingTreeNode * paramNode=self.optionNode.subOptions[(int)slider.value];
    if (self.optionNode.selectedSubOptionUID!=paramNode.uid) {
        if ([self.delegate respondsToSelector:@selector(setingSliderCell:clickOptionNode:paramNode:befSliderValue:)]) {
            
            [self.delegate setingSliderCell:self clickOptionNode:self.optionNode paramNode:paramNode befSliderValue:self.befSliderValue];
            self.befSliderValue=slider.value;
        }
//        self.optionNode.selectedSubOptionUID=paramNode.uid;
    }
    
}

- (void)setOptionNode:(SettingTreeNode *)optionNode
{
    _optionNode=optionNode;
    self.slider.maximumValue=optionNode.subOptions.count-1;
    int j=-1;
    for(int i=0;i<optionNode.subOptions.count;i++)
    {
        SettingTreeNode * paramNode=optionNode.subOptions[i];
        if (optionNode.selectedSubOptionUID==paramNode.uid) {
            j=i;
            break;
        }
    }
    self.slider.value=j;
    self.befSliderValue=self.slider.value;
    
}
- (void)setSliderUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    self.slider.userInteractionEnabled = userInteractionEnabled;
    if (userInteractionEnabled) {
        [self.slider setThumbImage:[UIImage imageNamed:@"blue_circle.png"] forState:UIControlStateNormal];
    }else
    {
        [self.slider setThumbImage:[UIImage imageNamed:@"gray_circle.png"] forState:UIControlStateNormal];
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
