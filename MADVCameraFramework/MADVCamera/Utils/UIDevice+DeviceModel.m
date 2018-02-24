//
//  UIDevice+DeviceModel.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/11.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "UIDevice+DeviceModel.h"
#import <sys/utsname.h>
#import "helper.h"

/*
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0)
#define IS_IPHONE_6PLUS (IS_IPHONE && [[UIScreen mainScreen] nativeScale] == 3.0f)
#define IS_IPHONE_6_PLUS (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 736.0)
#define IS_RETINA ([[UIScreen mainScreen] scale] == 2.0)
*/
@implementation UIDevice (DeviceModel)
+(BOOL)isIphone5Series
{
    if ([UIScreen mainScreen].bounds.size.height == 568) {
        return YES;
    }
    return NO;
}
/*+(BOOL)isNon4KModel
{
    NSString * isReference = [helper readProfileString:ISREFERENCEENCODEABILITY];
    if ([isReference isEqualToString:@"1"]) {
        struct utsname systemInfo;
        uname(&systemInfo);
        
        NSString* deviceModel = [NSString stringWithCString:systemInfo.machine
                                                   encoding:NSUTF8StringEncoding];
        
        if ([deviceModel isEqualToString:@"iPod5,1"] ||                                 //return "iPod Touch 5"
            [deviceModel isEqualToString:@"iPod7,1"] ||                                 //return "iPod Touch 6"
            [deviceModel isEqualToString:@"iPhone3,1"] ||
            [deviceModel isEqualToString:@"iPhone3,2"] ||
            [deviceModel isEqualToString:@"iPhone3,3"] ||                               //return "iPhone 4"
            [deviceModel isEqualToString:@"iPhone4,1"] ||                               //return "iPhone 4s"
            [deviceModel isEqualToString:@"iPhone5,1"] ||
            [deviceModel isEqualToString:@"iPhone5,2"] ||                               //return "iPhone 5"
            [deviceModel isEqualToString:@"iPhone5,3"] ||
            [deviceModel isEqualToString:@"iPhone5,4"] ||                               //return "iPhone 5c"
            [deviceModel isEqualToString:@"iPhone6,1"] ||
            [deviceModel isEqualToString:@"iPhone6,2"] ||                               //return "iPhone 5s"
            [deviceModel isEqualToString:@"iPhone7,2"] ||                               //return "iPhone 6"
            [deviceModel isEqualToString:@"iPhone7,1"] ||                               //return "iPhone 6 Plus"
            //        [deviceModel isEqualToString:@"iPhone8,1"] ||                               //return "iPhone 6s"
            //        [deviceModel isEqualToString:@"iPhone8,2"] ||                               //return "iPhone 6s Plus"
            //        [deviceModel isEqualToString:@"iPhone9,1"] ||
            //        [deviceModel isEqualToString:@"iPhone9,3"] ||                               //return "iPhone 7"
            //        [deviceModel isEqualToString:@"iPhone9,2"] ||
            //        [deviceModel isEqualToString:@"iPhone9,4"] ||                               //return "iPhone 7 Plus"
            //        [deviceModel isEqualToString:@"iPhone8,4"] ||                               //return "iPhone SE"
            [deviceModel isEqualToString:@"iPad2,1"] ||
            [deviceModel isEqualToString:@"iPad2,2"] ||
            [deviceModel isEqualToString:@"iPad2,3"] ||
            [deviceModel isEqualToString:@"iPad2,4"] ||                                 //return "iPad 2"
            [deviceModel isEqualToString:@"iPad3,1"] ||
            [deviceModel isEqualToString:@"iPad3,2"] ||
            [deviceModel isEqualToString:@"iPad3,3"] ||                                 //return "iPad 3"
            [deviceModel isEqualToString:@"iPad3,4"] ||
            [deviceModel isEqualToString:@"iPad3,5"] ||
            [deviceModel isEqualToString:@"iPad3,6"] ||                                 //return "iPad 4"
            [deviceModel isEqualToString:@"iPad4,1"] ||
            [deviceModel isEqualToString:@"iPad4,2"] ||
            [deviceModel isEqualToString:@"iPad4,3"] ||                                 //return "iPad Air"
            [deviceModel isEqualToString:@"iPad5,3"] ||
            [deviceModel isEqualToString:@"iPad5,4"] ||                                 //return "iPad Air 2"
            //        [deviceModel isEqualToString:@"iPad6,11"] ||
            //        [deviceModel isEqualToString:@"iPad6,12"] ||                                //return "iPad 5"
            [deviceModel isEqualToString:@"iPad2,5"] ||
            [deviceModel isEqualToString:@"iPad2,6"] ||
            [deviceModel isEqualToString:@"iPad2,7"] ||                                 //return "iPad Mini"
            [deviceModel isEqualToString:@"iPad4,4"] ||
            [deviceModel isEqualToString:@"iPad4,5"] ||
            [deviceModel isEqualToString:@"iPad4,6"] ||                                 //return "iPad Mini 2"
            [deviceModel isEqualToString:@"iPad4,7"] ||
            [deviceModel isEqualToString:@"iPad4,8"] ||
            [deviceModel isEqualToString:@"iPad4,9"] ||                                 //return "iPad Mini 3"
            //        [deviceModel isEqualToString:@"iPad5,1"] ||
            //        [deviceModel isEqualToString] ||@"iPad5,2"] ||                                 //return "iPad Mini 4"
            [deviceModel isEqualToString:@"iPad6,3"] ||
            [deviceModel isEqualToString:@"iPad6,4"] ||                                 //return "iPad Pro 9.7 Inch"
            [deviceModel isEqualToString:@"iPad6,7"] ||
            [deviceModel isEqualToString:@"iPad6,8"] ||                                 //return "iPad Pro 12.9 Inch"
            //        [deviceModel isEqualToString:@"iPad7,1"] ||
            //        [deviceModel isEqualToString:@"iPad7,2"] ||                                 //return "iPad Pro 12.9 Inch 2. Generation"
            //        [deviceModel isEqualToString:@"iPad7,3"] ||
            //        [deviceModel isEqualToString:@"iPad7,4"] ||                                 //return "iPad Pro 10.5 Inch"
            [deviceModel isEqualToString:@"AppleTV5,3"] ||                              //return "Apple TV"
            [deviceModel isEqualToString:@"i386"] ||
            [deviceModel isEqualToString:@"x86_64"]                                   //return "Simulator"
            ) {
            return YES;
        }
        return NO;
    }else
    {
        return NO;
    }
    
}//*/
+ (BOOL)isDeviceNon4KModel
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString* deviceModel = [NSString stringWithCString:systemInfo.machine
                                               encoding:NSUTF8StringEncoding];
    
    if ([deviceModel isEqualToString:@"iPod5,1"] ||                                 //return "iPod Touch 5"
        [deviceModel isEqualToString:@"iPod7,1"] ||                                 //return "iPod Touch 6"
        [deviceModel isEqualToString:@"iPhone3,1"] ||
        [deviceModel isEqualToString:@"iPhone3,2"] ||
        [deviceModel isEqualToString:@"iPhone3,3"] ||                               //return "iPhone 4"
        [deviceModel isEqualToString:@"iPhone4,1"] ||                               //return "iPhone 4s"
        [deviceModel isEqualToString:@"iPhone5,1"] ||
        [deviceModel isEqualToString:@"iPhone5,2"] ||                               //return "iPhone 5"
        [deviceModel isEqualToString:@"iPhone5,3"] ||
        [deviceModel isEqualToString:@"iPhone5,4"] ||                               //return "iPhone 5c"
        [deviceModel isEqualToString:@"iPhone6,1"] ||
        [deviceModel isEqualToString:@"iPhone6,2"] ||                               //return "iPhone 5s"
        [deviceModel isEqualToString:@"iPhone7,2"] ||                               //return "iPhone 6"
        [deviceModel isEqualToString:@"iPhone7,1"] ||                               //return "iPhone 6 Plus"
        //        [deviceModel isEqualToString:@"iPhone8,1"] ||                               //return "iPhone 6s"
        //        [deviceModel isEqualToString:@"iPhone8,2"] ||                               //return "iPhone 6s Plus"
        //        [deviceModel isEqualToString:@"iPhone9,1"] ||
        //        [deviceModel isEqualToString:@"iPhone9,3"] ||                               //return "iPhone 7"
        //        [deviceModel isEqualToString:@"iPhone9,2"] ||
        //        [deviceModel isEqualToString:@"iPhone9,4"] ||                               //return "iPhone 7 Plus"
        //        [deviceModel isEqualToString:@"iPhone8,4"] ||                               //return "iPhone SE"
        [deviceModel isEqualToString:@"iPad2,1"] ||
        [deviceModel isEqualToString:@"iPad2,2"] ||
        [deviceModel isEqualToString:@"iPad2,3"] ||
        [deviceModel isEqualToString:@"iPad2,4"] ||                                 //return "iPad 2"
        [deviceModel isEqualToString:@"iPad3,1"] ||
        [deviceModel isEqualToString:@"iPad3,2"] ||
        [deviceModel isEqualToString:@"iPad3,3"] ||                                 //return "iPad 3"
        [deviceModel isEqualToString:@"iPad3,4"] ||
        [deviceModel isEqualToString:@"iPad3,5"] ||
        [deviceModel isEqualToString:@"iPad3,6"] ||                                 //return "iPad 4"
        [deviceModel isEqualToString:@"iPad4,1"] ||
        [deviceModel isEqualToString:@"iPad4,2"] ||
        [deviceModel isEqualToString:@"iPad4,3"] ||                                 //return "iPad Air"
        [deviceModel isEqualToString:@"iPad5,3"] ||
        [deviceModel isEqualToString:@"iPad5,4"] ||                                 //return "iPad Air 2"
        //        [deviceModel isEqualToString:@"iPad6,11"] ||
        //        [deviceModel isEqualToString:@"iPad6,12"] ||                                //return "iPad 5"
        [deviceModel isEqualToString:@"iPad2,5"] ||
        [deviceModel isEqualToString:@"iPad2,6"] ||
        [deviceModel isEqualToString:@"iPad2,7"] ||                                 //return "iPad Mini"
        [deviceModel isEqualToString:@"iPad4,4"] ||
        [deviceModel isEqualToString:@"iPad4,5"] ||
        [deviceModel isEqualToString:@"iPad4,6"] ||                                 //return "iPad Mini 2"
        [deviceModel isEqualToString:@"iPad4,7"] ||
        [deviceModel isEqualToString:@"iPad4,8"] ||
        [deviceModel isEqualToString:@"iPad4,9"] ||                                 //return "iPad Mini 3"
        //        [deviceModel isEqualToString:@"iPad5,1"] ||
        //        [deviceModel isEqualToString] ||@"iPad5,2"] ||                                 //return "iPad Mini 4"
        [deviceModel isEqualToString:@"iPad6,3"] ||
        [deviceModel isEqualToString:@"iPad6,4"] ||                                 //return "iPad Pro 9.7 Inch"
        [deviceModel isEqualToString:@"iPad6,7"] ||
        [deviceModel isEqualToString:@"iPad6,8"] ||                                 //return "iPad Pro 12.9 Inch"
        //        [deviceModel isEqualToString:@"iPad7,1"] ||
        //        [deviceModel isEqualToString:@"iPad7,2"] ||                                 //return "iPad Pro 12.9 Inch 2. Generation"
        //        [deviceModel isEqualToString:@"iPad7,3"] ||
        //        [deviceModel isEqualToString:@"iPad7,4"] ||                                 //return "iPad Pro 10.5 Inch"
        [deviceModel isEqualToString:@"AppleTV5,3"] ||                              //return "Apple TV"
        [deviceModel isEqualToString:@"i386"] ||
        [deviceModel isEqualToString:@"x86_64"]                                   //return "Simulator"
        ) {
        return YES;
    }
    return NO;
}
+ (NSString *)getIphoneInfo
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString* deviceModel = [NSString stringWithCString:systemInfo.machine
                                               encoding:NSUTF8StringEncoding];
    
    NSString * iphoneInfo = deviceModel;
    
    if ([deviceModel isEqualToString:@"iPod5,1"])
    {
        return [NSString stringWithFormat:@"%@_iPod Touch 5",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPod7,1"])
    {
        return [NSString stringWithFormat:@"%@_iPod Touch 6",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPhone3,1"] || [deviceModel isEqualToString:@"iPhone3,2"] || [deviceModel isEqualToString:@"iPhone3,3"])
    {
        return [NSString stringWithFormat:@"%@_iPhone 4",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPhone4,1"])
    {
        return [NSString stringWithFormat:@"%@_iPhone 4s",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPhone5,1"] || [deviceModel isEqualToString:@"iPhone5,2"])
    {
        return [NSString stringWithFormat:@"%@_iPhone 5",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPhone5,3"] || [deviceModel isEqualToString:@"iPhone5,4"])
    {
        return [NSString stringWithFormat:@"%@_iPhone 5c",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPhone6,1"] || [deviceModel isEqualToString:@"iPhone6,2"])
    {
        return [NSString stringWithFormat:@"%@_iPhone 5s",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPhone7,2"])
    {
        return [NSString stringWithFormat:@"%@_iPhone 6",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPhone7,1"])
    {
        return [NSString stringWithFormat:@"%@_iPhone 6 Plus",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPhone8,1"])
    {
        return [NSString stringWithFormat:@"%@_iPhone 6s",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPhone8,2"])
    {
        return [NSString stringWithFormat:@"%@_iPhone 6s Plus",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPhone9,1"] || [deviceModel isEqualToString:@"iPhone9,3"])
    {
        return [NSString stringWithFormat:@"%@_iPhone 7",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPhone9,2"] || [deviceModel isEqualToString:@"iPhone9,4"])
    {
        return [NSString stringWithFormat:@"%@_iPhone 7 Plus",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPhone8,4"])
    {
        return [NSString stringWithFormat:@"%@_iPhone SE",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad2,1"] || [deviceModel isEqualToString:@"iPad2,2"] ||
        [deviceModel isEqualToString:@"iPad2,3"] || [deviceModel isEqualToString:@"iPad2,4"])
    {
        return [NSString stringWithFormat:@"%@_iPad 2",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad3,1"] ||
        [deviceModel isEqualToString:@"iPad3,2"] ||
        [deviceModel isEqualToString:@"iPad3,3"])
    {
        return [NSString stringWithFormat:@"%@_iPad 3",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad3,4"] ||
        [deviceModel isEqualToString:@"iPad3,5"] ||
        [deviceModel isEqualToString:@"iPad3,6"])
    {
        return [NSString stringWithFormat:@"%@_iPad 4",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad4,1"] ||
        [deviceModel isEqualToString:@"iPad4,2"] ||
        [deviceModel isEqualToString:@"iPad4,3"])
    {
        return [NSString stringWithFormat:@"%@_iPad Air",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad5,3"] ||
        [deviceModel isEqualToString:@"iPad5,4"])
    {
        return [NSString stringWithFormat:@"%@_iPad Air 2",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad6,11"] ||
        [deviceModel isEqualToString:@"iPad6,12"])
    {
        return [NSString stringWithFormat:@"%@_iPad 5",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad2,5"] ||
        [deviceModel isEqualToString:@"iPad2,6"] ||
        [deviceModel isEqualToString:@"iPad2,7"])
    {
        return [NSString stringWithFormat:@"%@_iPad Mini",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad4,4"] ||
        [deviceModel isEqualToString:@"iPad4,5"] ||
        [deviceModel isEqualToString:@"iPad4,6"])
    {
        return [NSString stringWithFormat:@"%@_iPad Mini 2",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad4,7"] ||
        [deviceModel isEqualToString:@"iPad4,8"] ||
        [deviceModel isEqualToString:@"iPad4,9"])
    {
        return [NSString stringWithFormat:@"%@_iPad Mini 3",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad5,1"] ||
        [deviceModel isEqualToString:@"iPad5,2"])
    {
        return [NSString stringWithFormat:@"%@_iPad Mini 4",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad6,3"] ||
        [deviceModel isEqualToString:@"iPad6,4"])
    {
        return [NSString stringWithFormat:@"%@_iPad Pro 9.7 Inch",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad6,7"] ||
        [deviceModel isEqualToString:@"iPad6,8"])
    {
        return [NSString stringWithFormat:@"%@_iPad Pro 12.9 Inch",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad7,1"] ||
        [deviceModel isEqualToString:@"iPad7,2"])
    {
        return [NSString stringWithFormat:@"%@_iPad Pro 12.9 Inch 2. Generation",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"iPad7,3"] ||
        [deviceModel isEqualToString:@"iPad7,4"])
    {
        return [NSString stringWithFormat:@"%@_iPad Pro 10.5 Inch",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"AppleTV5,3"])
    {
        return [NSString stringWithFormat:@"%@_Apple TV",iphoneInfo];
    }
    if ([deviceModel isEqualToString:@"i386"] ||
        [deviceModel isEqualToString:@"x86_64"])
    {
        return [NSString stringWithFormat:@"%@_Simulator",iphoneInfo];
    }
    return @"";
}
+ (BOOL)is6Above
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString* deviceModel = [NSString stringWithCString:systemInfo.machine
                                               encoding:NSUTF8StringEncoding];
    
    if ([deviceModel isEqualToString:@"iPod5,1"] ||                                 //return "iPod Touch 5"
        [deviceModel isEqualToString:@"iPod7,1"] ||                                 //return "iPod Touch 6"
        [deviceModel isEqualToString:@"iPhone3,1"] ||
        [deviceModel isEqualToString:@"iPhone3,2"] ||
        [deviceModel isEqualToString:@"iPhone3,3"] ||                               //return "iPhone 4"
        [deviceModel isEqualToString:@"iPhone4,1"] ||                               //return "iPhone 4s"
        [deviceModel isEqualToString:@"iPhone5,1"] ||
        [deviceModel isEqualToString:@"iPhone5,2"] ||                               //return "iPhone 5"
        [deviceModel isEqualToString:@"iPhone5,3"] ||
        [deviceModel isEqualToString:@"iPhone5,4"] ||                               //return "iPhone 5c"
        [deviceModel isEqualToString:@"iPhone6,1"] ||
        [deviceModel isEqualToString:@"iPhone6,2"] ||                               //return "iPhone 5s"
        [deviceModel isEqualToString:@"iPhone7,2"] ||                               //return "iPhone 6"
        [deviceModel isEqualToString:@"iPhone7,1"] ||                               //return "iPhone 6 Plus"
        //        [deviceModel isEqualToString:@"iPhone8,1"] ||                               //return "iPhone 6s"
        //        [deviceModel isEqualToString:@"iPhone8,2"] ||                               //return "iPhone 6s Plus"
        //        [deviceModel isEqualToString:@"iPhone9,1"] ||
        //        [deviceModel isEqualToString:@"iPhone9,3"] ||                               //return "iPhone 7"
        //        [deviceModel isEqualToString:@"iPhone9,2"] ||
        //        [deviceModel isEqualToString:@"iPhone9,4"] ||                               //return "iPhone 7 Plus"
        //        [deviceModel isEqualToString:@"iPhone8,4"] ||                               //return "iPhone SE"
        [deviceModel isEqualToString:@"iPad2,1"] ||
        [deviceModel isEqualToString:@"iPad2,2"] ||
        [deviceModel isEqualToString:@"iPad2,3"] ||
        [deviceModel isEqualToString:@"iPad2,4"] ||                                 //return "iPad 2"
        [deviceModel isEqualToString:@"iPad3,1"] ||
        [deviceModel isEqualToString:@"iPad3,2"] ||
        [deviceModel isEqualToString:@"iPad3,3"] ||                                 //return "iPad 3"
        [deviceModel isEqualToString:@"iPad3,4"] ||
        [deviceModel isEqualToString:@"iPad3,5"] ||
        [deviceModel isEqualToString:@"iPad3,6"] ||                                 //return "iPad 4"
        [deviceModel isEqualToString:@"iPad4,1"] ||
        [deviceModel isEqualToString:@"iPad4,2"] ||
        [deviceModel isEqualToString:@"iPad4,3"] ||                                 //return "iPad Air"
        [deviceModel isEqualToString:@"iPad5,3"] ||
        [deviceModel isEqualToString:@"iPad5,4"] ||                                 //return "iPad Air 2"
        //        [deviceModel isEqualToString:@"iPad6,11"] ||
        //        [deviceModel isEqualToString:@"iPad6,12"] ||                                //return "iPad 5"
        [deviceModel isEqualToString:@"iPad2,5"] ||
        [deviceModel isEqualToString:@"iPad2,6"] ||
        [deviceModel isEqualToString:@"iPad2,7"] ||                                 //return "iPad Mini"
        [deviceModel isEqualToString:@"iPad4,4"] ||
        [deviceModel isEqualToString:@"iPad4,5"] ||
        [deviceModel isEqualToString:@"iPad4,6"] ||                                 //return "iPad Mini 2"
        [deviceModel isEqualToString:@"iPad4,7"] ||
        [deviceModel isEqualToString:@"iPad4,8"] ||
        [deviceModel isEqualToString:@"iPad4,9"] ||                                 //return "iPad Mini 3"
        //        [deviceModel isEqualToString:@"iPad5,1"] ||
        //        [deviceModel isEqualToString] ||@"iPad5,2"] ||                                 //return "iPad Mini 4"
        [deviceModel isEqualToString:@"iPad6,3"] ||
        [deviceModel isEqualToString:@"iPad6,4"] ||                                 //return "iPad Pro 9.7 Inch"
        [deviceModel isEqualToString:@"iPad6,7"] ||
        [deviceModel isEqualToString:@"iPad6,8"] ||                                 //return "iPad Pro 12.9 Inch"
        //        [deviceModel isEqualToString:@"iPad7,1"] ||
        //        [deviceModel isEqualToString:@"iPad7,2"] ||                                 //return "iPad Pro 12.9 Inch 2. Generation"
        //        [deviceModel isEqualToString:@"iPad7,3"] ||
        //        [deviceModel isEqualToString:@"iPad7,4"] ||                                 //return "iPad Pro 10.5 Inch"
        [deviceModel isEqualToString:@"AppleTV5,3"] ||                              //return "Apple TV"
        [deviceModel isEqualToString:@"i386"] ||
        [deviceModel isEqualToString:@"x86_64"]                                   //return "Simulator"
        ) {
        return NO;
    }
    return YES;
}
+ (BOOL)isIphone6or6p
{
    BOOL flag = NO;
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString* deviceModel = [NSString stringWithCString:systemInfo.machine
                                               encoding:NSUTF8StringEncoding];
    if ([deviceModel isEqualToString:@"iPhone7,2"] ||                               //return "iPhone 6"
        [deviceModel isEqualToString:@"iPhone7,1"]) {
        flag = YES;
    }
    return flag;
}
@end
