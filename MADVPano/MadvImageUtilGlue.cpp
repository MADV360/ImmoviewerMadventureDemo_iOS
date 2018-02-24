//
// Created by QiuDong on 16/9/8.
//
#include "MadvImageUtilGlue.h"
#include <stdlib.h>
#include "JPEGUtils.h"
#include "PNGUtils.h"

JNIEXPORT void JNICALL Java_com_madv360_madv_utils_ImageUtil_writeImageToJPEG(JNIEnv* env, jclass clazz, jstring destJpegPath, jint colorSpace, jint bitFormat, jint quality, jbyteArray imageData, jint width, jint height) {
    if (NULL == destJpegPath) return;
    jboolean isCopy = false;
    const char* filename = env->GetStringUTFChars(destJpegPath, &isCopy);
    jboolean isDataCopy = false;
    jbyte* data = env->GetByteArrayElements(imageData, &isDataCopy);
    writeImageToJPEG(filename, colorSpace, bitFormat, quality, (unsigned char*) data, width, height);
    ALOGE("Java_com_madv360_madv_utils_ImageUtil_fwriteImageAsJPEG");
    if (isCopy)
    {
        env->ReleaseStringUTFChars(destJpegPath, filename);
    }
    if (isDataCopy)
    {
        env->ReleaseByteArrayElements(imageData, data, 0);
    }
}

JNIEXPORT jlong JNICALL Java_com_madv360_madv_utils_ImageUtil_startWritingImageToJPEG(JNIEnv* env, jclass clazz, jstring destJpegPath, jint colorSpace, jint bitFormat, jint quality, jint width, jint height) {
    if (NULL == destJpegPath) return 0L;
    jboolean isCopy = false;
    const char* filename = env->GetStringUTFChars(destJpegPath, &isCopy);
    JPEGCompressOutput* ret = startWritingImageToJPEG(filename, colorSpace, bitFormat, quality, width, height);
    if (isCopy)
    {
        env->ReleaseStringUTFChars(destJpegPath, filename);
    }
    return (jlong)ret;
}

JNIEXPORT void JNICALL Java_com_madv360_madv_utils_ImageUtil_releaseJPEGCompressOutput(JNIEnv* env, jclass clazz, jlong handler) {
    if (0 == handler) return;
    JPEGCompressOutput* ptr = (JPEGCompressOutput*) handler;
    delete ptr;
}

JNIEXPORT jboolean JNICALL Java_com_madv360_madv_utils_ImageUtil_appendImageStrideToJPEG(JNIEnv* env, jclass clazz, jlong handler, jbyteArray imageData, jint offset, jint lines, jboolean reverseOrder) {
    jboolean isDataCopy = false;
    ALOGE("renderJPEGToJPEG# appendImageStrideToJPEG#Glue0");
    jbyte* data = env->GetByteArrayElements(imageData, &isDataCopy);
    bool ret = appendImageStrideToJPEG((const JPEGCompressOutput*) handler, (unsigned char*) data + offset, lines, reverseOrder);
    if (isDataCopy)
    {
        env->ReleaseByteArrayElements(imageData, data, 0);
    }
    return ret;
}

//JNIEXPORT void JNICALL Java_com_madv360_madv_utils_ImageUtil_readExifFromJPEG(JNIEnv* env, jclass clazz, jstring jpegFilePath) {
//    if (NULL == jpegFilePath) return;
//    jboolean isCopy = false;
//    const char* filename = env->GetStringUTFChars(jpegFilePath, &isCopy);
//    int ret = readExifFromFile(filename);
//    ALOGE("Java_com_madv360_madv_utils_ImageUtil_readExifFromJPEG = %d : %s", ret, filename);
//    if (isCopy)
//    {
//        env->ReleaseStringUTFChars(jpegFilePath, filename);
//    }
//}

JNIEXPORT jint JNICALL Java_com_madv360_madv_gles_GlUtil_createTextureWithJPEG(JNIEnv* env, jclass clazz, jstring jpegFilePath) {
    if (NULL == jpegFilePath) return 0;
    jboolean isCopy = false;
    const char* filename = env->GetStringUTFChars(jpegFilePath, &isCopy);

    int texture = createTextureWithJPEG(filename);

    if (isCopy)
    {
        env->ReleaseStringUTFChars(jpegFilePath, filename);
    }

    return texture;
}

JNIEXPORT jint JNICALL Java_com_madv360_madv_gles_GlUtil_createTextureWithPNG(JNIEnv* env, jclass clazz, jstring pngFilePath) {
    if (NULL == pngFilePath) return 0;
    jboolean isCopy = false;
    const char* filename = env->GetStringUTFChars(pngFilePath, &isCopy);

    int texture = createTextureFromPNG(filename);

    if (isCopy)
    {
        env->ReleaseStringUTFChars(pngFilePath, filename);
    }

    return texture;
}