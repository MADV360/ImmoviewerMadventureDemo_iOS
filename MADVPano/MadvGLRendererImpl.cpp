//
//  MadvGLRendererImpl.cpp
//  MADVPano
//
//  Created by QiuDong on 2017/8/18.
//  Copyright © 2017年 MADV. All rights reserved.
//

#include "MadvGLRendererImpl.h"
#include "MadvGLRenderer.h"
#include "gles2.h"
#include "gles2ext.h"
#include "gles3.h"
#include "gles3ext.h"
#include "Log.h"
#include "MadvUtils.h"
#include "PNGUtils.h"
#include "JPEGUtils.h"
#include "GLRenderTexture.h"
#include "GLFilterCache.h"
#include "EXIFParser.h"
#include "kazmath.h"
#include <fstream>
#include <sstream>
#include <string.h>

using namespace std;

//#define DEBUG_CUBEMAP

// Macros for Shader:

//#define EXPAND_AS_PLANE
//#define USE_MSAA
#define SINGLE_LUT_TEXTURE

#define SPHERE_RADIUS 128

#ifdef EXPAND_AS_PLANE
#define Z_SHIFT -1024
#else
#define Z_SHIFT  0
#endif

#define STRINGIZE0(...) __VA_ARGS__
#define STRINGIZE(...) #__VA_ARGS__
#define STRINGIZE2(...) STRINGIZE(__VA_ARGS__)

typedef AutoRef<MadvGLProgram> MadvGLProgramRef;
typedef AutoRef<Mesh3D> Mesh3DRef;
typedef AutoRef<GLVAO> GLVAORef;

static const char* TrivalVertexShaderSource = STRINGIZE2
(
attribute vec4 a_position;
attribute vec4 a_color;
attribute vec2 a_texCoord;
varying vec4 v_color;
varying mediump vec2 v_texCoord;
void main(void) {
 gl_Position = a_position;
 v_color = a_color;
 v_texCoord = a_texCoord;
}
);

static const char* TrivalFragmentShaderSource = STRINGIZE2
(
varying highp vec4 v_color;
varying highp vec2 v_texCoord;

void main()
{
 gl_FragColor = v_color;
}
);

/*
* Beta = Longitude = 2*M_PI * s;
* Alpha = Latitude = M_PI - M_PI * t;
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
*     Beta += M_PI;
* else if (x1 > 0)
*     Beta += 2*M_PI;
*
* if (abs(x) > abs(z))
*     Beta = 5*M_PI/2 - Beta;
*     if (Beta > 2*M_PI)
*         Beta -= 2*M_PI;
*/

/*
ToCubeMap:
const float q1div3 = 1.0 / 3.0, q2div3 = 2.0 / 3.0, q1div2 = 0.5;
const float sqrt1div3 = sqrt(q1div3);

if (0.0 <= dest.s && dest.s < q1div3 && 0 <= dest.t && dest.t < q1div2)
{// Left (-X):
src.y = dest.t * 4.0 - 1.0;
src.z = 1.0 - dest.s * 6.0;
src.x = -sqrt(1 - (src.y ^ 2 + src.z ^ 2) * q1div3);
src.yz *= sqrt1div3;
}
if (q1div3 <= dest.s && dest.s < q2div3 && 0 <= dest.t && dest.t < q1div2)
{// Front (-Z)
src.y = dest.t * 4.0 - 1.0;
src.x = dest.s * 6.0 - 3.0;
src.z = -sqrt(1 - (src.y ^ 2 + src.x ^ 2) * q1div3);
src.yx *= sqrt1div3;
}
if (q2div3 <= dest.s && dest.s <= 1.0 && 0 <= dest.t && dest.t < q1div2)
{// Right (+X)
src.y = dest.t * 4.0 - 1.0;
src.z = dest.s * 6.0 - 5.0;
src.x = sqrt(1 - (src.y ^ 2 + src.z ^ 2) * q1div3);
src.yz *= sqrt1div3;
}
if (0 <= dest.s && dest.s < q1div3 && q1div2 <= dest.t && dest.t <= 1.0)
{// Top (+Y):
src.z = dest.t * 4.0 - 3.0;
src.x = dest.s * 6.0 - 1.0;
src.y = sqrt(1 - (src.x ^ 2 + src.z ^ 2) * q1div3);
src.xz *= sqrt1div3;
}
if (q1div3 <= dest.s && dest.s < q2div3 && q1div2 <= dest.t && dest.t <= 1.0)
{// Back (+Z):
src.y = dest.t * 4.0 - 3.0;
src.x = 3.0 - dest.s * 6.0;
src.z = sqrt(1 - (src.y ^ 2 + src.x ^ 2) * q1div3);
src.xy *= sqrt1div3;
}
if (q2div3 <= dest.s && dest.s <= 1.0 && q1div2 <= dest.t && dest.t <= 1.0)
{// Bottom (-Y):
src.z = 3.0 - dest.t * 4.0;
src.x = dest.s * 6.0 - 5.0;
src.y = sqrt(1 - (src.x ^ 2 + src.z ^ 2) * q1div3);
src.xz *= sqrt1div3;
}
*/
static const char* CubeMapToRemappedVertexShader = STRINGIZE2
(
attribute vec4 a_position; \n
attribute vec2 a_vertexIndex; \n
uniform mat4 u_screenMatrix; \n
\n
varying highp vec2 v_texcoord; \n
void main(void) { \n
 gl_Position = u_screenMatrix * (a_position / a_position.w); \n ///!!!a_position; \n ///!!!
 v_texcoord = a_vertexIndex; \n
} \n
);

static const char* CubeMapToRemappedFragmentShader = STRINGIZE2
(
varying vec2 v_texcoord; \n
uniform samplerCube u_sourceTexture; \n
///!!!uniform sampler2D u_sourceTexture; \n
uniform highp mat4 u_invCMMatrix; \n
\n
highp vec2 sphereCoordFromTexCoord(highp vec2 texCoord) { \n
 return vec2(2.0 * M_PI * texCoord.s, M_PI * (1.0 - texCoord.t)); \n
} \n
highp vec3 normalizedVec3FromSphereCoord(highp vec2 sphereCoord) { \n
 highp float sinA = sin(sphereCoord.y); \n
 highp float sinB = sin(sphereCoord.x); \n
 highp float cosA = cos(sphereCoord.y); \n
 highp float cosB = cos(sphereCoord.x); \n
 return vec3(-sinA * sinB, cosA, sinA * cosB); \n
} \n
void main(void) { \n
 highp vec4 viewVector = vec4(normalizedVec3FromSphereCoord(sphereCoordFromTexCoord(v_texcoord)), 1.0); \n;
 gl_FragColor = textureCube(u_sourceTexture, (u_invCMMatrix * viewVector).xyz); \n
	 ///!!!gl_FragColor = texture2D(u_sourceTexture, viewVector.xy); \n
///gl_FragColor = vec4(viewVector.xyz, 1.0); \n
} \n
);

