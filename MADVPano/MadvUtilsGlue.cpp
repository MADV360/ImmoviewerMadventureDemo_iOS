//
// Created by QiuDong on 16/9/8.
//
#include "MadvUtilsGlue.h"
#include <stdlib.h>

JNIEXPORT void JNICALL Java_com_madv360_madv_utils_FileUtil_makeCrash(JNIEnv *env, jclass clazz) {
    ALOGE("Make a crash");
    exit(-1);
}
