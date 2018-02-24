//
// Created by QiuDong on 16/9/8.
//
#include <jni.h>
#include "Log.h"

#ifndef MADV1_0_MADVIMAGEUTILGLUE_H
#define MADV1_0_MADVIMAGEUTILGLUE_H

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT void JNICALL Java_com_madv360_madv_utils_ImageUtil_writeImageToJPEG(JNIEnv* env, jclass clazz, jstring destJpegPath, jint colorSpace, jint bitFormat, jint quality, jbyteArray imageData, jint width, jint height);

JNIEXPORT jlong JNICALL Java_com_madv360_madv_utils_ImageUtil_startWritingImageToJPEG(JNIEnv* env, jclass clazz, jstring destJpegPath, jint colorSpace, jint bitFormat, jint quality, jint width, jint height);
JNIEXPORT jboolean JNICALL Java_com_madv360_madv_utils_ImageUtil_appendImageStrideToJPEG(JNIEnv* env, jclass clazz, jlong handler, jbyteArray imageData, jint offset, jint lines, jboolean reverseOrder);
JNIEXPORT void JNICALL Java_com_madv360_madv_utils_ImageUtil_releaseJPEGCompressOutput(JNIEnv* env, jclass clazz, jlong handler);

//JNIEXPORT void JNICALL Java_com_madv360_madv_utils_ImageUtil_readExifFromJPEG(JNIEnv* env, jclass clazz, jstring jpegFilePath);

JNIEXPORT jint JNICALL Java_com_madv360_madv_gles_GlUtil_createTextureWithJPEG(JNIEnv* env, jclass clazz, jstring jpegFilePath);

JNIEXPORT jint JNICALL Java_com_madv360_madv_gles_GlUtil_createTextureWithPNG(JNIEnv* env, jclass clazz, jstring pngFilePath);

#ifdef __cplusplus
}
#endif

#endif //MADV1_0_MADVIMAGEUTILGLUE_H
