//
// Created by QiuDong on 2017/5/19.
//
#include "MadvExiv2Glue.h"
#include "EXIFParser.h"
#include "Log.h"
#include <string.h>
#include <stdio.h>
#include <inttypes.h>

static jclass clazz_MadvEXIFExtension = NULL;
static jmethodID method_MadvEXIFExtension_CtorVFIZ = NULL;

JNIEXPORT jboolean JNICALL Java_com_madv360_exiv2_MadvExiv2_setXmpGPanoPacket(JNIEnv *env, jclass clazz, jstring imagePath) {
    jboolean isCopied = false;
    const char* cstrImagePath = (NULL == imagePath) ? NULL : env->GetStringUTFChars(imagePath, &isCopied);

    jboolean ret = setXmpGPanoPacket(cstrImagePath);

    if (isCopied)
    {
        env->ReleaseStringUTFChars(imagePath, cstrImagePath);
    }

    return ret;
}

JNIEXPORT jobject JNICALL Java_com_madv360_exiv2_MadvExiv2_readMadvEXIFExtensionFromJPEG(JNIEnv* env, jclass selfClass, jstring jpegPath) {
    if (NULL == method_MadvEXIFExtension_CtorVFIZ)
    {
        jclass tmp = env->FindClass("com/madv360/exiv2/MadvEXIFExtension");
        clazz_MadvEXIFExtension = (jclass) env->NewGlobalRef(tmp);
        method_MadvEXIFExtension_CtorVFIZ = env->GetMethodID(clazz_MadvEXIFExtension, "<init>", "([FIZFFFFFFFF)V");
    }

    jboolean copied = false;
    const char* cstrJPEGPath = env->GetStringUTFChars(jpegPath, &copied);

    jfloatArray gyroMatrix = NULL;
    MadvEXIFExtension madvExt = readMadvEXIFExtensionFromJPEG(cstrJPEGPath);
    int gyroMatrixSize = madvExt.gyroMatrixBytes / sizeof(jfloat);
    if (gyroMatrixSize > 0)
    {
        int i;
        ALOGE("readGyroDataFromJPEG : gyroMatrixSize = %d", gyroMatrixSize);
        for (i=0; i<gyroMatrixSize; i++)
        {
            ALOGE("gyroMatrixData[%d] = %f", i, madvExt.cameraParams.gyroMatrix[i]);
        }
        gyroMatrix = env->NewFloatArray(gyroMatrixSize);
        env->SetFloatArrayRegion(gyroMatrix, 0, gyroMatrixSize, madvExt.cameraParams.gyroMatrix);
    }

    if (copied)
    {
        env->ReleaseStringUTFChars(jpegPath, cstrJPEGPath);
    }

    jobject ret = env->NewObject(clazz_MadvEXIFExtension, method_MadvEXIFExtension_CtorVFIZ, gyroMatrix, madvExt.sceneType, madvExt.withEmbeddedLUT, madvExt.cameraParams.leftX, madvExt.cameraParams.leftY, madvExt.cameraParams.rightX, madvExt.cameraParams.rightY, madvExt.cameraParams.ratio, madvExt.cameraParams.yaw, madvExt.cameraParams.pitch, madvExt.cameraParams.roll);
    return ret;
}

JNIEXPORT jlong JNICALL Java_com_madv360_exiv2_MadvExiv2_readLUTOffsetInJPEG(JNIEnv* env, jclass selfClass, jstring jpegPath) {
    jboolean copied = false;
    const char* cstrJPEGPath = env->GetStringUTFChars(jpegPath, &copied);

    jlong lutOffset = readLUTOffsetInJPEG(cstrJPEGPath);

    if (copied)
    {
        env->ReleaseStringUTFChars(jpegPath, cstrJPEGPath);
    }

    return lutOffset;
}

JNIEXPORT jlong JNICALL Java_com_madv360_exiv2_MadvExiv2_createExiv2ImageFromJPEG(JNIEnv* env, jclass selfClass, jstring jpegPath) {
    if (NULL == jpegPath)
        return 0;

    jboolean copied = false;
    const char* cstrJPEGPath = env->GetStringUTFChars(jpegPath, &copied);

    jlong handler = createExivImage(cstrJPEGPath);

    if (copied)
    {
        env->ReleaseStringUTFChars(jpegPath, cstrJPEGPath);
    }

    return handler;
}

JNIEXPORT void JNICALL Java_com_madv360_exiv2_MadvExiv2_releaseExiv2Image(JNIEnv* env, jclass selfClass, jlong imagePtr) {
    releaseExivImage(imagePtr);
}

JNIEXPORT void JNICALL Java_com_madv360_exiv2_MadvExiv2_exivImageEraseGyroData(JNIEnv* env, jclass selfClass, jlong imagePtr) {
    exivImageEraseGyroData(imagePtr);
}

JNIEXPORT void JNICALL Java_com_madv360_exiv2_MadvExiv2_exivImageEraseSceneType(JNIEnv* env, jclass selfClass, jlong imagePtr) {
    exivImageEraseSceneType(imagePtr);
}

JNIEXPORT void JNICALL Java_com_madv360_exiv2_MadvExiv2_exivImageSaveMetaData(JNIEnv* env, jclass selfClass, jlong imagePtr) {
    exivImageSaveMetaData(imagePtr);
}

JNIEXPORT void JNICALL Java_com_madv360_exiv2_MadvExiv2_copyEXIFDataFromExiv2Image(JNIEnv* env, jclass selfClass, jstring destJpegPath, jlong imagePtr) {
    if (NULL == destJpegPath)
        return;

    jboolean copied = false;
    const char* cstrJPEGPath = env->GetStringUTFChars(destJpegPath, &copied);

    copyEXIFDataFromExivImage(cstrJPEGPath, imagePtr);

    if (copied)
    {
        env->ReleaseStringUTFChars(destJpegPath, cstrJPEGPath);
    }
}