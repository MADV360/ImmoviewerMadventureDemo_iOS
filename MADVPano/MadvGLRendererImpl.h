//
//  MadvGLRendererImpl.hpp
//  MADVPano
//
//  Created by QiuDong on 2017/8/18.
//  Copyright © 2017年 MADV. All rights reserved.
//

#ifndef MadvGLRendererImpl_hpp
#define MadvGLRendererImpl_hpp

#include "OpenGLHelper.h"
#include "GLProgram.h"
#include "GLCamera.h"
#include "GLRenderTexture.h"
#include "GLVAO.h"
#include "AutoRef.h"
#include "kazmath.h"

#pragma mark    MadvGLProgram Def

class MadvGLProgram : public GLProgram {
public:
    
    MadvGLProgram(const GLchar* const* vertexSources, int vertexSourcesCount, const GLchar* const* fragmentSources, int fragmentSourcesCount);
    
    inline GLint getSourceTextureSlot() {return _sourceTextureSlot;}
    
    inline GLint getVertexRoleSlot() {return _vertexRoleSlot;}
    inline GLint getDiffTexcoordSlot() {return _diffTexcoordSlot;}
    
    inline GLint getGridCoordSlot() {return _gridCoordSlot;}
    inline GLint getRowsSlot() {return _rowsSlot;}
    inline GLint getColumnsSlot() {return _columnsSlot;}
    
    inline GLint getLeftTexcoordSlot() {return _leftTexcoordSlot;}
    inline GLint getRightTexcoordSlot() {return _rightTexcoordSlot;}
    
    inline GLint getDstSizeSlot() {return _dstSizeSlot;}
    inline GLint getLeftSrcSizeSlot() {return _leftSrcSizeSlot;}
    inline GLint getRightSrcSizeSlot() {return _rightSrcSizeSlot;}
    
    inline GLint getSourceYTextureSlot() {return _ySourceTextureSlot;}
    inline GLint getSourceUTextureSlot() {return _uSourceTextureSlot;}
    inline GLint getSourceVTextureSlot() {return _vSourceTextureSlot;}
    
    inline GLint getLSLutTextureSlot() {return _lsLutTextureSlot;}
    inline GLint getLTLutTextureSlot() {return _ltLutTextureSlot;}
    inline GLint getRSLutTextureSlot() {return _rsLutTextureSlot;}
    inline GLint getRTLutTextureSlot() {return _rtLutTextureSlot;}
    
    inline GLint getLUTTextureSlot() {return _lutTextureSlot;}
    
    inline GLint getLUTSourceSizeSlot() {return _lutSrcSizeSlot;}
    
    inline GLint getTextureMatrixSlot() {return _textureMatrixSlot;}
    inline GLint getIllusionTextureMatrixSlot() {return _illusionTextureMatrixSlot;}
    
    inline GLint getSPCMMatrixSlot() {return _SPCMMatrixSlot;}
    inline GLint getCMMatrixSlot() {return _CMMatrixSlot;}
    inline GLint getInverseCMMatrixSlot() {return _invCMMatrixSlot;}
    
protected:
    
    GLint _sourceTextureSlot;
    
    GLint _vertexRoleSlot;
    GLint _diffTexcoordSlot;
    
    GLint _gridCoordSlot;
    GLint _columnsSlot;
    GLint _rowsSlot;
    
    GLint _leftTexcoordSlot;
    GLint _rightTexcoordSlot;
    
    GLint _dstSizeSlot;
    GLint _leftSrcSizeSlot;
    GLint _rightSrcSizeSlot;
    
    GLint _ySourceTextureSlot;
    GLint _uSourceTextureSlot;
    GLint _vSourceTextureSlot;
    
    GLint _lsLutTextureSlot;
    GLint _ltLutTextureSlot;
    GLint _rsLutTextureSlot;
    GLint _rtLutTextureSlot;
    
    GLint _lutTextureSlot;
    GLint _lutSrcSizeSlot;
    
    GLint _textureMatrixSlot;
    GLint _illusionTextureMatrixSlot;
    
    GLint _SPCMMatrixSlot;
    GLint _CMMatrixSlot;
    GLint _invCMMatrixSlot;
};

//typedef AutoRef<MadvGLProgram> MadvGLProgramRef;

#pragma mark    MadvGLRendererImpl Def

