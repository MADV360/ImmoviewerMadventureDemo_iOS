//
//  OpenGLHelper.c
//  Madv360
//
//  Created by FutureBoy on 11/5/15.
//  Copyright © 2015 Cyllenge. All rights reserved.
//

#include "OpenGLHelper.h"
#include "AutoRef.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "vec3.h"

unsigned long nextPOT(unsigned long x)
{
    x = x - 1;
    x = x | (x >> 1);
    x = x | (x >> 2);
    x = x | (x >> 4);
    x = x | (x >> 8);
    x = x | (x >>16);
    return x + 1;
}

int ComponentsOfColorSpace(GLenum colorspace) {
    switch (colorspace)
    {
        case GL_RGB:
            return 3;
        case GL_RGBA:
            return 4;
        case GL_DEPTH_COMPONENT:
        case GL_ALPHA:
        case GL_LUMINANCE:
            return 1;
        case GL_LUMINANCE_ALPHA:
            return 2;
        default:
            return 4;
    }
}

int BytesOfBitFormat(GLenum bitformat) {
    switch (bitformat)
    {
        case GL_UNSIGNED_BYTE:
            return 1;
        case GL_FLOAT:
        case GL_SHORT:
        case GL_UNSIGNED_SHORT:
        case GL_UNSIGNED_SHORT_4_4_4_4:
        case GL_UNSIGNED_SHORT_5_6_5:
        case GL_UNSIGNED_SHORT_5_5_5_1:
        case GL_UNSIGNED_SHORT_8_8_APPLE:
        case GL_UNSIGNED_SHORT_8_8_REV_APPLE:
            return 2;
        default:
            return 0;
    }
}

kmMat3* transformMatrix3InNormalizedCoordSystem2D(kmMat3* mat, Vec2f viewportOrigin, Vec2f viewportSize, Vec2f boundOrigin, Vec2f boundSize, Orientation2D orientation) {
    transformMatrixInNormalizedCoordSystem2D(mat->mat, 3, viewportOrigin, viewportSize, boundOrigin, boundSize, orientation);
    return mat;
}

kmMat4* transformMatrix4InNormalizedCoordSystem2D(kmMat4* mat, Vec2f viewportOrigin, Vec2f viewportSize, Vec2f boundOrigin, Vec2f boundSize, Orientation2D orientation) {
    transformMatrixInNormalizedCoordSystem2D(mat->mat, 4, viewportOrigin, viewportSize, boundOrigin, boundSize, orientation);
    return mat;
}

float* transformMatrixInNormalizedCoordSystem2D(float* matrix, int rank, Vec2f viewportOrigin, Vec2f viewportSize, Vec2f boundOrigin, Vec2f boundSize, Orientation2D orientation) {
    float kx = boundSize.width / viewportSize.width;
    float cx = (2.f * (boundOrigin.x - viewportOrigin.x) + boundSize.width) / viewportSize.width - 1.f;
    float ky = boundSize.height / viewportSize.height;
    float cy = (2.f * (boundOrigin.y - viewportOrigin.y) + boundSize.height) / viewportSize.height - 1.f;

    for (int i=rank*rank-1; i>=0; --i) matrix[i] = 0.f;
    for (int i=0; i<rank; ++i) matrix[i * rank + i] = 1.f;

    switch (orientation)
    {
        case OrientationNormal:
            matrix[0] = kx;
            matrix[rank+1] = ky;
            matrix[(rank-1) * rank] = cx;
            matrix[(rank-1) * rank + 1] = cy;
            break;
        case OrientationMirror:
            matrix[0] = -kx;
            matrix[rank+1] = ky;
            matrix[(rank-1) * rank] = cx;
            matrix[(rank-1) * rank + 1] = cy;
            break;
        case OrientationRotate180Degree:
            matrix[0] = -kx;
            matrix[1] = 0;
            matrix[rank] = 0;
            matrix[rank+1] = -ky;
            matrix[(rank-1) * rank] = cx;
            matrix[(rank-1) * rank + 1] = cy;
            break;
        case OrientationRotate180DegreeMirror:
            matrix[0] = kx;
            matrix[1] = 0;
            matrix[rank] = 0;
            matrix[rank+1] = -ky;
            matrix[(rank-1) * rank] = cx;
            matrix[(rank-1) * rank + 1] = cy;
            break;
        case OrientationRotateRight:
            matrix[0] = 0;
            matrix[1] = -ky;
            matrix[rank] = kx;
            matrix[rank+1] = 0;
            matrix[(rank-1) * rank] = cx;
            matrix[(rank-1) * rank + 1] = cy;
            break;
        case OrientationRotateRightMirror:
            matrix[0] = 0;
            matrix[1] = -ky;
            matrix[rank] = -kx;
            matrix[rank+1] = 0;
            matrix[(rank-1) * rank] = cx;
            matrix[(rank-1) * rank + 1] = cy;
            break;
        case OrientationRotateLeftMirror:
            matrix[0] = 0;
            matrix[1] = ky;
            matrix[rank] = kx;
            matrix[rank+1] = 0;
            matrix[(rank-1) * rank] = cx;
            matrix[(rank-1) * rank + 1] = cy;
            break;
        case OrientationRotateLeft:
            matrix[0] = 0;
            matrix[1] = ky;
            matrix[rank] = -kx;
            matrix[rank+1] = 0;
            matrix[(rank-1) * rank] = cx;
            matrix[(rank-1) * rank + 1] = cy;
            break;
        default:
            matrix[0] = kx;
            matrix[(rank-1) * rank] = cx;
            matrix[rank+1] = ky;
            matrix[(rank-1) * rank + 1] = cy;
            break;
    }
    return matrix;
}

