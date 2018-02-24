//
//  WiFiConnectManager.h
//  Madv360_v1
//  辅助工具类WiFiConnectManager
//  Created by 张巧隔 on 16/9/6.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WiFiConnectManager;

/** WiFi状态观察者 */
@protocol WiFiObserver <NSObject>

- (void) didWiFiConnected;

- (void) didWiFiDisconnected;

@end

/** 单例类WiFiConnectManager，封装了与WiFi状态监视相关的方法 */
@interface WiFiConnectManager : NSObject

+ (instancetype) sharedInstance;

- (void) addWiFiObserver:(id<WiFiObserver>)observer;
- (void) removeWiFiObserver:(id<WiFiObserver>)observer;

/** 跳转到系统WiFi设置页（在iOS10以上可能失效）*/
+ (void) jumpToWiFiSettings;

/** WiFi是否连接 */
- (BOOL) isWiFiReachable;

+ (NSDictionary*) wifiInfo;

/** 手机在当前连接的WiFi局域网中所分配的IP地址 */
+ (NSString*) wifiClientIP;

/** 当前连接WiFi的SSID */
+ (NSString*) wifiSSID;

@end
