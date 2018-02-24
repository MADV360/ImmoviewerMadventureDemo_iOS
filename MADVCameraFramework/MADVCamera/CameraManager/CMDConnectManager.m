//
//  CMDConnectManager.m
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/5.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "CMDConnectManager.h"
#import "SocketHelper.h"
#import "AMBARequest.h"
#import "AMBAResponse.h"
#import "AMBACommands.h"
#import "NSRecursiveCondition.h"
#import "NSMutableArray+Extensions.h"
#import "WiFiConnectManager.h"
#import <sys/socket.h>
#import <string.h>
#import "AMBAShootPhotoSurroundexpResponse.h"

#define kNotificationCmdStateChanged    10
#define kNotificationCmdResponseReceived    11
#define kNotificationCmdResponseError    12
#define kNotificationRequestHeartbeat    13

//连接重试次数
static const int SOCKET_RETRY_TIMES_LIMIT = 1;
static const int RESPONSE_TIMEOUT_LIMIT = 30 * 1000;
static const int BUFFER_SIZE = 8 * 1024 * 1024;
static const int MAX_NON_MONITORED_TIME_INTERVAL_MILLS = 7000;

static Class responseClassOfMsgID(int msgID) {
    static dispatch_once_t once;
    static NSDictionary<NSNumber*, Class>* responseClassMap;
    dispatch_once(&once, ^{
        responseClassMap
        = @{@(AMBA_MSGID_CANCEL_FILE_TRANSFER):NSClassFromString(@"AMBACancelFileTransferResponse"),
            @(AMBA_MSGID_FILE_TRANSFER_RESULT):NSClassFromString(@"AMBAFileTransferResultResponse"),
            @(AMBA_MSGID_SAVE_VIDEO_DONE):NSClassFromString(@"AMBASaveMediaFileDoneResponse"),
            @(AMBA_MSGID_SAVE_PHOTO_DONE):NSClassFromString(@"AMBASaveMediaFileDoneResponse"),
            @(AMBA_MSGID_SET_CAMERA_MODE):NSClassFromString(@"AMBASetCameraModeResponse"),
            @(AMBA_MSGID_SHOOT_PHOTO_INTERVAL):NSClassFromString(@"AMBAShootPhotoIntervalResponse"),
            @(AMBA_MSGID_START_PHOTO_SURROUNDEXP):NSClassFromString(@"AMBAShootPhotoSurroundexpResponse"),
            };
    });
    Class clazz = responseClassMap[@(msgID)];
    return clazz;
}

@interface CMDConnectManager () <WiFiObserver>
{
    CmdSocketState _connState;
    
    NSMutableArray<AMBARequest*>* _waitSendRequestQueue;
    NSMutableDictionary<NSString*, AMBARequest*>* _waitResponseRequestMap;
    NSMutableArray<AMBAResponse*>* _responseQueue;
    NSMutableDictionary<NSString*, AMBARequest*>* _responseReceivedRequestMap;
    NSMutableArray<AMBARequest*>* _timeoutRequestQueue;
    NSMutableArray<AMBARequest*>* _exceptionRequestQueue;
    
    NSString* _serverIP;
    int _serverPort;
    int _connectTimeOut;
    
    long long _latestMonitoredTimeMills;
    
    int _socket;
    int _msgReadBufferOffset;
    uint8_t* _msgReadBuffer;
    
    NSThread* _timeoutCheckThread;
    NSThread* _sendMsgThread;
    NSThread* _receiveMsgThread;
    
    NSMutableArray<id<CMDConnectionObserver> >* _observers;
    
    NSRecursiveCondition* _cond;
}

@property (nonatomic, assign) CmdSocketState state;

@property (nonatomic, assign) BOOL justReturnedFromBackground;
@property (nonatomic, assign) BOOL isFirstEnterForeground;

- (void) setState:(CmdSocketState)state object:(id)object;

- (void) setState:(CmdSocketState)state;

- (CmdSocketState) state;

- (void) notifyStateChanged:(CmdSocketState)newState oldState:(CmdSocketState)oldState object:(id)object;

- (void) open;
- (void) close;

- (void) close:(int)destState;

- (void) clearOnDisconnected;

