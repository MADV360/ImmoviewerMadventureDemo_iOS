//
// Created by QiuDong on 16/5/28.
//

#ifndef GLES3JNI_GLES2STUB_H
#define GLES3JNI_GLES2STUB_H

#include "TargetConditionals.h"

#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0

    #include <GLES2/gl2.h>

#elif defined(TARGET_OS_OSX) && TARGET_OS_OSX != 0

    #include <OpenGL/gl.h>
    #include <OpenGL/glext.h>

    #define glDeleteVertexArraysOES glDeleteVertexArraysAPPLE
    #define glGenVertexArraysOES glGenVertexArraysAPPLE
    #define glBindVertexArrayOES glBindVertexArrayAPPLE

    #define GL_VERTEX_ARRAY_BINDING_OES GL_VERTEX_ARRAY_BINDING_APPLE

    #ifndef GL_RGBA16F_EXT
    #define GL_RGBA16F_EXT GL_RGBA16F_ARB
    #endif

    #ifndef GL_RGB16F_EXT
    #define GL_RGB16F_EXT GL_RGB16F_ARB
    #endif

#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX != 0

  #ifdef REAL_GLES2
    #include <EGL/egl.h>
    #include <GLES2/gl2platform.h>
    #include <GLES2/gl2.h>
    #include <GLES2/gl2ext.h>
  #else //#ifdef REAL_GLES2
    #include "GL/osmesa.h"
    //#include "gl_wrap.h"
    #include "GL/glu.h"
    #include <X11/Xlib.h>
    #include <X11/Xutil.h>
    #include <X11/keysym.h>
    #include <GL/glext.h>

    #define glDeleteVertexArraysOES glDeleteVertexArrays
    #define glGenVertexArraysOES glGenVertexArrays
    #define glBindVertexArrayOES glBindVertexArray

    #define GL_VERTEX_ARRAY_BINDING_OES GL_VERTEX_ARRAY_BINDING
  #endif //#ifdef REAL_GLES2
#elif defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0

    #include <OpenGLES/ES2/gl.h>

#elif defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0

    #pragma comment(lib, "openGL32.lib")
    #pragma comment(lib, "glext.lib")
    #include <windows.h>
    #include <gl/gl.h>
    #include <gl/glext.h>
    //#include <gl/glu.h>

    #define _USE_MATH_DEFINES
    #include <math.h>
    //#include <cmath>

    #include <stdint.h>

    #define glDeleteVertexArraysOES glDeleteVertexArrays
    #define glGenVertexArraysOES glGenVertexArrays
    #define glBindVertexArrayOES glBindVertexArray

    #define GL_VERTEX_ARRAY_BINDING_OES GL_VERTEX_ARRAY_BINDING

    #ifndef GL_RGBA16F_EXT
    #define GL_RGBA16F_EXT GL_RGBA16F
    #endif

    #ifndef GL_RGB16F_EXT
    #define GL_RGB16F_EXT GL_RGB16F
    #endif

#endif

#ifndef GL_TEXTURE_EXTERNAL_OES
#define GL_TEXTURE_EXTERNAL_OES 0x8D65
#endif

#endif //GLES3JNI_GLES2STUB_H
