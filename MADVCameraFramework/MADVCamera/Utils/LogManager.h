//
// LogManager.h
// LogFileDemo
//
// Created by xgao on 17/3/9.
// Copyright © 2017年 xgao. All rights reserved.
//
#ifndef __LOGMANAGER_H
#define __LOGMANAGER_H

#import <Foundation/Foundation.h>

#define ENABLE_DOCTOR_LOG

#ifdef ENABLE_DOCTOR_LOG
#define DoctorLog(...)  do {NSLog(__VA_ARGS__);[[LogManager sharedInstance] logInfo:[NSString stringWithFormat:__VA_ARGS__]];} while (0)
//#define ALOGE(...) DoctorLog(@__VA_ARGS)
#else
#define DoctorLog(...) NSLog(__VA_ARGS__)
#endif

@interface LogManager : NSObject

/**
 * 获取单例实例
 *
 * @return 单例实例
 */
+ (instancetype) sharedInstance;

#pragma mark - Method

/**
 * 写入日志
 *
 * @param module 模块名称
 * @param logStr 日志信息,动态参数
 */
- (void)logInfo:(NSString*)module logStr:(NSString*)logStr, ...;

- (void)logInfo:(NSString*)logStr;

- (void) saveLog;

/**
 * 清空过期的日志
 */
- (void)clearExpiredLog;

/**
 * 检测日志是否需要上传
 */
- (void)checkLogNeedUpload;
@end

#endif //__LOGMANAGER_H
