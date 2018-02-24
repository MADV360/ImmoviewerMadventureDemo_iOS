//
//  VersionInfoResponse.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/17.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <MJExtension/MJExtension.h>
#import "VersionList.h"
@interface VersionInfoResponse : NSObject
@property (nonatomic, strong) VersionList * result;
@property (nonatomic, copy) NSString* cmd;
@property (nonatomic, assign) NSInteger rval;
@end
