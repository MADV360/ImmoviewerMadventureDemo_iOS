//
//  MessageDetail.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/10/14.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageDetail : NSObject
@property(nonatomic,copy)NSString * content;
@property(nonatomic,copy)NSString * url;
@property(nonatomic,copy)NSString * msgId;
@property(nonatomic,copy)NSString * title;
@property(nonatomic,assign)CGFloat contentHeight;
@property(nonatomic,assign)BOOL expand;
@end
