//
//  RealmQueue.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/10/9.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "RealmSerialQueue.h"
#import "NSRecursiveCondition.h"
#import "NSMutableArray+Extensions.h"

@interface AsyncBlockTask : NSObject
{
    BOOL _isFinished;
    dispatch_block_t _block;
    NSThread* _myThread;
}

@property (nonatomic, assign) BOOL isFinished;
@property (nonatomic, strong) dispatch_block_t block;

- (instancetype) initWithBlock:(dispatch_block_t)block;

- (void) waitForFinishing:(NSRecursiveCondition*)cond;

@end

@implementation AsyncBlockTask

@synthesize isFinished = _isFinished;
@synthesize block = _block;

- (instancetype) initWithBlock:(dispatch_block_t)block {
    if (self = [super init])
    {
        _isFinished = NO;
        _block = block;
        _myThread = [NSThread currentThread];
        //DoctorLog(@"#RLMDeadLock# AsyncBlockTask(%lx) init : @thread(%lx)", (NSUInteger)self.hash, (NSUInteger)_myThread.hash);
    }
    return self;
}

- (void) waitForFinishing:(NSRecursiveCondition*)cond {
    //DoctorLog(@"#RLMDeadLock# AsyncBlockTask(%lx) waitForFinishing#0 : @thread(%lx) @cond(%lx)", (NSUInteger)self.hash, (NSUInteger)_myThread.hash, (NSUInteger)cond.hash);
    [cond lock];
    {
        while (!_isFinished)
        {
            ///DoctorLog(@"#RLMDeadLock# AsyncBlockTask(%lx) waitForFinishing#1 : Waiting @thread(%lx) @cond(%lx)", (NSUInteger)self.hash, (NSUInteger)_myThread.hash, (NSUInteger)cond.hash);
            [cond wait];
            //DoctorLog(@"#RLMDeadLock# AsyncBlockTask(%lx) waitForFinishing#2 : Notified @thread(%lx) @cond(%lx)", (NSUInteger)self.hash, (NSUInteger)_myThread.hash, (NSUInteger)cond.hash);
        }
    }
    //DoctorLog(@"#RLMDeadLock# AsyncBlockTask(%lx) waitForFinishing#3 : Return @thread(%lx) @cond(%lx)", (NSUInteger)self.hash, (NSUInteger)_myThread.hash, (NSUInteger)cond.hash);
    [cond unlock];
}

@end

@interface RealmSerialQueue ()
{
    NSThread* _thread;
    NSRecursiveCondition* _cond;
    NSMutableArray<AsyncBlockTask*>* _tasks;
    BOOL _isRunning;
}

@end


@implementation RealmSerialQueue

- (void) dealloc {
    [self finish];
}

- (instancetype) init {
    if (self = [super init])
    {
        _tasks = [[NSMutableArray alloc] init];
        _isRunning = YES;
        _cond = [[NSRecursiveCondition alloc] init];
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(process:) object:nil];
        _thread.name = @"RealmSerailQueue";
        //DoctorLog(@"#RLMDeadLock# RealmSerialQueue init : _thread=(%lx) _cond=(%lx)", (NSUInteger)_thread.hash, (NSUInteger)_cond.hash);
        [_thread start];
    }
    return self;
}

+ (id)shareRealmQueue
{
    static dispatch_once_t once;
    static RealmSerialQueue* instance = nil;
    dispatch_once(&once, ^{
        if (instance == nil)
        {
            instance = [[RealmSerialQueue alloc] init];
            instance.realmQueue = dispatch_queue_create("Realm", DISPATCH_QUEUE_SERIAL);
        }
    });
    return instance;
}

- (void) addTask:(AsyncBlockTask*)task {
    //NSArray* callbackStacktrace = [NSThread callStackSymbols];
    //NSLog(@"#RLMDeadLock# addTask #0");/// in %@", callbackStacktrace);
    //DoctorLog(@"#RLMDeadLock# RealmSerialQueue addTask#0 : task=(%lx) @thread(%lx)", (NSUInteger)task.hash, (NSUInteger)[NSThread currentThread].hash);
    [_cond lock];
    {
        //NSLog(@"#RLMDeadLock# addTask #1 : cond=%@", _cond);
        //DoctorLog(@"#RLMDeadLock# RealmSerialQueue addTask#1 : _tasks.count=%ld, task=(%lx) @thread(%lx)", _tasks.count, (NSUInteger)task.hash, (NSUInteger)[NSThread currentThread].hash);
        [_tasks addObject:task];
        //NSLog(@"#RLMDeadLock# addTask #2 : _tasks(%lx).count = %d, task = %@", (long)_tasks.hash, (int)_tasks.count, task);
        //DoctorLog(@"#RLMDeadLock# RealmSerialQueue addTask#2 : _tasks.count=%ld, task=(%lx) @thread(%lx)", _tasks.count, (NSUInteger)task.hash, (NSUInteger)[NSThread currentThread].hash);
        [_cond broadcast];
        //NSLog(@"#RLMDeadLock# addTask #3");
    }
    [_cond unlock];
    //DoctorLog(@"#RLMDeadLock# RealmSerialQueue addTask#3 : _tasks.count=%ld, task=(%lx) @thread(%lx)", _tasks.count, (NSUInteger)task.hash, (NSUInteger)[NSThread currentThread].hash);
}

