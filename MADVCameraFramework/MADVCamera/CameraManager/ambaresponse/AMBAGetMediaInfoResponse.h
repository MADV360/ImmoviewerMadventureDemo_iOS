//
//  AMBAGetMediaInfoResponse.h
//  Madv360_v1
//
//  Created by QiuDong on 16/10/11.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"
#import "MVMedia.h"

// '{"rval":0,"msg_id":1026,"size":37748736,"date":"2017-01-01 20:46:24","resolution":"2304x1152","duration":6,"media_type":"mov"}'
/*
 0：3456x1728@30
 1：2304x1152@30
 2：2304x1152@60
 6：3840x1920@30
 7：1920x480@120U
 8：1920x480@120M
 9：1920x480@120B
 //*/

@interface AMBAGetMediaInfoResponse : AMBAResponse

@property (nonatomic, assign) int duration;

@property (nonatomic, assign) NSInteger jsonSize;

@property (nonatomic, copy) NSString* media_type;

@property (nonatomic, assign) int scene_type;

@property (nonatomic, copy) NSString* gyro;

@property (nonatomic, copy) NSString* res_id;

- (NSInteger) size;

- (VideoCaptureResolution) videoCaptureResolution;

@end
