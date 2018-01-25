//
//  AppDelegate.h
//  ImmoviewerMADVentureDemo
//
//  Created by QiuDong on 2018/1/24.
//  Copyright © 2018年 QiuDong. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* kNotificationDownloadedListUpdated;

extern NSMutableArray<NSString* >* g_downloadedFileNames;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

