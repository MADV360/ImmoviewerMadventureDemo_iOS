//
//  MadvGLRenderer.h
//  Created by QiuDong on 16/2/26.
//  Copyright © 2017 MADV360. All rights reserved.
//

#ifndef MadvGLRenderer_hpp
#define MadvGLRenderer_hpp

#include "OpenGLHelper.h"
#include "GLProgram.h"
#include "GLCamera.h"
#include "GLRenderTexture.h"
#include "AutoRef.h"
#include "kazmath.h"

#ifdef DEBUGGING_RENDER

#define LONGITUDE_SEGMENTS  DEBUG_LONGITUDE_SEGMENTS
#define LATITUDE_SEGMENTS   DEBUG_LATITUDE_SEGMENTS

#else //#ifdef DEBUGGING_RENDER

#define LONGITUDE_SEGMENTS   360
#define LATITUDE_SEGMENTS    180

#endif //#ifdef DEBUGGING_RENDER

#ifndef DEFAULT_LUT_VALUE_WIDTH
#define DEFAULT_LUT_VALUE_WIDTH  3456
#endif //DEFAULT_LUT_VALUE_WIDTH
#ifndef DEFAULT_LUT_VALUE_HEIGHT
#define DEFAULT_LUT_VALUE_HEIGHT 1728
#endif //DEFAULT_LUT_VALUE_HEIGHT

typedef void(*MVProgressCallback)(int percent, void* context);

typedef struct {
	MVProgressCallback callback;
	void* context;
} MVProgressClosure;

