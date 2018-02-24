//
//  MineHeadView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/6/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MineHeadView;
@protocol MineHeadViewDelegate <NSObject>

//返回事件
- (void)mineHeadViewBack:(MineHeadView *)mineHeadView;

- (void)mineHeadViewInfo:(MineHeadView *)mineHeadView;

//点击分享 发布 喜欢
- (void)mineHeadViewInfoDidTouch:(MineHeadView *)mineHeadView andIndex:(NSInteger)index;

@end

@interface MineHeadView : UIView
@property(nonatomic,weak)UIImageView * imageView;
@property(nonatomic,weak)id<MineHeadViewDelegate> delegate;
- (void)loadHeadView;
- (void)setInfoWithIsLogin:(BOOL)isLogin andHeadImage:(NSString *)headUrl andInfoArr:(NSArray *)infoArr andName:(NSString *)name level:(NSString *)level;
- (void)updateFrameWithOffsety:(CGFloat)y;
@end
