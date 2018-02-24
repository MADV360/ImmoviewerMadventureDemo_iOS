//
//  MessageResponse.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/10/14.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MessageResponse.h"
#import "Message.h"

@implementation MessageResponse
+ (NSDictionary*) mj_objectClassInArray {
    return @{@"result":Message.class};
}
@end
