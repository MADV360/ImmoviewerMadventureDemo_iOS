//
//  SDKTestBench.h
//  ImmoviewerMADVentureDemo
//
//  Created by QiuDong on 2018/5/17.
//  Copyright © 2018年 QiuDong. All rights reserved.
//

#ifndef SDKTestBench_h
#define SDKTestBench_h

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

    void stitchJPEG(NSString* destPath, NSString* sourcePath);
    
    void testMADVPanoStitching();
    
#ifdef __cplusplus
}
#endif

#endif /* SDKTestBench_h */
