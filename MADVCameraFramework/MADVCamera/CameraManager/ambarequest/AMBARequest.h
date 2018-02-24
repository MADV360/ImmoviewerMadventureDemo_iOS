//
//  AMBARequest.h
//  Madv360_v1
//  与AMBA进行TCP通信的请求对象基类
//  Created by DOM QIU on 16/9/5.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <MJExtension/MJExtension.h>
#import "JSONSerializableObject.h"

@class AMBAResponse;
@class AMBARequest;

///** TCP请求的响应回调接口
// *
// */
//@protocol AMBAResponseListener <NSObject>
//
///** 当接收到响应时 */
//- (void) ambaResponseReceived:(AMBAResponse*)response;
//
///** 当发送请求或接收响应中任一环节发生错误时（一般是通信超时） */
//- (void) ambaResponseError:(AMBARequest*)request error:(int)error msg:(NSString*)msg;
//
//@end

typedef enum : NSInteger {
    AMBARequestErrorTimeout = 10000,
    AMBARequestErrorException = 10001,
} AMBARequestError;

typedef void (^AMBAResponseReceivedBlock)(AMBAResponse* response);
typedef void (^AMBAResponseErrorBlock)(AMBARequest* response, int error, NSString* msg);

@interface AMBARequest : JsonSerializableObject

@property (nonatomic, strong) AMBAResponseReceivedBlock ambaResponseReceived;

@property (nonatomic, strong) AMBAResponseErrorBlock ambaResponseError;

@property (nonatomic, strong) dispatch_block_t ambaRequestSent;

#pragma mark    Constructors

/** 以回调对象和响应的类型（继承自AMBAResponse的类）初始化请求对象 */
- (instancetype) initWithReceiveBlock:(AMBAResponseReceivedBlock) receiveBlock errorBlock:(AMBAResponseErrorBlock)errorBlock responseClass:(Class)responseClass;

/** 以回调对象和AMBAResponse.class初始化请求对象 */
- (instancetype) initWithReceiveBlock:(AMBAResponseReceivedBlock)receiveBlock errorBlock:(AMBAResponseErrorBlock)errorBlock;

#pragma mark    JSON Fields

// JSON请求报文中的字段:msgID
@property (nonatomic, assign) NSInteger msgID;

// JSON请求报文中的字段:token
@property (nonatomic, assign) NSInteger token;

// JSON请求报文中的字段:type（可选）
@property (nonatomic, copy) NSString* type;

// JSON请求报文中的字段:param（可选）
@property (nonatomic, copy) NSString* param;

// JSON请求报文中的字段:btwifi
@property (nonatomic, assign) NSInteger btwifi;


#pragma mark    Public Methods & Properties

// 如果存在有相同msgID的请求对象尚未得到响应，是否应该等待其响应完毕再发送本次请求。默认值为YES
@property (nonatomic, assign) BOOL shouldWaitUntilPreviousResponded;

#pragma mark    Visible To SDK Only

@property (nonatomic, assign) long long timestamp;

@property (nonatomic, copy, readonly) NSString* requestKey;

// 响应对象的类别（isKindOf AMBAResponse.class）
@property (nonatomic, strong, readonly) Class responseClass;

@property (nonatomic, assign) long timeout;

@end
