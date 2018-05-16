//
//  MadvGLRenderer.mm
//  Madv360_v1
//
//  Created by QiuDong on 16/2/26.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#include "MadvGLRenderer.h"
#include "MadvGLRendererImpl.h"
#include "PanoCameraController.h"
#include "MadvUtils.h"
#include "EXIFParser.h"
#include "JPEGUtils.h"
#include "GLRenderTexture.h"
#include "GLFilters/GLFilterCache.h"
#include "gles2.h"
#include "gles2ext.h"
#include "gles3.h"
#include "gles3ext.h"
#include <string.h>

//#define DEBUG_CUBEMAP_PERFORMANCE

#define FPS30_3456x1728  0
#define FPS30_2304x1152  1
#define FPS60_2304x1152  2
#define FPS30_3840x1920  6
#define FPS120_TOP_1920x480  7
#define FPS120_MIDDLE_1920x480  8
#define FPS120_BOTTOM_1920x480  9

kmMat4 MadvGLRenderer::transformTextureMatrixByVideoCaptureResolution(const kmMat4* textureMatrix, int videoCaptureResolution) {
    kmMat4 ret;
    if (NULL == textureMatrix)
    {
        kmMat4Identity(&ret);
        return ret;
    }
    kmMat4Assign(&ret, textureMatrix);
    
    switch (videoCaptureResolution)
    {
        case FPS120_TOP_1920x480:
        {
            kmScalar textureMatrixData0[] = {
                1.f, 0.f, 0.f, 0.f,
                0.f, 2.f, 0.f, 0.f,
                0.f, 0.f, 1.f, 0.f,
                0.f, -1.f, 0.f, 1.f,
            };
            kmMat4 textureMatrix0;
            kmMat4Fill(&textureMatrix0, textureMatrixData0);
            kmMat4Multiply(&ret, textureMatrix, &textureMatrix0);
        }
            break;
        case FPS120_MIDDLE_1920x480:
        {
            kmScalar textureMatrixData0[] = {
                1.f, 0.f, 0.f, 0.f,
                0.f, 2.f, 0.f, 0.f,
                0.f, 0.f, 1.f, 0.f,
                0.f, -0.5f, 0.f, 1.f,
            };
            kmMat4 textureMatrix0;
            kmMat4Fill(&textureMatrix0, textureMatrixData0);
            kmMat4Multiply(&ret, textureMatrix, &textureMatrix0);
        }
            break;
        case FPS120_BOTTOM_1920x480:
        {
            kmScalar textureMatrixData0[] = {
                1.f, 0.f, 0.f, 0.f,
                0.f, 2.f, 0.f, 0.f,
                0.f, 0.f, 1.f, 0.f,
                0.f, 0.f, 0.f, 1.f,
            };
            kmMat4 textureMatrix0;
            kmMat4Fill(&textureMatrix0, textureMatrixData0);
            kmMat4Multiply(&ret, textureMatrix, &textureMatrix0);
        }
            break;
        default:
            break;
    }
    return ret;
}

#undef FPS30_3456x1728
#undef FPS30_2304x1152
#undef FPS60_2304x1152
#undef FPS30_3840x1920
#undef FPS120_TOP_1920x480
#undef FPS120_MIDDLE_1920x480
#undef FPS120_BOTTOM_1920x480

MadvGLRenderer::~MadvGLRenderer() {
    delete (MadvGLRendererImpl*)_impl;
    _glCamera = NULL;
    glDeleteTextures(1, &_cubemapTexture);
}

MadvGLRenderer::MadvGLRenderer(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments) {
    _glCamera = new GLCamera;
    _impl = new MadvGLRendererImpl(lutPath, leftSrcSize, rightSrcSize, longitudeSegments, latitudeSegments);
}

MadvGLRenderer::MadvGLRenderer(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize) {
	_glCamera = new GLCamera;
    _impl = new MadvGLRendererImpl(lutPath, leftSrcSize, rightSrcSize);
}

//void MadvGLRenderer::setBestMeshSize(GLuint longitudeSegments, GLuint latitudeSegments) {
//    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
//    if (!impl) return;
//
//    impl->setBestMeshSize(longitudeSegments, latitudeSegments);
//}

void MadvGLRenderer::prepareLUT(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->prepareLUT(lutPath, leftSrcSize, rightSrcSize);
}

void MadvGLRenderer::draw(int displayMode, int x, int y, int width, int height, /*bool separateSourceTextures, */int srcTextureType, int leftSrcTexture, int rightSrcTexture) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->draw(displayMode, _glCamera, x, y, width, height, /*separateSourceTextures, */srcTextureType, leftSrcTexture, rightSrcTexture);
}

void MadvGLRenderer::draw(int displayMode, int x, int y, int width, int height, /*bool separateSourceTextures, */int srcTextureType, int* leftSrcYUVTextures, int* rightSrcYUVTextures) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->draw(displayMode, _glCamera, x, y, width, height, /*separateSourceTextures, */srcTextureType, leftSrcYUVTextures, rightSrcYUVTextures);
}

void MadvGLRenderer::draw(GLint x, GLint y, GLint width, GLint height) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->draw(_glCamera, x, y, width, height);
}

void MadvGLRenderer::drawCubeMapFace(GLenum targetFace, GLint x, GLint y, GLint width, GLint height) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->drawCubeMapFace(targetFace, x, y, width, height);
}

