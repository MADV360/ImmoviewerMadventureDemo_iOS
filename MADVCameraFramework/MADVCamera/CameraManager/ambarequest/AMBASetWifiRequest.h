//
//  AMBASetWifiRequest.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/9/7.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBARequest.h"

@interface AMBASetWifiRequest : AMBARequest

@property(nonatomic,copy)NSString * ssid;
@property(nonatomic,copy)NSString * passwd;

@end
