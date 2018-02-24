//
//  SelectNetView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/22.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SelectNetView;

@protocol SelectNetViewDelegate <NSObject>

- (void)selectNetViewSelected:(SelectNetView *)selectNetView;

@end

@interface SelectNetView : UIView

@property(nonatomic,weak)id<SelectNetViewDelegate> delegate;

- (void)loadSelectNetView;
@end
