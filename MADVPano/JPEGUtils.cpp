//
//  JPEGUtils.cpp
//  ClumsyCopter
//
//  Created by FutureBoy on 2/10/15.
//
//

#include "JPEGUtils.h"
#include "EXIFParser.h"
#include <stdlib.h>
#include <string>
#include <string.h>
#include <setjmp.h>
#include <math.h>

//#define USE_MEM_IO

#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
//#pragma comment(lib, "libjpeg_a.lib")
//#pragma comment(lib, "libjpeg.lib")
#pragma comment(lib, "jpeg.lib")
#pragma comment(lib, "turbojpeg.lib")
#else
#include <sys/errno.h>
#endif

typedef struct jpeg_error_info_struct {
    struct jpeg_error_mgr pub;    /* "public" fields */

    jmp_buf setjmp_buffer;        /* for return to caller */
} jpeg_error_info;

typedef struct jpeg_error_info_struct* jpeg_error_info_ptr;

inline J_COLOR_SPACE jtColorSpaceOfPixelType(GLenum colorspace) {
    switch (colorspace)
    {
        case GL_RGB:
            return JCS_RGB;
        case GL_RGBA:
            return JCS_EXT_RGBA;
        case GL_DEPTH_COMPONENT:
        case GL_ALPHA:
        case GL_LUMINANCE:
        case GL_LUMINANCE_ALPHA:
            return JCS_GRAYSCALE;
        default:
            return JCS_UNKNOWN;
    }
}

inline int jtColorComponentsOfPixelType(GLenum colorspace, GLenum bitformat) {
    switch (bitformat)
    {
        case GL_UNSIGNED_BYTE:
            switch (colorspace)
        {
            case GL_RGB:
                return 3;
            case GL_RGBA:
                return 4;
            case GL_LUMINANCE_ALPHA:
                return 2;
            case GL_LUMINANCE:
            case GL_ALPHA:
                return 1;
            default:
                return 0;
        }
            break;
            
        case GL_UNSIGNED_SHORT_4_4_4_4:
//        case GL_UNSIGNED_SHORT_4_4_4_4_REV:
            return 2;
        case GL_UNSIGNED_SHORT_5_6_5:
            return 2;
        case GL_UNSIGNED_SHORT_5_5_5_1:
//        case GL_UNSIGNED_SHORT_1_5_5_5_REV:
            return 2;
        case GL_UNSIGNED_SHORT_8_8_APPLE:
        case GL_UNSIGNED_SHORT_8_8_REV_APPLE:
            return 2;
        default:
            return 0;
    }
}

void writeImageToJPEG(const char* filename,
                       GLenum colorspace, GLenum bitformat, int quality,
                       unsigned char* imageData, int imageWidth, int imageHeight)
{
    /* This struct contains the JPEG compression parameters and pointers to
     * working space (which is allocated as needed by the JPEG library).
     * It is possible to have several such structures, representing multiple
     * compression/decompression processes, in existence at once.  We refer
     * to any one struct (and its associated working data) as a "JPEG object".
     */
    struct jpeg_compress_struct cinfo;
    /* This struct represents a JPEG error handler.  It is declared separately
     * because applications often want to supply a specialized error handler
     * (see the second half of this file for an example).  But here we just
     * take the easy way out and use the standard error handler, which will
     * print a message on stderr and call exit() if compression fails.
     * Note that this struct must live as long as the main JPEG parameter
     * struct, to avoid dangling-pointer problems.
     */
    struct jpeg_error_mgr jerr;
    /* More stuff */
    FILE * outfile;               /* target file */
    JSAMPROW row_pointer[1];      /* pointer to JSAMPLE row[s] */
    int row_stride;               /* physical row width in image buffer */
    
    /* Step 1: allocate and initialize JPEG compression object */
    
    /* We have to set up the error handler first, in case the initialization
     * step fails.  (Unlikely, but it could happen if you are out of memory.)
     * This routine fills in the contents of struct jerr, and returns jerr's
     * address which we place into the link field in cinfo.
     */
    cinfo.err = jpeg_std_error(&jerr);
    /* Now we can initialize the JPEG compression object. */
    jpeg_create_compress(&cinfo);
    
    /* Step 2: specify data destination (eg, a file) */
    /* Note: steps 2 and 3 can be done in either order. */
    
    /* Here we use the library-supplied code to send compressed data to a
     * stdio stream.  You can also write your own code to do something else.
     * VERY IMPORTANT: use "b" option to fopen() if you are on a machine that
     * requires it in order to write binary files.
     */
    if ((outfile = fopen(filename, "wb+")) == NULL) {
        fprintf(stderr, "can't open %s\n", filename);
        exit(1);
    }
    jpeg_stdio_dest(&cinfo, outfile);
    
    /* Step 3: set parameters for compression */
    
    /* First we supply a description of the input image.
     * Four fields of the cinfo struct must be filled in:
     */
    cinfo.image_width = imageWidth;      /* image width and height, in pixels */
    cinfo.image_height = imageHeight;
    cinfo.input_components = jtColorComponentsOfPixelType(colorspace, bitformat);           /* # of color components per pixel */
    cinfo.in_color_space = jtColorSpaceOfPixelType(colorspace);       /* colorspace of input image */
    /* Now use the library's routine to set default compression parameters.
     * (You must set at least cinfo.in_color_space before calling this,
     * since the defaults depend on the source color space.)
     */
    jpeg_set_defaults(&cinfo);
    /* Now you can set any non-default parameters you wish to.
     * Here we just illustrate the use of quality (quantization table) scaling:
     */
    jpeg_set_quality(&cinfo, quality, TRUE /* limit to baseline-JPEG values */);
    
    /* Step 4: Start compressor */
    
    /* TRUE ensures that we will write a complete interchange-JPEG file.
     * Pass TRUE unless you are very sure of what you're doing.
     */
    jpeg_start_compress(&cinfo, TRUE);
    
    /* Step 5: while (scan lines remain to be written) */
    /*           jpeg_write_scanlines(...); */
    
    /* Here we use the library's state variable cinfo.next_scanline as the
     * loop counter, so that we don't have to keep track ourselves.
     * To keep things simple, we pass one scanline per call; you can pass
     * more if you wish, though.
     */
    row_stride = imageWidth * cinfo.input_components; /* JSAMPLEs per row in image_buffer */
    
    while (cinfo.next_scanline < cinfo.image_height) {
        /* jpeg_write_scanlines expects an array of pointers to scanlines.
         * Here the array is only one element long, but you could pass
         * more than one scanline at a time if that's more convenient.
         */
        row_pointer[0] = & imageData[cinfo.next_scanline * row_stride];
        jpeg_write_scanlines(&cinfo, row_pointer, 1);
    }
    
    /* Step 6: Finish compression */
    
    jpeg_finish_compress(&cinfo);
    /* After finish_compress, we can close the output file. */
    fclose(outfile);
    
    /* Step 7: release JPEG compression object */
    
    /* This is an important step since it will release a good deal of memory. */
    jpeg_destroy_compress(&cinfo);
    
    /* And we're done! */
}

