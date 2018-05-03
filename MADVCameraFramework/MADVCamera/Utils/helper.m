//
//  helper.m
//
//  Created by wen on 15/8/25.
//  Copyright (c) 2015年 HORSUN. All rights reserved.
//

#import "helper.h"
#import <CommonCrypto/CommonDigest.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>

#define PRAISE @"PRAISE"
#define PHOTO @"PHOTO"
@implementation helper

+ (void) writeProfileString:(NSString *)key value:(NSString *)content {
	NSUserDefaults *prof = [NSUserDefaults standardUserDefaults];
	[prof setObject:content forKey:key];
	[prof synchronize];
}

+ (NSString *) readProfileString:(NSString *)key {
	NSUserDefaults *prof = [NSUserDefaults standardUserDefaults];
    NSObject * obj = [prof objectForKey:key];
    if ([NSNull null] == obj) {
        return @"";
    }
    if (obj == nil) {
        return @"";
    }
	return (NSString *)obj;
}

+ (void)writeProfileId:(NSString *)key value:(id)content
{
    NSUserDefaults *prof = [NSUserDefaults standardUserDefaults];
    [prof setObject:content forKey:key];
    [prof synchronize];
}
+ (id)readProfileId:(NSString *)key
{
    NSUserDefaults *prof = [NSUserDefaults standardUserDefaults];
    NSObject * obj = [prof objectForKey:key];
    return obj;
}

//判断是否空数组
+ (BOOL)isBlankArray:(NSArray *)array
{
    if (array == nil)
    {
        return YES;
    }
    
    if (array == NULL)
    {
        return YES;
    }
    
    if ([array isKindOfClass:[NSNull class]])
    {
        return YES;
    }
    return NO;
    
}



//判断字符串是否为空
+ (BOOL)isNull:(id)object
{
    if ([object isKindOfClass:[NSNumber class]]) {
        object = [NSString stringWithFormat:@"%@",object];
    }
    // 判断是否为空串
    if ([object isEqual:[NSNull null]]) {
        return YES;
    }
    else if ([object isKindOfClass:[NSNull class]])
    {
        return YES;
    }
    else if (object==nil)
    {
        return YES;
    }else if ([object isEqualToString:@"<null>"]){
        return YES;
    }
    else if ([object isEqualToString:@"null"])
    {
        return YES;
    }
    else if ([object isEqualToString:@"(null)"])
    {
        return YES;
    }
    else if ([object isEqualToString:@""]){
        return YES;
    }
    return NO;
}


+ (Boolean) isLogin {
	
    NSDate* date = [[NSDate alloc] init];
    NSString *userTime = [[helper readProfileString:@"userendtime"] stringByReplacingOccurrencesOfString:@" +0000" withString:@""];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *userPwd =[helper readProfileString:@"userpwd"];
    if(![userPwd isEqualToString:@"<nil>"] && ![userPwd isEqualToString:@""] && ![userTime isEqualToString:@""])
    {
        NSDate *dateEnd = [dateFormatter dateFromString:userTime];
        if([date compare:dateEnd])
            return YES;
    }
	return NO;
}

// 将密码进行MD5加密
+ (NSString *)getMD:(NSString *)str {
    
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    
    CC_MD5( cStr, strlen(cStr), result );
    
    return [NSString stringWithFormat:
            
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            
            result[0], result[1], result[2], result[3],
            
            result[4], result[5], result[6], result[7],
            
            result[8], result[9], result[10], result[11],
            
            result[12], result[13], result[14], result[15]
            
            ];
    
}
//存入点赞的id
+(NSString *) savePraiseStr:(NSString *)praiseID
{
    //点赞存入userdefaults
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * praiseStr = [NSString stringWithFormat:@"praise_%@",praiseID];
    [defaults setValue:PRAISE forKey:praiseStr];
    return nil;
}
//判断存入的id是否存在

+ (BOOL) isThere:(NSString *)praiseID
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * praiseStr = [NSString stringWithFormat:@"praise_%@",praiseID];
    if ([[defaults valueForKey:praiseStr] isEqualToString:PRAISE]) {
        return YES;
    }
    else
    {
        return NO;
    }
}

/**
 * 照片点赞
 *
 */
