//
//  PartContentResponse.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/11.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <MJExtension/MJExtension.h>
#import "PartContent.h"

@interface PartContentResponse : NSObject
@property (nonatomic, strong) PartContent * result;
@property (nonatomic, copy) NSString* cmd;
@property (nonatomic, assign) NSInteger rval;
@end
