//
//  AMBACancelFileTransferResponse.h
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/16.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"

@interface AMBACancelFileTransferResponse : AMBAResponse

- (NSInteger) bytesSent;

- (NSString*) md5;

@property (nonatomic, assign) NSInteger transferred_size;

@end
