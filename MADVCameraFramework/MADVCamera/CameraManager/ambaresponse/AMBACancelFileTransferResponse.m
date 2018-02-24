//
//  AMBACancelFileTransferResponse.m
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/16.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBACancelFileTransferResponse.h"

@implementation AMBACancelFileTransferResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    mergeJsonSerializablePropertyNames(array, @[@"transferred_size"]);
    return array;
}

- (NSString*) md5 {
    return @"N/A";
}

- (NSInteger) bytesSent {
    return self.transferred_size;
}

@end
