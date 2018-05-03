//
//  MadvGLRenderer_iOS.mm
//  Madv360_v1
//
//  Created by FutureBoy on 4/2/16.
//  Copyright © 2016 Cyllenge. All rights reserved.
//

#include "MadvGLRenderer_iOS.h"
#ifndef MADVPANO_EXPORT

#ifdef FOR_DOUYIN
#import "KxMovieDecoder_douyin.h"
#else //#ifdef FOR_DOUYIN
#import "KxMovieDecoder.h"
#endif //#ifdef FOR_DOUYIN

#import "IDRDecoder.h"
#import "z_Sandbox.h"
#import "NSString+Extensions.h"
#import "UIDevice+DeviceModel.h"
#import "MVCameraClient.h"
#import "MVCameraDevice.h"
#endif
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>
#import <fstream>

#ifdef MADVPANO_BY_SOURCE
#import "OpenGLHelper.h"
#import "MadvGLRenderer.h"
#import "PanoCameraController.h"
#import "JPEGUtils.h"
#import "GLRenderTexture.h"
#import "GLFilterCache.h"
#import "MadvGLRendererImpl.h"
#import "MadvUtils.h"
#ifdef USE_IMAGE_BLENDER
#import "ImageBlender.h"
#endif //#ifdef USE_IMAGE_BLENDER

#else //#ifdef MADVPANO_BY_SOURCE

#import <MADVPano/OpenGLHelper.h>
#import <MADVPano/MadvGLRenderer.h>
#import <MADVPano/PanoCameraController.h>
#import <MADVPano/JPEGUtils.h>
#import <MADVPano/GLRenderTexture.h>
#import <MADVPano/GLFilterCache.h>
#import <MADVPano/MadvGLRendererImpl.h>
#import <MADVPano/MadvUtils.h>
#ifdef USE_IMAGE_BLENDER
#import <MADVPano/ImageBlender.h>
#endif //#ifdef USE_IMAGE_BLENDER

#endif //#ifdef MADVPANO_BY_SOURCE

using namespace std;

//CGSize bestMeshSizeOfCurrentDevice() {
//    NSString* iphoneInfo = [UIDevice getIphoneInfo];
//    NSLog(@"#Wavy# iphoneInfo = '%@'", iphoneInfo);
//    if ([iphoneInfo hasSuffix:@"iPhone 6 Plus"] || [iphoneInfo hasSuffix:@"iPhone 6"])
//        return CGSizeMake(LONGITUDE_SEGMENTS_IPHONE6, LATITUDE_SEGMENTS_IPHONE6);
//    else
//        return CGSizeMake(LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
//}

#pragma mark    MadvGLRendererImpl_iOS

class MadvGLRendererImpl_iOS : public MadvGLRendererImplBase_iOS {
public:
    
    virtual ~MadvGLRendererImpl_iOS();
    
    MadvGLRendererImpl_iOS(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments);
    
protected:
    
    virtual void prepareTextureWithRenderSource(void* renderSource);
    
    virtual void releaseGLObjects();
    
    //For iOS8HD
    struct __CVOpenGLESTextureCache * _videoTextureCache;
    struct __CVOpenGLESTexture *      _videoDestTexture;
};

class MadvGLRenderer_iOS : public MadvGLRendererBase_iOS {
public:
    
    MadvGLRenderer_iOS(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments);
    
    static UIImage* renderImageWithIDR(NSString* thumbnailPath, CGSize destSize, bool withLUT, NSString* sourceURI, int filterID, float* gyroMatrix, int gyroMatrixRank, VideoCaptureResolution videoCaptureResolution);
    
    static UIImage* renderImage(UIImage* sourceImage, CGSize destSize, BOOL forceLUTStitching, NSString* sourcePath, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank, VideoCaptureResolution videoCaptureResolution);
    
    static NSString* lutPathOfSourceURI(NSString* sourceURI, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension);
    
    static NSString* cameraLUTFilePath(NSString* cameraUUID);
    
    static NSString* preStitchPictureFileName(NSString* cameraUUID, NSString* fileName);
//    static NSString* stitchedPictureFileName(NSString* preStitchPictureFileName);
//    static NSString* cameraUUIDOfPreStitchFileName(NSString* preStitchFileName);
    
//    static void extractLUTFiles(const char* destDirectory, const char* lutBinFilePath, uint32_t fileOffset);
};

MadvGLRenderer_iOS::MadvGLRenderer_iOS(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments)
: MadvGLRendererBase_iOS(new MadvGLRendererImpl_iOS(lutPath, leftSrcSize, rightSrcSize, longitudeSegments, latitudeSegments))
{
    
}

