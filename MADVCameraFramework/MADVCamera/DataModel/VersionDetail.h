//
//  VersionDetail.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/17.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <MJExtension/MJExtension.h>

@interface VersionDetail : NSObject
@property(nonatomic,copy)NSString * version_code;//最新版本号
@property(nonatomic,copy)NSString * version_name;//最新版本名称
@property(nonatomic,copy)NSString * download_url;//下载地址
@property(nonatomic,copy)NSString * content;//更新日志
@end
