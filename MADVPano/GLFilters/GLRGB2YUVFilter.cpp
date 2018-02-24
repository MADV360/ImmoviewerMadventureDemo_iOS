//
//  GLRGB2YUVFilter.cpp
//  Madv360_v1
//
//  Created by DOM QIU on 2017/8/15.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#include "GLRGB2YUVFilter.h"

static const char* VertexShaderSource = STRINGIZE
(
 attribute vec4 a_position;
 attribute vec2 a_texcoord;
 
 varying vec2 v_texcoord;
 
 uniform mat4 u_screenMatrix;
 uniform vec2 u_texcoordOrigin;
 uniform vec2 u_texcoordSize;
 
 void main(void) { // 4
     v_texcoord = a_texcoord * u_texcoordSize + u_texcoordOrigin;
     gl_Position = u_screenMatrix * (a_position / a_position.w);
 }
 
 );

static const char* FragmentShaderSource = STRINGIZE2
(
 varying highp vec2 v_texcoord; \n
 \n
 STRINGIZE0(#ifdef EXTERNAL) \n
 STRINGIZE0(#define sourceSampler2D samplerExternalOES) \n
 STRINGIZE0(#else) \n
 STRINGIZE0(#define sourceSampler2D sampler2D) \n
 STRINGIZE0(#endif) \n
 uniform sourceSampler2D u_texture;
 
 void main(void) {
     lowp vec4 textureColor = texture2D(u_texture, v_texcoord);
     const vec3 W = vec3(0.2125, 0.7154, 0.0721);
     float luminance = dot(textureColor.rgb, W);
     
     gl_FragColor = vec4(vec3(luminance), textureColor.a);
 }
 
 );

GLRGB2YUVFilter::GLRGB2YUVFilter()
: GLFilter(&VertexShaderSource, 1, &FragmentShaderSource, 1)
{
    
}

void GLRGB2YUVFilter::render(GLVAO* vao, GLint sourceTexture, GLenum sourceTextureTarget) {
    glActiveTexture(GL_TEXTURE0);
    CHECK_GL_ERROR();
    //    ALOGE("glBindTexture(%d, %d)", sourceTextureTarget, sourceTexture);
    glBindTexture(sourceTextureTarget, sourceTexture);
    CHECK_GL_ERROR();
    glUniform1i(_uniTexture, 0);
    CHECK_GL_ERROR();
    vao->draw(_atrPosition, -1, _atrTexcoord);
}

void GLRGB2YUVFilter::prepareGLProgramSlots(GLint program) {
    _uniTexture = glGetUniformLocation(program, "u_texture");
    _atrPosition = glGetAttribLocation(program, "a_position");
    _atrTexcoord = glGetAttribLocation(program, "a_texcoord");
}

