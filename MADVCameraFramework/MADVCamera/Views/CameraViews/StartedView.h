//
//  StartedView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/19.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StartedView;
@protocol StartedViewDelegate <NSObject>

- (void)startedViewStarted:(StartedView *)startedView;

@end

@interface StartedView : UIView
@property(nonatomic,weak)id<StartedViewDelegate> delegate;
- (void)loadStartedView;
@end
