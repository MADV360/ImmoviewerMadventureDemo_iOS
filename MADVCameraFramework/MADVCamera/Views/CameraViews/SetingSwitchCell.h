//
//  SetingSwitchCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/7/11.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SetingSwitchCell;

@protocol SetingSwitchCellDelegate <NSObject>

- (void)setingSwitchCell:(SetingSwitchCell *)setingSwitchCell switchValueChange:(BOOL)on;

@end

@interface SetingSwitchCell : UITableViewCell
@property(nonatomic,weak)id<SetingSwitchCellDelegate> delegate;
@property(nonatomic,weak)UILabel * descLabel;
- (void)setOpenSwitchValue:(BOOL)on;
- (BOOL)getOpenSwitchValue;
@end