static const char* VertexShaderSource = STRINGIZE2
(
attribute vec4 a_position; \n
attribute vec2 a_vertexIndex; \n
//attribute vec2 a_texCoord; \n
// uniform int u_columns; \n
// uniform int u_rows; \n
uniform mat4 u_SPCMMatrix; \n
/// Samsum S8 issue is fixed by changing highp v_texCoord to mediump
varying highp vec2 v_texCoord; \n
\n
highp vec2 wrappedTexcoord(highp vec2 texcoord) { \n
 highp vec2 ret = texcoord; \n
STRINGIZE0(#if defined(DEBUG_FLAG2)) \n
 if (ret.s < 0.0) \n
	 ret.s += 1.0; \n
 else if (ret.s > 1.0) \n
	 ret.s -= 1.0; \n
 if (ret.t < 0.0) \n
	 ret.t += 1.0; \n
 else if (ret.t > 1.0) \n
	 ret.t -= 1.0; \n
STRINGIZE0(#else) \n
	if (ret.s < 0.0) \n
		ret.s += 1.0; \n
	if (ret.s > 1.0) \n
		ret.s -= 1.0; \n
	if (ret.t < 0.0) \n
		ret.t += 1.0; \n
	if (ret.t > 1.0) \n
		ret.t -= 1.0; \n
STRINGIZE0(#endif) \n
 return ret; \n
} \n
STRINGIZE0(#if defined(FLAG_STITCH_WITH_LUT_IN_SHADER)) \n
// uniform sampler2D u_lutTextureLS; \n
// uniform sampler2D u_lutTextureLT; \n
// uniform sampler2D u_lutTextureRS; \n
// uniform sampler2D u_lutTextureRT; \n
// uniform highp vec2 u_lutSrcSize; \n
uniform sampler2D u_lutTexture; \n
uniform highp vec2 u_dstSize; \n
varying highp vec2 v_texcoordL; \n
varying highp vec2 v_texcoordR; \n
varying mediump vec2 v_lutWeights; \n
\n
STRINGIZE0(#endif) \n
\n
STRINGIZE0(#if defined(FLAG_STITCH_WITH_LUT_IN_MESH)) \n
attribute highp vec2 a_texcoordL; \n
attribute highp vec2 a_texcoordR; \n
varying highp vec2 v_texcoordL; \n
varying highp vec2 v_texcoordR; \n
varying mediump vec2 v_lutWeights; \n
STRINGIZE0(#endif) \n
\n
// attribute float a_vertexRole; \n
uniform highp mat4 u_CMMatrix; \n
// uniform highp vec2 u_diffTexcoord; \n
\n
highp vec2 sphereCoordFromTexCoord(highp vec2 texCoord) { \n
 return vec2(2.0 * M_PI * texCoord.s, M_PI * (1.0 - texCoord.t)); \n
} \n
\n
highp vec2 texCoordFromSphereCoord(highp vec2 sphereCoord) { \n
 return vec2(sphereCoord.s / 2.0 / M_PI, 1.0 - sphereCoord.t / M_PI); \n
} \n
STRINGIZE0(#if defined(FLAG_STITCH_WITH_LUT_IN_SHADER) || defined(FLAG_STITCH_WITH_LUT_IN_MESH)) \n
	//highp vec2 sphereCoordOfXZPlane(float Rxz, float Y, )
mediump vec2 lutWeights(highp vec2 dstTexcoord) { \n
mediump float weight = 1.0; \n
mediump float weight1 = 0.0; \n
const highp float theta0 = M_PI / 2.0 - 2.0 * M_PI / 180.0; \n
const highp float theta1 = M_PI / 2.0 + 2.0 * M_PI / 180.0; \n
\n
highp vec2 dstSphereCoord = sphereCoordFromTexCoord(dstTexcoord); \n
 \n
highp float Rxz = abs(sin(dstSphereCoord.t)); \n
highp float z0 = cos(theta0); \n
highp float z1 = cos(theta1); \n
highp float boundTheta0, boundTheta1, boundTheta2, boundTheta3; \n
if (abs(z0) > Rxz) \n
{ \n
	boundTheta0 = 0.0; \n
} \n
else \n
{ \n
	boundTheta0 = acos(z0 / Rxz); \n
} \n
if (abs(z1) > Rxz) \n
{ \n
	boundTheta1 = M_PI; \n
} \n
else \n
{ \n
	boundTheta1 = acos(z1 / Rxz); \n
} \n
boundTheta2 = 2.0 * M_PI - boundTheta1; \n
boundTheta3 = 2.0 * M_PI - boundTheta0; \n
\n
if (dstSphereCoord.s < boundTheta0) \n
{ \n
	weight = 1.0; \n
	weight1 = 0.0; \n
} \n
else if (dstSphereCoord.s < boundTheta1) \n
{ \n
	if (boundTheta1 > boundTheta0) \n
	{ \n
	   weight1 = (dstSphereCoord.s - boundTheta0) / (boundTheta1 - boundTheta0); \n
	} \n
	else \n
	{ \n
		weight1 = 0.0; \n
	} \n
	weight = 1.0 - weight1; \n
} \n
else if (dstSphereCoord.s < boundTheta2) \n
{ \n
	weight1 = 1.0; \n
	weight = 0.0; \n
} \n
else if (dstSphereCoord.s < boundTheta3) \n
{ \n
	if (boundTheta3 > boundTheta2) \n
	{ \n
		weight = (dstSphereCoord.s - boundTheta2) / (boundTheta3 - boundTheta2); \n
	} \n
	else \n
	{ \n
		weight = 0.0; \n
	} \n
	weight1 = 1.0 - weight; \n
} \n
else \n
{ \n
	weight = 1.0; \n
	weight1 = 0.0; \n
} \n
\n
return vec2(weight, weight1); \n
//return vec2(0.0, 1.0); \n
} \n
STRINGIZE0(#endif) \n
\n
void main(void) { \n
 highp vec4 position = u_SPCMMatrix * a_position; \n
 gl_Position = vec4(position.xy, -position.z, position.w); \n
 \n
     highp vec2 dstTexcoord = a_vertexIndex; \n
STRINGIZE0(#if defined(DEBUG_FLAG1)) \n
     highp vec2 wrappedDstTexcoord = wrappedTexcoord(dstTexcoord); \n
STRINGIZE0(#else) \n
        highp vec2 wrappedDstTexcoord = (dstTexcoord); \n
STRINGIZE0(#endif) \n
        STRINGIZE0(#if defined(FLAG_STITCH_WITH_LUT_IN_SHADER)) \n
     highp vec2 texcoordInLUT = 0.5 / u_dstSize + (u_dstSize - vec2(1.0, 1.0)) / u_dstSize * wrappedDstTexcoord; \n
STRINGIZE0(#if defined(DEBUG_FLAG0)) \n
     texcoordInLUT = wrappedTexcoord(texcoordInLUT); \n
STRINGIZE0(#endif) \n
     highp vec4 lutTexel = texture2D(u_lutTexture, texcoordInLUT); \n
     v_texcoordL = vec2(lutTexel.r, lutTexel.g); \n
     v_texcoordR = vec2(lutTexel.b, lutTexel.a); \n
     \n
     v_lutWeights = lutWeights(wrappedDstTexcoord); \n
     \n
    STRINGIZE0(#elif defined(FLAG_STITCH_WITH_LUT_IN_MESH)) \n
     // Middle:2t-0.5; Top:2t-1; Bottom:2t
     v_texcoordL = vec2(a_texcoordL.s, a_texcoordL.t); \n
     v_texcoordR = vec2(a_texcoordR.s, a_texcoordR.t); \n
     \n
     v_lutWeights = lutWeights(wrappedDstTexcoord); \n
     STRINGIZE0(#else) \n
       // dstTexcoord = wrappedDstTexcoord; \n
     STRINGIZE0(#endif) \n
     v_texCoord = dstTexcoord; \n
 } \n
 );

///Ref: http://blog.csdn.net/opengl_es/article/details/17787495
static const char* FragmentShaderSource = STRINGIZE2
(
 varying vec2 v_texCoord; \n
 \n
 STRINGIZE0(#ifdef FLAG_STITCH_WITH_LUT_IN_SHADER) \n
 varying highp vec2 v_texcoordL; \n
 varying highp vec2 v_texcoordR; \n
 varying mediump vec2 v_lutWeights; \n
 STRINGIZE0(#endif) \n
 \n
 STRINGIZE0(#ifdef FLAG_STITCH_WITH_LUT_IN_MESH) \n
 varying highp vec2 v_texcoordL; \n
 varying highp vec2 v_texcoordR; \n
 varying mediump vec2 v_lutWeights; \n
 STRINGIZE0(#endif) \n
 \n
 STRINGIZE0(#ifndef FLAG_YUV_COLORSPACE) \n
 STRINGIZE0(#ifdef EXTERNAL) \n
 uniform samplerExternalOES u_sourceTexture; \n
 STRINGIZE0(#else) \n
 uniform sampler2D u_sourceTexture; \n
 STRINGIZE0(#endif) \n
 STRINGIZE0(#else) \n
 STRINGIZE0(#ifdef EXTERNAL) \n
 uniform samplerExternalOES u_sourceYTexture; \n
 uniform samplerExternalOES u_sourceUTexture; \n
 uniform samplerExternalOES u_sourceVTexture; \n
 STRINGIZE0(#else) \n
 uniform sampler2D u_sourceYTexture; \n
 uniform sampler2D u_sourceUTexture; \n
 uniform sampler2D u_sourceVTexture; \n
 STRINGIZE0(#endif) \n
 STRINGIZE0(#endif) \n
 uniform highp vec2 u_dstSize; \n
 uniform highp vec2 u_srcSizeL; \n
 uniform highp vec2 u_srcSizeR; \n
 uniform mat4 u_textureMatrix; \n
 uniform mat4 u_illusionTextureMatrix; \n
 \n
 highp vec2 wrappedTexcoord(highp vec2 texcoord) { \n
     highp vec2 ret = texcoord; \n
     if (ret.s < 0.0) \n
         ret.s += 1.0; \n
     else if (ret.s > 1.0) \n
         ret.s -= 1.0; \n
     if (ret.t < 0.0) \n
         ret.t += 1.0; \n
     else if (ret.t > 1.0) \n
         ret.t -= 1.0; \n
     return ret; \n
 } \n
 const float PI = 3.141592653589793238463; \n
 \n
 STRINGIZE0(#if defined(FLAG_STITCH_WITH_LUT_IN_SHADER)) \n
 \n
 highp vec2 sphereCoordFromTexCoord(highp vec2 texCoord) { \n
     return vec2(2.0 * PI * texCoord.s, PI * (1.0 - texCoord.t)); \n
 } \n
 \n
 highp vec2 texCoordFromSphereCoord(highp vec2 sphereCoord) { \n
     return vec2(sphereCoord.s / 2.0 / PI, 1.0 - sphereCoord.t / PI); \n
 } \n
 \n
  mediump vec2 lutWeights(highp vec2 dstTexcoord) { \n
     dstTexcoord.s = mod(dstTexcoord.s, 1.0); \n
     dstTexcoord.t = mod(dstTexcoord.t, 1.0); \n
		 mediump float weight = 1.0; \n
		 mediump float weight1 = 0.0; \n
		 const highp float theta0 = PI / 2.0 - 2.0 * PI / 180.0; \n
		 const highp float theta1 = PI / 2.0 + 2.0 * PI / 180.0; \n
		 \n
		 highp vec2 dstSphereCoord = sphereCoordFromTexCoord(dstTexcoord); \n
		 \n
		 highp float Rxz = abs(sin(dstSphereCoord.t)); \n
		 highp float z0 = cos(theta0); \n
		 highp float z1 = cos(theta1); \n
		 highp float boundTheta0, boundTheta1, boundTheta2, boundTheta3; \n
		 if (abs(z0) > Rxz) \n
		 { \n
		 boundTheta0 = 0.0; \n
		 } \n
		 else \n
		 { \n
		 boundTheta0 = acos(z0 / Rxz); \n
		 } \n
		 if (abs(z1) > Rxz) \n
		 { \n
		 boundTheta1 = PI; \n
		 } \n
		 else \n
		 { \n
		 boundTheta1 = acos(z1 / Rxz); \n
		 } \n
		 boundTheta2 = 2.0 * PI - boundTheta1; \n
		 boundTheta3 = 2.0 * PI - boundTheta0; \n
		 \n
		 if (dstSphereCoord.s < boundTheta0) \n
		 { \n
		 weight = 1.0; \n
		 weight1 = 0.0; \n
		 } \n
		 else if (dstSphereCoord.s < boundTheta1) \n
		 { \n
		 if (boundTheta1 > boundTheta0) \n
		 { \n
		 weight1 = (dstSphereCoord.s - boundTheta0) / (boundTheta1 - boundTheta0); \n
		 } \n
		 else \n
		 { \n
		 weight1 = 0.0; \n
		 } \n
		 weight = 1.0 - weight1; \n
		 } \n
		 else if (dstSphereCoord.s < boundTheta2) \n
		 { \n
		 weight1 = 1.0; \n
		 weight = 0.0; \n
		 } \n
		 else if (dstSphereCoord.s < boundTheta3) \n
		 { \n
		 if (boundTheta3 > boundTheta2) \n
		 { \n
		 weight = (dstSphereCoord.s - boundTheta2) / (boundTheta3 - boundTheta2); \n
		 } \n
		 else \n
		 { \n
		 weight = 0.0; \n
		 } \n
		 weight1 = 1.0 - weight; \n
		 } \n
		 else \n
		 { \n
		 weight = 1.0; \n
		 weight1 = 0.0; \n
		 } \n
		 \n
		 return vec2(weight, weight1); \n
		 //return vec2(0.0, 1.0); \n
 } \n
 \n
 STRINGIZE0(#endif) \n
 \n
 vec3 YUVTexel2RGB(vec3 yuvTexel) { \n
     float y = yuvTexel.r; \n
     float u = yuvTexel.g - 0.5; \n
     float v = yuvTexel.b - 0.5; \n
     vec3 rgb; \n
     rgb.r = y +             1.402 * v; \n
     rgb.g = y - 0.344 * u - 0.714 * v; \n
     rgb.b = y + 1.772 * u; \n
     return rgb; \n
 } \n
 vec4 textureYUV2D(sampler2D textureY, sampler2D textureU, sampler2D textureV, highp vec2 texcoord) { \n
     float texelYL = texture2D(textureY, wrappedTexcoord(texcoord)).r; \n
     float texelUL = texture2D(textureU, wrappedTexcoord(texcoord)).r; \n
     float texelVL = texture2D(textureV, wrappedTexcoord(texcoord)).r; \n
     return vec4(YUVTexel2RGB(vec3(texelYL, texelUL, texelVL)), 1.0); \n
 } \n
 \n
 lowp float transformTexcoord2D(inout highp vec2 texcoord, mat4 textureMatrix) { \n
     //     vec2 ret = sin(texcoord * M_PI * 2.0) / 2.0 + vec2(0.5, 0.5);
     highp vec2 ret = (textureMatrix * vec4(texcoord, 0.0, 1.0)).xy; \n
     /*
      if (ret.s < 0.0)
      ret.s += 1.0;
      else if (ret.s > 1.0)
      ret.s -= 1.0;
      if (ret.t < 0.0)
      ret.t += 1.0;
      else if (ret.t > 1.0)
      ret.t -= 1.0;
      /*/
     //vec2 ret = clamp(texcoord, 0.0, 1.0);
     //*/
     lowp float alpha = 1.0; \n
     if (texcoord.s >= 0.0 && texcoord.s <= 1.0 && (ret.s < 0.0 || ret.s > 1.0)) \n
     { \n
         alpha = 0.0; \n
         if (ret.s < 0.0) \n
             ret.s += 1.0; \n
         else if (ret.s > 1.0) \n
             ret.s -= 1.0; \n
     } \n
     if (texcoord.t >= 0.0 && texcoord.t <= 1.0 && (ret.t < 0.0 || ret.t > 1.0)) \n
     { \n
         alpha = 0.0; \n
         if (ret.t < 0.0) \n
             ret.t += 1.0; \n
         else if (ret.t > 1.0) \n
             ret.t -= 1.0; \n
     } \n
     texcoord = ret; \n
     return alpha; \n
 } \n
 \n
 vec4 color4OfTexCoord(highp vec2 dstTexcoord, mat4 textureMatrix, mat4 illusionTextureMatrix) { \n
     STRINGIZE0(#ifdef FLAG_PLAIN_STITCH) \n
     { \n
         highp vec2 srcTexcoord; \n
         float H = (u_srcSizeL.y > u_srcSizeR.y ? u_srcSizeL.y : u_srcSizeR.y); \n
         if (dstTexcoord.s <= u_srcSizeL.x / (u_srcSizeL.x + u_srcSizeR.x)) \n
         { \n
             srcTexcoord.s = dstTexcoord.s * (u_srcSizeL.x + u_srcSizeR.x) / u_srcSizeL.x; \n
             srcTexcoord.t = dstTexcoord.t * H / u_srcSizeL.y; \n
         } \n
         else \n
         { \n
             srcTexcoord.s = (dstTexcoord.s - u_srcSizeL.x / (u_srcSizeL.x + u_srcSizeR.x)) * (u_srcSizeL.x + u_srcSizeR.x) / u_srcSizeR.x; \n
             srcTexcoord.t = dstTexcoord.t * H / u_srcSizeR.y; \n
         } \n
         lowp float alpha = transformTexcoord2D(srcTexcoord, textureMatrix); \n
         STRINGIZE0(#ifdef FLAG_YUV_COLORSPACE) \n
             return textureYUV2D(u_sourceYTexture, u_sourceUTexture, u_sourceVTexture, srcTexcoord) * alpha; \n
         STRINGIZE0(#else) \n
             return texture2D(u_sourceTexture, wrappedTexcoord(srcTexcoord)).rgba * alpha; \n
         STRINGIZE0(#endif) \n
     } \n
     STRINGIZE0(#elif defined(FLAG_STITCH_WITH_LUT_IN_SHADER) || defined(FLAG_STITCH_WITH_LUT_IN_MESH)) \n
     { \n
         vec4 lTexel; \n
         vec4 rTexel; \n
         highp vec2 texcoordL = v_texcoordL; \n
         highp vec2 texcoordR = v_texcoordR; \n
         highp vec2 texcoordL1 = texcoordL; \n
         highp vec2 texcoordR1 = texcoordR; \n
         \n
         STRINGIZE0(#ifndef FLAG_YUV_COLORSPACE) \n
         { \n
             lowp float alphaL = transformTexcoord2D(texcoordL, textureMatrix); \n
             lowp float alphaL1 = transformTexcoord2D(texcoordL1, illusionTextureMatrix); \n
             STRINGIZE0(#ifndef FLAG_DEBUG_TEXCOORD) \n
             lTexel = texture2D(u_sourceTexture, wrappedTexcoord(texcoordL)) * alphaL * (alphaL1 * 0.25 + 0.75); \n
             STRINGIZE0(#else) \n
             lTexel = vec4(texcoordL*0.5 * alphaL * (alphaL1 * 0.25 + 0.75), 0.0, 1.0); \n ///vec4(0.5, 0.25, 0.0, 1.0); \n ///
             STRINGIZE0(#endif) \n
             \n
             texcoordR = texcoordR + vec2(0.5,0.0); \n
             lowp float alphaR = transformTexcoord2D(texcoordR, textureMatrix); \n
             lowp float alphaR1 = transformTexcoord2D(texcoordR1, illusionTextureMatrix); \n
             STRINGIZE0(#ifndef FLAG_DEBUG_TEXCOORD) \n
             rTexel = texture2D(u_sourceTexture, wrappedTexcoord(texcoordR)) * alphaR * (alphaR1 * 0.25 + 0.75); \n
             STRINGIZE0(#else) \n
             rTexel = vec4(texcoordR*0.5 * alphaR * (alphaR1 * 0.25 + 0.75), 0.0, 1.0); \n ///vec4(0.5, 0.25, 0.0, 1.0); \n ///
             STRINGIZE0(#endif) \n
             \n
             //        rTexel = texture2D(u_textureL, texcoordR + vec2(0.5,0.0));
         } \n
         STRINGIZE0(#else) \n
         { \n
             lowp float alphaL = transformTexcoord2D(texcoordL, textureMatrix); \n
             lowp float alphaL1 = transformTexcoord2D(texcoordL1, illusionTextureMatrix); \n
             lTexel = textureYUV2D(u_sourceYTexture, u_sourceUTexture, u_sourceVTexture, texcoordL) * alphaL * (alphaL1 * 0.5 + 0.5); \n
             \n
             texcoordR = texcoordR + vec2(0.5,0.0); \n
             lowp float alphaR = transformTexcoord2D(texcoordR, textureMatrix); \n
             lowp float alphaR1 = transformTexcoord2D(texcoordR1, illusionTextureMatrix); \n
             rTexel = textureYUV2D(u_sourceYTexture, u_sourceUTexture, u_sourceVTexture, texcoordR) * alphaR * (alphaR1 * 0.5 + 0.5); \n
         } \n
         STRINGIZE0(#endif) \n
		 vec2 weights = v_lutWeights; \n
        //if (weights.x != 1.0 && weights.x != 0.0)
         //   return vec4(weights.x, weights.y, 0.0, 1.0);
         //else
         return (lTexel * weights.s + rTexel * weights.t).rgba; \n
     } \n
     \n
     STRINGIZE0(#else) \n
     { \n
         highp vec2 texcoord = dstTexcoord; \n
         highp vec2 texcoord1 = dstTexcoord; \n
         lowp float alpha = transformTexcoord2D(texcoord, textureMatrix); \n
         lowp float alpha1 = transformTexcoord2D(texcoord1, illusionTextureMatrix); \n
         STRINGIZE0(#ifndef FLAG_YUV_COLORSPACE) \n
         STRINGIZE0(#ifndef FLAG_DEBUG_TEXCOORD) \n
         return texture2D(u_sourceTexture, wrappedTexcoord(texcoord)).rgba * alpha * (alpha1 * 0.25 + 0.75); \n
         STRINGIZE0(#else) \n ///#ifndef FLAG_DEBUG_TEXCOORD
         return vec4(texcoord*0.5 * alpha * (alpha1 * 0.25 + 0.75), 0.0, 1.0); \n ///vec4(0.5, 0.25, 0.0, 1.0); \n ///
         STRINGIZE0(#endif) \n ///#ifndef FLAG_DEBUG_TEXCOORD
         STRINGIZE0(#else) \n
         STRINGIZE0(#ifndef FLAG_DEBUG_TEXCOORD) \n
         return textureYUV2D(u_sourceYTexture, u_sourceUTexture, u_sourceVTexture, texcoord) * alpha * (alpha1 * 0.25 + 0.75); \n
         STRINGIZE0(#else) \n ///#ifndef FLAG_DEBUG_TEXCOORD
         return vec4(texcoord*0.5 * alpha * (alpha1 * 0.25 + 0.75), 0.0, 1.0); \n ///vec4(0.5, 0.25, 0.0, 1.0); \n ///
         STRINGIZE0(#endif) \n ///#ifndef FLAG_DEBUG_TEXCOORD
         STRINGIZE0(#endif) \n
     } \n
     \n
     STRINGIZE0(#endif) \n
 } \n
  \n
 void main() \n
{ \n
    ///!!!For Debug:
    //        if (v_texCoord.s < 0.0 || v_texCoord.s > 1.0 || v_texCoord.t < 0.0 || v_texCoord.t > 1.0)
    //        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
    //        else
    \n
    gl_FragColor = color4OfTexCoord(v_texCoord, u_textureMatrix, u_illusionTextureMatrix); \n
} \n
 
 );

/// 000:Plain 001:Sphere 010:PlainV1 011:SphereV1 10X:LittlePlanet 11X:LittlePlanetV1
#define FLAG_STITCH_WITH_LUT_IN_SHADER    0x01
#define FLAG_STITCH_WITH_LUT_IN_MESH    0x02
#define FLAG_YUV_COLORSPACE     0x04
#define FLAG_PLAIN_STITCH       0x08
///#define FLAG_REFLATTENING_IN_VERTEX      0x10
///#define FLAG_REFLATTENING_IN_PIXEL       0x20
#define FLAG_DEBUG_TEXCOORD 0x10
//#define FLAG_TO_CUBEMAP 0x80
#ifdef TARGET_OS_ANDROID
#define FLAG_IMAGE_EXTERNAL     0x20
#endif

#ifdef TARGET_OS_ANDROID
#define FLAG_BITS 6
#else
#define FLAG_BITS 5
#endif

MadvGLProgram::MadvGLProgram(const GLchar* const* vertexSources, int vertexSourcesCount, const GLchar* const* fragmentSources, int fragmentSourcesCount)
: GLProgram(vertexSources, vertexSourcesCount, fragmentSources, fragmentSourcesCount)
, _sourceTextureSlot(-1)
, _vertexRoleSlot(-1)
, _diffTexcoordSlot(-1)
, _gridCoordSlot(-1)
, _columnsSlot(-1)
, _rowsSlot(-1)
, _leftTexcoordSlot(-1)
, _rightTexcoordSlot(-1)
, _dstSizeSlot(-1)
, _leftSrcSizeSlot(-1)
, _rightSrcSizeSlot(-1)
//, _scaleSlot(-1)
//, _aspectSlot(-1)
//, _transformSlot(-1)
, _ySourceTextureSlot(-1)
, _uSourceTextureSlot(-1)
, _vSourceTextureSlot(-1)
, _lsLutTextureSlot(-1)
, _ltLutTextureSlot(-1)
, _rsLutTextureSlot(-1)
, _rtLutTextureSlot(-1)
, _lutTextureSlot(-1)
, _lutSrcSizeSlot(-1)
, _SPCMMatrixSlot(-1)
, _CMMatrixSlot(-1)
, _invCMMatrixSlot(-1)
{
    _vertexRoleSlot = glGetAttribLocation(_program, "a_vertexRole");
    _diffTexcoordSlot = glGetUniformLocation(_program, "u_diffTexcoord");
    
    _gridCoordSlot = glGetAttribLocation(_program, "a_vertexIndex");
    _rowsSlot = glGetUniformLocation(_program, "u_rows");
    _columnsSlot = glGetUniformLocation(_program, "u_columns");
    
    _leftTexcoordSlot = glGetAttribLocation(_program, "a_texcoordL");
    _rightTexcoordSlot = glGetAttribLocation(_program, "a_texcoordR");
    
    _sourceTextureSlot = glGetUniformLocation(_program, "u_sourceTexture");
    
    _dstSizeSlot = glGetUniformLocation(_program, "u_dstSize");
    _leftSrcSizeSlot = glGetUniformLocation(_program, "u_srcSizeL");
    _rightSrcSizeSlot = glGetUniformLocation(_program, "u_srcSizeR");
    
    _ySourceTextureSlot = glGetUniformLocation(_program, "u_sourceYTexture");
    _uSourceTextureSlot = glGetUniformLocation(_program, "u_sourceUTexture");
    _vSourceTextureSlot = glGetUniformLocation(_program, "u_sourceVTexture");
    
    _lsLutTextureSlot = glGetUniformLocation(_program, "u_lutTextureLS");
    _ltLutTextureSlot = glGetUniformLocation(_program, "u_lutTextureLT");
    _rsLutTextureSlot = glGetUniformLocation(_program, "u_lutTextureRS");
    _rtLutTextureSlot = glGetUniformLocation(_program, "u_lutTextureRT");
    _lutTextureSlot = glGetUniformLocation(_program, "u_lutTexture");
    _lutSrcSizeSlot = glGetUniformLocation(_program, "u_lutSrcSize");
    
    _textureMatrixSlot = glGetUniformLocation(_program, "u_textureMatrix");
    _illusionTextureMatrixSlot = glGetUniformLocation(_program, "u_illusionTextureMatrix");
    
    _SPCMMatrixSlot = glGetUniformLocation(_program, "u_SPCMMatrix");
    _CMMatrixSlot = glGetUniformLocation(_program, "u_CMMatrix");
    _invCMMatrixSlot = glGetUniformLocation(_program, "u_invCMMatrix");
}

static GLfloat* s_gridColors;

GLuint MadvGLRendererImpl::_shaderFlags = GLShaderDebugFlag2;

MadvGLRendererImpl::~MadvGLRendererImpl() {
    //    free(_gridColors);
    _trivialMesh = NULL;
    _quadMesh = NULL;
    _lutQuadMesh = NULL;
    _sphereMesh = NULL;
    _lutSphereMesh = NULL;
    _capsMesh = NULL;
    
    _currentVAO = NULL;
    _capsVAO = NULL;
    _trivialVAO = NULL;
    _quadVAO = NULL;
    _lutQuadVAO = NULL;
    _sphereVAO = NULL;
    _lutSphereVAO = NULL;
    
    delete[] _glPrograms;
	_currentGLProgram = NULL;
    //    glDeleteFramebuffers(1, &_framebuffer);
    //        glDeleteRenderbuffers(1, &_depthbuffer);
#ifdef USE_MSAA
    glDeleteFramebuffers(1, &_msaaFramebuffer);
    glDeleteRenderbuffers(1, &_msaaRenderbuffer);
    glDeleteRenderbuffers(1, &_msaaDepthbuffer);
#endif
    //    if (-1 != _srcTextureL) glDeleteTextures(1, (GLuint*)&_srcTextureL);
    //    if (-1 != _srcTextureR) glDeleteTextures(1, (GLuint*)&_srcTextureR);
    //    if (-1 != _capsTexture) glDeleteTextures(1, (GLuint*)&_capsTexture);
    //    if (-1 != _yuvTextures[0]) glDeleteTextures(3, (GLuint*)_yuvTextures);
    //    _srcTextureL = _srcTextureR = -1;
    //    for (int i=0; i<3; i++)
    //    {
    //        _yuvTextures[i] = -1;
    //    }
    if (_lsLutTexture > 0)
    {
        glDeleteTextures(1, (const GLuint*)&_lsLutTexture);
    }
    if (_ltLutTexture > 0)
    {
        glDeleteTextures(1, (const GLuint*)&_ltLutTexture);
    }
    if (_rsLutTexture > 0)
    {
        glDeleteTextures(1, (const GLuint*)&_rsLutTexture);
    }
    if (_rtLutTexture > 0)
    {
        glDeleteTextures(1, (const GLuint*)&_rtLutTexture);
    }
    if (_lutTexture > 0)
    {
        glDeleteTextures(1, (const GLuint*)&_lutTexture);
    }
    //_glCamera = NULL;
	//ALOGE("\n#Crash# ~MadvGLRendererImpl() @0x%lx;\n", (long)this);
}
/*
MadvGLRendererImpl::MadvGLRendererImpl(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize)
: MadvGLRendererImpl::MadvGLRendererImpl(lutPath, leftSrcSize, rightSrcSize, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS)
{
    
}
//*/
MadvGLRendererImpl::MadvGLRendererImpl(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments)
: _srcTextureL(-1)
, _srcTextureR(-1)
, _srcTextureTarget(GL_TEXTURE_2D)
, _drawCaps(false)
, _capsTexture(-1)
, _capsTextureTarget(GL_TEXTURE_2D)
//, _separateSourceTexture(false)
, _currentGLProgram(NULL)
, _glPrograms(NULL)
, _debugGLProgram(NULL)
, _debugVAOs()
, _enableDebug(false)
, _trivialVAO(NULL)
, _quadVAO(NULL)
, _lutQuadVAO(NULL)
, _sphereVAO(NULL)
, _lutSphereVAO(NULL)
, _currentVAO(NULL)
, _flipY(false)
, _renderSourceSize(Vec2f{0.f, 0.f})
//, _isPrevDisplayModeLittlePlanet(false)
//, _glCamera(NULL)
, _longitudeSegments(longitudeSegments)
, _latitudeSegments(latitudeSegments)
, _trivialMesh(NULL)
, _quadMesh(NULL)
, _sphereMesh(NULL)
, _lutQuadMesh(NULL)
, _lutSphereMesh(NULL)
, _capsMesh(NULL)
, _capsVAO(NULL)
, _lsLutTexture(-1)
, _ltLutTexture(-1)
, _rsLutTexture(-1)
, _rtLutTexture(-1)
, _lutTexture(-1)
{
    int maxProgramsCount = (1 << FLAG_BITS) + 1;//Last one for cubemap
    _glPrograms = new MadvGLProgramRef[maxProgramsCount];
    for (int i=0; i < maxProgramsCount; ++i)
    {
        _glPrograms[i] = NULL;
    }
    
    for (int i=0; i<3; ++i)
    {
        _yuvTexturesL[i] = -1;
        _yuvTexturesR[i] = -1;
    }
    
    _needRenderNewSource = false;
    
#ifdef EXPAND_AS_PLANE
    _mesh = Mesh3DCcreateGrids(2160, 1080, _longitudeSegments, _latitudeSegments);
#else
    _trivialMesh = Mesh3D::createTrivialQuad();
    _quadMesh = Mesh3D::createRedundantGrids(2.f, 2.f, _longitudeSegments, _latitudeSegments,_latitudeSegments, false, false);
    _lutQuadMesh = Mesh3D::createRedundantGrids(2.f, 2.f, _longitudeSegments, _latitudeSegments,_latitudeSegments, false, false);
    _sphereMesh = Mesh3D::createSphereV0(SPHERE_RADIUS, _longitudeSegments, _latitudeSegments, false, false);
    _lutSphereMesh = Mesh3D::createSphereV0(SPHERE_RADIUS, _longitudeSegments, _latitudeSegments, false, false);
    _capsMesh = Mesh3D::createSphereGaps(SPHERE_RADIUS, M_PI/6, M_PI - M_PI/6, 200.f/200.f);
#endif
    
    //_glCamera = new GLCamera;
    
    _yuvTexturesL[0] = _yuvTexturesL[1] = _yuvTexturesL[2] = _yuvTexturesR[0] = _yuvTexturesR[1] = _yuvTexturesR[2] = -1;
    
    kmScalar initTextureMatrixData[] = {
        1.f, 0.f, 0.f, 0.f,
        0.f, 1.f, 0.f, 0.f,
        0.f, 0.f, 1.f, 0.f,
        0.f, 0.f, 0.f, 1.f,
    };
    kmMat4Fill(&_textureMatrix, initTextureMatrixData);
    kmMat4Fill(&_illusionTextureMatrix, initTextureMatrixData);
    
    pthread_mutex_init(&_mutex, NULL);
    
    prepareLUT(lutPath, leftSrcSize, rightSrcSize);
}

MadvGLRendererImpl::MadvGLRendererImpl(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize)
	: MadvGLRendererImpl(lutPath, leftSrcSize, rightSrcSize, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS)
{
}
/*
void MadvGLRendererImpl::setBestMeshSize(GLuint longitudeSegments, GLuint latitudeSegments) {
    _longitudeSegments = longitudeSegments;
    _latitudeSegments = latitudeSegments;
}
//*/
void MadvGLRendererImpl::prepareGLCanvas(GLint x, GLint y, GLint width, GLint height) {
    switch (_currentDisplayMode & PanoramaDisplayModeExclusiveMask)
    {
        case PanoramaDisplayModeCrystalBall:
            glEnable(GL_CULL_FACE);
            glCullFace(GL_BACK);
            if (_flipX ^ _flipY)
                glFrontFace(GL_CW);
            else
                glFrontFace(GL_CCW);
            break;
        default:
            glDisable(GL_CULL_FACE);
            break;
    }
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glViewport(x, y, width, height);
    CHECK_GL_ERROR();
}

void MadvGLRendererImpl::setTextureMatrix(const kmMat4 *textureMatrix) {
    kmMat4Assign(&_textureMatrix, textureMatrix);
}

void MadvGLRendererImpl::setIllusionTextureMatrix(const kmMat4 *textureMatrix) {
    kmMat4Assign(&_illusionTextureMatrix, textureMatrix);
}

void MadvGLRendererImpl::setRenderSource(void* renderSource) {
    pthread_mutex_lock(&_mutex);
    {
        _renderSource = renderSource;
        _needRenderNewSource = true;
    }
    pthread_mutex_unlock(&_mutex);
    
    updateSourceTextureIfNecessary();
}

Vec4f gridCoord(Vec2f texcoord, Vec2f grids, Vec2f sampleCenter) {
    Vec2f grid = Vec2f{texcoord.s * grids.s, texcoord.t * grids.t};
    Vec2f major = Vec2f{floorf(grid.s - sampleCenter.s), floorf(grid.t - sampleCenter.t)};
    Vec2f minor = Vec2f{grid.s - major.s, grid.t - major.t};
    int diffS = (int) minor.s;
    int diffT = (int) minor.t;
    major.s += diffS;
    major.t += diffT;
    minor.s -= diffS;
    minor.t -= diffT;
    return Vec4f{major.s,major.t, minor.s,minor.t};
}

int ushortTexture(const GLushort* data, Vec2f dimension, int rowStride, int x, int y, GLenum wrapS, GLenum wrapT) {
    int rows = (int)dimension.t, cols = (int)dimension.s;
    if (x < 0)
    {
        if (GL_REPEAT == wrapS)
            x = ((x % cols) + cols) % cols;
        else
            x = 0;
    }
    else if (x >= cols)
    {
        if (GL_REPEAT == wrapS)
            x = x % cols;
        else
            x = cols - 1;///!!!cols ??
    }
    
    if (y < 0)
    {
        if (GL_REPEAT == wrapT)
            y = ((y % rows) + rows) % rows;
        else
            y = 0;
    }
    else if (y >= rows)
    {
        if (GL_REPEAT == wrapT)
            y = y % rows;
        else
            y = rows - 1;///!!!rows ??
    }
    
    return (int) data[(int)(rowStride * y + x)];
}

float ushortTexture(const GLushort* data, Vec2f dimension, int rowStride, Vec4f gridCoord, GLenum wrapS, GLenum wrapT) {
    int x0 = gridCoord.x;
    int y0 = gridCoord.y;
    float qS = gridCoord.z;
    float qT = gridCoord.w;
    float LB = ushortTexture(data, dimension, rowStride, x0, y0, wrapS, wrapT);
    float LT = ushortTexture(data, dimension, rowStride, x0, y0 + 1, wrapS, wrapT);
    float RT = ushortTexture(data, dimension, rowStride, x0 + 1, y0 + 1, wrapS, wrapT);
    float RB = ushortTexture(data, dimension, rowStride, x0 + 1, y0, wrapS, wrapT);
    return (RT * qS + LT * (1.0 - qS)) * qT + (RB * qS + LB * (1.0 - qS)) * (1.0 - qT);
}

void convertMesh3DWithLUT(Mesh3DRef mesh, Vec2f lutDstSize, Vec2f leftSrcSize,Vec2f rightSrcSize, int dataSizeInShort, const GLushort* lxIntData, const GLushort* lxMinData, const GLushort* lyIntData, const GLushort* lyMinData, const GLushort* rxIntData, const GLushort* rxMinData, const GLushort* ryIntData, const GLushort* ryMinData) {
    ALOGE("convertMesh3DWithLUT : leftSrcSize = (%f,%f), rightSrcSize = (%f,%f), lutDstSize = (%f,%f)", leftSrcSize.width,leftSrcSize.height, rightSrcSize.width,rightSrcSize.height, lutDstSize.width,lutDstSize.height);
    Vec2f minL = {65536.f, 65536.f}, maxL = {-65536.f, -65536.f};
    Vec2f minR = {65536.f, 65536.f}, maxR = {-65536.f, -65536.f};
    for (int i=0; i<mesh->vertexCount(); ++i)
    {
        P4C4T2f& vertex = mesh->vertices()[i];
        
        Vec2f dstTexCoord = Vec2f{vertex.s, 1.f - vertex.t};
        
        /// lutMappedTexcoords() :
        Vec2f lutDstSize1 = Vec2f{lutDstSize.s - 1, lutDstSize.t - 1};
        Vec4f dstGridCoord = gridCoord(dstTexCoord, lutDstSize1, Vec2f{0.5f, 0.5f});
        float lxInt = ushortTexture(lxIntData, lutDstSize1, lutDstSize.s, dstGridCoord, GL_REPEAT, GL_CLAMP_TO_EDGE);
        float lxMin = ushortTexture(lxMinData, lutDstSize1, lutDstSize.s, dstGridCoord, GL_REPEAT, GL_CLAMP_TO_EDGE);
        float lyInt = ushortTexture(lyIntData, lutDstSize1, lutDstSize.s, dstGridCoord, GL_REPEAT, GL_CLAMP_TO_EDGE);
        float lyMin = ushortTexture(lyMinData, lutDstSize1, lutDstSize.s, dstGridCoord, GL_REPEAT, GL_CLAMP_TO_EDGE);
        float rxInt = ushortTexture(rxIntData, lutDstSize1, lutDstSize.s, dstGridCoord, GL_REPEAT, GL_CLAMP_TO_EDGE);
        float rxMin = ushortTexture(rxMinData, lutDstSize1, lutDstSize.s, dstGridCoord, GL_REPEAT, GL_CLAMP_TO_EDGE);
        float ryInt = ushortTexture(ryIntData, lutDstSize1, lutDstSize.s, dstGridCoord, GL_REPEAT, GL_CLAMP_TO_EDGE);
        float ryMin = ushortTexture(ryMinData, lutDstSize1, lutDstSize.s, dstGridCoord, GL_REPEAT, GL_CLAMP_TO_EDGE);
        
        float lx = (lxInt + lxMin / 1000.f);
        float ly = leftSrcSize.t - (lyInt + lyMin / 1000.f);
        float rx = (rxInt + rxMin / 1000.f);
        float ry = leftSrcSize.t - (ryInt + ryMin / 1000.f);
        
        Vec2f texcoordL = Vec2f{lx / leftSrcSize.s, ly / leftSrcSize.t};
        Vec2f texcoordR = Vec2f{rx / rightSrcSize.s, ry / rightSrcSize.t};
        vertex.r = texcoordL.s;
        vertex.g = texcoordL.t;
        vertex.b = texcoordR.s;
        vertex.a = texcoordR.t;
        // Middle:2t-0.5; Top:2t-1; Bottom:2t
        
        if (texcoordL.s < minL.s) minL.s = texcoordL.s;
        if (texcoordL.t < minL.t) minL.t = texcoordL.t;
        if (texcoordR.s < minR.s) minR.s = texcoordR.s;
        if (texcoordR.t < minR.t) minR.t = texcoordR.t;
        if (texcoordL.s > maxL.s) maxL.s = texcoordL.s;
        if (texcoordL.t > maxL.t) maxL.t = texcoordL.t;
        if (texcoordR.t > maxR.t) maxR.t = texcoordR.t;
        if (texcoordR.s > maxR.s) maxR.s = texcoordR.s;
    }
    ALOGE("convertMesh3DWithLUT : minL = (%f,%f), maxL = (%f,%f), minR = (%f,%f), maxR = (%f,%f)", minL.s,minL.t, maxL.s,maxL.t, minR.s,minR.t, maxR.s,maxR.t);
}

inline float setRGBOfLUTTexel(GLubyte** ppDst, float value, float denom) {
    float fValue = value * 4;
    int iMajor = (int) floorf(fValue);
    int iMinor = (int) (256.f * (fValue - iMajor));
    if (iMinor >= 256)
    {
        iMajor ++;
        iMinor -= 256;
    }
    
    int R = (iMajor >> 8) & 0xff;
    int G = (iMajor) & 0xff;
    int B = (iMinor) & 0xff;
    
    *((*ppDst)++) = R;
    *((*ppDst)++) = G;
    *((*ppDst)++) = B;
    
    float r = (float)R / 256.f;
    float g = (float)G / 256.f;
    float b = (float)B / 256.f;
    
    float I = r * 65536.0 + g * 256.0;
    float M = b;
    ///!!!For Debug:
    if (roundf(fValue) != roundf(I + M)/* && (major < 0.f || minor < 0.f)*/)
    {
//        ALOGE("setRGBOfLUTTexel Failed: round(fValue)=%f, round(I+M)=%f\n", roundf(fValue), roundf(I + M));
    }
    return (I + M) / (4.0 * denom);
}

void* createLUTData(Vec2f lutDstSize, Vec2f leftSrcSize,Vec2f rightSrcSize, int dataSizeInShort, const GLushort* lxIntData, const GLushort* lxMinData, const GLushort* lyIntData, const GLushort* lyMinData, const GLushort* rxIntData, const GLushort* rxMinData, const GLushort* ryIntData, const GLushort* ryMinData) {
    ALOGE("createLUTTexture : leftSrcSize = (%f,%f), rightSrcSize = (%f,%f), lutDstSize = (%f,%f)", leftSrcSize.width,leftSrcSize.height, rightSrcSize.width,rightSrcSize.height, lutDstSize.width,lutDstSize.height);
    if (!lxIntData) return NULL;
#ifndef SINGLE_LUT_TEXTURE
    GLubyte* textureDatas = (GLubyte*) malloc(sizeof(GLubyte) * 3 * lutDstSize.width * lutDstSize.height * 4);
    long textureDataSize = 3 * lutDstSize.width * lutDstSize.height;
    GLubyte* pDstTextureDataLS = textureDatas;
    GLubyte* pDstTextureDataLT = pDstTextureDataLS + textureDataSize;
    GLubyte* pDstTextureDataRS = pDstTextureDataLT + textureDataSize;
    GLubyte* pDstTextureDataRT = pDstTextureDataRS + textureDataSize;
#else //#ifndef SINGLE_LUT_TEXTURE
    GLfloat* textureData = (GLfloat*) malloc(sizeof(GLfloat) * 4 * lutDstSize.width * lutDstSize.height);
    GLfloat* pDst = textureData;
#endif //#ifndef SINGLE_LUT_TEXTURE
    Vec2f lutDstSize1 = Vec2f{lutDstSize.s - 1, lutDstSize.t - 1};
    //    Vec2f minL = {65536.f, 65536.f}, maxL = {-65536.f, -65536.f};
    //    Vec2f minR = {65536.f, 65536.f}, maxR = {-65536.f, -65536.f};
    for (int iT=0; iT < lutDstSize.height; ++iT)
    {
        for (int iS = 0; iS < lutDstSize.width; ++iS)
        {
            Vec2f texcoordL, texcoordR;
            int index = roundf(lutDstSize.height - 1 - iT) * roundf(lutDstSize.width) + iS;
            float lxInt = lxIntData[index];
            float lxMin = lxMinData[index];
            float lyInt = lyIntData[index];
            float lyMin = lyMinData[index];
            float rxInt = rxIntData[index];
            float rxMin = rxMinData[index];
            float ryInt = ryIntData[index];
            float ryMin = ryMinData[index];
            
            float lx = (lxInt + lxMin / 1000.f);
            float ly = leftSrcSize.t - (lyInt + lyMin / 1000.f);
            float rx = (rxInt + rxMin / 1000.f);
            float ry = leftSrcSize.t - (ryInt + ryMin / 1000.f);
            //*/
#ifdef SINGLE_LUT_TEXTURE
            texcoordL = Vec2f{lx / leftSrcSize.s, ly / leftSrcSize.t};
            texcoordR = Vec2f{rx / rightSrcSize.s, ry / rightSrcSize.t};
#else //#ifdef SINGLE_LUT_TEXTURE
            texcoordL = Vec2f{lx / leftSrcSize.s, ly / leftSrcSize.t};
            texcoordR = Vec2f{rx / rightSrcSize.s, ry / rightSrcSize.t};
#endif //#ifdef SINGLE_LUT_TEXTURE
            //                texcoordL = Vec2f{(lxInt) / leftSrcSize.s, (lyInt) / leftSrcSize.t};
            //                texcoordR = Vec2f{(rxInt) / rightSrcSize.s, (ryInt) / rightSrcSize.t};
            
            //                if (texcoordL.s < minL.s) minL.s = texcoordL.s;
            //                if (texcoordL.t < minL.t) minL.t = texcoordL.t;
            //                if (texcoordR.s < minR.s) minR.s = texcoordR.s;
            //                if (texcoordR.t < minR.t) minR.t = texcoordR.t;
            //                if (texcoordL.s > maxL.s) maxL.s = texcoordL.s;
            //                if (texcoordL.t > maxL.t) maxL.t = texcoordL.t;
            //                if (texcoordR.t > maxR.t) maxR.t = texcoordR.t;
            //                if (texcoordR.s > maxR.s) maxR.s = texcoordR.s;
#ifdef SINGLE_LUT_TEXTURE
            *(pDst++) = texcoordL.s;
            *(pDst++) = texcoordL.t;
            *(pDst++) = texcoordR.s;
            *(pDst++) = texcoordR.t;
#else //#ifdef SINGLE_LUT_TEXTURE
            setRGBOfLUTTexel(&pDstTextureDataLS, lx, leftSrcSize.width);
            setRGBOfLUTTexel(&pDstTextureDataLT, ly, leftSrcSize.height);
            setRGBOfLUTTexel(&pDstTextureDataRS, rx, rightSrcSize.width);
            setRGBOfLUTTexel(&pDstTextureDataRT, ry, rightSrcSize.height);
#endif //#ifdef SINGLE_LUT_TEXTURE
        }
    }
#ifndef SINGLE_LUT_TEXTURE
    return textureDatas;
#else //#ifndef SINGLE_LUT_TEXTURE
    return textureData;
#endif //#ifndef SINGLE_LUT_TEXTURE
}

void* MadvGLRendererImpl::setLUTData(Vec2f lutDstSize, Vec2f leftSrcSize,Vec2f rightSrcSize, int dataSizeInShort, const GLushort* lxIntData, const GLushort* lxMinData, const GLushort* lyIntData, const GLushort* lyMinData, const GLushort* rxIntData, const GLushort* rxMinData, const GLushort* ryIntData, const GLushort* ryMinData) {
    _lutQuadMesh = Mesh3D::createRedundantGrids(2.f, 2.f, _longitudeSegments, _latitudeSegments,_latitudeSegments, false, false);
    _lutSphereMesh = Mesh3D::createSphereV0(SPHERE_RADIUS, _longitudeSegments, _latitudeSegments, false, false);
    _lutQuadVAO = NULL;
    _lutSphereVAO = NULL;
    convertMesh3DWithLUT(_lutQuadMesh, lutDstSize, leftSrcSize, rightSrcSize, dataSizeInShort, lxIntData, lxMinData, lyIntData, lyMinData, rxIntData, rxMinData, ryIntData, ryMinData);
    convertMesh3DWithLUT(_lutSphereMesh, lutDstSize, leftSrcSize, rightSrcSize, dataSizeInShort, lxIntData, lxMinData, lyIntData, lyMinData, rxIntData, rxMinData, ryIntData, ryMinData);
    
    void* textureData = createLUTData(lutDstSize, leftSrcSize, rightSrcSize, dataSizeInShort, lxIntData, lxMinData, lyIntData, lyMinData, rxIntData, rxMinData, ryIntData, ryMinData);
    setLUTData(lutDstSize, leftSrcSize, rightSrcSize, textureData);
    return textureData;
}

void MadvGLRendererImpl::setLUTData(Vec2f lutDstSize, Vec2f leftSrcSize,Vec2f rightSrcSize, const void* lutTextureData) {
    _lutDstSize = lutDstSize;
    _lutSrcSizeL = leftSrcSize;
    _lutSrcSizeR = rightSrcSize;
    
    if (_lsLutTexture > 0)
    {
        glDeleteTextures(1, (const GLuint*)&_lsLutTexture);
    }
    if (_ltLutTexture > 0)
    {
        glDeleteTextures(1, (const GLuint*)&_ltLutTexture);
    }
    if (_rsLutTexture > 0)
    {
        glDeleteTextures(1, (const GLuint*)&_rsLutTexture);
    }
    if (_rtLutTexture > 0)
    {
        glDeleteTextures(1, (const GLuint*)&_rtLutTexture);
    }
    
    if (_lutTexture > 0)
    {
        glDeleteTextures(1, (const GLuint*)&_lutTexture);
    }
    
    GLint prevTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &prevTexture);
#ifndef SINGLE_LUT_TEXTURE
    GLint* pLUTTextures[4] = {&_lsLutTexture, &_ltLutTexture, &_rsLutTexture, &_rtLutTexture};
    GLubyte* pLUTTextureData = (GLubyte*) lutTextureData;
    int lutComponentDataLength = sizeof(GLubyte) * 3 * lutDstSize.width * lutDstSize.height;
    for (int i=0; i<4; ++i)
    {
        glGenTextures(1, (GLuint*) pLUTTextures[i]);
        glBindTexture(GL_TEXTURE_2D, *pLUTTextures[i]);
        CHECK_GL_ERROR();
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST//GL_LINEAR_MIPMAP_LINEAR
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);//GL_CLAMP_TO_EDGE);//
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);//GL_CLAMP_TO_EDGE);//
        CHECK_GL_ERROR();
        glPixelStorei(GL_PACK_ALIGNMENT, 1);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        CHECK_GL_ERROR();
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, lutDstSize.width, lutDstSize.height, 0, GL_RGB, GL_UNSIGNED_BYTE, pLUTTextureData);
        CHECK_GL_ERROR();
        //    glGenerateMipmap(GL_TEXTURE_2D);
        pLUTTextureData += lutComponentDataLength;
    }
#else //#ifndef SINGLE_LUT_TEXTURE
    GLuint lutTexture;
    glGenTextures(1, &lutTexture);
    glBindTexture(GL_TEXTURE_2D, lutTexture);
    CHECK_GL_ERROR();
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST//GL_LINEAR_MIPMAP_LINEAR
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);//GL_CLAMP_TO_EDGE);//
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);//GL_CLAMP_TO_EDGE);//
    CHECK_GL_ERROR();
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    CHECK_GL_ERROR();
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F_EXT, lutDstSize.width, lutDstSize.height, 0, GL_RGBA, GL_FLOAT, lutTextureData);
    CHECK_GL_ERROR();
    //    glGenerateMipmap(GL_TEXTURE_2D);
    //    free(textureData);
#endif //#ifndef SINGLE_LUT_TEXTURE
    _lutTexture = lutTexture;
    //*/
    glBindTexture(GL_TEXTURE_2D, prevTexture);
}

/*void checkData(void* data, int length, const char* tag) {
 GLubyte* bytes = (GLubyte*) data;
 int checkLength = (length < 8 ? length : 8);
 char head[checkLength * 2 + 1];
 char body[checkLength * 2 + 1];
 char rear[checkLength * 2 + 1];
 
 char* pDst = head;
 for (int i=0; i<checkLength; i++)
 {
 sprintf(pDst, "%02x", bytes[i]);
 pDst += 2;
 }
 pDst = body;
 for (int i=(length-checkLength)/2; i<(length+checkLength)/2; i++)
 {
 sprintf(pDst, "%02x", bytes[i]);
 pDst += 2;
 }
 pDst = rear;
 for (int i=length-checkLength; i<length; i++)
 {
 sprintf(pDst, "%02x", bytes[i]);
 pDst += 2;
 }
 ALOGV("checkData %s: [0 ~ %d] ... [%d ~ %d] ... [%d ~ %d] = : %s ... %s ... %s .", tag, checkLength, (length-checkLength)/2, (length+checkLength)/2 - 1, length-checkLength, length-1, head, body, rear);
 }*/
/*
void MadvGLRendererImpl::clearCachedLUT(const char* lutPath) {
    if (NULL == lutPath) return;
    char* lutFilePath = (char*) malloc(strlen(lutPath) + strlen("/lut.png") + 1);
    sprintf(lutFilePath, "%s/lut.png", lutPath);
    remove(lutFilePath);
    free(lutFilePath);
}
//*/
#define USE_MERGED_LUT_FILE

void MadvGLRendererImpl::prepareLUT(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize) {
    if (NULL == lutPath) return;
    
    int bytesPerComponent = sizeof(GLfloat);
    char* lutFilePath = (char*) malloc(strlen(lutPath) + strlen("/L_x_int.png") + 1);
    pic_data lutDatas[8];
    
#ifndef USE_MERGED_LUT_FILE
    const char* MergedLUTFilePathPattern = "%s/lut.png";
    sprintf(lutFilePath, MergedLUTFilePathPattern, lutPath);
    ifstream ifs(lutFilePath, ios::in | ios::binary);
    if (ifs.fail() == 0)
    {
        int32_t bytes = 0;
        int32_t lutWidth, lutHeight;
        ifs.read((char*)&bytes, sizeof(int32_t));
        ifs.read((char*)&lutWidth, sizeof(int32_t));
        ifs.read((char*)&lutHeight, sizeof(int32_t));
        ALOGE("Before decodeLUT : (w,h) = (%d,%d), bytes=%d", lutWidth, lutHeight, bytes);
        char* lutData = (char*) malloc(bytes);
        ifs.read(lutData, bytes);
        setLUTData(Vec2f{(GLfloat)lutWidth, (GLfloat)lutHeight}, leftSrcSize, rightSrcSize, lutData);
        ALOGE("After decodeLUT : getLUTTexture()=%d, (w,h) = (%d,%d), bytes=%d", getLUTTexture(), lutWidth, lutHeight, bytes);
        free(lutData);
    }
    else
#endif
    {
        const char* LUTFilePathPattern[] = {"%s/l_x_int.png", "%s/l_x_min.png", "%s/l_y_int.png", "%s/l_y_min.png", "%s/r_x_int.png", "%s/r_x_min.png", "%s/r_y_int.png", "%s/r_y_min.png"};
        for (int i=0; i<8; ++i)
        {
            sprintf(lutFilePath, LUTFilePathPattern[i], lutPath);
            int result = decodePNG((char*)lutFilePath, lutDatas + i);
            ALOGE("#Bug3763# lutFilePath = %s, result = %d\n", lutFilePath, result);
            if (result != 0)
            {
                free(lutFilePath);
                return;
            }
            
            unsigned short* pShort = (unsigned short*) lutDatas[i].rgba;
            //        unsigned short min = 10240, max = 0;
            int length = lutDatas[i].width * lutDatas[i].height;
            for (int j=length; j>0; --j)
            {
                unsigned short s = *pShort;
                s = ((s << 8) & 0xff00) | ((s >> 8) & 0x00ff);
                *pShort++ = s;
                
                //            if (s > max) max = s;
                //            if (s < min) min = s;
            }
            //        ALOGE("Data length = %d, min = %d, max = %d", length, min, max);
        }
        
        ALOGE("#Bug3763# lutDstSize = (%d,%d), leftSrcSize = (%f,%f), rightSrcSize = (%f,%f)", lutDatas[0].width, lutDatas[0].height, leftSrcSize.width,leftSrcSize.height, rightSrcSize.width,rightSrcSize.height);
        char* lutData = (char*) setLUTData(Vec2f{(GLfloat)lutDatas[0].width, (GLfloat)lutDatas[0].height}, leftSrcSize, rightSrcSize, lutDatas[0].width * lutDatas[0].height,
                                           (unsigned short*)lutDatas[0].rgba, (unsigned short*)lutDatas[1].rgba, (unsigned short*)lutDatas[2].rgba, (unsigned short*)lutDatas[3].rgba, (unsigned short*)lutDatas[4].rgba, (unsigned short*)lutDatas[5].rgba, (unsigned short*)lutDatas[6].rgba, (unsigned short*)lutDatas[7].rgba);
        for (int i=0; i<8; ++i)
        {
            free(lutDatas[i].rgba);
        }
#ifndef USE_MERGED_LUT_FILE
        sprintf(lutFilePath, MergedLUTFilePathPattern, lutPath);
        int32_t bytes = lutDatas[0].width * lutDatas[0].height * 4 * bytesPerComponent;
        //*
        ofstream ofs(lutFilePath, ios::out | ios::binary);
        int32_t lutWidth = lutDatas[0].width;
        int32_t lutHeight = lutDatas[0].height;
        ofs.write((const char*)&bytes, sizeof(int32_t));
        ofs.write((const char*)&lutWidth, sizeof(int32_t));
        ofs.write((const char*)&lutHeight, sizeof(int32_t));
        ofs.write(lutData, bytes);
        ofs.flush();
        ALOGE("Write LUT data : bytes = %d, flags() = %d, lutFilePath = '%s'", bytes, ofs.flags(), lutFilePath);
        ofs.close();
        ALOGE("Before encodeLUTPNG");
#endif
        /*/
         GLubyte* pDst = (GLubyte*) lutData;
         for (int i=bytes; i>0; i-=4)
         {
         *pDst++ = rand();
         *pDst++ = 0x77;
         *pDst++ = 0x00;
         *pDst++ = 0xff;
         }
         checkData(lutData, bytes, "encodeLUTPNG");
         int encodeResult = encodePNG(lutFilePath, (uint8_t*)lutData, lutDatas[0].width, lutDatas[0].height * bytesPerComponent, 8);
         //        int encodeResult = encodePNG(lutFilePath, (uint8_t*)lutData, lutDatas[0].width, lutDatas[0].height * bytesPerComponent / 2, 8 * 2);
         ALOGE("encodeLUTPNG : encodeResultA  = %d", encodeResult);
         //*/
        free(lutData);
    }
    
    deleteIfTempLUTDirectory(lutPath);
    
    free(lutFilePath);
}

void MadvGLRendererImpl::prepareTextureWithRenderSource(void* renderSource) {
}

void MadvGLRendererImpl::setSourceTextures(/*bool separateSourceTexture, */GLint srcTextureL, GLint srcTextureR, GLenum srcTextureTarget, bool isYUVColorSpace) {
//    _separateSourceTexture = separateSourceTexture;
    _srcTextureL = srcTextureL;
    _srcTextureR = srcTextureR;
    _srcTextureTarget = (0 >= srcTextureTarget) ? GL_TEXTURE_2D : srcTextureTarget;
//    ALOGE("\n#Cubemap# setSourceTextures#A _srcTextureTarget=0x%x\n", _srcTextureTarget);
    _isYUVColorSpace = isYUVColorSpace;
}

void MadvGLRendererImpl::setSourceTextures(/*bool separateSourceTexture, */GLint* srcTextureL, GLint* srcTextureR, GLenum srcTextureTarget, bool isYUVColorSpace) {
//    _separateSourceTexture = separateSourceTexture;
    for (int i=0; i<3; ++i)
    {
        _yuvTexturesL[i] = srcTextureL[i];
        _yuvTexturesR[i] = srcTextureR[i];
    }
    _srcTextureTarget = (0 >= srcTextureTarget) ? GL_TEXTURE_2D : srcTextureTarget;
//    ALOGE("\n#Cubemap# setSourceTextures#B _srcTextureTarget=0x%x\n", _srcTextureTarget);
    _isYUVColorSpace = isYUVColorSpace;
}

void MadvGLRendererImpl::setCapsTexture(GLint texture, GLenum textureTarget) {
    _capsTexture = texture;
    _capsTextureTarget = (0 >= textureTarget) ? GL_TEXTURE_2D : textureTarget;
}

void MadvGLRendererImpl::setGLShaderFlags(int flags) {
	_shaderFlags = flags;

	if (NULL != _glPrograms)
	{
		int maxProgramsCount = (1 << FLAG_BITS) + 1;//Last one for cubemap
		for (int i=0; i<maxProgramsCount-1; ++i)
		{
			_glPrograms[i] = NULL;
		}
	}
}

void MadvGLRendererImpl::prepareGLPrograms() {
    int64_t flags = 0;
    ostringstream shaderPredefinations;

#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
    if (_srcTextureTarget != GL_TEXTURE_2D) {
        flags |= FLAG_IMAGE_EXTERNAL;
        shaderPredefinations << "#extension GL_OES_EGL_image_external : require\n#define EXTERNAL\n#define FOR_520\n";
    }
#endif
	shaderPredefinations << GLSLPredefinedMacros();

    if (_isYUVColorSpace) {
        flags |= FLAG_YUV_COLORSPACE;
        shaderPredefinations << "#define FLAG_YUV_COLORSPACE\n";
    }
    if (_currentDisplayMode & PanoramaDisplayModeLUTInShader)
    {
        flags |= FLAG_STITCH_WITH_LUT_IN_SHADER;
        shaderPredefinations << "#define FLAG_STITCH_WITH_LUT_IN_SHADER\n";
    }
    else if (_currentDisplayMode & PanoramaDisplayModeLUTInMesh)
    {
        flags |= FLAG_STITCH_WITH_LUT_IN_MESH;
        shaderPredefinations << "#define FLAG_STITCH_WITH_LUT_IN_MESH\n";
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
        shaderPredefinations << "#define FLAG_PLAIN_STITCH\n";
    }
    /*
    if ((PanoramaDisplayModeExclusiveMask & _currentDisplayMode) == PanoramaDisplayModeReFlatten)
    {
#if !defined(TARGET_OS_WINDOWS) || TARGET_OS_WINDOWS == 0
        flags |= FLAG_REFLATTENING_IN_VERTEX;
        shaderPredefinations << "#define FLAG_REFLATTENING_IN_VERTEX\n";
#else
		//flags |= FLAG_REFLATTENING_IN_PIXEL;
        //shaderPredefinations << "#define FLAG_REFLATTENING_IN_PIXEL\n";
		flags |= FLAG_REFLATTENING_IN_VERTEX;
		shaderPredefinations << "#define FLAG_REFLATTENING_IN_VERTEX\n";
#endif
    }
    else if ((PanoramaDisplayModeExclusiveMask & _currentDisplayMode) == PanoramaDisplayModeReFlattenInPixel)
    {
        flags |= FLAG_REFLATTENING_IN_PIXEL;
        shaderPredefinations << "#define FLAG_REFLATTENING_IN_PIXEL\n";
    }
//*/
//    if ((PanoramaDisplayModeExclusiveMask & _currentDisplayMode) == PanoramaDisplayModeToCubeMap)
//    {
//        flags |= FLAG_TO_CUBEMAP;
//        shaderPredefinations << "#define FLAG_TO_CUBEMAP\n";
//    }
    
    if (_debugTexcoord)
    {
        flags |= FLAG_DEBUG_TEXCOORD;
        shaderPredefinations << "#define FLAG_DEBUG_TEXCOORD\n";
    }
    
    int64_t shaderProgramIndex;
    const char* fragmentShaderMainSource;
    const char* vertexShaderMainSource;
    if (_currentDisplayMode == PanoramaDisplayModeFromCubeMap)
    {
        shaderProgramIndex = (1 << FLAG_BITS);
        fragmentShaderMainSource = CubeMapToRemappedFragmentShader;
        vertexShaderMainSource = CubeMapToRemappedVertexShader;
    }
    else
    {
        shaderProgramIndex = flags;
        fragmentShaderMainSource = FragmentShaderSource;
        vertexShaderMainSource = VertexShaderSource;
    }

	if (_shaderFlags & GLShaderDebugFlag0)
	{
		shaderPredefinations << "#define DEBUG_FLAG0\n";
	}
	if (_shaderFlags & GLShaderDebugFlag1)
	{
		shaderPredefinations << "#define DEBUG_FLAG1\n";
	}
	if (_shaderFlags & GLShaderDebugFlag2)
	{
		shaderPredefinations << "#define DEBUG_FLAG2\n";
	}

	_currentGLProgram = _glPrograms[shaderProgramIndex];
    if (NULL == _currentGLProgram)
    {
        shaderPredefinations.flush();
        string shaderPredefString = shaderPredefinations.str();
        const char* fragmentShaderSources[2] = {shaderPredefString.c_str(), fragmentShaderMainSource};
        const char* vertexShaderSources[2] = {shaderPredefString.c_str(), vertexShaderMainSource};
        _currentGLProgram = new MadvGLProgram(vertexShaderSources, 2, fragmentShaderSources, 2);
        
        _glPrograms[shaderProgramIndex] = _currentGLProgram;
    }
    glUseProgram(_currentGLProgram->getProgram());
}

void MadvGLRendererImpl::setGLProgramVariables(AutoRef<GLCamera> panoCamera, GLint x, GLint y, GLint width, GLint height, bool withGyroAdust) {
	GLint prevActiveTextureUnit = GL_TEXTURE0;
	glGetIntegerv(GL_ACTIVE_TEXTURE, &prevActiveTextureUnit);
	if (_currentDisplayMode & PanoramaDisplayModeLUTInShader)
    {
#ifdef SINGLE_LUT_TEXTURE
        glUniform1i(_currentGLProgram->getLUTTextureSlot(), 3);
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, _lutTexture);
#else //#ifdef SINGLE_LUT_TEXTURE
        glUniform1i(_currentGLProgram->getLSLutTextureSlot(), 7);
        glActiveTexture(GL_TEXTURE7);
        glBindTexture(GL_TEXTURE_2D, _lsLutTexture);
        
        glUniform1i(_currentGLProgram->getLTLutTextureSlot(), 6);
        glActiveTexture(GL_TEXTURE6);
        glBindTexture(GL_TEXTURE_2D, _ltLutTexture);
        
        glUniform1i(_currentGLProgram->getRSLutTextureSlot(), 5);
        glActiveTexture(GL_TEXTURE5);
        glBindTexture(GL_TEXTURE_2D, _rsLutTexture);
        
        glUniform1i(_currentGLProgram->getRTLutTextureSlot(), 4);
        glActiveTexture(GL_TEXTURE4);
        glBindTexture(GL_TEXTURE_2D, _rtLutTexture);
#endif //#ifdef SINGLE_LUT_TEXTURE
        glUniform2f(_currentGLProgram->getLUTSourceSizeSlot(), _lutSrcSizeL.width, _lutSrcSizeL.height);
    }
    CHECK_GL_ERROR();
    if (_isYUVColorSpace)
    {
        GLint yTextureSlot = _currentGLProgram->getSourceYTextureSlot();
        GLint uTextureSlot = _currentGLProgram->getSourceUTextureSlot();
        GLint vTextureSlot = _currentGLProgram->getSourceVTextureSlot();
        GLint yuvTextureSlots[3] = {yTextureSlot, uTextureSlot, vTextureSlot};
        for (int i = 0; i < 3; ++i)
        {
            glUniform1i(yuvTextureSlots[i], i);
            glActiveTexture(GL_TEXTURE0 + i);
            glBindTexture(GL_TEXTURE_2D, _yuvTexturesL[i]);
        }
        /*
        if (_currentGLProgram->getRightYTextureSlot() >= 0)
        {
            GLint yTextureSlotR = _currentGLProgram->getRightYTextureSlot();
            GLint uTextureSlotR = _currentGLProgram->getRightUTextureSlot();
            GLint vTextureSlotR = _currentGLProgram->getRightVTextureSlot();
            GLint yuvTextureSlotsR[3] = {yTextureSlotR, uTextureSlotR, vTextureSlotR};
            for (int i = 0; i < 3; ++i)
            {
                glUniform1i(yuvTextureSlotsR[i], i + 3);
                glActiveTexture(GL_TEXTURE0 + i + 3);
                glBindTexture(GL_TEXTURE_2D, _yuvTexturesR[i]);
            }
        }
        //*/
    }
    else
    {
		int textureUnitIndex = (GL_TEXTURE_CUBE_MAP == _srcTextureTarget ? 5 : 0);
		glUniform1i(_currentGLProgram->getSourceTextureSlot(), textureUnitIndex);
		glActiveTexture(GL_TEXTURE0 + textureUnitIndex);
        glBindTexture(_srcTextureTarget, _srcTextureL);
        //ALOGE("\n#Cubemap# glActiveTexture(GL_TEXTURE0), with target 0x%x\n", _srcTextureTarget);
        CHECK_GL_ERROR();
        /*
        if (_currentGLProgram->getRightTextureSlot() >= 0)
        {
            glUniform1i(_currentGLProgram->getRightTextureSlot(), 1);
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(_srcTextureTarget, _srcTextureR);
            CHECK_GL_ERROR();
        }
        //*/
    }
    
    //#ifdef SPHERE_RENDERING
    kmMat4 projection;
	AutoRef<GLCamera> glCamera = panoCamera;
    if (NULL == glCamera)
    {
        glCamera = new GLCamera;
    }
    switch (_currentDisplayMode & PanoramaDisplayModeExclusiveMask)
    {
        case PanoramaDisplayModeSphere:
        {
            glCamera->setWidth(width);
            glCamera->setHeight(height);
            /*
             _glCamera->getProjectionMatrix(&projection);
             /*/
            GLCamera::getProjectionMatrix(&projection, SPHERE_RADIUS, -SPHERE_RADIUS, glCamera->getFOVDegree(), (float)width/(float)height, 0.f, SPHERE_RADIUS);
            //*/
            break;
        }
        case PanoramaDisplayModeStereoGraphic:
        {
            glCamera->setWidth(width);
            glCamera->setHeight(height);
            glCamera->setZFar(-65536);
            glCamera->setZNear(SPHERE_RADIUS);
            /*
             _glCamera->getStereoGraphicProjectionMatrix(&projection);
             /*/
            GLCamera::getProjectionMatrix(&projection, SPHERE_RADIUS, -SPHERE_RADIUS, glCamera->getFOVDegree(), (float)width/(float)height, SPHERE_RADIUS, SPHERE_RADIUS);
            //*/
            break;
        }
        case PanoramaDisplayModeLittlePlanet:
        {
            /*
             _glCamera->setWidth(width);
             _glCamera->setHeight(height);
             _glCamera->setZFar(65536);
             _glCamera->setZNear(SPHERE_RADIUS);
             _glCamera->getLittlePlanetProjectionMatrix(&projection);
             /*/
            GLCamera::getProjectionMatrix(&projection, SPHERE_RADIUS, -SPHERE_RADIUS, glCamera->getFOVDegree() * 2.f, (float)width/(float)height, SPHERE_RADIUS, SPHERE_RADIUS);
            //*/
            break;
        }
        case PanoramaDisplayModeCrystalBall:
        {
            //ALOGE("GLCamera::getProjectionMatrix(kmMat4* projectionMatrix, float zNear, float zFar, float fovDegreeX=%f, float aspectRatio=%d/%d=%f, float zEye=%f, float cutRadius=0)", (float)glCamera->getFOVDegree(), width, height, (float)width/(float)height, SPHERE_RADIUS*1.2f);
            GLCamera::getProjectionMatrix(&projection, SPHERE_RADIUS, -SPHERE_RADIUS, glCamera->getFOVDegree(), (float)width/(float)height, SPHERE_RADIUS*1.35, 0.f);
            break;
        }
        default:
        {
            kmMat4Identity(&projection);
            break;
        }
    }
    glUniformMatrix4fv(_currentGLProgram->getProjectionMatrixSlot(), 1, 0, projection.mat);
    
    CHECK_GL_ERROR();
    
    kmMat4 modelMatrix;
    kmMat4Identity(&modelMatrix);
    glUniformMatrix4fv(_currentGLProgram->getModelMatrixSlot(), 1, 0, modelMatrix.mat);
    
    kmMat4 cameraMatrix;
    switch (_currentDisplayMode & PanoramaDisplayModeExclusiveMask)
    {
        case PanoramaDisplayModePlain:
            kmMat4Identity(&cameraMatrix);
            break;
        default:
            //ALOGE("#GyroVideo# projection#0 = {%.3f, %.3f, %.3f, %.3f;  %.3f, %.3f, %.3f, %.3f;  %.3f, %.3f, %.3f, %.3f;  %.3f, %.3f, %.3f, %.3f;}", projection.mat[0],projection.mat[1],projection.mat[2],projection.mat[3],projection.mat[4],projection.mat[5],projection.mat[6],projection.mat[7],projection.mat[8],projection.mat[9],projection.mat[10],projection.mat[11],projection.mat[12],projection.mat[13],projection.mat[14],projection.mat[15]);
            glCamera->getViewMatrix(&cameraMatrix);//, &projection);
            //ALOGE("#GyroVideo# cameraMatrix#0 = {%.3f, %.3f, %.3f, %.3f;  %.3f, %.3f, %.3f, %.3f;  %.3f, %.3f, %.3f, %.3f;  %.3f, %.3f, %.3f, %.3f;}", cameraMatrix.mat[0],cameraMatrix.mat[1],cameraMatrix.mat[2],cameraMatrix.mat[3],cameraMatrix.mat[4],cameraMatrix.mat[5],cameraMatrix.mat[6],cameraMatrix.mat[7],cameraMatrix.mat[8],cameraMatrix.mat[9],cameraMatrix.mat[10],cameraMatrix.mat[11],cameraMatrix.mat[12],cameraMatrix.mat[13],cameraMatrix.mat[14],cameraMatrix.mat[15]);
            if (!GLCamera::checkRotationMatrix(&cameraMatrix, true, "cameraMatrix"))
            {
                ALOGE("#GyroVideo# Check cameraMatrix failed");
            }
            break;
    }
    glUniformMatrix4fv(_currentGLProgram->getCameraMatrixSlot(), 1, 0, cameraMatrix.mat);
    
    CHECK_GL_ERROR();
    
    Orientation2D sourceOrientation = OrientationNormal;
    if (_flipY)
    {
        if (_flipX)
        {
            sourceOrientation = OrientationRotate180Degree;
        }
        else
        {
            sourceOrientation = OrientationRotate180DegreeMirror;
        }
    }
    else if (_flipX)
    {
        sourceOrientation = OrientationMirror;
    }
    kmMat4 screenMatrix;
    Vec2f viewportOrigin = {(GLfloat)x, (GLfloat)y}, viewportSize = {(GLfloat)width, (GLfloat)height};
    Vec2f boundRectOrigin = {(GLfloat)x, (GLfloat)y}, boundRectSize = {(GLfloat)width, (GLfloat)height};
    transformMatrix4InNormalizedCoordSystem2D(screenMatrix.mat, viewportOrigin, viewportSize, boundRectOrigin, boundRectSize, sourceOrientation);
    glUniformMatrix4fv(_currentGLProgram->getScreenMatrixSlot(), 1, 0, screenMatrix.mat);
    
    glUniformMatrix4fv(_currentGLProgram->getTextureMatrixSlot(), 1, 0, _textureMatrix.mat);
    glUniformMatrix4fv(_currentGLProgram->getIllusionTextureMatrixSlot(), 1, 0, _illusionTextureMatrix.mat);
    
    kmMat4 SPCMMatrix, CMMatrix, invCMMatrix;
    //    ALOGE("#GyroVideo# cameraMatrix = {%.3f, %.3f, %.3f, %.3f;  %.3f, %.3f, %.3f, %.3f;  %.3f, %.3f, %.3f, %.3f;  %.3f, %.3f, %.3f, %.3f;}", cameraMatrix.mat[0],cameraMatrix.mat[1],cameraMatrix.mat[2],cameraMatrix.mat[3],cameraMatrix.mat[4],cameraMatrix.mat[5],cameraMatrix.mat[6],cameraMatrix.mat[7],cameraMatrix.mat[8],cameraMatrix.mat[9],cameraMatrix.mat[10],cameraMatrix.mat[11],cameraMatrix.mat[12],cameraMatrix.mat[13],cameraMatrix.mat[14],cameraMatrix.mat[15]);
    kmMat4Multiply(&CMMatrix, &cameraMatrix, &modelMatrix);
    /*if (PanoramaDisplayModeReFlatten == (_currentDisplayMode & PanoramaDisplayModeExclusiveMask)
        || PanoramaDisplayModeReFlattenInPixel == (_currentDisplayMode & PanoramaDisplayModeExclusiveMask))
    {
        kmMat4Assign(&invCMMatrix, &CMMatrix);
        kmMat4Inverse(&CMMatrix, &CMMatrix);
    }
    else//*/
    {
        kmMat4Inverse(&invCMMatrix, &CMMatrix);
    }
    ///!!!For Debug:
    //kmMat4RotationX(&CMMatrix, M_PI/2);
    glUniformMatrix4fv(_currentGLProgram->getCMMatrixSlot(), 1, 0, CMMatrix.mat);
    glUniformMatrix4fv(_currentGLProgram->getInverseCMMatrixSlot(), 1, 0, invCMMatrix.mat);
    if (///PanoramaDisplayModeReFlatten == (_currentDisplayMode & PanoramaDisplayModeExclusiveMask) ||
        ///PanoramaDisplayModeReFlattenInPixel == (_currentDisplayMode & PanoramaDisplayModeExclusiveMask) ||
        PanoramaDisplayModeFromCubeMap == (_currentDisplayMode & PanoramaDisplayModeExclusiveMask) ||
        PanoramaDisplayModePlain == (_currentDisplayMode & PanoramaDisplayModeExclusiveMask))
    {
        kmMat4Assign(&SPCMMatrix, &screenMatrix);
    }
    else
    {
        kmMat4Multiply(&SPCMMatrix, &projection, &CMMatrix);
        kmMat4Multiply(&SPCMMatrix, &screenMatrix, &SPCMMatrix);
    }
    glUniformMatrix4fv(_currentGLProgram->getSPCMMatrixSlot(), 1, 0, SPCMMatrix.mat);
    /*if (_currentDisplayMode == PanoramaDisplayModeFromCubeMap)
    {
        ALOGE("\n#Cubemap# invCMMatrix #%d: %.3f, %.3f, %.3f, %.3f; %.3f, %.3f, %.3f, %.3f; %.3f, %.3f, %.3f, %.3f; %.3f, %.3f, %.3f, %.3f; \n", _currentGLProgram->getInverseCMMatrixSlot(),
          invCMMatrix.mat[0], invCMMatrix.mat[1], invCMMatrix.mat[2], invCMMatrix.mat[3], invCMMatrix.mat[4], invCMMatrix.mat[5], invCMMatrix.mat[6], invCMMatrix.mat[7],
          invCMMatrix.mat[8], invCMMatrix.mat[9], invCMMatrix.mat[10], invCMMatrix.mat[11], invCMMatrix.mat[12], invCMMatrix.mat[13], invCMMatrix.mat[14], invCMMatrix.mat[15]);
    }//*/
    GLint uni_dstSize = _currentGLProgram->getDstSizeSlot();
    GLint uni_srcSizeL = _currentGLProgram->getLeftSrcSizeSlot();
    GLint uni_srcSizeR = _currentGLProgram->getRightSrcSizeSlot();
    glUniform2f(uni_dstSize, _lutDstSize.width, _lutDstSize.height);
    glUniform2f(uni_srcSizeL, _lutSrcSizeL.width, _lutSrcSizeL.height);
    glUniform2f(uni_srcSizeR, _lutSrcSizeR.width, _lutSrcSizeR.height);
    
    glUniform2f(_currentGLProgram->getDiffTexcoordSlot(), 1.f / _longitudeSegments, 1.f / _latitudeSegments);
    
    glUniform1i(_currentGLProgram->getRowsSlot(), _latitudeSegments);
    glUniform1i(_currentGLProgram->getColumnsSlot(), _longitudeSegments);
    
    CHECK_GL_ERROR();
    
    if (_enableDebug)
    {
        //*/ Polar Axis:
        {
            kmVec4 northPolar = glCamera->_debugGetNorthPolar();
            kmVec4 southPolar = glCamera->_debugGetSouthPolar();
            ALOGE("#GLCamera# Polar 0 north={%.3f, %.3f, %.3f}, south={%.3f, %.3f, %.3f}", northPolar.x, northPolar.y, northPolar.z, southPolar.x, southPolar.y, southPolar.z);
            //kmVec4Scale(&northPolar, &northPolar, SPHERE_RADIUS);
            //kmVec4Scale(&southPolar, &southPolar, SPHERE_RADIUS);
            //northPolar.w = 1.f;
            //southPolar.w = 1.f;
            //northPolar.z = 0.f;
            //southPolar.z = 0.f;
            ALOGE("#GLCamera# Polar 1 north={%.3f, %.3f, %.3f}, south={%.3f, %.3f, %.3f}", northPolar.x, northPolar.y, northPolar.z, southPolar.x, southPolar.y, southPolar.z);
            P4C4T2f line[] = {P4C4T2fMake(southPolar.x, southPolar.y, southPolar.z, 1.f, 1.f, 0.f, 0.f, 1.f, 0.f, 0.f),
                P4C4T2fMake(northPolar.x, northPolar.y, northPolar.z, 1.f, 0.f, 1.f, 0.f, 1.f, 0.f, 0.f)};
            Mesh3DRef mesh = Mesh3D::createMeshWithContinuousVertices(line, 2, GL_LINE_STRIP);
            GLVAORef vao = getDebugPrimitive(0);
            if (NULL != vao)
            {
                vao->refreshData(mesh, GL_DYNAMIC_DRAW);
            }
            else
            {
                setDebugPrimitive(mesh, 0);
            }
        }
        //*/
        /*/ Camera Rotation Matrix:
         {
         kmMat4 cameraRotation = _glCamera->_debugGetCameraRotation();
         kmVec4 X = {SPHERE_RADIUS,0,0,1};
         kmVec4 Y = {0,SPHERE_RADIUS,0,1};
         kmVec4 Z = {0,0,SPHERE_RADIUS,1};
         kmVec4Transform(&X, &X, &cameraRotation);
         kmVec4Transform(&Y, &Y, &cameraRotation);
         kmVec4Transform(&Z, &Z, &cameraRotation);
         kmVec4Transform(&X, &X, &projection);
         kmVec4Transform(&Y, &Y, &projection);
         kmVec4Transform(&Z, &Z, &projection);
         kmVec4Scale(&X, &X, 1.f / X.w);
         kmVec4Scale(&Y, &Y, 1.f / Y.w);
         kmVec4Scale(&Z, &Z, 1.f / Z.w);
         P4C4T2f pX = P4C4T2fMake(X.x,X.y,X.z,1.f, 1.f,0.f,0.f,1.f, 0.f,0.f);
         P4C4T2f pY = P4C4T2fMake(Y.x,Y.y,Y.z,1.f, 1.f,0.f,0.f,1.f, 0.f,0.f);
         P4C4T2f pZ = P4C4T2fMake(Z.x,Z.y,Z.z,1.f, 1.f,0.f,0.f,1.f, 0.f,0.f);
         P4C4T2f pO = P4C4T2fMake(0.f,0.f,0.f,1.f, 0.f,0.f,0.f,0.f, 0.f,0.f);
         P4C4T2f lines[] = {pO, pX,
         pO, pY,
         pO, pZ,
         pX, pY,
         pZ, pY,
         pX, pZ,
         };
         int i = 0;
         for (i=1; i<2; ++i)
         {
         lines[i].r = 1.f;
         lines[i].g = 0.f;
         lines[i].b = 0.f;
         lines[i].a = 1.f;
         }
         for (i=3; i<4; ++i)
         {
         lines[i].g = 1.f;
         lines[i].r = 0.f;
         lines[i].b = 0.f;
         lines[i].a = 1.f;
         }
         for (i=5; i<6; ++i)
         {
         lines[i].b = 1.f;
         lines[i].g = 0.f;
         lines[i].r = 0.f;
         lines[i].a = 1.f;
         }
         for (; i<12; ++i)
         {
         lines[i].r = 1.f;
         lines[i].g = 1.f;
         lines[i].b = 1.f;
         lines[i].a = 0.7f;
         }
         Mesh3DRef mesh = Mesh3D::createMeshWithContinuousVertices(lines, sizeof(lines) / sizeof(P4C4T2f), GL_LINES);
         GLVAORef vao = getDebugPrimitive(1);
         if (NULL != vao)
         {
         vao->refreshData(mesh, GL_DYNAMIC_DRAW);
         }
         else
         {
         setDebugPrimitive(mesh, 1);
         }
         }
         //*/
    }
	glActiveTexture(prevActiveTextureUnit);
}

void MadvGLRendererImpl::updateSourceTextureIfNecessary() {
    bool shouldUpdateTexture = false;
    void* currentRenderSource = NULL;
    pthread_mutex_lock(&_mutex);
    {
        if (_renderSource && _needRenderNewSource)
        {
            shouldUpdateTexture = true;
            _needRenderNewSource = false;
            currentRenderSource = _renderSource;
        }
    }
    pthread_mutex_unlock(&_mutex);
    if (shouldUpdateTexture)
    {
        prepareTextureWithRenderSource(currentRenderSource);
    }
}

void MadvGLRendererImpl::drawPrimitives() {
    _currentVAO->drawMadvMesh(_currentGLProgram->getPositionSlot(), _currentGLProgram->getVertexRoleSlot(), _currentGLProgram->getGridCoordSlot());
    //    _currentVAO->drawVAO(_currentGLProgram->getPositionSlot(), _currentGLProgram->getColorSlot(), _currentGLProgram->getTexcoordSlot());
    
    if (_drawCaps &&
        (PanoramaDisplayModePlain != (_currentDisplayMode & PanoramaDisplayModeExclusiveMask)) &&
        (PanoramaDisplayModeFromCubeMap != (_currentDisplayMode & PanoramaDisplayModeExclusiveMask)))
    {
        glUniform1i(_currentGLProgram->getSourceTextureSlot(), 4);
        glActiveTexture(GL_TEXTURE4);
        glBindTexture(_capsTextureTarget, _capsTexture);
        /*
        if (_currentGLProgram->getRightTextureSlot() >= 0)
        {
            glUniform1i(_currentGLProgram->getRightTextureSlot(), 6);
            glActiveTexture(GL_TEXTURE6);
            glBindTexture(_capsTextureTarget, _capsTexture);
        }
        //*/
        _capsVAO->drawMadvMesh(_currentGLProgram->getPositionSlot(), _currentGLProgram->getVertexRoleSlot(), _currentGLProgram->getTexcoordSlot());
        CHECK_GL_ERROR();
    }
}

void MadvGLRendererImpl::draw(AutoRef<GLCamera> panoCamera, GLint x, GLint y, GLint width, GLint height) {
    Mesh3DRef currentMesh;
    GLVAORef* pCurrentVAO = NULL;
    switch (_currentDisplayMode & PanoramaDisplayModeExclusiveMask)
    {
        case PanoramaDisplayModeFromCubeMap:
            currentMesh = _trivialMesh;
            pCurrentVAO = &_trivialVAO;
            break;
        case PanoramaDisplayModePlain:
            if (_currentDisplayMode & PanoramaDisplayModeLUTInMesh)
            {
                currentMesh = _lutQuadMesh;
                pCurrentVAO = &_lutQuadVAO;
            }
            else
            {
                currentMesh = _quadMesh;
                pCurrentVAO = &_quadVAO;
            }
            break;
        default:
            if (_currentDisplayMode & PanoramaDisplayModeLUTInMesh)
            {
                currentMesh = _lutSphereMesh;
                pCurrentVAO = &_lutSphereVAO;
            }
            else
            {
                currentMesh = _sphereMesh;
                pCurrentVAO = &_sphereVAO;
            }
            break;
    }
    
    if (NULL == *pCurrentVAO)
    {
        *pCurrentVAO = new GLVAO(currentMesh, GL_STATIC_DRAW);
    }
    _currentVAO = *pCurrentVAO;
    
    switch (_currentDisplayMode & PanoramaDisplayModeExclusiveMask)
    {
        case PanoramaDisplayModePlain:
        case PanoramaDisplayModeFromCubeMap:
            break;
        default:
            if (NULL == _capsVAO)
            {
                _capsVAO = new GLVAO(_capsMesh, GL_STATIC_DRAW);
            }
            break;
    }
    
    updateSourceTextureIfNecessary();
    //*///!!!
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    
    prepareGLCanvas(x,y, width,height);
    CHECK_GL_ERROR();
    //    ALOGE("prepareGLCanvas(%d,%d, %d,%d)",x,y,width,height);
    
    prepareGLPrograms();
    CHECK_GL_ERROR();
    setGLProgramVariables(panoCamera, x,y, width,height, true);

    if (_currentDisplayMode & PanoramaDisplayModeLUTInMesh)
    {
        _currentVAO->drawMadvLUTMappedMesh(_currentGLProgram->getPositionSlot(), _currentGLProgram->getLeftTexcoordSlot(), _currentGLProgram->getRightTexcoordSlot(), _currentGLProgram->getGridCoordSlot());
    }
    else
    {
        _currentVAO->drawMadvMesh(_currentGLProgram->getPositionSlot(), _currentGLProgram->getVertexRoleSlot(), _currentGLProgram->getGridCoordSlot());
        //    _currentVAO->drawVAO(_currentGLProgram->getPositionSlot(), _currentGLProgram->getColorSlot(), _currentGLProgram->getTexcoordSlot());
    }
    
    if (_drawCaps &&
        (PanoramaDisplayModePlain != (_currentDisplayMode & PanoramaDisplayModeExclusiveMask)) &&
        (PanoramaDisplayModeFromCubeMap != (_currentDisplayMode & PanoramaDisplayModeExclusiveMask))
        )
    {
        int prevSrcTextureL = _srcTextureL;
        int prevSrcTextureR = _srcTextureR;
        int prevSrcTextureTarget = _srcTextureTarget;
        bool prevIsYUVColorSpace = _isYUVColorSpace;
        int prevDisplayMode = _currentDisplayMode;
        
        setSourceTextures(_capsTexture, _capsTexture, _capsTextureTarget, false);
        _currentDisplayMode = (_currentDisplayMode & (~PanoramaDisplayModeLUTInShader)) & (~PanoramaDisplayModeLUTInMesh);
        prepareGLPrograms();
        setGLProgramVariables(panoCamera, x,y, width,height, false);
        _capsVAO->drawMadvMesh(_currentGLProgram->getPositionSlot(), _currentGLProgram->getVertexRoleSlot(), _currentGLProgram->getGridCoordSlot());
        CHECK_GL_ERROR();
        
        setSourceTextures(prevSrcTextureL, prevSrcTextureR, prevSrcTextureTarget, prevIsYUVColorSpace);
        _currentDisplayMode = prevDisplayMode;
    }
    
    if (_enableDebug && _debugVAOs.size() > 0)
    {
        if (NULL == _debugGLProgram)
        {
            _debugGLProgram = new GLProgram(&TrivalVertexShaderSource,1, &TrivalFragmentShaderSource,1);
        }
        glUseProgram(_debugGLProgram->getProgram());
        
        for (map<int, GLVAORef>::iterator iter = _debugVAOs.begin(); iter != _debugVAOs.end(); ++iter)
        {
            GLVAORef vao = iter->second;
            vao->draw(_debugGLProgram->getPositionSlot(), _debugGLProgram->getColorSlot(), _debugGLProgram->getTexcoordSlot());
        }
    }
    
    CHECK_GL_ERROR();
    glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
    glDisable(GL_CULL_FACE);
#ifdef USE_MSAA
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, _framebuffer);
    glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, _msaaFramebuffer);
    glResolveMultisampleFramebufferAPPLE();
    
    if (_supportDiscardFramebuffer)
    {
        const GLenum discards[]  = {GL_COLOR_ATTACHMENT0,GL_DEPTH_ATTACHMENT};
        glDiscardFramebuffer(GL_READ_FRAMEBUFFER_APPLE,2,discards);
    }
#endif
    //*/
}

void MadvGLRendererImpl::draw(int displayMode, AutoRef<GLCamera> panoCamera, int x, int y, int width, int height, /*bool separateSourceTextures, */int srcTextureType, int leftSrcTexture, int rightSrcTexture) {
    setDisplayMode(displayMode);
    setSourceTextures(/*separateSourceTextures, */leftSrcTexture, rightSrcTexture, srcTextureType, false);
    draw(panoCamera, x, y, width, height);
}

void MadvGLRendererImpl::draw(int displayMode, AutoRef<GLCamera> panoCamera, int x, int y, int width, int height, /*bool separateSourceTextures, */int srcTextureType, int* leftSrcYUVTextures, int* rightSrcYUVTextures) {
    setDisplayMode(displayMode);
    setSourceTextures(/*separateSourceTextures, */leftSrcYUVTextures, rightSrcYUVTextures, srcTextureType, true);
    draw(panoCamera, x, y, width, height);
}

void MadvGLRendererImpl::drawCubeMapFace(GLenum targetFace, GLint x, GLint y, GLint width, GLint height) {
    AutoRef<GLCamera> camera = new GLCamera;
    camera->setFOVDegree(90);
    
    kmMat4 cameraRotationMatrix;
    switch (targetFace)
    {
        case GL_TEXTURE_CUBE_MAP_POSITIVE_X:
            kmMat4RotationY(&cameraRotationMatrix, -M_PI/2.f);
            break;
        case GL_TEXTURE_CUBE_MAP_NEGATIVE_X:
            kmMat4RotationY(&cameraRotationMatrix, M_PI/2.f);
            break;
        case GL_TEXTURE_CUBE_MAP_POSITIVE_Y:
            kmMat4RotationX(&cameraRotationMatrix, M_PI/2.f);
            break;
        case GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:
            kmMat4RotationX(&cameraRotationMatrix, -M_PI/2.f);
            break;
        case GL_TEXTURE_CUBE_MAP_POSITIVE_Z:
            kmMat4RotationY(&cameraRotationMatrix, M_PI);
            break;
        case GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:
            kmMat4Identity(&cameraRotationMatrix);
            break;
        default:
            kmMat4Identity(&cameraRotationMatrix);
            break;
    }
    camera->setCameraRotationMatrix(&cameraRotationMatrix, false);
    
    int prevDisplayMode = getDisplayMode();
    setDisplayMode((prevDisplayMode & (~PanoramaDisplayModeExclusiveMask)) | PanoramaDisplayModeSphere);
    draw(camera, x, y, width, height);
    setDisplayMode(prevDisplayMode);
}
/*
 AutoRef<GLRenderTexture> MadvGLRenderer::drawToCubemapFaces(AutoRef<GLRenderTexture> cubemapFacesTexture, GLint faceWidth, GLint faceHeight) {
 if (NULL != cubemapFacesTexture)
 {
 cubemapFacesTexture->resizeIfNecessary(faceWidth * 6, faceHeight);
 }
 else
 {
 cubemapFacesTexture = new GLRenderTexture(faceWidth * 6, faceHeight);
 }
 cubemapFacesTexture->blit();
 
 GLint viewport[4];
 glGetIntegerv(GL_VIEWPORT, viewport);
 glViewport(0, 0, faceWidth * 6, faceHeight);
 CHECK_GL_ERROR();
 drawCubeMapFace(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, 0, faceWidth, faceHeight);
 drawCubeMapFace(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, faceWidth, 0, faceWidth, faceHeight);
 drawCubeMapFace(GL_TEXTURE_CUBE_MAP_POSITIVE_X, faceWidth * 2, 0, faceWidth, faceHeight);
 drawCubeMapFace(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, faceWidth * 3, 0, faceWidth, faceHeight);
 drawCubeMapFace(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, faceWidth * 4, 0, faceWidth, faceHeight);
 drawCubeMapFace(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, faceWidth * 5, 0, faceWidth, faceHeight);
 CHECK_GL_ERROR();
 glFlush();
 
 glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
 if (NULL != cubemapFacesTexture)
 {
 cubemapFacesTexture->unblit();
 }
 return cubemapFacesTexture;
 }
 //*/
void MadvGLRendererImpl::drawFromCubemap(AutoRef<GLCamera> camera, int x, int y, int width, int height, GLint sourceCubemapTexture) {
    int prevDisplayMode = _currentDisplayMode;
    int prevSourceTextureTarget = _srcTextureTarget;
    int prevSourceTextureL = _srcTextureL;
    int prevSourceTextureR = _srcTextureR;
    int prevIsYUVColorSpace = _isYUVColorSpace;
    
    draw(PanoramaDisplayModeFromCubeMap, camera, x, y, width, height, GL_TEXTURE_CUBE_MAP, sourceCubemapTexture, sourceCubemapTexture);
    
    setSourceTextures(prevSourceTextureL, prevSourceTextureR, prevSourceTextureTarget, prevIsYUVColorSpace);
    setDisplayMode(prevDisplayMode);
}

//#define DEBUGGING_CUBEMAP

#ifdef DEBUGGING_CUBEMAP

#if defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0
#import "z_Sandbox.h"
#endif

#endif

void MadvGLRendererImpl::resizeCubemap(GLuint cubemapTexture, int cubemapFaceSize) {
    GLint prevCubemapBinding = 0;
    glGetIntegerv(GL_TEXTURE_BINDING_CUBE_MAP, &prevCubemapBinding);

    glBindTexture(GL_TEXTURE_CUBE_MAP, cubemapTexture);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);//https://stackoverflow.com/questions/26647672/npot-support-in-opengl-for-r8g8b8-texture
    glPixelStorei(GL_PACK_ALIGNMENT, 1);//https://stackoverflow.com/questions/26647672/npot-support-in-opengl-for-r8g8b8-texture
	CHECK_GL_ERROR();
    for (GLenum iTarget = 0; iTarget < 6; ++iTarget)
    {
        GLenum target = iTarget + GL_TEXTURE_CUBE_MAP_POSITIVE_X;
        glTexImage2D(target, 0, GL_RGBA, cubemapFaceSize, cubemapFaceSize, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    }
	CHECK_GL_ERROR();
    glBindTexture(GL_TEXTURE_CUBE_MAP, prevCubemapBinding);
}

GLint MadvGLRendererImpl::drawToRemappedCubemap(GLuint cubemapTexture, int cubemapFaceSize) {
    if (0 >= cubemapTexture)
    {
        ///glEnable(GL_TEXTURE_CUBE_MAP);
        CHECK_GL_ERROR();
        glGenTextures(1, &cubemapTexture);
        CHECK_GL_ERROR();
        resizeCubemap(cubemapTexture, cubemapFaceSize);
        CHECK_GL_ERROR();
    }
    CHECK_GL_ERROR();
    bool prevFlipX = getFlipX();
    bool prevFlipY = getFlipY();
    //*///!!!
    GLuint cubemapFaceFramebuffers[6];
    glGenFramebuffers(6, cubemapFaceFramebuffers);
    CHECK_GL_ERROR();
#ifdef DEBUGGING_CUBEMAP
    const char* CubemapFaceNames[] = {"PX","NX", "PY","NY", "PZ","NZ"};
#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
	const char* CubemapFaceFileDirectory = "C:/Madv360/";
	char* cubemapFaceFile = (char*) malloc(strlen(CubemapFaceFileDirectory) + strlen(CubemapFaceNames[0]) + strlen(".jpg") + 1);
	GLubyte* cubemapFacePixels = (GLubyte*)malloc(cubemapFaceSize * cubemapFaceSize * 4);
#endif

#endif
    //int prevGyroMatrixRank = _gyroMatrixRank;
    //setGyroMatrix(_gyroMatrix, 0);
    GLint prevFramebufferBinding = 0;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFramebufferBinding);
    for (GLenum iTarget = 0; iTarget < 6; ++iTarget)
    {
		GLenum target = iTarget + GL_TEXTURE_CUBE_MAP_POSITIVE_X;
        
        glBindFramebuffer(GL_FRAMEBUFFER, cubemapFaceFramebuffers[iTarget]);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, target, cubemapTexture, 0);
        CHECK_GL_ERROR();
        if (GL_TEXTURE_CUBE_MAP_NEGATIVE_Y == target || GL_TEXTURE_CUBE_MAP_POSITIVE_Y == target)
        {
            setFlipY(false);
            setFlipX(false);
        }
        else
        {
            setFlipY(true);
            setFlipX(true);
        }
#ifdef DEBUGGING_CUBEMAP
		GLuint color = iTarget + 1;
		glClearColor(((color >> 2) & 0x01), ((color >> 1) & 0x01), ((color >> 0) & 0x01), 1.f);
		glClear(GL_COLOR_BUFFER_BIT);
		drawCubeMapFace(target, 0, 0, cubemapFaceSize, cubemapFaceSize);
		/*/
		glReadPixels(0, 0, cubemapFaceSize, cubemapFaceSize, GL_RGBA, GL_UNSIGNED_BYTE, cubemapFacePixels);
		color = ((0xff * ((color >> 2) & 0x01)) << 16) | ((0xff * ((color >> 1) & 0x01)) << 8) | ((0xff * ((color >> 0) & 0x01)) << 0) | 0xff000000;
		GLuint* pDst = (GLuint*)cubemapFacePixels;
		for (int i = cubemapFaceSize * cubemapFaceSize - 1; i >= 0; --i)
		{
			*pDst++ = color;
		}
		glTexImage2D(target, 0, GL_RGBA, cubemapFaceSize, cubemapFaceSize, 0, GL_RGBA, GL_UNSIGNED_BYTE, cubemapFacePixels);
		//*/
#else
		drawCubeMapFace(target, 0, 0, cubemapFaceSize, cubemapFaceSize);
#endif
        
		CHECK_GL_ERROR();
        glBindFramebuffer(GL_FRAMEBUFFER, prevFramebufferBinding);
        CHECK_GL_ERROR();
#ifdef DEBUGGING_CUBEMAP

#if defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0
		NSString* destJpegPath = [NSString stringWithFormat:@"%@/%s.jpg", [z_Sandbox docPath], CubemapFaceNames[iTarget]];
        MadvGLRenderer::debugRenderTextureToJPEG(destJpegPath.UTF8String, cubemapFaceSize, cubemapFaceSize, cubemapFaceTexture->getTexture(), NULL, 0, NULL, NULL, 0, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
#elif defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
		//sprintf(cubemapFaceFile, "%s%s.jpg", CubemapFaceFileDirectory, CubemapFaceNames[iTarget]);
		//MadvGLRenderer::debugRenderTextureToJPEG(cubemapFaceFile, cubemapFaceSize, cubemapFaceSize, cubemapFaceTexture->getTexture(), NULL, 0, NULL, NULL, 0, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
#endif

#endif
    }
    
    glDeleteFramebuffers(6, cubemapFaceFramebuffers);
#ifdef DEBUGGING_CUBEMAP

#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
	free(cubemapFaceFile);
	free(cubemapFacePixels);
#endif

#endif

    setFlipY(prevFlipY);
    setFlipX(prevFlipX);
    //setGyroMatrix(_gyroMatrix, prevGyroMatrixRank);
    
    return cubemapTexture;
}

AutoRef<GLRenderTexture> MadvGLRendererImpl::drawCubemapToBuffers(GLubyte* outPixelDatas, GLuint* PBOs, AutoRef<GLRenderTexture> cubemapFaceTexture, int cubemapFaceSize) {
    if (NULL == cubemapFaceTexture)
    {
        CHECK_GL_ERROR();
        cubemapFaceTexture = new GLRenderTexture(0, GL_TEXTURE_2D, cubemapFaceSize, cubemapFaceSize, GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE);
        CHECK_GL_ERROR();
    }
    
    bool prevFlipX = getFlipX();
    bool prevFlipY = getFlipY();
    
    const int CubemapFaceDataSize = cubemapFaceSize * cubemapFaceSize * 4;
    GLint prevPixelPackBuffer = 0;
    GLuint pboArray[] = {0, 0, 0, 0, 0, 0};
    boolean ownPBOs = false;
    if (NULL != outPixelDatas)
    {
        glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING, &prevPixelPackBuffer);
        if (NULL == PBOs)
        {
            ownPBOs = true;
            PBOs = pboArray;
        }
        for (int i=0; i<6; ++i)
        {
            if (0 == PBOs[i])
            {
                glGenBuffers(1, PBOs + i);
                glBindBuffer(GL_PIXEL_PACK_BUFFER, PBOs[i]);
                glBufferData(GL_PIXEL_PACK_BUFFER, CubemapFaceDataSize, NULL, GL_DYNAMIC_READ);///!!!
                CHECK_GL_ERROR();
            }
        }
        glBindBuffer(GL_PIXEL_PACK_BUFFER, prevPixelPackBuffer);
    }
    
    //int prevGyroMatrixRank = _gyroMatrixRank;
    //setGyroMatrix(_gyroMatrix, 0);
    for (GLenum iTarget = 0; iTarget < 6; ++iTarget)
    {
        cubemapFaceTexture->blit();
        
        GLenum target = iTarget + GL_TEXTURE_CUBE_MAP_POSITIVE_X;
        if (GL_TEXTURE_CUBE_MAP_NEGATIVE_Y == target || GL_TEXTURE_CUBE_MAP_POSITIVE_Y == target)
        {
            setFlipY(false);
            setFlipX(false);
        }
        else
        {
            setFlipY(true);
            setFlipX(true);
        }
        drawCubeMapFace(target, 0, 0, cubemapFaceSize, cubemapFaceSize);
        
        if (NULL != outPixelDatas)
        {
            if (iTarget > 0)
            {
                glBindBuffer(GL_PIXEL_PACK_BUFFER, PBOs[iTarget - 1]);
                CHECK_GL_ERROR();
                GLubyte* bufferRead = (GLubyte*)glMapBufferRange(GL_PIXEL_PACK_BUFFER, 0, CubemapFaceDataSize, GL_MAP_READ_BIT);
                CHECK_GL_ERROR();
                memcpy(outPixelDatas + CubemapFaceDataSize * (iTarget - 1), bufferRead, CubemapFaceDataSize);
                glUnmapBuffer(GL_PIXEL_PACK_BUFFER);
            }
            
            glBindBuffer(GL_PIXEL_PACK_BUFFER, PBOs[iTarget]);
            glReadPixels(0, 0, cubemapFaceSize, cubemapFaceSize, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
            CHECK_GL_ERROR();
        }
        
        cubemapFaceTexture->unblit();
        CHECK_GL_ERROR();
    }
    
    if (NULL != outPixelDatas)
    {
        glBindBuffer(GL_PIXEL_PACK_BUFFER, PBOs[5]);
        GLubyte* bufferRead = (GLubyte*)glMapBufferRange(GL_PIXEL_PACK_BUFFER, 0, CubemapFaceDataSize, GL_MAP_READ_BIT);
        memcpy(outPixelDatas + CubemapFaceDataSize * 5, bufferRead, CubemapFaceDataSize);
        glUnmapBuffer(GL_PIXEL_PACK_BUFFER);
        
        glBindBuffer(GL_PIXEL_PACK_BUFFER, prevPixelPackBuffer);
        if (ownPBOs)
        {
            glDeleteBuffers(6, PBOs);
        }
    }
    
    setFlipY(prevFlipY);
    setFlipX(prevFlipX);
    //setGyroMatrix(_gyroMatrix, prevGyroMatrixRank);
    
    return cubemapFaceTexture;
}

AutoRef<GLVAO> MadvGLRendererImpl::getDebugPrimitive(int key) {
    map<int, AutoRef<GLVAO> >::iterator found = _debugVAOs.find(key);
    if (found != _debugVAOs.end())
    {
        return found->second;
    }
    return NULL;
}

void MadvGLRendererImpl::setDebugPrimitive(AutoRef<Mesh3D> mesh, int key) {
    map<int, AutoRef<GLVAO> >::iterator found = _debugVAOs.find(key);
    if (found != _debugVAOs.end())
    {
        _debugVAOs.erase(found);
    }
    AutoRef<GLVAO> vao = new GLVAO(mesh, GL_DYNAMIC_DRAW);
    _debugVAOs.insert(make_pair(key, vao));
}
/*
void MadvGLRendererImpl::extractLUTFiles(const char* destDirectory, const char* lutBinFilePath, uint32_t fileOffset) {
    ifstream ifs(lutBinFilePath, ios::in | ios::binary);
    ALOGE("extractLUTFiles : fileOffset = %u, destDirectory = '%s', lutBinFilePath = '%s'", fileOffset, destDirectory, lutBinFilePath);
    //    fseek(fp, fileOffset, SEEK_CUR);
    const uint32_t Limit2G = 0x80000000;
    if (fileOffset >= Limit2G)
    {
        uint32_t fileOffsetLeft = fileOffset;
        //        ALOGE("extractLUTFiles : #0 fileOffsetLeft = %u", fileOffsetLeft);
        ifs.seekg(0x40000000, ios::beg);
        ifs.seekg(0x40000000, ios::cur);
        for (fileOffsetLeft -= Limit2G; fileOffsetLeft >= Limit2G; fileOffsetLeft -= Limit2G)
        {
            //            ALOGE("extractLUTFiles : #1 fileOffsetLeft = %u", fileOffsetLeft);
            ifs.seekg(0x40000000, ios::cur);
            ifs.seekg(0x40000000, ios::cur);
        }
        //        ALOGE("extractLUTFiles : #2 fileOffsetLeft = %u", fileOffsetLeft);
        ifs.seekg(fileOffsetLeft, ios::cur);
    }
    else
    {
        ifs.seekg(fileOffset, ios::beg);
    }
    
    uint32_t offsets[8];
    uint32_t sizes[8];
    uint32_t totalSize = 0;
    uint32_t maxSize = 0;
    for (int i = 0; i<8; ++i)
    {
        ifs.read((char*)&offsets[i], sizeof(uint32_t));
        ifs.read((char*)&sizes[i], sizeof(uint32_t));
        ALOGE("offsets[%d] = %u, sizes[%d] = %u", i, offsets[i], i, sizes[i]);
        if (sizes[i] > maxSize) maxSize = sizes[i];
        totalSize += sizes[i];
    }
    ifs.close();
    //    ALOGV("totalSize = %u", totalSize);
    
    const char* pngFileNames[] = { "/r_x_int.png", "/r_x_min.png",
        "/r_y_int.png", "/r_y_min.png",
        "/l_x_int.png", "/l_x_min.png",
        "/l_y_int.png", "/l_y_min.png" };
    char* pngFilePath = (char*)malloc(strlen(destDirectory) + strlen(pngFileNames[0]) + 1);
    
    uint8_t* pngData = (uint8_t*)malloc(maxSize);
    ifstream ofs(lutBinFilePath, ios::in | ios::binary);
    //	FILE* fpIn = fopen(lutBinFilePath, "rb");
    if (fileOffset >= Limit2G)
    {
        ofs.seekg(0x40000000, ios::beg);
        ofs.seekg(0x40000000, ios::cur);
        //fseek(fpIn, 0x40000000, SEEK_SET);
        //fseek(fpIn, 0x40000000, SEEK_CUR);
        for (fileOffset -= Limit2G; fileOffset >= Limit2G; fileOffset -= Limit2G)
        {
            ofs.seekg(0x40000000, ios::cur);
            ofs.seekg(0x40000000, ios::cur);
            //fseek(fpIn, 0x40000000, SEEK_CUR);
        }
        ofs.seekg(fileOffset, ios::cur);
        //fseek(fpIn, fileOffset, SEEK_CUR);
    }
    else
    {
        ofs.seekg(fileOffset, ios::beg);
        //fseek(fpIn, fileOffset, SEEK_SET);
    }
    
    uint64_t currentOffset = 0;
    for (int i = 0; i<8; ++i)
    {
        ofs.seekg(offsets[i] - currentOffset, ios::cur);
        //fseek(fpIn, offsets[i] - currentOffset, SEEK_CUR);
        ofs.read((char*)pngData, sizes[i]);
        //fread(pngData, sizes[i], 1, fpIn);
        sprintf(pngFilePath, "%s%s", destDirectory, pngFileNames[i]);
        FILE* fout = fopen(pngFilePath, "wb+");
        fwrite(pngData, sizes[i], 1, fout);
        fclose(fout);
        currentOffset = offsets[i] + sizes[i];
    }
    ofs.close();
    //fclose(fpIn);
    free(pngData);
    free(pngFilePath);
}
//*/

