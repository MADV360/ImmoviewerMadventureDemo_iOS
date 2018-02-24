//
//  AMBAGetThumbnailResponse.h
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/16.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"

@interface AMBAGetThumbnailResponse : AMBAResponse

@property (nonatomic, copy) NSString* md5sum;

@property (nonatomic, assign) NSInteger size;

@end