#ifdef __cplusplus
extern "C" {
#endif
//*
#ifdef MADVPANO_DLL

#ifdef MADVPANO_EXPORTS
#define MADVPANO_API _declspec(dllexport)
#else
#define MADVPANO_API _declspec(dllimport)
#endif

#else // MADVPANO_DLL
#define MADVPANO_API
#endif // MADVPANO_DLL
//*/
/** Panorama Projection Mode */
typedef enum {
    PanoramaDisplayModePlain = 0x00, // No projection, just draw input texture as it is
    PanoramaDisplayModeSphere = 0x01, // Normal mode: Camera at centre of the panorama sphere
    PanoramaDisplayModeLittlePlanet = 0x02, // Asteroid mode: Camera at north pole of the panorama sphere, and with wider FOV
    PanoramaDisplayModeStereoGraphic = 0x03, // Fisheye mode: Camera at back point on the panorama sphere
    PanoramaDisplayModeFromCubeMap = 0x04,
    PanoramaDisplayModeCrystalBall = 0x05,
    ///PanoramaDisplayModeReFlatten = 0x04, // Cylindrical-equidistance projection mode: Project back into a cylindrical-equidistance image, with necessary rotation
    ///PanoramaDisplayModeReFlattenInPixel = 0x05, // // Cylindrical-equidistance projection in pixel mode: Project back into a cylindrical-equidistance image, with necessary rotation, in fragment shader (Not good now. Reserved only)
    //PanoramaDisplayModeToCubeMap = 0x06,
    
    // The following 3 enum values are exclusive, but bit-or ed with the above 6 enum values:
	PanoramaDisplayModeLUTInShader = 0x10, // Stitch with LUT data by shader
    PanoramaDisplayModeLUTInMesh = 0x40, // Stitch with LUT data by CPU
    PanoramaDisplayModePlainStitch = 0x20, // Mode for debugging
    
    PanoramaDisplayModeExclusiveMask = 0x0f, // Mask of the above 3
} PanoramaDisplayMode;

/**
 *  Renderer for panorama content
 *
 *  Take a texture which presents a dual-fisheye or cylindrical-equidistance projection image as input, it draws projected panorama content, with given projection mode.
 *
 *  As for dual-fisheye texture input, the LUT(lookup table) data which is necessary for stitching should be provided as a path to the local directory of extracted LUT data files.
 *  Functions for extract LUT data from MADV360-created JPEG or MP4 files are contained in other classes.
 *
 *  Only OpenGL drawing calls are concerned in it, process of establishing/switching/destroying OpenGL context is up to the SDK's user.
 *
 */
class MADVPANO_API MadvGLRenderer {
    friend class PanoCameraController;
    
public:
    
    virtual ~MadvGLRenderer();
    
    /** Ctor：Create renderer, with prepared LUT data files(if any)
     * LUT data is necessary for stitching dual-fisheye photo or video from MADV360 camera.
     * Functions for extracting LUT data from MP4 box or JPEG EXIF metadata into LUT data files are not concerned in the renderer,
     * please refer to #EXIFParser# and other classes.
     * @param lutPath       Local path of directory which contains extracted LUT data files
     * @param leftSrcSize   Value range of left LUT. Now only 3456x1728 is valid
     * @param rightSrcSize  Value range of right LUT. Now only 3456x1728 is valid
     */
    MadvGLRenderer(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments);
    
	MadvGLRenderer(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize);

//    void setBestMeshSize(GLuint longitudeSegments, GLuint latitudeSegments);

    /** Reassign LUT data input */
    void prepareLUT(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize);
    
    /** Draw in specified rect region with input texture and given projection mode
     * @param displayMode      Valid #PanoramaDisplayMode# value
     * Deprecated @param separateSourceTextures    Whether the input are 2 textures each for one fisheye. But always false now
     * @param srcTextureType   Target of input texture，GL_TEXTURE_2D or GL_TEXTURE_EXTERNAL_OES(usually on Android)
     * @param leftSrcTexture   Left input texture
     * @param rightSrcTexture  Right input texture. For now, it is always the same one as leftSrcTexture
     */
    void draw(int displayMode, int x, int y, int width, int height, /*bool separateSourceTextures, */int srcTextureType, int leftSrcTexture, int rightSrcTexture);
    
    /** Draw in specified rect region with input YUV textures and given projection mode
     * @param displayMode          Valid #PanoramaDisplayMode# value
     * Deprecated @param separateSourceTextures    Whether the input are 2 group of YUV textures, each for one fisheye. But always false now
     * @param srcTextureType       Target of input texture，GL_TEXTURE_2D or GL_TEXTURE_EXTERNAL_OES(usually on Android)
     * @param leftSrcYUVTextures   Left input YUV textures array, [0] for Y, [1] for U, [2] for V
     * @param rightSrcYUVTextures  Right input textures array, [0] for Y, [1] for U, [2] for V. For now, they are always the same as leftSrcYUVTextures
     */
	void draw(int displayMode, int x, int y, int width, int height, /*bool separateSourceTextures, */int srcTextureType, int* leftSrcYUVTextures, int* rightSrcYUVTextures);

    /** State-machine mode drawing. Parameters lacked can be set with previous other function calls */
    void draw(GLint x, GLint y, GLint width, GLint height);
    
    void drawCubeMapFace(GLenum targetFace, GLint x, GLint y, GLint width, GLint height);
    
    ///AutoRef<GLRenderTexture> drawToCubemapFaces(AutoRef<GLRenderTexture> cubemapFacesTexture, GLint faceWidth, GLint faceHeight);
    
    ///static GLuint convertCubemapTexture(GLuint cubemapTexture, AutoRef<GLRenderTexture> cubemapFacesTexture);
    
    void drawFromCubemap(int x, int y, int width, int height, GLint sourceCubemapTexture);
    
    GLint drawToRemappedCubemap(GLuint cubemapTexture, int cubemapFaceSize);
    
    void drawRemappedPanorama(int x, int y, int width, int height, int cubemapFaceSize);
    void drawRemappedPanorama(int lutStitchMode, int x, int y, int width, int height, int cubemapFaceSize,int srcTextureType, int srcTexture);

    AutoRef<GLRenderTexture> drawCubemapToBuffers(GLubyte* outPixelDatas, GLuint* PBOs, AutoRef<GLRenderTexture> cubemapFaceTexture, int cubemapFaceSize);
    
    /** Getter&Setter of #PanoramaDisplayMode# */
    int getDisplayMode();
    void setDisplayMode(int displayMode);
    
    /** Getter&Setter of whether take input texture(s) as YUV textures */
    bool getIsYUVColorSpace();
    void setIsYUVColorSpace(bool isYUVColorSpace);
    
    /** Set input texture
     * Deprecated @param separateSourceTextures    Whether the input are 2 textures each for one fisheye. But always false now
     * @param srcTextureType   Target of input texture，GL_TEXTURE_2D or GL_TEXTURE_EXTERNAL_OES(usually on Android)
     * @param leftSrcTexture   Left input texture
     * @param rightSrcTexture  Right input texture. For now, it is always the same one as leftSrcTexture
     * @param isYUVColorSpace  Always false(this parameter is useless, I should remove it...)
     */
    void setSourceTextures(/*bool separateSourceTexture, */GLint srcTextureL, GLint srcTextureR, GLenum srcTextureTarget, bool isYUVColorSpace);
    
    /** Set input YUV textures
     * Deprecated @param separateSourceTextures    Whether the input are 2 group of YUV textures, each for one fisheye. But always false now
     * @param srcTextureType       Target of input texture，GL_TEXTURE_2D or GL_TEXTURE_EXTERNAL_OES(usually on Android)
     * @param leftSrcYUVTextures   Left input YUV textures array, [0] for Y, [1] for U, [2] for V
     * @param rightSrcYUVTextures  Right input textures array, [0] for Y, [1] for U, [2] for V. For now, they are always the same as leftSrcYUVTextures
     * @param isYUVColorSpace      Always true(this parameter is useless, I should remove it...)
     */
    void setSourceTextures(/*bool separateSourceTexture, */GLint* srcTextureL, GLint* srcTextureR, GLenum srcTextureTarget, bool isYUVColorSpace);
    
    /** 设置源纹理的变换矩阵
     * 常见用途是在某些安卓机型上，由于其不支持NPOT纹理，解码出的纹理图像会有一部分是无效空白区域，
     * 这种情况下可通过SurfaceTexture的方法获得纹理变换矩阵，以得到正确的渲染结果
     */
    void setTextureMatrix(const kmMat4* textureMatrix);

    void setTextureMatrix(const kmMat4* textureMatrix, int videoCaptureResolution);
    
    void setIllusionTextureMatrix(const kmMat4* textureMatrix);
    
    void setIllusionTextureMatrix(const kmMat4* textureMatrix, int videoCaptureResolution);
    
    /** 查询已设置的源纹理相关属性值 */
    GLint getLeftSourceTexture();
    GLint getRightSourceTexture();
    GLenum getSourceTextureTarget();
    
    /** Set gyroscope stabilizer data
     * MADV360 APP can perform anti-shake by applying rotation of camera, which is calculated with data from 6-axis gyroscope in MADV360 camera.
     * APIs for extracting recorded gyro data in EXIF of JPEG or box in MP4 are provided in other place. Please refer to #EXIFParser# and other classes
     * @param matrix   Transform matrix data
     @ @param rank     Rank of the matrix, always be 3
     */
    void setGyroMatrix(float* matrix, int rank);
    
    void setModelPostRotation(kmVec3 fromVector, kmVec3 toVector);
    
    /** 是否要上下镜像 */
    void setFlipY(bool flipY);
    
    void setFlipX(bool flipX);
    
    /** 是否需要绘制底部Logo */
    void setNeedDrawCaps(bool drawCaps);

    /** 设置底部Logo的纹理 */
    void setCapsTexture(GLint texture, GLenum textureTarget);
    
    /** 用任何可用的对象生成纹理并设置为源纹理
     * @param renderSource 用于生成源纹理的无类型对象指针
     * setRenderSource内部调用#prepareTextureWithRenderSource#方法从无类型对象生成源纹理并设置源纹理相关的属性值
     * 具体参见#prepareTextureWithRenderSource#方法的说明
     */
    void setRenderSource(void* renderSource);
    
    /** 获取源纹理图像的大小。一般不常用，可以在#prepareTextureWithRenderSource#的具体实现中设置 */
    Vec2f getRenderSourceSize();
    
    void setEnableDebug(bool enableDebug);

    void setDebugTexcoord(bool debugTexcoord);
    
//    static void clearCachedLUT(const char* lutPath);

    AutoRef<GLCamera> glCamera();

    /** Extract LUT data files into given directory
     * @param destDirectory    Destiny directory path where to store extracted LUT data files
     * @param lutBinFilePath   Path of file that contains LUT data, could be a JPEG or MP4 file
     * @param fileOffset       Byte position of begining of the LUT data in file. It should be get by APIs for reading MADV360 metadata in JPEG or MP4 box
     */
//    static void extractLUTFiles(const char* destDirectory, const char* lutBinFilePath, uint32_t fileOffset);

    /** Render JPEG into another(or itself) JPEG file
     * @param lutPath    Path of directory which already contains LUT data files extracted from this MADV360 JPEG file. NULL if no LUT stitching is needed
     * @param filterID   ID represents filter to apply(refer to #GLFilterCache#). 0 if no filter is applied
     * @param glFilterResourcePath    Path of directory to persist resources used by filters
     * @param gyroMatrix Transform matrix data parsed from metadata in EXIF of this JPEG file
     * @return Whether gyro matrix data is not applied in this rendering pass. That means it needs to be rendered with gyro matrix data later.
     *         Because in #PanoramaDisplayModeLUTInMesh# mode, we can't perform stitching and gyroscope transforming in one single rendering pass.
     */
	static void renderMadvJPEGToJPEG(const char* destJpegPath, const char* sourceJpegPath, int dstWidth, int dstHeight, const char* lutPath, int filterID, const char* glFilterResourcePath, float* gyroMatrix, int gyroMatrixRank, GLuint longitudeSegments, GLuint latitudeSegments, MVProgressClosure progressClosure = { NULL, NULL });

    static void renderTextureToJPEG(const char* destJpegPath, int dstWidth, int dstHeight, GLint sourceTexture, const char* lutPath, int filterID, const char* glFilterResourcePath, float* gyroMatrix, int gyroMatrixRank, GLuint longitudeSegments, GLuint latitudeSegments);
    
    static void debugRenderTextureToJPEG(const char* destJpegPath, int dstWidth, int dstHeight, GLint sourceTexture, const char* lutPath, int filterID, const char* glFilterResourcePath, float* gyroMatrix, int gyroMatrixRank, GLuint longitudeSegments, GLuint latitudeSegments);
    
	static bool renderMadvRawToRaw(const char* destRawPath, const char* sourceRawPath, int dstWidth, int dstHeight, const char* lutPath, int filterID, const char* glFilterResourcePath, float* gyroMatrix, int gyroMatrixRank, GLuint longitudeSegments, GLuint latitudeSegments, MVProgressClosure progressClosure = { NULL, NULL });

    static kmMat4 transformTextureMatrixByVideoCaptureResolution(const kmMat4* textureMatrix, int videoCaptureResolution);
    
protected:
    
    /** 通过无类型对象设置源纹理，需要平台相关的子类具体实现
     * 具体实现中，当可以通过传入的无类型对象设置源纹理时，必须通过某个#setSourceTextures#方法将生成的纹理设置为源纹理
     * 非必须设置源纹理图像的尺寸_renderSourceSize
     * 如何从无类型对象生成源纹理是平台相关的，例如MadvGLRenderer_iOS上的实现是把无类型指针转换为id，
     * 然后判断其类型，如果是UIImage则生成对应的图像纹理，如果是NSString并且字符串表示一个有效的本地JPEG文件则通过JPEG图像创建纹理，等等
     */
    virtual void prepareTextureWithRenderSource(void* renderSource);
    
    MadvGLRenderer(void* impl) {
        _impl = impl;
        _glCamera = new GLCamera;
    }
    
    void* _impl = NULL;
    AutoRef<GLCamera> _glCamera = NULL;
    GLuint _cubemapTexture = 0;
    GLint _cubemapFaceSize = 0;
};

//typedef AutoRef<MadvGLRenderer> MadvGLRendererRef;
//*
#ifdef __cplusplus
}
#endif
//*/
#endif //MadvGLRenderer_hpp
