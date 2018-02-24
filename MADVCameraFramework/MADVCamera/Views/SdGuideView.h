//
//  SdGuideView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/3/20.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SdGuideView;
@protocol SdGuideViewDelegate <NSObject>

- (void)sdGuideViewDidClose:(SdGuideView *)sdGuideView;

@end

@interface SdGuideView : UIView
@property(nonatomic,weak)id<SdGuideViewDelegate> delegate;
- (void)loadSdGuideView;
@end
