//
//  CMDConnectManager.h
//  Madv360_v1
//  与AMBA进行TCP消息通信的管理器，管理请求和响应的排队、分发、异常处理等事务
//  Created by DOM QIU on 16/9/5.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 连接状态 */
typedef enum : NSInteger {
    CmdSocketStateNotReady = 1,
    CmdSocketStateConnecting = 2,
    CmdSocketStateReady = 4,
    CmdSocketStateDisconnecting = 8,
    CmdSocketStateReconnectingStep0 = 16,
    CmdSocketStateReconnectingStep1 = 32,
} CmdSocketState;

@class AMBAResponse;
@class AMBARequest;

/** 消息通信管理器观察者接口 */
@protocol CMDConnectionObserver <NSObject>

/** 当连接状态发生变化时的回调
 * @param object : 附加参数对象
 */
- (void) cmdConnectionStateChanged:(CmdSocketState)newState oldState:(CmdSocketState)oldState object:(id)object;

/** 当接收到无相应请求对象的响应对象时的回调
 *  大多数情况下是App主动发起JSON请求然后接收到AMBA的响应，
 *  但有时需要接收AMBA主动发送的通知，这时就应在这个回调中处理
 */
- (void) cmdConnectionReceiveCameraResponse:(AMBAResponse*)response;

- (void) cmdConnectionHeartbeatRequired;

@end

@interface CMDConnectManager : NSObject

+ (instancetype) sharedInstance;

- (void) addObserver:(id<CMDConnectionObserver>)observer;
- (void) removeObserver:(id<CMDConnectionObserver>)observer;

@property (nonatomic, assign, readonly) CmdSocketState state;

/** 阻塞等待，直到连接状态变成state参数所表示的状态集合中的任一种状态
 * @param state : 一个或几个CmdSocketState枚举值用按位或（|）构成的集合
 */
- (int) waitForState:(CmdSocketState)state;

/**
 * return: If is already connected
 */
- (BOOL) openConnection;
- (void) closeConnection:(id)reason;

/** 重新连接，阻塞 */
- (void) reconnect:(BOOL)forcedCloseFirst;
/** 重新连接，异步 */
- (void) reconnectAsync:(BOOL)forcedCloseFirst;

- (BOOL) isConnected;

- (BOOL) trySendRequest:(AMBARequest*)request;

- (BOOL) sendRequest:(AMBARequest*)request;

- (BOOL) sendRequestAndClearOthers:(AMBARequest *)request;
    
- (BOOL) cancelRequest:(AMBARequest*)request;

- (void) updateLatestMonitoredTime:(long)mills;

- (void) enterBackground;
- (void) enterForeground;

@end
