//
//  NSString+Extensions.h
//  Madv360
//
//  Created by FutureBoy on 11/6/15.
//  Copyright © 2015 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extensions)

+ (NSString*) stringOfBundleFile : (NSString*)baseName
                         extName : (NSString*)extName;

+ (NSString*) stringWithJSONDictionary : (NSDictionary*)jsonDictionary;
#pragma mark --秒转成00:00:00--
+ (NSString *)timeformatFromSeconds:(int)seconds;
//iOS 获取当前手机系统语言 是否包括印尼
+ (NSString*)getPreferredLanguage;
+ (NSString *)formatFloat:(float)f;

//获取app语言，只包括简体、繁体、en
+ (NSString *)getAppLessLanguage;

//获取app语言，包括app所要适配的语言
+ (NSString *)getAppLanguage;

//获取当前时间的时间戳获取当前时间戳有两种方法(以秒为单位
+(NSString *)getNowTimeTimestamp;
+ (NSString*) deviceString;
- (NSComparisonResult)new_compare:(NSString *)string;
+ (NSString*)md5num:(unsigned char*) data length:(UInt32)length;
@end
