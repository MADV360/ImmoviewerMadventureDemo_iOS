//
//  XGLContext.cpp
//  MADVPano_Unix
//
//  Created by DOM QIU on 2018/2/6.
//  Copyright © 2018年 QiuDong. All rights reserved.
//

#ifndef TARGET_OS_ANDROID

#include "XGLContext.h"
#include "Log.h"
#include <stdlib.h>

#if defined(TARGET_OS_OSX) && TARGET_OS_OSX == 1

#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX == 1

#ifdef REAL_GLES2
#else //#ifdef REAL_GLES2
#endif //#ifdef REAL_GLES2

#elif defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS == 1

#endif

XGLContext::~XGLContext() {
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX == 1
    CGLUnlockContext(_ctx);
    CGLSetCurrentContext(NULL);
    CGLReleaseContext(_ctx);
#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX == 1
    
#ifdef REAL_GLES2
    eglDestroyContext(_eglDisp, _eglCtx);
    eglDestroySurface(_eglDisp, _eglSurface);
    eglTerminate(_eglDisp);
#else //#ifdef REAL_GLES2
    
    /* free the image buffer */
    free(_buffer);
    /* destroy the context */
    OSMesaDestroyContext(_ctx);
    
#endif //#ifdef REAL_GLES2
    
#elif defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS == 1
    
#endif
}

XGLContext::XGLContext(int width, int height, bool withAlpha, bool withDepth, int glesVersion) {
    _width = width;
    _height = height;
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX == 1
    CGLPixelFormatAttribute attribs[] = {
        kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute)kCGLOGLPVersion_Legacy, // This sets the context to 3.2
        kCGLPFAColorSize,     (CGLPixelFormatAttribute)24,
        kCGLPFAAlphaSize,     (CGLPixelFormatAttribute)(withAlpha ? 8 : 0),
        kCGLPFADepthSize,     (CGLPixelFormatAttribute)(withDepth ? 16 : 0),
        //kCGLPFAAccelerated,
        //kCGLPFADoubleBuffer,
        kCGLPFASampleBuffers, (CGLPixelFormatAttribute)1,
        kCGLPFASamples,       (CGLPixelFormatAttribute)4,
        (CGLPixelFormatAttribute)0
    };
    
    CGLPixelFormatObj pix;
    GLint npix;
    CGLChoosePixelFormat(attribs, &pix, &npix);
    
    CGLCreateContext(pix, 0, &_ctx);
#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX == 1
    
#ifdef REAL_GLES2
    
    // EGL config attributes
    const EGLint confAttr[] =
    {
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT_KHR,// very important!
        EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,//EGL_WINDOW_BIT EGL_PBUFFER_BIT we will create a pixelbuffer surface
        EGL_RED_SIZE,   8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE,  8,
        EGL_ALPHA_SIZE, withAlpha ? 8 : 0,// if you need the alpha channel
        EGL_DEPTH_SIZE, withDepth ? 8 : 0,// if you need the depth buffer
        EGL_STENCIL_SIZE, 0,
        EGL_TRANSPARENT_TYPE, EGL_NONE,
        EGL_NONE
    };
    // EGL context attributes
    const EGLint ctxAttr[] = {
        EGL_CONTEXT_CLIENT_VERSION, glesVersion >= 3 ? 3 : 2,// very important!
        EGL_NONE
    };
    // surface attributes
    // the surface size is set to the input frame size
    const EGLint surfaceAttr[] = {
        EGL_WIDTH, (EGLint)width,
        EGL_HEIGHT, (EGLint)height,
        EGL_NONE
    };
    EGLint eglMajVers, eglMinVers;
    EGLint numConfigs;
    
    _eglDisp = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (_eglDisp == EGL_NO_DISPLAY)
    {
        //Unable to open connection to local windowing system
        ALOGE("\nUnable to open connection to local windowing system");
    }
    if (!eglInitialize(_eglDisp, &eglMajVers, &eglMinVers))
    {
        // Unable to initialize EGL. Handle and recover
        ALOGE("\nUnable to initialize EGL");
    }
    ALOGV("\nEGL init with version %d.%d", eglMajVers, eglMinVers);
    // choose the first config, i.e. best config
    EGLConfig eglConf;
    if (!eglChooseConfig(_eglDisp, confAttr, &eglConf, 1, &numConfigs))
    {
        ALOGE("\nsome config is wrong");
    }
    else
    {
        ALOGE("\nall configs is OK");
    }
    // create a pixelbuffer surface
    _eglSurface = eglCreatePbufferSurface(_eglDisp, eglConf, surfaceAttr);
    if (_eglSurface == EGL_NO_SURFACE)
    {
        switch (eglGetError())
        {
            case EGL_BAD_ALLOC:
                // Not enough resources available. Handle and recover
                ALOGE("\nNot enough resources available");
                break;
            case EGL_BAD_CONFIG:
                // Verify that provided EGLConfig is valid
                ALOGE("\nprovided EGLConfig is invalid");
                break;
            case EGL_BAD_PARAMETER:
                // Verify that the EGL_WIDTH and EGL_HEIGHT are
                // non-negative values
                ALOGE("\nprovided EGL_WIDTH and EGL_HEIGHT is invalid");
                break;
            case EGL_BAD_MATCH:
                // Check window and EGLConfig attributes to determine
                // compatibility and pbuffer-texture parameters
                ALOGE("\nCheck window and EGLConfig attributes");
                break;
        }
    }
    _eglCtx = eglCreateContext(_eglDisp, eglConf, EGL_NO_CONTEXT, ctxAttr);
    if (_eglCtx == EGL_NO_CONTEXT)
    {
        EGLint error = eglGetError();
        if (error == EGL_BAD_CONFIG)
        {
            // Handle error and recover
            throw "EGL_BAD_CONFIG";
        }
    }
    
