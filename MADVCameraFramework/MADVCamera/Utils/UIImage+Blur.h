//
//  UIImage+Blur.h
//  拉scrolview改变图片的大小
//
//  Created by 张巧隔 on 16/6/16.
//  Copyright © 2016年 MS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Blur)
//isNet表示是否是网上的图片
+(UIImage *)boxblurImage:(UIImage *)image withBlurNumber:(CGFloat)blur andIsNet:(BOOL)isNet;
+(UIImage *)coreBlurImage:(UIImage *)image withBlurNumber:(CGFloat)blur;
//生成缩略图
+(UIImage *)getVideoImage:(NSString *)videoURL time:(float)time;
@end