- (void) sendMessage:(int)what arg1:(int)arg1 arg2:(int)arg2 object:(id)object;

@end

@implementation CMDConnectManager

@synthesize justReturnedFromBackground;
@synthesize isFirstEnterForeground;

+ (instancetype) sharedInstance {
    static dispatch_once_t once;
    static CMDConnectManager* singleton = nil;
    dispatch_once(&once, ^{
        singleton = [[CMDConnectManager alloc] init];
    });
    return singleton;
}

- (void) dealloc {
    if (_msgReadBuffer) free(_msgReadBuffer);
    [[WiFiConnectManager sharedInstance] removeWiFiObserver:self];
}

- (instancetype) init {
    if (self = [super init])
    {
        _cond = [[NSRecursiveCondition alloc] init];
        
        _waitSendRequestQueue = [[NSMutableArray alloc] init];
        _responseQueue = [[NSMutableArray alloc] init];
        _timeoutRequestQueue = [[NSMutableArray alloc] init];
        _exceptionRequestQueue = [[NSMutableArray alloc] init];
        
        _waitResponseRequestMap = [[NSMutableDictionary alloc] init];
        _responseReceivedRequestMap = [[NSMutableDictionary alloc] init];
        
        _serverIP = AMBA_CAMERA_IP;
        _serverPort = AMBA_CAMERA_COMMAND_PORT;
        _connectTimeOut = AMBA_CAMERA_TIMEOUT;
        
        _latestMonitoredTimeMills = -1;
        
        _connState = CmdSocketStateNotReady;
        
        _socket = 0;
        _msgReadBufferOffset = 0;
        _msgReadBuffer = (unsigned char*) malloc(BUFFER_SIZE);
        
        _observers = [[NSMutableArray alloc] init];
        
        [[WiFiConnectManager sharedInstance] addWiFiObserver:self];
        
        self.justReturnedFromBackground = NO;
        self.isFirstEnterForeground = YES;
    }
    return self;
}

- (void) addObserver:(id<CMDConnectionObserver>)observer {
    [_cond lock];
    [_observers addObject:observer];
    [_cond unlock];
}

- (void) removeObserver:(id<CMDConnectionObserver>)observer {
    [_cond lock];
    [_observers removeObject:observer];
    [_cond unlock];
}

- (CmdSocketState) state {
    return _connState;
}

- (void) setState:(CmdSocketState)state {
    [self setState:state object:nil];
}

- (void) setState:(CmdSocketState)state object:(id)object {
//    NSLog(@"Before lock @ setState:");
    [_cond lock];
    [self willChangeValueForKey:@"state"];
//    Log.d(TAG, "setState() from " + StringFromState(connState) + " to " + StringFromState(newState));
    NSInteger oldState = _connState;
    _connState = state;
    [self didChangeValueForKey:@"state"];
    [_cond broadcast];
    if (state == CmdSocketStateReady)
    {
        NSLog(@"justReturnedFromBackground : CmdSocketStateReady");
        self.justReturnedFromBackground = NO;
    }
    [self notifyStateChanged:(CmdSocketState)state oldState:(CmdSocketState)oldState object:object];
    [_cond unlock];
}

- (void) notifyStateChanged:(CmdSocketState)newState oldState:(CmdSocketState)oldState object:(id)object {
    [self sendMessage:kNotificationCmdStateChanged arg1:newState arg2:oldState object:object];
}

- (int) waitForState:(CmdSocketState)state {
//    NSLog(@"Before lock @ waitForState:");
    [_cond lock];
    while ((state != 0 || _connState != 0) && ((state & _connState) == 0))
    {
        [_cond wait];
    }
    [_cond unlock];
    return _connState;
}

- (void) sendMessage:(int)what arg1:(int)arg1 arg2:(int)arg2 object:(id)object {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleMessage:what arg1:arg1 arg2:arg2 object:object];
    });
}

