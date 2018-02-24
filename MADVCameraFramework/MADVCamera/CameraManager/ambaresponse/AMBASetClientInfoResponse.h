//
//  AMBASetClientInfoResponse.h
//  Madv360_v1
//
//  Created by QiuDong on 2017/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"

@interface AMBASetClientInfoResponse : AMBAResponse

@property (nonatomic, assign) int update;
@property (nonatomic, assign) uint32_t session_id;

@end
