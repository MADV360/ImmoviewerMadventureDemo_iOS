//
//  Log.h
//  Madv360_v1
//
//  Created by QiuDong on 16/6/2.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#ifndef GLES3JNI_LOG_H
#define GLES3JNI_LOG_H

#include "TargetConditionals.h"
#include <stdio.h>

#define SHOW_LOG

#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0

#include <android/log.h>

#define LOG_TAG "QD:MADVGL"
#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#if DEBUG
#define ALOGV(...) __android_log_print(ANDROID_LOG_VERBOSE, LOG_TAG, __VA_ARGS__)
#else
#define ALOGV(...)
#endif

#elif defined(TARGET_OS_OSX) && TARGET_OS_OSX != 0

#ifdef SHOW_LOG
#define ALOGE(...) printf(__VA_ARGS__)
#define ALOGV(...) printf(__VA_ARGS__)
#else
#define ALOGE(...)
#define ALOGV(...)
#endif

#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX != 0

#ifdef SHOW_LOG
#define ALOGE(...) printf(__VA_ARGS__)
#define ALOGV(...) printf(__VA_ARGS__)
#else
#define ALOGE(...)
#define ALOGV(...)
#endif

#elif defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0

#include <Foundation/Foundation.h>
//#include "LogManager.h"

#ifdef ENABLE_DOCTOR_LOG
#define ALOGE(...) DoctorLog(@__VA_ARGS__)
#define ALOGV(...) DoctorLog(@__VA_ARGS__)
#else
#define ALOGE(...) NSLog(@__VA_ARGS__)
#define ALOGV(...) NSLog(@__VA_ARGS__)
#endif

//#define ALOGE(...) printf(__VA_ARGS__)
//#define ALOGV(...) printf(__VA_ARGS__)

#elif defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0

#include <stdafx.h>
#include <windows.h>
//#include <atltrace.h>

#define ALOGE(...) printf(__VA_ARGS__)
#define ALOGV(...) printf(__VA_ARGS__)

#else

#ifdef SHOW_LOG
#define ALOGE(...) printf(__VA_ARGS__)
#define ALOGV(...) printf(__VA_ARGS__)
#else
#define ALOGE(...)
#define ALOGV(...)
#endif

#endif

#endif //GLES3JNI_LOG_H