- (void) handleMessage:(int)what arg1:(int)arg1 arg2:(int)arg2 object:(id)object {
    switch (what)
    {
        case kNotificationCmdStateChanged:
        {
            [self onStateChanged:arg1 oldState:arg2 object:object];
        }
        break;
        case kNotificationCmdResponseError:
        {
            [self onResponseError];
        }
        break;
        case kNotificationCmdResponseReceived:
        {
            [self onResponseReceived];
        }
        break;
        case kNotificationRequestHeartbeat:
        {
            [self onRequestHeartbeat];
        }
            break;
        default:
        break;
    }
}

- (BOOL) openConnection {
    switch (self.state)
    {
        case CmdSocketStateReady:
            return YES;
        case CmdSocketStateConnecting:
            break;
        
        case CmdSocketStateDisconnecting:
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self waitForState:CmdSocketStateNotReady];
                self.state = CmdSocketStateConnecting;
                [self open];
            });
        }
            break;
        case CmdSocketStateNotReady:
        {
            self.state = CmdSocketStateConnecting;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self open];
            });
        }
            break;
        default:
            break;
    }
    return NO;
}

- (void) closeConnection:(id)reason {
    switch (self.state)
    {
        case CmdSocketStateDisconnecting:
        case CmdSocketStateNotReady:
            return;
        
        case CmdSocketStateConnecting:
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                int state = [self waitForState:(CmdSocketState)(CmdSocketStateNotReady | CmdSocketStateReady)];
                if (CmdSocketStateReady == state)
                {
                    self.state = CmdSocketStateDisconnecting;
                    [self close:CmdSocketStateNotReady reason:reason];
                }
            });
        }
            break;
        case CmdSocketStateReady:
        {
            self.state = CmdSocketStateDisconnecting;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self close:CmdSocketStateNotReady reason:reason];
            });
        }
            break;
        default:
            break;
    }
}

- (void) reconnect:(BOOL)forcedCloseFirst {
    switch (self.state)
    {
        case CmdSocketStateNotReady:
        {
            self.state = CmdSocketStateConnecting;
            [self open];
        }
            break;
        case CmdSocketStateReady:
        {
            if (forcedCloseFirst)
            {
                self.state = CmdSocketStateReconnectingStep0;
                [self close:CmdSocketStateReconnectingStep1 reason:nil];
                [self open];
            }
        }
            break;
        case CmdSocketStateDisconnecting:
        {
            [self waitForState:CmdSocketStateNotReady];
            self.state = CmdSocketStateConnecting;
            [self open];
        }
            break;
        default:
            break;
    }
}

- (void) reconnectAsync:(BOOL)forcedCloseFirst {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self reconnect:forcedCloseFirst];
    });
}

- (BOOL) isConnected {
    BOOL ret;
//    NSLog(@"Before lock @ isConnected");
    [_cond lock];
    ret = (CmdSocketStateReady == self.state && _sendMsgThread && _sendMsgThread.isExecuting && _receiveMsgThread && _receiveMsgThread.isExecuting);
    [_cond unlock];
    return ret;
}

- (void) open {
    __block BOOL success = NO;
    __block int retryTimes = 0;
    while (!success && retryTimes < SOCKET_RETRY_TIMES_LIMIT && CmdSocketStateDisconnecting != self.state && CmdSocketStateReconnectingStep0 != self.state)
    {
        if (![WiFiConnectManager sharedInstance].isWiFiReachable)
        {
            break;
        }
        
        connectServer(_serverIP, _serverPort, ^id(id responseObject, NSError *error, NSString *errMsg) {
            if (!error)
            {
                _socket = [responseObject intValue];
                
                _sendMsgThread = [[NSThread alloc] initWithTarget:self selector:@selector(sendMsgViaSocket:) object:self];
                [_sendMsgThread start];
                
                _receiveMsgThread = [[NSThread alloc] initWithTarget:self selector:@selector(receiveMsgViaSocket:) object:self];
                [_receiveMsgThread start];
                
                if (!_timeoutCheckThread)
                {
                    _timeoutCheckThread = [[NSThread alloc] initWithTarget:self selector:@selector(checkTimeout:) object:self];
                    [_timeoutCheckThread start];
                }
                
                if (CmdSocketStateDisconnecting != self.state && CmdSocketStateReconnectingStep0 != self.state)
                {
                    self.state = CmdSocketStateReady;
                }
                
                success = YES;
            }
            else
            {
                [NSThread sleepForTimeInterval:1.f];
                retryTimes++;
            }
            
            return nil;
        }, -1);
    }
    
    if (!success)
    {
        NSLog(@"justReturnedFromBackground : open failed : self.justReturnedFromBackground=%d", self.justReturnedFromBackground);
        [self clearOnDisconnected];
        self.state = CmdSocketStateNotReady;
    }
}

