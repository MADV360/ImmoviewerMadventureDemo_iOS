//
//  DBHelper.m
//  02-数据库的下载管理模型
//
//  Created by MS on 15-12-22.
//  Copyright (c) 2015年 MS. All rights reserved.
//

#import "DBHelper.h"
#import "z_Sandbox.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import <objc/runtime.h>
@interface DBHelper()
@property(nonatomic,strong)FMDatabaseQueue * databaseQueue;

@end
@implementation DBHelper
static DBHelper * instance;
+ (id)shareDBHelper
{
    if (instance==nil) {
        instance=[[self alloc] init];
    }
    return instance;
}
- (void)moveDatabaseWithFileName:(NSString *)fileName
{
    //得到数据库的路径
    NSString * path=[z_Sandbox documentPath:fileName];
    if (![z_Sandbox isFileExists:path]) {
        //如果不存在就把数据库移到caches文件夹里
        NSFileManager * fileManager=[NSFileManager defaultManager];
        NSError * error;
        [fileManager copyItemAtPath:[z_Sandbox getAppPathWithFileName:fileName] toPath:path error:&error];
        if (error) {
            NSLog(@"数据库拷贝失败error%@",error);
        }
        else
        {
            NSLog(@"数据库拷贝成功！");
        }
    }
    self.databaseQueue=[FMDatabaseQueue databaseQueueWithPath:path];
    
}

- (void)insertDataWithModel:(id)model
{
    //得到一个对象的所有属性
    NSArray * propertyArr=[self getAllAttributeWithModel:model];
    
    NSString * colStr=[[NSString alloc] init];
    NSString * str=[[NSString alloc] init];
    int i=0;
    for(NSString * propertyName in propertyArr)
    {
        if (i==0) {
            colStr=[colStr stringByAppendingString:propertyName];
            str=[str stringByAppendingString:[NSString stringWithFormat:@"'%@'",[model valueForKey:propertyName]]];
        }
        else
        {
            colStr=[colStr stringByAppendingString:[NSString stringWithFormat:@",%@",propertyName]];
            str=[str stringByAppendingString:[NSString stringWithFormat:@",'%@'",[model valueForKey:propertyName]]];
        }
        i++;
    }
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString * sql=[NSString stringWithFormat:@"insert into %@ (%@) values(%@)",NSStringFromClass([model class]),colStr,str];
        [db executeUpdate:sql];
    }];
}

-(NSArray *)selectDataWithTableName:(NSString *)tableName andDownloadUrl:(NSString *)downloadUrl
{
    NSMutableArray * muArr=[[NSMutableArray alloc] init];
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        
        NSString * sqlStr=[NSString stringWithFormat:@"select * from %@ where downloadUrl='%@'",tableName,downloadUrl];
        FMResultSet * res=[db executeQuery:sqlStr];
        //遍历每一行
        while ([res next]) {
            id item=[[NSClassFromString(tableName) alloc] init];
            //遍历每一列
            for(int i=0;i<[res columnCount];i++)
            {
                //得到列的列名
                NSString * columnName=[res columnNameForIndex:i];
                
                [item setValue:[res stringForColumn:columnName] forKey:columnName];
            }
            [muArr addObject:item];
        }
        [res close];
    }];
    
   
    return muArr;
}

- (NSArray *)selectAllWithTableName:(NSString *)tableName
{
    NSMutableArray * muArr=[[NSMutableArray alloc] init];
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString * sqlStr=[NSString stringWithFormat:@"select * from %@",tableName];
        FMResultSet * res=[db executeQuery:sqlStr];
        
        //遍历每一行
        while ([res next]) {
            id item=[[NSClassFromString(tableName) alloc] init];
            //遍历每一列
            for(int i=0;i<[res columnCount];i++)
            {
                //得到列的列名
                NSString * columnName=[res columnNameForIndex:i];
                
                [item setValue:[res stringForColumn:columnName] forKey:columnName];
                
            }
            [muArr addObject:item];
        }
        
        [res close];
    }];
    return muArr;
}
- (NSArray *)selectAllWithTableName:(NSString *)tableName andStartPoint:(NSString *)startPoint andSize:(NSString *)size
{
    NSMutableArray * muArr=[[NSMutableArray alloc] init];
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString * sqlStr=[NSString stringWithFormat:@"select * from %@ limit %@,%@",tableName,startPoint,size];
        FMResultSet * res=[db executeQuery:sqlStr];
        
        //遍历每一行
        while ([res next]) {
            id item=[[NSClassFromString(tableName) alloc] init];
            //遍历每一列
            for(int i=0;i<[res columnCount];i++)
            {
                //得到列的列名
                NSString * columnName=[res columnNameForIndex:i];
                
                [item setValue:[res stringForColumn:columnName] forKey:columnName];
                
            }
            [muArr addObject:item];
        }
        
        [res close];
    }];
    return muArr;
}

