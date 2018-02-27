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
#import "MadvGLRenderer.h"
#import "JPEGUtils.h"
#import "GLRenderTexture.h"
#import "GLFilterCache.h"
#import "MadvGLRendererImpl.h"
#else
#import <MADVPano/MadvGLRenderer.h>
#import <MADVPano/JPEGUtils.h>
#import <MADVPano/GLRenderTexture.h>
#import <MADVPano/GLFilterCache.h>
#import <MADVPano/MadvGLRendererImpl.h>
#endif

using namespace std;

//CGSize bestMeshSizeOfCurrentDevice() {
//    NSString* iphoneInfo = [UIDevice getIphoneInfo];
//    NSLog(@"#Wavy# iphoneInfo = '%@'", iphoneInfo);
//    if ([iphoneInfo hasSuffix:@"iPhone 6 Plus"] || [iphoneInfo hasSuffix:@"iPhone 6"])
//        return CGSizeMake(LONGITUDE_SEGMENTS_IPHONE6, LATITUDE_SEGMENTS_IPHONE6);
//    else
//        return CGSizeMake(LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
//}

void cgDataProviderReleaseDataCallback(void * __nullable info, const void *  data, size_t size) {
    free((void*) data);
}

#pragma mark    MadvGLRendererImpl_iOS

class MadvGLRenderer_iOS : public MadvGLRenderer {
public:
    
    MadvGLRenderer_iOS(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments);
    
    static UIImage* renderImageWithIDR(NSString* thumbnailPath, CGSize destSize, bool withLUT, NSString* sourceURI, int filterID, float* gyroMatrix, int gyroMatrixRank, VideoCaptureResolution videoCaptureResolution);
    
    static UIImage* renderImage(UIImage* sourceImage, CGSize destSize, BOOL forceLUTStitching, NSString* sourcePath, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank, VideoCaptureResolution videoCaptureResolution);
    
    static UIImage* renderJPEG(const char* sourcePath, CGSize destSize, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank);
    
    static void renderJPEGToJPEG(NSString* destJpegPath, NSString* sourcePath, int dstWidth, int dstHeight, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank);
    
    static void renderJPEGToJPEG(NSString* destJpegPath, NSString* sourcePath, int dstWidth, int dstHeight, NSString* lutPath, int filterID, float* gyroMatrix, int gyroMatrixRank);
    
    static NSString* lutPathOfSourceURI(NSString* sourceURI, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension);
    
    static NSString* cameraLUTFilePath(NSString* cameraUUID);
    
    static NSString* preStitchPictureFileName(NSString* cameraUUID, NSString* fileName);
    static NSString* stitchedPictureFileName(NSString* preStitchPictureFileName);
    static NSString* cameraUUIDOfPreStitchFileName(NSString* preStitchFileName);
    
    static void extractLUTFiles(const char* destDirectory, const char* lutBinFilePath, uint32_t fileOffset);
};

class MadvGLRendererImpl_iOS : public MadvGLRendererImpl {
public:
    
    virtual ~MadvGLRendererImpl_iOS();
    
    MadvGLRendererImpl_iOS(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments);
    
protected:
    
    void prepareTextureWithRenderSource(void* renderSource);
    
    void releaseGLObjects();
    
    //For iOS8HD
    struct __CVOpenGLESTextureCache * _videoTextureCache;
    struct __CVOpenGLESTexture *      _videoDestTexture;
    
    GLint _sourceTexture = -1;
};

void MadvGLRendererImpl_iOS::releaseGLObjects() {
    if(_videoDestTexture) {
        CFRelease(_videoDestTexture);
        _videoDestTexture = NULL;
    }
    
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
    
    if (_sourceTexture > 0)
    {
        glDeleteTextures(1, (GLuint*) &_sourceTexture);
        _sourceTexture = -1;
    }
}

MadvGLRendererImpl_iOS::~MadvGLRendererImpl_iOS() {
    releaseGLObjects();
}

MadvGLRendererImpl_iOS::MadvGLRendererImpl_iOS(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments)
: MadvGLRendererImpl(lutPath, leftSrcSize, rightSrcSize, longitudeSegments, latitudeSegments)
, _videoDestTexture(NULL)
, _videoTextureCache(NULL)
, _sourceTexture(-1)
{
    //prepareLUT(lutPath, leftSrcSize, rightSrcSize);
}

