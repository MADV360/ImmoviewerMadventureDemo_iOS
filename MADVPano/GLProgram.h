//
//  GLShaderProgram.h
//  Madv360
//
//  Created by FutureBoy on 11/5/15.
//  Copyright © 2015 Cyllenge. All rights reserved.
//

#ifndef GLProgram_hpp
#define GLProgram_hpp

#include "gles2.h"

class GLProgram {
public:
    
    virtual ~GLProgram();
    
    GLProgram(const GLchar* const* vertexSources, int vertexSourcesCount, const GLchar* const* fragmentSources, int fragmentSourcesCount);
    
    inline GLuint getProgram() {return _program;}
    
    inline GLuint getPositionSlot() {return _positionSlot;}
    inline GLuint getColorSlot() {return _colorSlot;}
    inline GLuint getTexcoordSlot() {return _texcoordSlot;}
    inline GLuint getNormSlot() {return _normSlot;}
    
    inline GLuint getTextureSlot() {return _textureSlot;}
    inline GLuint getDTexcoordSlot() {return _dTexcoordSlot;}
    
    inline GLuint getProjectionMatrixSlot() {return _projectionMatrixSlot;}
    inline GLuint getCameraMatrixSlot() {return _cameraMatrixSlot;}
    inline GLuint getModelMatrixSlot() {return _modelMatrixSlot;}
    inline GLuint getScreenMatrixSlot() {return _screenMatrixSlot;}

protected:
    
    GLint  _program;
    GLint  _vertexShader;
    GLint  _fragmentShader;
    
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _texcoordSlot;
    GLuint _normSlot;
    
    GLuint _textureSlot;
    GLuint _dTexcoordSlot;
    
    GLuint _projectionMatrixSlot;
    GLuint _cameraMatrixSlot;
    GLuint _modelMatrixSlot;
    GLuint _screenMatrixSlot;
};

//typedef AutoRef<GLProgram> GLProgramRef;

#endif //GLProgram_hpp
