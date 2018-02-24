#include "GLColorMatrixFilter.h"

static const char* VertexShaderSource = STRINGIZE
(
        attribute vec4 a_position; // 1
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
        varying highp vec2 v_texcoord;

        uniform sampler2D u_texture;

        uniform lowp mat4 u_colorMatrix;
        uniform lowp float u_intensity;

        void main()
        {
            lowp vec4 textureColor = texture2D(u_texture, v_texcoord);
            lowp vec4 outputColor = textureColor * u_colorMatrix;

            gl_FragColor = (u_intensity * outputColor) + ((1.0 - u_intensity) * textureColor);
        }
);

GLColorMatrixFilter::GLColorMatrixFilter(kmMat4 colorMatrix, float intensity)
        : GLFilter(&VertexShaderSource, 1, &FragmentShaderSource, 1)
, _colorMatrix(colorMatrix)
, _intensity(intensity)
{

}

void GLColorMatrixFilter::render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget) {
    glActiveTexture(GL_TEXTURE0);
    CHECK_GL_ERROR();
//    ALOGE("glBindTexture(%d, %d)", sourceTextureTarget, sourceTexture);
    glBindTexture(sourceTextureTarget, sourceTexture);
    CHECK_GL_ERROR();
    glUniform1i(_uniTexture, 0);
    CHECK_GL_ERROR();
    glUniform1f(_uniIntensity, _intensity);
    CHECK_GL_ERROR();
    glUniformMatrix4fv(_uniColorMatrix, 1, false, _colorMatrix.mat);
    CHECK_GL_ERROR();
    ptrVAO->draw(_atrPosition, -1, _atrTexcoord);
}

void GLColorMatrixFilter::prepareGLProgramSlots(GLint program) {
    _uniIntensity = glGetUniformLocation(program, "u_intensity");
    _uniColorMatrix = glGetUniformLocation(program, "u_colorMatrix");
    _uniTexture = glGetUniformLocation(program, "u_texture");
    _atrPosition = glGetAttribLocation(program, "a_position");
    _atrTexcoord = glGetAttribLocation(program, "a_texcoord");
}