//存入点赞的id
+(NSString *) savePhotoStr:(NSString *)praiseID
{
    //点赞存入userdefaults
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * praiseStr = [NSString stringWithFormat:@"photo_%@",praiseID];
    [defaults setValue:PHOTO forKey:praiseStr];
    return nil;
}
//判断存入的id是否存在

+ (BOOL) isPhotoThere:(NSString *)PhotoID
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * praiseStr = [NSString stringWithFormat:@"photo_%@",PhotoID];
    if ([[defaults valueForKey:praiseStr] isEqualToString:PHOTO]) {
        return YES;
    }
    else
    {
        return NO;
    }
}



//存用户id和名字
+(void) saveUserNameStr:(NSString *)username ID:(NSString *)userID
{
    if(username == nil)
        username = @"";
    userID = [NSString  stringWithFormat:@"userName_%@",userID];
    //点赞存入userdefaults
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:username forKey:userID];
}
+ (NSString *) isNameThere:(NSString *)userID
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    userID = [NSString  stringWithFormat:@"userName_%@",userID];
    NSLog(@"姓名 === %@",[defaults valueForKey:userID]);
    return [defaults valueForKey:userID];
}

//活动专题

+ (NSString *)saveActivity:(NSString *)activity
{
    //点赞存入userdefaults
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * praiseStr = [NSString stringWithFormat:@"activity_%@",activity];
    [defaults setValue:PRAISE forKey:praiseStr];
    return nil;
}

+ (BOOL)activityIsThere:(NSString *)activity
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * praiseStr = [NSString stringWithFormat:@"activity_%@",activity];
    if ([[defaults valueForKey:praiseStr] isEqualToString:PRAISE]) {
        return YES;
    }
    else
    {
        return NO;
    }
}
//mac 地址
+ (NSString *) macaddress
{
    int                   mib[6];
    size_t               len;
    char               *buf;
    unsigned char       *ptr;
    struct if_msghdr   *ifm;
    struct sockaddr_dl   *sdl;
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error/n");
        return NULL;
    }
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1/n");
        return NULL;
    }
    if ((buf = (char*)malloc(len)) == NULL) {
        printf("Could not allocate memory. error!/n");
        return NULL;
    }
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        return NULL;
    }
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    return [outstring uppercaseString];
}

//运营商
+ (NSString *) carrierStr
{

    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc]init];
    CTCarrier*carrier = [netInfo subscriberCellularProvider];
    NSString * carrierStr = [NSString stringWithFormat:@"%@",[carrier carrierName]];
    return carrierStr;
}
//时间
+ (NSString *)timeStr
{
    NSDate *  senddate=[NSDate date];
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSString *  locationString=[dateformatter stringFromDate:senddate];
    return locationString;
}
#ifndef MADVCAMERA_EXPORT
+(BOOL) animation:(UIView *)view  shouldHiden:(BOOL)visible
{
    if (visible) {
        
        view.hidden = YES;
    }else
    {
        view.hidden = NO;
    }
    CATransition* transition = [CATransition animation];
    transition.duration = 0.5;
    transition.timingFunction = UIViewAnimationCurveEaseInOut;
    transition.type = @"rippleEffect";
    transition.subtype = kCATransitionFromBottom;
    [view.layer addAnimation:transition forKey:nil];
    [view exchangeSubviewAtIndex:0 withSubviewAtIndex:1];

    return YES;
}
#endif
//加载到uiwindow上得视图
+ (BOOL)addConstraintsForContentView:(UIView *)aView contentView:(UIView *)contentView contentWidth:(float)contentWidth contentHeight:(float)contentHeight
{
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:contentView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0
                                                                        constant:contentWidth];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:contentView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:contentHeight];
    [contentView addConstraints:@[widthConstraint, heightConstraint]];
    
    
    // Create the constraint to put the view horizontally in the center */
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:contentView
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:aView
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0f constant:0.0f];
    /* 3) Create the constraint to put the button vertically in the center */
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:contentView
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:aView
                                                                         attribute:NSLayoutAttributeCenterY
                                                                        multiplier:1.0f constant:0.0f];
    /* Add the constraints to the superview of the button */
    [aView addConstraints:@[centerXConstraint, centerYConstraint]];
    return YES;
}

