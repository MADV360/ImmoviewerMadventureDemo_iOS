//
//  main.m
//  ImmoviewerMADVentureDemo
//
//  Created by QiuDong on 2018/1/24.
//  Copyright © 2018年 QiuDong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "SDKTestBench.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        testMADVPanoStitching();
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
