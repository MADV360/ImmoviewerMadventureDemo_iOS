//
//  SelectSexView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/18.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SelectSexView;
@protocol SelectSexViewDelegate <NSObject>
//sex 1男2女
- (void)selectSexView:(SelectSexView *)selectSexView sex:(NSString *)sex;

@end

@interface SelectSexView : UIView
@property(nonatomic,weak)id<SelectSexViewDelegate> delegate;
- (void)loadSelectSexView;
- (void)selectSex:(NSString *)sex;
@end
