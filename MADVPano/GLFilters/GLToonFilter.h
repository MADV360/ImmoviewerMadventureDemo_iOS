//
//  GLToonFilter.hpp
//  Madv360_v1
//
//  Created by DOM QIU on 2017/8/16.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#ifndef GLToonFilter_hpp
#define GLToonFilter_hpp

#include "GLFilter.h"
//#include "../GLRenderTexture.h"

class GLToonFilter : public GLFilter {
public:
    
    GLToonFilter();
    
    void render(GLVAO* vao, GLint sourceTexture, GLenum sourceTextureTarget);
    
    void prepareGLProgramSlots(GLint program);
    
    void setThreshold(GLfloat threshold);
    
    void setQuantizationLevels(GLfloat quantizationLevels);
    
protected:
    
    GLint _uniTexture;
    GLint _uniDstSize;
    GLint _uniSrcSize;
    
    GLint _atrPosition;
    GLint _atrTexcoord;
    
    GLint _uniThreshold;
    GLint _uniQuantizationLevels;
    
    GLfloat _threshold = 0.2;
    GLfloat _quantizationLevels = 10.0;
};

//typedef AutoRef<GLToonFilter> GLToonFilterRef;

#endif /* GLToonFilter_hpp */