- (void) close:(int)destState reason:(id)reason {
    if (CmdSocketStateNotReady != self.state)
    {
        if (_socket != 0)
        {
            disconnect(_socket, ^id(id responseObject, NSError *error, NSString *errMsg) {
                _socket = 0;
                return nil;
            });
        }
//        NSLog(@"Before lock @ close:");
        [_cond lock];
        {
            while (_sendMsgThread || _receiveMsgThread)
            {
                [_cond wait];
            }
        }
        [_cond unlock];
    }
    
    if (CmdSocketStateNotReady == destState)
    {
        [self clearOnDisconnected];
    }
    
    [self setState:(CmdSocketState)destState object:reason];
}

- (void) enterBackground {
    DoctorLog(@"#Socket# justReturnedFromBackground : enterBackground");
    self.justReturnedFromBackground = YES;
}

- (void) enterForeground {
#ifdef RECONNECT_ON_BACK_FOREGROUND
    @synchronized (self)
    {
        if (self.justReturnedFromBackground)
        {
            DoctorLog(@"#Socket# justReturnedFromBackround : enterForegound : reconnect");
            self.justReturnedFromBackground = NO;
            [self reconnectAsync:NO];
        }
        else
        {
            DoctorLog(@"#Socket# justReturnedFromBackround : enterForegound : NOP");
        }
    }
#endif
}

- (void) clearOnDisconnected {
//    NSLog(@"Before lock @ clearOnDisconnected");
    [_cond lock];
    {
        [_waitResponseRequestMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, AMBARequest * _Nonnull obj, BOOL * _Nonnull stop) {
            [_exceptionRequestQueue addObject:obj];
        }];
        [_waitResponseRequestMap removeAllObjects];
        
        [_waitSendRequestQueue removeAllObjects];
        
        AMBARequest* request;
        while (nil != (request = [_waitSendRequestQueue poll]))
        {
            [_exceptionRequestQueue addObject:request];
        }
        
        [_responseQueue removeAllObjects];
        
        [self handleMessage:kNotificationCmdResponseError arg1:0 arg2:0 object:nil];
        
        [_cond broadcast];
    }
    [_cond unlock];
}

- (BOOL) trySendRequest:(AMBARequest *)request {
    [_cond lock];
    {
        if (_waitResponseRequestMap.count > 0)
        {
            [_cond unlock];
            return NO;
        }
        
        [_waitSendRequestQueue addObject:request];
        [_cond broadcast];
    }
    [_cond unlock];
    return YES;
}

- (BOOL) sendRequest:(AMBARequest *)request {
//    NSLog(@"Before lock @ sendRequest");
    [_cond lock];
    
    [_waitSendRequestQueue addObject:request];
    [_cond broadcast];
    
    [_cond unlock];
    return YES;
}

- (BOOL) sendRequestAndClearOthers:(AMBARequest *)request {
    [_waitSendRequestQueue removeAllObjects];
    return [self sendRequest:request];
}

- (BOOL) cancelRequest:(AMBARequest *)request {
    //NSLog(@"Before lock @ cancelRequest");
    [_cond lock];
    [_waitSendRequestQueue removeObject:request];
    [_cond unlock];
    return YES;
}

- (void) updateLatestMonitoredTime:(long)mills {
    if (mills > _latestMonitoredTimeMills)
    {
        _latestMonitoredTimeMills = mills;
    }
}

