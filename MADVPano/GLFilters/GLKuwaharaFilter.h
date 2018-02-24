//
//  GLKuwaharaFilter.hpp
//  Madv360_v1
//
//  Created by FutureBoy on 7/20/16.
//  Copyright © 2016 Cyllenge. All rights reserved.
//

#ifndef GLKuwaharaFilter_hpp
#define GLKuwaharaFilter_hpp

#include "GLFilter.h"
#include "../GLRenderTexture.h"

class GLKuwaharaFilter : public GLFilter {
public:
    
    GLKuwaharaFilter();
    
    void render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget);

    void prepareGLProgramSlots(GLint program);
    
protected:
    
    GLint _uniTexture;
    GLint _uniDstSize;
    GLint _uniSrcSize;
    
    GLint _uniRadius;
    
    GLint _atrPosition;
    GLint _atrColor;
    GLint _atrTexcoord;
};

//typedef AutoRef<GLKuwaharaFilter> GLKuwaharaFilterRef;

#endif /* GLKuwaharaFilter_hpp */
