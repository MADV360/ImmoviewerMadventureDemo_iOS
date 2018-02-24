//
//  LXInfoView.h
//  DasBank
//
//  Created by 张巧隔 on 16/3/31.
//  Copyright © 2016年 LXWT. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LXInfoView;
@protocol LXInfoViewDelegate <NSObject>

- (void)infoViewDidTouch:(LXInfoView *)infoView andIndex:(NSInteger)index;

@end

@interface LXInfoView : UIView
@property(nonatomic,weak)id<LXInfoViewDelegate> delegate;
@property(nonatomic,strong)NSArray * infoArr;
- (void)loadInfoView;
@end