- (void) checkTimeout:(id)object {
    _latestMonitoredTimeMills = [[NSDate date] timeIntervalSince1970] * 1000;
    
    while (YES)
    {//NSLog(@"Before lock @ checkTimeout");
        [_cond lock];
        {
            [_waitResponseRequestMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, AMBARequest * _Nonnull request, BOOL * _Nonnull stop) {
                long long timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
                if (request.timeout > 0)
                {
                    if (timestamp - request.timestamp > request.timeout)
                    {
                        [_timeoutRequestQueue addObject:request];
                    }
                }
                else if (timestamp - request.timestamp > RESPONSE_TIMEOUT_LIMIT)
                {
                    [_timeoutRequestQueue addObject:request];
                }
            }];
            
            if (_timeoutRequestQueue.count > 0)
            {NSLog(@"Timeout! @ CMDConnectManager");
                for (AMBARequest* request in _timeoutRequestQueue)
                {
                    [_waitResponseRequestMap removeObjectForKey:request.requestKey];
                }
                
                [self handleMessage:kNotificationCmdResponseError arg1:0 arg2:0 object:nil];
            }
            
            [_cond broadcast];
        }
        [_cond unlock];
        
        if ([[NSDate date] timeIntervalSince1970] * 1000 - _latestMonitoredTimeMills > MAX_NON_MONITORED_TIME_INTERVAL_MILLS)
        {
            [self handleMessage:kNotificationRequestHeartbeat arg1:0 arg2:0 object:nil];
        }
        
        [NSThread sleepForTimeInterval:2];
    }
}

- (void) sendMsgViaSocket:(id)object {
    @try
    {
        int state = [self waitForState:(CmdSocketState) (CmdSocketStateReady | CmdSocketStateNotReady | CmdSocketStateDisconnecting | CmdSocketStateReconnectingStep0)];
        if (CmdSocketStateReady != state)
        {
            return;
        }
        
        while (YES)
        {
            AMBARequest* requestItem = nil;
            BOOL shouldPending = NO;
//            NSLog(@"Before lock @ sendMsgViaSocket#0");
            [_cond lock];
            {
                while (!requestItem)
                {
                    while ((_waitSendRequestQueue.count == 0 || shouldPending)
                           && CmdSocketStateNotReady != self.state
                           && CmdSocketStateDisconnecting != self.state
                           && CmdSocketStateReconnectingStep0 != self.state
                           && 0 != _socket)
                    {
                        shouldPending = NO;
                        [_cond wait];
                    }
                    
                    state = self.state;
                    if (CmdSocketStateNotReady == self.state
                        || CmdSocketStateDisconnecting == self.state
                        || CmdSocketStateReconnectingStep0 == self.state
                        || 0 == _socket)
                    {
                        [_cond unlock];
                        return;
                    }
                    
                    // Check if there is any AMBARequest in waitResponseRequestMap that has the same msg_id with it:
                    if (_waitResponseRequestMap.count > 0)
                    {
                        for (AMBARequest* requestToSend in _waitSendRequestQueue)
                        {
                            /*
                             if (requestToSend.shouldWaitUntilPreviousResponded)
                             {
                             boolean notAvailable = false;
                             
                             Iterator<ConcurrentHashMap.Entry<String, AMBARequest>> iterator = waitResponseRequestMap.entrySet().iterator();
                             while (iterator.hasNext())
                             {
                             ConcurrentHashMap.Entry<String, AMBARequest> entry = iterator.next();
                             AMBARequest requestPending = entry.getValue();
                             if (null != requestPending && null != requestToSend)
                             {
                             if (requestPending.getMsg_id() == requestToSend.getMsg_id())
                             {
                             notAvailable = true;
                             break;
                             }
                             }
                             }
                             
                             if (!notAvailable)
                             {
                             requestItem = requestToSend;
                             break;
                             }
                             }
                             else
                             {
                             requestItem = requestToSend;
                             break;
                             }
                             /*/
                            if (!requestToSend.shouldWaitUntilPreviousResponded)
                            {
                                requestItem = requestToSend;
                                break;
                            }
                            //*/
                        }
                    }
                    else
                    {
                        requestItem = [_waitSendRequestQueue firstObject];
                    }
                    
                    shouldPending = (nil == requestItem);
                }
            }
            [_cond unlock];

            NSString* jsonString = [requestItem toJSON];
            const char* cJSONString = [jsonString UTF8String];
            @try
            {
                requestItem.timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
                [_cond lock];
                {
                    [_waitSendRequestQueue removeObject:requestItem];
                    [_waitResponseRequestMap setObject:requestItem forKey:requestItem.requestKey];
                }
                [_cond unlock];
                DoctorLog(@"#Socket# Before send");
                long status = send(_socket, cJSONString, jsonString.length, 0);
                DoctorLog(@"#Socket# After send : request:%s", cJSONString);
                if (status > 0)
                {//NSLog(@"Before lock @ sendMsgViaSocket#1");
                    [_cond lock];
                    {
                        //NSLog(@"Heartbeat updated @ sendMsgViaSocket : %s", cJSONString);
                        [self updateLatestMonitoredTime:(long)requestItem.timestamp];
                        
                        //if (requestItem.ambaResponseError || requestItem.ambaResponseReceived || requestItem.shouldWaitUntilPreviousResponded)
                        //{
                        //    [_waitResponseRequestMap setObject:requestItem forKey:requestItem.requestKey];
                        //}
                    }
                    [_cond unlock];
                    if (requestItem.ambaRequestSent)
                    {
                        requestItem.ambaRequestSent();
                    }
                }
                else
                {
                    [_cond lock];
                    {
                        [_waitResponseRequestMap removeObjectForKey:requestItem.requestKey];
                    }
                    [_cond unlock];
                    
                    NSLog(@"SendRequestRunnable : SocketException #0: ");
                    if (CmdSocketStateReady == self.state)
                    {
                        NSLog(@"SendRequestRunnable : SocketException : reconnect");
#ifdef RECONNECT_ON_BACK_FOREGROUND
                        if (self.justReturnedFromBackground)
                        {
                            NSLog(@"justReturnedFromBackground : sendMsgViaSocket : reconnectAsync");
                            [self reconnectAsync:YES];
                        }
                        else
#endif
                        {
                            NSLog(@"justReturnedFromBackground : sendMsgViaSocket : clearOnDisconnected");
                            [self clearOnDisconnected];
                            self.state = CmdSocketStateNotReady;
                        }
                    }
                    
                    return;
                }
            }
            @catch (NSException *exception)
            {
                NSLog(@"SendRequestRunnable : SocketException #1: %@", exception);
                if (CmdSocketStateReady == self.state)
                {
                    NSLog(@"SendRequestRunnable : SocketException : reconnect");
                    ///!!![self reconnectAsync];
                    [self clearOnDisconnected];
                    self.state = CmdSocketStateNotReady;
                }
                
                return;
            }
            @finally
            {
            }
        }
    }
    @catch (NSException *exception)
    {
    }
    @finally
    {//NSLog(@"Before lock @ sendMsgViaSocket#2");
        [_cond lock];
        _sendMsgThread = nil;
        [_cond broadcast];
        [_cond unlock];
    }
}