void MadvGLRenderer::drawFromCubemap(int x, int y, int width, int height, GLint sourceCubemapTexture) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->drawFromCubemap(_glCamera, x, y, width, height, sourceCubemapTexture);
}
/*
AutoRef<GLRenderTexture> MadvGLRenderer::drawToCubemapFaces(AutoRef<GLRenderTexture> cubemapFacesTexture, GLint faceWidth, GLint faceHeight) {
    if (NULL != cubemapFacesTexture)
    {
        cubemapFacesTexture->resizeIfNecessary(faceWidth * 6, faceHeight);
    }
    else
    {
        cubemapFacesTexture = new GLRenderTexture(faceWidth * 6, faceHeight);
    }
    cubemapFacesTexture->blit();
    
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    glViewport(0, 0, faceWidth * 6, faceHeight);
    CHECK_GL_ERROR();
    drawCubeMapFace(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, 0, faceWidth, faceHeight);
    drawCubeMapFace(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, faceWidth, 0, faceWidth, faceHeight);
    drawCubeMapFace(GL_TEXTURE_CUBE_MAP_POSITIVE_X, faceWidth * 2, 0, faceWidth, faceHeight);
    drawCubeMapFace(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, faceWidth * 3, 0, faceWidth, faceHeight);
    drawCubeMapFace(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, faceWidth * 4, 0, faceWidth, faceHeight);
    drawCubeMapFace(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, faceWidth * 5, 0, faceWidth, faceHeight);
    CHECK_GL_ERROR();
    glFlush();
    
    glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
    if (NULL != cubemapFacesTexture)
    {
        cubemapFacesTexture->unblit();
    }
    return cubemapFacesTexture;
}
//*/

GLint MadvGLRenderer::drawToRemappedCubemap(GLuint cubemapTexture, int cubemapFaceSize) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return 0;
    
    return impl->drawToRemappedCubemap(cubemapTexture, cubemapFaceSize);
}

void MadvGLRenderer::drawRemappedPanorama(int x, int y, int width, int height, int cubemapFaceSize) {
#ifdef DEBUG_CUBEMAP_PERFORMANCE
    int prevDisplayMode = getDisplayMode();
    setDisplayMode(PanoramaDisplayModePlain | (0 != (prevDisplayMode & PanoramaDisplayModeLUTInMesh) ? PanoramaDisplayModeLUTInMesh : 0));
    draw(x, y, width, height);
    setDisplayMode(prevDisplayMode);
#else
    if (_cubemapTexture > 0 && cubemapFaceSize != _cubemapFaceSize)
    {
        MadvGLRendererImpl::resizeCubemap(_cubemapTexture, cubemapFaceSize);
    }
    _cubemapFaceSize = cubemapFaceSize;//#ST_BUG#4634

    if (((_debugCubemapRenderNumber++) % MaxCubemapRenderNumber) == 0) {///!!!For Debug
        _cubemapTexture = drawToRemappedCubemap(_cubemapTexture, cubemapFaceSize);
    }
    drawFromCubemap(x, y, width, height, _cubemapTexture);
#endif
}

void MadvGLRenderer::drawRemappedPanorama(int lutStitchMode, int x, int y, int width, int height, int cubemapFaceSize,int srcTextureType, int srcTexture) {
    setSourceTextures(srcTexture, srcTexture, srcTextureType, false);
    setDisplayMode(lutStitchMode & (~PanoramaDisplayModeExclusiveMask));
#ifdef DEBUG_CUBEMAP_PERFORMANCE
    draw(x, y, width, height);
#else
    if (_cubemapTexture > 0 && cubemapFaceSize != _cubemapFaceSize)
    {
        MadvGLRendererImpl::resizeCubemap(_cubemapTexture, cubemapFaceSize);
    }
    _cubemapFaceSize = cubemapFaceSize;//#ST_BUG#4634

    if (((_debugCubemapRenderNumber++) % MaxCubemapRenderNumber) == 0) {///!!!For Debug
        _cubemapTexture = drawToRemappedCubemap(_cubemapTexture, cubemapFaceSize);
    }
    drawFromCubemap(x, y, width, height, _cubemapTexture);
#endif
}

AutoRef<GLRenderTexture> MadvGLRenderer::drawCubemapToBuffers(GLubyte* outPixelDatas, GLuint* PBOs, AutoRef<GLRenderTexture> cubemapFaceTexture, int cubemapFaceSize) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return NULL;
    
    return impl->drawCubemapToBuffers(outPixelDatas, PBOs, cubemapFaceTexture, cubemapFaceSize);
}

int MadvGLRenderer::getDisplayMode() {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return 0;
    
    return impl->getDisplayMode();
}

void MadvGLRenderer::setDisplayMode(int displayMode) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setDisplayMode(displayMode);
}

bool MadvGLRenderer::getIsYUVColorSpace() {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return false;
    
    return impl->getIsYUVColorSpace();
}

void MadvGLRenderer::setIsYUVColorSpace(bool isYUVColorSpace) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setIsYUVColorSpace(isYUVColorSpace);
}

void MadvGLRenderer::setSourceTextures(/*bool separateSourceTexture, */GLint srcTextureL, GLint srcTextureR, GLenum srcTextureTarget, bool isYUVColorSpace) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setSourceTextures(/*separateSourceTexture, */srcTextureL, srcTextureR, srcTextureTarget, isYUVColorSpace);
}

void MadvGLRenderer::setSourceTextures(/*bool separateSourceTexture, */GLint* srcTextureL, GLint* srcTextureR, GLenum srcTextureTarget, bool isYUVColorSpace) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setSourceTextures(/*separateSourceTexture, */srcTextureL, srcTextureR, srcTextureTarget, isYUVColorSpace);
}

void MadvGLRenderer::setTextureMatrix(const kmMat4* textureMatrix) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setTextureMatrix(textureMatrix);
}

void MadvGLRenderer::setTextureMatrix(const kmMat4* textureMatrix, int videoCaptureResolution) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    kmMat4 finalMat = transformTextureMatrixByVideoCaptureResolution(textureMatrix, videoCaptureResolution);
    impl->setTextureMatrix(&finalMat);
}

void MadvGLRenderer::setIllusionTextureMatrix(const kmMat4* textureMatrix) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setIllusionTextureMatrix(textureMatrix);
}

void MadvGLRenderer::setIllusionTextureMatrix(const kmMat4* textureMatrix, int videoCaptureResolution) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    kmMat4 finalMat = transformTextureMatrixByVideoCaptureResolution(textureMatrix, videoCaptureResolution);
    impl->setIllusionTextureMatrix(&finalMat);
}

GLint MadvGLRenderer::getLeftSourceTexture() {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return 0;
    
    return impl->getLeftSourceTexture();
}

GLint MadvGLRenderer::getRightSourceTexture() {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return 0;
    
    return impl->getRightSourceTexture();
}

