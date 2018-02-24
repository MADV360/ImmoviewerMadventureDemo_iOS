//
// Created by QiuDong on 16/7/22.
//

#ifndef APP_ANDROID_GLPLAINFILTER_H
#define APP_ANDROID_GLPLAINFILTER_H

#include "GLFilter.h"
#include "../GLRenderTexture.h"

class GLPlainFilter : public GLFilter {
public:

    GLPlainFilter();

    void render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget);

    void prepareGLProgramSlots(GLint program);

protected:

    GLint _uniTexture;
    GLint _uniDstSize;
    GLint _uniSrcSize;

    GLint _atrPosition;
    GLint _atrColor;
    GLint _atrTexcoord;
};

//typedef AutoRef<GLPlainFilter> GLPlainFilterRef;


#endif //APP_ANDROID_GLPLAINFILTER_H
