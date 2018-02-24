//
//  WiFiConnectManager.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/9/6.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "WiFiConnectManager.h"
#import "MyReachability.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#import "MVCameraClient.h"

@interface WiFiConnectManager ()
{
    MyReachability* _reach;
    
    NSMutableArray<id<WiFiObserver> >* _callbacks;
}

@end

@implementation WiFiConnectManager

#pragma mark    Singleton

+ (instancetype) sharedInstance {
    static dispatch_once_t once;
    static WiFiConnectManager* singleton = nil;
    dispatch_once(&once, ^{
        singleton = [[super allocWithZone:nil] init];
    });
    return singleton;
}

+ (instancetype) allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (instancetype) copy {
    return [self.class sharedInstance];
}

#pragma mark    Ctor & Dtor

- (void) dealloc {
    [_reach stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype) init {
    if (self = [super init])
    {
        _reach = [MyReachability reachabilityForLocalWiFi];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:NETCHANGED object:nil];
        [_reach startNotifier];
        
        _callbacks = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark    Reachability

- (void) reachabilityChanged:(NSNotification*)noti {
    MVCameraDevice * device = [MVCameraClient sharedInstance].connectingCamera;
    if (device) {
        NSLog(@"reachabilityChanged : Not reachable to %@", [self.class wifiSSID]);
        for (id<WiFiObserver> observer in _callbacks)
        {
            if (observer && [observer respondsToSelector:@selector(didWiFiDisconnected)])
            {
                [observer didWiFiDisconnected];
            }
        }
    }
    
//    if (self.isWiFiReachable)
//    {
//        NSLog(@"reachabilityChanged : Reachable to %@", [self.class wifiSSID]);
//        for (id<WiFiObserver> observer in _callbacks)
//        {
//            if (observer && [observer respondsToSelector:@selector(didWiFiConnected)])
//            {
//                [observer didWiFiConnected];
//            }
//        }
//    }
//    else
//    {
//        NSLog(@"reachabilityChanged : Not reachable to %@", [self.class wifiSSID]);
//        for (id<WiFiObserver> observer in _callbacks)
//        {
//            if (observer && [observer respondsToSelector:@selector(didWiFiDisconnected)])
//            {
//                [observer didWiFiDisconnected];
//            }
//        }
//    }
}

- (void) addWiFiObserver:(id<WiFiObserver>)observer {
    [_callbacks addObject:observer];
}

- (void) removeWiFiObserver:(id<WiFiObserver>)observer {
    [_callbacks removeObject:observer];
}

+ (NSDictionary*) wifiInfo {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge_retained CFStringRef)ifnam);
        if (info && [info count]) {
            break;
        }
    }
    return [NSDictionary dictionaryWithDictionary:info];
}

+ (void) jumpToWiFiSettings {
    NSString* urlString = @"prefs:root=WIFI";
    NSURL * url = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        [[UIApplication sharedApplication] openURL:url];
    }
    else
    {
        urlString = [NSString stringWithFormat:@"%@", UIApplicationOpenSettingsURLString];
        url = [NSURL URLWithString:urlString];
        if ([[UIApplication sharedApplication] canOpenURL:url])
        {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (BOOL) isWiFiReachable {
    return _reach.isReachableViaWiFi;
}

+ (NSString*) wifiSSID {
    return [self.class wifiInfo][@"SSID"];
}

+ (NSString*) wifiClientIP {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

@end
