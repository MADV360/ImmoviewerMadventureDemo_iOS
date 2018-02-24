//
//  DivisionButtonView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/8/17.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DivisionButtonView;

@protocol DivisionButtonViewDelegate <NSObject>

- (void)divisionButtonViewClick:(DivisionButtonView *)divisionButtonView index:(int)index;

@end

@interface DivisionButtonView : UIView
@property(nonatomic,weak)id<DivisionButtonViewDelegate> delegate;
@property(nonatomic,strong)NSArray * imageArray;
@property(nonatomic,strong)NSArray * nameArray;
- (void)loadDivisionButtonView;
- (void)setImageIndex:(int)index imageName:(NSString *)imageName;
- (void)setNameIndex:(int)index name:(NSString *)name;

@end