MadvGLRenderer_iOS::MadvGLRenderer_iOS(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments)
: MadvGLRenderer(new MadvGLRendererImpl_iOS(lutPath, leftSrcSize, rightSrcSize, longitudeSegments, latitudeSegments))
{
    
}

void findMaxAndMin(const GLushort* data, int length) {
    GLushort min = 10240, max = 0;
    for (int i=length; i>0; --i)
    {
        GLushort s = *data++;
        if (s > max) max = s;
        if (s < min) min = s;
    }
    NSLog(@"min = %d, max = %d", min, max);
}

//void MadvGLRenderer_iOS::prepareLUT(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize) {
////    GLfloat minXL, minYL, maxXL, maxYL, minXR, minYR, maxXR, maxYR;
//    if (NULL == lutPath) return;
//    NSString* nsLUTPath = [NSString stringWithUTF8String:lutPath];
//    UIImage* imgLXI = [UIImage imageWithContentsOfFile:[nsLUTPath stringByAppendingPathComponent:@"l_x_int.png"]];
//    UIImage* imgLXM = [UIImage imageWithContentsOfFile:[nsLUTPath stringByAppendingPathComponent:@"l_x_min.png"]];
//    UIImage* imgLYI = [UIImage imageWithContentsOfFile:[nsLUTPath stringByAppendingPathComponent:@"l_y_int.png"]];
//    UIImage* imgLYM = [UIImage imageWithContentsOfFile:[nsLUTPath stringByAppendingPathComponent:@"l_y_min.png"]];
//    UIImage* imgRXI = [UIImage imageWithContentsOfFile:[nsLUTPath stringByAppendingPathComponent:@"r_x_int.png"]];
//    UIImage* imgRXM = [UIImage imageWithContentsOfFile:[nsLUTPath stringByAppendingPathComponent:@"r_x_min.png"]];
//    UIImage* imgRYI = [UIImage imageWithContentsOfFile:[nsLUTPath stringByAppendingPathComponent:@"r_y_int.png"]];
//    UIImage* imgRYM = [UIImage imageWithContentsOfFile:[nsLUTPath stringByAppendingPathComponent:@"r_y_min.png"]];
//
//    CFDataRef LXIDataRef = CGDataProviderCopyData(CGImageGetDataProvider(imgLXI.CGImage));
//    const GLushort* LXIData = (const GLushort*) CFDataGetBytePtr(LXIDataRef);
//    
//    CFDataRef LXMDataRef = CGDataProviderCopyData(CGImageGetDataProvider(imgLXM.CGImage));
//    const GLushort* LXMData = (const GLushort*) CFDataGetBytePtr(LXMDataRef);
//    
//    CFDataRef LYIDataRef = CGDataProviderCopyData(CGImageGetDataProvider(imgLYI.CGImage));
//    const GLushort* LYIData = (const GLushort*) CFDataGetBytePtr(LYIDataRef);
//    
//    CFDataRef LYMDataRef = CGDataProviderCopyData(CGImageGetDataProvider(imgLYM.CGImage));
//    const GLushort* LYMData = (const GLushort*) CFDataGetBytePtr(LYMDataRef);
//    
//    CFDataRef RXIDataRef = CGDataProviderCopyData(CGImageGetDataProvider(imgRXI.CGImage));
//    const GLushort* RXIData = (const GLushort*) CFDataGetBytePtr(RXIDataRef);
//    
//    CFDataRef RXMDataRef = CGDataProviderCopyData(CGImageGetDataProvider(imgRXM.CGImage));
//    const GLushort* RXMData = (const GLushort*) CFDataGetBytePtr(RXMDataRef);
//    
//    CFDataRef RYIDataRef = CGDataProviderCopyData(CGImageGetDataProvider(imgRYI.CGImage));
//    const GLushort* RYIData = (const GLushort*) CFDataGetBytePtr(RYIDataRef);
//    
//    CFDataRef RYMDataRef = CGDataProviderCopyData(CGImageGetDataProvider(imgRYM.CGImage));
//    const GLushort* RYMData = (const GLushort*) CFDataGetBytePtr(RYMDataRef);
//    
//    NSInteger byteSize = CFDataGetLength(LXIDataRef);
//    NSInteger sizeInShort = byteSize / sizeof(GLushort);
//    
////    ///!!!For Debug:
////    findMaxAndMin(LXIData, (int)sizeInShort);
////    findMaxAndMin(LXMData, (int)sizeInShort);
////    findMaxAndMin(LYIData, (int)sizeInShort);
////    findMaxAndMin(LYMData, (int)sizeInShort);
////    findMaxAndMin(RXIData, (int)sizeInShort);
////    findMaxAndMin(RXMData, (int)sizeInShort);
////    findMaxAndMin(RYIData, (int)sizeInShort);
////    findMaxAndMin(RYMData, (int)sizeInShort);
//    
//    setLUTData(CGSize2Vec2f(imgLXI.size), leftSrcSize, rightSrcSize, (int)sizeInShort, LXIData, LXMData, LYIData, LYMData, RXIData, RXMData, RYIData, RYMData);
//    
//    CFRelease(LXIDataRef);
//    CFRelease(LXMDataRef);
//    CFRelease(LYIDataRef);
//    CFRelease(LYMDataRef);
//    CFRelease(RXIDataRef);
//    CFRelease(RXMDataRef);
//    CFRelease(RYIDataRef);
//    CFRelease(RYMDataRef);
//}

