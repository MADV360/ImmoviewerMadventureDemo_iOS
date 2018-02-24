//
//  AMBAResponse.h
//  Madv360_v1
//  与AMBA进行TCP通信的响应对象基类
//  Created by DOM QIU on 16/9/5.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

//#import <MJExtension/MJExtension.h>
#import "JSONSerializableObject.h"

@interface AMBAResponse : JsonSerializableObject

#pragma mark    JSON Fields

@property (nonatomic, assign) NSInteger token;

@property (nonatomic, assign) NSInteger rval;

@property (nonatomic, assign) NSInteger msgID;

@property (nonatomic, copy) NSString* type;

@property (nonatomic, strong) id param;

#pragma mark    Public Methods & Properties

@property (nonatomic, copy) NSString* requestKey;

- (BOOL) isRvalOK;

@end