GLenum MadvGLRenderer::getSourceTextureTarget() {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return 0;
    
    return impl->getSourceTextureTarget();
}

void MadvGLRenderer::setFlipY(bool flipY) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setFlipY(flipY);
}

void MadvGLRenderer::setFlipX(bool flipX) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setFlipX(flipX);
}

void MadvGLRenderer::setNeedDrawCaps(bool drawCaps) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setNeedDrawCaps(drawCaps);
}

void MadvGLRenderer::setCapsTexture(GLint texture, GLenum textureTarget) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setCapsTexture(texture, textureTarget);
}

void MadvGLRenderer::setRenderSource(void* renderSource) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setRenderSource(renderSource);
}

Vec2f MadvGLRenderer::getRenderSourceSize() {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return Vec2f{0.f, 0.f};
    
    return impl->getRenderSourceSize();
}

void MadvGLRenderer::setEnableDebug(bool enableDebug) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setEnableDebug(enableDebug);
}

void MadvGLRenderer::setDebugTexcoord(bool debugTexcoord) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->setDebugTexcoord(debugTexcoord);
}

void MadvGLRenderer::setGLShaderFlags(int flags) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;

    impl->setGLShaderFlags(flags);
}

//void MadvGLRenderer::clearCachedLUT(const char* lutPath) {
//    MadvGLRendererImpl::clearCachedLUT(lutPath);
//}

//void MadvGLRenderer::extractLUTFiles(const char* destDirectory, const char* lutBinFilePath, uint32_t fileOffset) {
//    extractLUTFiles(destDirectory, lutBinFilePath, fileOffset);
//}

AutoRef<GLCamera> MadvGLRenderer::glCamera() {
    return _glCamera;
}

void MadvGLRenderer::prepareTextureWithRenderSource(void* renderSource) {
    MadvGLRendererImpl* impl = (MadvGLRendererImpl*)_impl;
    if (!impl) return;
    
    impl->prepareTextureWithRenderSource(renderSource);
}

void MadvGLRenderer::testMADVPanoCrash(int width, int height) {
    GLRenderTexture renderTexture(width, height);
    CHECK_GL_ERROR();
    renderTexture.blit();
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ZERO);
    glClearColor(0, 0, 0, 0);
    glViewport(0, 0, width, height);
    CHECK_GL_ERROR();
}

void MadvGLRenderer::renderTextureToJPEG(const char* destJpegPath, int dstWidth, int dstHeight, GLint sourceTexture, const char* lutPath, int filterID, const char* glFilterResourcePath, float* gyroMatrix, int gyroMatrixRank, GLuint longitudeSegments, GLuint latitudeSegments) {
    int blockLines = dstHeight / 8;
    const int pixelStripBytes = 4 * dstWidth * blockLines;
    
    GLuint PBOs[2];
    glGenBuffers(2, PBOs);
    for (int i=0; i<2; ++i)
    {
        glBindBuffer(GL_PIXEL_PACK_BUFFER, PBOs[i]);
        glBufferData(GL_PIXEL_PACK_BUFFER, pixelStripBytes, NULL, GL_DYNAMIC_READ);
    }
    
    GLRenderTexture renderTexture(dstWidth, blockLines);
    CHECK_GL_ERROR();
#ifdef USE_MSAA
    glBindFramebuffer(GL_FRAMEBUFFER, _msaaFramebuffer);
#else
    renderTexture.blit();
#endif
    CHECK_GL_ERROR();
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ZERO);
    glClearColor(0, 0, 0, 0);
    glViewport(0, 0, dstWidth, dstHeight);
    CHECK_GL_ERROR();
    
    AutoRef<GLRenderTexture> filterRenderTexture = NULL;
    AutoRef<GLFilterCache> filterCache = NULL;
    if (filterID > 0)
    {
        filterCache = new GLFilterCache(glFilterResourcePath);
        filterRenderTexture = new GLRenderTexture(0, GL_TEXTURE_2D, dstWidth, blockLines, GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE, GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE);
        CHECK_GL_ERROR();
    }
    
    Vec2f lutSourceSize = { DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT };
    AutoRef<MadvGLRenderer> renderer = new MadvGLRenderer(lutPath, lutSourceSize, lutSourceSize, longitudeSegments, latitudeSegments);
    AutoRef<PanoCameraController> panoController = new PanoCameraController(renderer);
    renderer->setIsYUVColorSpace(false);
    bool withLUTStitching = (lutPath && 0 < strlen(lutPath));
    renderer->setDisplayMode(withLUTStitching ? PanoramaDisplayModeLUTInMesh : 0);
    renderer->setSourceTextures(sourceTexture, sourceTexture, GL_TEXTURE_2D, false);
    CHECK_GL_ERROR();
    ///!!!Important {
    kmScalar textureMatrixData[] = {
        1.f, 0.f, 0.f, 0.f,
        0.f, -1.f, 0.f, 0.f,
        0.f, 0.f, 1.f, 0.f,
        0.f, 1.f, 0.f, 1.f,
    };
    kmMat4 textureMatrix;
    kmMat4Fill(&textureMatrix, textureMatrixData);
    renderer->setTextureMatrix(&textureMatrix);
    renderer->setFlipY(true);
    ///!!!} Important
    if (gyroMatrixRank > 0)
    {
        panoController->setGyroMatrix(gyroMatrix, gyroMatrixRank);
    }
    CHECK_GL_ERROR();
	GLint maxCubemapSize = 1024;
	glGetIntegerv(GL_MAX_CUBE_MAP_TEXTURE_SIZE, &maxCubemapSize);
	ALOGE("\nGL_MAX_CUBE_MAP_TEXTURE_SIZE = %d\n", maxCubemapSize);
#if !defined(TARGET_OS_WINDOWS) || TARGET_OS_WINDOWS == 0
    GLuint cubemapTexture = renderer->drawToRemappedCubemap(0, roundf(dstHeight * 0.5773));
#else
	GLuint cubemapTexture = renderer->drawToRemappedCubemap(0, 1024);
