//
//  PlayerMore.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerMoreCell.h"
@class PlayerMoreView;
@protocol PlayerMoreViewDelegate <NSObject>

- (void)playerMoreView:(PlayerMoreView *)playerMoreView playerMoreModel:(PlayerMoreModel *)playerMoreModel switchOn:(BOOL)on index:(NSInteger)index;

@end

@interface PlayerMoreView : UIView
@property(nonatomic,weak)id<PlayerMoreViewDelegate> delegate;
@property(nonatomic,strong)NSArray * dataSource;
@property(nonatomic,weak)UIView * lineView;
@property(nonatomic,assign)BOOL bounces;
- (void)loadPlayerMoreView;
- (void)refresh;

@end
