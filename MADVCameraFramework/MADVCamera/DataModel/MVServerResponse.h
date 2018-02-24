//
//  MVServerResponse.h
//  Madv360_v1
//
//  Created by QiuDong on 16/4/29.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MJExtension/MJExtension.h>

@interface MVServerResponse : NSObject

@property (nonatomic, assign) int ret;

@property (nonatomic, copy) NSString* errmsg;

@property (nonatomic, copy) id result;

@end
