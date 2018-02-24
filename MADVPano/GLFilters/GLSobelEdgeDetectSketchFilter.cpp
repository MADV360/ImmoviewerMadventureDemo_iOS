//
//  GLSobelEdgeDetectSketchFilter.cpp
//  Madv360_v1
//
//  Created by DOM QIU on 2017/8/16.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#include "GLSobelEdgeDetectSketchFilter.h"

static const char* VertexShaderSource = STRINGIZE
(
 attribute vec4 a_position;
 attribute vec2 a_texcoord;
 
 varying vec2 v_texcoord;
 
 uniform mat4 u_screenMatrix;
 uniform vec2 u_texcoordOrigin;
 uniform vec2 u_texcoordSize;
 
 void main(void) {
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
 
 uniform highp vec2 u_dstSize;
 uniform highp vec2 u_srcSize;
 
 uniform lowp float u_edgeStrength;
 
 const vec3 W = vec3(0.2125, 0.7154, 0.0721);
 \n
 lowp float luminanceOfTexcoord(sourceSampler2D texture, highp vec2 texcoord) {//, highp vec2 diffTexcoord) {
//     highp vec2 clampedTexcoord = clamp(texcoord, vec2(0.0, 0.0), vec2(1.0, 1.0));
//     lowp vec4 textureColor = texture2D(texture, clampedTexcoord);
     lowp vec4 textureColor = texture2D(texture, texcoord);
     lowp float luminance = dot(textureColor.rgb, W);
     return luminance;
 }
 \n
 void main(void) {
     vec2 diffTexcoord = u_srcSize / u_dstSize;
     \n
     lowp float topLeftIntensity = luminanceOfTexcoord(u_texture, v_texcoord + diffTexcoord * vec2(-1.0, 1.0));
     lowp float topIntensity = luminanceOfTexcoord(u_texture, v_texcoord + diffTexcoord * vec2(0.0, 1.0));
     lowp float topRightIntensity = luminanceOfTexcoord(u_texture, v_texcoord + diffTexcoord * vec2(1.0, 1.0));
     \n
     lowp float bottomLeftIntensity = luminanceOfTexcoord(u_texture, v_texcoord + diffTexcoord * vec2(-1.0, -1.0));
     lowp float bottomIntensity = luminanceOfTexcoord(u_texture, v_texcoord + diffTexcoord * vec2(0.0, -1.0));
     lowp float bottomRightIntensity = luminanceOfTexcoord(u_texture, v_texcoord + diffTexcoord * vec2(1.0, -1.0));
     \n
     lowp float leftIntensity = luminanceOfTexcoord(u_texture, v_texcoord + diffTexcoord * vec2(-1.0, 0.0));
     //lowp float topIntensity = luminanceOfTexcoord(u_texture, v_texcoord + diffTexcoord * vec2(0.0, 0.0));
     lowp float rightIntensity = luminanceOfTexcoord(u_texture, v_texcoord + diffTexcoord * vec2(1.0, 0.0));
     \n
     float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
     float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
     \n
     float mag = 1.0 - (length(vec2(h, v)) * u_edgeStrength);
     gl_FragColor = vec4(vec3(mag), 1.0);
//     gl_FragColor = vec4(vec3(luminanceOfTexcoord(u_texture, v_texcoord + diffTexcoord)), 1.0);///!!!For Debug
 }
 
 );

GLSobelEdgeDetectSketchFilter::GLSobelEdgeDetectSketchFilter()
: GLFilter(&VertexShaderSource, 1, &FragmentShaderSource, 1)
, _edgeStrength(1.f)
{
    
}

void GLSobelEdgeDetectSketchFilter::render(GLVAO* vao, GLint sourceTexture, GLenum sourceTextureTarget) {
    glActiveTexture(GL_TEXTURE0);
    CHECK_GL_ERROR();
    //    ALOGE("glBindTexture(%d, %d)", sourceTextureTarget, sourceTexture);
    glBindTexture(sourceTextureTarget, sourceTexture);
    CHECK_GL_ERROR();
    glUniform1i(_uniTexture, 0);
    CHECK_GL_ERROR();
    Vec2f destSize = getDestRectSize();
    glUniform2f(_uniDstSize, destSize.width, destSize.height);
    Vec2f clippedTextureSize = getClippedTexcoordSize();
    glUniform2f(_uniSrcSize, clippedTextureSize.width, clippedTextureSize.height);
    CHECK_GL_ERROR();
    glUniform1f(_uniEdgeStrength, _edgeStrength);
    vao->draw(_atrPosition, -1, _atrTexcoord);
}

void GLSobelEdgeDetectSketchFilter::prepareGLProgramSlots(GLint program) {
    _uniTexture = glGetUniformLocation(program, "u_texture");
    _uniDstSize = glGetUniformLocation(program, "u_dstSize");
    _uniSrcSize = glGetUniformLocation(program, "u_srcSize");
    _uniEdgeStrength = glGetUniformLocation(program, "u_edgeStrength");
    _atrPosition = glGetAttribLocation(program, "a_position");
    _atrTexcoord = glGetAttribLocation(program, "a_texcoord");
}

void GLSobelEdgeDetectSketchFilter::setEdgeStrength(GLfloat edgeStrength) {
    _edgeStrength = edgeStrength;
}