+ (NSString *)direction:(NSInteger )direction with:(NSString *)money
{
    //1-收入 2-支出
    switch (direction) {
        case 1:return  [NSString stringWithFormat:@"+%@",money];
        case 2:return  [NSString stringWithFormat:@"-%@",money];
        default:       return nil;
    }
    
}

//判断是否是手机号码
+(BOOL) isPhone:(NSString *)string{
    NSString *Regex = @"\\b(1)[345678][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]\\b";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", Regex];
    return [phoneTest evaluateWithObject:string];
}

//判断是否是身份证
+(BOOL) validateIdentityCard:(NSString *)identityCard
{
    BOOL flag;
    if (identityCard.length <= 0) {
        flag = NO;
        return flag;
    }
    NSString *regex2 = @"^(\\d{14}|\\d{17})(\\d|[xX])$";
    NSPredicate *identityCardPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex2];
    return [identityCardPredicate evaluateWithObject:identityCard];
}

// 字典转json字符串
+ (NSString*)dictionaryToJson:(NSDictionary *)dic
{
    NSError *parseError = nil;
    NSData  *jsonData = [NSJSONSerialization dataWithJSONObject:dic
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

//// json转字典
//+ (NSMutableDictionary *)jsonStringToDictionary:(NSString *)jsonString {
//    NSLog(@"%@",jsonString);
//
//    if ([helper isNull:jsonString]) {
//        NSLog(@"无返回数据");
//        return nil;
//    }else if ([jsonString isEqualToString:@"error"])
//    {
//        NSLog(@"返回数据为error");
//        return nil;
//    }
//    else {
//    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//    NSError *err;
//    NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
//                                                        options:NSJSONReadingMutableContainers
//                                                          error:&err];
//    if(err) {
//        NSLog(@"json解析失败：%@",err);
//        return nil;
//    }
//    return dic;
//    }
//}

//加密操作
+ (NSMutableDictionary *)dictionaryToDesDictionary:(NSMutableDictionary *)dic
{
//    NSError *parseError = nil;
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic
//                                                        options:NSJSONWritingPrettyPrinted
//                                                          error:&parseError];
//    if(parseError) {
//        NSLog(@"失败：%@",parseError);
//        return nil;
//    }
//
//    NSString *jsonStr =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    NSString *desStr = [DesUtil encrypt:jsonStr useKey:@"12345678"];
//    
//    NSData *desData = [desStr dataUsingEncoding:NSUTF8StringEncoding];
//    NSError *err;
//    NSMutableDictionary *desDic = [NSJSONSerialization JSONObjectWithData:desData
//                                                               options:NSJSONReadingMutableContainers
//                                                                 error:&err];
//    if(err) {
//        NSLog(@"失败：%@",err);
//        return nil;
//    }
//    return desDic;
    return nil;
}

// 获取128bit随机数
+ (NSString *)generateSalt192 {
    
    NSString *alphabet  = @"0123456789";
    NSMutableString *s = [NSMutableString stringWithCapacity:24];
    for (NSUInteger i = 0; i < 24; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    NSString *key = s;
    return key;
    
}

//获取uuid
//+ (NSString *)getUUID
//{
//    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"private" accessGroup:nil];
//
//    NSString *uuid = [wrapper objectForKey:(__bridge id)kSecValueData];
//
//    return uuid;
//}

+( NSInteger)getDays:(NSInteger )year toNext:(NSInteger )limitMonth
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    
    NSDateComponents *components = [calendar components:unitFlags fromDate:[NSDate date]];
    
    NSInteger iCurYear = [components year];  //当前的年份
    NSInteger iCurMonth = [components month];  //当前的月份
    //    NSInteger iCurDay = [components day];  // 当前的号数
    
    int days[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    //             1   2    3  4   5   6   7   8   9   10  11  12
    if ([helper getLeapYear:iCurYear] && iCurMonth <= 2) {
        
        days[1] = 29;
    }
    
    int otherDays = 0 ;
    
    for (int i = 0; i < limitMonth  - 1 ; i++) {
        
        if (iCurMonth + i > 11) {
            
            if ([helper getLeapYear:iCurYear + 1] && i + iCurMonth  >= 12 ) {
                
                days[1] = 29;
            }

            otherDays += (days[(iCurMonth + i) % 12]);
            
        }else
        {
            otherDays += (days[iCurMonth + i]);
            
        }
        
    }
    
    NSInteger totalDays = otherDays + days[iCurMonth -1];//(days[iCurMonth -1]:当前月天数.   otherDays:其余月份天数)

    return totalDays;
    
}

+ (float)getInterestWithRate:(double)totalRevenue forMoney:(float)money toNextMouths:(NSInteger )limitMonth
{
    
    float lastRevenue = 0;
    
    lastRevenue = (float)totalRevenue;
    
    //天化利率
    float dayRate = 0;
    
    dayRate = lastRevenue/365/100.0;
    
    NSLog(@"dayRate:%f",dayRate);

    //每天的收益
    float dayRevenue = 0;
    
    dayRevenue = dayRate*money;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    
    NSDateComponents *components = [calendar components:unitFlags fromDate:[NSDate date]];
    
    NSInteger iCurYear = [components year];  //当前的年份
    
    NSInteger iCurMonth = [components month];  //当前的月份
    
    //    NSInteger iCurDay = [components day];  // 当前的号数
    
    NSRange firstMouthDays = [[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:[NSDate date]];
    
    NSString *firstRevenue = [NSString stringWithFormat:@"%.2f",firstMouthDays.length*dayRevenue];
    
    int days[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    //             1   2    3  4   5   6   7   8   9   10  11  12
    if ([helper getLeapYear:iCurYear] && iCurMonth <= 2) {
        
        days[1] = 29;
        
    }
    
    NSString *othersRevenue;
    float totalOthers;
    for (int i = 0; i < limitMonth - 1 ; i++) {
        
        if (iCurMonth + i > 11) {
            
            if ([helper getLeapYear:iCurYear + 1] && i + iCurMonth  >= 12) {
                
                days[1] = 29;
            }
            
            othersRevenue = [NSString stringWithFormat:@"%.2f",dayRevenue*(days[(iCurMonth + i) % 12])];
            //            NSLog(@"月收益%f",othersRevenue.floatValue);
            
            totalOthers += othersRevenue.floatValue;
            
            
        }else
        {
            othersRevenue = [NSString stringWithFormat:@"%.2f",dayRevenue*(days[iCurMonth + i])];
            //            NSLog(@"月收益%f",othersRevenue.floatValue);
            
            totalOthers += othersRevenue.floatValue;
        }
        
    }
    
    return totalOthers + firstRevenue.floatValue;
    
    
}


+ (BOOL)getLeapYear:(NSInteger)year{
  //能被4整除且不能被100 或者能被400整除的就是闰年
    if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
        return YES;
    }else
    {
        return NO;
    }
}

//时间戳转日期
+(NSString *)getDateWithString:(NSString *)str
{
    NSTimeInterval _interval=[str doubleValue] ;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_interval];
    NSDateFormatter *objDateformat = [[NSDateFormatter alloc] init];
    [objDateformat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return  [objDateformat stringFromDate: date];
}

//未来时间戳(13位毫秒)到当前时间的倒计时
+(NSString *)getStandardTimeInterval:(NSString *)str{
    //进行时间差比较
    NSDate *nowDate = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval nowTimer = [nowDate timeIntervalSince1970];
    NSTimeInterval interval = [str doubleValue] / 1000.0;
    
    NSTimeInterval timeInterval = interval - nowTimer;
    int day = timeInterval/(60*60*24);
    int hour = ((long)timeInterval%(60*60*24))/(60*60);
    int minite = ((long)timeInterval%(60*60*24))%(60*60)/60;
    int second = ((long)timeInterval%(60*60*24))%(60*60)%60;
//    NSLog(@"剩余时间:%@",[NSString stringWithFormat:@"%d天%d小时%d分%d秒",day,hour,minite,second]);
    return [NSString stringWithFormat:@"%d天%d小时%d分%d秒",day,hour,minite,second];
}


+ (CGSize)getMaxSize:(CGSize)maxSize withContentFont:(UIFont *)font contentString:(NSString *)string
{
    CGSize max_Size = maxSize;
    NSDictionary *sizeDic = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil];
    CGSize useful_size = [string boundingRectWithSize:max_Size options:NSStringDrawingUsesLineFragmentOrigin attributes:sizeDic context:nil].size;
    
    return useful_size;
}

+ (CGSize)getMaxSize:(CGSize)maxSize withContentFont:(UIFont *)font contentString:(NSString *)string customLable:(UILabel *)label lineSpacing:(CGFloat)spacing
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    //    paragraphStyle.maximumLineHeight = 60;  //最大的行高
    paragraphStyle.lineSpacing = spacing;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, string.length)];
    label.attributedText = attributedString;
    CGSize max_Size = maxSize;
    NSDictionary *sizeDic = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,paragraphStyle,NSParagraphStyleAttributeName, nil];
    CGSize useful_size = [string boundingRectWithSize:max_Size options:NSStringDrawingUsesLineFragmentOrigin attributes:sizeDic context:nil].size;
    
    return useful_size;
}

