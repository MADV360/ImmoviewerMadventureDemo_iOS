//
//  SdWhiteResponse.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/3/29.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "SdWhiteResponse.h"
#import "SdWhiteDetail.h"

@implementation SdWhiteResponse
+ (NSDictionary*) mj_objectClassInArray {
    return @{@"result":SdWhiteDetail.class};
}
@end
