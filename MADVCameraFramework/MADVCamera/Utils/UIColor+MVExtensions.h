//
//  UIColor+MVExtensions.h
//  Madv360_v1
//
//  Created by QiuDong on 16/4/11.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (MVExtensions)

+ (UIColor*) olorWithHexString:(int)rgba;

//从十六进制字符串获取颜色，
//color:支持@“#123456”、 @“0X123456”、 @“123456”三种格式
+ (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha;

+ (UIColor *)colorWithHexString:(NSString *)color;

@end
