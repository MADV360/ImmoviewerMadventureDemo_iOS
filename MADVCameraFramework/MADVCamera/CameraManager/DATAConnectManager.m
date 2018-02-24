//
//  DATAConnectManager.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/9/7.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "DATAConnectManager.h"
#import "SocketHelper.h"
#import <sys/socket.h>
#import "NSRecursiveCondition.h"

// Handler Messages :
#define MSG_STATE_CHANGED  10
#define MSG_RECEIVE_ERROR  12
#define MSG_RECEIVE_TIMEOUT  13
#define MSG_RECEIVER_EMPTIED  14

//连接重试次数
#define SOCKET_RETRY_TIMES_LIMIT  2
#define RECEIVE_TIMEOUT_LIMIT  10000
#define BUFFER_SIZE  1048576

@implementation DataReceiver

@synthesize recentReceiveTime;

- (instancetype) init {
    if (self = [super init])
    {
        self.recentReceiveTime = -1;
    }
    return self;
}

- (void) finish {
    [[DATAConnectManager sharedInstance] removeDataReceiver:self];
}

- (int) didReceiveData:(UInt8*)data offset:(int)offset length:(int)length {
    self.recentReceiveTime = [[NSDate date] timeIntervalSince1970] * 1000;
    return [self onReceiveData:data offset:offset length:length];
}

- (int) onReceiveData:(UInt8*)data offset:(int)offset length:(int)length {return 0;}

- (void) onError:(int)error errMsg:(NSString*)errMsg {}

- (BOOL) isFinished {return YES;}

@end

@interface DATAConnectManager ()
{
    NSRecursiveCondition* _cond;
    
    DataReceiver* _currentDataReceiver;
    
    NSString* _serverIP;
    int _serverPort;
    
    int _connTimeout;
    
    DataSocketState _connState;
    
    int _socket;
    
    Byte* _receiveBuffer;
    
    NSThread* _timeoutCheckThread;
    NSThread* _receiveDataThread;
    
    NSMutableArray<id<DataConnectionObserver> >* _observers;
}

@end

@implementation DATAConnectManager

+ (instancetype) sharedInstance {
    static dispatch_once_t once;
    static DATAConnectManager* singleton = nil;
    dispatch_once(&once, ^{
        singleton = [[DATAConnectManager alloc] init];
    });
    return singleton;
}

- (void) dealloc {
    if (_receiveBuffer) free(_receiveBuffer);
}

- (instancetype) init {
    if (self = [super init])
    {
        _cond = [[NSRecursiveCondition alloc] init];
        
        _serverIP = AMBA_CAMERA_IP;
        _serverPort = AMBA_CAMERA_DATA_PORT;
        _connTimeout = AMBA_CAMERA_TIMEOUT;
        
        _receiveBuffer = (Byte*)malloc(BUFFER_SIZE);
        
        _observers = [[NSMutableArray alloc] init];
        _connState = DataSocketStateNotReady;
    }
    return self;
}

- (DataSocketState) state {
    return _connState;
}

- (void) setState:(DataSocketState)state {
    [_cond lock];
    {
        int oldState = _connState;
        [self willChangeValueForKey:@"state"];
        _connState = state;
        [self didChangeValueForKey:@"state"];
        [_cond broadcast];
        
        [self notifyStateChanged:state oldState:(DataSocketState)oldState object:self];
    }
    [_cond unlock];
}

- (int) waitForState:(int)stateCombo {
    [_cond lock];
    {
        while ((stateCombo != 0 || _connState != 0) && ((stateCombo & _connState) == 0))
        {
            [_cond wait];
        }
    }
    [_cond unlock];
    return _connState;
}

- (void) addObserver:(id<DataConnectionObserver>)observer {
    [_observers addObject:observer];
}

- (void) removeObserver:(id<DataConnectionObserver>)observer {
    [_observers removeObject:observer];
}

- (DataReceiver*) removeDataReceiver {
    return [self removeDataReceiver:_currentDataReceiver];
}

- (DataReceiver*) removeDataReceiver:(DataReceiver *)receiver {
    DataReceiver* ret = nil;
    [_cond lock];
    {
        if (_currentDataReceiver == receiver)
        {
            ret = _currentDataReceiver;
            _currentDataReceiver = nil;
            [_cond broadcast];
            
            [self sendMessage:MSG_RECEIVER_EMPTIED arg1:0 arg2:0 object:nil];
        }
    }
    [_cond unlock];
    return ret;
}

