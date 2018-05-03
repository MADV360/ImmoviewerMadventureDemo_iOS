//
// Created by QiuDong on 2017/6/22.
//

#include "PanoCameraControllerGlue.h"
#include "PanoCameraController.h"
#include "GLCamera.h"
#include "MadvFrameworkGlue.h"
#include "Log.h"
#include "AutoRef.h"

static jclass clazz_PanoCameraController = NULL;
static jfieldID field_PanoCameraController_nativePanoCameraControllerPointer = NULL;

void initPanoCameraControllerClassAndFields(JNIEnv* env, jobject self) {
    if (NULL == clazz_PanoCameraController)
    {
        clazz_PanoCameraController = env->GetObjectClass(self);
        ALOGE("My class = %ld", clazz_PanoCameraController);
        field_PanoCameraController_nativePanoCameraControllerPointer = env->GetFieldID(clazz_PanoCameraController, "nativePanoCameraControllerPointer", "J");
        ALOGE("field_PanoCameraController_nativePanoCameraControllerPointer = %ld", field_PanoCameraController_nativePanoCameraControllerPointer);
    }
}

PanoCameraController* getCppPanoCameraControllerFromJavaObject(JNIEnv* env, jobject self) {
    initPanoCameraControllerClassAndFields(env, self);
    jlong pointer = env->GetLongField(self, field_PanoCameraController_nativePanoCameraControllerPointer);
    PanoCameraController* ret = (PanoCameraController*) (void*) pointer;
    return ret;
}

void setCppPanoCameraControllerToJavaObject(JNIEnv* env, jobject self, PanoCameraController* cPanoCameraController) {
    initPanoCameraControllerClassAndFields(env, self);
    jlong pointer = (jlong) cPanoCameraController;
    env->SetLongField(self, field_PanoCameraController_nativePanoCameraControllerPointer, pointer);
}

JNIEXPORT jlong JNICALL Java_com_madv360_glrenderer_PanoCameraController_createNativePanoCameraController(JNIEnv* env, jobject self, jobject panoRenderer) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (panoCtrl)
    {
        delete panoCtrl;
    }

    MadvGLRenderer_Android* cPanoRenderer = getCppRendererFromJavaRenderer(env, panoRenderer);
    if (NULL == cPanoRenderer)
        panoCtrl = new PanoCameraController((AutoRef<GLCamera>)NULL);
    else
        panoCtrl = new PanoCameraController(cPanoRenderer->glCamera());

    setCppPanoCameraControllerToJavaObject(env, self, panoCtrl);

    return (long)(void*)panoCtrl;
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_releaseNativePanoCameraController(JNIEnv* env, jobject self) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (panoCtrl)
    {
        delete panoCtrl;
    }
    setCppPanoCameraControllerToJavaObject(env, self, NULL);
}

JNIEXPORT jboolean JNICALL Java_com_madv360_glrenderer_PanoCameraController_getEnablePitchDragging(JNIEnv* env, jobject self) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return false;
    }
    return panoCtrl->getEnablePitchDragging();
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setEnablePitchDragging(JNIEnv* env, jobject self, jboolean enablePitchDragging) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }
    panoCtrl->setEnablePitchDragging(enablePitchDragging);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setFOVDegree(JNIEnv* env, jobject self, jint fovDegree) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }
    panoCtrl->setFOVDegree(fovDegree);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setUIOrientationImpl(JNIEnv* env, jobject self, jint orientation) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }
    panoCtrl->setScreenOrientation((Orientation2D) orientation);///!!!
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setGyroRotationMatrixImpl(JNIEnv* env, jobject self, jfloatArray matrix, jint orientation) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }
    jboolean isCopy;
    jfloat* matrixData = env->GetFloatArrayElements(matrix, &isCopy);

    kmMat4 kmMatrix;
    kmMat4Fill(&kmMatrix, matrixData);
// We should remove impact of Pitch(-90) * Roll(-90), so Roll(90) * Pitch(90):
    kmMat4 rollMatrix, pitchMatrix;
    kmMat4RotationZ(&rollMatrix, M_PI/2);
    kmMat4RotationX(&pitchMatrix, M_PI/2);