#endif
    JPEGCompressOutput* imageOutput = startWritingImageToJPEG(destJpegPath, GL_RGBA, GL_UNSIGNED_BYTE, 100, dstWidth, dstHeight);
    GLubyte* pixelData = (GLubyte*)malloc(pixelStripBytes);
    
    bool finishedAppending = false;
    const int blockLines0 = blockLines;
    int pboIndex = -1;
    for (int iLine = 0; iLine < dstHeight; iLine += blockLines)
    {
        if (dstHeight - iLine < blockLines)
        {
            blockLines = dstHeight - iLine;
        }
        
        if (filterID > 0)
        {
            filterRenderTexture->blit();
        }
        glClear(GL_COLOR_BUFFER_BIT);
        CHECK_GL_ERROR();
        //renderer->draw(0, -iLine, dstWidth, dstHeight);
        renderer->drawFromCubemap(0, -iLine, dstWidth, dstHeight, cubemapTexture);
        
        if (filterID > 0)
        {
            filterRenderTexture->unblit();
            filterCache->render(filterID, 0, 0, dstWidth, blockLines0, filterRenderTexture->getTexture(), GL_TEXTURE_2D);
            CHECK_GL_ERROR();
        }
        
        GLint prevBindingPBO;
        glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING, &prevBindingPBO);
        if (-1 == pboIndex)
        {
            pboIndex = 0;
        }
        else
        {
            glBindBuffer(GL_PIXEL_PACK_BUFFER, PBOs[pboIndex]);
            GLubyte* mappedPixels = (GLubyte*)glMapBufferRange(GL_PIXEL_PACK_BUFFER, 0, pixelStripBytes, GL_MAP_READ_BIT);
//            if (!appendImageStrideToJPEG(imageOutput, mappedPixels, blockLines))
//            {
//                finishedAppending = true;
//                glUnmapBuffer(GL_PIXEL_PACK_BUFFER);
//                break;
//            }
            memcpy(pixelData, mappedPixels, pixelStripBytes);
            glUnmapBuffer(GL_PIXEL_PACK_BUFFER);
            appendImageStrideToJPEG(imageOutput, pixelData, blockLines0);
            pboIndex = 1 - pboIndex;
        }
        glBindBuffer(GL_PIXEL_PACK_BUFFER, PBOs[pboIndex]);
        glReadPixels(0, 0, dstWidth, blockLines0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
        glBindBuffer(GL_PIXEL_PACK_BUFFER, prevBindingPBO);
        CHECK_GL_ERROR();
    }
    GLint prevBindingPBO;
    glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING, &prevBindingPBO);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, PBOs[pboIndex]);
    GLubyte* mappedPixels = (GLubyte*)glMapBufferRange(GL_PIXEL_PACK_BUFFER, 0, pixelStripBytes, GL_MAP_READ_BIT);
    memcpy(pixelData, mappedPixels, pixelStripBytes);
    glUnmapBuffer(GL_PIXEL_PACK_BUFFER);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, prevBindingPBO);
    
    if (appendImageStrideToJPEG(imageOutput, pixelData, blockLines))
    {
        delete imageOutput;
    }
    free(pixelData);
    
    renderTexture.unblit();
    glDeleteTextures(1, &cubemapTexture);
    if (filterID > 0)
    {
        filterRenderTexture = NULL;
        filterCache = NULL;
    }
    renderer = NULL;
    
    glDeleteBuffers(2, PBOs);
}

void MadvGLRenderer::debugRenderTextureToJPEG(const char* destJpegPath, int dstWidth, int dstHeight, GLint sourceTexture, const char* lutPath, int filterID, const char* glFilterResourcePath, float* gyroMatrix, int gyroMatrixRank, GLuint longitudeSegments, GLuint latitudeSegments) {
    int blockLines = dstHeight / 8;
    
    GLint prevFramebuffer = 0, prevTexture = 0, prevRenderbuffer = 0;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFramebuffer);
    glGetIntegerv(GL_RENDERBUFFER_BINDING, &prevRenderbuffer);
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &prevTexture);
    GLint prevViewport[4] = {0,0,0,0};
    glGetIntegerv(GL_VIEWPORT, prevViewport);
    
    GLRenderTexture renderTexture(dstWidth, blockLines);
#ifdef USE_MSAA
    glBindFramebuffer(GL_FRAMEBUFFER, _msaaFramebuffer);
#else
    glBindFramebuffer(GL_FRAMEBUFFER, renderTexture.getFramebuffer());
