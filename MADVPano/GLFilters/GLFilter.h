//
//  GLFilter.hpp
//  Madv360_v1
//
//  Created by QiuDong on 16/7/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#ifndef GLFilter_hpp
#define GLFilter_hpp

#include "OpenGLHelper.h"
#include "GLVAO.h"
#include "AutoRef.h"

class GLFilter {
public:
    
    virtual ~GLFilter();
    
    GLFilter(const GLchar** vertexShaderSources, int vertexShaderSourceCount, const GLchar** fragmentShaderSources, int fragmentShaderSourceCount);
    
    virtual void render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget);
    
    virtual void prepareGLProgramSlots(GLint program);
    
    virtual void render(GLfloat x, GLfloat y, GLfloat width, GLfloat height, GLint sourceTexture, GLenum sourceTextureTarget);
    
    virtual void render(GLfloat x, GLfloat y, GLfloat width, GLfloat height, GLint sourceTexture, GLenum sourceTextureTarget, Orientation2D sourceOrientation, Vec2f texcoordOrigin, Vec2f texcoordSize);
    
    virtual void initGLObjects();
    
    virtual void releaseGLObjects();
    
protected:
    
    void releaseShaderSources();
    
    inline Vec2f getDestRectSize() {
        return _boundRectSize;
    }
    
    inline Vec2f getClippedTexcoordSize() {
        return _texcoordSize;
    }
    
    AutoRef<GLVAO> _vao = NULL;
    
private:
    
    GLint _glProgram = -1;
    GLint _glExtProgram = -1;
    
    GLint _uniScreenMatrix = -1;
    GLint _uniTexcoordOrigin = -1;
    GLint _uniTexcoordSize = -1;
    
    GLchar** _vertexShaderSources = NULL;
    int _vertexShaderSourceCount = 0;
    GLchar** _fragmentShaderSources = NULL;
    int _fragmentShaderSourceCount = 0;
    
    Vec2f _boundRectOrigin;
    Vec2f _boundRectSize;
    
    Vec2f _texcoordOrigin;
    Vec2f _texcoordSize;
    
    void prepareGLProgram();
    void prepareExtGLProgram();
};

//typedef AutoRef<GLFilter> GLFilterRef;

#endif /* GLFilter_hpp */
