//
//  DATAConnectManager.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/9/7.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    DataSocketStateNotReady = 1,
    DataSocketStateConnecting = 2,
    DataSocketStateReady = 4,
    DataSocketStateDisconnecting = 8,
} DataSocketState;

typedef enum : NSInteger {
    DataSocketErrorException = 1,
    DataSocketErrorTimeout = 2,
} DataSocketError;

@interface DataReceiver : NSObject

- (int) onReceiveData:(UInt8*)data offset:(int)offset length:(int)length;

- (void) onError:(int)error errMsg:(NSString*)errMsg;

- (BOOL) isFinished;

- (void) finish;

@property (nonatomic, assign) long long recentReceiveTime;

//- (int) didReceiveData:(UInt8*)data offset:(int)offset length:(int)length;

@end

@protocol DataConnectionObserver <NSObject>

- (void) onDataConnectionStateChanged:(int)newState oldState:(int)oldState object:(id)object;

- (void) onReceiverEmptied;

@end

@interface DATAConnectManager : NSObject

+ (instancetype) sharedInstance;

- (void) addObserver:(id<DataConnectionObserver>)observer;
- (void) removeObserver:(id<DataConnectionObserver>)observer;

- (void) openConnection;
- (void) closeConnection;

@property (nonatomic, assign, readonly) BOOL isConnected;

@property (nonatomic, assign, readonly) DataSocketState state;

- (int) waitForState:(int)stateCombo;

- (DataReceiver*) removeDataReceiver;

- (DataReceiver*) removeDataReceiver:(DataReceiver*)receiver;

@property (nonatomic, strong) DataReceiver* dataReceiver;

- (int) socket;

@end
