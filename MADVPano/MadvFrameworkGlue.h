/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
#include "MadvGLRenderer_Android.h"
#include "Log.h"

#ifndef _Included_com_android_madv_glrenderer_MadvGLRenderer
#define _Included_com_android_madv_glrenderer_MadvGLRenderer
#ifdef __cplusplus
extern "C" {
#endif

MadvGLRenderer_Android* getCppRendererFromJavaRenderer(JNIEnv* env, jobject self);

Vec2f Vec2fFromJava(JNIEnv *env, jobject vec2Obj);
jobject Vec2fToJava(JNIEnv* env, Vec2f v2);

Vec3f Vec3fFromJava(JNIEnv *env, jobject vec3Obj);
jobject Vec3fToJava(JNIEnv* env, Vec3f v3);

/*
 * Class:     com_android_madv_glrenderer_MadvGLRenderer
 * Method:    createNativeGLRenderer
 * Signature: (Ljava/lang/String;)J
 */
JNIEXPORT jlong JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_createNativeGLRenderer(JNIEnv* env, jobject self, jstring lutPath, jobject srcTextureSizeL, jobject srcTextureSizeR);

/*
 * Class:     com_android_madv_glrenderer_MadvGLRenderer
 * Method:    releaseNativeGLRenderer
 * Signature: (J)V
 */
JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_releaseNativeGLRenderer
        (JNIEnv *, jobject);

JNIEXPORT jlong JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_clearCachedLUT
        (JNIEnv* env, jclass clazz, jstring lutPath);

/*
 * Class:     com_android_madv_glrenderer_MadvGLRenderer
 * Method:    setSourceTextures
 * Signature: (ZIILcom/android/madv/glrenderer/MadvGLRenderer/SizeF;Lcom/android/madv/glrenderer/MadvGLRenderer/SizeF;IZ)V
 */
JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setSourceTextures
        (JNIEnv *, jobject, jboolean, jint, jint, jobject, jobject, jint, jboolean);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setSourceYUVTextures
        (JNIEnv* env, jobject self, jboolean separateSourceTexture, jintArray srcTextureL, jintArray srcTextureR, jobject srcTextureSizeL, jobject srcTextureSizeR, jint srcTextureTarget, jboolean isYUVColorSpace);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setCapsTexture
        (JNIEnv* env, jobject self, jint texture, jint textureTarget);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setNeedDrawCaps
        (JNIEnv* env, jobject self, jboolean drawCaps);

/*
 * Class:     com_android_madv_glrenderer_MadvGLRenderer
 * Method:    draw
 * Signature: (IIII)V
 */
JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_draw__IIII
        (JNIEnv *, jobject, jint, jint, jint, jint);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_draw__IIIIIZIII
        (JNIEnv* env, jobject self, jint currentDisplayMode, jint x, jint y, jint width, jint height, jboolean separateSourceTextures, jint srcTextureType, jint leftSrcTexture, jint rightSrcTexture);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_drawRemappedPanorama__IIIII(JNIEnv* env, jobject self, jint x, jint y, jint width, jint height, jint cubemapFaceSize);
JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_drawRemappedPanorama__IIIIIIII(JNIEnv* env, jobject self, jint lutStitchMode, jint x, jint y, jint width, jint height, jint cubemapFaceSize, jint srcTextureType, jint srcTexture);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_renderMadvJPEGToJPEG(JNIEnv* env, jclass selfClass, jstring destJpegPath, jstring sourceJpegPath, jint dstWidth, jint dstHeight, jstring lutPath, jint filterID, jstring glFilterResourcePath, jfloatArray gyroMatrix, jint gyroMatrixRank);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setTextureMatrix___3F(JNIEnv* env, jobject self, jfloatArray textureMatrix);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setTextureMatrix___3FI(JNIEnv* env, jobject self, jfloatArray textureMatrix, jint videoCaptureResolution);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setIllusionTextureMatrix___3F(JNIEnv* env, jobject self, jfloatArray illusionTextureMatrix);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setIllusionTextureMatrix___3FI(JNIEnv* env, jobject self, jfloatArray illusionTextureMatrix, jint videoCaptureResolution);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setEnableDebug(JNIEnv* env, jobject self, jboolean enableDebug);

/*
 * Class:     com_android_madv_glrenderer_MadvGLRenderer
 * Method:    getDisplayMode
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_getDisplayMode
        (JNIEnv *, jobject);

/*
 * Class:     com_android_madv_glrenderer_MadvGLRenderer
 * Method:    setDisplayMode
 * Signature: (I)V
 */
JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setDisplayMode
        (JNIEnv *, jobject, jint);

/*
 * Class:     com_android_madv_glrenderer_MadvGLRenderer
 * Method:    getIsYUVColorSpace
 * Signature: ()Z
 */
JNIEXPORT jboolean JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_getIsYUVColorSpace
        (JNIEnv *, jobject);

/*
 * Class:     com_android_madv_glrenderer_MadvGLRenderer
 * Method:    setIsYUVColorSpace
 * Signature: (Z)V
 */
JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setIsYUVColorSpace
        (JNIEnv *, jobject, jboolean);


JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setFlipY
        (JNIEnv* env, jobject self, jboolean flipY);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_setGLShaderFlags(JNIEnv* env, jobject self, jint flags);

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_getGLShaderFlags(JNIEnv* env, jclass selfClass);

JNIEXPORT jboolean JNICALL Java_com_madv360_madv_utils_FileUtil_saveFileChunk
        (JNIEnv* env, jclass selfClass, jstring filePath, jlong fileOffset, jbyteArray data, jlong dataOffset, jlong length);

JNIEXPORT jfloatArray JNICALL Java_com_madv360_madv_utils_FileUtil_getGyroMatrixFromString(JNIEnv* env, jclass selfClass, jstring gyroMatrixString);

JNIEXPORT jboolean JNICALL Java_com_madv360_madv_utils_FileUtil_extractLUTFiles
        (JNIEnv* env, jclass selfClass, jstring destDirectory, jstring lutBinFilePath, jint fileOffset);

JNIEXPORT jbyteArray JNICALL Java_com_madv360_glrenderer_MadvGLRenderer_renderThumbnail
        (JNIEnv* env, jclass selfClass, jint sourceTexture, jobject jobjSrcSize, jobject jobjDestSize, jstring lutPath, jint longitudeSegments, jint latitudeSegments);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLFilterCache_init(JNIEnv* env, jobject self, jstring resourceDirectory);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLFilterCache_dealloc(JNIEnv* env, jobject self);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLFilterCache_render__IFFFFII(JNIEnv* env, jobject self,
                                                                        jint filterID, jfloat x, jfloat y, jfloat width, jfloat height, jint sourceTexture, jint sourceTextureTarget);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLFilterCache_render__IFFFFIIILcom_madv360_glrenderer_Vec2f_2Lcom_madv360_glrenderer_Vec2f_2(JNIEnv* env, jobject self,
                                                                        jint filterID, jfloat x, jfloat y, jfloat width, jfloat height, jint sourceTexture, jint sourceTextureTarget, jint sourceOrientation, jobject jTexcoordOrigin, jobject jTexcoordSize);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLFilterCache_releaseGLObjects(JNIEnv* env, jobject self);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLRenderTexture_init(JNIEnv* env, jobject self, jint width, jint height, jboolean enableDepthTest);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLRenderTexture_dealloc(JNIEnv* env, jobject self);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLRenderTexture_releaseGLObjects(JNIEnv* env, jobject self);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLRenderTexture_blit(JNIEnv* env, jobject self);

JNIEXPORT void JNICALL Java_com_madv360_glrenderer_GLRenderTexture_unblit(JNIEnv* env, jobject self);

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_copyPixelData(JNIEnv* env, jobject self, jbyteArray jData);

JNIEXPORT jbyteArray JNICALL Java_com_madv360_glrenderer_GLRenderTexture_copyPixelDataFromPBO(JNIEnv* env, jobject self);

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_getFramebuffer(JNIEnv* env, jobject self);

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_getTexture(JNIEnv* env, jobject self);

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_getTextureTarget(JNIEnv* env, jobject self);

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_getWidth(JNIEnv* env, jobject self);

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_getHeight(JNIEnv* env, jobject self);

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_bytesLength(JNIEnv* env, jobject self);

JNIEXPORT jint JNICALL Java_com_madv360_glrenderer_GLRenderTexture_resizeIfNecessary(JNIEnv* env, jobject self, jint width, jint height);

#ifdef __cplusplus
}
#endif
#endif
