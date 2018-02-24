//
// Created by QiuDong on 16/9/1.
//

#ifndef MADV1_0_GLTESTFILTER_H
#define MADV1_0_GLTESTFILTER_H

#include "GLFilter.h"
#include "../GLRenderTexture.h"

class GLTestFilter : public GLFilter {
public:

    GLTestFilter();

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

//typedef AutoRef<GLTestFilter> GLTestFilterRef;

#endif //MADV1_0_GLTESTFILTER_H
