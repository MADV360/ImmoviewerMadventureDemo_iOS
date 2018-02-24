//
//  DBMVCloudMedia.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/13.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Realm.h"
#import "MVCloudMedia.h"
#import "DBMediaVideoStream.h"

RLM_ARRAY_TYPE(DBMediaVideoStream)
@interface DBMVCloudMedia : RLMObject
@property(nonatomic,copy)NSString * filename;//文件名

@property (nonatomic, copy) NSString* title;//标题

@property(nonatomic,copy)NSString * thumbnail;//题图图片url前缀

@property(nonatomic,copy)NSString * author_name;//发布者昵称

@property(nonatomic,copy)NSString * author_avatar;//发布者头像url

@property(nonatomic,copy)NSString * keyword;

@property(nonatomic,copy)NSString * type;//类型(图片0视频1)

@property(nonatomic,copy)NSString * favor;//收藏总数

@property(nonatomic,copy)NSString * favored;//是否收藏过
@property(nonatomic,copy)NSString * playtime;
@property(nonatomic,copy)NSString * picsize;
@property(nonatomic,copy)NSString * createtime;
@property(nonatomic,copy)NSString * level;
@property(nonatomic,copy)NSString * author_id;//发布者手机号
@property(nonatomic,copy)NSString * view_count;//浏览量
@property(nonatomic,copy)NSString * url;//地址前缀

@property(nonatomic,copy)NSString * descr;//描述

@property(nonatomic,copy)NSString * share;//分享总数
@property(nonatomic,copy)NSString * fileurl;//视频的地址
@property(nonatomic,copy)NSString * shareurl;//分享url

@property(nonatomic,strong)RLMArray<DBMediaVideoStream *><DBMediaVideoStream> * streamlist;
@property(nonatomic,copy)NSString * viewerurl;

@property(nonatomic,copy)NSString * isuploaded;

@property(nonatomic,copy)NSString * create_date;//拍摄时间

@property(nonatomic,copy)NSString * equipment;//设备型号
@property(nonatomic,copy)NSString * position;//位置
@property(nonatomic,copy)NSString * speed;//快门速度
@property(nonatomic,copy)NSString * compensate;//曝光补偿
@property(nonatomic,copy)NSString * iso;
@property(nonatomic,copy)NSString * longitude;//经度
@property(nonatomic,copy)NSString * latitude;//维度
@property(nonatomic,copy)NSString * height;//高度

@property(nonatomic,copy)NSString * isNewest;//0推荐  1最新


- (id)createWithMVCloudMedia:(MVCloudMedia *)cloudMedia;
@end
