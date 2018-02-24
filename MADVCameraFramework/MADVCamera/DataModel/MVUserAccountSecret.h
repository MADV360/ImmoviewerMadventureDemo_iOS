//
//  MVUserAccountSecret.h
//  Madv360_v1
//
//  Created by QiuDong on 16/5/20.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MVUserAccountSecret : NSObject <NSCoding>

@property (nonatomic, copy) NSString* userID;

@property (nonatomic, copy) NSString* password;

@property (nonatomic, copy) NSString* token;

@end