class MadvGLRendererImpl {
    friend class MadvGLRenderer;
    friend class PanoCameraController;
    
public:
    
    virtual ~MadvGLRendererImpl();
    
//    MadvGLRendererImpl(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize);
    MadvGLRendererImpl(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments);
    
	MadvGLRendererImpl(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize);

//	void setBestMeshSize(GLuint longitudeSegments, GLuint latitudeSegments);

    void prepareLUT(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize);
    
    void drawCubeMapFace(GLenum targetFace, GLint x, GLint y, GLint width, GLint height);
    
    void drawFromCubemap(AutoRef<GLCamera> camera, int x, int y, int width, int height, GLint sourceCubemapTexture);

    static void resizeCubemap(GLuint cubemapTexture, int cubemapFaceSize);
    
    GLint drawToRemappedCubemap(GLuint cubemapTexture, int cubemapFaceSize);
    
    AutoRef<GLRenderTexture> drawCubemapToBuffers(GLubyte* outPixelDatas, GLuint* PBOs, AutoRef<GLRenderTexture> cubemapFaceTexture, int cubemapFaceSize);
    
    void draw(int displayMode, AutoRef<GLCamera> panoCamera, int x, int y, int width, int height, /*bool separateSourceTextures, */int srcTextureType, int leftSrcTexture, int rightSrcTexture);
    
    void draw(int displayMode, AutoRef<GLCamera> panoCamera, int x, int y, int width, int height, /*bool separateSourceTextures, */int srcTextureType, int* leftSrcYUVTextures, int* rightSrcYUVTextures);
    
    void draw(AutoRef<GLCamera> panoCamera, GLint x, GLint y, GLint width, GLint height);
    
    inline int getDisplayMode() {return _currentDisplayMode;}
    inline void setDisplayMode(int displayMode) {_currentDisplayMode = displayMode;}
    
    inline bool getIsYUVColorSpace() {return _isYUVColorSpace;}
    inline void setIsYUVColorSpace(bool isYUVColorSpace) {_isYUVColorSpace = isYUVColorSpace;}
    
    void setSourceTextures(/*bool separateSourceTexture, */GLint srcTextureL, GLint srcTextureR, GLenum srcTextureTarget, bool isYUVColorSpace);
    
    void setSourceTextures(/*bool separateSourceTexture, */GLint* srcTextureL, GLint* srcTextureR, GLenum srcTextureTarget, bool isYUVColorSpace);
    
    void setTextureMatrix(const kmMat4* textureMatrix);
    void setIllusionTextureMatrix(const kmMat4* textureMatrix);
    
    inline GLint getLeftSourceTexture() {return _srcTextureL;}
    inline GLint getRightSourceTexture() {return _srcTextureR;}
    inline GLenum getSourceTextureTarget() {return _srcTextureTarget;}
    
    void setGyroMatrix(float* matrix, int rank);
    
    void setModelPostRotation(kmVec3 fromVector, kmVec3 toVector);
    
    inline void setFlipY(bool flipY) {_flipY = flipY;}
    inline void setFlipX(bool flipX) {_flipX = flipX;}
    
    inline bool getFlipY() {return _flipY;}
    inline bool getFlipX() {return _flipX;}
    
    inline void setNeedDrawCaps(bool drawCaps) {_drawCaps = drawCaps;}
    
    void setCapsTexture(GLint texture, GLenum textureTarget);
    
    void setRenderSource(void* renderSource);
    
    inline Vec2f getRenderSourceSize() {return _renderSourceSize;}
    
    inline void setEnableDebug(bool enableDebug) {_enableDebug = enableDebug;}
    
    inline void setDebugTexcoord(bool debugTexcoord) {_debugTexcoord = debugTexcoord;}
    
    static void clearCachedLUT(const char* lutPath);
    
    static void extractLUTFiles(const char* destDirectory, const char* lutBinFilePath, uint32_t fileOffset);
    
protected:
    
    void* setLUTData(Vec2f lutDstSize, Vec2f leftSrcSize,Vec2f rightSrcSize, int dataSizeInShort, const GLushort* lxIntData, const GLushort* lxMinData, const GLushort* lyIntData, const GLushort* lyMinData, const GLushort* rxIntData, const GLushort* rxMinData, const GLushort* ryIntData, const GLushort* ryMinData);
    void setLUTData(Vec2f lutDstSize, Vec2f leftSrcSize,Vec2f rightSrcSize, const void* lutTextureData);
    
