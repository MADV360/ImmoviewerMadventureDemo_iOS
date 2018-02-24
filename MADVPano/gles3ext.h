//
// Created by QiuDong on 16/5/28.
//

#ifndef GLES3JNI_GLES3EXT_H
#define GLES3JNI_GLES3EXT_H

#include "TargetConditionals.h"

#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
#define GL_GLEXT_PROTOTYPES
#include <GLES3/gl3ext.h>
#elif defined(TARGET_OS_OSX) && TARGET_OS_OSX != 0
#include <OpenGL/gl3ext.h>
#elif defined(TARGET_OS_UNIX) && TARGET_OS_UNIX != 0
#elif defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0
#include <OpenGLES/ES3/glext.h>
#endif

#endif //GLES3JNI_GLES3EXT_H
