//
//  MessageDetail.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/10/14.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MessageDetail.h"

@implementation MessageDetail

- (void)setContent:(NSString *)content
{
    _content=content;
    CGSize size=CGSizeMake(ScreenWidth-60,CGFLOAT_MAX);
    size=[content boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes: @{NSFontAttributeName:[UIFont systemFontOfSize:12]} context:nil].size;
    self.contentHeight=size.height+15;
}
+ (NSDictionary*) mj_replacedKeyFromPropertyName {
    return @{@"msgId":@"id"};
}
@end
