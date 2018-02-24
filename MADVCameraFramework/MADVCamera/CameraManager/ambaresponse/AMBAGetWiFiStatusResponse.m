//
//  AMBAGetWiFiStatusResponse.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/9/6.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAGetWiFiStatusResponse.h"

@implementation AMBAGetWiFiStatusResponse

- (NSString*) MAC {
    NSDictionary* dict = (NSDictionary*) self.param;
    return dict[@"MAC"];
}

- (NSString*) SSID {
    NSDictionary* dict = (NSDictionary*) self.param;
    return dict[@"SSID"];
}

@end
