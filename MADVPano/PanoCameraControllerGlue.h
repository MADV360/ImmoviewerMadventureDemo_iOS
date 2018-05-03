//
// Created by QiuDong on 2017/6/22.
//

#ifndef MADV1_0_PANOCAMERACONTROLLERGLUE_H
#define MADV1_0_PANOCAMERACONTROLLERGLUE_H

#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT jlong JNICALL Java_com_madv360_glrenderer_PanoCameraController_createNativePanoCameraController(JNIEnv* env, jobject self, jobject panoRenderer);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_releaseNativePanoCameraController(JNIEnv* env, jobject self);

JNIEXPORT jboolean JNICALL Java_com_madv360_glrenderer_PanoCameraController_getEnablePitchDragging(JNIEnv* env, jobject self);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setEnablePitchDragging(JNIEnv* env, jobject self, jboolean enablePitchDragging);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setFOVDegree(JNIEnv* env, jobject self, jint fovDegree);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setUIOrientationImpl(JNIEnv* env, jobject self, jint orientation);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setGyroRotationMatrixImpl(JNIEnv* env, jobject self, jfloatArray matrix, jint orientation);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_startTouchControl(JNIEnv* env, jobject self, jobject normalizedTouchPoint);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setDragPoint(JNIEnv* env, jobject self, jobject normalizedTouchPoint);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_stopTouchControl(JNIEnv* env, jobject self, jobject normalizedVelocity);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_resetViewPosition(JNIEnv* env, jobject self);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_adjustDragAxis(JNIEnv* env, jobject self);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_update(JNIEnv* env, jobject self, jfloat dtSeconds);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setModelPostRotation(JNIEnv* env, jobject self, jobject from, jobject to);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setGyroMatrix(JNIEnv* env, jobject self, jfloatArray gyroMatrix, jint rank);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setAsteroidMode(JNIEnv* env, jobject self, jboolean set);

JNIEXPORT jobject JNICALL Java_com_madv360_glrenderer_PanoCameraController_getEulerAnglesFromViewMatrix(JNIEnv* env, jobject self);

#ifdef __cplusplus
}
#endif

#endif //MADV1_0_PANOCAMERACONTROLLERGLUE_H
