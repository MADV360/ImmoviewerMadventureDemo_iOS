//
//  GLColorMatrixFilter.hpp
//  Madv360_v1
//
//  Created by QiuDong on 16/7/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#ifndef GLColorMatrixFilter_hpp
#define GLColorMatrixFilter_hpp

#include "GLFilter.h"
#include "kazmath.h"

class GLColorMatrixFilter : public GLFilter {
public:
    
    GLColorMatrixFilter(kmMat4 colorMatrix, float intensity);
    
    void render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget);

//    void render(int x, int y, int width, int height, GLint sourceTexture);
//    
//    void render(int x, int y, int width, int height, GLint sourceTexture, GLFilterOrientation sourceOrientation, Vec2f texcoordOrigin, Vec2f texcoordSize);

    void prepareGLProgramSlots(GLint program);

protected:

    GLint _uniColorMatrix;
    GLint _uniIntensity;

    GLint _uniTexture;
    
    GLint _atrPosition;
    GLint _atrTexcoord;

    kmMat4 _colorMatrix;
    float  _intensity;
};

//typedef AutoRef<GLColorMatrixFilter> GLColorMatrixFilterRef;

#endif /* GLColorMatrixFilter_hpp */
