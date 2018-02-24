//
//  JsonSerializableObject.h
//  Madv360_v1
//
//  Created by QiuDong on 2017/8/30.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

#define mergeJsonSerializablePropertyNames(finalArray, ...) static NSArray* finalArray = nil; \
static dispatch_once_t once; \
dispatch_once(&once, ^{ \
finalArray = [self.class jsonSerializablePropertyNamesMergedWithSuper:__VA_ARGS__]; \
});

#define mergePropertyNameToJsonKeyMap(finalDict, ...) static NSDictionary* finalDict = nil; \
static dispatch_once_t once; \
dispatch_once(&once, ^{ \
finalDict = [self.class propertyNameToJsonKeyMapMergedWithSuper:__VA_ARGS__]; \
});

@interface JsonSerializableObject : NSObject

+ (NSDictionary<NSString*, NSString* >*) propertyNameToJsonKeyMap;

+ (NSArray<NSString* >*) jsonSerializablePropertyNames;

- (instancetype) fromJSON:(NSString*)jsonString;

- (NSString*) toJSON;

+ (NSArray<NSString* >*) jsonSerializablePropertyNamesMergedWithSuper:(NSArray<NSString* >*)baseArray;

+ (NSDictionary<NSString*, NSString* >*) propertyNameToJsonKeyMapMergedWithSuper:(NSDictionary<NSString*, NSString* >*)baseDictionary;

@end