//设置 label 数字转换带单位 ,数字大,单位小
+ (void)getBigNumberAttributeTextForLabel:(UILabel *)label andString:(NSString *)str andFont:(CGFloat)font{
    // 编写正则表达式：只能是数字或英文，或两者都存在
    NSString *regex = @"^[a-z0－9A-Z]*$";
    // 创建谓词对象并设定条件的表达式
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    if(str.length >= 5){
        NSInteger planAmount = [str floatValue] / 10000.0;
       label.text = [NSString stringWithFormat:@"%ld万",planAmount];
    }else{
       label.text =str;
    }
    NSInteger length2 =label.text.length;
    // 对字符串进行判断
    if ([predicate evaluateWithObject:label.text]) {
        NSMutableAttributedString *richText2 = [[NSMutableAttributedString alloc] initWithString:label.text ];
        [richText2 addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:font] range:NSMakeRange(0, length2)];
        label.attributedText  = richText2;
    }else{
        NSMutableAttributedString *richText2 = [[NSMutableAttributedString alloc] initWithString:label.text ];
        [richText2 addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:font] range:NSMakeRange(0, length2-1)];
        label.attributedText  = richText2;
    }
}

//数字和 % 组合
+ (void)getBigNumberSmallcharForLabel:(UILabel *)label withSingle:(BOOL)isSingle andString:(NSString *)str andFont:(CGFloat)font
{
    label.text = str;
    if(isSingle){
        NSInteger length0 = label.text.length;
        NSMutableAttributedString *richText0 = [[NSMutableAttributedString alloc] initWithString:label.text];
        [richText0 addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:font] range:NSMakeRange(0, length0-1)];
        label.attributedText = richText0;
    }else{
        NSInteger length0 = label.text.length;
        NSMutableAttributedString *richText0 = [[NSMutableAttributedString alloc] initWithString:label.text];
        [richText0 addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:font] range:NSMakeRange(0, length0-2)];
        label.attributedText = richText0;
    }
    
}

