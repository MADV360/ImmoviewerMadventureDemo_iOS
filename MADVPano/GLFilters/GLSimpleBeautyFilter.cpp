//
//  GLSimpleBeautyFilter.c
//  Madv360_v1
//
//  Created by QiuDong on 16/7/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#include "GLSimpleBeautyFilter.h"

static const char* VertexShaderSource = STRINGIZE
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
// const int GAUSSIAN_SAMPLES = 9;
//
// uniform float texelWidthOffset;
// uniform float texelHeightOffset;

        uniform mat4 u_screenMatrix;
        uniform vec2 u_texcoordOrigin;
        uniform vec2 u_texcoordSize;

 varying vec2 textureCoordinate;
// varying vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main()
 {
     gl_Position = u_screenMatrix * (position / position.w);
//     textureCoordinate = inputTextureCoordinate.xy;
     textureCoordinate = inputTextureCoordinate.xy * u_texcoordSize + u_texcoordOrigin;

//     // Calculate the positions for the blur
//     int multiplier = 0;
//     vec2 blurStep;
//     vec2 singleStepOffset = vec2(texelWidthOffset, texelHeightOffset);
//
//     for (int i = 0; i < GAUSSIAN_SAMPLES; i++)
//     {
//         multiplier = (i - ((GAUSSIAN_SAMPLES - 1) / 2));
//         // Blur in x (horizontal)
//         blurStep = float(multiplier) * singleStepOffset;
//         blurCoordinates[i] = textureCoordinate + blurStep;
//     }
 }
 );

static const char* FragmentShaderSource = STRINGIZE2
(
        \n
        STRINGIZE0(#ifdef EXTERNAL) \n
        STRINGIZE0(#define sourceSampler2D samplerExternalOES) \n
        STRINGIZE0(#else) \n
        STRINGIZE0(#define sourceSampler2D sampler2D) \n
        STRINGIZE0(#endif) \n
        uniform sourceSampler2D inputImageTexture;
 
// const lowp int GAUSSIAN_SAMPLES = 9;
 
 varying highp vec2 textureCoordinate;
// varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
// uniform mediump float distanceNormalizationFactor;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
//        gl_FragColor = vec4(0.1, 1.0, 0.0, 1.0);
}
 );

GLSimpleBeautyFilter::GLSimpleBeautyFilter()
        : GLFilter(&VertexShaderSource, 1, &FragmentShaderSource, 1)
{

}

void GLSimpleBeautyFilter::render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget) {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(sourceTextureTarget, sourceTexture);
    glUniform1i(_uniTexture, 0);
    
    glUniform1f(_uniDistanceNormalizationFactor, 8.0);

    Vec2f destSize = getDestRectSize();
    glUniform1f(_uniTexWidthOffset, 1.f / destSize.width);
    glUniform1f(_uniTexHeightOffset, 1.f / destSize.height);

    ptrVAO->draw(_atrPosition, -1, _atrTexcoord);
    /*/
     glClearColor(0, 0, 1, 1);
     glClear(GL_COLOR_BUFFER_BIT);
     //*/
}

void GLSimpleBeautyFilter::prepareGLProgramSlots(GLint program) {
    _uniTexture = glGetUniformLocation(program, "inputImageTexture");
    _uniTexWidthOffset = glGetUniformLocation(program, "texelWidthOffset");
    _uniTexHeightOffset = glGetUniformLocation(program, "texelHeightOffset");
    _uniDistanceNormalizationFactor = glGetUniformLocation(program, "distanceNormalizationFactor");
    _atrPosition = glGetAttribLocation(program, "position");
    _atrTexcoord = glGetAttribLocation(program, "inputTextureCoordinate");
}
