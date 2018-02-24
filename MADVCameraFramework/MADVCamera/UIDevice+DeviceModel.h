//
//  UIDevice+DeviceModel.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/11.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (DeviceModel)
+ (BOOL)isIphone5Series;
+ (BOOL)isNon4KModel;
+ (BOOL)isDeviceNon4KModel;
+ (NSString *)getIphoneInfo;
+ (BOOL)is6Above;
@end
