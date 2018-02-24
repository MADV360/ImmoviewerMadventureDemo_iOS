//
// Created by QiuDong on 16/5/30.
//
#include "MadvFrameworkGlue.h"
#include "GLFilters/GLFilterCache.h"
#include "GLRenderTexture.h"
#include "EXIFParser.h"
#include "MadvUtils.h"
#include <fstream>
#include <stdio.h>

using namespace std;

static jclass clazz_Vec2f = NULL;
static jfieldID field_Vec2f_x = NULL;
static jfieldID field_Vec2f_y = NULL;

static jclass clazz_Vec3f = NULL;
static jfieldID field_Vec3f_x = NULL;
static jfieldID field_Vec3f_y = NULL;
static jfieldID field_Vec3f_z = NULL;

static jclass clazz_Renderer = NULL;
static jfieldID field_Renderer_nativeGLRendererPointer = NULL;

static jclass clazz_FilterCache = NULL;
static jfieldID field_FilterCache_nativeGLFilterCachePointer = NULL;

static jclass clazz_GLRenderTexture = NULL;
static jfieldID field_GLRenderTexture_nativeGLRenderTexturePointer = NULL;

static jmethodID method_Vec2f_CtorFF = NULL;

Vec2f Vec2fFromJava(JNIEnv *env, jobject vec2Obj) {
    if (NULL == clazz_Vec2f)
    {
        clazz_Vec2f = env->GetObjectClass(vec2Obj);
        ALOGE("Vec2f class = %ld", clazz_Vec2f);
        field_Vec2f_x = env->GetFieldID(clazz_Vec2f, "x", "F");
        ALOGE("field_Vec2f_x = %ld", field_Vec2f_x);
        field_Vec2f_y = env->GetFieldID(clazz_Vec2f, "y", "F");
    }
    Vec2f ret;
    if (NULL != vec2Obj)
    {
        ret.width = (GLfloat) env->GetFloatField(vec2Obj, field_Vec2f_x);
        ret.height = (GLfloat) env->GetFloatField(vec2Obj, field_Vec2f_y);
    }
    else
    {
        ret.width = ret.height = 0;
    }
    return ret;
}

Vec3f Vec3fFromJava(JNIEnv *env, jobject vec3Obj) {
    if (NULL == clazz_Vec3f)
    {
        clazz_Vec3f = env->GetObjectClass(vec3Obj);
        ALOGE("Vec3f class = %ld", clazz_Vec3f);
        field_Vec3f_x = env->GetFieldID(clazz_Vec3f, "x", "F");
        ALOGE("field_Vec3f_x = %ld", field_Vec3f_x);
        field_Vec3f_y = env->GetFieldID(clazz_Vec3f, "y", "F");
        field_Vec3f_z = env->GetFieldID(clazz_Vec3f, "z", "F");
    }
    Vec3f ret;
    if (NULL != vec3Obj)
    {
        ret.x = (GLfloat) env->GetFloatField(vec3Obj, field_Vec3f_x);
        ret.y = (GLfloat) env->GetFloatField(vec3Obj, field_Vec3f_y);
        ret.z = (GLfloat) env->GetFloatField(vec3Obj, field_Vec3f_z);
    }
    else
    {
        ret.x = ret.y = ret.z = 0;
    }
    return ret;
}

MadvGLRenderer_Android* getCppRendererFromJavaRenderer(JNIEnv* env, jobject self) {
    if (NULL == clazz_Renderer)
    {
        clazz_Renderer = env->GetObjectClass(self);
        ALOGE("My class = %ld", clazz_Renderer);
        field_Renderer_nativeGLRendererPointer = env->GetFieldID(clazz_Renderer, "nativeGLRendererPointer", "J");
        ALOGE("field_Renderer_nativeGLRendererPointer = %ld", field_Renderer_nativeGLRendererPointer);
    }
    jlong pointer = env->GetLongField(self, field_Renderer_nativeGLRendererPointer);
    MadvGLRenderer_Android* ret = (MadvGLRenderer_Android*) (void*) pointer;
    return ret;
}

void setCppRendererFromJavaRenderer(JNIEnv* env, jobject self, MadvGLRenderer_Android* pRenderer) {
    if (NULL == clazz_Renderer)
    {
        clazz_Renderer = env->GetObjectClass(self);
        field_Renderer_nativeGLRendererPointer = env->GetFieldID(clazz_Renderer, "nativeGLRendererPointer", "J");
    }
    jlong pointer = (jlong) pRenderer;
    env->SetLongField(self, field_Renderer_nativeGLRendererPointer, pointer);
}

