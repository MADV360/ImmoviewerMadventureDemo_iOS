//
//  AMBAListResponse.h
//  Madv360_v1
//
//  Created by QiuDong on 16/10/12.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"

@interface AMBAListResponse : AMBAResponse

@property (nonatomic, strong) NSArray<NSDictionary<NSString*, NSString* >* >* listing;

@end
