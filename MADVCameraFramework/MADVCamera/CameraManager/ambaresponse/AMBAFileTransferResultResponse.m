 //
//  AMBAFileTransferResultResponse.m
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/16.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAFileTransferResultResponse.h"

@implementation AMBAFileTransferResultResponse

- (NSString*) md5 {
    NSArray* paramArray = (NSArray*) self.param;
    NSDictionary* md5Dict = (NSDictionary*) paramArray[1];
    NSString* md5 = (NSString*) md5Dict[@"md5sum"];
    return md5;
}

- (NSInteger) bytesSent {
    NSArray* paramArray = (NSArray*) self.param;
    NSDictionary* bytesSentDict = (NSDictionary*) paramArray[0];
    double bytesSent = [bytesSentDict[@"bytes sent"] doubleValue];
    return (NSInteger)bytesSent;
}

- (NSInteger) bytesReceived {
    NSArray* paramArray = (NSArray*) self.param;
    NSDictionary* bytesReceivedDict = (NSDictionary*) paramArray[0];
    double bytesReceived = [bytesReceivedDict[@"bytes received"] doubleValue];
    return (NSInteger)bytesReceived;
}

@end