MadvGLRendererImpl_iOS::~MadvGLRendererImpl_iOS() {
    releaseGLObjects();
}

MadvGLRendererImpl_iOS::MadvGLRendererImpl_iOS(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments)
: MadvGLRendererImplBase_iOS(lutPath, leftSrcSize, rightSrcSize, longitudeSegments, latitudeSegments)
, _videoDestTexture(NULL)
, _videoTextureCache(NULL)
{
    
}

void MadvGLRendererImpl_iOS::releaseGLObjects() {
    if(_videoDestTexture) {
        CFRelease(_videoDestTexture);
        _videoDestTexture = NULL;
    }
    
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
    
    MadvGLRendererImplBase_iOS::releaseGLObjects();
}

void MadvGLRendererImpl_iOS::prepareTextureWithRenderSource(void* renderSource) {
    //*
    id currentRenderSource = (__bridge id)renderSource;
    MadvGLRendererImplBase_iOS::prepareTextureWithRenderSource(renderSource);
    /*
    if ([currentRenderSource isKindOfClass:NSArray.class])
    {///For Debug Only:
        NSArray* images = currentRenderSource;
        UIImage* leftImg = images[0];
        UIImage* rightImg = images[1];
        GLuint srcTextureL = createTextureFromImage(leftImg, CGSizeZero);
        GLuint srcTextureR = createTextureFromImage(rightImg, CGSizeZero);
        setSourceTextures(srcTextureL, srcTextureR, GL_TEXTURE_2D, false);
        _renderSourceSize = Vec2f{(float)leftImg.size.width, (float)leftImg.size.height};
    }
    else if ([currentRenderSource isKindOfClass:UIImage.class])
    {
        if (_sourceTexture > 0)
        {
            glDeleteTextures(1, (GLuint*) &_sourceTexture);
            _sourceTexture = -1;
        }
        
        UIImage* image = currentRenderSource;
        _sourceTexture = createTextureFromImage(image, CGSizeZero);
        setSourceTextures(_sourceTexture, _sourceTexture, GL_TEXTURE_2D, false);
        _renderSourceSize = Vec2f{(float)image.size.width, (float)image.size.height};
    }
    else if ([currentRenderSource isKindOfClass:NSString.class])
    {
        const char* cstrPath = [currentRenderSource UTF8String];
        GLint texture = createTextureWithJPEG(cstrPath, &_renderSourceSize);
        if (0 >= texture)
        {
            GLint maxTextureSize = 0;
            glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
            NSLog(@"prepareTextureWithRenderSource : GL_MAX_TEXTURE_SIZE = %d", maxTextureSize);
            UIImage* image = [UIImage imageWithContentsOfFile:currentRenderSource];
            _renderSourceSize = Vec2f{(float)image.size.width, (float)image.size.height};
            texture = createTextureFromImage(image, CGSizeMake(MIN(image.size.width, maxTextureSize), MIN(image.size.height, maxTextureSize)));
        }
        setSourceTextures(texture, texture, GL_TEXTURE_2D, false);
    }//*/
#ifndef MADVPANO_EXPORT
    if ([currentRenderSource isKindOfClass:KxVideoFrame.class])
    {
        KxVideoFrame* frame = currentRenderSource;
        if ([frame isKindOfClass:KxVideoFrameCVBuffer.class])
        {
            KxVideoFrameCVBuffer *cvbFrame = (KxVideoFrameCVBuffer *)frame;
            
            CVBufferRef cvBufferRef = cvbFrame.cvBufferRef;
            
            if (!_videoTextureCache) {
                CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [EAGLContext currentContext], NULL, (CVOpenGLESTextureCacheRef *)&_videoTextureCache);
                if (err != noErr) {
                    //                    goto failed;
                    [cvbFrame releasePixelBuffer];
                    return;
                }
                //CFRetain(_videoTextureCache);//2016.3.3 spy
            }
            
            // Periodic texture cache flush every frame
            CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
            // cleanUp Textures
            if (_videoDestTexture) {
                CFRelease(_videoDestTexture);
                _videoDestTexture = NULL;
            }
            
            glActiveTexture(GL_TEXTURE0);
            CVReturn err;
            
            int frameWidth = (int)CVPixelBufferGetWidth(cvBufferRef);
            int frameHeight = (int)CVPixelBufferGetHeight(cvBufferRef);
            _renderSourceSize = Vec2f{(float)frameWidth, (float)frameHeight};
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               _videoTextureCache,
                                                               cvBufferRef,
                                                               NULL,
                                                               GL_TEXTURE_2D,
                                                               GL_RGBA,
                                                               frameWidth,
                                                               frameHeight,
                                                               GL_BGRA,
                                                               GL_UNSIGNED_BYTE,
                                                               0,
                                                               (CVOpenGLESTextureRef*)&_videoDestTexture);
            if (err) {
                //                goto failed;
                [cvbFrame releasePixelBuffer];
                return;
            }
            
            GLuint texture = CVOpenGLESTextureGetName((CVOpenGLESTextureRef)_videoDestTexture);
            
            glBindTexture(CVOpenGLESTextureGetTarget((CVOpenGLESTextureRef)_videoDestTexture), texture);
            
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR_MIPMAP_LINEAR
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
            
//            glHint(GL_GENERATE_MIPMAP_HINT, GL_NICEST);
//            glGenerateMipmap(GL_TEXTURE_2D);
            //        failed:
            [cvbFrame releasePixelBuffer];
            setSourceTextures(texture, texture, GL_TEXTURE_2D, false);
        }
        else if ([frame isKindOfClass:KxVideoFrameRGB.class])
        {
            if (_sourceTexture > 0)
            {
                glDeleteTextures(1, (GLuint*) &_sourceTexture);
                _sourceTexture = -1;
            }
            glGenTextures(1, (GLuint*) &_sourceTexture);
            glBindTexture(GL_TEXTURE_2D, _sourceTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR_MIPMAP_LINEAR
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
            glPixelStorei(GL_PACK_ALIGNMENT, 4);
            glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
            
            KxVideoFrameRGB* rgbFrame = (KxVideoFrameRGB*) frame;
            CHECK_GL_ERROR();
            NSLog(@"#BlackPreview# rgbFrame.rgb.length = %ld, width=%d,height=%d", (long)rgbFrame.rgb.length, (int)rgbFrame.width, (int)rgbFrame.height);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, (GLsizei)rgbFrame.width, (GLsizei)rgbFrame.height, 0, GL_RGB, GL_UNSIGNED_BYTE, rgbFrame.rgb.bytes);
            CHECK_GL_ERROR();
            setSourceTextures(_sourceTexture, _sourceTexture, GL_TEXTURE_2D, false);
            rgbFrame.rgb = nil;
        }