- (void) extractJSONAndDispatch:(char*)str strLen:(int)strLen {
    int lastEndIndex = -1;
    int startIndex = 0;
    int leftBrackets = 0;
    BOOL receivedNewResponse = NO;
    for (int i=0; i<strLen; ++i)
    {
        char c = str[i];
        if ('{' == c)
        {
            if (0 == leftBrackets++)
            {
                startIndex = i;
            }
        }
        else if ('}' == c)
        {
            if (0 != leftBrackets && 0 == --leftBrackets)
            {
                if (!receivedNewResponse)
                {
                    receivedNewResponse = YES;
                }
                char nextChar = str[i + 1];
                str[i + 1] = '\0';
                NSString* jsonString = [NSString stringWithCString:str + startIndex encoding:NSASCIIStringEncoding];
                DoctorLog(@"#Socket# jsonString = (%d~%d:%d) '%@'", startIndex, i, i+1-startIndex, jsonString);
                AMBAResponse* baseResponse = [[AMBAResponse.class alloc] init];
                [baseResponse fromJSON:jsonString];
//                NSLog(@"Before lock @ CMDConnectManager.extractJSONAndDispatch#0");
                AMBAResponse* response = nil;
                [_cond lock];
                {
                    AMBARequest* request = [_waitResponseRequestMap objectForKey:baseResponse.requestKey];
                    [_waitResponseRequestMap removeObjectForKey:baseResponse.requestKey];
                    if (request)
                    {
//                        Log.v(TAG, "Request found:" + request + " for response:" + jsonString);
                        Class responseClass = request.responseClass;
                        if (!responseClass) responseClass = AMBAResponse.class;
                        
                        response = [[responseClass alloc] init];
                        [response fromJSON:jsonString];
                        //response = [responseClass mj_objectWithKeyValues:jsonString];
                        [_responseQueue addObject:response];
                        [_responseReceivedRequestMap setObject:request forKey:request.requestKey];
                        
                        [_cond broadcast];///!!! 20160818
                    }
                    else
                    {
//                        Log.v(TAG, "No request for response:" + jsonString);
                        Class responseClass = responseClassOfMsgID((int) baseResponse.msgID);
                        if (!responseClass) responseClass = AMBAResponse.class;
                        
                        response = [[responseClass alloc] init];
                        [response fromJSON:jsonString];
                        //response = [responseClass mj_objectWithKeyValues:jsonString];
                        [_responseQueue addObject:response];
                    }
                }
                [_cond unlock];
                
                NSLog(@"QD:Socket : receivedNewResponse=%d, response=%@", receivedNewResponse, response);
                //                    Log.v(TAG, "After synchronized #0 @ CMDConnectManager.extractJSONAndDispatch");
                str[i + 1] = nextChar;
                lastEndIndex = i;
            }
        }
    }
    
    if (lastEndIndex > 0)
    {
        memcpy(_msgReadBuffer, _msgReadBuffer + lastEndIndex + 1, BUFFER_SIZE - lastEndIndex - 1);
        _msgReadBufferOffset -= (lastEndIndex + 1);
    }
    
    if (receivedNewResponse)
    {
        /*
         Message responseReceivedMsg = mResponseHandler.obtainMessage(MSG_RESPONSE_RECEIVED);
         mResponseHandler.sendMessage(responseReceivedMsg);
         /*/
        [self handleMessage:kNotificationCmdResponseReceived arg1:0 arg2:0 object:nil];
        //*/
    }
}