typedef struct {
    size_t width;
    size_t height;
    CGImageRef cgImage;
} CreateOrUpdateTextureWithBitmapBlockContext;

void createOrUpdateTextureWithBitmap(GLubyte *data, GLint pow2Width, GLint pow2Height, void* userData) {
    CreateOrUpdateTextureWithBitmapBlockContext* context = (CreateOrUpdateTextureWithBitmapBlockContext*) userData;
    size_t width = context->width;
    size_t height = context->height;
    CGImageRef cgImage = context->cgImage;
    delete context;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef cgContext = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextSetFillColorWithColor(cgContext, [UIColor clearColor].CGColor);
    CGContextSetBlendMode(cgContext, kCGBlendModeCopy);
    CGContextSetAlpha(cgContext, 1.0f);
    CGContextFillRect(cgContext, CGRectMake(0, 0, width, height));
    CGContextDrawImage(cgContext, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(cgContext);
    CGImageRelease(cgImage);
}

GLuint createTextureFromImage(UIImage* image, CGSize destSize) {
    CGImageRef cgImage = [image CGImage];
    CGImageRetain(cgImage);
    size_t width = (destSize.width == 0 ? CGImageGetWidth(cgImage) : destSize.width);
    size_t height = (destSize.height == 0 ? CGImageGetHeight(cgImage) : destSize.height);
    
    CreateOrUpdateTextureWithBitmapBlockContext* context = new CreateOrUpdateTextureWithBitmapBlockContext;
    context->width = width;
    context->height = height;
    context->cgImage = cgImage;
    
    GLuint texture = 0;
    createOrUpdateTexture(&texture, (GLint)width, (GLint)height, NULL, NULL, createOrUpdateTextureWithBitmap, context);
    
    return texture;
}

void MadvGLRendererImpl_iOS::prepareTextureWithRenderSource(void* renderSource) {
    id currentRenderSource = (__bridge_transfer id)renderSource;
    //NSLog(@"MadvGLRenderer_iOS::prepareTextureWithRenderSource : %lx", (long)renderSource);
    if ([currentRenderSource isKindOfClass:NSArray.class])
    {///For Debug Only:
        NSArray* images = currentRenderSource;
        UIImage* leftImg = images[0];
        UIImage* rightImg = images[1];
        GLuint srcTextureL = createTextureFromImage(leftImg, CGSizeZero);
        GLuint srcTextureR = createTextureFromImage(rightImg, CGSizeZero);
        setSourceTextures(/*true, */srcTextureL, srcTextureR, GL_TEXTURE_2D, false);
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
        setSourceTextures(/*false, */_sourceTexture, _sourceTexture, GL_TEXTURE_2D, false);
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
        setSourceTextures(/*false, */texture, texture, GL_TEXTURE_2D, false);
    }
#ifndef MADVPANO_EXPORT
    else if ([currentRenderSource isKindOfClass:KxVideoFrame.class])
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
            /* cleanUp Textures*/
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
            setSourceTextures(/*false, */texture, texture, GL_TEXTURE_2D, false);
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
            setSourceTextures(/*false, */_sourceTexture, _sourceTexture, GL_TEXTURE_2D, false);
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
    currentRenderSource = nil;
}
#ifndef MADVPANO_EXPORT
void MadvGLRenderer_iOS::extractLUTFiles(const char* destDirectory, const char* lutBinFilePath, uint32_t fileOffset) {
    ifstream ifs(lutBinFilePath, ios::in | ios::binary);
    DoctorLog(@"#Bug3763# extractLUTFiles : fileOffset=%u, destDirectory='%s', lutBinFilePath='%s'", fileOffset, destDirectory, lutBinFilePath);
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
    for (int i=0; i<8; ++i)
    {
        ifs.read((char*)&offsets[i], sizeof(uint32_t));
        ifs.read((char*)&sizes[i], sizeof(uint32_t));
        DoctorLog(@"#Bug3763# offsets[%d] = %u, sizes[%d] = %u", i,offsets[i], i,sizes[i]);
        if (sizes[i] > maxSize) maxSize = sizes[i];
        totalSize += sizes[i];
    }
    ifs.close();
    //    ALOGV("totalSize = %u", totalSize);
    
    const char* pngFileNames[] = {"/r_x_int.png", "/r_x_min.png",
        "/r_y_int.png", "/r_y_min.png",
        "/l_x_int.png", "/l_x_min.png",
        "/l_y_int.png", "/l_y_min.png"};
    char* pngFilePath = (char*) malloc(strlen(destDirectory) + strlen(pngFileNames[0]) + 1);
    
    uint8_t* pngData = (uint8_t*) malloc(maxSize);
    fstream ofs(lutBinFilePath, ios::out | ios::in | ios::binary);
    if (fileOffset >= Limit2G)
    {
        ofs.seekp(0x40000000, ios::beg);
        ofs.seekp(0x40000000, ios::cur);
        for (fileOffset -= Limit2G; fileOffset >= Limit2G; fileOffset -= Limit2G)
        {
            ofs.seekp(0x40000000, ios::cur);
            ofs.seekp(0x40000000, ios::cur);
        }
        ofs.seekp(fileOffset, ios::cur);
    }
    else
    {
        ofs.seekp(fileOffset, ios::beg);
    }
    
    uint64_t currentOffset = 0;
    for (int i=0; i<8; ++i)
    {
        ofs.seekp(offsets[i] - currentOffset, ios::cur);
        ofs.read((char*)pngData, sizes[i]);
        sprintf(pngFilePath, "%s%s", destDirectory, pngFileNames[i]);
        FILE* fout = fopen(pngFilePath, "wb");
        fwrite(pngData, sizes[i], 1, fout);
        fflush(fout);
        fclose(fout);
        ALOGE("#Bug3763# Written pngData into '%s'\n", pngFilePath);
        currentOffset = offsets[i] + sizes[i];
    }
    ofs.close();
    free(pngData);
    free(pngFilePath);
}

NSString* MadvGLRenderer_iOS::cameraLUTFilePath(NSString* cameraUUID) {
    NSString* lutFilePath = [[MVCameraClient formattedCameraUUID:cameraUUID] stringByAppendingString:@"_lut.bin"];
    lutFilePath = [z_Sandbox documentPath:lutFilePath];
    return lutFilePath;
}

NSString* loadDefaultLUT() {
    return [[[NSBundle mainBundle] pathForResource:@"l_x_int" ofType:@"png"] stringByDeletingLastPathComponent];
}

NSString* cameraOrDefaultLUT() {
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

NSString* MadvGLRenderer_iOS::preStitchPictureFileName(NSString* cameraUUID, NSString* fileName) {
    NSString* uuid = cameraUUID ? [MVCameraClient formattedCameraUUID:cameraUUID] : @"LOCAL";
    NSString* ret = [fileName stringByAppendingPathExtension:uuid];
    ret = [ret stringByAppendingPathExtension:PRESTITCH_PICTURE_EXTENSION];
    return ret;
}

NSString* MadvGLRenderer_iOS::stitchedPictureFileName(NSString* fileName) {
    if ([fileName hasSuffix:PRESTITCH_PICTURE_EXTENSION])
    {
        return [[fileName substringToIndex:(fileName.length - PRESTITCH_PICTURE_EXTENSION.length - 1)] stringByDeletingPathExtension];
    }
    else
    {
        return nil;
    }
}

NSString* MadvGLRenderer_iOS::cameraUUIDOfPreStitchFileName(NSString* preStitchFileName) {
    if ([preStitchFileName hasSuffix:PRESTITCH_PICTURE_EXTENSION])
    {
        return [[preStitchFileName substringToIndex:(preStitchFileName.length - PRESTITCH_PICTURE_EXTENSION.length - 1)] pathExtension];
    }
    else
    {
        return nil;
    }
}

NSString* makeTempLUTDirectory() {
    NSString* lutPath = [z_Sandbox documentPath:@"tmplut"];
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL isDirectory = YES;
    if (![fm fileExistsAtPath:lutPath isDirectory:&isDirectory] || !isDirectory)
    {
        [fm removeItemAtPath:lutPath error:nil];
        [fm createDirectoryAtPath:lutPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return lutPath;
}

#ifdef USE_PRESTORED_LUT
NSString* prestoredLUTPath() {
    NSString* directoryPath = [z_Sandbox documentPath:@"PrestoredLUT"];
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL isDirectory = YES;
    if (![fm fileExistsAtPath:directoryPath isDirectory:&isDirectory] || !isDirectory)
    {
        [fm removeItemAtPath:directoryPath error:nil];
        [fm createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSEnumerator* fileEnumerator = [fm enumeratorAtPath:directoryPath];
    if (!fileEnumerator.nextObject)
    {
        NSString* lutBinPath = [z_Sandbox documentPath:@"lut.bin"];
        MadvGLRenderer_iOS::extractLUTFiles(directoryPath.UTF8String, lutBinPath.UTF8String, 0);
    }
    return directoryPath;
}
#endif

NSString* MadvGLRenderer_iOS::lutPathOfSourceURI(NSString* sourceURI, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension) {
    DoctorLog(@"lutPathOfSourceURI : %@, forceLUTStitching = %d", sourceURI, forceLUTStitching);
#ifdef USE_PRESTORED_LUT
    return prestoredLUTPath();
#endif
    if (!sourceURI || 0 == sourceURI.length)
    {
        if (forceLUTStitching)
            return cameraOrDefaultLUT();
        else
            return nil;
    }
    
    NSString* lutPath = nil;
    NSString* lowerExt = [[sourceURI pathExtension] lowercaseString];
    if ([@"jpg" isEqualToString:lowerExt] || [@"png" isEqualToString:lowerExt] || [@"gif" isEqualToString:lowerExt] || [@"bmp" isEqualToString:lowerExt])
    {
        MadvEXIFExtension madvEXIFExtension;
        if (NULL != pMadvEXIFExtension)
        {
            madvEXIFExtension = *pMadvEXIFExtension;
        }
        else
        {
            madvEXIFExtension = readMadvEXIFExtensionFromJPEG(sourceURI.UTF8String);
        }
        
        if (StitchTypeStitched != madvEXIFExtension.sceneType && !lutPath)
        {
            forceLUTStitching = YES;

            if (madvEXIFExtension.withEmbeddedLUT)
            {
                if (madvEXIFExtension.embeddedLUTOffset > 0)
                {
                    lutPath = makeTempLUTDirectory();
                    extractLUTFiles(lutPath.UTF8String, sourceURI.UTF8String, (uint32_t)madvEXIFExtension.embeddedLUTOffset);
                    return lutPath;
                }
            }
        }
        
//        if ([sourceURI hasSuffix:PRESTITCH_PICTURE_EXTENSION] && !lutPath)
//        {
//            forceLUTStitching = YES;
//
//            NSString* cameraUUID = cameraUUIDOfPreStitchFileName(sourceURI);
//            lutPath = [cameraLUTFilePath(cameraUUID) stringByDeletingPathExtension];
//
//            BOOL isDirectory;
//            if (![[NSFileManager defaultManager] fileExistsAtPath:[lutPath stringByAppendingPathComponent:@"l_x_int.png"] isDirectory:&isDirectory] || isDirectory)
//            {
//                return nil;
//            }
//        }
        
        if (forceLUTStitching && !lutPath)
        {
            lutPath = cameraOrDefaultLUT();
        }
    }
    else if ([@"dng" isEqualToString:lowerExt])
    {
        MadvEXIFExtension madvEXIFExtension;
        if (NULL != pMadvEXIFExtension)
        {
            madvEXIFExtension = *pMadvEXIFExtension;
        }
        else
        {
            std::list<std::list<DirectoryEntry> > IFDList;
            madvEXIFExtension = readMadvEXIFExtensionFromRaw(sourceURI.UTF8String, NULL, IFDList);
        }
        
        if (StitchTypeStitched != madvEXIFExtension.sceneType && !lutPath)
        {
            forceLUTStitching = YES;
            
            if (madvEXIFExtension.withEmbeddedLUT)
            {
                if (madvEXIFExtension.embeddedLUTOffset > 0)
                {
                    lutPath = makeTempLUTDirectory();
                    extractLUTFiles(lutPath.UTF8String, sourceURI.UTF8String, (uint32_t)madvEXIFExtension.embeddedLUTOffset);
                    return lutPath;
                }
            }
        }
    }
    else if ([sourceURI hasPrefix:AMBA_CAMERA_RTSP_URL_ROOT] || [sourceURI hasPrefix:HTTP_DOWNLOAD_URL_PREFIX])
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
                lutPath = makeTempLUTDirectory();
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
    EAGLContext* eaglContext = [EAGLContext currentContext];
    if (!eaglContext)
    {
        eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    }
    [EAGLContext setCurrentContext:eaglContext];
    {
        GLuint sourceTexture = createTextureFromImage(sourceImage, CGSizeZero);
        
        GLRenderTexture renderTexture(destSize.width, destSize.height);
        pixelData = (GLubyte*) malloc(renderTexture.bytesLength());
#ifdef USE_MSAA
        glBindFramebuffer(GL_FRAMEBUFFER, _msaaFramebuffer);
#else
        renderTexture.blit();
#endif
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        CHECK_GL_ERROR();
        NSLog(@"status = 0x%x", status);
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ZERO);
        glViewport(0, 0, destSize.width, destSize.height);
        CHECK_GL_ERROR();
        
        glClearColor(0, 0, 0, 0);
        glClear(GL_COLOR_BUFFER_BIT);
        CHECK_GL_ERROR();
        
        AutoRef<GLRenderTexture> filterRenderTexture = NULL;
        AutoRef<GLFilterCache> filterCache = NULL;
        //*///!!!For Debug
        if (filterID > 0)
        {
            filterCache = new GLFilterCache([[[NSBundle mainBundle] pathForResource:@"lookup" ofType:@"png"] stringByDeletingLastPathComponent].UTF8String);
            filterRenderTexture = new GLRenderTexture(destSize.width, destSize.height);
            filterRenderTexture->blit();
        }
        
        AutoRef<MadvGLRenderer> renderer = new MadvGLRenderer_iOS(lutPath.UTF8String, Vec2f{DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT}, Vec2f{DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT}, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
        renderer->setIsYUVColorSpace(false);
        renderer->setDisplayMode((lutPath ? PanoramaDisplayModeLUTInShader : 0));/// | PanoramaDisplayModeReFlatten);
        renderer->setSourceTextures(sourceTexture, sourceTexture, GL_TEXTURE_2D, false);
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
                renderer->setModelPostRotation({0.f, 1.f, 0.f}, {0.f, 0.f, 1.f});
                renderer->setDisplayMode((lutPath ? PanoramaDisplayModeLUTInShader : 0) | PanoramaDisplayModeStereoGraphic);
                renderer->glCamera()->setFOVDegree(270);
                break;
            case FPS120_TOP_1920x480:
                renderer->setModelPostRotation({0.f, 1.f, 0.f}, {0.f, 0.f, -1.f});
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
                    renderer->setGyroMatrix(gyroMatrix, gyroMatrixRank);
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
        //*/
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

UIImage* MadvGLRenderer_iOS::renderJPEG(const char* sourcePath, CGSize destSize, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank) {
    NSString* sourceURI = [NSString stringWithUTF8String:sourcePath];
    NSString* lutPath = lutPathOfSourceURI(sourceURI, forceLUTStitching, pMadvEXIFExtension);
    //*
    GLubyte* pixelData = NULL;
    EAGLContext* eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:eaglContext];
    {
        GLint sourceTexture = createTextureWithJPEG(sourcePath);
        if (0 >= sourceTexture)
        {
            GLint maxTextureSize = 0;
            glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
            NSLog(@"prepareTextureWithRenderSource : GL_MAX_TEXTURE_SIZE = %d", maxTextureSize);
            UIImage* image = [UIImage imageWithContentsOfFile:[NSString stringWithUTF8String:sourcePath]];
            sourceTexture = createTextureFromImage(image, CGSizeMake(MIN(image.size.width, maxTextureSize), MIN(image.size.height, maxTextureSize)));
        }
        
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
        kmMat4 textureMatrix;
        kmMat4Fill(&textureMatrix, textureMatrixData);
        renderer->setTextureMatrix(&textureMatrix);
        renderer->setFlipY(true);
        ///!!!} Important
        if (gyroMatrixRank > 0)
        {
            renderer->setGyroMatrix(gyroMatrix, gyroMatrixRank);
        }
        ///renderer->draw(0,0, destSize.width,destSize.height);
        GLuint cubemapTexture = renderer->drawToRemappedCubemap(0, roundf(destSize.height * 0.57735));
        renderer->drawFromCubemap(0, 0, destSize.width, destSize.height, cubemapTexture);
        glDeleteTextures(1, &cubemapTexture);
        
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
        
        glDeleteTextures(1, (GLuint*)&sourceTexture);
    }
    //*/!!!For Debug 0320:
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
    
    return renderedImage;
    /*/
    free(pixelData);
    return nil;
    //*/
}

void MadvGLRenderer_iOS::renderJPEGToJPEG(NSString* destJpegPath, NSString* sourcePath, int dstWidth, int dstHeight, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank) {
    NSString* lutPath = lutPathOfSourceURI(sourcePath, forceLUTStitching, pMadvEXIFExtension);
    EAGLContext* eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:eaglContext];
    {
        MadvGLRenderer::renderMadvJPEGToJPEG(destJpegPath.UTF8String, sourcePath.UTF8String, dstWidth, dstHeight, lutPath.UTF8String, filterID, [[[NSBundle mainBundle] pathForResource:@"lookup" ofType:@"png"] stringByDeletingLastPathComponent].UTF8String, gyroMatrix, gyroMatrixRank, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
    }
    [EAGLContext setCurrentContext:nil];
}

void MadvGLRenderer_iOS::renderJPEGToJPEG(NSString* destJpegPath, NSString* sourcePath, int dstWidth, int dstHeight, NSString* lutPath, int filterID, float* gyroMatrix, int gyroMatrixRank) {
    EAGLContext* eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:eaglContext];
    {
        MadvGLRenderer::renderMadvJPEGToJPEG(destJpegPath.UTF8String, sourcePath.UTF8String, dstWidth, dstHeight, lutPath.UTF8String, filterID, [[[NSBundle mainBundle] pathForResource:@"lookup" ofType:@"png"] stringByDeletingLastPathComponent].UTF8String, gyroMatrix, gyroMatrixRank, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
    }
    [EAGLContext setCurrentContext:nil];
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

+ (void) extractLUTFiles:(const char*)destDirectory lutBinFilePath:(const char*)lutBinFilePath fileOffset:(uint32_t)fileOffset {
    MadvGLRenderer_iOS::extractLUTFiles(destDirectory, lutBinFilePath, fileOffset);
}
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

- (void) setGyroMatrix:(float*)matrix rank:(int)rank {
    if (NULL == _impl)
        return;
    
    _impl->setGyroMatrix(matrix, rank);
}

- (void) setModelPostRotationFrom:(kmVec3)fromVector to:(kmVec3)toVector {
    if (NULL == _impl)
        return;
    
    _impl->setModelPostRotation(fromVector, toVector);
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