//    kmMat4Multiply(&kmMatrix, &pitchMatrix, &kmMatrix);
//    kmMat4Multiply(&kmMatrix, &rollMatrix, &kmMatrix);
    kmMat4Multiply(&kmMatrix, &kmMatrix, &rollMatrix);
    kmMat4Multiply(&kmMatrix, &kmMatrix, &pitchMatrix);

    kmQuaternion gyroQuaternion;
    kmQuaternionRotationMatrix(&gyroQuaternion, &kmMatrix);
//ALOGE("#Rotation# orientation=%d", orientation);
    panoCtrl->setScreenOrientation((Orientation2D)orientation);
    panoCtrl->setGyroRotationQuaternion(&gyroQuaternion, true);

    if (isCopy)
    {
        env->ReleaseFloatArrayElements(matrix, matrixData, 0);
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_startTouchControl(JNIEnv* env, jobject self, jobject normalizedTouchPoint) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }

    Vec2f v2fNormalizedTouchPoint = Vec2fFromJava(env, normalizedTouchPoint);
    panoCtrl->startTouchControl({v2fNormalizedTouchPoint.x, v2fNormalizedTouchPoint.y});
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setDragPoint(JNIEnv* env, jobject self, jobject normalizedTouchPoint) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }

    Vec2f v2fNormalizedTouchPoint = Vec2fFromJava(env, normalizedTouchPoint);
    panoCtrl->setDragPoint({v2fNormalizedTouchPoint.x, v2fNormalizedTouchPoint.y});
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_stopTouchControl(JNIEnv* env, jobject self, jobject normalizedVelocity) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }

    Vec2f v2fNormalizedVelocity = Vec2fFromJava(env, normalizedVelocity);
    panoCtrl->stopTouchControl({v2fNormalizedVelocity.x, v2fNormalizedVelocity.y});
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_resetViewPosition(JNIEnv* env, jobject self) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }
    panoCtrl->resetViewPosition();
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_adjustDragAxis(JNIEnv* env, jobject self) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }
    panoCtrl->adjustDragAxis();
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_update(JNIEnv* env, jobject self, jfloat dtSeconds) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }
    panoCtrl->update(dtSeconds);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setModelPostRotation(JNIEnv* env, jobject self, jobject from, jobject to) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }

    Vec3f v3fFrom = Vec3fFromJava(env, from);
    Vec3f v3fTo = Vec3fFromJava(env, to);
    kmVec3 kmv3From = {v3fFrom.x, v3fFrom.y, v3fFrom.z};
    kmVec3 kmv3To = {v3fTo.x, v3fTo.y, v3fTo.z};
    panoCtrl->setModelPostRotation(kmv3From, kmv3To);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setGyroMatrix(JNIEnv* env, jobject self, jfloatArray gyroMatrix, jint rank) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }

    if (NULL == gyroMatrix || 0 == rank)
        return;

    jboolean isCopy;
    jfloat* matrixData = env->GetFloatArrayElements(gyroMatrix, &isCopy);

    panoCtrl->setGyroMatrix(matrixData, rank);

    if (isCopy)
    {
        env->ReleaseFloatArrayElements(gyroMatrix, matrixData, 0);
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_PanoCameraController_setAsteroidMode(JNIEnv* env, jobject self, jboolean set) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return;
    }

    panoCtrl->setAsteroidMode(set);
}

JNIEXPORT jobject JNICALL Java_com_madv360_glrenderer_PanoCameraController_getEulerAnglesFromViewMatrix(JNIEnv* env, jobject self) {
    PanoCameraController* panoCtrl = getCppPanoCameraControllerFromJavaObject(env, self);
    if (NULL == panoCtrl)
    {
        return NULL;
    }

    kmVec3 v3 = panoCtrl->getEulerAnglesFromViewMatrix();
    jobject jV3 = Vec3fToJava(env, Vec3f{v3.x, v3.y, v3.z});
    return jV3;
}
