//
//  PlayerMoreModel.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    Edit = 0,
    Screen_Shot = 1,
    Delete = 2,
    Export = 3,
    Gyroscope = 4,
    Phone_Gyroscope = 5,
    Favor = 6,
    Quality = 7,
    VR_Patter = 8,
    CONTENT_INFO = 9,
    Phone_Gyroscope_NoImage = 10,
    Watermark = 11,
    Screen_Size = 12,
} MoreType;
@interface PlayerMoreModel : NSObject
@property(nonatomic,copy)NSString * title;
@property(nonatomic,copy)NSString * imageName;
@property(nonatomic,assign)BOOL isExported;
@property(nonatomic,assign)MoreType moreType;
@property(nonatomic,assign)BOOL isCorrecting;//是否校正
@property(nonatomic,assign)BOOL isGyroscope;
@property(nonatomic,strong)NSArray * dataSource;
@end