//        else if ([frame isKindOfClass:KxVideoFrameYUV.class])
//        {
//            _isYUVColorSpace = true;
//            
//            KxVideoFrameYUV *yuvFrame = (KxVideoFrameYUV *)frame;
//            assert(yuvFrame.luma.length == yuvFrame.width * yuvFrame.height);
//            assert(yuvFrame.chromaB.length == (yuvFrame.width * yuvFrame.height) / 4);
//            assert(yuvFrame.chromaR.length == (yuvFrame.width * yuvFrame.height) / 4);
//            
//            const NSUInteger frameWidth = frame.width;
//            const NSUInteger frameHeight = frame.height;
//            
//            const UInt8 *pixels[3] = {(const UInt8*) yuvFrame.luma.bytes, (const UInt8*)yuvFrame.chromaB.bytes, (const UInt8*)yuvFrame.chromaR.bytes };
//            
//            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
//            
//            if (0 == _yuvTextures[0])
//                glGenTextures(3, _yuvTextures);
//            
//            //            const UInt8 *pixels[3] = {(const UInt8*) yuvFrame.luma, (const UInt8*)yuvFrame.chromaB, (const UInt8*)yuvFrame.chromaR };
//            const NSUInteger widths[3]  = { frameWidth, frameWidth / 2, frameWidth / 2 };
//            const NSUInteger heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
//            
//            for (int i = 0; i < 3; ++i) {
//                
//                glBindTexture(GL_TEXTURE_2D, _yuvTextures[i]);
//                
//                glTexImage2D(GL_TEXTURE_2D,
//                             0,
//                             GL_LUMINANCE,
//                             (GLsizei)widths[i],
//                             (GLsizei)heights[i],
//                             0,
//                             GL_LUMINANCE,
//                             GL_UNSIGNED_BYTE,
//                             pixels[i]);
//                
//                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);//GL_CLAMP_TO_EDGE);//
//                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);//GL_CLAMP_TO_EDGE);//
//            }
//            
//            yuvFrame.luma = nil;
//            yuvFrame.chromaB = nil;
//            yuvFrame.chromaR = nil;
//        }
        _renderSourceSize = Vec2f{(float)frame.width, (float)frame.height};
        frame = nil;
    }
#endif //#ifndef MADVPANO_EXPORT
//    currentRenderSource = nil;
    /*/
    MadvGLRendererImplBase_iOS::prepareTextureWithRenderSource(renderSource);
//*/
}
#ifndef MADVPANO_EXPORT

inline NSString* loadDefaultLUT() {
    return [[[NSBundle mainBundle] pathForResource:@"l_x_int" ofType:@"png"] stringByDeletingLastPathComponent];
}

