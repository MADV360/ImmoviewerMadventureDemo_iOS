//
// Created by QiuDong on 16/5/31.
//

#include "MadvGLRenderer_Android.h"
#include <EGL/egl.h>
#include <EGL/eglext.h>

MadvGLRenderer_Android::~MadvGLRenderer_Android() {
}

MadvGLRenderer_Android::MadvGLRenderer_Android(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments)
        : MadvGLRenderer(lutPath, leftSrcSize, rightSrcSize, longitudeSegments, latitudeSegments)
{
}

void MadvGLRenderer_Android::prepareTextureWithRenderSource(void* renderSource) {
    ALOGE("MadvGLRenderer_Android::prepareTextureWithRenderSource");
}

GLubyte* MadvGLRenderer_Android::renderThumbnail(GLint sourceTexture, Vec2f srcSize, Vec2f destSize, const char* lutPath, int longitudeSegments, int latitudeSegments) {
    // EGL config attributes
    const EGLint confAttr[] =
            {
                    EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT_KHR,// very important!
                    EGL_SURFACE_TYPE,EGL_PBUFFER_BIT,//EGL_WINDOW_BIT EGL_PBUFFER_BIT we will create a pixelbuffer surface
                    EGL_RED_SIZE,   8,
                    EGL_GREEN_SIZE, 8,
                    EGL_BLUE_SIZE,  8,
                    EGL_ALPHA_SIZE, 8,// if you need the alpha channel
                    EGL_DEPTH_SIZE, 8,// if you need the depth buffer
                    EGL_STENCIL_SIZE,8,
                    EGL_TRANSPARENT_TYPE, EGL_NONE,
                    EGL_NONE
            };
    // EGL context attributes
    const EGLint ctxAttr[] = {
            EGL_CONTEXT_CLIENT_VERSION, 2,// very important!
            EGL_NONE
    };
    // surface attributes
    // the surface size is set to the input frame size
    const EGLint surfaceAttr[] = {
            EGL_WIDTH, (EGLint)srcSize.width,
            EGL_HEIGHT, (EGLint)srcSize.height,
            EGL_NONE
    };
    EGLint eglMajVers, eglMinVers;
    EGLint numConfigs;

    EGLDisplay eglDisp = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if(eglDisp == EGL_NO_DISPLAY)
    {
        //Unable to open connection to local windowing system
        ALOGE("Unable to open connection to local windowing system");
    }
    if(!eglInitialize(eglDisp, &eglMajVers, &eglMinVers))
    {
        // Unable to initialize EGL. Handle and recover
        ALOGE("Unable to initialize EGL");
    }
    ALOGV("EGL init with version %d.%d", eglMajVers, eglMinVers);
    // choose the first config, i.e. best config
    EGLConfig eglConf;
    if(!eglChooseConfig(eglDisp, confAttr, &eglConf, 1, &numConfigs))
    {
        ALOGE("some config is wrong");
    }
    else
    {
        ALOGE("all configs is OK");
    }
    // create a pixelbuffer surface
    EGLSurface eglSurface = eglCreatePbufferSurface(eglDisp, eglConf, surfaceAttr);
    if(eglSurface == EGL_NO_SURFACE)
    {
        switch(eglGetError())
        {
            case EGL_BAD_ALLOC:
                // Not enough resources available. Handle and recover
                ALOGE("Not enough resources available");
                break;
            case EGL_BAD_CONFIG:
                // Verify that provided EGLConfig is valid
                ALOGE("provided EGLConfig is invalid");
                break;
            case EGL_BAD_PARAMETER:
                // Verify that the EGL_WIDTH and EGL_HEIGHT are
                // non-negative values
                ALOGE("provided EGL_WIDTH and EGL_HEIGHT is invalid");
                break;
            case EGL_BAD_MATCH:
                // Check window and EGLConfig attributes to determine
                // compatibility and pbuffer-texture parameters
                ALOGE("Check window and EGLConfig attributes");
                break;
        }
    }
    EGLContext eglCtx = eglCreateContext(eglDisp, eglConf, EGL_NO_CONTEXT, ctxAttr);
    if(eglCtx == EGL_NO_CONTEXT)
    {
        EGLint error = eglGetError();
        if(error == EGL_BAD_CONFIG)
        {
            // Handle error and recover
            ALOGE("EGL_BAD_CONFIG");
        }
    }
    if(!eglMakeCurrent(eglDisp, eglSurface, eglSurface, eglCtx))
    {
        ALOGE("MakeCurrent failed");
    }
    ALOGV("initialize success!");

    MadvGLRenderer_Android* renderer = new MadvGLRenderer_Android(lutPath, srcSize, srcSize, longitudeSegments, latitudeSegments);

    glViewport(0,0, destSize.width, destSize.height);
    glClearColor(0.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    renderer->setSourceTextures(/*false, */sourceTexture, sourceTexture, GL_TEXTURE_2D, false);
    renderer->setIsYUVColorSpace(false);
    renderer->setDisplayMode(0);
    renderer->draw(0,0, destSize.width,destSize.height);
    eglSwapBuffers(eglDisp, eglSurface);
//    ALOGV("QD:GL", "Before glReadPixels");
    GLubyte* pixelData = (GLubyte*) malloc(destSize.width * destSize.height * 4);
    glReadPixels(0, 0, destSize.width, destSize.height, GL_RGBA, GL_UNSIGNED_BYTE, pixelData);
//    ALOGV("QD:GL", "After glReadPixels");
    delete renderer;

    eglMakeCurrent(eglDisp, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    eglDestroyContext(eglDisp, eglCtx);
    eglDestroySurface(eglDisp, eglSurface);
    eglTerminate(eglDisp);

    eglDisp = EGL_NO_DISPLAY;
    eglSurface = EGL_NO_SURFACE;
    eglCtx = EGL_NO_CONTEXT;

    return pixelData;
}
