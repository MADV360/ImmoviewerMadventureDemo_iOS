//
// Created by QiuDong on 16/5/28.
//

#ifndef GLES3JNI_GLES3STUB_H
#define GLES3JNI_GLES3STUB_H

#include "TargetConditionals.h"

#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
#include <GLES3/gl3.h>
#elif defined(TARGET_OS_OSX) && TARGET_OS_OSX != 0
#include <OpenGL/gl3.h>
#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX != 0

  #ifdef REAL_GLES2
    #include <EGL/egl.h>
    #include <GLES3/gl3platform.h>
    #include <GLES3/gl3ext.h>
    #include <GLES3/gl3.h>
  #endif //#ifdef REAL_GLES2

#elif defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0
#include <OpenGLES/ES3/gl.h>
#endif

#ifndef GL_RGB16F_EXT
#define GL_RGB16F_EXT GL_RGB16F
#endif

#endif //GLES3JNI_GLES3STUB_H
