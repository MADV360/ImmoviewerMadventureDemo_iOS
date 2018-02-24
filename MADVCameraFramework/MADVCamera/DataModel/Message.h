//
//  Message.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/10/14.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MessageDetail.h"

@interface Message : NSObject
@property(nonatomic,strong)MessageDetail * msg;
@property(nonatomic,copy)NSString * sendtime;
@end