GLint compileShader(const GLchar* const* shaderSources, int sourcesCount, GLenum type) {
    GLint shader = glCreateShader(type);
    glShaderSource(shader, sourcesCount, shaderSources, NULL);
    glCompileShader(shader);
    
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[1024];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        ALOGE("ShaderType=%d : %s\nSource(s):\n", type, messages);
        for (int i=0; i<sourcesCount; ++i)
        {
            ALOGE("%s\n", shaderSources[i]);
        }
        ///!!!exit(1);
    }
    
    return shader;
}

GLint compileAndLinkShaderProgram(const GLchar* const* vertexSources, int vertexSourcesCount,
                                  const GLchar* const* fragmentSources, int fragmentSourcesCount) {
    return compileAndLinkShaderProgramWithShaderPointers(vertexSources, vertexSourcesCount, fragmentSources, fragmentSourcesCount, NULL,NULL);
}

GLint compileAndLinkShaderProgramWithShaderPointers(const GLchar* const* vertexSources, int vertexSourcesCount,
                                                    const GLchar* const* fragmentSources, int fragmentSourcesCount,
                                                    GLint* pVertexShader, GLint* pFragmentShader) {
    GLint vertexShader, fragmentShader;
    if (!pVertexShader)
    {
        pVertexShader = &vertexShader;
    }
    if (!pFragmentShader)
    {
        pFragmentShader = &fragmentShader;
    }
    *pVertexShader = vertexShader = compileShader(vertexSources, vertexSourcesCount, GL_VERTEX_SHADER);
    *pFragmentShader = fragmentShader = compileShader(fragmentSources, fragmentSourcesCount, GL_FRAGMENT_SHADER);
    
    GLint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[1024];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        ALOGE("%s\n", messages);
        ///!!!exit(1);
    }
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return program;
}

void createOrUpdateTexture(GLuint* pTextureID, GLint width, GLint height, GLubyte** pTextureData, GLsizei* pTextureDataSize, void(*dataSetter)(GLubyte* data, GLint pow2Width, GLint pow2Height, void* userData), void* userData)
{
    GLsizei pow2Width = (GLsizei) width;///nextPOT(width);
    GLsizei pow2Height = (GLsizei) height;///nextPOT(height);
    
    GLubyte* textureData = NULL;
    if (NULL == pTextureData)
    {
        pTextureData = &textureData;
    }
    GLsizei textureDataSize = 0;
    if (NULL == pTextureDataSize)
    {
        pTextureDataSize = &textureDataSize;
    }
    
    if (0 == *pTextureID)
    {
        glGenTextures(1, pTextureID);
    }
    glBindTexture(GL_TEXTURE_2D, *pTextureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST//GL_LINEAR_MIPMAP_LINEAR
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
    
    bool isOwnerOfData = true;
    if (NULL == *pTextureData)
    {
        *pTextureDataSize = pow2Width * pow2Height * 4;
        *pTextureData = (GLubyte*) malloc(*pTextureDataSize);
    }
    else if (*pTextureDataSize < pow2Height * pow2Width * 4)
    {
        free(*pTextureData);
        *pTextureDataSize = pow2Width * pow2Height * 4;
        *pTextureData = (GLubyte*) malloc(*pTextureDataSize);
    }
    else
    {
        isOwnerOfData = false;
    }
    
    if (dataSetter)
    {
        dataSetter(*pTextureData, pow2Width, pow2Height, userData);
    }
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)pow2Width, (GLsizei)pow2Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, *pTextureData);
    
    if (isOwnerOfData)
    {
        free(*pTextureData);
    }
//    glGenerateMipmap(GL_TEXTURE_2D);
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

P4C4T2f P4C4T2fMake(GLfloat x, GLfloat y, GLfloat z, GLfloat w, GLfloat r, GLfloat g, GLfloat b, GLfloat a, GLfloat s, GLfloat t) {
    P4C4T2f ret = {x,y,z,w, r,g,b,a, s,t};
    return ret;
}
