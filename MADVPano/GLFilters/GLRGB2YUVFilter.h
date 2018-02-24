//
//  GLRGB2YUVFilter.hpp
//  Madv360_v1
//
//  Created by DOM QIU on 2017/8/15.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#ifndef GLRGB2YUVFilter_hpp
#define GLRGB2YUVFilter_hpp

#include "GLFilter.h"

class GLRGB2YUVFilter : public GLFilter {
public:
    
    GLRGB2YUVFilter();
    
    void render(GLVAO* vao, GLint sourceTexture, GLenum sourceTextureTarget);
    
    //    void render(int x, int y, int width, int height, GLint sourceTexture);
    //
    //    void render(int x, int y, int width, int height, GLint sourceTexture, GLFilterOrientation sourceOrientation, Vec2f texcoordOrigin, Vec2f texcoordSize);
    
    void prepareGLProgramSlots(GLint program);
    
protected:
    
    GLint _uniTexture;
    
    GLint _atrPosition;
    GLint _atrTexcoord;
    
    //    GLRenderTextureRef _renderTexture = NULL;
};

//typedef AutoRef<GLRGB2YUVFilter> GLRGB2YUVFilterRef;

#endif /* GLRGB2YUVFilter_hpp */
