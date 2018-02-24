//
//  GLSimpleBeautyFilter.h
//  Madv360_v1
//
//  Created by QiuDong on 16/7/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#ifndef GLSimpleBeautyFilter_h
#define GLSimpleBeautyFilter_h

#include "GLFilter.h"
#include "OpenGLHelper.h"
//#include "AutoRef.h"

class GLSimpleBeautyFilter : public GLFilter {
public:
    
    GLSimpleBeautyFilter();

    void render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget);

    void prepareGLProgramSlots(GLint program);

protected:
    
    GLint _uniTexture;
    GLint _uniTexWidthOffset;
    GLint _uniTexHeightOffset;
    GLint _uniDistanceNormalizationFactor;
    
    GLint _atrPosition;
    GLint _atrTexcoord;
};

//typedef AutoRef<GLSimpleBeautyFilter> GLSimpleBeautyFilterRef;

#endif /* GLSimpleBeautyFilter_h */