- (void)deleteAllDataWithTableName:(NSString *)tableName
{
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString * sqlStr=[NSString stringWithFormat:@"delete from %@",tableName];
        [db executeUpdate:sqlStr];
    }];
}

- (void)deleteAllDataWithTableName:(NSString *)tableName andAttributeName:(NSString *)attributeName andAttributeValue:(NSString *)attributeValue
{
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString * sqlStr=[NSString stringWithFormat:@"delete from %@ where %@='%@'",tableName,attributeName,attributeValue];
        [db executeUpdate:sqlStr];
    }];
}
- (void)deleteAllDataWithTableName:(NSString *)tableName andAttributeNameArr:(NSArray *)attributeName andAttributeValueArr:(NSArray *)attributeValue
{
    NSString * sqlStr=[NSString stringWithFormat:@"delete from %@ where %@='%@'",tableName,attributeName[0],attributeValue[0]];
    for (int i=1; i<attributeName.count; i++) {
        sqlStr=[sqlStr stringByAppendingString:[NSString stringWithFormat:@" and %@='%@'",attributeName[i],attributeValue[i]]];
    }
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:sqlStr];
    }];

}




- (BOOL)isCachesWithTableName:(NSString *)tableName andDownloadUrl:(NSString *)downloadUrl
{
    NSArray * dataArr= [self selectDataWithTableName:tableName andDownloadUrl:downloadUrl];
    if (dataArr.count>0) {
        return YES;
    }
    else
    {
        return NO;
    }
    
}

//用runtime方法得到对象的所有属性
- (NSArray *)getAllAttributeWithModel:(id)model
{
    NSMutableArray * attributeArr=[[NSMutableArray alloc] init];
    unsigned int outCount;
    objc_property_t * propertys=class_copyPropertyList([model class], &outCount);
    for(int i=0;i<outCount;i++)
    {
        objc_property_t property=propertys[i];
        const char * propertyName=property_getName(property);
        NSString * name=[NSString stringWithUTF8String:propertyName];
        
        NSString * classType =  [NSString stringWithUTF8String:property_getAttributes(property)];
        NSRange range = NSMakeRange(3, [classType rangeOfString:@","].location-4);
        NSString * keyType = [classType substringWithRange:range];
        if ([keyType isEqualToString:@"NSString"]) {
          [attributeArr addObject:name];
        }
    }
    
    
    
    return attributeArr;
}


- (NSArray *)selectAllWithTableName:(NSString *)tableName andAttributeName:(NSString *)attributeName andAttributeValue:(NSString *)attributeValue
{
    NSMutableArray * muArr=[[NSMutableArray alloc] init];
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString * sqlStr=[NSString stringWithFormat:@"select * from %@ where %@=?",tableName,attributeName];
        FMResultSet * res=[db executeQuery:sqlStr,attributeValue];
        //遍历每一行
        while ([res next]) {
            id item=[[NSClassFromString(tableName) alloc] init];
            //遍历每一列
            for(int i=0;i<[res columnCount];i++)
            {
                //得到列的列名
                NSString * columnName=[res columnNameForIndex:i];
                
                [item setValue:[res stringForColumn:columnName] forKey:columnName];
            }
            [muArr addObject:item];
        }
        [res close];
    }];
    
    return muArr;

}


- (NSArray *)selectAllWithTableName:(NSString *)tableName andAttributeNameArr:(NSArray *)attributeName andAttributeValueArr:(NSArray *)attributeValue
{
    NSMutableArray * muArr=[[NSMutableArray alloc] init];
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString * sqlStr=[NSString stringWithFormat:@"select * from %@ where %@='%@'",tableName,attributeName[0],attributeValue[0]];
        for (int i=1; i<attributeName.count; i++) {
            sqlStr=[sqlStr stringByAppendingString:[NSString stringWithFormat:@" and %@='%@'",attributeName[i],attributeValue[i]]];
        }
        
        FMResultSet * res=[db executeQuery:sqlStr];
        //遍历每一行
        while ([res next]) {
            id item=[[NSClassFromString(tableName) alloc] init];
            //遍历每一列
            for(int i=0;i<[res columnCount];i++)
            {
                //得到列的列名
                NSString * columnName=[res columnNameForIndex:i];
                
                [item setValue:[res stringForColumn:columnName] forKey:columnName];
            }
            [muArr addObject:item];
        }
        [res close];
    }];
    
    return muArr;
}



@end
