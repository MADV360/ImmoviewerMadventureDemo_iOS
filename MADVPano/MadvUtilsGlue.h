//
// Created by QiuDong on 16/9/8.
//
#include <jni.h>
#include "Log.h"

#ifndef MADV1_0_MADVUTILSGLUE_H
#define MADV1_0_MADVUTILSGLUE_H

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT void JNICALL Java_com_madv360_madv_utils_FileUtil_makeCrash(JNIEnv *env, jclass clazz);

#ifdef __cplusplus
}
#endif

#endif //MADV1_0_MADVUTILSGLUE_H