- (void) setDataReceiver:(DataReceiver *)dataReceiver {
    [_cond lock];
    {
        dataReceiver.recentReceiveTime = [[NSDate date] timeIntervalSince1970] * 1000;
        _currentDataReceiver = dataReceiver;
        [_cond broadcast];
    }
    [_cond unlock];
}

- (DataReceiver*) dataReceiver {
    return _currentDataReceiver;
}

- (void) openConnection {
    switch (self.state)
    {
        case DataSocketStateConnecting:
        case DataSocketStateReady:
            return;
        case DataSocketStateDisconnecting:
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self waitForState:DataSocketStateNotReady];
                self.state = DataSocketStateConnecting;
                [self open];
            });
        }
            break;
        case DataSocketStateNotReady:
        {
            self.state = DataSocketStateConnecting;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self open];
            });
        }
            break;
        default:
            break;
    }
}

- (void) closeConnection {
    switch (self.state)
    {
        case DataSocketStateDisconnecting:
        case DataSocketStateNotReady:
            return;
        case DataSocketStateConnecting:
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self waitForState:DataSocketStateReady];
                self.state = DataSocketStateDisconnecting;
                [self close:DataSocketStateNotReady];
            });
        }
            break;
        case DataSocketStateReady:
        {
            self.state = DataSocketStateDisconnecting;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self close:DataSocketStateNotReady];
            });
        }
            break;
        default:
            break;
    }
}

- (BOOL) isConnected {
    return ((DataSocketStateReady == self.state)
            && _receiveDataThread
            && _receiveDataThread.isExecuting);
}

- (void) open {
    __block int retryTimes = 0;
    __block BOOL success = NO;
    while (retryTimes < SOCKET_RETRY_TIMES_LIMIT && self.state != DataSocketStateDisconnecting)
    {
        connectServer(_serverIP, _serverPort, ^id(id responseObject, NSError* error, NSString* errMsg) {
            if (error)
            {
                [NSThread sleepForTimeInterval:0.6];
                retryTimes++;
                success = NO;
            }
            else
            {
                _socket = [responseObject intValue];
                success = YES;
            }
            
            return nil;
        }, -1);
        
        if (success)
        {
            _receiveDataThread = [[NSThread alloc] initWithTarget:self selector:@selector(receiveDataViaSocket:) object:nil];
            [_receiveDataThread start];
            
            if (!_timeoutCheckThread)
            {
                _timeoutCheckThread = [[NSThread alloc] initWithTarget:self selector:@selector(timeoutCheck:) object:nil];
                [_timeoutCheckThread start];
            }
            
            if (DataSocketStateDisconnecting != self.state)
            {
                self.state = DataSocketStateReady;
            }
            
            return;
        }
    }
    
    if (DataSocketStateDisconnecting != self.state)
    {
        self.state = DataSocketStateNotReady;
    }
}

- (void) close:(int)destState {
    @try
    {
        if (DataSocketStateNotReady != self.state)
        {
            if (_socket != 0)
            {
                disconnect(_socket, ^id(id responseObject, NSError *error, NSString *errMsg) {
                    _socket = 0;
                    return nil;
                });
            }
            
            [_cond lock];
            {
                while (_receiveDataThread)
                {
                    [_cond wait];
                }
                
                while (_timeoutCheckThread)
                {
                    [_cond wait];
                }
            }
            [_cond unlock];
        }
    }
    @catch (NSException *exception)
    {
        
    }
    @finally
    {
        self.state = (DataSocketState)destState;
        [self removeDataReceiver];
    }
}

- (void) timeoutCheck:(id)object {
    @try
    {
        int state = [self waitForState:(DataSocketStateNotReady | DataSocketStateReady)];
        if (DataSocketStateReady != state)
        {
            return;
        }
        
        while (YES)
        {
            [_cond lock];
            {
                while (!_currentDataReceiver && DataSocketStateReady == self.state)
                {
                    [_cond wait];
                }
                
                if (DataSocketStateReady != self.state)
                {
                    [_cond unlock];
                    return;
                }
                
                NSTimeInterval nowSeconds = [[NSDate date] timeIntervalSince1970];
                if (_currentDataReceiver.recentReceiveTime > 0
                    && nowSeconds * 1000 - _currentDataReceiver.recentReceiveTime > RECEIVE_TIMEOUT_LIMIT)
                {
                    NSLog(@"#DataConnectManager# TimeOut? _currentDataReceiver.recentReceiveTime=%lld, now=%lld", (long long)_currentDataReceiver.recentReceiveTime, (long long)(nowSeconds * 1000));
                    [self sendMessage:MSG_RECEIVE_TIMEOUT arg1:0 arg2:0 object:_currentDataReceiver];
                    
                    _currentDataReceiver = nil;
                    [self sendMessage:MSG_RECEIVER_EMPTIED arg1:0 arg2:0 object:nil];
                    
                    [_cond unlock];
                    return;
                }
            }
            [_cond unlock];
            
            [NSThread sleepForTimeInterval:5.0f];
        }
    }
    @catch (NSException *exception)
    {
        
    }
    @finally
    {
        [_cond lock];
        {
            _timeoutCheckThread = nil;
            [_cond broadcast];
        }
        [_cond unlock];
    }
}