#endif
    CHECK_GL_ERROR();
    
    AutoRef<GLRenderTexture> filterRenderTexture = NULL;
    AutoRef<GLFilterCache> filterCache = NULL;
    if (filterID > 0)
    {
        filterCache = new GLFilterCache(glFilterResourcePath);
        //    m_filterCache->obtainFilter(GLFilterAmatorkaID);
        //    m_filterCache->obtainFilter(GLFilterMissEtikateID);
        
        filterRenderTexture = new GLRenderTexture(0, GL_TEXTURE_2D, dstWidth, blockLines, GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE, GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE);
        CHECK_GL_ERROR();
    }
    
    Vec2f lutSourceSize = { DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT };
    AutoRef<MadvGLRenderer> renderer = new MadvGLRenderer(lutPath, lutSourceSize, lutSourceSize, longitudeSegments, latitudeSegments);
    AutoRef<PanoCameraController> panoController = new PanoCameraController(renderer);
    renderer->setIsYUVColorSpace(false);
    bool withLUTStitching = (lutPath && 0 < strlen(lutPath));
    renderer->setDisplayMode(withLUTStitching ? PanoramaDisplayModeLUTInMesh : 0);
    renderer->setSourceTextures(/*false, */sourceTexture, sourceTexture, GL_TEXTURE_2D, false);
    ///!!!Important {
    kmScalar textureMatrixData[] = {
        1.f, 0.f, 0.f, 0.f,
        0.f, -1.f, 0.f, 0.f,
        0.f, 0.f, 1.f, 0.f,
        0.f, 1.f, 0.f, 1.f,
    };
    kmMat4 textureMatrix;
    kmMat4Fill(&textureMatrix, textureMatrixData);
    renderer->setTextureMatrix(&textureMatrix);
    renderer->setFlipY(true);
    ///!!!} Important
    //*/!!!For Debug:
    if (gyroMatrixRank > 0)
    {
        panoController->setGyroMatrix(gyroMatrix, gyroMatrixRank);
    }
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ZERO);
    glClearColor(0, 0, 0, 0);
    glViewport(0, 0, dstWidth, dstHeight);
    CHECK_GL_ERROR();
    
    //*/
    JPEGCompressOutput* imageOutput = startWritingImageToJPEG(destJpegPath, GL_RGBA, GL_UNSIGNED_BYTE, 100, dstWidth, dstHeight);
    GLubyte* pixelData = (GLubyte*)malloc(4 * dstWidth * blockLines);
    
    bool finishedAppending = false;
    int blockLines0 = blockLines;
    for (int iLine = 0; iLine < dstHeight; iLine += blockLines)
    {
        if (dstHeight - iLine < blockLines)
        {
            blockLines = dstHeight - iLine;
        }
        
        if (filterID > 0)
        {
            filterRenderTexture->blit();
        }
        glClear(GL_COLOR_BUFFER_BIT);
        CHECK_GL_ERROR();
        renderer->draw(0, -iLine, dstWidth, dstHeight);
        
        if (filterID > 0)
        {
            filterRenderTexture->unblit();
            filterCache->render(filterID, 0, 0, dstWidth, blockLines0, filterRenderTexture->getTexture(), GL_TEXTURE_2D);
            CHECK_GL_ERROR();
        }
        
        glReadPixels(0, 0, dstWidth, blockLines, GL_RGBA, GL_UNSIGNED_BYTE, pixelData);
        glFinish();
        CHECK_GL_ERROR();
        if (!appendImageStrideToJPEG(imageOutput, pixelData, blockLines))
        {
            finishedAppending = true;
            break;
        }
    }
    
    if (!finishedAppending)
    {
        delete imageOutput;
    }
    free(pixelData);
    //*/
    if (filterID > 0)
    {
        filterRenderTexture = NULL;
        filterCache = NULL;
    }
    renderer = NULL;
    
    glBindFramebuffer(GL_FRAMEBUFFER, prevFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, prevRenderbuffer);
    glBindTexture(GL_TEXTURE_2D, prevTexture);
    glViewport(prevViewport[0], prevViewport[1], prevViewport[2], prevViewport[3]);
}

void MadvGLRenderer::renderMadvJPEGToJPEG(const char* destJpegPath, const char* sourceJpegPath, int dstWidth, int dstHeight, const char* lutPath, int filterID, const char* glFilterResourcePath, float* gyroMatrix, int gyroMatrixRank, GLuint longitudeSegments, GLuint latitudeSegments, MVProgressClosure progressClosure) {
    long sourceExivImageHandler = createExivImage(sourceJpegPath);
    GLint sourceTexture = createTextureWithJPEG(sourceJpegPath);
    CHECK_GL_ERROR();
    bool withLUTStitching = (lutPath && 0 < strlen(lutPath));
    renderTextureToJPEG(destJpegPath, dstWidth, dstHeight, sourceTexture, lutPath, filterID, glFilterResourcePath, gyroMatrix, gyroMatrixRank, longitudeSegments, latitudeSegments);
    glDeleteTextures(1, (GLuint*)&sourceTexture);
    CHECK_GL_ERROR();
	copyEXIFDataFromExivImage(destJpegPath, sourceExivImageHandler);
	releaseExivImage(sourceExivImageHandler);
    
    if (withLUTStitching || gyroMatrixRank > 0)
	{
		MadvEXIFExtension madvExtension = readMadvEXIFExtensionFromJPEG(destJpegPath);
		long exivImageHandler = createExivImage(destJpegPath);

		if (withLUTStitching)
		{
			if (StitchTypeStitched != madvExtension.sceneType)
			{
				exivImageEraseSceneType(exivImageHandler);
			}
			if (madvExtension.withEmbeddedLUT)
			{
				exivImageEraseFileSource(exivImageHandler);
			}
		}
		if (gyroMatrixRank > 0)
		{
			exivImageEraseGyroData(exivImageHandler);
		}

		exivImageSaveMetaData(exivImageHandler);
		releaseExivImage(exivImageHandler);
	}//*/
}

#define RAW_BITS 14
#define RAW_SHIFTLEFT_BITS (RAW_BITS - 8)
#define RAW_SHIFTRIGHT_BITS (16 - RAW_BITS)
///!!!#define REWRITE_RAW_TIFF_FIELDS

