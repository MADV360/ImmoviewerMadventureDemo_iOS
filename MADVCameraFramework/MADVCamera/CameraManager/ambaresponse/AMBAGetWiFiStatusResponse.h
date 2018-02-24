//
//  AMBAGetWiFiStatusResponse.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/9/6.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"

@interface AMBAGetWiFiStatusResponse : AMBAResponse
- (NSString *)MAC;
- (NSString *)SSID;
@end
