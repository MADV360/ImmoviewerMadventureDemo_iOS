//
//  ImageTitleView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/5/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageTitleView;

@protocol ImageTitleViewDelegate <NSObject>

- (void)imageTitleViewClick:(ImageTitleView *)imageTitleView loginIndex:(NSInteger)loginIndex;

@end

@interface ImageTitleView : UIView
@property(nonatomic,weak)id<ImageTitleViewDelegate> delegate;
@property(nonatomic,copy)NSString * imageName;
@property(nonatomic,copy)NSString * title;
@property(nonatomic,assign)NSInteger loginIndex;
- (void)loadImageTitleView;
@end
