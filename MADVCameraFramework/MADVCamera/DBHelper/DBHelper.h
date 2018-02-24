//
//  DBHelper.h
//  02-数据库的下载管理模型
//
//  Created by MS on 15-12-22.
//  Copyright (c) 2015年 MS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBHelper : NSObject
+ (id)shareDBHelper;
- (void)moveDatabaseWithFileName:(NSString *)fileName;
/**
 *  根据表名和数据模型插入数据
 *
 *  @param tableName 表名
 *  @param model     数据模型
 */
- (void)insertDataWithModel:(id)model;
/**
 *  根据表名和组名查找信息
 *
 *  @param tableName  表名
 *  @param groupIndex 组名
 *
 *  @return 信息的数组
 */
-(NSArray *)selectDataWithTableName:(NSString *)tableName andDownloadUrl:(NSString *)downloadUrl;

/**
 *  查询表的所有信息
 *
 *  @param tableName 表名
 *
 *  @return 所有信息的数组
 */
- (NSArray *)selectAllWithTableName:(NSString *)tableName;

/**
 *  查询表的所有信息
 *
 *  @param tableName 表名
 *
 *  @return 所有信息的数组
 */
- (NSArray *)selectAllWithTableName:(NSString *)tableName andStartPoint:(NSString *)startPoint andSize:(NSString *)size;

/**
 *  通过表名删除这个表的所有数据
 *
 *  @param tableName 表名
 */
-(void)deleteAllDataWithTableName:(NSString *)tableName;

/**
 *  通过表名删除这个表的所有数据
 *
 *  @param tableName 表名
 */
-(void)deleteAllDataWithTableName:(NSString *)tableName andAttributeName:(NSString *)attributeName andAttributeValue:(NSString *)attributeValue;

/**
 *  根据表名和组名判断表中是否有数据
 *
 *  @param tableName  表名
 *  @param groupIndex 组
 */
- (BOOL)isCachesWithTableName:(NSString *)tableName andDownloadUrl:(NSString *)downloadUrl;
/**
 * 得到一个类的全部属性
 *
 *  @param model 一个对象
 *
 *  @return 属性数组
 */
- (NSArray *)getAllAttributeWithModel:(id)model;


- (NSArray *)selectAllWithTableName:(NSString *)tableName andAttributeName:(NSString *)attributeName andAttributeValue:(NSString *)attributeValue;

- (NSArray *)selectAllWithTableName:(NSString *)tableName andAttributeNameArr:(NSArray *)attributeName andAttributeValueArr:(NSArray *)attributeValue;

- (void)deleteAllDataWithTableName:(NSString *)tableName andAttributeNameArr:(NSArray *)attributeName andAttributeValueArr:(NSArray *)attributeValue;
@end
