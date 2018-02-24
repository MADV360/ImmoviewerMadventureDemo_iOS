//
//  ShareView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/6/27.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ShareView;
@protocol ShareViewDelegate <NSObject>

- (void)shareViewDidQuit:(ShareView *)shareView;
- (void)shareViewDidClick:(ShareView *)shareView andIndex:(NSInteger)index;
@end

@interface ShareView : UIView
@property(nonatomic,strong)NSArray * dataArr;
@property(nonatomic,strong)NSArray * selectDataArr;
@property(nonatomic,strong)NSArray * nameDataArr;
@property(nonatomic,strong)NSArray * indexArr;
@property(nonatomic,weak)id<ShareViewDelegate> delegate;

- (void)loadShareView;
- (void)show;
@end
