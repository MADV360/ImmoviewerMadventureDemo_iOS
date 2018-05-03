//
//  helper.m
//
//  Created by wen on 15/8/25.
//  Copyright (c) 2015年 HORSUN. All rights reserved.
//

#import "avUtils.h"
#import "UIDevice+DeviceModel.h"

@implementation avUtils


#pragma mark --这是获得剪切的视频大小, qualityMode: 0 original mode, 1 share mode--

+ (float)getEstimatedVideoEncodedFileSizeInMB:(int)width
                                       height:(int)height
                            startTimeInSecond:(float)startTimeInSecond
                              endTimeInSecond:(float)endTimeInSecond
                                          fps:(float)fps
                                  qualityMode:(int)qualityMode
{
    float bitrate = [self getEstimatedVideoEncodedBitrateInBps:width height:height fps:fps qualityMode:qualityMode];
    
    float fileSize = (endTimeInSecond - startTimeInSecond) * bitrate / (8*1024*1024);
    fileSize *= 1.3; //allow 30% overflow
    return fileSize;
}

#pragma mark --这是获得视频码率, qualityMode: 0 original mode, 1 share mode--

+ (float)getEstimatedVideoEncodedBitrateInBps:(int)width
                                  height:(int)height
                                     fps:(float)fps
                             qualityMode:(int)qualityMode
{
    float bitrate;
    
    switch(qualityMode){
        case 0: //original
            switch(width) {
                case 2304:
                    if (fps > 27 && fps <33)
                        bitrate = 16;
                    else if (fps > 57 && fps <63)
                        bitrate = 24;
                    else if (fps > 12 && fps <18)
                        bitrate = 12;
                    else if (fps > 4.5 && fps < 10.5)
                        bitrate = 6;
                    else
                        bitrate = 6;
                    break;
                case 3456:
                    bitrate = 36 * fps / 29.97;
                    break;
                case 3840:
                    bitrate = 44 * fps / 29.97;
                    break;
                case 2048:
                    bitrate = 16 * fps / 119.88;
                    break;
                case 1920:
                    bitrate = 15;
                    if(height == 1920)
                    {
                        bitrate *= 1.5;
                    }
                    break;
                default:
                {
                    bitrate = 6;
                    if(width == 1080 && height == 1920)
                    {
                        bitrate = 15;
                    }
                    break;
                }
                    
            }
            break;
        case 1: //share
            switch(width) {
                case 2304:
                    if (fps > 27 && fps <33)
                        bitrate = 5;
                    else if (fps > 57 && fps <63)
                        bitrate = 7.5;
                    else if (fps > 12 && fps <18)
                        bitrate = 3.75;
                    else if (fps > 4.5 && fps < 10.5)
                        bitrate = 2;
                    else
                        bitrate = 2;
                    break;
                case 3456:
                    bitrate = 9 * fps / 29.97;
                    break;
                case 3840:
                    bitrate = 9 * fps / 29.97;
                    break;
                case 2048:
                    bitrate = 4 * fps / 119.88;
                    break;
                default:
                    bitrate = 2;
                    break;
            }
            break;
        default:
            bitrate = 2;
            break;
    }
    
    bitrate *= 1024 * 1024;
    return bitrate;
}

+ (BOOL)isVideoEncodeLimitedTo1080
{
    return [UIDevice isNon4KModel];
}

+ (BOOL)isVideoDecodeLimitedTo1080
{
    return NO;
}

@end
