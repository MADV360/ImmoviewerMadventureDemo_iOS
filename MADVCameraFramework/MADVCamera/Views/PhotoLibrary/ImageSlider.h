//
//  ImageSlider.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/7.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MVMedia.h"

@class ImageSlider;

@protocol ImageSliderDelegate <NSObject>

- (void)imageSliderProgressDidChange:(ImageSlider *)imageSlider;
- (void)imageSlider:(ImageSlider *)imageSlider leftValue:(float)leftValue;
- (void)imageSlider:(ImageSlider *)imageSlider rightValue:(float)rightValue;
- (void)imageSliderProgressValueChange:(ImageSlider *)imageSlider;
- (void)imageSliderProgressBeginChange:(ImageSlider *)imageSlider;
@end

@interface ImageSlider : UIView
@property(nonatomic,weak)id<ImageSliderDelegate> delegate;
@property(nonatomic,strong)MVMedia * media;
@property(nonatomic,assign)float value;
@property(nonatomic,assign)float leftValue;
@property(nonatomic,assign)float rightValue;
- (void)loadImageSlider;
- (void) stopGettingThumbnails;
@end
