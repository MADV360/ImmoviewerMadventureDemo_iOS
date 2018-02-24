#include "GLColorLookupFilter.h"

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
        uniform sampler2D u_lookupTexture; // lookup texture

        uniform lowp float u_intensity;

        void main()
        {
            highp vec4 textureColor = texture2D(u_texture, v_texcoord);

            highp float blueColor = textureColor.b * 63.0;

            highp vec2 quad1;
            quad1.y = floor(floor(blueColor) / 8.0);
            quad1.x = floor(blueColor) - (quad1.y * 8.0);

            highp vec2 quad2;
            quad2.y = floor(ceil(blueColor) / 8.0);
            quad2.x = ceil(blueColor) - (quad2.y * 8.0);

            highp vec2 texPos1;
            texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
            texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

            highp vec2 texPos2;
            texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
            texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

            lowp vec4 newColor1 = texture2D(u_lookupTexture, texPos1);
            lowp vec4 newColor2 = texture2D(u_lookupTexture, texPos2);

            lowp vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
            gl_FragColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), u_intensity);
//            gl_FragColor = texture2D(u_lookupTexture, v_texcoord);
        }
);

GLColorLookupFilter::GLColorLookupFilter()
        : GLFilter(&VertexShaderSource, 1, &FragmentShaderSource, 1)
        , _lookupTexture(-1)
        , _intensity(1.0f)
{

}

void GLColorLookupFilter::render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget) {
    glActiveTexture(GL_TEXTURE0);
    CHECK_GL_ERROR();
//    ALOGE("glBindTexture(%d, %d)", sourceTextureTarget, sourceTexture);
    glBindTexture(sourceTextureTarget, sourceTexture);
    CHECK_GL_ERROR();
    glUniform1i(_uniTexture, 0);
    CHECK_GL_ERROR();

    if (-1 != _lookupTexture)
    {
        glActiveTexture(GL_TEXTURE1);
        CHECK_GL_ERROR();
        glBindTexture(GL_TEXTURE_2D, _lookupTexture);
        CHECK_GL_ERROR();
        glUniform1i(_uniLookupTexture, 1);
        CHECK_GL_ERROR();
    }

    glUniform1f(_uniIntensity, _intensity);
    CHECK_GL_ERROR();
    ptrVAO->draw(_atrPosition, -1, _atrTexcoord);
}

void GLColorLookupFilter::prepareGLProgramSlots(GLint program) {
    _uniIntensity = glGetUniformLocation(program, "u_intensity");
    _uniLookupTexture = glGetUniformLocation(program, "u_lookupTexture");
    _uniTexture = glGetUniformLocation(program, "u_texture");
    _atrPosition = glGetAttribLocation(program, "a_position");
    _atrTexcoord = glGetAttribLocation(program, "a_texcoord");
}

void GLColorLookupFilter::releaseGLObjects() {
    ALOGV("GLColorLookupFilter::releaseGLObjects");
    GLuint textures[] = {(GLuint)_lookupTexture};
    glDeleteTextures(1, textures);
    _lookupTexture = -1;

    GLFilter::releaseGLObjects();
}
