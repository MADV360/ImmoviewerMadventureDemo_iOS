//
//  MadvGLRendererBase_iOS.mm
//  Madv360_v1
//
//  Created by FutureBoy on 4/2/16.
//  Copyright © 2016 Cyllenge. All rights reserved.
//

#include "MadvGLRendererBase_iOS.h"
#ifndef MADVPANO_EXPORT

///!!!#import "z_Sandbox.h"
///!!!#import "NSString+Extensions.h"
#endif
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>
#import <fstream>

#ifdef MADVPANO_BY_SOURCE
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

void cgDataProviderReleaseDataCallback(void * __nullable info, const void *  data, size_t size) {
    free((void*) data);
}

void MadvGLRendererImplBase_iOS::releaseGLObjects() {
    if (_sourceTexture > 0)
    {
        glDeleteTextures(1, (GLuint*) &_sourceTexture);
        _sourceTexture = -1;
    }
}

MadvGLRendererImplBase_iOS::~MadvGLRendererImplBase_iOS() {
    releaseGLObjects();
}

MadvGLRendererImplBase_iOS::MadvGLRendererImplBase_iOS(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments)
: MadvGLRendererImpl(lutPath, leftSrcSize, rightSrcSize, longitudeSegments, latitudeSegments)
, _sourceTexture(-1)
{
    //prepareLUT(lutPath, leftSrcSize, rightSrcSize);
}

MadvGLRendererBase_iOS::MadvGLRendererBase_iOS(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments)
: MadvGLRenderer(new MadvGLRendererImplBase_iOS(lutPath, leftSrcSize, rightSrcSize, longitudeSegments, latitudeSegments))
{
    
}

MadvGLRendererBase_iOS::MadvGLRendererBase_iOS(void* impl)
: MadvGLRenderer(impl)
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

//void MadvGLRendererBase_iOS::prepareLUT(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize) {
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

void MadvGLRendererImplBase_iOS::prepareTextureWithRenderSource(void* renderSource) {
    id currentRenderSource = (__bridge id)renderSource;
    //NSLog(@"MadvGLRendererBase_iOS::prepareTextureWithRenderSource : %lx", (long)renderSource);
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
//    currentRenderSource = nil;
}
#ifndef MADVPANO_EXPORT
/*
 void MadvGLRendererBase_iOS::extractLUTFiles(const char* destDirectory, const char* lutBinFilePath, uint32_t fileOffset) {
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
 //*/
NSString* loadDefaultLUT() {
    return [[[NSBundle mainBundle] pathForResource:@"l_x_int" ofType:@"png"] stringByDeletingLastPathComponent];
}

#define PRESTITCH_PICTURE_EXTENSION @"prestitch.jpg"

NSString* MadvGLRendererBase_iOS::stitchedPictureFileName(NSString* fileName) {
    if ([fileName hasSuffix:PRESTITCH_PICTURE_EXTENSION])
    {
        return [[fileName substringToIndex:(fileName.length - PRESTITCH_PICTURE_EXTENSION.length - 1)] stringByDeletingPathExtension];
    }
    else
    {
        return nil;
    }
}

NSString* MadvGLRendererBase_iOS::cameraUUIDOfPreStitchFileName(NSString* preStitchFileName) {
    if ([preStitchFileName hasSuffix:PRESTITCH_PICTURE_EXTENSION])
    {
        return [[preStitchFileName substringToIndex:(preStitchFileName.length - PRESTITCH_PICTURE_EXTENSION.length - 1)] pathExtension];
    }
    else
    {
        return nil;
    }
}

#include <stdlib.h>

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
        extractLUTFiles(directoryPath.UTF8String, lutBinPath.UTF8String, 0);
    }
    return directoryPath;
}
#endif

NSString* MadvGLRendererBase_iOS::lutPathOfSourceURI_base(NSString* sourceURI, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension) {
#ifdef USE_PRESTORED_LUT
    return prestoredLUTPath();
#endif
    if (!sourceURI || 0 == sourceURI.length)
    {/*///!!!
        if (forceLUTStitching)
            return cameraOrDefaultLUT();
        else//*/
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
                    lutPath = makeTempLUTDirectory(sourceURI);
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
        /*
        if (forceLUTStitching && !lutPath)
        {
            lutPath = cameraOrDefaultLUT();
        }//*/
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
                    lutPath = makeTempLUTDirectory(sourceURI);
                    extractLUTFiles(lutPath.UTF8String, sourceURI.UTF8String, (uint32_t)madvEXIFExtension.embeddedLUTOffset);
                    return lutPath;
                }
            }
        }
    }/*///!!!
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
    else if (forceLUTStitching)
    {
        lutPath = cameraOrDefaultLUT();
        DoctorLog(@"lutPathOfSourceURI : #5 lutPath='%@'", lutPath);
    }
    else
    {
        lutPath = nil;
        DoctorLog(@"lutPathOfSourceURI : Video from other stream, no LUT stitching");
    }//*/
    return lutPath;
}

//[MadvGLRenderer renderThumbnail:@"thumb.h264" destSize:CGSizeMake(1920, 1080)];