- (void)async:(dispatch_block_t)asyncblock
{
#ifndef DEBUG_DISABLE_REALM
    AsyncBlockTask* task = [[AsyncBlockTask alloc] initWithBlock:asyncblock];
    [self addTask:task];
#else
    asyncblock();
#endif
}

- (void)sync:(dispatch_block_t)syncblock
{
#ifndef DEBUG_DISABLE_REALM
    NSThread* realmThread = [[RealmSerialQueue shareRealmQueue] myThread];
    NSThread* currentThread = [NSThread currentThread];
    if (realmThread == currentThread)
    {
#endif
        syncblock();
#ifndef DEBUG_DISABLE_REALM
    }
    else
    {
        AsyncBlockTask* task = [[AsyncBlockTask alloc] initWithBlock:syncblock];
        [self addTask:task];
        [task waitForFinishing:_cond];
    }
#endif
}

- (void) finish {
    //DoctorLog(@"#RLMDeadLock# RealmSerialQueue finish#0 : _tasks.count=%ld, @thread(%lx)", _tasks.count, (NSUInteger)[NSThread currentThread].hash);
    [_cond lock];
    {
        _isRunning = NO;
        [_cond broadcast];
    }
    [_cond unlock];
}

- (void) process:(id)object {
    while (_isRunning)
    {
        AsyncBlockTask* task = nil;
        [_cond lock];
        {
            while (_isRunning && _tasks.count == 0)
            {
                //DoctorLog(@"#RLMDeadLock# RealmSerialQueue process#1 : Waiting _tasks.count=%ld, _isRunning=%d, @thread(%lx)", _tasks.count, _isRunning, (NSUInteger)[NSThread currentThread].hash);
                //NSLog(@"#RLMDeadLock# wait #0, _isRunning=%d, _tasks(%lx).count=%d", _isRunning, (long)_tasks.hash, (int)_tasks.count);
                [_cond wait];
                //DoctorLog(@"#RLMDeadLock# RealmSerialQueue process#2 : Notified _tasks.count=%ld, _isRunning=%d, @thread(%lx)", _tasks.count, _isRunning, (NSUInteger)[NSThread currentThread].hash);
            }
            //NSLog(@"#RLMDeadLock# After wait #1");
            //DoctorLog(@"#RLMDeadLock# RealmSerialQueue process#2 : New loop begin _tasks.count=%ld, _isRunning=%d, @thread(%lx)", _tasks.count, _isRunning, (NSUInteger)[NSThread currentThread].hash);
            
            if (!_isRunning)
            {
                //DoctorLog(@"#RLMDeadLock# RealmSerialQueue process#3: Will finish _tasks.count=%ld, _isRunning=%d, @thread(%lx)", _tasks.count, _isRunning, (NSUInteger)[NSThread currentThread].hash);
                for (AsyncBlockTask* task in _tasks)
                {
//                    NSLog(@"RLMDeadLock : process In Bunch Waking up @ %@", task);
                    task.isFinished = YES;
                }
                [_cond broadcast];
                
                [_cond unlock];
                break;
            }
            
            task = [_tasks poll];
        }
        [_cond unlock];
        
        if (task)
        {
            if (task.block)
            {
                @try
                {//DoctorLog(@"#RLMDeadLock# RealmSerialQueue process#4 : Begin another task(%lx),  _tasks.count=%ld, _isRunning=%d, @thread(%lx)", task.hash, _tasks.count, _isRunning, (NSUInteger)[NSThread currentThread].hash);
                    //NSLog(@"#RLMDeadLock# task.block() in %s", __PRETTY_FUNCTION__);
                    task.block();
                }
                @catch (NSException *exception)
                {
                    //NSLog(@"#RLMDeadLock# Exception : %@", exception);
                    //DoctorLog(@"#RLMDeadLock# RealmSerialQueue process#Exception : '%@' @task(%lx) _tasks.count=%ld, _isRunning=%d, @thread(%lx)", exception, task.hash, _tasks.count, _isRunning, (NSUInteger)[NSThread currentThread].hash);
                }
                @finally
                {
                    
                }
            }
            
            [_cond lock];
            {
                task.isFinished = YES;
                //NSLog(@"#RLMDeadLock# process Waking up @ %@, cond=%@", task, _cond);
                //DoctorLog(@"#RLMDeadLock# RealmSerialQueue process#6 : Waking up task(%lx) _tasks.count=%ld, _isRunning=%d, @thread(%lx)", task.hash, _tasks.count, _isRunning, (NSUInteger)[NSThread currentThread].hash);
                [_cond broadcast];
            }
            [_cond unlock];
        }
    }
    //DoctorLog(@"#RLMDeadLock# RealmSerialQueue process#!!! : _tasks.count=%ld, @thread(%lx)", _tasks.count, (NSUInteger)[NSThread currentThread].hash);
}

- (NSThread*) myThread {
    return _thread;
}

+ (void) test {
    RealmSerialQueue* queue = [RealmSerialQueue shareRealmQueue];
    __block int number = 0;
    for (int i=0; i<1048576; ++i)
    {
        int prevNumber = number;
        [queue async:^{
            number += i;
        }];
        if (number - prevNumber == i)
        {
            NSLog(@"Passed. number=%d, prevNumber=%d, i=%d", number, prevNumber, i);
        }
        else
        {
            NSLog(@"Failed!");
            exit(-17);
        }
    }
}

@end