    virtual void prepareTextureWithRenderSource(void* renderSource);
    
    void updateSourceTextureIfNecessary();
    
    virtual void prepareGLPrograms();
    
    void prepareGLCanvas(GLint x, GLint y, GLint width, GLint height);
    
    void setGLProgramVariables(AutoRef<GLCamera> panoCamera, GLint x, GLint y, GLint width, GLint height, bool withGyroAdust);
    void drawPrimitives();
    
    inline GLint getLSLutTexture() {return _lsLutTexture;}
    inline GLint getLTLutTexture() {return _ltLutTexture;}
    inline GLint getRSLutTexture() {return _rsLutTexture;}
    inline GLint getRTLutTexture() {return _rtLutTexture;}
    
    inline GLint getLUTTexture() {return _lutTexture;}
    
    void setDebugPrimitive(AutoRef<Mesh3D> mesh, int key);
    AutoRef<GLVAO> getDebugPrimitive(int key);
    
    Vec2f _renderSourceSize;
    
protected:
    
    void* _renderSource;
    bool _needRenderNewSource;
    
    float _gyroMatrix[16];
    int _gyroMatrixRank = 0;
    
    kmVec3 _modelPostRotationFromVector;
    kmVec3 _modelPostRotationToVector;
    
#ifdef USE_MSAA
    GLuint _msaaFramebuffer;
    GLuint _msaaRenderbuffer;
    GLuint _msaaDepthbuffer;
    
    bool   _supportDiscardFramebuffer;
#endif
    GLint _srcTextureL;
    GLint _srcTextureR;
    GLenum _srcTextureTarget;
//    bool   _separateSourceTexture;
    
    GLint _capsTexture;
    GLenum _capsTextureTarget;
    
    Vec2f _lutDstSize;
    Vec2f _lutSrcSizeL, _lutSrcSizeR;
    
    GLint _yuvTexturesL[3];
    GLint _yuvTexturesR[3];
    
    bool _drawCaps;
    
    AutoRef<MadvGLProgram> _currentGLProgram = NULL;
    AutoRef<MadvGLProgram>* _glPrograms = NULL;
    
    bool _enableDebug = false;
    AutoRef<GLProgram> _debugGLProgram = NULL;
    std::map<int, AutoRef<GLVAO> > _debugVAOs;
    
#ifdef DRAW_GRID_SPHERE
    GLint _uniGridColors;
    GLint _uniLongitudeFragments;
    GLint _uniLatitudeFragments;
#endif
    
    bool _flipY = false;
    bool _flipX = false;
    
    GLuint _longitudeSegments;
    GLuint _latitudeSegments;
    
    AutoRef<Mesh3D> _trivialMesh = NULL;
    AutoRef<Mesh3D> _quadMesh = NULL;
    AutoRef<Mesh3D> _sphereMesh = NULL;
    AutoRef<Mesh3D> _lutQuadMesh = NULL;
    AutoRef<Mesh3D> _lutSphereMesh = NULL;
    AutoRef<Mesh3D> _capsMesh = NULL;
    
    AutoRef<GLVAO> _trivialVAO = NULL;
    AutoRef<GLVAO> _quadVAO = NULL;
    AutoRef<GLVAO> _sphereVAO = NULL;
    AutoRef<GLVAO> _lutQuadVAO = NULL;
    AutoRef<GLVAO> _lutSphereVAO = NULL;
    
    AutoRef<GLVAO> _currentVAO = NULL;
    AutoRef<GLVAO> _capsVAO = NULL;
    
    GLint _lsLutTexture = -1;
    GLint _ltLutTexture = -1;
    GLint _rsLutTexture = -1;
    GLint _rtLutTexture = -1;
    
    GLint _lutTexture = -1;
    
    bool _isYUVColorSpace;
    
    kmMat4 _textureMatrix;
    kmMat4 _illusionTextureMatrix;
    
    int _currentDisplayMode = 0;
//    bool _isPrevDisplayModeLittlePlanet = false;
    
    bool _debugTexcoord = false;
    
    pthread_mutex_t _mutex;
};

#endif /* MadvGLRendererImpl_hpp */