bool MadvGLRenderer::renderMadvRawToRaw(const char* destRawPath, const char* sourceRawPath, int dstWidth, int dstHeight, const char* lutPath, int filterID, const char* glFilterResourcePath, float* gyroMatrix, int gyroMatrixRank, GLuint longitudeSegments, GLuint latitudeSegments, MVProgressClosure progressClosure) {
	GLenum srcInternalFormat = GL_R16F;//GL_RGBA;
	GLenum srcFormat = GL_RED;
	GLenum srcType = GL_FLOAT;//GL_UNSIGNED_BYTE;

	FILE* fp = fopen(sourceRawPath, "rb+");
	fseek(fp, 8, SEEK_SET);
	GLint sourceTexture = createTextureWithDNG(fp, dstWidth, dstHeight, srcInternalFormat, srcFormat, srcType, RAW_BITS);
	fclose(fp);

	// Drawing:
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ZERO);
	glViewport(0, 0, dstWidth, dstHeight);
	CHECK_GL_ERROR();
	// VBO:
	GLfloat vertexBufferData[] = {
		-1.f, -1.f, 0.f, 1.f, 0.f, 0.f,
		-1.f, 1.f, 0.f, 1.f, 0.f, 1.f,
		1.f, 1.f, 0.f, 1.f, 1.f, 1.f,
		1.f, -1.f, 0.f, 1.f, 1.f, 0.f,
	};
	GLuint vertexBuffer;
	glGenBuffers(1, &vertexBuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertexBufferData), vertexBufferData, GL_STATIC_DRAW);
	CHECK_GL_ERROR();
	GLushort indexBufferData[] = { 0, 1, 3, 2 };
	GLuint indexBuffer;
	glGenBuffers(1, &indexBuffer);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexBufferData), indexBufferData, GL_STATIC_DRAW);
	CHECK_GL_ERROR();
	// Shaders:
	static const char* vertexShader =
		STRINGIZE2
		(attribute highp vec4 a_position; \n
		attribute highp vec2 a_texcoord; \n
		varying highp vec2 v_texcoord; \n
		void main(void) {
		\n
			gl_Position = a_position; \n
			v_texcoord = a_texcoord; \n
	} \n
	);
	static const char* highByteFragmentShader =
		STRINGIZE2
		(STRINGIZE0(#ifdef) GL_ES \n
		precision highp float; \n
		STRINGIZE0(#endif) \n
		varying vec2 v_texcoord; \n
		uniform sampler2D u_texture; \n
		void main(void) {
		\n
			highp vec4 color = texture2D(u_texture, v_texcoord) * 256.0; \n
			gl_FragColor = vec4((floor(color) / 256.0).rgb, 1.0); \n
	} \n
	);
	static const char* lowByteFragmentShader =
		STRINGIZE2
		(STRINGIZE0(#ifdef) GL_ES \n
		precision highp float; \n
		STRINGIZE0(#endif) \n
		varying vec2 v_texcoord; \n
		uniform sampler2D u_texture; \n
		void main(void) {
		\n
			highp vec4 color = texture2D(u_texture, v_texcoord) * 256.0; \n
			gl_FragColor = vec4((color - floor(color)).rgb, 1.0); \n
	} \n
	);

	static const char* glslVersionString = GLSLPredefinedMacros();
	const char* vertexShaderSources[] = { glslVersionString, vertexShader };
	const char* perByteFragmentShaders[] = { highByteFragmentShader, lowByteFragmentShader };
	GLint shaderPrograms[2];
	GLint textureSlots[2], positionSlots[2], texcoordSlots[2];
	for (int iShader = 0; iShader<2; ++iShader)
	{
		const char* fragmentShaderSources[] = { glslVersionString, perByteFragmentShaders[iShader] };
		shaderPrograms[iShader] = compileAndLinkShaderProgram(vertexShaderSources, 2, fragmentShaderSources, 2);
		textureSlots[iShader] = glGetUniformLocation(shaderPrograms[iShader], "u_texture");
		positionSlots[iShader] = glGetAttribLocation(shaderPrograms[iShader], "a_position");
		texcoordSlots[iShader] = glGetAttribLocation(shaderPrograms[iShader], "a_texcoord");
		ALOGE("\n#%d shaderPrograms[iShader]=%d, textureSlots[iShader]=%d, positionSlots[iShader]=%d, texcoordSlots[iShader]=%d\n", iShader, shaderPrograms[iShader], textureSlots[iShader], positionSlots[iShader], texcoordSlots[iShader]);
		CHECK_GL_ERROR();
	}
	// RenderTextures:
	GLenum internalFormat = GL_RGBA;//GL_RGBA16F_EXT;
	GLenum format = GL_RGBA;//GL_RGBA;
	GLenum type = GL_UNSIGNED_BYTE;//GL_FLOAT;
	GLRenderTexture* byteRenderTexture = new GLRenderTexture(0, GL_TEXTURE_2D, dstWidth, dstHeight, internalFormat, format, type);
	GLRenderTexture* stitchedRenderTexture = new GLRenderTexture(0, GL_TEXTURE_2D, dstWidth, dstHeight, internalFormat, format, type);
	CHECK_GL_ERROR();
	// Panoramic renderer:
	Vec2f lutSourceSize = { DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT };
	AutoRef<MadvGLRenderer> renderer = new MadvGLRenderer(lutPath, lutSourceSize, lutSourceSize, longitudeSegments, latitudeSegments);
    AutoRef<PanoCameraController> panoController = new PanoCameraController(renderer);
	renderer->setIsYUVColorSpace(false);
	bool withLUTStitching = (lutPath && 0 < strlen(lutPath));
    renderer->setDisplayMode(withLUTStitching ? PanoramaDisplayModeLUTInMesh : 0);
	renderer->setSourceTextures(byteRenderTexture->getTexture(), byteRenderTexture->getTexture(), GL_TEXTURE_2D, false);
	kmScalar textureMatrixData[] = {
		1.f, 0.f, 0.f, 0.f,
		0.f, -1.f, 0.f, 0.f,
		0.f, 0.f, 1.f, 0.f,
		0.f, 1.f, 0.f, 1.f,
	};
	kmMat4 textureMatrix;
	kmMat4Fill(&textureMatrix, textureMatrixData);
	renderer->setTextureMatrix(&textureMatrix);
	renderer->setFlipY(true);
	if (!withLUTStitching && gyroMatrixRank > 0)
	{
		panoController->setGyroMatrix(gyroMatrix, gyroMatrixRank);
	}
	CHECK_GL_ERROR();
	GLenum dstInternalFormat = GL_RGBA;
	GLenum dstFormat = GL_RGBA;
	GLenum dstType = GL_UNSIGNED_BYTE;
	const int colorComponents = 4;
	const int colorComponentsCount = dstWidth * dstHeight * colorComponents;
	GLubyte* pixelData = (GLubyte*)malloc(sizeof(GLubyte) * colorComponentsCount);///highBytes & lowBytes
	GLushort* rawData = (GLushort*)malloc(sizeof(GLushort) * dstWidth * dstHeight);
	CHECK_GL_ERROR();
	if (NULL != progressClosure.callback)
	{
		progressClosure.callback(25, progressClosure.context);
	}
#if !defined(TARGET_OS_WINDOWS) || TARGET_OS_WINDOWS == 0
	int cubemapFaceSize = roundf(dstHeight * 0.57735);
#else
	int cubemapFaceSize = 1024;
#endif
    GLuint cubemapTexture = 0;
    AutoRef<GLRenderTexture> cubemapFaceTexture = NULL;
    
	for (int iShader = 0; iShader<2; ++iShader)
	{
#ifdef USE_MSAA
		glBindFramebuffer(GL_FRAMEBUFFER, _msaaFramebuffer);
#else
		byteRenderTexture->blit();
#endif
		glClearColor(0, 0, 1, 1);
		CHECK_GL_ERROR();
		glClear(GL_COLOR_BUFFER_BIT);
		CHECK_GL_ERROR();
		glUseProgram(shaderPrograms[iShader]);
		CHECK_GL_ERROR();
		glEnableVertexAttribArray(positionSlots[iShader]);
		glEnableVertexAttribArray(texcoordSlots[iShader]);
		glVertexAttribPointer(positionSlots[iShader], 4, GL_FLOAT, false, sizeof(GLfloat) * 6, NULL);
		glVertexAttribPointer(texcoordSlots[iShader], 2, GL_FLOAT, false, sizeof(GLfloat) * 6, (const void*)(sizeof(GLfloat) * 4));
		CHECK_GL_ERROR();
		// Active texture unit:
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, sourceTexture);
		ALOGE("\nsourceTexture = %d", sourceTexture);
		CHECK_GL_ERROR();
		glUniform1i(textureSlots[iShader], 0);
		CHECK_GL_ERROR();
		glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, NULL);
		CHECK_GL_ERROR();
		byteRenderTexture->unblit();

		stitchedRenderTexture->blit();
		glClear(GL_COLOR_BUFFER_BIT);
		///renderer->draw(NULL, 0, 0, dstWidth, dstHeight);
        cubemapTexture = renderer->drawToRemappedCubemap(cubemapTexture, cubemapFaceSize);
        renderer->drawFromCubemap(0, 0, dstWidth, dstHeight, cubemapTexture);
        
		glReadPixels(0, 0, dstWidth, dstHeight, dstFormat, dstType, pixelData);
		stitchedRenderTexture->unblit();
		//*///!!!
		if (0 == iShader)
		{
			const GLubyte* pSrcHighByte;
			GLushort* pDst;
			// R:
			pDst = rawData;
			pSrcHighByte = pixelData;
			for (int iRow = 0; iRow<dstHeight; iRow += 2)
			{
				int iCol = 0;
				for (; iCol<dstWidth; iCol += 2)
				{
					pDst[0] = (pSrcHighByte[0] << RAW_SHIFTLEFT_BITS);
					pDst += 2;
					pSrcHighByte += (2 * colorComponents);
				}
				int nextRowStep = 2 * dstWidth - iCol;
				pDst += nextRowStep;
				pSrcHighByte += nextRowStep * colorComponents;
			}
			// Even-row G:
			pDst = rawData + 1;
			pSrcHighByte = pixelData + colorComponents;
			for (int iRow = 0; iRow<dstHeight; iRow += 2)
			{
				int iCol = 1;
				for (; iCol<dstWidth; iCol += 2)
				{
					pDst[0] = (pSrcHighByte[1] << RAW_SHIFTLEFT_BITS);
					pDst += 2;
					pSrcHighByte += (2 * colorComponents);
				}
				int nextRowStep = 2 * dstWidth + 1 - iCol;
				pDst += nextRowStep;
				pSrcHighByte += nextRowStep * colorComponents;
			}
			// Odd-row G:
			pDst = rawData + dstWidth;
			pSrcHighByte = pixelData + colorComponents * dstWidth;
			for (int iRow = 1; iRow<dstHeight; iRow += 2)
			{
				int iCol = 0;
				for (; iCol<dstWidth; iCol += 2)
				{
					pDst[0] = (pSrcHighByte[1] << RAW_SHIFTLEFT_BITS);
					pDst += 2;
					pSrcHighByte += (2 * colorComponents);
				}
				int nextRowStep = 2 * dstWidth - iCol;
				pDst += nextRowStep;
				pSrcHighByte += nextRowStep * colorComponents;
			}
			// B:
			pDst = rawData + dstWidth + 1;
			pSrcHighByte = pixelData + colorComponents * (dstWidth + 1);
			for (int iRow = 1; iRow<dstHeight; iRow += 2)
			{
				int iCol = 1;
				for (; iCol<dstWidth; iCol += 2)
				{
					pDst[0] = (pSrcHighByte[2] << RAW_SHIFTLEFT_BITS);
					pDst += 2;
					pSrcHighByte += (2 * colorComponents);
				}
				int nextRowStep = 2 * dstWidth + 1 - iCol;
				pDst += nextRowStep;
				pSrcHighByte += nextRowStep * colorComponents;
			}

			if (NULL != progressClosure.callback)
			{
				progressClosure.callback(50, progressClosure.context);
			}
		}
		else
		{
			const GLubyte* pSrcLowByte;
			GLushort* pDst;
			// R:
			pDst = rawData;
			pSrcLowByte = pixelData;
			for (int iRow = 0; iRow<dstHeight; iRow += 2)
			{
				int iCol = 0;
				for (; iCol<dstWidth; iCol += 2)
				{
					pDst[0] += (pSrcLowByte[0] >> RAW_SHIFTRIGHT_BITS);
					pDst += 2;
					pSrcLowByte += (2 * colorComponents);
				}
				int nextRowStep = 2 * dstWidth - iCol;
				pDst += nextRowStep;
				pSrcLowByte += nextRowStep * colorComponents;
			}
			// Even-row G:
			pDst = rawData + 1;
			pSrcLowByte = pixelData + colorComponents;
			for (int iRow = 0; iRow<dstHeight; iRow += 2)
			{
				int iCol = 1;
				for (; iCol<dstWidth; iCol += 2)
				{
					pDst[0] += (pSrcLowByte[1] >> RAW_SHIFTRIGHT_BITS);
					pDst += 2;
					pSrcLowByte += (2 * colorComponents);
				}
				int nextRowStep = 2 * dstWidth + 1 - iCol;
				pDst += nextRowStep;
				pSrcLowByte += nextRowStep * colorComponents;
			}
			// Odd-row G:
			pDst = rawData + dstWidth;
			pSrcLowByte = pixelData + colorComponents * dstWidth;
			for (int iRow = 1; iRow<dstHeight; iRow += 2)
			{
				int iCol = 0;
				for (; iCol<dstWidth; iCol += 2)
				{
					pDst[0] += (pSrcLowByte[1] >> RAW_SHIFTRIGHT_BITS);
					pDst += 2;
					pSrcLowByte += (2 * colorComponents);
				}
				int nextRowStep = 2 * dstWidth - iCol;
				pDst += nextRowStep;
				pSrcLowByte += nextRowStep * colorComponents;
			}
			// B:
			pDst = rawData + dstWidth + 1;
			pSrcLowByte = pixelData + colorComponents * (dstWidth + 1);
			for (int iRow = 1; iRow<dstHeight; iRow += 2)
			{
				int iCol = 1;
				for (; iCol<dstWidth; iCol += 2)
				{
					pDst[0] += (pSrcLowByte[2] >> RAW_SHIFTRIGHT_BITS);
					pDst += 2;
					pSrcLowByte += (2 * colorComponents);
				}
				int nextRowStep = 2 * dstWidth + 1 - iCol;
				pDst += nextRowStep;
				pSrcLowByte += nextRowStep * colorComponents;
			}

			if (NULL != progressClosure.callback)
			{
				progressClosure.callback(75, progressClosure.context);
			}
		}
		//*/
	}
    CHECK_GL_ERROR();
	glDeleteBuffers(1, &vertexBuffer);
	glDeleteBuffers(1, &indexBuffer);
	for (int iShader = 0; iShader<2; ++iShader)
	{
		glDeleteProgram(shaderPrograms[iShader]);
	}
	delete byteRenderTexture;
	delete stitchedRenderTexture;
    cubemapFaceTexture = NULL;
    glDeleteTextures(1, &cubemapTexture);
    glDeleteTextures(1, (GLuint*)&sourceTexture);
    glFinish();
	CHECK_GL_ERROR();
    free(pixelData);
    
	//Write output DNG:
	TIFFHeader tiffHeader;
	std::list<std::list<DirectoryEntry> > IFDList;
	fp = fopen(sourceRawPath, "rb+");
	readTIFF(&tiffHeader, IFDList, fp);
	fclose(fp);
    
    fp = fopen(sourceRawPath, "rb+");
    fseek(fp, 0, SEEK_END);
    uint32_t fileLength = (uint32_t)ftell(fp);
    ///fseek(fp, 0, SEEK_SET);///!!!
    
	FILE* fpOut = fopen(destRawPath, "wb+");
    
    TIFFHeaderRaw rawTIFFHeader;
    convertTIFFHeaderToRaw(rawTIFFHeader, tiffHeader);
    fwrite(&rawTIFFHeader, SizeOfTIFFHeaderRaw, 1, fpOut);
    size_t dataSessionSize = sizeof(GLushort) * dstWidth * dstHeight;
    fwrite(rawData, dataSessionSize, 1, fpOut);
    fseek(fp, SizeOfTIFFHeaderRaw + dataSessionSize, SEEK_SET);///!!!
    free(rawData);
    
    std::list<DirectoryEntry> allDEs;
    for (std::list<std::list<DirectoryEntry> >::iterator iIFDList = IFDList.begin();
         iIFDList != IFDList.end();
         iIFDList++)
    {
        std::list<DirectoryEntry>& DEList = *iIFDList;
        for (std::list<DirectoryEntry>::iterator iDE = DEList.begin(); iDE != DEList.end(); iDE++)
        {
            DirectoryEntry& DE = *iDE;
            switch (DE.tag)
            {
//#ifdef REWRITE_RAW_TIFF_FIELDS
                case TAG_USER_COMMENT:
                {
                    DE.length = 0;
                    DE.value = 0;
                }
                    break;
                case TAG_FILE_SOURCE:
                {
                    DE.value = 0;
                }
                    break;
                case TAG_SCENE_TYPE:
                {
                    DE.value = 2;
                }
                    break;
                case TAG_DNG_WIDTH:
                {
                    dstWidth = DE.value;
                }
                    break;
                case TAG_DNG_HEIGHT:
                {
                    dstHeight = DE.value;
                }
                    break;
//#endif //#ifdef REWRITE_RAW_TIFF_FIELDS
                default:
                    break;
            }
            allDEs.push_back(DE);
        }
    }
    ///!!!allDEs.sort(compareDEOffset);
    
    const int BufferSize = 1048576 * 8;
    uint8_t* buffer = (uint8_t*)malloc(BufferSize);
	
    std::list<DirectoryEntry>::iterator iter = allDEs.begin();
    size_t thisBlockBytesLeft = (allDEs.size() > 0 ? iter->thisOffsetInFile : fileLength) - SizeOfTIFFHeaderRaw - dataSessionSize;
    do
    {
        for (; thisBlockBytesLeft >= BufferSize; thisBlockBytesLeft -= BufferSize)
        {
            fread(buffer, BufferSize, 1, fp);
            fwrite(buffer, BufferSize, 1, fpOut);
        }
        if (thisBlockBytesLeft > 0)
        {
            fread(buffer, thisBlockBytesLeft, 1, fp);
            fwrite(buffer, thisBlockBytesLeft, 1, fpOut);
        }
        
        if (iter != allDEs.end())
        {
            DirectoryEntry& DE = *iter;
            DirectoryEntryRaw rawDE, rawDE0;
            fread(&rawDE0, SizeOfDirectoryEntryRaw, 1, fp);
            convertDirectoryEntryToRaw(rawDE, DE, tiffHeader.isBigEndian);
            
            long valueSize = sizeOfDEValueType((DEValueType)DE.type) * DE.length;
            if (valueSize > 4)
            {
                memcpy(rawDE.valueOrOffset, rawDE0.valueOrOffset, sizeof(rawDE.valueOrOffset));
            }
            
            fwrite(&rawDE, SizeOfDirectoryEntryRaw, 1, fpOut);
            
            iter++;
            uint64_t currentLocation = ftell(fp);
            if (iter != allDEs.end())
            {
                uint64_t nextOffset = iter->thisOffsetInFile;
                thisBlockBytesLeft = nextOffset - currentLocation;
            }
            else
            {
                thisBlockBytesLeft = fileLength - currentLocation;
            }
        }
    } while (ftell(fp) < fileLength);
    
    free(buffer);
    fclose(fpOut);
	fclose(fp);
	
	if (NULL != progressClosure.callback)
	{
		progressClosure.callback(100, progressClosure.context);
	}
	return true;
}
