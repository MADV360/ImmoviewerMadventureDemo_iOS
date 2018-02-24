//
// Created by QiuDong on 16/5/28.
//

#ifndef GLES3JNI_GLES2EXT_H
#define GLES3JNI_GLES2EXT_H

#include "TargetConditionals.h"

#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0

    #define GL_GLEXT_PROTOTYPES
    #include <GLES2/gl2ext.h>

#elif defined(TARGET_OS_OSX) && TARGET_OS_OSX != 0

    #include <OpenGL/glext.h>

#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX != 0

  #ifdef REAL_GLES2
    #include <GLES2/gl2ext.h>
  #else //#ifdef REAL_GLES2
    #include <GL/glext.h>
  #endif //#ifdef REAL_GLES2

    #ifndef GL_RGB16F_EXT
    #define GL_RGB16F_EXT                     0x881B
    #endif

    #ifndef GL_RGBA16F_EXT
    #define GL_RGBA16F_EXT                    0x881A
    #endif

#elif defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0

    #include <OpenGLES/ES2/glext.h>

#endif

#ifndef GL_READ_ONLY_ARB
#define GL_READ_ONLY_ARB                  0x88B8
#endif

#endif //GLES3JNI_GLES2EXT_H
