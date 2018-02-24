//
//  RLModel.m
//  Madv360_v1
//
//  Created by QiuDong on 16/10/20.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "RLModel.h"
#import "RealmSerialQueue.h"
#import <sys/time.h>
#import <objc/runtime.h>

//+ (NSArray *)propertiesForClass:(Class)objectClass isSwift:(bool)isSwiftClass
typedef NSArray* (*PropertiesForClassIsSwiftClassPrototype)(Class, SEL, Class, bool);

@interface RLModel ()
{
    NSArray<RLMProperty* >* _realmProperties;
}
@end

@implementation RLModel

static const char* keyPropertyValueDictionary = "keyPropertyValueDictionary";

- (NSArray<RLMProperty*> *) realmProperties {
    if (!_realmProperties) {
        Class clsRLMObjectSchema = objc_getClass("RLMObjectSchema");
        SEL selPropertiesForClass = NSSelectorFromString(@"propertiesForClass:isSwift:");
        Method mtdPropertiesForClass = class_getClassMethod(clsRLMObjectSchema, selPropertiesForClass);
        IMP impPropertiesForClass = method_getImplementation(mtdPropertiesForClass);
        PropertiesForClassIsSwiftClassPrototype propertiesForClassFunction = (PropertiesForClassIsSwiftClassPrototype) impPropertiesForClass;
        
        NSString* className = NSStringFromClass(self.class);
        NSString* regexPattern = @"^RLM.+_(.+)";
        NSRegularExpression* regEx = [NSRegularExpression regularExpressionWithPattern:regexPattern options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray* matches = [regEx matchesInString:className options:0 range:NSMakeRange(0, className.length)];
        NSTextCheckingResult* result = nil;
        if (matches && matches.count > 0 && (result = matches[0]) && result.numberOfRanges > 0)
        {
            className = [className substringWithRange:[result rangeAtIndex:1]];
        }
        _realmProperties = propertiesForClassFunction(clsRLMObjectSchema, selPropertiesForClass, NSClassFromString(className), false);
    }
    return _realmProperties;
}

- (void) registerPropertyObservers {
    for (RLMProperty* property : [self realmProperties])
    {
        [self addObserver:self forKeyPath:property.name options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void) dumpPropertyValues {
    NSMutableDictionary* propertyValueDict = objc_getAssociatedObject(self, keyPropertyValueDictionary);
    if (!propertyValueDict) {
        propertyValueDict = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, keyPropertyValueDictionary, propertyValueDict, OBJC_ASSOCIATION_RETAIN);
    }
    
    for (RLMProperty* property : [self realmProperties])
    {
        id value = [self dbValueForKeyPath:property.name];
        if (value)
        {
            [propertyValueDict setObject:value forKey:property.name];
        }
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    //NSLog(@"observeValueForKeyPath:%@, new = %@", keyPath, change[NSKeyValueChangeNewKey]);
}

-(BOOL) isFromDB {
    return (self.realm != nil);
}

- (void) insert {
#ifndef DEBUG_DISABLE_REALM
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[RealmSerialQueue shareRealmQueue] sync:^{
            RLMRealm* realm = [RLMRealm defaultRealm];
            [realm transactionWithBlock:^{
                [realm addObject:self];
                [realm commitWriteTransaction];
            }];
        }];
        [self registerPropertyObservers];
        [self dumpPropertyValues];
    //});
#endif
}

+ (void) insert:(NSArray<RLModel* >*)models {
    [[RealmSerialQueue shareRealmQueue] sync:^{
        RLMRealm* realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [realm addObjects:models];
            [realm commitWriteTransaction];
        }];
    }];
    for (RLModel* rm in models)
    {
        [rm registerPropertyObservers];
        [rm dumpPropertyValues];
    }
}

- (void) remove {
    [self dumpPropertyValues];
    __weak __typeof(self) wSelf = self;
    [[RealmSerialQueue shareRealmQueue] sync:^{
        __strong __typeof(self) pSelf = wSelf;
        if (pSelf.isFromDB)
        {
            __weak __typeof(self) wSelf = pSelf;
            RLMRealm* realm = [RLMRealm defaultRealm];
            [realm transactionWithBlock:^{
                __strong __typeof(self) pSelf = wSelf;
                [realm deleteObject:pSelf];
                [realm commitWriteTransaction];
            }];
        }
    }];
}

- (void) transactionWithBlock:(dispatch_block_t)block {
#ifdef DEBUG_DISABLE_REALM
    block();
#else
    __weak __typeof(self) wSelf = self;
    [[RealmSerialQueue shareRealmQueue] sync:^{
        __strong __typeof(self) pSelf = wSelf;
        if (pSelf.isFromDB)
        {
            RLMRealm* realm = [RLMRealm defaultRealm];
            [realm transactionWithBlock:^{
                block();
                ///!!![realm commitWriteTransaction];
            }];
        }
        else
        {
            block();
        }
    }];
#endif
}

- (_Nullable id) dbValueForKeyPath:(NSString*)keyPath {
#ifdef DEBUG_DISABLE_REALM
    return [self valueForKeyPath:keyPath];
#else
    __block id value = nil;
    __weak __typeof(self) wSelf = self;
//    __block NSException* exception = nil;
    [[RealmSerialQueue shareRealmQueue] sync:^{
        __strong __typeof(self) pSelf = wSelf;
        @try {
            value = [pSelf valueForKeyPath:keyPath];
            if (!value) {
                NSMutableDictionary* dict = objc_getAssociatedObject(pSelf, keyPropertyValueDictionary);
                value = [dict objectForKey:keyPath];
            }
        } @catch (NSException* ex) {
//            exception = ex;
            NSMutableDictionary* dict = objc_getAssociatedObject(pSelf, keyPropertyValueDictionary);
            value = [dict objectForKey:keyPath];
        } @finally {
        }
    }];
//    if (exception)
//    {
//        NSLog(@"Exception : %@", exception);
//    }
    return value;
#endif
}

@end
