//
//  DBMVCloudMedia.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/13.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "DBMVCloudMedia.h"

@implementation DBMVCloudMedia
- (id)createWithMVCloudMedia:(MVCloudMedia *)cloudMedia
{
    DBMVCloudMedia * media=[[DBMVCloudMedia alloc] init];
    media.filename=cloudMedia.filename;
    media.title=cloudMedia.title;
    media.thumbnail=cloudMedia.thumbnail;
    media.author_name=cloudMedia.author_name;
    media.author_avatar=cloudMedia.author_avatar;
    media.keyword=cloudMedia.keyword;
    media.type=cloudMedia.type;
    media.favor=cloudMedia.favor;
    media.favored=cloudMedia.favored;
    media.playtime = cloudMedia.playtime;
    media.picsize = cloudMedia.picsize;
    media.createtime = cloudMedia.createtime;
    media.level = cloudMedia.level;
    
    media.author_id = cloudMedia.author_id;
    media.url = cloudMedia.url;//地址前缀
    media.descr = cloudMedia.descr;//描述
    
    media.share = cloudMedia.share;//分享总数
    media.fileurl = cloudMedia.fileurl;//视频的地址
    media.shareurl = cloudMedia.shareurl;//分享url
    
    for (int i = 0; i<cloudMedia.streamlist.count; i++) {
        MediaVideoStream * videoStream = cloudMedia.streamlist[i];
        DBMediaVideoStream * dbVideoStream = [[DBMediaVideoStream alloc] createWithMediaVideoStream:videoStream];
        [media.streamlist addObject:dbVideoStream];
    }
    
    media.viewerurl = cloudMedia.viewerurl;
    
    media.isuploaded = cloudMedia.isuploaded;
    
    media.create_date = cloudMedia.create_date;//拍摄时间
    
    media.equipment = cloudMedia.equipment;//设备型号
    media.position = cloudMedia.position;//位置
    media.speed = cloudMedia.speed;//快门速度
    media.compensate = cloudMedia.compensate;//曝光补偿
    media.iso = cloudMedia.iso;
    media.longitude = cloudMedia.longitude;
    media.latitude = cloudMedia.latitude;
    media.height = cloudMedia.height;
    media.view_count = cloudMedia.view_count;
    return media;
    
}
@end
