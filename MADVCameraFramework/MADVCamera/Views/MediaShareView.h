//
//  MediaShareView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/7/7.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MediaShareView;

@protocol MediaShareViewDelegate <NSObject>

- (void)mediaShareViewDidClick:(MediaShareView *)mediaShareView andIndex:(NSInteger)index;

- (void)mediaShareViewQuit:(MediaShareView *) mediaShareView;

@end

@interface MediaShareView : UIView
@property(nonatomic,weak)id<MediaShareViewDelegate> delegate;
- (void)show;
@end
