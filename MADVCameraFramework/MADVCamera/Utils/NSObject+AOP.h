//
//  NSObject+AOP.h
//  01-AOP编程
//
//  Created by  on 15/11/20.
//  Copyright (c) 2015年  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (AOP)

//交换类方法
+(void)aop_exchangeMethodIMP:(SEL)oldSelector newSelector:(SEL)newSelector;

//交换对象方法
+(void)aop_exchangeObjectMethodIMP:(SEL)oldSelector newSelector:(SEL)newSelector;

@end
