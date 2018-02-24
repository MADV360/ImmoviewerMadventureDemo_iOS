//
//  RealmQueue.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/10/9.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^dispatch_block_t)(void);
@interface RealmSerialQueue : NSObject
@property(nonatomic,strong)dispatch_queue_t realmQueue;
+ (id)shareRealmQueue;
- (void)async:(dispatch_block_t)asyncblock;
- (void)sync:(dispatch_block_t)syncblock;
+ (void) test;

- (NSThread*) myThread;

@end
