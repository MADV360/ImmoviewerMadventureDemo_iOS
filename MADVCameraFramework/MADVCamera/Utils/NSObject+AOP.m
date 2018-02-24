//
//  NSObject+AOP.m
//
//  Created by  on 15/11/20.
//  Copyright (c) 2015年All rights reserved.
//

#import "NSObject+AOP.h"
#import <objc/runtime.h>

@implementation NSObject (AOP)

+(void)aop_exchangeMethodIMP:(SEL)oldSelector newSelector:(SEL)newSelector
{
    Method oldMethod =  class_getClassMethod([self class], oldSelector);
    Method newMethod =  class_getClassMethod([self class], newSelector);
    //class_getClassMethod(<#__unsafe_unretained Class cls#>, <#SEL name#>)
    //交换了两个方法的志向地址
    method_exchangeImplementations(oldMethod, newMethod);
}
//交换对象方法
+(void)aop_exchangeObjectMethodIMP:(SEL)oldSelector newSelector:(SEL)newSelector
{
    Method oldMethod =  class_getInstanceMethod([self class], oldSelector);
    Method newMethod =  class_getInstanceMethod([self class], newSelector);
    
    //交换了两个方法的志向地址
    method_exchangeImplementations(oldMethod, newMethod);
}

@end
