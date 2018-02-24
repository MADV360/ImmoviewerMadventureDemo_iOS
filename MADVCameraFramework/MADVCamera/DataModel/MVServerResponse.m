//
//  MVServerResponse.m
//  Madv360_v1
//
//  Created by QiuDong on 16/4/29.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVServerResponse.h"

@implementation MVServerResponse

+ (NSDictionary*) mj_replacedKeyFromPropertyName {
    return @{@"ret":@"ret", @"errmsg":@"errmsg", @"result":@"result"};
}

@end
