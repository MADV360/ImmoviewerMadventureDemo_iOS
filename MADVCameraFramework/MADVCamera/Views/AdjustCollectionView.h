//
//  AdjustCollectionView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/12/21.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdjustCameraModel.h"
typedef enum : NSInteger {
    TopPicture_BottomWord = 0,
    TopBottomWord = 1,
    CircleWord = 2,
    Picture = 3,
} AdjustType;

@class AdjustCollectionView;

@protocol AdjustCollectionViewDelegate <NSObject>

- (void)adjustCollectionView:(AdjustCollectionView *)adjustCollectionView click:(AdjustCameraModel *)adjustCameraModel index:(NSInteger)index;

@end

@interface AdjustCollectionView : UIView
@property(nonatomic,strong)NSArray * dataSource;
@property(nonatomic,assign)AdjustType adjustType;
@property(nonatomic,weak)id<AdjustCollectionViewDelegate> delegate;
- (void)loadAdjustCollectionView;
- (void)refresh;
@end
