//
//  FGLanguageTool.h
//  appswitchlanguage
//
//  Created by 张巧隔 on 17/3/17.
//  Copyright © 2017年 张巧隔. All rights reserved.
//
#define FGGetStringWithKeyFromTable(key, tbl) [[FGLanguageTool sharedInstance] getStringForKey:key withTable:tbl]
#import <Foundation/Foundation.h>
#define CNS @"zh-Hans"
#define EN @"en"
#define CNT @"zh-Hant"
#define ES @"es"
#define RU @"ru"
#define LANGUAGE_SET @"langeuageset"

@interface FGLanguageTool : NSObject
@property(nonatomic,assign)BOOL isChangeLanguage;
+(id)sharedInstance;

/**
 *  返回table中指定的key的值
 *
 *  @param key   key
 *  @param table table 默认是Localizable
 *
 *  @return 返回table中指定的key的值
 */
-(NSString *)getStringForKey:(NSString *)key withTable:(NSString *)table;

/**
 *  设置新的语言
 *
 *  @param language 新语言
 */
-(void)setNewLanguage:(NSString*)language;
- (NSString *)getFilePath:(NSString *)fileName;
- (NSString *)getNewLanguage;
@end
