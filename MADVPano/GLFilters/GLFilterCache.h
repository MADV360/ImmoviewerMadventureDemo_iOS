//
//  GLFilterCache.hpp
//  Madv360_v1
//
//  Created by QiuDong on 16/7/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#ifndef GLFilterCache_hpp
#define GLFilterCache_hpp

#include "GLFilter.h"
#include "OpenGLHelper.h"
//*
#ifdef __cplusplus
extern "C" {
#endif

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
typedef enum {
    GLFilterNone = 0,
    GLFilterTestID = -1,
    GLFilterSimpleBeautyID = 1,
    GLFilterInverseColorID = 2,
    GLFilterBilateralID = 3,
    GLFilterKuwaharaID = 4,
    GLFilterSepiaToneID = 5,
    GLFilterAmatorkaID = 6,
    GLFilterMissEtikateID = 7,
    GLFilterRGB2YUVID = 8,
    GLFilterSobelEdgeDetectSketchID = 9,
    GLFilterToonID = 10,
} GLFilterID;

class MADVPANO_API GLFilterCache {
public:

    virtual ~GLFilterCache();
    
    GLFilterCache(const char* resourceDirectory);
    
    void releaseGLObjects();
    
    void render(int filterID, GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget);
    
    void render(int filterID, GLfloat x, GLfloat y, GLfloat width, GLfloat height, GLint sourceTexture, GLenum sourceTextureTarget);
    
//    void render(int filterID, int x, int y, int width, int height, GLint sourceTexture, GLenum sourceTextureTarget, GLFilterOrientation sourceOrientation);
    
    void render(int filterID, GLfloat x, GLfloat y, GLfloat width, GLfloat height, GLint sourceTexture, GLenum sourceTextureTarget, Orientation2D sourceOrientation, Vec2f texcoordOrigin, Vec2f texcoordSize);
    
    GLFilter* createFilter(int filterID);

    GLFilter* obtainFilter(int filterID);
    
private:
    
    void* _filtersOfIDMap;

    const char* _resourceDirectory = NULL;
};
//*
//typedef AutoRef<GLFilterCache> GLFilterCacheRef;
#ifdef __cplusplus
}
#endif
//*/
#endif /* GLFilterCache_hpp */
