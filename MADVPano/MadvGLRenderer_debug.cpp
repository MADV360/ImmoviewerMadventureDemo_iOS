//
//  MadvGLRenderer_debug.mm
//  Madv360_v1
//
//  Created by QiuDong on 16/2/26.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//
#if defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0

#include "MadvGLRenderer_debug.h"
#include "gles2.h"
#include "gles2ext.h"
#include "gles3.h"
#include "gles3ext.h"
#include "Log.h"
#include "PNGUtils.h"
#include <fstream>

using namespace std;

#define STRINGIZE0(...) __VA_ARGS__
#define STRINGIZE(...) #__VA_ARGS__
#define STRINGIZE2(...) STRINGIZE(__VA_ARGS__)

/*
 * Beta = Longitude = 2*PI * s;
 * Alpha = Latitude = PI - PI * t;
 *
 * x = -sinA * sinB;
 * y = cosA;
 * z = sinA * cosB;
 *
 * Alpha = arccos(y);
 * float x1, z1;
 * if (abs(x) <= abs(z))
 *     x1 = x;
 *     z1 = z;
 * else
 *     x1 = z;
 *     z1 = x;
 *
 * Beta = arctan(-x1 / z1);
 * if (z1 < 0)
 *     Beta += PI;
 * else if (x1 > 0)
 *     Beta += 2*PI;
 *
 * if (abs(x) > abs(z))
 *     Beta = 5*PI/2 - Beta;
 *     if (Beta > 2*PI)
 *         Beta -= 2*PI;
 */