JPEGCompressOutput* startWritingImageToJPEG(const char* filename, GLenum colorspace, GLenum bitformat, int quality, int imageWidth, int imageHeight)
{
    JPEGCompressOutput* ret = new JPEGCompressOutput;
    /* This struct contains the JPEG compression parameters and pointers to
     * working space (which is allocated as needed by the JPEG library).
     * It is possible to have several such structures, representing multiple
     * compression/decompression processes, in existence at once.  We refer
     * to any one struct (and its associated working data) as a "JPEG object".
     */
    struct jpeg_compress_struct& cinfo = ret->cinfo;
    /* This struct represents a JPEG error handler.  It is declared separately
     * because applications often want to supply a specialized error handler
     * (see the second half of this file for an example).  But here we just
     * take the easy way out and use the standard error handler, which will
     * print a message on stderr and call exit() if compression fails.
     * Note that this struct must live as long as the main JPEG parameter
     * struct, to avoid dangling-pointer problems.
     */
    struct jpeg_error_mgr jerr;
    /* More stuff */
    FILE*& outfile = ret->destFile;               /* target file */

    /* Step 1: allocate and initialize JPEG compression object */

    /* We have to set up the error handler first, in case the initialization
     * step fails.  (Unlikely, but it could happen if you are out of memory.)
     * This routine fills in the contents of struct jerr, and returns jerr's
     * address which we place into the link field in cinfo.
     */
    cinfo.err = jpeg_std_error(&jerr);
    /* Now we can initialize the JPEG compression object. */
    jpeg_create_compress(&cinfo);

    /* Step 2: specify data destination (eg, a file) */
    /* Note: steps 2 and 3 can be done in either order. */

    /* Here we use the library-supplied code to send compressed data to a
     * stdio stream.  You can also write your own code to do something else.
     * VERY IMPORTANT: use "b" option to fopen() if you are on a machine that
     * requires it in order to write binary files.
     */
    if ((outfile = fopen(filename, "wb+")) == NULL) {
        fprintf(stderr, "can't open %s\n", filename);
        exit(1);
    }
    jpeg_stdio_dest(&cinfo, outfile);

    /* Step 3: set parameters for compression */

    /* First we supply a description of the input image.
     * Four fields of the cinfo struct must be filled in:
     */
    cinfo.image_width = imageWidth;      /* image width and height, in pixels */
    cinfo.image_height = imageHeight;
    cinfo.input_components = jtColorComponentsOfPixelType(colorspace, bitformat);           /* # of color components per pixel */
    cinfo.in_color_space = jtColorSpaceOfPixelType(colorspace);       /* colorspace of input image */
    /* Now use the library's routine to set default compression parameters.
     * (You must set at least cinfo.in_color_space before calling this,
     * since the defaults depend on the source color space.)
     */
    jpeg_set_defaults(&cinfo);
    /* Now you can set any non-default parameters you wish to.
     * Here we just illustrate the use of quality (quantization table) scaling:
     */
    jpeg_set_quality(&cinfo, quality, TRUE /* limit to baseline-JPEG values */);

    /* Step 4: Start compressor */

    /* TRUE ensures that we will write a complete interchange-JPEG file.
     * Pass TRUE unless you are very sure of what you're doing.
     */
    jpeg_start_compress(&cinfo, TRUE);

    return ret;
}
#ifdef USE_MEM_IO
JPEGCompressOutput* startWritingImageToJPEGMem(unsigned char** outData, unsigned long* outSize, GLenum colorspace, GLenum bitformat, int quality, int imageWidth, int imageHeight)
{
    JPEGCompressOutput* ret = new JPEGCompressOutput;
    
    struct jpeg_compress_struct& cinfo = ret->cinfo;
    struct jpeg_error_mgr jerr;
    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_compress(&cinfo);
    jpeg_mem_dest(&cinfo, outData, outSize);
    ret->destMem = *outData;
    
    cinfo.image_width = imageWidth;      /* image width and height, in pixels */
    cinfo.image_height = imageHeight;
    cinfo.input_components = jtColorComponentsOfPixelType(colorspace, bitformat);           /* # of color components per pixel */
    cinfo.in_color_space = jtColorSpaceOfPixelType(colorspace);       /* colorspace of input image */
    /* Now use the library's routine to set default compression parameters.
     * (You must set at least cinfo.in_color_space before calling this,
     * since the defaults depend on the source color space.)
     */
    jpeg_set_defaults(&cinfo);
    /* Now you can set any non-default parameters you wish to.
     * Here we just illustrate the use of quality (quantization table) scaling:
     */
    jpeg_set_quality(&cinfo, quality, TRUE /* limit to baseline-JPEG values */);
    
    /* Step 4: Start compressor */
    
    /* TRUE ensures that we will write a complete interchange-JPEG file.
     * Pass TRUE unless you are very sure of what you're doing.
     */
    jpeg_start_compress(&cinfo, TRUE);
    
    return ret;
}
#endif
bool appendImageStrideToJPEG(const JPEGCompressOutput* output, unsigned char* imageData, int lines, bool reverseOrder) {
    ALOGE("renderJPEGToJPEG# appendImageStrideToJPEG#Enter");
    if (!output) return false;
    /* Step 5: while (scan lines remain to be written) */
    /*           jpeg_write_scanlines(...); */

    /* Here we use the library's state variable cinfo.next_scanline as the
     * loop counter, so that we don't have to keep track ourselves.
     * To keep things simple, we pass one scanline per call; you can pass
     * more if you wish, though.
     */
    JSAMPROW row_pointer[1];      /* pointer to JSAMPLE row[s] */
    int row_stride;               /* physical row width in image buffer */
    struct jpeg_compress_struct& cinfo = (struct jpeg_compress_struct&) output->cinfo;
    row_stride = cinfo.image_width * cinfo.input_components; /* JSAMPLEs per row in image_buffer */
    ALOGE("renderJPEGToJPEG# appendImageStrideToJPEG#0");
    if (reverseOrder)
    {
        for (int iLine = lines-1; iLine >= 0 && cinfo.next_scanline < cinfo.image_height; --iLine)
        {
            /* jpeg_write_scanlines expects an array of pointers to scanlines.
             * Here the array is only one element long, but you could pass
             * more than one scanline at a time if that's more convenient.
             */
            row_pointer[0] = & imageData[iLine * row_stride];
            jpeg_write_scanlines(&cinfo, row_pointer, 1);
            //        ALOGE("renderJPEGToJPEG# appendImageStrideToJPEG#1 lines=%d, iLine=%d, cinfo.next_scanline=%d, cinfo.image_height=%d", lines, iLine, cinfo.next_scanline, cinfo.image_height);
        }
    }
    else
    {
        for (int iLine=0; iLine < lines && cinfo.next_scanline < cinfo.image_height; ++iLine)
        {
            /* jpeg_write_scanlines expects an array of pointers to scanlines.
             * Here the array is only one element long, but you could pass
             * more than one scanline at a time if that's more convenient.
             */
            row_pointer[0] = & imageData[iLine * row_stride];
            jpeg_write_scanlines(&cinfo, row_pointer, 1);
            //        ALOGE("renderJPEGToJPEG# appendImageStrideToJPEG#1 lines=%d, iLine=%d, cinfo.next_scanline=%d, cinfo.image_height=%d", lines, iLine, cinfo.next_scanline, cinfo.image_height);
        }
    }

    if (cinfo.next_scanline < cinfo.image_height)
    {
        ALOGE("renderJPEGToJPEG# appendImageStrideToJPEG#2A");
        return true;
    }
    else
    {
        /* Step 6: Finish compression */
        ALOGE("renderJPEGToJPEG# appendImageStrideToJPEG#2B");
        jpeg_finish_compress(&cinfo);
        /* After finish_compress, we can close the output file. */
        if (output->destFile)
        {
            fclose(output->destFile);
        }

        /* Step 7: release JPEG compression object */

        /* This is an important step since it will release a good deal of memory. */
        jpeg_destroy_compress(&cinfo);

        delete output;
        /* And we're done! */
        return false;
    }
}
#ifdef USE_MEM_IO
void writeImageToJPEGData(unsigned char** dstBuffer, unsigned long* dstBufferSize,
                      GLenum colorspace, GLenum bitformat, int quality,
                      unsigned char* imageData, int imageWidth, int imageHeight)
{
    if (NULL == *dstBuffer || 0 == *dstBufferSize)
    {
        *dstBufferSize = jtColorComponentsOfPixelType(colorspace, bitformat) * imageWidth * imageHeight;
        *dstBuffer = (unsigned char*) malloc(*dstBufferSize);
    }
    
    struct jpeg_compress_struct cinfo;
    struct jpeg_error_mgr jerr;
    JSAMPROW row_pointer[1];      /* pointer to JSAMPLE row[s] */
    int row_stride;               /* physical row width in image buffer */
    
    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_compress(&cinfo);
    
    jpeg_mem_dest(&cinfo, dstBuffer, dstBufferSize);
    
    cinfo.image_width = imageWidth;      /* image width and height, in pixels */
    cinfo.image_height = imageHeight;
    cinfo.input_components = jtColorComponentsOfPixelType(colorspace, bitformat);           /* # of color components per pixel */
    cinfo.in_color_space = jtColorSpaceOfPixelType(colorspace);       /* colorspace of input image */
    
    jpeg_set_defaults(&cinfo);
    jpeg_set_quality(&cinfo, quality, TRUE /* limit to baseline-JPEG values */);
    
    jpeg_start_compress(&cinfo, TRUE);
    
    row_stride = imageWidth * cinfo.input_components; /* JSAMPLEs per row in image_buffer */
    while (cinfo.next_scanline < cinfo.image_height) {
        row_pointer[0] = & imageData[cinfo.next_scanline * row_stride];
        jpeg_write_scanlines(&cinfo, row_pointer, 1);
    }
    
    jpeg_finish_compress(&cinfo);
    jpeg_destroy_compress(&cinfo);
}
#endif
/*
 * Here's the routine that will replace the standard error_exit method:
 */