NSString* MadvGLRenderer_iOS::cameraLUTFilePath(NSString* cameraUUID) {//TODO
    NSString* lutFilePath = [[MVCameraClient formattedCameraUUID:cameraUUID] stringByAppendingString:@"_lut.bin"];
    lutFilePath = [z_Sandbox documentPath:lutFilePath];
    return lutFilePath;
}

NSString* cameraOrDefaultLUT() {//TODO
    NSString* lutPath = nil;
    MVCameraDevice* connectingCamera = [MVCameraClient sharedInstance].connectingCamera;
    NSFileManager* fm = [NSFileManager defaultManager];
    if (connectingCamera != nil)
    {
        lutPath = [MadvGLRenderer_iOS::cameraLUTFilePath(connectingCamera.uuid) stringByDeletingPathExtension];
        BOOL isDirectory;
        if (![fm fileExistsAtPath:[lutPath stringByAppendingPathComponent:@"l_x_int.png"] isDirectory:&isDirectory] || isDirectory)
        {
            lutPath = loadDefaultLUT();
        }
        else
        {
            NSLog(@"lutPathOfSourceURI : LUT of this camera : %@", lutPath);
        }
    }
    else
    {
        NSDirectoryEnumerator<NSString* >* fileIter = [fm enumeratorAtPath:[z_Sandbox docPath]];
        for (NSString* file in fileIter)
        {
            BOOL isDirectory = NO;
            if ([fm fileExistsAtPath:[z_Sandbox documentPath:file] isDirectory:&isDirectory] && isDirectory && [file hasSuffix:@"_lut"])
            {
                if ([fm fileExistsAtPath:[z_Sandbox documentPath:[file stringByAppendingPathComponent:@"l_x_int.png"]] isDirectory:NULL])
                {
                    lutPath = [z_Sandbox documentPath:file];
                    break;
                }
            }
        }
        
        if (!lutPath)
        {
            lutPath = loadDefaultLUT();
        }
    }
    return lutPath;
}

#define PRESTITCH_PICTURE_EXTENSION @"prestitch.jpg"

NSString* MadvGLRenderer_iOS::preStitchPictureFileName(NSString* cameraUUID, NSString* fileName) {//TODO
    NSString* uuid = cameraUUID ? [MVCameraClient formattedCameraUUID:cameraUUID] : @"LOCAL";
    NSString* ret = [fileName stringByAppendingPathExtension:uuid];
    ret = [ret stringByAppendingPathExtension:PRESTITCH_PICTURE_EXTENSION];
    return ret;
}

NSString* MadvGLRenderer_iOS::lutPathOfSourceURI(NSString* sourceURI, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension) {
    NSString* lutPath = MadvGLRendererBase_iOS::lutPathOfSourceURI_base(sourceURI, forceLUTStitching, pMadvEXIFExtension);
    if (lutPath)
        return lutPath;
    
    if (sourceURI && sourceURI.length > 0)
    {
        if ([sourceURI hasPrefix:AMBA_CAMERA_RTSP_URL_ROOT] || [sourceURI hasPrefix:HTTP_DOWNLOAD_URL_PREFIX])
        {
            lutPath = cameraOrDefaultLUT();
            DoctorLog(@"lutPathOfSourceURI : #3 lutPath='%@'", lutPath);
        }
        else if ([sourceURI rangeOfString:[z_Sandbox docPath]].location != NSNotFound)
        {
            if ([sourceURI rangeOfString:MADV_DUAL_FISHEYE_VIDEO_TAG].location != NSNotFound)
            {
                lutPath = cameraOrDefaultLUT();
                DoctorLog(@"lutPathOfSourceURI : #3.5 lutPath='%@'", lutPath);
                return lutPath;
            }
            
            static NSCondition* cond = [[NSCondition alloc] init];
            [cond lock];
            @try
            {
                KxMovieDecoder* decoder = [[KxMovieDecoder alloc] init];
                [decoder openFile:sourceURI error:nil];
                int64_t LutzOffset = [decoder getLutzOffset];
                int64_t LutzSize = [decoder getLutzSize];
                [decoder closeFile];
                NSLog(@"setupPresentViw : lutz offset = %lld size = %lld", LutzOffset, LutzSize);
                if (LutzOffset >= 0 && LutzSize > 0)
                {
                    lutPath = makeTempLUTDirectory(sourceURI);
                    extractLUTFiles(lutPath.UTF8String, sourceURI.UTF8String, (uint32_t)LutzOffset);
                }
                else if (forceLUTStitching)
                {
                    lutPath = cameraOrDefaultLUT();
                }
                else
                {
                    lutPath = nil;
                }
            }
            @catch (NSException *exception)
            {
                
            }
            @finally
            {
                
            }
            [cond unlock];
            DoctorLog(@"lutPathOfSourceURI : #4 lutPath='%@'", lutPath);
        }
    }
    else if (forceLUTStitching)
    {
        lutPath = cameraOrDefaultLUT();
        DoctorLog(@"lutPathOfSourceURI : #5 lutPath='%@'", lutPath);
    }
    else
    {
        lutPath = nil;
        DoctorLog(@"lutPathOfSourceURI : Video from other stream, no LUT stitching");
    }
    return lutPath;
}

