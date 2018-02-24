//
//  GLInverseColorFilter.hpp
//  Madv360_v1
//
//  Created by QiuDong on 16/7/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#ifndef GLInverseColorFilter_hpp
#define GLInverseColorFilter_hpp

#include "GLFilter.h"
#include "../GLRenderTexture.h"

class GLInverseColorFilter : public GLFilter {
public:
    
    GLInverseColorFilter();
    
    void render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget);

//    void render(int x, int y, int width, int height, GLint sourceTexture);
//    
//    void render(int x, int y, int width, int height, GLint sourceTexture, GLFilterOrientation sourceOrientation, Vec2f texcoordOrigin, Vec2f texcoordSize);

    void prepareGLProgramSlots(GLint program);

protected:
    
    GLint _uniTexture;
    GLint _uniDstSize;
    GLint _uniSrcSize;
    
    GLint _atrPosition;
    GLint _atrColor;
    GLint _atrTexcoord;
    
//    GLRenderTextureRef _renderTexture = NULL;
};

//typedef AutoRef<GLInverseColorFilter> GLInverseColorFilterRef;

#endif /* GLInverseColorFilter_hpp */
