//
//  NSString+Extensions.m
//  Madv360
//
//  Created by FutureBoy on 11/6/15.
//  Copyright © 2015 Cyllenge. All rights reserved.
//

#import "NSString+Extensions.h"
#import "sys/utsname.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Extensions)

+ (NSString*) stringOfBundleFile : (NSString*)baseName
                         extName : (NSString*)extName {
    NSString* path = [[NSBundle mainBundle] pathForResource:baseName ofType:extName];
    NSString* ret = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    return ret;
}

+ (NSString*) stringWithJSONDictionary : (NSDictionary*)jsonDictionary {
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:nil];
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}
+ (NSString *)timeformatFromSeconds:(int)seconds
{
    //format of hour
    NSString *str_hour = [NSString stringWithFormat:@"%02d",seconds/3600];
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%02d",(seconds%3600)/60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%02d",seconds%60];
    //format of time
    NSString *format_time;
    if ([str_hour isEqualToString:@"00"]) {
        format_time=[NSString stringWithFormat:@"%@:%@",str_minute,str_second];
    }else
    {
        format_time = [NSString stringWithFormat:@"%@:%@:%@",str_hour,str_minute,str_second];
    }
    return format_time;
}
//iOS 获取当前手机系统语言

/**
 *得到本机现在用的语言
 * en-CN 或en  英文  zh-Hans-CN或zh-Hans  简体中文   zh-Hant-CN或zh-Hant  繁体中文    ja-CN或ja  日本  ......
 */
+ (NSString*)getPreferredLanguage
{
    static NSString * language=nil;
    
    language = [NSLocale preferredLanguages].firstObject;
    if ([language hasPrefix:@"en"]) {
        language = @"en";
    } else if ([language hasPrefix:@"zh"]) {
        if ([language rangeOfString:@"Hans"].location != NSNotFound) {
            language = @"zh-Hans"; // 简体中文
        } else { // zh-Hant\zh-HK\zh-TW
            language = @"zh-Hant"; // 繁體中文
        }
    }else if ([language hasPrefix:@"es"])
    {
        language = @"es";
    }else if ([language hasPrefix:@"ru"])
    {
        language = @"ru";
    }else {
        language = @"en";
        
    }
    return language;
}
+ (NSString *)getAppLanguage
{
    NSString * language=nil;
    NSString *tmp = [[NSUserDefaults standardUserDefaults]objectForKey:LANGUAGE_SET];
    if (!tmp || [tmp isEqualToString:@""]) {
        language = [NSLocale preferredLanguages].firstObject;
        if ([language hasPrefix:@"en"]) {
            language = @"en";
        } else if ([language hasPrefix:@"zh"]) {
            if ([language rangeOfString:@"Hans"].location != NSNotFound) {
                language = @"zh-Hans"; // 简体中文
            } else { // zh-Hant\zh-HK\zh-TW
                language = @"zh-Hant"; // 繁體中文
            }
        }else if ([language hasPrefix:@"id"])//印尼
        {
            language = @"id";
        }else if ([language hasPrefix:@"es"])//西班牙语
        {
            language = @"es";
        }else if ([language hasPrefix:@"ru"])//俄语
        {
            language = @"ru";
        }else if ([language hasPrefix:@"ar"])//阿拉伯语
        {
            language = @"ar";
        }else if ([language hasPrefix:@"it"])//意大利语
        {
            language = @"it";
        }else if ([language hasPrefix:@"fr"])//法语
        {
            language = @"fr";
        }else if ([language hasPrefix:@"de"])//德语
        {
            language = @"de";
        }else
        {
            language = @"en";
        }
        
    }else if ([tmp isEqualToString:CNS])
    {
        language = @"zh-Hans";
    }else if ([tmp isEqualToString:CNT])
    {
        language = @"zh-Hant";
    }else if ([tmp isEqualToString:EN])
    {
        language = @"en";
    }else
    {
        language = tmp;
    }
    return language;
}

+ (NSString *)getAppLessLanguage
{
    NSString * language=nil;
    NSString *tmp = [[NSUserDefaults standardUserDefaults]objectForKey:LANGUAGE_SET];
    if (!tmp || [tmp isEqualToString:@""]) {
        language = [NSLocale preferredLanguages].firstObject;
        if ([language hasPrefix:@"en"]) {
            language = @"en";
        } else if ([language hasPrefix:@"zh"]) {
            if ([language rangeOfString:@"Hans"].location != NSNotFound) {
                language = @"zh-Hans"; // 简体中文
            } else { // zh-Hant\zh-HK\zh-TW
                language = @"zh-Hant"; // 繁體中文
            }
        }else
        {
            language = @"en";
        }
        
    }else if ([tmp isEqualToString:CNS])
    {
        language = @"zh-Hans";
    }else if ([tmp isEqualToString:CNT])
    {
        language = @"zh-Hant";
    }else
    {
        language = @"en";
    }
    return language;
}

+ (NSString *)formatFloat:(float)f
{
    if (fmodf(f, 1)==0) {//如果有一位小数点
        return [NSString stringWithFormat:@"%.2f",f];
    } else if (fmodf(f*10, 1)==0) {//如果有两位小数点
        return [NSString stringWithFormat:@"%.2f",f];
    } else {
        return [NSString stringWithFormat:@"%.2f",f];
    }
}
+(NSString *)getNowTimeTimestamp{
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    
    NSTimeInterval a=[dat timeIntervalSince1970];
    
    NSString*timeString = [NSString stringWithFormat:@"%0.f", a];//转为字符型
    
    ;
    
    return timeString;
    
}

+ (NSString *)deviceString
{
    struct utsname systemInfo;
    
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceString;
}
- (NSComparisonResult)new_compare:(NSString *)string
{
    NSArray * arr1 = [self componentsSeparatedByString:@"."];
    NSArray * arr2 = [string componentsSeparatedByString:@"."];
    for (int i = 0; i < arr1.count; i++) {
        if ((i+1) > arr2.count) {
            return NSOrderedDescending;
        }else
        {
            if ([arr1[i] integerValue] > [arr2[i] integerValue]) {
                return NSOrderedDescending;
                
            }else if ([arr1[i] integerValue] < [arr2[i] integerValue])
            {
                return NSOrderedAscending;
            }else if (i == arr1.count-1 && (i+1) < arr2.count)
            {
                return NSOrderedAscending;
            }
        }
        
    }
    return NSOrderedSame;
}

+ (NSString*)md5num:(unsigned char*) data length:(UInt32)length {
    unsigned char result[16];
    CC_MD5(data, length, result);
    
    char md5str[16 * 2 + 1];
    md5str[16 * 2] = '\0';
    char* pDst = md5str;
    unsigned char* pSrc = result;
    for (int i=0; i<16; ++i)
    {
        sprintf(pDst, "%02x", *pSrc);
        pDst += 2;
        pSrc++;
    }
    
    return [NSString stringWithUTF8String:md5str];
}

@end