- (void) receiveDataViaSocket:(id)object {
    int readSize = 0;
//    @try
//    {
        int state = [self waitForState:(DataSocketStateReady | DataSocketStateDisconnecting | DataSocketStateNotReady)];
        if (DataSocketStateReady != state)
        {
            //goto Finally;
            [_cond lock];
            {
                _receiveDataThread = nil;
                [_cond broadcast];
            }
            [_cond unlock];
            return;
        }
        
        do
        {
//            @try
//            {
                if ((readSize = (int)recv(_socket, _receiveBuffer, BUFFER_SIZE, 0)) <= 0)
                {
                    NSLog(@"Break on readSize = %d", readSize);
                    break;
                }
            //NSLog(@"Receive readSize = %d", readSize);
//            }
//            @catch (NSException *exception)
//            {
//                break;
//            }
//            @finally
//            {
//                break;
//            }
            
            [_cond lock];
            {
                if (_currentDataReceiver)
                {
                    [_currentDataReceiver didReceiveData:_receiveBuffer offset:0 length:readSize];
                    
                    if (_currentDataReceiver && _currentDataReceiver.isFinished)
                    {
                        [self removeDataReceiver];
                    }
                }
            }
            [_cond unlock];
        }
        while (readSize > 0);
        
        //            [_cond unlock];///!!!
        [self closeConnection];
        DataReceiver* receiver = [self removeDataReceiver];
        [self sendMessage:MSG_RECEIVE_ERROR arg1:0 arg2:0 object:receiver];
    
    goto Finally;
//    }
//    @catch (NSException *exception)
//    {
//        
//    }
//    @finally
Finally:
    {
        [_cond lock];
        {
            _receiveDataThread = nil;
            [_cond broadcast];
        }
        [_cond unlock];
    }
}

- (void) notifyStateChanged:(DataSocketState)newState oldState:(DataSocketState)oldState object:(id)object {
    [self sendMessage:MSG_STATE_CHANGED arg1:newState arg2:oldState object:object];
}

- (void) sendMessage:(int)what arg1:(int)arg1 arg2:(int)arg2 object:(id)object {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleMessage:what arg1:arg1 arg2:arg2 object:object];
    });
}

- (void) handleMessage:(int)what arg1:(int)arg1 arg2:(int)arg2 object:(id)object {
    switch (what)
    {
        case MSG_STATE_CHANGED:
        {
            [self onStateChanged:arg1 oldState:arg2 object:object];
        }
            break;
        case MSG_RECEIVE_ERROR:
        {
            DataReceiver* receiver = (DataReceiver*) object;
            if (receiver && [receiver respondsToSelector:@selector(onError:errMsg:)])
            {
                [receiver onError:DataSocketErrorException errMsg:@"SocketError"];
            }
        }
            break;
        case MSG_RECEIVE_TIMEOUT:
        {
            DataReceiver* receiver = (DataReceiver*) object;
            if (receiver && [receiver respondsToSelector:@selector(onError:errMsg:)])
            {
                [receiver onError:DataSocketErrorTimeout errMsg:@"ReceivingTimeOut"];
            }
        }
            break;
        case MSG_RECEIVER_EMPTIED:
        {
            [self onReceiverEmptied];
        }
            break;
        default:
            break;
    }
}

- (void) onStateChanged:(int)newState oldState:(int)oldState object:(id)object {
    for (id<DataConnectionObserver> observer in _observers)
    {
        if ([observer respondsToSelector:@selector(onDataConnectionStateChanged:oldState:object:)])
        {
            [observer onDataConnectionStateChanged:newState oldState:oldState object:object];
        }
    }
}

- (void) onReceiverEmptied {
    for (id<DataConnectionObserver> observer in _observers)
    {
        if ([observer respondsToSelector:@selector(onReceiverEmptied)])
        {
            [observer onReceiverEmptied];
        }
    }
}

- (int) socket {
    [self openConnection];
    if (DataSocketStateReady == [self waitForState:DataSocketStateReady])
        return _socket;
    else
        return 0;
}

@end
