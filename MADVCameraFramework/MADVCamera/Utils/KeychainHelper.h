//
//  KeychainHelper.h
//  Madv360_v1
//  Ref : http://www.2cto.com/kf/201506/411321.html
//  Created by QiuDong on 16/5/20.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyChainHelper : NSObject

// save username and password to keychain
+ (void)save:(NSString *)service data:(id)data;

// take out username and passwore from keychain
+ (id)load:(NSString *)service;

// delete username and password from keychain
+ (void)delete:(NSString *)service;

@end
