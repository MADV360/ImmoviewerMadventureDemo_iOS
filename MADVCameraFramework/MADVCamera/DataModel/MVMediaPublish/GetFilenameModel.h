//
//  GetFilenameModel.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/7/26.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetFilenameModel : NSObject
@property(nonatomic,copy)NSString * filename;//文件id
@property(nonatomic,copy)NSString * filename_media;//上传媒体文件名
@property(nonatomic,copy)NSString * filename_thumbnail;//上传缩略图文件名
@property(nonatomic,copy)NSString * region;//区域
@property(nonatomic,copy)NSString * bucket;//文件夹
@property(nonatomic,copy)NSString * url;//地址前缀
@property(nonatomic,copy)NSString * mac_key;//key
@property(nonatomic,copy)NSString * access_token;
@property(nonatomic,copy)NSString * thumbnail;//缩略图地址
@property(nonatomic,copy)NSString * shareurl;//分享地址
@property(nonatomic,copy)NSString * viewerurl;
@property (nonatomic, assign) NSInteger rval;
@end
