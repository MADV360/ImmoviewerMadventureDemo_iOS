//
//  JPEGUtils.h
//  ClumsyCopter
//
//  Created by FutureBoy on 2/10/15.
//
//

#ifndef __ClumsyCopter__JPEGUtils__
#define __ClumsyCopter__JPEGUtils__

#include "OpenGLHelper.h"
#include <stdio.h>
#include <setjmp.h>

#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
#define HAVE_BOOLEAN
#endif
#include "jpeglib.h"

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

/*
 * ERROR HANDLING:
 *
 * The JPEG library's standard error handler (jerror.c) is divided into
 * several "methods" which you can override individually.  This lets you
 * adjust the behavior without duplicating a lot of code, which you might
 * have to update with each future release.
 *
 * Our example here shows how to override the "error_exit" method so that
 * control is returned to the library's caller when a fatal error occurs,
 * rather than calling exit() as the standard error_exit method does.
 *
 * We use C's setjmp/longjmp facility to return control.  This means that the
 * routine which calls the JPEG library must first execute a setjmp() call to
 * establish the return point.  We want the replacement error_exit to do a
 * longjmp().  But we need to make the setjmp buffer accessible to the
 * error_exit routine.  To do this, we make a private extension of the
 * standard JPEG error handler object.  (If we were using C++, we'd say we
 * were making a subclass of the regular error handler.)
 *
 * Here's the extended error handler struct:
 */

typedef struct {
    struct jpeg_compress_struct cinfo;
    FILE* destFile;
    unsigned char* destMem;
} JPEGCompressOutput;

typedef void(*JPEGDecodeLineCallback)(struct jpeg_decompress_struct* cinfo, JSAMPROW sampleRow, int lineNumber, void* userParams, bool finished);

	MADVPANO_API void writeImageToJPEG(const char* filename,
                           GLenum colorspace, GLenum bitformat, int quality,
                           unsigned char* imageData, int imageWidth, int imageHeight);
    
	MADVPANO_API void writeImageToJPEGData(unsigned char** dstBuffer, unsigned long* dstBufferSize,
                          GLenum colorspace, GLenum bitformat, int quality,
                          unsigned char* imageData, int imageWidth, int imageHeight);

	MADVPANO_API JPEGCompressOutput* startWritingImageToJPEG(const char* filename, GLenum colorspace, GLenum bitformat, int quality, int imageWidth, int imageHeight);
	MADVPANO_API JPEGCompressOutput* startWritingImageToJPEGMem(unsigned char** outData, unsigned long* outSize, GLenum colorspace, GLenum bitformat, int quality, int imageWidth, int imageHeight);
    
	MADVPANO_API bool appendImageStrideToJPEG(const JPEGCompressOutput* output, unsigned char* imageData, int lines, bool reverseOrder = false);
    
	MADVPANO_API jpeg_decompress_struct readImageFromJPEG(unsigned char* outPixelData,
                                            GLenum colorspace, GLenum bitformat,
                                            const char* filename);
    
	MADVPANO_API jpeg_decompress_struct readImageInfoFromJPEG(const char* filename);
    
	MADVPANO_API jpeg_decompress_struct readImageFromJPEGData(unsigned char* outPixelData,
                                           GLenum colorspace, GLenum bitformat,
                                           unsigned char* srcBuffer, unsigned long srcBufferSize);
    
	MADVPANO_API jpeg_decompress_struct allocateReadImageFromJPEG(unsigned char** outPixelDataPtr, int* outBytesPtr,
                                             GLenum colorspace, GLenum bitformat,
                                             const char* filename);
    
	MADVPANO_API jpeg_decompress_struct allocateReadImageFromJPEGData(unsigned char** outPixelDataPtr, int* outBytesPtr,
                                                         GLenum colorspace, GLenum bitformat,
                                                         unsigned char* srcBuffer, unsigned long srcBufferSize);

	MADVPANO_API jpeg_decompress_struct readImageFromJPEGWithCallback(JPEGDecodeLineCallback callback, void* userParams, GLenum colorspace, GLenum bitformat, int scaleNum, int scaleDenom, const char* filename);

	MADVPANO_API GLint createTextureWithJPEG(const char* filePath, Vec2f* outTextureSize = NULL);

    MADVPANO_API GLint createTextureWithDNG(FILE* fpStartsFromData, GLuint width, GLuint height, GLint internalFormat, GLenum format, GLenum type, int rawBits = 12);
    
#ifdef __cplusplus
}
#endif

#endif /* defined(__ClumsyCopter__JPEGUtils__) */
