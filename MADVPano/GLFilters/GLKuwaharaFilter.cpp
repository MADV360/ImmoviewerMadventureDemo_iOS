//
//  GLKuwaharaFilter.cpp
//  Madv360_v1
//
//  Created by FutureBoy on 7/20/16.
//  Copyright © 2016 Cyllenge. All rights reserved.
//

#include "GLKuwaharaFilter.h"

static const char* VertexShaderSource = STRINGIZE
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;

        uniform mat4 u_screenMatrix;
        uniform vec2 u_texcoordOrigin;
        uniform vec2 u_texcoordSize;

 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = u_screenMatrix * (position / position.w);
//     textureCoordinate = inputTextureCoordinate.xy;
     textureCoordinate = inputTextureCoordinate.xy * u_texcoordSize + u_texcoordOrigin;
 }
 );

static const char* FragmentShaderSource = STRINGIZE2
(
 varying highp vec2 textureCoordinate; \n
        \n
        STRINGIZE0(#ifdef EXTERNAL) \n
        STRINGIZE0(#define sourceSampler2D samplerExternalOES) \n
        STRINGIZE0(#else) \n
        STRINGIZE0(#define sourceSampler2D sampler2D) \n
        STRINGIZE0(#endif) \n
        uniform sourceSampler2D inputImageTexture;

 uniform int radius;
 
 const vec2 src_size = vec2 (1.0 / 768.0, 1.0 / 1024.0);
 
 void main ()
 {
     vec2 uv = textureCoordinate;
     float n = float((radius + 1) * (radius + 1));
     int i; int j;
     vec3 m0 = vec3(0.0); vec3 m1 = vec3(0.0); vec3 m2 = vec3(0.0); vec3 m3 = vec3(0.0);
     vec3 s0 = vec3(0.0); vec3 s1 = vec3(0.0); vec3 s2 = vec3(0.0); vec3 s3 = vec3(0.0);
     vec3 c;
     
     for (j = -radius; j <= 0; ++j)  {
         for (i = -radius; i <= 0; ++i)  {
             c = texture2D(inputImageTexture, uv + vec2(i,j) * src_size).rgb;
             m0 += c;
             s0 += c * c;
         }
     }
     
     for (j = -radius; j <= 0; ++j)  {
         for (i = 0; i <= radius; ++i)  {
             c = texture2D(inputImageTexture, uv + vec2(i,j) * src_size).rgb;
             m1 += c;
             s1 += c * c;
         }
     }
     
     for (j = 0; j <= radius; ++j)  {
         for (i = 0; i <= radius; ++i)  {
             c = texture2D(inputImageTexture, uv + vec2(i,j) * src_size).rgb;
             m2 += c;
             s2 += c * c;
         }
     }
     
     for (j = 0; j <= radius; ++j)  {
         for (i = -radius; i <= 0; ++i)  {
             c = texture2D(inputImageTexture, uv + vec2(i,j) * src_size).rgb;
             m3 += c;
             s3 += c * c;
         }
     }
     
     
     float min_sigma2 = 1e+2;
     m0 /= n;
     s0 = abs(s0 / n - m0 * m0);
     
     float sigma2 = s0.r + s0.g + s0.b;
     if (sigma2 < min_sigma2) {
         min_sigma2 = sigma2;
         gl_FragColor = vec4(m0, 1.0);
     }
     
     m1 /= n;
     s1 = abs(s1 / n - m1 * m1);
     
     sigma2 = s1.r + s1.g + s1.b;
     if (sigma2 < min_sigma2) {
         min_sigma2 = sigma2;
         gl_FragColor = vec4(m1, 1.0);
     }
     
     m2 /= n;
     s2 = abs(s2 / n - m2 * m2);
     
     sigma2 = s2.r + s2.g + s2.b;
     if (sigma2 < min_sigma2) {
         min_sigma2 = sigma2;
         gl_FragColor = vec4(m2, 1.0);
     }
     
     m3 /= n;
     s3 = abs(s3 / n - m3 * m3);
     
     sigma2 = s3.r + s3.g + s3.b;
     if (sigma2 < min_sigma2) {
         min_sigma2 = sigma2;
         gl_FragColor = vec4(m3, 1.0);
     }
 }
);

GLKuwaharaFilter::GLKuwaharaFilter()
        : GLFilter(&VertexShaderSource, 1, &FragmentShaderSource, 1)
{

}

void GLKuwaharaFilter::render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget) {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(sourceTextureTarget, sourceTexture);
    glUniform1i(_uniTexture, 0);
    
    glUniform1i(_uniRadius, 3);
    
    ptrVAO->draw(_atrPosition, -1, _atrTexcoord);
}

void GLKuwaharaFilter::prepareGLProgramSlots(GLint program) {
    _uniTexture = glGetUniformLocation(program, "inputImageTexture");
    _uniRadius = glGetUniformLocation(program, "radius");
    _atrPosition = glGetAttribLocation(program, "position");
    _atrTexcoord = glGetAttribLocation(program, "inputTextureCoordinate");
}

