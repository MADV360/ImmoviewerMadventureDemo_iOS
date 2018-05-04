
//
//  MadvGLRendererBase_iOS.hpp
//  Madv360_v1
//
//  Created by FutureBoy on 4/2/16.
//  Copyright © 2016 Cyllenge. All rights reserved.
//

#ifndef MadvGLRendererBase_iOS_hpp
#define MadvGLRendererBase_iOS_hpp

#ifdef MADVPANO_BY_SOURCE
#import "OpenGLHelper.h"
#import "MadvGLRenderer.h"
#import "MadvGLRendererImpl.h"
#import "EXIFParser.h"
#else
#import <MADVPano/OpenGLHelper.h>
#import <MADVPano/MadvGLRenderer.h>
#import <MADVPano/MadvGLRendererImpl.h>
#import <MADVPano/EXIFParser.h>
#endif

//#import "MVMedia.h"
#import <UIKit/UIKit.h>

#define MADV_DUAL_FISHEYE_VIDEO_TAG @"MADV_DUAL_FISHEYE"

#ifdef __cplusplus
extern "C" {
#endif
    
    inline Vec2f CGPoint2Vec2f(CGPoint point) {
        Vec2f vec2;
        vec2.x = point.x;
        vec2.y = point.y;
        return vec2;
    }
    
    inline Vec2f CGSize2Vec2f(CGSize size) {
        Vec2f vec2;
        vec2.x = size.width;
        vec2.y = size.height;
        return vec2;
    }
    
#ifdef __cplusplus
}
#endif

extern void cgDataProviderReleaseDataCallback(void * __nullable info, const void *  data, size_t size);

class MadvGLRendererImplBase_iOS : public MadvGLRendererImpl {
public:
    
    virtual ~MadvGLRendererImplBase_iOS();
    
    MadvGLRendererImplBase_iOS(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments);
    
protected:
    
    virtual void prepareTextureWithRenderSource(void* renderSource);
    
    virtual void releaseGLObjects();
    
    GLint _sourceTexture = -1;
};

class MadvGLRendererBase_iOS : public MadvGLRenderer {
public:
    
    MadvGLRendererBase_iOS(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments);
    
    MadvGLRendererBase_iOS(void* impl);
    
    static UIImage* renderJPEG(const char* sourcePath, CGSize destSize, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank);
    
    static void renderJPEGToJPEG(NSString* destJpegPath, NSString* sourcePath, int dstWidth, int dstHeight, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank);
    
    static void renderJPEGToJPEG(NSString* destJpegPath, NSString* sourcePath, int dstWidth, int dstHeight, NSString* lutPath, int filterID, float* gyroMatrix, int gyroMatrixRank);
    
    static NSString* lutPathOfSourceURI_base(NSString* sourceURI, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension);
    
    static NSString* stitchedPictureFileName(NSString* preStitchPictureFileName);
    static NSString* cameraUUIDOfPreStitchFileName(NSString* preStitchFileName);
    //    static void extractLUTFiles(const char* destDirectory, const char* lutBinFilePath, uint32_t fileOffset);
};

#endif /* MadvGLRenderer_iOS_hpp */

