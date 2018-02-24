//
//  SetingSliderCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/31.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingTreeNode.h"
@class SetingSliderCell;
@protocol SetingSliderCellDelegate <NSObject>

- (void)setingSliderCell:(SetingSliderCell *)setingSliderCell clickOptionNode:(SettingTreeNode *)optionNode paramNode:(SettingTreeNode *)paramNode befSliderValue:(float)befSliderValue;

@end

@interface SetingSliderCell : UITableViewCell
@property(nonatomic,weak)UILabel * titleLabel;
@property(nonatomic,weak)UILabel * rightLabel;
@property(nonatomic,strong)SettingTreeNode * optionNode;
@property(nonatomic,weak)UISlider * slider;
@property(nonatomic,assign)float befSliderValue;
@property(nonatomic,weak)id<SetingSliderCellDelegate> delegate;

- (void)setSliderUserInteractionEnabled:(BOOL)userInteractionEnabled;

@end
