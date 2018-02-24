//
//  VideoStream.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/2.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MJExtension/MJExtension.h>
@interface MediaVideoStream : NSObject
@property(nonatomic,copy)NSString * fps;//帧率
@property(nonatomic,copy)NSString * resolution;//分辨率
@property(nonatomic,copy)NSString * bitrate;//码率
@property(nonatomic,copy)NSString * videocodec;//编码(264/265)
@property(nonatomic,copy)NSString * fileurl;//流地址
//- (id)createWithFps:(NSString *)fps resolution:(NSString *)resolution bitrate:(NSString *)bitrate videocodec:(NSString *)videocodec fileurl:(NSString *)fileurl;
@end
