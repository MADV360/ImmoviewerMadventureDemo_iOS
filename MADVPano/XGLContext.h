//
//  XGLContext.hpp
//  MADVPano_Unix
//
//  Created by DOM QIU on 2018/2/6.
//  Copyright © 2018年 QiuDong. All rights reserved.
//

#ifndef XGLContext_hpp
#define XGLContext_hpp

#ifndef TARGET_OS_ANDROID

#if defined(TARGET_OS_OSX) && TARGET_OS_OSX == 1

#include <OpenGL/OpenGL.h>
#include <OpenGL/gl3.h>
#include <OpenGL/gl3ext.h>

#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX == 1

#ifdef REAL_GLES2

#include <EGL/egl.h>
#include <EGL/eglext.h>

#else //#ifdef REAL_GLES2
#endif //#ifdef REAL_GLES2

#elif defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS == 1

#endif

#include "gles2.h"
#include "gles3.h"
#include <stddef.h>

class XGLContext {
public:
    
    virtual ~XGLContext();
    
    XGLContext(int width, int height, bool withAlpha, bool withDepth, int glesVersion = 2);
    
    int makeCurrent();
    
    void swapBuffers();
    
    static void makeNullCurrent();
    
private:
    
    int _width;
    int _height;
    
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX == 1
    CGLContextObj _ctx = NULL;
#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX == 1

#ifdef REAL_GLES2
    EGLDisplay _eglDisp;
    EGLSurface _eglSurface;
    EGLContext _eglCtx;
#else //#ifdef REAL_GLES2
    OSMesaContext _ctx;
    GLubyte* _buffer;
#endif //#ifdef REAL_GLES2
    
#elif defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS == 1
    
#endif
};

#endif //#ifndef TARGET_OS_ANDROID

#endif /* XGLContext_hpp */
