//
// Created by QiuDong on 2017/5/19.
//

#ifndef MADV1_0_MADVEXIV2GLUE_H
#define MADV1_0_MADVEXIV2GLUE_H

#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT jboolean JNICALL Java_com_madv360_exiv2_MadvExiv2_setXmpGPanoPacket(JNIEnv *env, jclass clazz, jstring imagePath);

JNIEXPORT jobject JNICALL Java_com_madv360_exiv2_MadvExiv2_readMadvEXIFExtensionFromJPEG(JNIEnv* env, jclass selfClass, jstring jpegPath);

JNIEXPORT jlong JNICALL Java_com_madv360_exiv2_MadvExiv2_readLUTOffsetInJPEG(JNIEnv* env, jclass selfClass, jstring jpegPath);

JNIEXPORT jlong JNICALL Java_com_madv360_exiv2_MadvExiv2_createExiv2ImageFromJPEG(JNIEnv* env, jclass selfClass, jstring jpegPath);

JNIEXPORT void JNICALL Java_com_madv360_exiv2_MadvExiv2_releaseExiv2Image(JNIEnv* env, jclass selfClass, jlong imagePtr);

JNIEXPORT void JNICALL Java_com_madv360_exiv2_MadvExiv2_copyEXIFDataFromExiv2Image(JNIEnv* env, jclass selfClass, jstring destJpegPath, jlong imagePtr);

JNIEXPORT void JNICALL Java_com_madv360_exiv2_MadvExiv2_exivImageEraseGyroData(JNIEnv* env, jclass selfClass, jlong imagePtr);

JNIEXPORT void JNICALL Java_com_madv360_exiv2_MadvExiv2_exivImageEraseSceneType(JNIEnv* env, jclass selfClass, jlong imagePtr);

JNIEXPORT void JNICALL Java_com_madv360_exiv2_MadvExiv2_exivImageSaveMetaData(JNIEnv* env, jclass selfClass, jlong imagePtr);

#ifdef __cplusplus
}
#endif

#endif //MADV1_0_MADVEXIV2GLUE_H