- (void) receiveMsgViaSocket:(id)object {
    int readSize = 0;
    int state = [self waitForState:(CmdSocketState) (CmdSocketStateReady | CmdSocketStateNotReady | CmdSocketStateDisconnecting | CmdSocketStateReconnectingStep0)];
    if (CmdSocketStateReady != state)
    {
        goto Finally;
    }
    
    do
    {
        @try
        {
            DoctorLog(@"#Socket# Before recv");
            if ((readSize = (int)recv(_socket, _msgReadBuffer + _msgReadBufferOffset, BUFFER_SIZE - _msgReadBufferOffset, 0)) <= 0)
            {
                break;
            }
            DoctorLog(@"#Socket# After recv #0 : response:(strlen=%ld, readSize=%d, offset=%d, len=%d) %s\n", strlen((const char *)_msgReadBuffer + _msgReadBufferOffset), readSize, _msgReadBufferOffset, BUFFER_SIZE - _msgReadBufferOffset, _msgReadBuffer + _msgReadBufferOffset);
        }
        @catch (NSException* exception)
        {
            DoctorLog(@"#Socket# SocketException#1 : %s, exception=%@", strerror(errno), exception);
            break;
        }
        //NSLog(@"Heartbeat updated @ receiveMsgViaSocket : %s", _msgReadBuffer + _msgReadBufferOffset);
        [self updateLatestMonitoredTime:(long)[[NSDate date] timeIntervalSince1970] * 1000];
        _msgReadBuffer[_msgReadBufferOffset + readSize] = '\0';
        DoctorLog(@"#Socket# After recv : response:(strlen=%ld, readSize=%d, offset=%d, len=%d) %s\n", strlen((const char *)_msgReadBuffer + _msgReadBufferOffset), readSize, _msgReadBufferOffset, BUFFER_SIZE - _msgReadBufferOffset, _msgReadBuffer + _msgReadBufferOffset);
        _msgReadBufferOffset += readSize;
        //解析JSON并通知处理
        [self extractJSONAndDispatch:(char*)_msgReadBuffer strLen:_msgReadBufferOffset];
    }
    while (readSize > 0);
    
    @try
    {
        if (CmdSocketStateReady == self.state)
        {
            NSLog(@"receiveMsgViaSocket # Finally reconnectAsync");
#ifdef RECONNECT_ON_BACK_FOREGROUND
            if (self.justReturnedFromBackground)
            {
                NSLog(@"justReturnedFromBackground : recvMsgViaSocket : reconnectAsync");
                [self reconnectAsync:YES];
            }
            else
#endif
            {
                NSLog(@"justReturnedFromBackground : recvMsgViaSocket : clearOnDisconnected");
                [self clearOnDisconnected];
                self.state = CmdSocketStateNotReady;
            }
        }
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception in receiveMsgViaSocket : %@", exception);
        goto Finally;
    }
    
Finally:
    [_cond lock];
    _receiveMsgThread = nil;
    [_cond broadcast];
    [_cond unlock];
}

