//
//  AMBASetGPSInfoRequest.h
//  Madv360_v1
//
//  Created by QiuDong on 2017/7/17.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AMBARequest.h"

@interface AMBASetGPSInfoRequest : AMBARequest

@property (nonatomic, copy) NSString* lon;
@property (nonatomic, copy) NSString* lat;
@property (nonatomic, copy) NSString* alt;

@end
