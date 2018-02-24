//
//  SubAdjustPickerView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/12/26.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdjustCameraModel.h"
#import "CustomPickerView.h"

@class SubAdjustPickerView;

@protocol SubAdjustPickerViewDelegate <NSObject>

- (void)subAdjustPickerViewClose:(SubAdjustPickerView *)subAdjustPickerView;
- (void)subAdjustPickerView:(SubAdjustPickerView *)subAdjustPickerView click:(AdjustCameraModel *)adjustCameraModel error:(int)error;

@end

@interface SubAdjustPickerView : UIView
@property(nonatomic,strong)NSArray * dataSource;
@property(nonatomic,strong)AdjustCameraModel * adjustCameraModel;
@property(nonatomic,assign)PickerType pickerType;
@property(nonatomic,weak)id<SubAdjustPickerViewDelegate> delegate;
@property(nonatomic,assign)NSInteger scrollToIndex;
@property(nonatomic,assign)BOOL isEnabled;
- (void)loadSubAdjustPickerView;
- (void)refresh;
@end
