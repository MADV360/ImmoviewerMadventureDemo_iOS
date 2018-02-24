//
//  NewHand.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/3/21.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Realm.h"
@interface NewHand : RLMObject
@property(nonatomic,copy)NSString * handId;
@property(nonatomic,copy)NSString * createtime;
@property(nonatomic,copy)NSString * title;
@property(nonatomic,copy)NSString * des;
@property(nonatomic,copy)NSString * url;
@property(nonatomic,copy)NSString * thumbnail;
@property(nonatomic,copy)NSString * thumbnail_ios;
@property(nonatomic,copy)NSString * type;//"类型 1图片 2视频"
@property(nonatomic,assign)CGFloat desHeight;
@end