GLFilterCache* getCppFilterCacheFromJavaFilterCache(JNIEnv* env, jobject self) {
    if (NULL == clazz_FilterCache)
    {
        clazz_FilterCache = env->GetObjectClass(self);
        field_FilterCache_nativeGLFilterCachePointer = env->GetFieldID(clazz_FilterCache, "nativeGLFilterCachePointer", "J");
    }
    jlong pointer = env->GetLongField(self, field_FilterCache_nativeGLFilterCachePointer);
    GLFilterCache* ret = (GLFilterCache*) (void*) pointer;
    return ret;
}

void setCppFilterCacheFromJavaFilterCache(JNIEnv* env, jobject self, GLFilterCache* pGLFilterCache) {
    if (NULL == clazz_FilterCache)
    {
        clazz_FilterCache = env->GetObjectClass(self);
        field_FilterCache_nativeGLFilterCachePointer = env->GetFieldID(clazz_FilterCache, "nativeGLFilterCachePointer", "J");
    }
    jlong pointer = (jlong) pGLFilterCache;
    env->SetLongField(self, field_FilterCache_nativeGLFilterCachePointer, pointer);
}

GLRenderTexture* getGLRenderTextureFromJava(JNIEnv* env, jobject self) {
    if (NULL == clazz_GLRenderTexture)
    {
        clazz_GLRenderTexture = env->GetObjectClass(self);
        field_GLRenderTexture_nativeGLRenderTexturePointer = env->GetFieldID(clazz_GLRenderTexture, "nativeGLRenderTexturePointer", "J");
    }
    jlong pointer = env->GetLongField(self, field_GLRenderTexture_nativeGLRenderTexturePointer);
    GLRenderTexture* ret = (GLRenderTexture*) (void*) pointer;
    return ret;
}

void setGLRenderTextureToJava(JNIEnv* env, jobject self, GLRenderTexture* pGLRenderTexture) {
    if (NULL == clazz_GLRenderTexture)
    {
        clazz_GLRenderTexture = env->GetObjectClass(self);
        field_GLRenderTexture_nativeGLRenderTexturePointer = env->GetFieldID(clazz_GLRenderTexture, "nativeGLRenderTexturePointer", "J");
    }
    jlong pointer = (jlong) pGLRenderTexture;
    env->SetLongField(self, field_GLRenderTexture_nativeGLRenderTexturePointer, pointer);
}