static const char* VertexShaderSource = STRINGIZE2
(
 attribute vec4 a_position;
 attribute vec2 a_vertexIndex; \n
 //attribute vec2 a_texCoord; \n
 uniform int u_columns; \n
 uniform int u_rows; \n
 uniform mat4 u_SPCMMatrix;
        /// Samsum S8 issue is fixed by changing highp v_texCoord to mediump
 varying mediump vec2 v_texCoord; \n
 \n
 STRINGIZE0(#if defined(FLAG_STITCH_WITH_LUT_IN_SHADER)) \n
 uniform sampler2D u_lutTextureLS; \n
 uniform sampler2D u_lutTextureLT; \n
 uniform sampler2D u_lutTextureRS; \n
 uniform sampler2D u_lutTextureRT; \n
 uniform highp vec2 u_lutSrcSize; \n
 varying highp vec2 v_texcoordL; \n
 varying highp vec2 v_texcoordR; \n
// varying highp vec2 v_lutWeights; \n
 highp float lutTexcoordComponentOfTexel(vec4 texel, float denom) { \n
     highp float I = texel.r * 65536.0 + texel.g * 256.0;
     highp float M = texel.b;
     return (I + M) / 4.0 / denom;
 } \n
 highp vec4 lutTexcoordOfTexcoord(highp vec2 texcoord) { \n
     highp vec4 ret; \n
     vec4 lsTexel = texture2D(u_lutTextureLS, texcoord); \n
     ret.r = lutTexcoordComponentOfTexel(lsTexel, u_lutSrcSize.x); \n
     vec4 ltTexel = texture2D(u_lutTextureLT, texcoord); \n
     ret.g = lutTexcoordComponentOfTexel(ltTexel, u_lutSrcSize.y); \n
     vec4 rsTexel = texture2D(u_lutTextureRS, texcoord); \n
     ret.b = lutTexcoordComponentOfTexel(rsTexel, u_lutSrcSize.x); \n
     vec4 rtTexel = texture2D(u_lutTextureRT, texcoord); \n
     ret.a = lutTexcoordComponentOfTexel(rtTexel, u_lutSrcSize.y); \n
     return ret; \n
 } \n
 \n
 STRINGIZE0(#endif) \n
 \n
 highp vec2 texcoordFromVertexIndex(vec2 vertexIndex) {
     return vertexIndex / vec2(float(u_columns), float(u_rows));
 }
 \n
 void main(void) { \n
     gl_Position = u_SPCMMatrix * a_position; \n
     highp vec2 dstTexcoord = texcoordFromVertexIndex(a_vertexIndex); \n
     \n
STRINGIZE0(#if defined(FLAG_STITCH_WITH_LUT)) \n
     highp vec4 lutTexel = lutTexcoordOfTexcoord(vec2(dstTexcoord.s, 1.0 - dstTexcoord.t));
     v_texcoordL = vec2(lutTexel.r, 1.0 - lutTexel.g);
     v_texcoordR = vec2(lutTexel.b, 1.0 - lutTexel.a); \n
//     v_lutWeights = lutWeights(dstTexcoord); \n
STRINGIZE0(#endif) \n
     v_texCoord = dstTexcoord;
 }
 );

///Ref: http://blog.csdn.net/opengl_es/article/details/17787495
static const char* FragmentShaderSource = STRINGIZE2
(
 STRINGIZE0(#ifdef EXTERNAL) \n
 STRINGIZE0(#extension GL_)STRINGIZE0(OES_EGL_image_external) : require \n
 STRINGIZE0(#endif) \n
 precision highp float;
 
 varying vec2 v_texCoord;
 \n
 STRINGIZE0(#ifdef FLAG_REFLATTENING_IN_PIXEL) \n
 uniform highp mat4 u_CMMatrix; \n
 STRINGIZE0(#endif) \n
 \n
 STRINGIZE0(#ifdef FLAG_STITCH_WITH_LUT) \n
 STRINGIZE0(#ifdef FLAG_REFLATTENING_IN_PIXEL) \n
 uniform sampler2D u_lutTextureLS; \n
 uniform sampler2D u_lutTextureLT; \n
 uniform sampler2D u_lutTextureRS; \n
 uniform sampler2D u_lutTextureRT; \n
 uniform highp vec2 u_lutSrcSize; \n
 STRINGIZE0(#else) \n
 varying highp vec2 v_texcoordL; \n
 varying highp vec2 v_texcoordR; \n
// varying highp vec2 v_lutWeights; \n
 STRINGIZE0(#endif) \n
 STRINGIZE0(#endif) \n
 \n
 uniform highp vec2 u_dstSize;
 uniform highp vec2 u_srcSizeL;
 uniform highp vec2 u_srcSizeR;
 uniform mat4 u_textureMatrix;

 \n
 STRINGIZE0(#ifdef FLAG_STITCH_WITH_LUT) \n
 STRINGIZE0(#ifdef FLAG_REFLATTENING_IN_PIXEL) \n
 highp float lutTexcoordComponentOfTexel(vec4 texel, float denom) { \n
     highp float I = texel.r * 65536.0 + texel.g * 256.0;
     highp float M = texel.b;
     return (I + M) / 4.0 / denom;
 } \n
 highp vec4 lutTexcoordOfTexcoord(highp vec2 texcoord) { \n
     highp vec4 ret; \n
     vec4 lsTexel = texture2D(u_lutTextureLS, texcoord); \n
     ret.r = lutTexcoordComponentOfTexel(lsTexel, u_lutSrcSize.x); \n
     vec4 ltTexel = texture2D(u_lutTextureLT, texcoord); \n
     ret.g = lutTexcoordComponentOfTexel(ltTexel, u_lutSrcSize.y); \n
     vec4 rsTexel = texture2D(u_lutTextureRS, texcoord); \n
     ret.b = lutTexcoordComponentOfTexel(rsTexel, u_lutSrcSize.x); \n
     vec4 rtTexel = texture2D(u_lutTextureRT, texcoord); \n
     ret.a = lutTexcoordComponentOfTexel(rtTexel, u_lutSrcSize.y); \n
     return ret; \n
 } \n
 STRINGIZE0(#endif) \n
 STRINGIZE0(#endif) \n
 
 const float PI = 3.141592653589793;
 
 highp vec2 texcoordWrapped(highp vec2 texcoord) {
//     vec2 ret = sin(texcoord * PI * 2.0) / 2.0 + vec2(0.5, 0.5);
     vec2 ret = texcoord / 2.0;
     /*
     if (ret.s < 0.0)
         ret.s += 1.0;
     else if (ret.s > 1.0)
         ret.s -= 1.0;
     if (ret.t < 0.0)
         ret.t += 1.0;
     else if (ret.t > 1.0)
         ret.t -= 1.0;
     //*/
     return ret;
 }

 \n
 STRINGIZE0(#if defined(FLAG_STITCH_WITH_LUT) || defined(FLAG_REFLATTENING_IN_PIXEL)) \n
 highp vec2 sphereCoordFromVector3(highp vec3 point) {
     highp vec3 normalized = normalize(point);
     highp float alpha = acos(normalized.y);
     highp float beta = atan(-point.x, point.z);
     if (beta < 0.0) beta = 2.0 * M_PI + beta;
     return vec2(beta, alpha);
 }
 
 highp vec3 normalizedVec3FromSphereCoord(highp vec2 sphereCoord) {
     highp float sinA = sin(sphereCoord.y);
     highp float sinB = sin(sphereCoord.x);
     highp float cosA = cos(sphereCoord.y);
     highp float cosB = cos(sphereCoord.x);
     return vec3(-sinA * sinB, cosA, sinA * cosB);
 }
 
 highp vec2 sphereCoordFromTexCoord(highp vec2 texCoord) {
     return vec2(2.0 * M_PI * texCoord.s, M_PI * (1.0 - texCoord.t));
 }
 
 highp vec2 texCoordFromSphereCoord(highp vec2 sphereCoord) {
     return vec2(sphereCoord.s / 2.0 / M_PI, 1.0 - sphereCoord.t / M_PI);
 }
 
 highp vec2 transformTexcoordInSphere(highp vec2 texcoord, highp mat4 transformMatrix) {
     const highp float EPSILON = 0.0001;
     highp vec3 texcoordVector3 = normalizedVec3FromSphereCoord(sphereCoordFromTexCoord(texcoord));
     highp vec4 texcoordVector = transformMatrix * vec4(texcoordVector3, 1.0);
     highp vec2 retA = texCoordFromSphereCoord(sphereCoordFromVector3(texcoordVector.xyz));
     /*
     if (abs(texcoordVector.x) <= EPSILON && abs(texcoordVector.z) <= EPSILON)
     {
         texcoordVector3 = normalizedVec3FromSphereCoord(sphereCoordFromTexCoord(vec2(texcoord.s, 0.5)));
         texcoordVector = transformMatrix * vec4(texcoordVector3, 1.0);
         highp vec2 retB = texCoordFromSphereCoord(sphereCoordFromVector3(texcoordVector.xyz));
         retA.s = retB.s;
     }
    //*/
     return retA;
 } \n

 mediump vec2 lutWeights(mediump vec2 dstTexCoord) {
        mediump float weight = 1.0;
        mediump float weight1 = 0.0;
     
     const highp float PI_div_2 = M_PI / 2.0;
     const highp float theta0 = PI_div_2 - M_PI / 60.0;
     const highp float theta1 = PI_div_2 + M_PI / 60.0;
     const highp float theta2 = PI_div_2 * 3.0 - M_PI / 60.0;
     const highp float theta3 = PI_div_2 * 3.0 + M_PI / 60.0;
     
     highp vec2 dstSphereCoord = sphereCoordFromTexCoord(dstTexCoord);
     highp vec3 dstNormalizedVec = normalizedVec3FromSphereCoord(dstSphereCoord);
     dstNormalizedVec.x = sign(dstNormalizedVec.x) * sqrt(dstNormalizedVec.x * dstNormalizedVec.x + dstNormalizedVec.y * dstNormalizedVec.y);
     dstNormalizedVec.y = 0.0;
     dstSphereCoord = sphereCoordFromVector3(dstNormalizedVec);
     if (dstSphereCoord.s < theta0)
     {
         weight = 1.0;
         weight1 = 0.0;
     }
     else if (dstSphereCoord.s < theta1)
     {
         weight = (theta1 - dstSphereCoord.s) / (theta1 - theta0);
         weight1 = 1.0 - weight;
     }
     else if (dstSphereCoord.s < theta2)
     {
         weight = 0.0;
         weight1 = 1.0;
     }
     else if (dstSphereCoord.s < theta3)
     {
         weight1 = (theta3 - dstSphereCoord.s) / (theta3 - theta2);
         weight = 1.0 - weight1;
     }
     else
     {
         weight = 1.0;
         weight1 = 0.0;
     }
     
     return vec2(weight, weight1);
     //return vec2(0.5, 0.5);
 } \n
 STRINGIZE0(#endif) \n
      \n
 vec3 YUVTexel2RGB(vec3 yuvTexel) {
     float y = yuvTexel.r;
     float u = yuvTexel.g - 0.5;
     float v = yuvTexel.b - 0.5;
     vec3 rgb;
     rgb.r = y +             1.402 * v;
     rgb.g = y - 0.344 * u - 0.714 * v;
     rgb.b = y + 1.772 * u;
     return rgb;
 }

 vec2 transformedTexcoord(vec2 texCoord) {
      vec2 ret = (u_textureMatrix * vec4(texCoord, 0.0, 1.0)).st;
      return vec2(ret.s, ret.t);
 }
 
 vec4 color4OfTexCoord(vec2 dstTexCoord) { \n
 STRINGIZE0(#ifdef FLAG_PLAIN_STITCH) \n
     {
         highp vec2 srcTexcoord;
         float H = (u_srcSizeL.y > u_srcSizeR.y ? u_srcSizeL.y : u_srcSizeR.y);
         if (dstTexCoord.s <= u_srcSizeL.x / (u_srcSizeL.x + u_srcSizeR.x))
         {
             srcTexcoord.s = dstTexCoord.s * (u_srcSizeL.x + u_srcSizeR.x) / u_srcSizeL.x;
             srcTexcoord.t = dstTexCoord.t * H / u_srcSizeL.y; \n
             STRINGIZE0(#ifdef FLAG_YUV_COLORSPACE) \n
                 return vec4(texcoordWrapped(transformedTexcoord(srcTexcoord)), 0.0, 1.0); \n
             STRINGIZE0(#else) \n
                 return vec4(texcoordWrapped(transformedTexcoord(srcTexcoord)), 0.0, 1.0); \n
             STRINGIZE0(#endif) \n
         }
         else
         {
             srcTexcoord.s = (dstTexCoord.s - u_srcSizeL.x / (u_srcSizeL.x + u_srcSizeR.x)) * (u_srcSizeL.x + u_srcSizeR.x) / u_srcSizeR.x;
             srcTexcoord.t = dstTexCoord.t * H / u_srcSizeR.y; \n
             STRINGIZE0(#ifdef FLAG_YUV_COLORSPACE) \n
                 return vec4(texcoordWrapped(transformedTexcoord(srcTexcoord)), 0.0, 1.0); \n
             STRINGIZE0(#else) \n
                 return vec4(texcoordWrapped(transformedTexcoord(srcTexcoord)), 0.0, 1.0); \n
             STRINGIZE0(#endif) \n
         }
     } \n
 STRINGIZE0(#elif defined(FLAG_STITCH_WITH_LUT)) \n
     {
         vec4 lTexel;
         vec4 rTexel; \n
         STRINGIZE0(#ifdef FLAG_REFLATTENING_IN_PIXEL) \n
         highp vec4 lutTexel = lutTexcoordOfTexcoord(vec2(dstTexCoord.s, 1.0 - dstTexCoord.t));
         //highp vec4 lutTexel = vec4(dstTexCoord, dstTexCoord);///!!!For Debug#BURR#
         highp vec2 texcoordL = vec2(lutTexel.r, 1.0 - lutTexel.g);
         highp vec2 texcoordR = vec2(lutTexel.b, 1.0 - lutTexel.a); \n
         STRINGIZE0(#else) \n
         highp vec2 texcoordL = v_texcoordL;
         highp vec2 texcoordR = v_texcoordR; \n
         STRINGIZE0(#endif) \n
        \n
        STRINGIZE0(#ifndef FLAG_YUV_COLORSPACE) \n
         {
            vec2 leftTexcoord = transformedTexcoord(texcoordL);
            lTexel = vec4(texcoordWrapped(leftTexcoord), 0.0, 1.0);
\n
            vec2 rightTexcoord = transformedTexcoord(texcoordR + vec2(0.5,0.0));
            rTexel = vec4(texcoordWrapped(rightTexcoord), 0.0, 1.0);
//        rTexel = vec4(texcoordR + vec2(0.5,0.0), 0.0, 0.0);
         } \n
        STRINGIZE0(#else) \n
         {
            vec2 leftTexcoord = transformedTexcoord(texcoordL);
            lTexel = vec4(texcoordWrapped(transformedTexcoord(leftTexcoord)), 0.0, 1.0);

            float texelYR, texelUR, texelVR; \n
            {
                vec2 rightTexcoord = transformedTexcoord(texcoordR + vec2(0.5,0.0));
            } \n
            rTexel = vec4(texcoordWrapped(transformedTexcoord(rightTexcoord)), 0.0, 1.0);
         } \n
        STRINGIZE0(#endif) \n
         vec2 weights = lutWeights(dstTexCoord);
         //if (weights.x != 1.0 && weights.x != 0.0)
         //   return vec4(weights.x, weights.y, 0.0, 1.0);
         //else
         return (lTexel * weights.s + rTexel * weights.t).rgba;
     }
\n
 STRINGIZE0(#else) \n
     { \n
         vec2 colorOfTexcoord = texcoordWrapped(transformedTexcoord(dstTexCoord)); \n
         STRINGIZE0(#ifndef FLAG_YUV_COLORSPACE) \n
         return vec4(colorOfTexcoord.s, 0.0, colorOfTexcoord.t, 1.0); \n
         STRINGIZE0(#else) \n
         return vec4(colorOfTexcoord.s, 0.0, colorOfTexcoord.t, 1.0); \n
         STRINGIZE0(#endif) \n
     }
\n
 STRINGIZE0(#endif) \n
 }
 
 void main()
{
        ///!!!For Debug:
//        if (v_texCoord.s < 0.0 || v_texCoord.s > 1.0 || v_texCoord.t < 0.0 || v_texCoord.t > 1.0)
//        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
//        else
    \n
STRINGIZE0(#ifdef FLAG_REFLATTENING_IN_PIXEL) \n
    gl_FragColor = color4OfTexCoord(transformTexcoordInSphere(v_texCoord, u_CMMatrix)); \n
STRINGIZE0(#else) \n
    gl_FragColor = color4OfTexCoord(v_texCoord); \n
STRINGIZE0(#endif) \n
}
 
 );

/// 000:Plain 001:Sphere 010:PlainV1 011:SphereV1 10X:LittlePlanet 11X:LittlePlanetV1
#define FLAG_STITCH_WITH_LUT_IN_SHADER    0x01
#define FLAG_STITCH_WITH_LUT_IN_MESH    0x02
#define FLAG_YUV_COLORSPACE     0x04
//#define FLAG_SEPARATE_SOURCE    0x08
#define FLAG_PLAIN_STITCH       0x10
#define FLAG_REFLATTENING_IN_VERTEX      0x20
#define FLAG_REFLATTENING_IN_PIXEL       0x40
#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
#define FLAG_IMAGE_EXTERNAL     0x80
#endif

#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
#define FLAG_BITS 8
#else
#define FLAG_BITS 7
#endif

MadvGLRendererImpl_debug::~MadvGLRendererImpl_debug() {
}

MadvGLRendererImpl_debug::MadvGLRendererImpl_debug(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments)
: MadvGLRendererImpl(lutPath, leftSrcSize, rightSrcSize, longitudeSegments, latitudeSegments)
{
}

void MadvGLRendererImpl_debug::prepareGLPrograms() {
    int flags = 0;
    int sourcesCount = 1;
#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
    if (_srcTextureTarget != GL_TEXTURE_2D) {
        flags |= FLAG_IMAGE_EXTERNAL;
        sourcesCount++;
    }
#endif
    if (_isYUVColorSpace) {
        flags |= FLAG_YUV_COLORSPACE;
        sourcesCount++;
    }
    if (_currentDisplayMode & PanoramaDisplayModeLUTInShader)
    {
        flags |= FLAG_STITCH_WITH_LUT_IN_SHADER;
        sourcesCount++;
    }
    /*
    if (_separateSourceTexture)
    {
        flags |= FLAG_SEPARATE_SOURCE;
        sourcesCount++;
    }
    //*/
    if (_currentDisplayMode & PanoramaDisplayModePlainStitch)
    {
        flags |= FLAG_PLAIN_STITCH;
        sourcesCount++;
    }
    /*if ((PanoramaDisplayModeExclusiveMask & _currentDisplayMode) == PanoramaDisplayModeReFlatten)
    {
        //flags |= FLAG_REFLATTENING_IN_PIXEL;
        flags |= FLAG_REFLATTENING_IN_VERTEX;
        sourcesCount++;
    }
    else if ((PanoramaDisplayModeExclusiveMask & _currentDisplayMode) == PanoramaDisplayModeReFlattenInPixel)
    {
        flags |= FLAG_REFLATTENING_IN_PIXEL;
        sourcesCount++;
    }//*/

    _currentGLProgram = _glPrograms[flags];
    if (NULL == _currentGLProgram)
    {
        int iSource = 0;
        const GLchar** fragmentShaderSources = (const GLchar**) malloc(sizeof(GLchar*) * sourcesCount);
#ifdef TARGET_OS_ANDROID
        if (flags & FLAG_IMAGE_EXTERNAL)
        {
            fragmentShaderSources[iSource++] = "#define EXTERNAL\n#define FOR_520\n";///!!!#extension GL_OES_EGL_image_external : require\n";
        }
#endif
        if (flags & FLAG_YUV_COLORSPACE)
        {
            fragmentShaderSources[iSource++] = "#define FLAG_YUV_COLORSPACE\n";
        }
        if (flags & FLAG_STITCH_WITH_LUT_IN_SHADER)
        {
            fragmentShaderSources[iSource++] = "#define FLAG_STITCH_WITH_LUT_IN_SHADER\n";
        }
        if (flags & FLAG_STITCH_WITH_LUT_IN_MESH)
        {
            fragmentShaderSources[iSource++] = "#define FLAG_STITCH_WITH_LUT_IN_MESH\n";
        }
        /*
        if (flags & FLAG_SEPARATE_SOURCE)
        {
            fragmentShaderSources[iSource++] = "#define FLAG_SEPARATE_SOURCE\n";
        }
        //*/
        if (flags & FLAG_PLAIN_STITCH)
        {
            fragmentShaderSources[iSource++] = "#define FLAG_PLAIN_STITCH\n";
        }
        if (flags & FLAG_REFLATTENING_IN_VERTEX)
        {
            fragmentShaderSources[iSource++] = "#define FLAG_REFLATTENING_IN_VERTEX\n";
        }
        else if (flags & FLAG_REFLATTENING_IN_PIXEL)
        {
            fragmentShaderSources[iSource++] = "#define FLAG_REFLATTENING_IN_PIXEL\n";
        }
        fragmentShaderSources[iSource++] = FragmentShaderSource;

        iSource = 0;
        const GLchar** vertexShaderSources = (const GLchar**) malloc(sizeof(GLchar*) * sourcesCount);
#ifdef TARGET_OS_ANDROID
        if (flags & FLAG_IMAGE_EXTERNAL)
        {
            vertexShaderSources[iSource++] = "#define EXTERNAL\n#define FOR_520\n";///!!!#extension GL_OES_EGL_image_external : require\n";
        }
#endif
        if (flags & FLAG_YUV_COLORSPACE)
        {
            vertexShaderSources[iSource++] = "#define FLAG_YUV_COLORSPACE\n";
        }
        if (flags & FLAG_STITCH_WITH_LUT_IN_SHADER)
        {
            vertexShaderSources[iSource++] = "#define FLAG_STITCH_WITH_LUT_IN_SHADER\n";
        }
        if (flags & FLAG_STITCH_WITH_LUT_IN_MESH)
        {
            vertexShaderSources[iSource++] = "#define FLAG_STITCH_WITH_LUT_IN_MESH\n";
        }
        /*
        if (flags & FLAG_SEPARATE_SOURCE)
        {
            vertexShaderSources[iSource++] = "#define FLAG_SEPARATE_SOURCE\n";
        }
        //*/
        if (flags & FLAG_PLAIN_STITCH)
        {
            vertexShaderSources[iSource++] = "#define FLAG_PLAIN_STITCH\n";
        }
        if (flags & FLAG_REFLATTENING_IN_VERTEX)
        {
            vertexShaderSources[iSource++] = "#define FLAG_REFLATTENING_IN_VERTEX\n";
        }
        else if (flags & FLAG_REFLATTENING_IN_PIXEL)
        {
            vertexShaderSources[iSource++] = "#define FLAG_REFLATTENING_IN_PIXEL\n";
        }
        vertexShaderSources[iSource++] = VertexShaderSource;
        
        _currentGLProgram = new MadvGLProgram(vertexShaderSources, sourcesCount, fragmentShaderSources, sourcesCount);
        _glPrograms[flags] = _currentGLProgram;

        free(fragmentShaderSources);
        free(vertexShaderSources);
    }
    glUseProgram(_currentGLProgram->getProgram());
}

#endif //#if defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0
