//
//  GuideView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/28.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GuideView;
@protocol GuideViewDelegate <NSObject>

- (void)guideViewGoto:(GuideView *)guideView;

@end

@interface GuideView : UIView
@property(nonatomic,weak)id<GuideViewDelegate> delegate;
- (void)loadGuideView;
@end
