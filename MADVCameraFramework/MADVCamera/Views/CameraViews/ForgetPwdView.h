//
//  ForgetPwdView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/23.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ForgetPwdView;
@protocol ForgetPwdViewDelegate <NSObject>

- (void)forgetPwdViewConnect:(ForgetPwdView *)forgetPwdView;

@end

@interface ForgetPwdView : UIView
@property(nonatomic,weak)id<ForgetPwdViewDelegate> delegate;
- (void)loadForgetPwdView;
@end
