//
//  SubAdjustCellView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/12/22.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdjustCameraModel.h"
#import "AdjustCollectionView.h"

@class SubAdjustCellView;

@protocol SubAdjustCellViewDelegate <NSObject>

- (void)subAdjustCellView:(SubAdjustCellView *)subAdjustCellView click:(AdjustCameraModel *)adjustCameraModel;

- (void)subAdjustCellViewClose:(SubAdjustCellView *)subAdjustCellView;

@end

@interface SubAdjustCellView : UIView
@property(nonatomic,strong)NSArray * dataSource;
@property(nonatomic,strong)AdjustCameraModel * adjustCameraModel;
@property(nonatomic,assign)AdjustType adjustType;
@property(nonatomic,weak)id<SubAdjustCellViewDelegate> delegate;
- (void)loadSubAdjustCellView;
- (void)refresh;
@end