+ (void)getBigNumberSmallcharForLabel:(UILabel *)label textFont:(CGFloat)font textColor:(UIColor *)color cutOutLength:(NSInteger)cutOutLength
{
    NSInteger length0 = label.text.length;
    NSMutableAttributedString *richText0 = [[NSMutableAttributedString alloc] initWithString:label.text];
    [richText0 addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:font] range:NSMakeRange(length0 - cutOutLength, cutOutLength)];
    [richText0 addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(length0 - cutOutLength, cutOutLength)];
    label.attributedText = richText0;
    
}

+ (long long)countDirectorySize:(NSString *)directory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //获取到目录下面所有的文件名
    NSArray *fileNames = [fileManager subpathsOfDirectoryAtPath:directory error:nil];
    
    long long sum = 0;
    for (NSString *fileName in fileNames) {
        NSString *filePath = [directory stringByAppendingPathComponent:fileName];
        
        NSDictionary *attribute = [fileManager attributesOfItemAtPath:filePath error:nil];
        
        //        NSNumber *filesize = [attribute objectForKey:NSFileSize];
        long long size = [attribute fileSize];
        
        sum += size;
    }
    
    return sum;
}
+ (NSString *)getAppVersion
{
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    return [infoDic objectForKey:@"CFBundleShortVersionString"];
}

+ (id)sharedInstance
{
    static dispatch_once_t once;
    static helper * instance = nil;
    dispatch_once(&once, ^{
        /*
         if ([MRDIAMABAGER_ENVIRONMENT isEqualToString:ENVIRONMENT_DEVELOPMENT])
         instance = [[MVMediaManagerCase alloc] init];
         else
         //*/
        instance = [[helper alloc] init];
    });
    return instance;
}

@end
