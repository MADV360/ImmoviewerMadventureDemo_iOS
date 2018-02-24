//
//  JsonSerializableObject.m
//  Madv360_v1
//
//  Created by QiuDong on 2017/8/30.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "JsonSerializableObject.h"
#import <objc/runtime.h>

@implementation JsonSerializableObject

+ (NSDictionary<NSString*, NSString* >*) propertyNameToJsonKeyMap {
    return nil;
}

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    return nil;
}

- (instancetype) fromJSON:(NSString*)jsonString {
    NSData* jsonStringData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error = nil;
    NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:jsonStringData options:NSJSONReadingMutableLeaves error:&error];
    if (error)
        return nil;
    
    NSDictionary<NSString*, NSString* >* jsonKeyMap = [self.class propertyNameToJsonKeyMap];
    NSArray<NSString* >* propertyNames = [self.class jsonSerializablePropertyNames];
    if (propertyNames)
    {
        for (NSString* propertyName in propertyNames)
        {
            NSString* jsonKey = propertyName;
            if (jsonKeyMap)
            {
                NSString* key = [jsonKeyMap objectForKey:propertyName];
                if (key)
                {
                    jsonKey = key;
                }
            }
            
            id jsonValue = [jsonDict objectForKey:jsonKey];
            if (jsonValue)
            {
                [self setValue:jsonValue forKey:propertyName];
            }
        }
    }
    
    return self;
}

- (NSString*) toJSON {
    NSMutableDictionary<NSString*, NSString* >* jsonDict = [[NSMutableDictionary alloc] init];
    NSDictionary<NSString*, NSString* >* jsonKeyMap = [self.class propertyNameToJsonKeyMap];
    NSArray<NSString* >* propertyNames = [self.class jsonSerializablePropertyNames];
    if (propertyNames)
    {
        for (NSString* propertyName in propertyNames)
        {
            NSString* jsonKey = propertyName;
            if (jsonKeyMap)
            {
                NSString* key = [jsonKeyMap objectForKey:propertyName];
                if (key)
                {
                    jsonKey = key;
                }
            }
            
            id jsonValue = [self valueForKey:propertyName];
            if (jsonValue)
            {
                [jsonDict setObject:jsonValue forKey:jsonKey];
            }
        }
    }
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

+ (NSArray<NSString* >*) jsonSerializablePropertyNamesMergedWithSuper:(NSArray<NSString* >*)baseArray {
    NSMutableArray* tmpArray = [baseArray mutableCopy];
    Class superClass = class_getSuperclass(self.class);
    [tmpArray addObjectsFromArray:[superClass jsonSerializablePropertyNames]];
    NSArray* array = [NSArray arrayWithArray:tmpArray];
    return array;
}

+ (NSDictionary<NSString*, NSString* >*) propertyNameToJsonKeyMapMergedWithSuper:(NSDictionary<NSString*, NSString* >*)baseDictionary {
    NSMutableDictionary* tmpDict = [baseDictionary mutableCopy];
    Class superClass = class_getSuperclass(self.class);
    [tmpDict addEntriesFromDictionary:[superClass propertyNameToJsonKeyMap]];
    NSDictionary* dict = [NSDictionary dictionaryWithDictionary:tmpDict];
    return dict;
    
}

@end
