//
//  ImageFilterBean.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/10.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageFilterBean : NSObject

@property(nonatomic,assign)int uuid;//它的唯一标识
@property(nonatomic,copy)NSString * name;
@property(nonatomic,copy)NSString * enName;
@property(nonatomic,copy)NSString * iconPNGPath;
@property(nonatomic,copy)NSString * roundIconPNGPath;

- (instancetype) initWithUUID:(int)uuid name:(NSString *)name enName:(NSString *)enName
                  iconPNGPath:(NSString *)iconPNGPath roundIconPNGPath:(NSString*)roundIconPNGPath;

+ (NSMutableArray<ImageFilterBean *> *)allImageFilters;

+ (ImageFilterBean *)findImageFilterByID:(int)uuid;

@end
