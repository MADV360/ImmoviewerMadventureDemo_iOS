//
//  GLSobelEdgeDetectSketchFilter.hpp
//  Madv360_v1
//
//  Created by DOM QIU on 2017/8/16.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#ifndef GLSobelEdgeDetectSketchFilter_hpp
#define GLSobelEdgeDetectSketchFilter_hpp

#include "GLFilter.h"
//#include "../GLRenderTexture.h"

class GLSobelEdgeDetectSketchFilter : public GLFilter {
public:
    
    GLSobelEdgeDetectSketchFilter();
    
    void render(GLVAO* vao, GLint sourceTexture, GLenum sourceTextureTarget);
    
    void prepareGLProgramSlots(GLint program);
    
    void setEdgeStrength(GLfloat edgeStrength);
    
protected:
    
    GLint _uniTexture;
    GLint _uniDstSize;
    GLint _uniSrcSize;
    
    GLint _atrPosition;
    GLint _atrTexcoord;
    
    GLint _uniEdgeStrength;
    
    GLfloat _edgeStrength;
};

//typedef AutoRef<GLSobelEdgeDetectSketchFilter> GLSobelEdgeDetectSketchFilterRef;

#endif /* GLSobelEdgeDetectSketchFilter_hpp */
