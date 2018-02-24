//
//  UIImage+LXColor.m
//  DasBank
//
//  Created by 张巧隔 on 16/5/5.
//  Copyright © 2016年 LXWT. All rights reserved.
//

#import "UIImage+LXColor.h"

@implementation UIImage (LXColor)
+ (UIImage*) createImageWithColor: (UIColor*) color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage*theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    return theImage;
}

@end
