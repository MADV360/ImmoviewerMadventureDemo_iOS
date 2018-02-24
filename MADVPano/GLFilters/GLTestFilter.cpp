//
// Created by QiuDong on 16/9/1.
//

#include "GLTestFilter.h"

static const char* VertexShaderSource = STRINGIZE
(
        attribute vec4 a_position; // 1
        attribute vec4 a_color; // 2
        attribute vec2 a_texcoord;

        varying vec4 v_color; // 3
        varying vec2 v_texcoord;

        uniform mat4 u_screenMatrix;
        uniform vec2 u_texcoordOrigin;
        uniform vec2 u_texcoordSize;

        void main(void) { // 4
            v_color = a_color; // 5
            v_texcoord = a_texcoord * u_texcoordSize + u_texcoordOrigin;
            gl_Position = u_screenMatrix * (a_position / a_position.w);
//            gl_Position = a_position;
        }
);

static const char* FragmentShaderSource = STRINGIZE2
(
        varying highp vec4 v_color; \n
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

        void main(void) {
//        if (v_texcoord.s >= 0.0 && v_texcoord.s <= 1.0 && v_texcoord.t >= 0.0 && v_texcoord.t <= 1.0)
//        gl_FragColor = texture2D(u_texture, v_texcoord);
//        else
        gl_FragColor = vec4(v_texcoord.s, v_texcoord.t, 1.0,1.0);
}

);

GLTestFilter::GLTestFilter()
        : GLFilter(&VertexShaderSource, 1, &FragmentShaderSource, 1)
{

}

void GLTestFilter::render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget) {
    glActiveTexture(GL_TEXTURE0);
    CHECK_GL_ERROR();
//    ALOGE("glBindTexture(%d, %d)", sourceTextureTarget, sourceTexture);
    glBindTexture(sourceTextureTarget, sourceTexture);
    CHECK_GL_ERROR();
    glUniform1i(_uniTexture, 0);
    CHECK_GL_ERROR();
    Vec2f destSize = getDestRectSize();
    glUniform2f(_uniDstSize, destSize.width, destSize.height);
    CHECK_GL_ERROR();
    ptrVAO->draw(_atrPosition, -1, _atrTexcoord);
}

void GLTestFilter::prepareGLProgramSlots(GLint program) {
    _uniTexture = glGetUniformLocation(program, "u_texture");
    _uniDstSize = glGetUniformLocation(program, "u_dstSize");
    _uniSrcSize = glGetUniformLocation(program, "u_srcSize");
    _atrPosition = glGetAttribLocation(program, "a_position");
    _atrColor = glGetAttribLocation(program, "a_color");
    _atrTexcoord = glGetAttribLocation(program, "a_texcoord");
}

