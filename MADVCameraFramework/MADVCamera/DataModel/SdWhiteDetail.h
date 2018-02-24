//
//  SdWhiteDetail.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/3/29.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Realm.h"

@interface SdWhiteDetail : RLMObject
@property(nonatomic,copy)NSString * sd_name;
@property(nonatomic,copy)NSString * sd_mid;
@property(nonatomic,copy)NSString * sd_oid;
@property(nonatomic,copy)NSString * sd_pnm;
@property(nonatomic,copy)NSString * update_time;
@end
