//
//  LoginModeScrollView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/5/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoginModeScrollView;

@protocol LoginModeScrollViewDelegate <NSObject>

- (void)loginModeScrollViewClick:(LoginModeScrollView *)loginModeScrollView loginIndex:(NSInteger)loginIndex;

@end

@interface LoginModeScrollView : UIView

@property(nonatomic,weak)id<LoginModeScrollViewDelegate> delegate;
- (void)loadLoginModeScrollView;
@end
