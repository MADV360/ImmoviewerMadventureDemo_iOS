//
//  GetFilenameResponse.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/7/26.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GetFilenameModel.h"

@interface GetFilenameResponse : NSObject
@property (nonatomic, strong)GetFilenameModel * result;
@property (nonatomic, copy) NSString* cmd;
@property (nonatomic, assign) NSInteger rval;
@end
