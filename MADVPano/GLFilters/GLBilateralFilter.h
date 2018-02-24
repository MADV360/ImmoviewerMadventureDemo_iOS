//
//  GLBilateralFilter.hpp
//  Madv360_v1
//
//  Created by FutureBoy on 7/16/16.
//  Copyright © 2016 Cyllenge. All rights reserved.
//

#ifndef GLBilateralFilter_hpp
#define GLBilateralFilter_hpp

#include "GLFilter.h"
#include "../GLRenderTexture.h"
#include "GLFilterCache.h"
#include "GLPlainFilter.h"

class GLBilateralFilter : public GLFilter {
public:

    virtual ~GLBilateralFilter();

    GLBilateralFilter();

    void render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget);

    void prepareGLProgramSlots(GLint program);
    
protected:
    
    GLint _uniTexture;
    GLint _uniDstSize;
    GLint _uniSrcSize;
    GLint _uniGaussianFactors;
    GLint _uniSimilaritySigma;
    GLint _uniExpLUT;
    
    GLint _atrPosition;
    GLint _atrTexcoord;

    float* _expLUT;
    float* _gaussianFactors;
};

#endif /* GLBilateralFilter_hpp */