UIImage* MadvGLRendererBase_iOS::renderJPEG(const char* sourcePath, CGSize destSize, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank) {
    NSString* sourceURI = [NSString stringWithUTF8String:sourcePath];
    NSString* lutPath = lutPathOfSourceURI_base(sourceURI, forceLUTStitching, pMadvEXIFExtension);
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
        
        AutoRef<MadvGLRenderer> renderer = new MadvGLRendererBase_iOS(lutPath.UTF8String, Vec2f{DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT}, Vec2f{DEFAULT_LUT_VALUE_WIDTH, DEFAULT_LUT_VALUE_HEIGHT}, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
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
        kmMat4 textureMatrix;
        kmMat4Fill(&textureMatrix, textureMatrixData);
        renderer->setTextureMatrix(&textureMatrix);
        renderer->setFlipY(true);
        ///!!!} Important
        if (gyroMatrixRank > 0)
        {
            panoController->setGyroMatrix(gyroMatrix, gyroMatrixRank);
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

void MadvGLRendererBase_iOS::renderJPEGToJPEG(NSString* destJpegPath, NSString* sourcePath, int dstWidth, int dstHeight, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank) {
    NSString* lutPath = lutPathOfSourceURI_base(sourcePath, forceLUTStitching, pMadvEXIFExtension);
    EAGLContext* eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:eaglContext];
    {
        NSString* resourcePath = [[[NSBundle mainBundle] pathForResource:@"lookup" ofType:@"png"] stringByDeletingLastPathComponent];
#ifdef USE_IMAGE_BLENDER
        NSString* tmpJPEGPath = (0 != gyroMatrixRank) ? [destJpegPath stringByAppendingPathExtension:@"tmp.jpg"] : destJpegPath;
        // 1. Stitch with no rotation:
        NSString* tmp0JPEGPath = [destJpegPath stringByAppendingPathExtension:@"0.tmp.jpg"];
        MadvGLRenderer::renderMadvJPEGToJPEG(tmp0JPEGPath.UTF8String, sourcePath.UTF8String, dstWidth, dstHeight, lutPath.UTF8String, filterID, resourcePath.UTF8String, NULL, 0, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
        // 2. Save EXIF metadata:
        long sourceExivImageHandler = createExivImage(tmp0JPEGPath.UTF8String);
        // 3. Blend with MBB by OpenCV:
        blendImage(tmpJPEGPath.UTF8String, tmp0JPEGPath.UTF8String);
        // 4. Restore EXIF metadata:
        copyEXIFDataFromExivImage(tmpJPEGPath.UTF8String, sourceExivImageHandler);
        releaseExivImage(sourceExivImageHandler);
        [[NSFileManager defaultManager] removeItemAtPath:tmp0JPEGPath error:nil];
        // 5. Rotate with gyro calibration matrix (if any):
        if (0 != gyroMatrixRank)
        {
            MadvGLRenderer::renderMadvJPEGToJPEG(destJpegPath.UTF8String, tmpJPEGPath.UTF8String, dstWidth, dstHeight, NULL, 0, resourcePath.UTF8String, gyroMatrix, gyroMatrixRank, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
            [[NSFileManager defaultManager] removeItemAtPath:tmpJPEGPath error:nil];
        }
#else
        MadvGLRenderer::renderMadvJPEGToJPEG(destJpegPath.UTF8String, sourcePath.UTF8String, dstWidth, dstHeight, lutPath.UTF8String, filterID, resourcePath.UTF8String, gyroMatrix, gyroMatrixRank, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
#endif
        exifPrint(destJpegPath.UTF8String, std::cout);///!!!For Debug
    }
    [EAGLContext setCurrentContext:nil];
}

void MadvGLRendererBase_iOS::renderJPEGToJPEG(NSString* destJpegPath, NSString* sourcePath, int dstWidth, int dstHeight, NSString* lutPath, int filterID, float* gyroMatrix, int gyroMatrixRank) {
    EAGLContext* eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:eaglContext];
    {
        NSString* resourcePath = [[[NSBundle mainBundle] pathForResource:@"lookup" ofType:@"png"] stringByDeletingLastPathComponent];
#ifdef USE_IMAGE_BLENDER
        NSString* tmpJPEGPath = (0 != gyroMatrixRank) ? [destJpegPath stringByAppendingPathExtension:@"tmp.jpg"] : destJpegPath;
        // 1. Stitch with no rotation:
        NSString* tmp0JPEGPath = [destJpegPath stringByAppendingPathExtension:@"0.tmp.jpg"];
        MadvGLRenderer::renderMadvJPEGToJPEG(tmp0JPEGPath.UTF8String, sourcePath.UTF8String, dstWidth, dstHeight, lutPath.UTF8String, filterID, resourcePath.UTF8String, NULL, 0, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
        // 2. Save EXIF metadata:
        long sourceExivImageHandler = createExivImage(tmp0JPEGPath.UTF8String);
        // 3. Blend with MBB by OpenCV:
        blendImage(tmpJPEGPath.UTF8String, tmp0JPEGPath.UTF8String);
        // 4. Restore EXIF metadata:
        copyEXIFDataFromExivImage(tmpJPEGPath.UTF8String, sourceExivImageHandler);
        releaseExivImage(sourceExivImageHandler);
        [[NSFileManager defaultManager] removeItemAtPath:tmp0JPEGPath error:nil];
        // 5. Rotate with gyro calibration matrix (if any):
        if (0 != gyroMatrixRank)
        {
            MadvGLRenderer::renderMadvJPEGToJPEG(destJpegPath.UTF8String, tmpJPEGPath.UTF8String, dstWidth, dstHeight, NULL, 0, resourcePath.UTF8String, gyroMatrix, gyroMatrixRank, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
            [[NSFileManager defaultManager] removeItemAtPath:tmpJPEGPath error:nil];
        }
#else
        MadvGLRenderer::renderMadvJPEGToJPEG(destJpegPath.UTF8String, sourcePath.UTF8String, dstWidth, dstHeight, lutPath.UTF8String, filterID, resourcePath.UTF8String, gyroMatrix, gyroMatrixRank, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
#endif
        exifPrint(destJpegPath.UTF8String, std::cout);///!!!For Debug
    }
    [EAGLContext setCurrentContext:nil];
}

#endif //#ifndef MADVPANO_EXPORT