- (void) onReceiveCameraResponse:(AMBAResponse*)response {
    NSArray<id<CMDConnectionObserver> >* copiedObservers = [NSArray arrayWithArray:_observers];
    for (id<CMDConnectionObserver> observer in copiedObservers)
    {
        if (observer && [observer respondsToSelector:@selector(cmdConnectionReceiveCameraResponse:)])
        {
            [observer cmdConnectionReceiveCameraResponse:response];
        }
    }
}

- (void) onRequestHeartbeat {
    NSArray<id<CMDConnectionObserver> >* copiedObservers = [NSArray arrayWithArray:_observers];
    for (id<CMDConnectionObserver> observer in copiedObservers)
    {
        if (observer && [observer respondsToSelector:@selector(cmdConnectionHeartbeatRequired)])
        {
            [observer cmdConnectionHeartbeatRequired];
        }
    }
}

- (void) onResponseReceived {
    AMBAResponse* responseItem = [_responseQueue poll];
    NSLog(@"QD:Socket onResponseReceived # responseItem=%@", responseItem);
    while (responseItem)
    {
        AMBARequest* requestItem = nil;
        [_cond lock];
        {
            requestItem = [_responseReceivedRequestMap objectForKey:responseItem.requestKey];
            [_responseReceivedRequestMap removeObjectForKey:responseItem.requestKey];
        }
        [_cond unlock];
        NSLog(@"QD:Socket onResponseReceived # requestItem=%@", requestItem);
        if (requestItem && requestItem.ambaResponseReceived)
        {
            requestItem.ambaResponseReceived(responseItem);
        }
        else
        {
            [self onReceiveCameraResponse:responseItem];
        }
        
        responseItem = [_responseQueue poll];
    }
//    NSLog(@"Before lock @ onResponseReceived");
    [_cond lock];
    [_cond broadcast];
    [_cond unlock];
}

- (void) onResponseError {
    if (_timeoutRequestQueue)
    {
        AMBARequest* requestItem = [_timeoutRequestQueue poll];
        while (requestItem)
        {
            if (nil != requestItem.ambaResponseError)
            {
                requestItem.ambaResponseError(requestItem, AMBARequestErrorTimeout, @"TimeOut");
            }
            
            requestItem = [_timeoutRequestQueue poll];
        }
    }
    
    if (_exceptionRequestQueue)
    {
        AMBARequest* requestItem = [_exceptionRequestQueue poll];
        while (requestItem)
        {
            if (nil != requestItem.ambaResponseError)
            {
                requestItem.ambaResponseError(requestItem, AMBARequestErrorException, @"Exception");
            }
            
            requestItem = [_exceptionRequestQueue poll];
        }
    }
}

- (void) onStateChanged:(int)newState oldState:(int)oldState object:(id)object {
    NSArray<id<CMDConnectionObserver> >* copiedObservers = [NSArray arrayWithArray:_observers];
    for (id<CMDConnectionObserver> observer in copiedObservers)
    {
        if (observer && [observer respondsToSelector:@selector(cmdConnectionStateChanged:oldState:object:)])
        {
            [observer cmdConnectionStateChanged:(CmdSocketState)newState oldState:(CmdSocketState)oldState object:object];
        }
    }
}

- (void) didWiFiConnected {
    
}

- (void) didWiFiDisconnected {
    if (_socket > 0)
        close(_socket);
}

@end
