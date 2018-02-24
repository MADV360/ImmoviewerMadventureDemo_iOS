//
//  AMBASaveMediaFileDoneResponse.h
//  Madv360_v1
//
//  Created by QiuDong on 2016/11/26.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"

@interface AMBASaveMediaFileDoneResponse : AMBAResponse

@property (nonatomic, assign) int remain_video;
@property (nonatomic, assign) int remain_jpg;
@property (nonatomic, assign) int total_mp4;
@property (nonatomic, assign) int sd_total;
@property (nonatomic, assign) int sd_free;
@property (nonatomic, assign) int sd_full;
@property (nonatomic, assign) int mp4_time;

@end
