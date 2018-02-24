//
//  AvPlayScrollView.h
//  video
//
//  Created by 张巧隔 on 17/3/18.
//  Copyright © 2017年 张巧隔. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayScrollModel.h"
@class AvPlayScrollView;
@protocol AvPlayScrollViewDelegate <NSObject>

- (void)avPlayScrollViewKnowClick:(AvPlayScrollView *)avPlayScrollView;

@end

@interface AvPlayScrollView : UIView
@property(nonatomic,weak)id<AvPlayScrollViewDelegate> delegate;
@property(nonatomic,strong)NSArray * dataSource;
@property(nonatomic,strong)NSMutableArray * playerArr;
@end
