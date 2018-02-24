//
//  AMBAGetFileRequest.h
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/16.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBARequest.h"

@interface AMBAGetFileRequest : AMBARequest

@property (nonatomic, copy) NSString* offset;

@property (nonatomic, assign) NSInteger fetchSize;

@end
