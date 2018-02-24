//
//  PartContent.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/11.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PartContent : NSObject
@property(nonatomic,copy)NSString * baseurl;
@property(nonatomic,strong)NSArray * signatures;
@property(nonatomic,copy)NSString * uploadid;
@end
