//
//  helper.h
//
//  Created by wen on 15/8/25.
//  Copyright (c) 2015年 HORSUN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface helper : NSObject

+ (NSString *)getMD:(NSString *) str;
+ (void) writeProfileString:(NSString *)key value:(NSString *)content;
+ (NSString *) readProfileString:(NSString *)key;

+ (void) writeProfileId:(NSString *)key value:(id)content;
+ (id) readProfileId:(NSString *)key;

// 判断字符串是否为空
+ (BOOL)isNull:(id)object;

// 判断是否空数组
+ (BOOL)isBlankArray:(NSArray *)array;

// 资金方向
+ (NSString *)direction:(NSInteger )direction with:(NSString *)money;

+(NSString *) savePraiseStr:(NSString *)praiseID;
+ (BOOL) isThere:(NSString *)praiseID;

// 照片
+ (BOOL) isPhotoThere:(NSString *)PhotoID;
+(NSString *) savePhotoStr:(NSString *)praiseID;

// 存名字
+(void) saveUserNameStr:(NSString *)username ID:(NSString *)userID;
+ (NSString *) isNameThere:(NSString *)userID;

// mac 地址
+ (NSString *) macaddress;

// 运营商
+ (NSString *) carrierStr;

// 时间
+ (NSString *) timeStr;

// 活动
+ (NSString *)saveActivity:(NSString *)activity;
+ (BOOL)activityIsThere:(NSString *)activity;
#ifndef MADVCAMERA_EXPORT
+(BOOL) animation:(UIView *)view  shouldHiden:(BOOL)visible;
#endif
// 弹窗tabelview
+ (BOOL)addConstraintsForContentView:(UIView *)aView contentView:(UIView *)contentView contentWidth:(float)contentWidth contentHeight:(float)contentHeight;

//电话号码判断
+(BOOL) isPhone:(NSString *)string;
//身份证判断
+ (BOOL) validateIdentityCard: (NSString *)identityCard;

// 字典转json字符串
+ (NSString*)dictionaryToJson:(NSDictionary *)dic;

// json转字典
//+ (NSMutableDictionary *)jsonStringToDictionary:(NSString *)jsonString;

// 加密操作
+ (NSMutableDictionary *)dictionaryToDesDictionary:(NSMutableDictionary *)dic;

// 获取128bit随机数
+ (NSString *)generateSalt192;


//获取UUID
+ (NSString *)getUUID;

// 获取未来几月的天数和
+( NSInteger)getDays:(NSInteger )year toNext:(NSInteger )limitMonth;

// 收益计算
+ (float)getInterestWithRate:(double)totalRevenue forMoney:(float)money toNextMouths:(NSInteger )limitMonth;

//判断是否是闰年
+ (BOOL)getLeapYear:(NSInteger)year;

+(NSString *)getDateWithString:(NSString *)str;

//未来时间戳(13位毫秒)到当前时间的倒计时
+(NSString *)getStandardTimeInterval:(NSString *)str;

/**
 *  UILabel内容自适应宽高.  by Color
 *
 *  @param maxSize 设置宽高最大限制 -> 重要:控制内容最大宽高
 *  @param font    内容字体大小参数
 *  @param string  具体内容
 *
 *  @return 计算后得出的适应宽高
 */
+ (CGSize)getMaxSize:(CGSize)maxSize withContentFont:(UIFont *)font contentString:(NSString *)string;
+ (CGSize)getMaxSize:(CGSize)maxSize withContentFont:(UIFont *)font contentString:(NSString *)string customLable:(UILabel *)label lineSpacing:(CGFloat)spacing;

//设置 label 数字大,单位小
+ (void)getBigNumberAttributeTextForLabel:(UILabel *)label andString:(NSString *)str andFont:(CGFloat)font;


//数字和 % 组合
+ (void)getBigNumberSmallcharForLabel:(UILabel *)label withSingle:(BOOL)isSingle andString:(NSString *)str andFont:(CGFloat)font;
/**
 *  富文本 简单处理label  add by Color
 *
 *  @param label    需要处理的label
 *  @param isSingle 是否一个单位长度
 *  @param font     指定字体大小
 *  @param color    指定字体颜色
 *  @param color    指定裁剪长度  if（isSingle） -> 填写任意值
 */
+ (void)getBigNumberSmallcharForLabel:(UILabel *)label textFont:(CGFloat)font textColor:(UIColor *)color cutOutLength:(NSInteger)cutOutLength;

//计算目录下面所有文件的大小
+ (long long)countDirectorySize:(NSString *)directory;
+ (NSString *)getAppVersion;
@end
