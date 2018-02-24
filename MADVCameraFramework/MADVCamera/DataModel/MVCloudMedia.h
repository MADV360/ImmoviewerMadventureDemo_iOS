//
//  MVCloudMedia.h
//  Madv360_v1
//
//  Created by QiuDong on 16/4/29.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVServerResponse.h"
#import "MVHttpResponse.h"
#import <UIKit/UIKit.h>
#import "CloudMediaDetail.h"

typedef enum {
    MVCloudMediaTypeVideo,
    MVCloudMediaTypePhoto,
} MVCloudMediaType;

@interface MVCloudMedia : CloudMediaDetail
/*
@property(nonatomic,copy)NSString * filename;//文件名

@property (nonatomic, copy) NSString* title;//标题

@property(nonatomic,copy)NSString * thumbnail;//题图图片url前缀

@property(nonatomic,copy)NSString * author_id;//发布者手机号

@property(nonatomic,copy)NSString * author_name;//发布者昵称

@property(nonatomic,copy)NSString * author_avatar;//发布者头像url

@property(nonatomic,strong)NSArray * keywords;//关键字

@property(nonatomic,copy)NSString * keyword;

@property(nonatomic,copy)NSString * type;//类型(图片0视频1)

@property(nonatomic,copy)NSString * favor;//收藏总数

@property(nonatomic,copy)NSString * favored;//是否收藏过

@property(nonatomic,copy)NSString * removed;//是否删除
@property(nonatomic,copy)NSString * playtime;
@property(nonatomic,copy)NSString * picsize;
@property(nonatomic,copy)NSString * createtime;

@property(nonatomic,copy)NSString * level;

@property(nonatomic,copy)NSString * url;//地址前缀

@property(nonatomic,copy)NSString * descr;//描述

@property(nonatomic,copy)NSString * share;//分享总数
@property(nonatomic,copy)NSString * fileurl;//视频的地址
@property(nonatomic,copy)NSString * shareurl;//分享url

@property(nonatomic,strong)NSArray * streamlist;//所有转码视频的信息*/

//@property(nonatomic,copy)NSString * view_count;//浏览量

/*@property(nonatomic,copy)NSString * viewerurl;


@property(nonatomic,assign)CGFloat favorWidth;
@property(nonatomic,copy)NSString * isuploaded;*/


//@property (nonatomic, assign) NSInteger authorID;
//
//@property (nonatomic, copy) NSString* detail;
//
//@property (nonatomic, copy) NSString* assetUrl;
//
//@property (nonatomic, copy) NSString* thumbnailUrl;

//@property (nonatomic, strong) NSArray* keywords;

@end


#pragma mark    For Debug
#import "Macros.h"

#define ForgedMediaListItemJSON0 STRINGIZE(  \
{"authorID":1234567, "title":"跟随小疯逛车展", "detail":"Auto China 2016是亚洲第一车展，中国三大A级国际车展之一！展会上众多豪车、概念车亮相，虽然没有了车模，“香车美女”的场面不再，不过眼尖的观众发现，车展上的礼仪、拍单员和讲解员颜值颇高，不输以前的车模，这让本届车展多了一丝温柔的色彩。", "keywords":["车展", "车模", "美女"], "assetUrl":"rtsp://54.222.223.102/gsxfgcz.mp4", "thumbnailUrl":"http://101.200.157.66/gsxfgcz.png"})

#define ForgedMediaListItemJSON1 STRINGIZE(  \
{"authorID":1234567, "title":"换个角度看北京", "detail":"北京，中国首都。作为中国的政治中心，北京是一座世界顶级的城市，诸多文化、经济产业在这繁盛发展。每个人心中都有一个属于自己的北京，这支全景短片，带你感受不一样的北京。", "keywords":[], "assetUrl":"rtsp://54.222.223.102/hgsjkbj.mp4", "thumbnailUrl":"http://101.200.157.66/hgsjkbj.png"})

#define ForgedMediaListItemJSON2 STRINGIZE(  \
{"authorID":1234567, "title":"京东大峡谷", "detail":"“探峡谷感受神秘清幽，登高峰尽揽千山万壑”，位于北京平谷的京东大峡谷狭险幽深，壁立万仞，井台山平阔如台，高耸连云。与小情侣一起感受幽谷深潭360°的美丽景色。", "keywords":[], "assetUrl":"rtsp://54.222.223.102/jddxg.mp4", "thumbnailUrl":"http://101.200.157.66/jddxg.png"})

#define ForgedMediaListItemJSON3 STRINGIZE(  \
{"authorID":1234567, "title":"看模型展感受科技的发展", "detail":"Hobby Expo China是亚太地区最具规模和影响力的模型博览会，每年4月份在中国北京举办，被称为“北京模型展”，展会集中呈现着兴趣模型产业最新的设计理念、科技应用和发展趋势。各式各样有趣的模型，让你眼花缭乱。", "keywords":[], "assetUrl":"rtsp://54.222.223.102/kmxzgskjdfz.mp4", "thumbnailUrl":"http://101.200.157.66/kmxzgskjdfz.png"})

#define ForgedMediaListItemJSON4 STRINGIZE(  \
{"authorID":1234567, "title":"跨上马背穿越坝上草原", "detail":"坝上草原位于内蒙古高原与大兴安岭南麓的接壤地带，属大陆季风高原气候，冬季漫长，夏季无暑，清凉宜人。结束了一周忙碌的工作，约二、三好友，策马扬鞭，感受蓝天、白云下的自在与惬意！", "keywords":[], "assetUrl":"rtsp://54.222.223.102/gsmbcybscy.mp4", "thumbnailUrl":"http://101.200.157.66/gsmbcybscy.png"})

#define ForgedMediaListJSON STRINGIZE2({"ret":0, "errmsg":"", "result":[ForgedMediaListItemJSON0, ForgedMediaListItemJSON1, ForgedMediaListItemJSON2, ForgedMediaListItemJSON3, ForgedMediaListItemJSON4]})

//
