//
//  AMBAFileTransferResultResponse.h
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/16.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"

@interface AMBAFileTransferResultResponse : AMBAResponse

- (NSString*) md5;

- (NSInteger) bytesSent;

- (NSInteger) bytesReceived;

@end