//[MadvGLRenderer renderThumbnail:@"thumb.h264" destSize:CGSizeMake(1920, 1080)];

UIImage* MadvGLRenderer_iOS::renderImage(UIImage* sourceImage, CGSize destSize, BOOL forceLUTStitching, NSString* sourcePath, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank, VideoCaptureResolution videoCaptureResolution) {
//    CGSize bestMeshSize = bestMeshSizeOfCurrentDevice();
//    GLuint longitudeSegments = bestMeshSize.width;
//    GLuint latitudeSegments = bestMeshSize.height;
    
    NSString* lutPath = lutPathOfSourceURI(sourcePath, forceLUTStitching, pMadvEXIFExtension);
    GLubyte* pixelData = NULL;
    EAGLContext* eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:eaglContext];
    {
        GLuint sourceTexture = createTextureFromImage(sourceImage, CGSizeZero);
        
        GLRenderTexture renderTexture(destSize.width, destSize.height);
        pixelData = (GLubyte*) malloc(renderTexture.bytesLength());
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        CHECK_GL_ERROR();
        NSLog(@"status = %d", status);
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ZERO);
        glViewport(0, 0, destSize.width, destSize.height);
        CHECK_GL_ERROR();
#ifdef USE_MSAA
        glBindFramebuffer(GL_FRAMEBUFFER, _msaaFramebuffer);
#else
        glBindFramebuffer(GL_FRAMEBUFFER, renderTexture.getFramebuffer());
#endif
        
        glClearColor(0, 0, 0, 0);
        glClear(GL_COLOR_BUFFER_BIT);
        CHECK_GL_ERROR();
        
        AutoRef<GLRenderTexture> filterRenderTexture = NULL;
        AutoRef<GLFilterCache> filterCache = NULL;
        if (filterID > 0)
        {
            filterCache = new GLFilterCache([[[NSBundle mainBundle] pathForResource:@"lookup" ofType:@"png"] stringByDeletingLastPathComponent].UTF8String);
            filterRenderTexture = new GLRenderTexture(destSize.width, destSize.height);
            filterRenderTexture->blit();
        }
        
        AutoRef<MadvGLRenderer> renderer = new MadvGLRenderer_iOS(lutPath.UTF8String, Vec2f{DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT}, Vec2f{DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT}, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
        AutoRef<PanoCameraController> panoController = new PanoCameraController(renderer);
        renderer->setIsYUVColorSpace(false);
        renderer->setDisplayMode((lutPath ? PanoramaDisplayModeLUTInShader : 0));/// | PanoramaDisplayModeReFlatten);
        renderer->setSourceTextures(/*false, */sourceTexture, sourceTexture, GL_TEXTURE_2D, false);
        ///!!!Important {
        kmScalar textureMatrixData[] = {
            1.f, 0.f, 0.f, 0.f,
            0.f, -1.f, 0.f, 0.f,
            0.f, 0.f, 1.f, 0.f,
            0.f, 1.f, 0.f, 1.f,
        };
        renderer->setFlipY(true);
        kmMat4 textureMatrix;
        kmMat4Fill(&textureMatrix, textureMatrixData);
        renderer->setTextureMatrix(&textureMatrix, videoCaptureResolution);
        renderer->setIllusionTextureMatrix(&textureMatrix, videoCaptureResolution);
        ///!!!} Important
        switch (videoCaptureResolution)
        {
            case FPS120_BOTTOM_1920x480:
                panoController->setModelPostRotation({0.f, 1.f, 0.f}, {0.f, 0.f, 1.f});
                renderer->setDisplayMode((lutPath ? PanoramaDisplayModeLUTInShader : 0) | PanoramaDisplayModeStereoGraphic);
                renderer->glCamera()->setFOVDegree(270);
                break;
            case FPS120_TOP_1920x480:
                panoController->setModelPostRotation({0.f, 1.f, 0.f}, {0.f, 0.f, -1.f});
                renderer->setDisplayMode((lutPath ? PanoramaDisplayModeLUTInShader : 0) | PanoramaDisplayModeStereoGraphic);
                renderer->glCamera()->setFOVDegree(270);
                break;
            case FPS120_MIDDLE_1920x480:
                renderer->setDisplayMode((lutPath ? PanoramaDisplayModeLUTInShader : 0) | PanoramaDisplayModeStereoGraphic);
                renderer->glCamera()->setFOVDegree(270);
                break;
            default:
                if (gyroMatrixRank > 0)
                {
                    panoController->setGyroMatrix(gyroMatrix, gyroMatrixRank);
                }
                break;
        }
        if (0 == (renderer->getDisplayMode() & PanoramaDisplayModeExclusiveMask))
        {
            GLuint cubemapTexture = renderer->drawToRemappedCubemap(0, roundf(sourceImage.size.height * 0.57735));
            renderer->drawFromCubemap(0, 0, destSize.width, destSize.height, cubemapTexture);
            glDeleteTextures(1, &cubemapTexture);
        }
        else
        {
            renderer->draw(0,0, destSize.width,destSize.height);
        }
        
        if (filterID > 0)
        {
            filterRenderTexture->unblit();
            filterCache->render(filterID, 0, 0, destSize.width, destSize.height, filterRenderTexture->getTexture(), GL_TEXTURE_2D);
        }
        
        CHECK_GL_ERROR();
        renderTexture.copyPixelData(pixelData, 0, renderTexture.bytesLength());
        CHECK_GL_ERROR();
        
        if (filterID > 0)
        {
            filterRenderTexture->releaseGLObjects();
            filterCache->releaseGLObjects();
        }
        
        glDeleteTextures(1, &sourceTexture);
    }
    //*/!!!For Debug 0320:
    glFinish();
    CGDataProviderRef cgProvider = CGDataProviderCreateWithData(NULL, pixelData, destSize.width * destSize.height * 4, cgDataProviderReleaseDataCallback);
    CGColorSpaceRef cgColorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef cgImage = CGImageCreate(destSize.width, destSize.height, 8, 32, 4 * destSize.width, cgColorSpace, bitmapInfo, cgProvider, NULL, false, renderingIntent);
    UIImage* renderedImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGDataProviderRelease(cgProvider);
    CGColorSpaceRelease(cgColorSpace);
    [EAGLContext setCurrentContext:nil];
    /*/
    NSData* data = [NSData dataWithBytes:pixelData length:(destSize.width * destSize.height)];
    UIImage* renderedImage = [UIImage imageWithData:data];
    free(pixelData);
    //*/
    return renderedImage;
}

