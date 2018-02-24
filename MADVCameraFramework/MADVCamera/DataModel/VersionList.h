//
//  VersionList.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/17.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <MJExtension/MJExtension.h>
#import "VersionDetail.h"
@interface VersionList : NSObject
@property(nonatomic,strong)VersionDetail * soft;
@property(nonatomic,strong)VersionDetail * hard;
@property(nonatomic,strong)VersionDetail * remoter;
@property(nonatomic,copy)NSString * location;
@end
