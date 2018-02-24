//
//  MVAlertView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/18.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MVAlertView;

@protocol MVAlertViewDelegate <NSObject>

- (void)mvAlertViewClick:(MVAlertView *)mvAlertView index:(NSInteger)index;

- (void)mvAlertViewDetail:(MVAlertView *)mvAlertView;

@end

@interface MVAlertView : UIView
@property(nonatomic,weak)id<MVAlertViewDelegate> delegate;
-(void)loadWithTitle:(NSString *)title message:(NSString *)message delegate:(id<MVAlertViewDelegate>)delegate otherButtonTitles:(NSArray *)otherButtonTitles;
@end