UIImage* MadvGLRenderer_iOS::renderImageWithIDR(NSString* thumbnailPath, CGSize destSize, bool withLUT, NSString* sourceURI, int filterID, float* gyroMatrix, int gyroMatrixRank, VideoCaptureResolution videoCaptureResolution) {
    //*
    const char* cstrThumbnailPath = thumbnailPath.UTF8String;
    decodeIDR(cstrThumbnailPath, cstrThumbnailPath);
    ///!!!remove(cstrThumbnailPath);
    
    NSString* bmpPath = [thumbnailPath stringByAppendingPathExtension:@"bmp"];
    UIImage* bmpImage = [UIImage imageWithContentsOfFile:bmpPath];
    /*/
     UIImage* bmpImage = [UIImage imageNamed:@"video.png"];
     //*/
    
    UIImage* renderedImage = renderImage(bmpImage, destSize, withLUT, sourceURI, NULL, filterID, gyroMatrix, gyroMatrixRank, videoCaptureResolution);
    
    remove(bmpPath.UTF8String);
    
    return renderedImage;
}

#endif //#ifndef MADVPANO_EXPORT

@interface MVPanoRenderer ()
{
    AutoRef<MadvGLRenderer_iOS> _impl;
}

@end

@implementation MVPanoRenderer

- (void*) internalInstance {
    return &_impl;
}

- (void) dealloc {
    _impl = NULL;
}

