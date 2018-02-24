//
//  helper.h
//
//  Created by wen on 15/8/25.
//  Copyright (c) 2015年 HORSUN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface avUtils : NSObject

+ (float)getEstimatedVideoEncodedFileSizeInMB:(int)width
                                       height:(int)height
                            startTimeInSecond:(float)startTimeInSecond
                              endTimeInSecond:(float)endTimeInSecond
                                          fps:(float)fps
                                  qualityMode:(int)qualityMode
;

+ (float)getEstimatedVideoEncodedBitrateInBps:(int)width
                                       height:(int)height
                                          fps:(float)fps
                                  qualityMode:(int)qualityMode
;

+ (BOOL)isVideoEncodeLimitedTo1080;

+ (BOOL)isVideoDecodeLimitedTo1080;

@end
