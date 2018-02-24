//
//  GLBilateralFilter.cpp
//  Madv360_v1
//
//  Created by FutureBoy on 7/16/16.
//  Copyright © 2016 Cyllenge. All rights reserved.
//

#include "GLBilateralFilter.h"
#include "../gles3.h"
#include "../gles3ext.h"
#include <math.h>

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
 
 uniform float u_gaussianFactors[49];
 uniform float u_similaritySigma;
 uniform float u_expLUT[128];
 
 float similarityFactor(vec4 color0, vec4 color1, highp float sigma) {
     highp float dist2 = distance(color0, color1);
     dist2 = dist2 * dist2;
//     return exp(- dist2 / 2.0 / sigma / sigma);
     int idx = int(dist2 / 3.0 * 128.0);
     if (idx == 128)
         return u_expLUT[127];
     else
         return u_expLUT[idx];

//        const float distanceNormalizationFactor = 10.0;
//        float f = 1.0  - min(distance(color0, color1) * distanceNormalizationFactor, 0.99);
//        return f * f;

//        return 1.0;
 }
 
 void main(void) {
     const float texcoordDistanceStrength = 5.0;
     
     vec4 centerColor = texture2D(u_texture, v_texcoord);
     vec2 texcoordOffset = u_srcSize / u_dstSize * texcoordDistanceStrength;
     lowp vec4 sum = vec4(0.0,0.0,0.0,0.0);
     lowp float factorSum = 0.0;
     lowp float factor;
     lowp vec4 texels[49];
     
     int idx = 0;
     for (int ds=-3; ds<=3; ds++)
     {
         for (int dt=-3; dt<=3; dt++)
         {
             vec2 dTexcoord = vec2(float(ds), float(dt));
             texels[idx] = texture2D(u_texture, v_texcoord + texcoordOffset * dTexcoord);
             factor = u_gaussianFactors[idx] * similarityFactor(centerColor, texels[idx], u_similaritySigma);
             factorSum += factor;
             sum += texels[idx] * factor;
             
             idx++;
         }
     }
     
     gl_FragColor = sum / factorSum;//vec4(1.0 - color.rgb, color.a);
 }
 
 );

GLBilateralFilter::~GLBilateralFilter() {
    if (_gaussianFactors)
        delete[] _gaussianFactors;

    if (_expLUT)
        delete[] _expLUT;
}

GLBilateralFilter::GLBilateralFilter()
: GLFilter(&VertexShaderSource, 1, &FragmentShaderSource, 1)
, _expLUT(NULL)
, _gaussianFactors(NULL)
{

}

float* PascalCoefficiants(int size) {
    float* results = new float[size * size];
    int** coeffs = new int*[2];
    coeffs[0] = new int[size];
    coeffs[1] = new int[size];
    // 1 2 1
    // 2 4 2
    // 1 2 1
    coeffs[0][0] = 1;
    for (int i=1; i<size; ++i) coeffs[0][i] = 0;
//    printf("\nPascal Triangles (1~%d):\n", size);
    int iRead = 0;
    for (int i=1; i<size; ++i)
    {
//        printf("Row#%d : ", i);
        for (int j=0; j<=i; ++j)
        {
            coeffs[1-iRead][j] = 0;
            if (j-1 >= 0)
                coeffs[1-iRead][j] += coeffs[iRead][j-1];
            if (j < i)
                coeffs[1-iRead][j] += coeffs[iRead][j];
            
//            printf("%d  ", coeffs[1-iRead][j]);
        }
//        printf("\n");
        iRead = 1 - iRead;
    }
    
    int sum = 0;
    float* pDst = results;
    for (int iR=0; iR<size; ++iR)
    {
        for (int iC=0; iC<size; ++iC)
        {
            *pDst = coeffs[iRead][iC] * coeffs[iRead][iR];
            sum += (int) (*pDst);
            pDst++;
        }
    }
    
    pDst = results;
    for (int i=size*size; i>0; --i)
    {
        *pDst = (*pDst / (float)sum);
    }
    
    delete[] coeffs[0];
    delete[] coeffs[1];
    delete[] coeffs;
    
    return results;
}

float* Coefficiants2DFrom1D(float* coeffs1D, int size) {
    float* coeffs2D = new float[size * size];
    float sum = 0;
    float* pDst = coeffs2D;
    for (int iR=0; iR<size; ++iR)
    {
        for (int iC=0; iC<size; ++iC)
        {
            *pDst = coeffs1D[iC] * coeffs1D[iR];
            sum += *pDst;
            pDst++;
        }
    }

    pDst = coeffs2D;
    for (int i=size*size; i>0; --i)
    {
        *pDst = (*pDst / (float)sum);
    }
    
    return coeffs2D;
}

void GLBilateralFilter::render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget) {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(sourceTextureTarget, sourceTexture);
    glUniform1i(_uniTexture, 0);
    
    Vec2f destSize = getDestRectSize();
    glUniform2f(_uniDstSize, destSize.width, destSize.height);
    
    Vec2f clippedTextureSize = getClippedTexcoordSize();
    glUniform2f(_uniSrcSize, clippedTextureSize.width, clippedTextureSize.height);

    if (NULL == _gaussianFactors)
    {
//        _gaussianFactors[] = {1.f/16.f, 2.f/16.f, 1.f/16.f, 2.f/16.f, 4.f/16.f, 2.f/16.f, 1.f/16.f, 2.f/16.f, 1.f/16.f};
//        float factors1D[] = {.05, .09, .12, .15, .18, .15, .12, .09, .05};
//        _gaussianFactors = Coefficiants2DFrom1D(&factors1D[0], 9);
        _gaussianFactors = PascalCoefficiants(7);
    }
    glUniform1fv(_uniGaussianFactors, 49, _gaussianFactors);
    
    const float similaritySigma = 0.03f;
    glUniform1f(_uniSimilaritySigma, similaritySigma);

    GLint maxComponents;
    glGetIntegerv(GL_MAX_VERTEX_UNIFORM_COMPONENTS, &maxComponents);
    maxComponents = 128;
    if (NULL == _expLUT)
    {
        _expLUT = new float[maxComponents];
        for (int i=0; i<maxComponents; ++i)
        {
            float dist2 = 3.f * ((float)i + 0.5f) / (float)maxComponents;
            _expLUT[i] = exp(-dist2 / 2.f / similaritySigma / similaritySigma);
        }
    }
    glUniform1fv(_uniExpLUT, maxComponents, _expLUT);
//    ALOGE("maxComponents = %d, getDestRectSize() = (%f,%f), getClippedTexcoordSize() = (%f,%f)", maxComponents, destSize.width, destSize.height, clippedTextureSize.width, clippedTextureSize.height);

    ptrVAO->draw(_atrPosition, -1, _atrTexcoord);
    CHECK_GL_ERROR();
}

void GLBilateralFilter::prepareGLProgramSlots(GLint program) {
    _uniTexture = glGetUniformLocation(program, "u_texture");
    _uniDstSize = glGetUniformLocation(program, "u_dstSize");
    _uniSrcSize = glGetUniformLocation(program, "u_srcSize");
    _atrPosition = glGetAttribLocation(program, "a_position");
    _atrTexcoord = glGetAttribLocation(program, "a_texcoord");
    
    _uniGaussianFactors = glGetUniformLocation(program, "u_gaussianFactors");
    _uniSimilaritySigma = glGetUniformLocation(program, "u_similaritySigma");
    _uniExpLUT = glGetUniformLocation(program, "u_expLUT");
}