- (instancetype) initWithLUTPath:(NSString*)lutPath leftSrcSize:(CGSize)leftSrcSize rightSrcSize:(CGSize)rightSrcSize {
    if (self = [super init])
    {
        _impl = new MadvGLRenderer_iOS(lutPath.UTF8String, CGSize2Vec2f(leftSrcSize), CGSize2Vec2f(rightSrcSize), LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
    }
    return self;
}
#ifndef MADVPANO_EXPORT

+ (UIImage*) renderImageWithIDR:(NSString*)idrPath destSize:(CGSize)destSize withLUT:(BOOL)withLUT sourceURI:(NSString*)sourceURI filterID:(int)filterID gyroMatrix:(float*)gyroMatrix gyroMatrixBank:(int)gyroMatrixRank videoCaptureResolution:(VideoCaptureResolution)videoCaptureResolution {
    return MadvGLRenderer_iOS::renderImageWithIDR(idrPath, destSize, withLUT, sourceURI, filterID, gyroMatrix, gyroMatrixRank, videoCaptureResolution);
}

+ (UIImage*) renderImage:(UIImage*)sourceImage destSize:(CGSize)destSize forceLUTStitching:(BOOL)forceLUTStitching sourcePath:(NSString*)sourcePath pMadvEXIFExtension:(MadvEXIFExtension*)pMadvEXIFExtension filterID:(int)filterID gyroMatrix:(float*)gyroMatrix gyroMatrixBank:(int)gyroMatrixRank videoCaptureResolution:(VideoCaptureResolution)videoCaptureResolution {
    return MadvGLRenderer_iOS::renderImage(sourceImage, destSize, forceLUTStitching, sourcePath, pMadvEXIFExtension, filterID, gyroMatrix, gyroMatrixRank, videoCaptureResolution);
}

+ (UIImage*) renderJPEG:(NSString*)sourcePath destSize:(CGSize)destSize forceLUTStitching:(BOOL)forceLUTStitching pMadvEXIFExtension:(MadvEXIFExtension*)pMadvEXIFExtension filterID:(int)filterID gyroMatrix:(float*)gyroMatrix gyroMatrixRank:(int)gyroMatrixRank {
    return MadvGLRenderer_iOS::renderJPEG(sourcePath.UTF8String, destSize, forceLUTStitching, pMadvEXIFExtension, filterID, gyroMatrix, gyroMatrixRank);
}

+ (void) renderJPEGToJPEG:(NSString*)destJpegPath sourcePath:(NSString*)sourcePath dstWidth:(int)dstWidth dstHeight:(int)dstHeight forceLUTStitching:(BOOL)forceLUTStitching pMadvEXIFExtension:(MadvEXIFExtension*)pMadvEXIFExtension filterID:(int)filterID gyroMatrix:(float*)gyroMatrix gyroMatrixRank:(int)gyroMatrixRank {
    MadvGLRenderer_iOS::renderJPEGToJPEG(destJpegPath, sourcePath, dstWidth, dstHeight, forceLUTStitching, pMadvEXIFExtension, filterID, gyroMatrix, gyroMatrixRank);
}

+ (void) renderJPEGToJPEG:(NSString*)destJpegPath sourcePath:(NSString*)sourcePath dstWidth:(int)dstWidth dstHeight:(int)dstHeight lutPath:(NSString*)lutPath filterID:(int)filterID gyroMatrix:(float*)gyroMatrix gyroMatrixRank:(int)gyroMatrixRank {
    MadvGLRenderer_iOS::renderJPEGToJPEG(destJpegPath, sourcePath, dstWidth, dstHeight, lutPath, filterID, gyroMatrix, gyroMatrixRank);
}

+ (NSString*) lutPathOfSourceURI:(NSString*)sourceURI forceLUTStitching:(BOOL)forceLUTStitching pMadvEXIFExtension:(MadvEXIFExtension*)pMadvEXIFExtension {
    return MadvGLRenderer_iOS::lutPathOfSourceURI(sourceURI, forceLUTStitching, pMadvEXIFExtension);
}

+ (NSString*) cameraLUTFilePath:(NSString*)cameraUUID {
    return MadvGLRenderer_iOS::cameraLUTFilePath(cameraUUID);
}

+ (NSString*) preStitchPictureFileName:(NSString*)cameraUUID fileName:(NSString*)fileName {
    return MadvGLRenderer_iOS::preStitchPictureFileName(cameraUUID, fileName);
}

+ (NSString*) stitchedPictureFileName:(NSString*)preStitchPictureFileName {
    return MadvGLRenderer_iOS::stitchedPictureFileName(preStitchPictureFileName);
}

+ (NSString*) cameraUUIDOfPreStitchFileName:(NSString*)preStitchFileName {
    return MadvGLRenderer_iOS::cameraUUIDOfPreStitchFileName(preStitchFileName);
}
/*
+ (void) extractLUTFiles:(const char*)destDirectory lutBinFilePath:(const char*)lutBinFilePath fileOffset:(uint32_t)fileOffset {
    MadvGLRenderer_iOS::extractLUTFiles(destDirectory, lutBinFilePath, fileOffset);
}//*/
#endif //#ifndef MADVPANO_EXPORT
- (void) setIsYUVColorSpace:(BOOL)isYUVColorSpace {
    if (NULL != _impl)
    {
        _impl->setIsYUVColorSpace(isYUVColorSpace);
    }
}

- (BOOL) isYUVColorSpace {
    if (NULL != _impl)
        return _impl->getIsYUVColorSpace();
    else
        return NO;
}

- (void) prepareLUT:(NSString*)lutPath leftSrcSize:(CGSize)leftSrcSize rightSrcSize:(CGSize)rightSrcSize {
    if (NULL != _impl)
    {
        _impl->prepareLUT(lutPath.UTF8String, CGSize2Vec2f(leftSrcSize), CGSize2Vec2f(rightSrcSize));
    }
}

- (void) setTextureMatrix:(kmMat4*)textureMatrix {
    if (NULL == _impl)
        return;
    
    _impl->setTextureMatrix(textureMatrix);
}

- (void) setIllusionTextureMatrix:(kmMat4*)textureMatrix {
    if (NULL == _impl)
        return;
    
    _impl->setIllusionTextureMatrix(textureMatrix);
}

- (void) setTextureMatrix:(kmMat4*)textureMatrix videoCaptureResolution:(VideoCaptureResolution)videoCaptureResolution {
    if (NULL == _impl)
        return;
    
    _impl->setTextureMatrix(textureMatrix, videoCaptureResolution);
}

- (void) setIllusionTextureMatrix:(kmMat4*)illusionTextureMatrix videoCaptureResolution:(VideoCaptureResolution)videoCaptureResolution {
    if (NULL == _impl)
        return;
    
    _impl->setIllusionTextureMatrix(illusionTextureMatrix, videoCaptureResolution);
}

- (void) setRenderSource:(void*)renderSource {
    if (NULL == _impl)
        return;
    
    _impl->setRenderSource(renderSource);
}

- (CGSize) renderSourceSize {
    if (NULL == _impl)
        return CGSizeZero;
    
    Vec2f sizeV2f = _impl->getRenderSourceSize();
    return CGSizeMake(sizeV2f.width, sizeV2f.height);
}

- (GLint) leftSourceTexture {
    if (NULL == _impl)
        return 0;
    return _impl->getLeftSourceTexture();
}

- (GLint) rightSourceTexture {
    if (NULL == _impl)
        return 0;
    return _impl->getRightSourceTexture();
}

- (int) displayMode {
    if (NULL == _impl)
        return 0;
    return _impl->getDisplayMode();
}

- (void) setDisplayMode:(int)displayMode {
    if (NULL == _impl)
        return;
    _impl->setDisplayMode(displayMode);
}

- (GLenum) sourceTextureTarget {
    if (NULL == _impl)
        return GL_TEXTURE_2D;
    return (GLenum) _impl->getSourceTextureTarget();
}

- (void) setEnableDebug:(BOOL)enable {
    if (NULL == _impl)
        return;
    _impl->setEnableDebug(enable);
}

- (void) setNeedDrawCaps:(BOOL)needDrawCaps {
    if (NULL == _impl)
        return;
    _impl->setNeedDrawCaps(needDrawCaps);
}

- (void) setCapsTexture:(GLint)texture {
    if (NULL == _impl)
        return;
    _impl->setCapsTexture(texture, GL_TEXTURE_2D);
}

- (void) setFlipY:(BOOL)flipY {
    if (NULL == _impl)
        return;
    _impl->setFlipY(flipY);
}

- (void) drawWithDisplayMode:(int)displayMode x:(int)x y:(int)y width:(int)width height:(int)height /*separateSourceTextures:(BOOL)separateSourceTextures */srcTextureType:(int)srcTextureType leftSrcTexture:(int)leftSrcTexture rightSrcTexture:(int)rightSrcTexture {
    if (NULL == _impl)
        return;
    _impl->draw(displayMode, x, y, width, height, /*separateSourceTextures, */srcTextureType, leftSrcTexture, rightSrcTexture);
}

- (void) drawWithX:(int)x y:(int)y width:(int)width height:(int)height {
    if (NULL == _impl)
        return;
    _impl->draw(x, y, width, height);
}

- (void) drawRemappedPanoramaWithRect:(CGRect)rect cubemapFaceSize:(int)cubemapFaceSize {
    if (NULL == _impl)
        return;

    _impl->drawRemappedPanorama(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, cubemapFaceSize);
}

-(AutoRef<GLRenderTexture>) drawCubemapToBuffers:(GLubyte*)outPixelDatas PBOs:(GLuint*)PBOs cubemapFaceTexture:(AutoRef<GLRenderTexture>)cubemapFaceTexture cubemapFaceSize:(int)cubemapFaceSize {
    if (NULL == _impl)
        return NULL;
    
    return _impl->drawCubemapToBuffers(outPixelDatas, PBOs, cubemapFaceTexture, cubemapFaceSize);
}

- (int) fovDegree {
    if (NULL == _impl || NULL == _impl->glCamera())
        return 75;
    return _impl->glCamera()->getFOVDegree();
}

@end