JNIEXPORT jlong JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_createNativeGLRenderer
        (JNIEnv* env, jobject self, jstring lutPath, jobject srcTextureSizeL, jobject srcTextureSizeR) {
    ALOGE("Java_com_madv360_glrenderer_MadvGLRenderer_createNativeGLRenderer");
    jboolean copied = false;
    const char* cstrLUTPath = (lutPath == NULL ? NULL : env->GetStringUTFChars(lutPath, &copied));
//    ALOGE("LUT Path : isCopy = %d, %s", copied, cstrLUTPath);
    Vec2f leftSrcTextureSize = Vec2fFromJava(env, srcTextureSizeL);
    Vec2f rightSrcTextureSize = Vec2fFromJava(env, srcTextureSizeR);

    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (glRenderer)
    {
        delete glRenderer;
    }
    glRenderer = new MadvGLRenderer_Android(cstrLUTPath, leftSrcTextureSize, rightSrcTextureSize, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
    setCppRendererFromJavaRenderer(env, self, glRenderer);

    if (lutPath && copied)
    {
        env->ReleaseStringUTFChars(lutPath, cstrLUTPath);
    }

    return (long)(void*)glRenderer;
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_releaseNativeGLRenderer
                (JNIEnv* env, jobject self) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (glRenderer)
    {
        delete glRenderer;
    }
    setCppRendererFromJavaRenderer(env, self, NULL);
}

JNIEXPORT jlong JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_clearCachedLUT
        (JNIEnv* env, jclass clazz, jstring lutPath) {
    jboolean copied = false;
    const char* cstrLUTPath = (lutPath == NULL ? NULL : env->GetStringUTFChars(lutPath, &copied));
    clearCachedLUT(cstrLUTPath);
    if (lutPath && copied)
    {
        env->ReleaseStringUTFChars(lutPath, cstrLUTPath);
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setSourceTextures
(JNIEnv* env, jobject self, jboolean separateSourceTexture, jint srcTextureL, jint srcTextureR, jobject srcTextureSizeL, jobject srcTextureSizeR, jint srcTextureTarget, jboolean isYUVColorSpace) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;
//    ALOGE("srcTextureL = %d, srcTextureR = %d, srcTextureTarget = %x", srcTextureL, srcTextureR, srcTextureTarget);
    glRenderer->setSourceTextures(/*separateSourceTexture, */srcTextureL, srcTextureR, srcTextureTarget, isYUVColorSpace);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setSourceYUVTextures
        (JNIEnv* env, jobject self, jboolean separateSourceTexture, jintArray srcTextureL, jintArray srcTextureR, jobject srcTextureSizeL, jobject srcTextureSizeR, jint srcTextureTarget, jboolean isYUVColorSpace) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;
//    ALOGE("srcTextureL = %d, srcTextureR = %d, srcTextureTarget = %x", srcTextureL, srcTextureR, srcTextureTarget);
    jboolean isCopyR, isCopyL;
    jint* dataL = env->GetIntArrayElements(srcTextureL, &isCopyL);
    jint* dataR = env->GetIntArrayElements(srcTextureR, &isCopyR);

    glRenderer->setSourceTextures(/*separateSourceTexture, */dataL, dataR, srcTextureTarget, isYUVColorSpace);

    if (isCopyL) free(dataL);
    if (isCopyR) free(dataR);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setCapsTexture
        (JNIEnv* env, jobject self, jint texture, jint textureTarget) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;
//    ALOGE("srcTextureL = %d, srcTextureR = %d, srcTextureTarget = %x", srcTextureL, srcTextureR, srcTextureTarget);
    glRenderer->setCapsTexture(texture, textureTarget);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setNeedDrawCaps
        (JNIEnv* env, jobject self, jboolean drawCaps) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;
//    ALOGE("srcTextureL = %d, srcTextureR = %d, srcTextureTarget = %x", srcTextureL, srcTextureR, srcTextureTarget);
    glRenderer->setNeedDrawCaps(drawCaps);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_draw__IIII
(JNIEnv* env, jobject self, jint x, jint y, jint width, jint height) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;

    glRenderer->draw(x,y,width,height);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_draw__IIIIIZIII
        (JNIEnv* env, jobject self, jint currentDisplayMode, jint x, jint y, jint width, jint height, jboolean separateSourceTextures, jint srcTextureType, jint leftSrcTexture, jint rightSrcTexture) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;

    glRenderer->draw(currentDisplayMode, x,y,width,height/*, separateSourceTextures*/, srcTextureType, leftSrcTexture, rightSrcTexture);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_drawRemappedPanorama__IIIII(JNIEnv* env, jobject self, jint x, jint y, jint width, jint height, jint cubemapFaceSize) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;
    
    glRenderer->drawRemappedPanorama(x, y, width, height, cubemapFaceSize);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_drawRemappedPanorama__IIIIIIII(JNIEnv* env, jobject self, jint lutStitchMode, jint x, jint y, jint width, jint height, jint cubemapFaceSize, jint srcTextureType, jint srcTexture) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;

    glRenderer->drawRemappedPanorama(lutStitchMode, x, y, width, height, cubemapFaceSize, srcTextureType, srcTexture);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setGyroMatrix
        (JNIEnv* env, jobject self, jfloatArray matrix, jint rank) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer)
        return;
    if (NULL == matrix || 0 == rank)
        return;

    jboolean isCopy;
    jfloat* matrixData = env->GetFloatArrayElements(matrix, &isCopy);

    glRenderer->setGyroMatrix(matrixData, rank);
    if (isCopy)
    {
        env->ReleaseFloatArrayElements(matrix, matrixData, 0);
    }
}

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_getDisplayMode
        (JNIEnv* env, jobject self) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return 0;

    return glRenderer->getDisplayMode();
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setDisplayMode
               (JNIEnv* env, jobject self, jint displayMode) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;

    glRenderer->setDisplayMode(displayMode);
}

JNIEXPORT jboolean JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_getIsYUVColorSpace
        (JNIEnv* env, jobject self) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return 0;
    return glRenderer->getIsYUVColorSpace();
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setIsYUVColorSpace
                   (JNIEnv* env, jobject self, jboolean isYUVColorSpace) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;

    glRenderer->setIsYUVColorSpace(isYUVColorSpace);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setFlipY
        (JNIEnv* env, jobject self, jboolean flipY) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;
