//
//  RLModel.h
//  Madv360_v1
//
//  Created by QiuDong on 16/10/20.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Realm/Realm.h>
//#ifdef DEBUG_DISABLE_REALM
//@interface RLModel : NSObject
//#else
@interface RLModel : RLMObject
//#endif
- (BOOL) isFromDB;

- (void) insert;

+ (void) insert:(NSArray<RLModel* >* __nonnull)models;

- (void) remove;

- (void) transactionWithBlock:(dispatch_block_t)block;

- (_Nullable id) dbValueForKeyPath:(NSString*)keyPath;

@end
