//
//  DBMVMediaAsset.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/7/18.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Realm.h"

@interface DBMVMediaAsset : RLMObject
//文件大小
@property (nonatomic, copy)NSString * fileSize;
//视频多长时间
@property (nonatomic, copy)NSString * duration;
//分辨率
@property (nonatomic, copy)NSString * resolution;
 //下载的时间
@property (nonatomic, copy)NSString * publishDate;
//0 -图片  1-视频
@property (nonatomic, copy)NSString * mediaType;

@property (nonatomic, copy) NSString* localPath;
@property (nonatomic, copy) NSString* thumbnailPath;
@end
