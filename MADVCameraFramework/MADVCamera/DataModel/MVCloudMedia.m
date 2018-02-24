//
//  MVCloudMedia.m
//  Madv360_v1
//
//  Created by QiuDong on 16/4/29.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVCloudMedia.h"
#import "MediaVideoStream.h"

@implementation MVCloudMedia
/*
- (void)setFavor:(NSString *)favor
{
    _favor=favor;
    CGSize size=CGSizeMake(ScreenWidth-82, 17);
    size=[favor boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes: @{NSFontAttributeName:[UIFont systemFontOfSize:15]} context:nil].size;
    self.favorWidth=size.width;
}*/
+ (NSDictionary*) mj_replacedKeyFromPropertyName {
    return @{@"descr":@"description"};
}
//+ (NSDictionary*) mj_objectClassInArray {
//    return @{@"streamlist":MediaVideoStream.class};
//}

//+ (NSDictionary*) mj_objectClassInArray {
//    return @{@"keywords":NSString.class};
//}


@end