#else //#ifdef REAL_GLES2

#if OSMESA_MAJOR_VERSION * 100 + OSMESA_MINOR_VERSION >= 305
    /* specify Z, stencil, accum sizes */
    _ctx = OSMesaCreateContextExt(withAlpha ? OSMESA_RGBA : OSMESA_RGB, withDepth ? 16 : 0, 0, 0, NULL);
#else //#if OSMESA_MAJOR_VERSION * 100 + OSMESA_MINOR_VERSION >= 305
    _ctx = OSMesaCreateContext(OSMESA_RGBA, NULL);
#endif //#if OSMESA_MAJOR_VERSION * 100 + OSMESA_MINOR_VERSION >= 305
    if (!_ctx)
    {
        throw "OSMesaCreateContext failed!\n";
    }
    
    /* Allocate the image buffer */
    _buffer = (GLubyte*) malloc(_width * _height * (withAlpha ? 4 : 3) * sizeof(GLubyte));
    if (!_buffer)
    {
        throw "Alloc image buffer failed!\n";
    }

#endif //#ifdef REAL_GLES2

#elif defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS == 1
#endif
}

int XGLContext::makeCurrent() {
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX == 1
    CGLSetCurrentContext(_ctx);
    CGLLockContext(_ctx);
#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX == 1
    
#ifdef REAL_GLES2
    if (!eglMakeCurrent(_eglDisp, _eglSurface, _eglSurface, _eglCtx))
    {
        ALOGE("MakeCurrent failed");
    }
#else //#ifdef REAL_GLES2
    /* Bind the buffer to the context and make it current */
    if (!OSMesaMakeCurrent(_ctx, _buffer, GL_UNSIGNED_BYTE, _width, _height))
    {
        ALOGE("OSMesaMakeCurrent failed!\n");
        return -1;
    }
#endif //#ifdef REAL_GLES2
    
#elif defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS == 1
    
#endif
    return 0;
}

void XGLContext::swapBuffers() {
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX == 1
    CGLUnlockContext(_ctx);
#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX == 1
    
#ifdef REAL_GLES2
    eglSwapBuffers(_eglDisp, _eglSurface);
#else //#ifdef REAL_GLES2
#endif //#ifdef REAL_GLES2
    
#elif defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS == 1
    
#endif
}

void XGLContext::makeNullCurrent() {
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX == 1
    CGLSetCurrentContext(NULL);
#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX == 1
    
#ifdef REAL_GLES2
    eglMakeCurrent(NULL, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
#else //#ifdef REAL_GLES2
#endif //#ifdef REAL_GLES2
    
#elif defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS == 1
    
#endif
}

#endif //#ifndef TARGET_OS_ANDROID