METHODDEF(void)
my_error_exit(j_common_ptr cinfo)
{
    /* cinfo->err really points to a my_error_mgr struct, so coerce pointer */
    jpeg_error_info_ptr myerr = (jpeg_error_info_ptr) cinfo->err;
    
    /* Always display the message. */
    /* We could postpone this until after returning, if we chose. */
    (*cinfo->err->output_message) (cinfo);
    
    /* Return control to the setjmp point */
    longjmp(myerr->setjmp_buffer, 1);
}

jpeg_decompress_struct readImageFromJPEG(unsigned char* outPixelData,
                                        GLenum colorspace, GLenum bitformat,
                                        const char* filename)
{
    /* This struct contains the JPEG decompression parameters and pointers to
     * working space (which is allocated as needed by the JPEG library).
     */
    struct jpeg_decompress_struct cinfo;
	memset(&cinfo, 0, sizeof(struct jpeg_decompress_struct));
    /* We use our private extension JPEG error handler.
     * Note that this struct must live as long as the main JPEG parameter
     * struct, to avoid dangling-pointer problems.
     */
    jpeg_error_info jerr;
    /* More stuff */
    FILE * infile;                /* source file */
    JSAMPARRAY buffer;            /* Output row buffer */
    int row_stride;               /* physical row width in output buffer */
    
    /* In this example we want to open the input file before doing anything else,
     * so that the setjmp() error recovery below can assume the file is open.
     * VERY IMPORTANT: use "b" option to fopen() if you are on a machine that
     * requires it in order to read binary files.
     */
    
    if ((infile = fopen(filename, "rb+")) == NULL) {
        fprintf(stderr, "can't open %s\n", filename);
        return cinfo;
    }
    
    /* Step 1: allocate and initialize JPEG decompression object */
    
    /* We set up the normal JPEG error routines, then override error_exit. */
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;
    /* Establish the setjmp return context for my_error_exit to use. */
    if (setjmp(jerr.setjmp_buffer)) {
        /* If we get here, the JPEG code has signaled an error.
         * We need to clean up the JPEG object, close the input file, and return.
         */
        jpeg_destroy_decompress(&cinfo);
        fclose(infile);
        return cinfo;
    }
    /* Now we can initialize the JPEG decompression object. */
    jpeg_create_decompress(&cinfo);
    
    /* Step 2: specify data source (eg, a file) */
    
    jpeg_stdio_src(&cinfo, infile);
    
    /* Step 3: read file parameters with jpeg_read_header() */
    
    (void) jpeg_read_header(&cinfo, TRUE);
    /* We can ignore the return value from jpeg_read_header since
     *   (a) suspension is not possible with the stdio data source, and
     *   (b) we passed TRUE to reject a tables-only JPEG file as an error.
     * See libjpeg.txt for more info.
     */
    
    /* Step 4: set parameters for decompression */
    
    /* In this example, we don't need to change any of the defaults set by
     * jpeg_read_header(), so we do nothing here.
     */
    cinfo.out_color_components = jtColorComponentsOfPixelType(colorspace, bitformat);           /* # of color components per pixel */
    cinfo.out_color_space = jtColorSpaceOfPixelType(colorspace);       /* colorspace of input image */
    //    cinfo.out_color_components = 3;
    //    cinfo.out_color_space = JCS_RGB;
    
    /* Step 5: Start decompressor */
    
    (void) jpeg_start_decompress(&cinfo);
    /* We can ignore the return value since suspension is not possible
     * with the stdio data source.
     */
    
    /* We may need to do some setup of our own at this point before reading
     * the data.  After jpeg_start_decompress() we have the correct scaled
     * output image dimensions available, as well as the output colormap
     * if we asked for color quantization.
     * In this example, we need to make an output work buffer of the right size.
     */
    /* JSAMPLEs per row in output buffer */
    row_stride = cinfo.output_width * cinfo.output_components;
    /* Make a one-row-high sample array that will go away when done with image */
    buffer = (*cinfo.mem->alloc_sarray)
    ((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, 1);
    
    /* Step 6: while (scan lines remain to be read) */
    /*           jpeg_read_scanlines(...); */
    
    /* Here we use the library's state variable cinfo.output_scanline as the
     * loop counter, so that we don't have to keep track ourselves.
     */
    while (cinfo.output_scanline < cinfo.output_height) {
        /* jpeg_read_scanlines expects an array of pointers to scanlines.
         * Here the array is only one element long, but you could ask for
         * more than one scanline at a time if that's more convenient.
         */
        (void) jpeg_read_scanlines(&cinfo, buffer, 1);
        /* Assume put_scanline_someplace wants a pointer and sample count. */
        ///!!!    put_scanline_someplace(buffer[0], row_stride);
        memcpy(outPixelData + (cinfo.output_scanline - 1) * sizeof(JSAMPLE) * row_stride, buffer[0], sizeof(JSAMPLE) * row_stride);
    }
    
    /* Step 7: Finish decompression */
    
    (void) jpeg_finish_decompress(&cinfo);
    /* We can ignore the return value since suspension is not possible
     * with the stdio data source.
     */
    
    /* Step 8: Release JPEG decompression object */
    
    /* This is an important step since it will release a good deal of memory. */
    jpeg_destroy_decompress(&cinfo);
    
    /* After finish_decompress, we can close the input file.
     * Here we postpone it until after no more JPEG errors are possible,
     * so as to simplify the setjmp error logic above.  (Actually, I don't
     * think that jpeg_destroy can do an error exit, but why assume anything...)
     */
    fclose(infile);
    
    /* At this point you may want to check to see whether any corrupt-data
     * warnings occurred (test whether jerr.pub.num_warnings is nonzero).
     */
    
    /* And we're done! */
    return cinfo;
}

jpeg_decompress_struct readImageInfoFromJPEG(const char* filename)
{
    /* This struct contains the JPEG decompression parameters and pointers to
     * working space (which is allocated as needed by the JPEG library).
     */
    struct jpeg_decompress_struct cinfo;
	memset(&cinfo, 0, sizeof(struct jpeg_decompress_struct));
    /* We use our private extension JPEG error handler.
     * Note that this struct must live as long as the main JPEG parameter
     * struct, to avoid dangling-pointer problems.
     */
    jpeg_error_info jerr;
    /* More stuff */
    FILE * infile;                /* source file */
    JSAMPARRAY buffer;            /* Output row buffer */
    int row_stride;               /* physical row width in output buffer */
    
    /* In this example we want to open the input file before doing anything else,
     * so that the setjmp() error recovery below can assume the file is open.
     * VERY IMPORTANT: use "b" option to fopen() if you are on a machine that
     * requires it in order to read binary files.
     */
    
    if ((infile = fopen(filename, "rb+")) == NULL) {
		ALOGE("JPEGUtils::readImageInfoFromJPEG : File open failed with error %s,  in %s", strerror(errno), filename);
        fprintf(stderr, "can't open %s\n", filename);
        return cinfo;
    }
    
    /* Step 1: allocate and initialize JPEG decompression object */
    
    /* We set up the normal JPEG error routines, then override error_exit. */
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;
    /* Establish the setjmp return context for my_error_exit to use. */
    if (setjmp(jerr.setjmp_buffer)) {
        /* If we get here, the JPEG code has signaled an error.
         * We need to clean up the JPEG object, close the input file, and return.
         */
        jpeg_destroy_decompress(&cinfo);
        fclose(infile);
        return cinfo;
    }
    /* Now we can initialize the JPEG decompression object. */
    jpeg_create_decompress(&cinfo);
    
    /* Step 2: specify data source (eg, a file) */
    
    jpeg_stdio_src(&cinfo, infile);
    
    /* Step 3: read file parameters with jpeg_read_header() */
    
    (void) jpeg_read_header(&cinfo, TRUE);
    /* We can ignore the return value from jpeg_read_header since
     *   (a) suspension is not possible with the stdio data source, and
     *   (b) we passed TRUE to reject a tables-only JPEG file as an error.
     * See libjpeg.txt for more info.
     */
    
//    /* Step 4: set parameters for decompression */
//    
//    /* In this example, we don't need to change any of the defaults set by
//     * jpeg_read_header(), so we do nothing here.
//     */
//    cinfo.out_color_components = jtColorComponentsOfPixelType(colorspace, bitformat);           /* # of color components per pixel */
//    cinfo.out_color_space = jtColorSpaceOfPixelType(colorspace);       /* colorspace of input image */
//    //    cinfo.out_color_components = 3;
//    //    cinfo.out_color_space = JCS_RGB;
//    
//    /* Step 5: Start decompressor */
//    
//    (void) jpeg_start_decompress(&cinfo);
//    /* We can ignore the return value since suspension is not possible
//     * with the stdio data source.
//     */
//    
//    /* We may need to do some setup of our own at this point before reading
//     * the data.  After jpeg_start_decompress() we have the correct scaled
//     * output image dimensions available, as well as the output colormap
//     * if we asked for color quantization.
//     * In this example, we need to make an output work buffer of the right size.
//     */
//    /* JSAMPLEs per row in output buffer */
//    row_stride = cinfo.output_width * cinfo.output_components;
//    /* Make a one-row-high sample array that will go away when done with image */
//    buffer = (*cinfo.mem->alloc_sarray)
//    ((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, 1);
//    
//    /* Step 6: while (scan lines remain to be read) */
//    /*           jpeg_read_scanlines(...); */
//    
//    /* Here we use the library's state variable cinfo.output_scanline as the
//     * loop counter, so that we don't have to keep track ourselves.
//     */
//    while (cinfo.output_scanline < cinfo.output_height) {
//        /* jpeg_read_scanlines expects an array of pointers to scanlines.
//         * Here the array is only one element long, but you could ask for
//         * more than one scanline at a time if that's more convenient.
//         */
//        (void) jpeg_read_scanlines(&cinfo, buffer, 1);
//        /* Assume put_scanline_someplace wants a pointer and sample count. */
//        ///!!!    put_scanline_someplace(buffer[0], row_stride);
//        memcpy(outPixelData + (cinfo.output_scanline - 1) * sizeof(JSAMPLE) * row_stride, buffer[0], sizeof(JSAMPLE) * row_stride);
//    }
//    
//    /* Step 7: Finish decompression */
//    
//    (void) jpeg_finish_decompress(&cinfo);
//    /* We can ignore the return value since suspension is not possible
//     * with the stdio data source.
//     */
//    
//    /* Step 8: Release JPEG decompression object */
//    
//    /* This is an important step since it will release a good deal of memory. */
//    jpeg_destroy_decompress(&cinfo);
    
    /* After finish_decompress, we can close the input file.
     * Here we postpone it until after no more JPEG errors are possible,
     * so as to simplify the setjmp error logic above.  (Actually, I don't
     * think that jpeg_destroy can do an error exit, but why assume anything...)
     */
    fclose(infile);
    
    /* At this point you may want to check to see whether any corrupt-data
     * warnings occurred (test whether jerr.pub.num_warnings is nonzero).
     */
    
    /* And we're done! */
    return cinfo;
}

jpeg_decompress_struct readImageFromJPEGWithCallback(JPEGDecodeLineCallback callback, void* userParams, GLenum colorspace, GLenum bitformat, int scaleNum, int scaleDenom, const char* filename)
{
    /* This struct contains the JPEG decompression parameters and pointers to
     * working space (which is allocated as needed by the JPEG library).
     */
    struct jpeg_decompress_struct cinfo;
    /* We use our private extension JPEG error handler.
     * Note that this struct must live as long as the main JPEG parameter
     * struct, to avoid dangling-pointer problems.
     */
    jpeg_error_info jerr;
    /* More stuff */
    FILE * infile;                /* source file */
    JSAMPARRAY buffer;            /* Output row buffer */
    int row_stride;               /* physical row width in output buffer */

    /* In this example we want to open the input file before doing anything else,
     * so that the setjmp() error recovery below can assume the file is open.
     * VERY IMPORTANT: use "b" option to fopen() if you are on a machine that
     * requires it in order to read binary files.
     */

    if ((infile = fopen(filename, "rb+")) == NULL) {
        fprintf(stderr, "can't open %s\n", filename);
//        ALOGE("createTextureWithJPEG : Can't open file '%s'", filename);
        if (NULL != callback)
        {
            callback(&cinfo, NULL, -1, userParams, true);
        }
        return cinfo;
    }

    /* Step 1: allocate and initialize JPEG decompression object */

    /* We set up the normal JPEG error routines, then override error_exit. */
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;
    /* Establish the setjmp return context for my_error_exit to use. */
    if (setjmp(jerr.setjmp_buffer)) {
        /* If we get here, the JPEG code has signaled an error.
         * We need to clean up the JPEG object, close the input file, and return.
         */
        jpeg_destroy_decompress(&cinfo);
        fclose(infile);
//        ALOGE("createTextureWithJPEG : Error #1 in file '%s'", filename);
        remove(filename);
        if (NULL != callback)
        {
            callback(&cinfo, NULL, -1, userParams, true);
        }
        return cinfo;
    }
    /* Now we can initialize the JPEG decompression object. */
    jpeg_create_decompress(&cinfo);

    /* Step 2: specify data source (eg, a file) */

    jpeg_stdio_src(&cinfo, infile);

    /* Step 3: read file parameters with jpeg_read_header() */

    jpeg_read_header(&cinfo, TRUE);
    /* We can ignore the return value from jpeg_read_header since
     *   (a) suspension is not possible with the stdio data source, and
     *   (b) we passed TRUE to reject a tables-only JPEG file as an error.
     * See libjpeg.txt for more info.
     */

    /* Step 4: set parameters for decompression */

    /* In this example, we don't need to change any of the defaults set by
     * jpeg_read_header(), so we do nothing here.
     */
    cinfo.out_color_components = jtColorComponentsOfPixelType(colorspace, bitformat);           /* # of color components per pixel */
    cinfo.out_color_space = jtColorSpaceOfPixelType(colorspace);       /* colorspace of input image */
//    cinfo.out_color_components = 3;
//    cinfo.out_color_space = JCS_RGB;
    if (scaleNum > 0 && scaleDenom > 0)
    {
        cinfo.scale_num = scaleNum;
        cinfo.scale_denom = scaleDenom;
    }
    
    /* Step 5: Start decompressor */

    jpeg_start_decompress(&cinfo);
    /* We can ignore the return value since suspension is not possible
     * with the stdio data source.
     */

    /* We may need to do some setup of our own at this point before reading
     * the data.  After jpeg_start_decompress() we have the correct scaled
     * output image dimensions available, as well as the output colormap
     * if we asked for color quantization.
     * In this example, we need to make an output work buffer of the right size.
     */
    /* JSAMPLEs per row in output buffer */
    row_stride = cinfo.output_width * cinfo.output_components;
    /* Make a one-row-high sample array that will go away when done with image */
    buffer = (*cinfo.mem->alloc_sarray)
            ((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, 1);

    /* Step 6: while (scan lines remain to be read) */
    /*           jpeg_read_scanlines(...); */

    /* Here we use the library's state variable cinfo.output_scanline as the
     * loop counter, so that we don't have to keep track ourselves.
     */
//    ALOGE("createTextureWithJPEG : Begin decoding '%s'", filename);
    while (cinfo.output_scanline < cinfo.output_height) {
        /* jpeg_read_scanlines expects an array of pointers to scanlines.
         * Here the array is only one element long, but you could ask for
         * more than one scanline at a time if that's more convenient.
         */
        jpeg_read_scanlines(&cinfo, buffer, 1);
        /* Assume put_scanline_someplace wants a pointer and sample count. */
        ///!!!    put_scanline_someplace(buffer[0], row_stride);
//        memcpy(outPixelData + (cinfo.output_scanline - 1) * sizeof(JSAMPLE) * row_stride, buffer[0], sizeof(JSAMPLE) * row_stride);
        if (NULL != callback)
        {
            callback(&cinfo, buffer[0], (cinfo.output_scanline - 1), userParams, false);
        }
    }
    if (NULL != callback)
    {
        callback(&cinfo, NULL, cinfo.output_scanline, userParams, true);
    }

    /* Step 7: Finish decompression */

    jpeg_finish_decompress(&cinfo);
    /* We can ignore the return value since suspension is not possible
     * with the stdio data source.
     */

    /* Step 8: Release JPEG decompression object */

    /* This is an important step since it will release a good deal of memory. */
    jpeg_destroy_decompress(&cinfo);

    /* After finish_decompress, we can close the input file.
     * Here we postpone it until after no more JPEG errors are possible,
     * so as to simplify the setjmp error logic above.  (Actually, I don't
     * think that jpeg_destroy can do an error exit, but why assume anything...)
     */
    fclose(infile);

    /* At this point you may want to check to see whether any corrupt-data
     * warnings occurred (test whether jerr.pub.num_warnings is nonzero).
     */

    /* And we're done! */
    return cinfo;
}

jpeg_decompress_struct allocateReadImageFromJPEG(unsigned char** outPixelDataPtr, int* outBytesPtr,
                                         GLenum colorspace, GLenum bitformat,
                                         const char* filename)
{
    /* This struct contains the JPEG decompression parameters and pointers to
     * working space (which is allocated as needed by the JPEG library).
     */
    struct jpeg_decompress_struct cinfo;
	memset(&cinfo, 0, sizeof(struct jpeg_decompress_struct));
    /* We use our private extension JPEG error handler.
     * Note that this struct must live as long as the main JPEG parameter
     * struct, to avoid dangling-pointer problems.
     */
    jpeg_error_info jerr;
	memset(&jerr, 0, sizeof(jpeg_error_info));
    /* More stuff */
    FILE * infile;                /* source file */
    JSAMPARRAY buffer;            /* Output row buffer */
    int row_stride;               /* physical row width in output buffer */
    
    /* In this example we want to open the input file before doing anything else,
     * so that the setjmp() error recovery below can assume the file is open.
     * VERY IMPORTANT: use "b" option to fopen() if you are on a machine that
     * requires it in order to read binary files.
     */
    
    if ((infile = fopen(filename, "rb+")) == NULL) {
        fprintf(stderr, "can't open %s\n", filename);
        return cinfo;
    }
    
    /* Step 1: allocate and initialize JPEG decompression object */
    
    /* We set up the normal JPEG error routines, then override error_exit. */
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;
    /* Establish the setjmp return context for my_error_exit to use. */
    if (setjmp(jerr.setjmp_buffer)) {
        /* If we get here, the JPEG code has signaled an error.
         * We need to clean up the JPEG object, close the input file, and return.
         */
        jpeg_destroy_decompress(&cinfo);
        fclose(infile);
        return cinfo;
    }
	
	/* Now we can initialize the JPEG decompression object. */
    jpeg_create_decompress(&cinfo);
    
	/* Step 2: specify data source (eg, a file) */
	jpeg_stdio_src(&cinfo, infile);

	/* Step 3: read file parameters with jpeg_read_header() */
    
    (void) jpeg_read_header(&cinfo, TRUE);
    /* We can ignore the return value from jpeg_read_header since
     *   (a) suspension is not possible with the stdio data source, and
     *   (b) we passed TRUE to reject a tables-only JPEG file as an error.
     * See libjpeg.txt for more info.
     */
    
	/* Step 4: set parameters for decompression */

	/* In this example, we don't need to change any of the defaults set by
	* jpeg_read_header(), so we do nothing here.
	*/
	cinfo.out_color_components = jtColorComponentsOfPixelType(colorspace, bitformat);           /* # of color components per pixel */
	cinfo.out_color_space = jtColorSpaceOfPixelType(colorspace);       /* colorspace of input image */
	//    cinfo.out_color_components = 3;
	//    cinfo.out_color_space = JCS_RGB;

	/* Step 5: Start decompressor */
    
    (void) jpeg_start_decompress(&cinfo);
    /* We can ignore the return value since suspension is not possible
     * with the stdio data source.
     */
    
    /* We may need to do some setup of our own at this point before reading
     * the data.  After jpeg_start_decompress() we have the correct scaled
     * output image dimensions available, as well as the output colormap
     * if we asked for color quantization.
     * In this example, we need to make an output work buffer of the right size.
     */
    /* JSAMPLEs per row in output buffer */
    row_stride = cinfo.output_width * cinfo.output_components;
    /* Make a one-row-high sample array that will go away when done with image */
    buffer = (*cinfo.mem->alloc_sarray)
    ((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, 1);
    
    /* Step 6: while (scan lines remain to be read) */
    /*           jpeg_read_scanlines(...); */
    
    /* Here we use the library's state variable cinfo.output_scanline as the
     * loop counter, so that we don't have to keep track ourselves.
     */
    if (NULL == *outPixelDataPtr || cinfo.output_height * sizeof(JSAMPLE) * row_stride > *outBytesPtr)
    {
        *outBytesPtr = cinfo.output_height * sizeof(JSAMPLE) * row_stride;
        *outPixelDataPtr = (unsigned char*) malloc(*outBytesPtr);
    }
    while (cinfo.output_scanline < cinfo.output_height) {
        /* jpeg_read_scanlines expects an array of pointers to scanlines.
         * Here the array is only one element long, but you could ask for
         * more than one scanline at a time if that's more convenient.
         */
        (void) jpeg_read_scanlines(&cinfo, buffer, 1);
        /* Assume put_scanline_someplace wants a pointer and sample count. */
        ///!!!    put_scanline_someplace(buffer[0], row_stride);
        memcpy(*outPixelDataPtr + (cinfo.output_scanline - 1) * sizeof(JSAMPLE) * row_stride, buffer[0], sizeof(JSAMPLE) * row_stride);
    }
    
    /* Step 7: Finish decompression */
    
    (void) jpeg_finish_decompress(&cinfo);
    /* We can ignore the return value since suspension is not possible
     * with the stdio data source.
     */
    
    /* Step 8: Release JPEG decompression object */
    
    /* This is an important step since it will release a good deal of memory. */
    jpeg_destroy_decompress(&cinfo);
    
    /* After finish_decompress, we can close the input file.
     * Here we postpone it until after no more JPEG errors are possible,
     * so as to simplify the setjmp error logic above.  (Actually, I don't
     * think that jpeg_destroy can do an error exit, but why assume anything...)
     */
    fclose(infile);
    
    /* At this point you may want to check to see whether any corrupt-data
     * warnings occurred (test whether jerr.pub.num_warnings is nonzero).
     */
    
    /* And we're done! */
    return cinfo;
}
#ifdef USE_MEM_IO
jpeg_decompress_struct readImageFromJPEGData(unsigned char* outPixelData,
                                       GLenum colorspace, GLenum bitformat,
                                       unsigned char* srcBuffer, unsigned long srcBufferSize)
{
    struct jpeg_decompress_struct cinfo;
    jpeg_error_info jerr;
    JSAMPARRAY buffer;            /* Output row buffer */
    int row_stride;               /* physical row width in output buffer */
    
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;
    if (setjmp(jerr.setjmp_buffer)) {
        jpeg_destroy_decompress(&cinfo);
        return cinfo;
    }
    jpeg_create_decompress(&cinfo);
    
    jpeg_mem_src(&cinfo, srcBuffer, srcBufferSize);
    
    (void) jpeg_read_header(&cinfo, TRUE);
    
    cinfo.out_color_components = jtColorComponentsOfPixelType(colorspace, bitformat);           /* # of color components per pixel */
    cinfo.out_color_space = jtColorSpaceOfPixelType(colorspace);       /* colorspace of input image */
    //    cinfo.out_color_components = 3;
    //    cinfo.out_color_space = JCS_RGB;
    
    (void) jpeg_start_decompress(&cinfo);
    row_stride = cinfo.output_width * cinfo.output_components;
    buffer = (*cinfo.mem->alloc_sarray) ((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, 1);
    
    while (cinfo.output_scanline < cinfo.output_height) {
        (void) jpeg_read_scanlines(&cinfo, buffer, 1);
        /* Assume put_scanline_someplace wants a pointer and sample count. */
        ///!!!    put_scanline_someplace(buffer[0], row_stride);
        memcpy(outPixelData + (cinfo.output_scanline - 1) * sizeof(JSAMPLE) * row_stride, buffer[0], sizeof(JSAMPLE) * row_stride);
    }
    
    (void) jpeg_finish_decompress(&cinfo);
    /* We can ignore the return value since suspension is not possible
     * with the stdio data source.
     */
    
    jpeg_destroy_decompress(&cinfo);
    
    return cinfo;
}

jpeg_decompress_struct allocateReadImageFromJPEGData(unsigned char** outPixelDataPtr, int* outBytesPtr,
                                             GLenum colorspace, GLenum bitformat,
                                             unsigned char* srcBuffer, unsigned long srcBufferSize)
{
    struct jpeg_decompress_struct cinfo;
    jpeg_error_info jerr;
    JSAMPARRAY buffer;            /* Output row buffer */
    int row_stride;               /* physical row width in output buffer */
    
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;
    if (setjmp(jerr.setjmp_buffer)) {
        jpeg_destroy_decompress(&cinfo);
        return cinfo;
    }
    jpeg_create_decompress(&cinfo);
    
    jpeg_mem_src(&cinfo, srcBuffer, srcBufferSize);
    
    (void) jpeg_read_header(&cinfo, TRUE);
    
    cinfo.out_color_components = jtColorComponentsOfPixelType(colorspace, bitformat);           /* # of color components per pixel */
    cinfo.out_color_space = jtColorSpaceOfPixelType(colorspace);       /* colorspace of input image */
    //    cinfo.out_color_components = 3;
    //    cinfo.out_color_space = JCS_RGB;
    
    (void) jpeg_start_decompress(&cinfo);
    row_stride = cinfo.output_width * cinfo.output_components;
    buffer = (*cinfo.mem->alloc_sarray) ((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, 1);
    
    if (NULL == *outPixelDataPtr || cinfo.output_height * sizeof(JSAMPLE) * row_stride > *outBytesPtr)
    {
        *outBytesPtr = cinfo.output_height * sizeof(JSAMPLE) * row_stride;
        *outPixelDataPtr = (unsigned char*) malloc(*outBytesPtr);
    }
    while (cinfo.output_scanline < cinfo.output_height) {
        (void) jpeg_read_scanlines(&cinfo, buffer, 1);
        /* Assume put_scanline_someplace wants a pointer and sample count. */
        ///!!!    put_scanline_someplace(buffer[0], row_stride);
        memcpy(*outPixelDataPtr + (cinfo.output_scanline - 1) * sizeof(JSAMPLE) * row_stride, buffer[0], sizeof(JSAMPLE) * row_stride);
    }
    
    (void) jpeg_finish_decompress(&cinfo);
    /* We can ignore the return value since suspension is not possible
     * with the stdio data source.
     */
    
    jpeg_destroy_decompress(&cinfo);
    
    return cinfo;
}
#endif
typedef struct {
	JSAMPLE* quaterData;
	int filledQuaterDataLine;
	GLuint texture;

	int rowStride;
	int width;
	int height;
	int quaterHeight;
} DecodeOneJPEGLineVariables;

void InitDecodeOneJPEGLineVariables(DecodeOneJPEGLineVariables* ptr) {
	if (NULL == ptr) return;
	ptr->quaterData = NULL;
	ptr->filledQuaterDataLine = 0;
	ptr->texture = 0;
	ptr->rowStride = 0;
	ptr->width = 0;
	ptr->height = 0;
	ptr->quaterHeight = 0;
}

void onDecodeOneJPEGLineByCreateTextureWithJPEG(struct jpeg_decompress_struct* cinfo, JSAMPROW sampleRow, int lineNumber, void* userParams, bool finished) {
//    ALOGE("createTextureWithJPEG$onDecodeOneJPEGLineByCreateTextureWithJPEG : lineNumber=%d, finished=%d", lineNumber, finished);
    DecodeOneJPEGLineVariables* pVars = (DecodeOneJPEGLineVariables*) userParams;
    if (NULL == pVars)
    {
        ALOGE("createTextureWithJPEG returned#1");
        return;
    }

    if (finished)
    {
        if (pVars->texture > 0 && pVars->filledQuaterDataLine > 0)
        {
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, cinfo->output_scanline - pVars->filledQuaterDataLine, pVars->width, pVars->filledQuaterDataLine, GL_RGBA, GL_UNSIGNED_BYTE, pVars->quaterData);
            pVars->filledQuaterDataLine = 0;
        }
        return;
    }

    if (lineNumber >= 0)
    {
        if (0 == pVars->rowStride)
        {
            pVars->rowStride = cinfo->output_width * cinfo->output_components;
            pVars->width = cinfo->output_width;
            pVars->height = cinfo->output_height;
            pVars->quaterHeight = pVars->height / 4;
//            ALOGE("createTextureWithJPEG : width=%d, height=%d, rowStride=%d, quaterHeight=%d", pVars->width, pVars->height, pVars->rowStride, pVars->quaterHeight);
        }

        if (0 == pVars->texture)
        {
            glGenTextures(1, &pVars->texture);
            glBindTexture(GL_TEXTURE_2D, pVars->texture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST//GL_LINEAR_MIPMAP_LINEAR
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
            glPixelStorei(GL_PACK_ALIGNMENT, 1);
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

            CHECK_GL_ERROR();
//            glTexStorage2DEXT(GL_TEXTURE_2D, 2, GL_RGBA, cinfo->output_width, cinfo->output_height);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, cinfo->output_width, cinfo->output_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
            CHECK_GL_ERROR();
        }
        if (NULL == pVars->quaterData)
        {
            pVars->quaterData = (JSAMPLE*) malloc(sizeof(JSAMPLE) * pVars->rowStride * pVars->quaterHeight);
        }

        memcpy(pVars->quaterData + pVars->rowStride * pVars->filledQuaterDataLine, sampleRow, pVars->rowStride * sizeof(JSAMPLE));
//        memset(pVars->quaterData + pVars->rowStride * pVars->filledQuaterDataLine, 0xffffffff, pVars->rowStride * sizeof(JSAMPLE));///!!!For Debug

        if (pVars->quaterHeight == ++(pVars->filledQuaterDataLine))
        {
//            ALOGE("createTextureWithJPEG : Flush one quater : cinfo->output_scanline = %d, pVars->filledQuaterDataLine = %d", cinfo->output_scanline, pVars->filledQuaterDataLine);
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, cinfo->output_scanline - pVars->filledQuaterDataLine, pVars->width, pVars->filledQuaterDataLine, GL_RGBA, GL_UNSIGNED_BYTE, pVars->quaterData);
            pVars->filledQuaterDataLine = 0;
        }
    }
}

template <typename T>
bool checkPointerOffset(T* ptr1, T* ptr0, int min, int max) {
    int offset = (int)(ptr1 - ptr0);
    if (offset < min || offset > max)
    {
        throw "chekPointerOffset: Offset invalid!";
        return false;
    }
    return true;
}

class ConvolutionIterator {
public:
    
    static const int DstRGBComponents = 3;
    
    virtual ~ConvolutionIterator();
    
    ConvolutionIterator(int rowStep, int columnStep, int rowWidth, int columnHeight);
    
    void beginIteration(int startRow, int endRow, int startColumn, int endColumn,
                        int convolutionMatrixWidth, int convolutionMatrixHeight, int convolutionMatrixOffsetRow, int convolutionMatrixOffsetColumn,
                        const int* coefficientMatrixR, const int* coefficientMatrixG, const int* coefficientMatrixB, GLfloat coefficientMatrixScale,
                        GLubyte* dstRGBDataOrigin, const GLushort* srcRawDataOrigin);
    
    bool next();
    
    inline int getCurrentRow() {return _iRow;}
    inline int getCurrentColumn() {return _iColumn;}
    
	inline GLushort getMaxSrcValue() { return _maxSrcValue; }
	inline GLushort getMinSrcValue() { return _minSrcValue; }

private:
    
    void releaseResources();
    
    // Dimension & Step & Counter of convolution region:
    int _rowWidth;
    int _pixelCount;
    int _rowStep;
    int _columnStep;
    
    int _rowL;
    int _rowH;
    int _columnL;
    int _columnH;
    
    int _iRow;
    int _iColumn;
    
    // Convolution matrix coefficients:
    //int _convolutionMatrixWidth;
    //int _convolutionMatrixHeight;
    int _convolutionMatrixSize;
    
    const int* _coefficientMatrixR;
    const int* _coefficientMatrixG;
    const int* _coefficientMatrixB;
    GLfloat _coefficientMatrixScale;
    
    // Destination GLfloat RGB matrix pointer:
	GLubyte* _pDstR;
	GLubyte* _pDstG;
	GLubyte* _pDstB;
    
    GLubyte* _pDstRowStartR;
	GLubyte* _pDstRowStartG;
	GLubyte* _pDstRowStartB;
    
    int _dstRowStep;
    int _dstColumnStep;
    
    // Source GLushort Raw matrix pointer:
    const GLushort** _pSrcMatrix;
    const GLushort** _pSrcRowStartMatrix;
    
    int _srcRowStep;
    int _srcColumnStep;

	//For Debug:
	GLushort _maxSrcValue;
	GLushort _minSrcValue;
    
    GLubyte* _dstRGBDataOrigin;
    const GLushort* _srcRawDataOrigin;
};

void ConvolutionIterator::releaseResources() {
    if (NULL != _coefficientMatrixR) delete[] _coefficientMatrixR;
    _coefficientMatrixR = NULL;
    
    if (NULL != _coefficientMatrixG) delete[] _coefficientMatrixG;
    _coefficientMatrixG = NULL;
    
    if (NULL != _coefficientMatrixB) delete[] _coefficientMatrixB;
    _coefficientMatrixB = NULL;
    
    if (NULL != _pSrcRowStartMatrix) delete[] _pSrcRowStartMatrix;
    _pSrcRowStartMatrix = NULL;
    
    if (NULL != _pSrcMatrix) delete[] _pSrcMatrix;
    _pSrcMatrix = NULL;
}

ConvolutionIterator::~ConvolutionIterator() {
    releaseResources();
}

ConvolutionIterator::ConvolutionIterator(int rowStep, int columnStep, int rowWidth, int columnHeight)
: _rowWidth(rowWidth)
, _pixelCount(rowWidth * columnHeight)
, _rowStep(rowStep)
, _columnStep(columnStep)
, _coefficientMatrixR(NULL)
, _coefficientMatrixG(NULL)
, _coefficientMatrixB(NULL)
, _pSrcRowStartMatrix(NULL)
, _pSrcMatrix(NULL)
, _maxSrcValue(0)
, _minSrcValue(65535)
{
    
}

void ConvolutionIterator::beginIteration(int startRow, int endRow, int startColumn, int endColumn,
                                         int convolutionMatrixWidth, int convolutionMatrixHeight, int convolutionMatrixOffsetRow, int convolutionMatrixOffsetColumn,
                    const int* coefficientMatrixR, const int* coefficientMatrixG, const int* coefficientMatrixB, GLfloat coefficientMatrixScale,
                    GLubyte* dstRGBDataOrigin, const GLushort* srcRawDataOrigin) {
    releaseResources();
    
    _dstRGBDataOrigin = dstRGBDataOrigin;
    _srcRawDataOrigin = srcRawDataOrigin;
    
    _rowL = startRow;
    _rowH = endRow;
    _columnL = startColumn;
    _columnH = endColumn;
    
    _iRow = startRow;
    _iColumn = startColumn;
    
//    _convolutionMatrixWidth = convolutionMatrixWidth;
//    _convolutionMatrixHeight = convolutionMatrixHeight;
    _coefficientMatrixScale = coefficientMatrixScale;
    _convolutionMatrixSize = convolutionMatrixWidth * convolutionMatrixHeight;
    _coefficientMatrixR = new int[_convolutionMatrixSize];
    _coefficientMatrixG = new int[_convolutionMatrixSize];
    _coefficientMatrixB = new int[_convolutionMatrixSize];
    memcpy((int*)_coefficientMatrixR, coefficientMatrixR, sizeof(int) * _convolutionMatrixSize);
    memcpy((int*)_coefficientMatrixG, coefficientMatrixG, sizeof(int) * _convolutionMatrixSize);
    memcpy((int*)_coefficientMatrixB, coefficientMatrixB, sizeof(int) * _convolutionMatrixSize);
    
    _srcRowStep = _rowStep * _rowWidth;
    _srcColumnStep = _columnStep;
    
    _pSrcRowStartMatrix = new const GLushort*[_convolutionMatrixSize];
    _pSrcMatrix = new const GLushort*[_convolutionMatrixSize];
    int iM = 0;
    for (int iR=0; iR<convolutionMatrixHeight; ++iR)
    {
        for (int iC=0; iC<convolutionMatrixWidth; ++iC)
        {
            _pSrcRowStartMatrix[iM] = srcRawDataOrigin + _rowWidth * (iR + startRow + convolutionMatrixOffsetRow) + (iC + startColumn + convolutionMatrixOffsetColumn);
            _pSrcMatrix[iM] = _pSrcRowStartMatrix[iM];
            iM++;
        }
    }
    
    _dstRowStep = _rowStep * _rowWidth * DstRGBComponents;
    _dstColumnStep = _columnStep * DstRGBComponents;
    GLubyte* dst0 = dstRGBDataOrigin + (startRow * _rowWidth + startColumn) * DstRGBComponents;
    _pDstRowStartR = dst0;
    _pDstRowStartG = dst0 + 1;
    _pDstRowStartB = dst0 + 2;
    _pDstR = _pDstRowStartR;
    _pDstG = _pDstRowStartG;
    _pDstB = _pDstRowStartB;

	_maxSrcValue = 0;
	_minSrcValue = 65535;
}

bool ConvolutionIterator::next() {
    if (_iRow > _rowH)
    {
        releaseResources();
        return false;
    }
    else
    {
        if (_iColumn <= _columnH)
        {
            int R = 0;
            int G = 0;
            int B = 0;
            
            for (int iM = 0; iM < _convolutionMatrixSize; ++iM)
            {
                checkPointerOffset(_pSrcMatrix[iM], _srcRawDataOrigin, 0, _pixelCount);///!!!For Debug
                R += (*(_pSrcMatrix[iM])) * _coefficientMatrixR[iM];
                G += (*(_pSrcMatrix[iM])) * _coefficientMatrixG[iM];
                B += (*(_pSrcMatrix[iM])) * _coefficientMatrixB[iM];
                
				if (*_pSrcMatrix[iM] > _maxSrcValue) _maxSrcValue = *_pSrcMatrix[iM];
				if (*_pSrcMatrix[iM] <_minSrcValue) _minSrcValue = *_pSrcMatrix[iM];

                _pSrcMatrix[iM] += _srcColumnStep;
            }
            checkPointerOffset(_pDstR, _dstRGBDataOrigin, 0, _pixelCount * 3);///!!!For Debug
            checkPointerOffset(_pDstG, _dstRGBDataOrigin, 0, _pixelCount * 3);///!!!For Debug
            checkPointerOffset(_pDstB, _dstRGBDataOrigin, 0, _pixelCount * 3);///!!!For Debug
            
            *_pDstR = (int)roundf(255.f * ((GLfloat)R * _coefficientMatrixScale));
			*_pDstG = (int)roundf(255.f * ((GLfloat)G * _coefficientMatrixScale));
			*_pDstB = (int)roundf(255.f * ((GLfloat)B * _coefficientMatrixScale));
            
            // Next column:
            _pDstR += _dstColumnStep;
            _pDstG += _dstColumnStep;
            _pDstB += _dstColumnStep;
            
            _iColumn += _columnStep;
        }
        else
        {
            // Next row:
            if (_iRow + _rowStep > _rowH)
            {
                releaseResources();
                return false;
            }
            else
            {
                for (int iM = 0; iM < _convolutionMatrixSize; ++iM)
                {
                    _pSrcRowStartMatrix[iM] += _srcRowStep;
                    _pSrcMatrix[iM] = _pSrcRowStartMatrix[iM];
                }
                
                _pDstRowStartR += _dstRowStep;
                _pDstRowStartG += _dstRowStep;
                _pDstRowStartB += _dstRowStep;
                _pDstR = _pDstRowStartR;
                _pDstG = _pDstRowStartG;
                _pDstB = _pDstRowStartB;
                
                _iRow += _rowStep;
                _iColumn = _columnL;
            }
        }
    }
    return true;
}

GLint createTextureWithDNG(FILE* fpStartsFromData, GLuint width, GLuint height, GLint internalFormat, GLenum format, GLenum type, int rawBits) {///!!!For Debug
    GLsizei pixelCount = width * height;
    GLushort* srcData = (GLushort*) malloc(sizeof(GLushort) * pixelCount);
    fread(srcData, sizeof(GLushort) * pixelCount, 1, fpStartsFromData);
	CHECK_GL_ERROR();
    const float MaxValue = (float)(1 << rawBits);
	GLubyte* textureData = (GLubyte*)malloc(sizeof(GLubyte) * pixelCount * 3);
    //*
    ConvolutionIterator convIter(2, 2, width, height);
    // Inner B(s) :
    int coefficientsR_innerB[] = {1, 0, 1, 0, 0, 0, 1, 0, 1};
    int coefficientsG_innerB[] = {0, 1, 0, 1, 0, 1, 0, 1, 0};
    int coefficientsB_innerB[] = {0, 0, 0, 0, 4, 0, 0, 0, 0};
    convIter.beginIteration(1, height-2, 1, width-2, 3,3, -1,-1, coefficientsR_innerB, coefficientsG_innerB, coefficientsB_innerB, 0.25/MaxValue, textureData, srcData);
    while (convIter.next());
	ALOGE("\n(Max, Min) of inner B(s) : (%d, %d)\n", convIter.getMaxSrcValue(), convIter.getMinSrcValue());
    /* Last row B(s) if any:
    int lastRow = convIter.getCurrentRow() + 2;
    if (lastRow < height)
    {
        int coefficientsR_lastRowB[] = {2, 0, 2, 0, 0, 0, 0, 0, 0};
        int coefficientsG_lastRowB[] = {0, 2, 0, 1, 0, 1, 0, 0, 0};
        int coefficientsB_lastRowB[] = {0, 0, 0, 0, 4, 0, 0, 0, 0};
        convIter.beginIteration(lastRow, lastRow, 1, width-2, 3,3, -1,-1, coefficientsR_lastRowB, coefficientsG_lastRowB, coefficientsB_lastRowB, 0.25/MaxValue, textureData, srcData);
        while (convIter.next());
    }
    // Last column B(s) if any:
    if (convIter.getCurrentColumn() < width)
    {
        int coefficientsR_lastColumnB[] = {2,0,0, 0,0,0, 2,0,0};
        int coefficientsG_lastColumnB[] = {0,1,0, 2,0,0, 0,1,0};
        int coefficientsB_lastColumnB[] = {0, 0, 0, 0, 4, 0, 0, 0, 0};
        convIter.beginIteration(1, height-2, convIter.getCurrentColumn(), convIter.getCurrentColumn(), 3,3, -1,-1, coefficientsR_lastColumnB, coefficientsG_lastColumnB, coefficientsB_lastColumnB, 0.25/MaxValue, textureData, srcData);
        while (convIter.next());
    }
    // Right-bottom B at cross of last row and last column if any:
    if (lastRow < height && convIter.getCurrentColumn() < width)
    {
        int coefficientsR_rightBottomB[] = {2,0,0, 0,0,0, 0,0,0};
        int coefficientsG_rightBottomB[] = {0,1,0, 1,0,0, 0,0,0};
        int coefficientsB_rightBottomB[] = {0, 0, 0, 0, 2, 0, 0, 0, 0};
        convIter.beginIteration(1, height-2, lastRow, lastRow, 3,3, -1,-1, coefficientsR_rightBottomB, coefficientsG_rightBottomB, coefficientsB_rightBottomB, 0.5/MaxValue, textureData, srcData);
        while (convIter.next());
    }//*/
    // Inner R(s):
    int coefficientsR_innerR[] = {0,0,0, 0,4,0, 0,0,0};
    int coefficientsG_innerR[] = {0,1,0, 1,0,1, 0,1,0};
    int coefficientsB_innerR[] = {1,0,1, 0,0,0, 1,0,1};
    convIter.beginIteration(2, height-2, 2, width-2, 3,3, -1,-1, coefficientsR_innerR, coefficientsG_innerR, coefficientsB_innerR, 0.25/MaxValue, textureData, srcData);
    while (convIter.next());
	ALOGE("\n(Max, Min) of inner R(s) : (%d, %d)\n", convIter.getMaxSrcValue(), convIter.getMinSrcValue());
	// Last row R(s) if any: TODO
    //int lastRow = convIter.getCurrentRow() + 2;
    // Last column R(s) if any: TODO
    // First column R(s) if any: TODO
    // First row R(s) if any: TODO

    // Inner even-row G(s):
    int coefficientsR_evenRowG[] = {0,0,0, 4,0,4, 0,0,0};
    int coefficientsG_evenRowG[] = {1,0,1, 0,4,0, 1,0,1};
    int coefficientsB_evenRowG[] = {0,4,0, 0,0,0, 0,4,0};
    convIter.beginIteration(2, height-2, 1, width-2, 3,3, -1,-1, coefficientsR_evenRowG, coefficientsG_evenRowG, coefficientsB_evenRowG, 0.125/MaxValue, textureData, srcData);
    while (convIter.next());
	ALOGE("\n(Max, Min) of inner even-row G(s) : (%d, %d)\n", convIter.getMaxSrcValue(), convIter.getMinSrcValue());
	// Inner odd-row G(s):
    int coefficientsR_oddRowG[] = {0,4,0, 0,0,0, 0,4,0};
    int coefficientsG_oddRowG[] = {1,0,1, 0,4,0, 1,0,1};
    int coefficientsB_oddRowG[] = {0,0,0, 4,0,4, 0,0,0};
    convIter.beginIteration(1, height-2, 2, width-2, 3,3, -1,-1, coefficientsR_oddRowG, coefficientsG_oddRowG, coefficientsB_oddRowG, 0.125/MaxValue, textureData, srcData);
    while (convIter.next());
	ALOGE("\n(Max, Min) of inner odd-row G(s) : (%d, %d)\n", convIter.getMaxSrcValue(), convIter.getMinSrcValue());
	free(srcData);
    // (X,Y) = (4851, 378)
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST//GL_LINEAR_MIPMAP_LINEAR
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
    glPixelStorei(GL_PACK_ALIGNMENT, 1);//https://stackoverflow.com/questions/26647672/npot-support-in-opengl-for-r8g8b8-texture
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	CHECK_GL_ERROR();
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, textureData);
	CHECK_GL_ERROR();
	//glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    free(textureData);
    return (GLint)texture;
}

GLint createTextureWithJPEG(const char* filePath, Vec2f* outTextureSize) {
    GLint prevTextureBinding = 0;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &prevTextureBinding);
    DecodeOneJPEGLineVariables variables;
	InitDecodeOneJPEGLineVariables(&variables);
    GLint maxTextureSize = 0;
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
    ALOGE("createTextureWithJPEG: GL_MAX_TEXTURE_SIZE = %d", maxTextureSize);
    jpeg_decompress_struct cinfo = readImageInfoFromJPEG(filePath);
    int scaleNum = 0, scaleDenom = 0;
    if (cinfo.image_width > maxTextureSize || cinfo.image_height > maxTextureSize)
    {
        scaleNum = maxTextureSize;
        scaleDenom = (cinfo.image_width > cinfo.image_height) ? cinfo.image_width : cinfo.image_height;
        scaleDenom = (int) nextPOT(scaleDenom);
    }
    cinfo = readImageFromJPEGWithCallback(onDecodeOneJPEGLineByCreateTextureWithJPEG, &variables, GL_RGBA, GL_UNSIGNED_BYTE, scaleNum,scaleDenom, filePath);
    if (NULL != outTextureSize)
    {
        outTextureSize->width = cinfo.output_width;
        outTextureSize->height = cinfo.output_height;
    }
//    ///!!!For Debug:
//    memset(variables.quaterData, 0xffffffff, variables.rowStride * sizeof(JSAMPLE) * variables.quaterHeight);///!!!For Debug
//    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, variables.width, variables.filledQuaterDataLine, GL_RGBA, GL_UNSIGNED_BYTE, variables.quaterData);
//    glGenerateMipmap(GL_TEXTURE_2D);

//    if (cinfo.image_width <= maxTextureSize && cinfo.image_height <= maxTextureSize && variables.height > 0 && variables.width > 0)
    {
        glBindTexture(GL_TEXTURE_2D, prevTextureBinding);
        if (variables.quaterData) free(variables.quaterData);
//        ALOGE("createTextureWithJPEG : return texture = %d", variables.texture);
        return variables.texture;
    }
//    else
//    {
//        return -1;
//    }
}
