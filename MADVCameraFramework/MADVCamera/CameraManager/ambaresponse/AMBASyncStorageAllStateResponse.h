//
//  AMBASyncStorageAllStateResponse.h
//  Madv360_v1
//
//  Created by QiuDong on 16/11/7.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"

@interface AMBASyncStorageAllStateResponse : AMBAResponse

@property (nonatomic, assign)  int remain_video;

@property (nonatomic, assign)  int remain_jpg;

@property (nonatomic, assign)  int sd_total;

@property (nonatomic, assign)  int sd_free;

@property (nonatomic, assign)  int sd_full;

@property (nonatomic, assign)  int sd_mid;

@property (nonatomic, assign)  int sd_oid;

@property (nonatomic, copy)  NSString* sd_pnm;

@end