//    ALOGE("setFlipY : %d", flipY);
    glRenderer->setFlipY(flipY);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setTextureMatrix___3F
        (JNIEnv* env, jobject self, jfloatArray textureMatrix) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;

    if (!textureMatrix) return;
    jboolean isArrayCopied = false;
    jfloat* data = env->GetFloatArrayElements(textureMatrix, &isArrayCopied);
    kmScalar matrixData[16];
    for (int i=0; i<16; ++i) matrixData[i] = data[i];
    kmMat4 matrix;
    kmMat4Fill(&matrix, matrixData);
    glRenderer->setTextureMatrix(&matrix);

    if (isArrayCopied)
    {
        env->ReleaseFloatArrayElements(textureMatrix, data, 0);
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setTextureMatrix___3FI
        (JNIEnv* env, jobject self, jfloatArray textureMatrix, jint videoCaptureResolution) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;

    if (!textureMatrix) return;
    jboolean isArrayCopied = false;
    jfloat* data = env->GetFloatArrayElements(textureMatrix, &isArrayCopied);
    kmScalar matrixData[16];
    for (int i=0; i<16; ++i) matrixData[i] = data[i];
    kmMat4 matrix;
    kmMat4Fill(&matrix, matrixData);
    glRenderer->setTextureMatrix(&matrix, videoCaptureResolution);

    if (isArrayCopied)
    {
        env->ReleaseFloatArrayElements(textureMatrix, data, 0);
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setIllusionTextureMatrix___3F
        (JNIEnv* env, jobject self, jfloatArray illusionTextureMatrix) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;

    if (!illusionTextureMatrix) return;
    jboolean isArrayCopied = false;
    jfloat* data = env->GetFloatArrayElements(illusionTextureMatrix, &isArrayCopied);
    kmScalar matrixData[16];
    for (int i=0; i<16; ++i) matrixData[i] = data[i];
    kmMat4 matrix;
    kmMat4Fill(&matrix, matrixData);
    glRenderer->setIllusionTextureMatrix(&matrix);

    if (isArrayCopied)
    {
        env->ReleaseFloatArrayElements(illusionTextureMatrix, data, 0);
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setIllusionTextureMatrix___3FI
        (JNIEnv* env, jobject self, jfloatArray illusionTextureMatrix, jint videoCaptureResolution) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;

    if (!illusionTextureMatrix) return;
    jboolean isArrayCopied = false;
    jfloat* data = env->GetFloatArrayElements(illusionTextureMatrix, &isArrayCopied);
    kmScalar matrixData[16];
    for (int i=0; i<16; ++i) matrixData[i] = data[i];
    kmMat4 matrix;
    kmMat4Fill(&matrix, matrixData);
    glRenderer->setIllusionTextureMatrix(&matrix, videoCaptureResolution);

    if (isArrayCopied)
    {
        env->ReleaseFloatArrayElements(illusionTextureMatrix, data, 0);
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setModelPostRotation(JNIEnv* env, jobject self, jobject fromVector, jobject toVector) {
    MadvGLRenderer_Android *glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;

    Vec3f ccFromVector = Vec3fFromJava(env, fromVector);
    Vec3f ccToVector = Vec3fFromJava(env, toVector);
    kmVec3 kmFromVector = {ccFromVector.x, ccFromVector.y, ccFromVector.z};
    kmVec3 kmToVector = {ccToVector.x, ccToVector.y, ccToVector.z};
    glRenderer->setModelPostRotation(kmFromVector, kmToVector);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setEnableDebug(JNIEnv* env, jobject self, jboolean enableDebug) {
    MadvGLRenderer_Android* glRenderer = getCppRendererFromJavaRenderer(env, self);
    if (!glRenderer) return;

    glRenderer->setEnableDebug(enableDebug);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_renderMadvJPEGToJPEG(JNIEnv* env, jclass selfClass, jstring destJpegPath, jstring sourceJpegPath, jint dstWidth, jint dstHeight, jstring lutPath, jint filterID, jstring glFilterResourcePath, jfloatArray gyroMatrix, jint gyroMatrixRank) {
    jboolean isDestJpegPathCopied = false;
    const char* cstrDestJpegPath = destJpegPath ? env->GetStringUTFChars(destJpegPath, &isDestJpegPathCopied) : NULL;

    jboolean isSourceJpegPathCopied = false;
    const char* cstrSourceJpegPath = sourceJpegPath ? env->GetStringUTFChars(sourceJpegPath, &isSourceJpegPathCopied) : NULL;

    jboolean isLUTPathCopied = false;
    const char* cstrLUTPath = lutPath ? env->GetStringUTFChars(lutPath, &isLUTPathCopied) : NULL;

    jboolean isResourcePathCopied = false;
    const char* cstrResourcePath = glFilterResourcePath ? env->GetStringUTFChars(glFilterResourcePath, &isResourcePathCopied) : NULL;

    jboolean isGyroMatrixCopied = false;
    jfloat* gyroMatrixBytes = gyroMatrix ? env->GetFloatArrayElements(gyroMatrix, &isGyroMatrixCopied) : NULL;

    MadvGLRenderer::renderMadvJPEGToJPEG(cstrDestJpegPath, cstrSourceJpegPath, dstWidth, dstHeight, cstrLUTPath, filterID, cstrResourcePath, gyroMatrixBytes, gyroMatrixRank, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);

    if (isGyroMatrixCopied)
    {
        env->ReleaseFloatArrayElements(gyroMatrix, gyroMatrixBytes, 0);
    }
    if (isDestJpegPathCopied)
    {
        env->ReleaseStringUTFChars(destJpegPath, cstrDestJpegPath);
    }

    if (isSourceJpegPathCopied)
    {
        env->ReleaseStringUTFChars(sourceJpegPath, cstrSourceJpegPath);
    }

    if (isLUTPathCopied)
    {
        env->ReleaseStringUTFChars(lutPath, cstrLUTPath);
    }

    if (isResourcePathCopied)
    {
        env->ReleaseStringUTFChars(glFilterResourcePath, cstrResourcePath);
    }
}

JNIEXPORT jboolean JNICALL Java_com_madv360_madv_utils_FileUtil_saveFileChunk
        (JNIEnv* env, jclass selfClass, jstring filePath, jlong fileOffset, jbyteArray data, jlong dataOffset, jlong length) {
    ALOGE("Java_com_madv360_madv_utils_FileUtil_saveFileChunk");
    if (NULL == filePath || NULL == data) return false;

    jboolean copied = false;
    const char* cstrFilePath = env->GetStringUTFChars(filePath, &copied);
//    ALOGE("cstrFilePath = %s, copied = %d", cstrFilePath, copied);

    jbyte* bytes = env->GetByteArrayElements(data,0);
    jsize bytesLength = env->GetArrayLength(data);
//    ALOGE("bytesLength = %d", bytesLength);

    FILE* fp = fopen(cstrFilePath, "ab+");
    int ferr = errno;//ferror(fp);//
    if (0 == fp)
    {
        ALOGE("CreateIfExist file %s : fp=%ld, ferr=%d, strerr=%s", cstrFilePath, (long)fp, ferr, strerror(ferr));
        return false;
    }
//    ALOGE("CreateIfExist file %s OK: fp=%ld, ferr=%d, strerr=%s", cstrFilePath, (long)fp, ferr, strerror(ferr));
    fclose(fp);

    ofstream ofs(cstrFilePath, ios::out | ios::in | ios::binary);
    //*
    const uint64_t Limit2G = 0x80000000;
    if (fileOffset >= Limit2G)
    {
//        ALOGV("#0 : fileOffset = %ld", fileOffset);
        ofs.seekp(0x40000000, ios::beg);
        ofs.seekp(0x40000000, ios::cur);
        for (fileOffset -= Limit2G; fileOffset >= Limit2G; fileOffset -= Limit2G)
        {
            ofs.seekp(0x40000000, ios::cur);
            ofs.seekp(0x40000000, ios::cur);
//            ALOGV("#1 : fileOffset = %ld", fileOffset);
        }
//        ALOGV("#2 : fileOffset = %ld", fileOffset);
        ofs.seekp(fileOffset, ios::cur);
    }
    else
    {
//        ALOGV("#3 : fileOffset = %ld", fileOffset);
        ofs.seekp(fileOffset, ios::beg);
        fileOffset = 0;
    }
    /*/
    ofs.seekp(0x40000000, ios::beg);
    ofs.seekp(0x40000000, ios::cur);
    ofs.seekp(0x40000000, ios::cur);
    ofs.seekp(0x40000000, ios::cur);
    ofs.seekp(fileOffset, ios::cur);
    //*/
    ALOGV("saveFileChunk #4 : bytes=%lx, dataOffset=%ld, length=%ld, bytesLength=%ld", (long)bytes, dataOffset, length, bytesLength);
    if (length > 0)
    {
        length = (length > bytesLength ? bytesLength : length);
        ofs.write((const char*)bytes + dataOffset, (int)length);
    }

//    ALOGV("saveFileChunk #5");
    ofs.flush();
//    ALOGV("saveFileChunk #6");
    ofs.close();
//    ALOGV("saveFileChunk #7");
    if (copied)
    {
        env->ReleaseStringUTFChars(filePath, cstrFilePath);
    }
    ALOGE("saveFileChunk DONE");
    return true;
}

#include "EXIFParser.h"

JNIEXPORT jfloatArray JNICALL Java_com_madv360_madv_utils_FileUtil_getGyroMatrixFromString(JNIEnv* env, jclass selfClass, jstring gyroMatrixString) {
    if (NULL == gyroMatrixString)
    {
        return NULL;
    }

    jboolean copied = false;
    const char* cstrGyroMatrixString = env->GetStringUTFChars(gyroMatrixString, &copied);

    jfloatArray ret = NULL;
    float* gyroMatrixData = (float*) malloc(sizeof(float) * 9);
    int matrixSize = copyGyroMatrixFromString(gyroMatrixData, cstrGyroMatrixString);
    matrixSize *= matrixSize;
    if (0 < matrixSize)
    {
        ret = env->NewFloatArray(matrixSize);
        env->SetFloatArrayRegion(ret, 0, matrixSize, gyroMatrixData);
    }

    free(gyroMatrixData);
    if (copied)
    {
        env->ReleaseStringUTFChars(gyroMatrixString, cstrGyroMatrixString);
    }

    return ret;
}

JNIEXPORT jboolean JNICALL Java_com_madv360_madv_utils_FileUtil_extractLUTFiles
        (JNIEnv* env, jclass selfClass, jstring destDirectory, jstring lutBinFilePath, jint fileOffset) {
    jboolean ret = true;
    int finallyCase = 1;

    jboolean binFilePathCopied = false;
    const char* cstrBinFilePath = env->GetStringUTFChars(lutBinFilePath, &binFilePathCopied);
//    ALOGE("cstrFilePath = %s, copied = %d", cstrBinFilePath, binFilePathCopied);
    jboolean destDirCopied = false;
    const char* cstrDestDirectory = env->GetStringUTFChars(destDirectory, &destDirCopied);
//    ALOGE("cstrDestDir = %s, copied = %d", cstrDestDirectory, destDirCopied);
    char* pngFilePath = NULL;
    uint8_t* pngData = NULL;
    fstream* pOfs = NULL;

    do
    {
        ifstream ifs(cstrBinFilePath, ios::in | ios::binary);
//    ALOGE("extractLUTFiles : fileOffset = %u sizeof(long) = %d", fileOffset, sizeof(long));
//    fseek(fp, fileOffset, SEEK_CUR);
        const uint32_t Limit2G = 0x80000000;
        if (fileOffset >= Limit2G)
        {
            uint32_t fileOffsetLeft = fileOffset;
//        ALOGE("extractLUTFiles : #0 fileOffsetLeft = %u", fileOffsetLeft);
            ifs.seekg(0x40000000, ios::beg);
            ifs.seekg(0x40000000, ios::cur);
            for (fileOffsetLeft -= Limit2G; fileOffsetLeft >= Limit2G; fileOffsetLeft -= Limit2G)
            {
//            ALOGE("extractLUTFiles : #1 fileOffsetLeft = %u", fileOffsetLeft);
                ifs.seekg(0x40000000, ios::cur);
                ifs.seekg(0x40000000, ios::cur);
            }
//        ALOGE("extractLUTFiles : #2 fileOffsetLeft = %u", fileOffsetLeft);
            ifs.seekg(fileOffsetLeft, ios::cur);
        }
        else
        {
            ifs.seekg(fileOffset, ios::beg);
        }

        if (ifs.fail())
        {
            ALOGE("ifs.fail() #1");
            finallyCase = 0;
            ret = false;
            break;
        }

        uint32_t offsets[8];
        uint32_t sizes[8];
        uint32_t totalSize = 0;
        uint32_t maxSize = 0;
        for (int i=0; i<8; ++i)
        {
            ifs.read((char*)&offsets[i], sizeof(uint32_t));
            ifs.read((char*)&sizes[i], sizeof(uint32_t));
//        ALOGE("offsets[%d] = %u, sizes[%d] = %u", i,offsets[i], i,sizes[i]);
            if (sizes[i] > maxSize) maxSize = sizes[i];
            totalSize += sizes[i];

            if (ifs.fail())
            {
                ALOGE("ifs.fail() #2");
                finallyCase = 0;
                ret = false;
                break;
            }
        }
        ifs.close();
//    ALOGV("totalSize = %u", totalSize);

        const char* pngFileNames[] = {"/r_x_int.png", "/r_x_min.png",
                                      "/r_y_int.png", "/r_y_min.png",
                                      "/l_x_int.png", "/l_x_min.png",
                                      "/l_y_int.png", "/l_y_min.png"};
        pngFilePath = (char*) malloc(strlen(cstrDestDirectory) + strlen(pngFileNames[0]) + 1);

        pngData = (uint8_t*) malloc(maxSize);
        pOfs = new fstream(cstrBinFilePath, ios::out | ios::in | ios::binary);
        if (fileOffset >= Limit2G)
        {
            pOfs->seekp(0x40000000, ios::beg);
            pOfs->seekp(0x40000000, ios::cur);
            for (fileOffset -= Limit2G; fileOffset >= Limit2G; fileOffset -= Limit2G)
            {
                pOfs->seekp(0x40000000, ios::cur);
                pOfs->seekp(0x40000000, ios::cur);
            }
            pOfs->seekp(fileOffset, ios::cur);
        }
        else
        {
            pOfs->seekp(fileOffset, ios::beg);
        }

        if (pOfs->fail())
        {
            ALOGE("pOfs->fail() #1");
            ret = false;
            break;
        }

        uint64_t currentOffset = 0;
        for (int i=0; i<8; ++i)
        {
            pOfs->seekp(offsets[i] - currentOffset, ios::cur);
            pOfs->read((char*)pngData, sizes[i]);

            if (pOfs->fail())
            {
                ALOGE("pOfs->fail() #2");
                ret = false;
                break;
            }

            sprintf(pngFilePath, "%s%s", cstrDestDirectory, pngFileNames[i]);
            FILE* fout = fopen(pngFilePath, "wb+");
            fwrite(pngData, sizes[i], 1, fout);
            fclose(fout);
            currentOffset = offsets[i] + sizes[i];
        }
    }
    while (false);

    if (1 == finallyCase)
    {
        if (pOfs) pOfs->close();
    }

    if (pngData) free(pngData);
    if (pngFilePath) free(pngFilePath);

    if (binFilePathCopied)
    {
        env->ReleaseStringUTFChars(lutBinFilePath, cstrBinFilePath);
    }
    if (destDirCopied)
    {
        env->ReleaseStringUTFChars(destDirectory, cstrDestDirectory);
    }

    return ret;
}

JNIEXPORT jbyteArray JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_renderThumbnail
        (JNIEnv* env, jclass selfClass, jint sourceTexture, jobject jobjSrcSize, jobject jobjDestSize, jstring lutPath, jint longitudeSegments, jint latitudeSegments) {
    ALOGE("Java_com_madv360_madv_utils_FileUtil_renderThubmnail");
    jboolean copied = false;
    const char* cstrLUTPath;
    if (NULL == lutPath)
    {
        cstrLUTPath = NULL;
    }
    else
    {
        cstrLUTPath = env->GetStringUTFChars(lutPath, &copied);
        ALOGE("cstrLUTPath = %s, copied = %d", cstrLUTPath, copied);
    }

    Vec2f srcSize = Vec2fFromJava(env, jobjSrcSize);
    Vec2f dstSize = Vec2fFromJava(env, jobjDestSize);

    jbyte* rgbData = (jbyte*) MadvGLRenderer_Android::renderThumbnail(sourceTexture, srcSize, dstSize, cstrLUTPath, longitudeSegments, latitudeSegments);
    int byteLength = 4 * dstSize.width * dstSize.height;
    jbyteArray jaRGBArray = env->NewByteArray(byteLength);
    env->SetByteArrayRegion(jaRGBArray, 0, byteLength, rgbData);

    if (copied)
    {
        env->ReleaseStringUTFChars(lutPath, cstrLUTPath);
    }
    ALOGE("renderThumbnail DONE");

    return jaRGBArray;
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLFilterCache_init(JNIEnv* env, jobject self, jstring resourceDirectory) {
    GLFilterCache* filterCache = getCppFilterCacheFromJavaFilterCache(env, self);
    if (filterCache)
    {
        delete filterCache;
    }

    jboolean copied = false;
    const char* cstrResDir = (resourceDirectory == NULL ? NULL : env->GetStringUTFChars(resourceDirectory, &copied));

    filterCache = new GLFilterCache(cstrResDir);
    setCppFilterCacheFromJavaFilterCache(env, self, filterCache);

    if (copied)
    {
        env->ReleaseStringUTFChars(resourceDirectory, cstrResDir);
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLFilterCache_dealloc(JNIEnv* env, jobject self) {
    GLFilterCache* filterCache = getCppFilterCacheFromJavaFilterCache(env, self);
    if (filterCache)
    {
        delete filterCache;
    }
    setCppFilterCacheFromJavaFilterCache(env, self, NULL);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLFilterCache_render__IFFFFII(JNIEnv* env, jobject self,
                                                                        jint filterID, jfloat x, jfloat y, jfloat width, jfloat height, jint sourceTexture, jint sourceTextureTarget) {
    GLFilterCache* filterCache = getCppFilterCacheFromJavaFilterCache(env, self);
    if (filterCache)
    {
        filterCache->render(filterID, x, y, width, height, sourceTexture, sourceTextureTarget);
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLFilterCache_render__IFFFFIIILcom_madv360_glrenderer_Vec2f_2Lcom_madv360_glrenderer_Vec2f_2(JNIEnv* env, jobject self,
                                                                        jint filterID, jfloat x, jfloat y, jfloat width, jfloat height, jint sourceTexture, jint sourceTextureTarget, jint sourceOrientation, jobject jTexcoordOrigin, jobject jTexcoordSize) {
    GLFilterCache* filterCache = getCppFilterCacheFromJavaFilterCache(env, self);
    if (filterCache)
    {
        Vec2f texcoordOrigin = Vec2fFromJava(env, jTexcoordOrigin);
        Vec2f texcoordSize = Vec2fFromJava(env, jTexcoordSize);
        filterCache->render(filterID, x, y, width, height, sourceTexture, sourceTextureTarget, (Orientation2D)sourceOrientation, texcoordOrigin, texcoordSize);
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLFilterCache_releaseGLObjects(JNIEnv* env, jobject self) {
    GLFilterCache* filterCache = getCppFilterCacheFromJavaFilterCache(env, self);
    if (filterCache)
    {
        filterCache->releaseGLObjects();
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLRenderTexture_init(JNIEnv* env, jobject self, jint width, jint height, jboolean enableDepthTest) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        delete renderTexture;
    }
    renderTexture = new GLRenderTexture(width, height, enableDepthTest);
    setGLRenderTextureToJava(env, self, renderTexture);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLRenderTexture_dealloc(JNIEnv* env, jobject self) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        delete renderTexture;
    }
    setGLRenderTextureToJava(env, self, NULL);
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLRenderTexture_releaseGLObjects(JNIEnv* env, jobject self) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        renderTexture->releaseGLObjects();
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLRenderTexture_blit(JNIEnv* env, jobject self) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        renderTexture->blit();
    }
}

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLRenderTexture_unblit(JNIEnv* env, jobject self) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        renderTexture->unblit();
    }
}

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_copyPixelData(JNIEnv* env, jobject self, jbyteArray jData) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
//        int bytesLength = renderTexture->bytesLength();
//        jbyteArray array = env->NewByteArray(bytesLength);
//        GLubyte* bytes = renderTexture->copyPixelData();
//        env->SetByteArrayRegion(array, 0, bytesLength, (const jbyte*)bytes);
//        return array;
        int bytesLength = env->GetArrayLength(jData);
        jboolean isCopy;
        jbyte* data = env->GetByteArrayElements(jData, &isCopy);
        jint ret = renderTexture->copyPixelData((uint8_t*)data, 0, bytesLength);
        if (isCopy)
        {
            free(data);
        }
        return ret;
    }
    return 0;
}

JNIEXPORT jbyteArray JNICALL Java_com_madv360_glrenderer_GLRenderTexture_copyPixelDataFromPBO(JNIEnv* env, jobject self) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        int bytesLength = renderTexture->bytesLength();
        GLubyte* pixels = renderTexture->copyPixelDataFromPBO(0, bytesLength);
        if (pixels)
        {
            jbyteArray ret = env->NewByteArray(bytesLength);
            ALOGE("copyPixelDataFromPBO : pixels = %lx, ret = %lx, bytesLength = %d", (long)pixels, (long)ret, bytesLength);
            env->SetByteArrayRegion(ret, 0, bytesLength, (const jbyte*) pixels);
            ALOGE("copyPixelDataFromPBO : SetByteArrayRegion OK");
            return ret;
        }
    }
    return NULL;
}

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_getFramebuffer(JNIEnv* env, jobject self) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        return renderTexture->getFramebuffer();
    }
    return 0;
}

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_getTexture(JNIEnv* env, jobject self) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        return renderTexture->getTexture();
    }
    return 0;
}

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_getTextureTarget(JNIEnv* env, jobject self) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        return renderTexture->getTextureTarget();
    }
    return 0;
}

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_getWidth(JNIEnv* env, jobject self) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        return renderTexture->getWidth();
    }
    return 0;
}

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_getHeight(JNIEnv* env, jobject self) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        return renderTexture->getHeight();
    }
    return 0;
}

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_bytesLength(JNIEnv* env, jobject self) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        return renderTexture->bytesLength();
    }
    return 0;
}

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_resizeIfNecessary(JNIEnv* env, jobject self, jint width, jint height) {
    GLRenderTexture* renderTexture = getGLRenderTextureFromJava(env, self);
    if (renderTexture)
    {
        return renderTexture->resizeIfNecessary(width, height);
    }
    return -2;
}
