//
// Created by admin on 16/8/24.
//
#include "PNGUtils.h"
#include "Log.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
#pragma comment(lib, "zlibwapi.lib")
#pragma comment(lib, "zlibstat.lib")
#endif //#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0

#include "libpng/png.h"
#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
#include "jpeglib.h"
#include "jerror.h"
#endif
#include "OpenGLHelper.h"

#define PNG_BYTES_TO_CHECK 4
#define HAVE_ALPHA 1
#define NO_ALPHA 0

int decodePNG(const char *filepath, pic_data *out)
/* 用于解码png图片 */
{
    FILE* pic_fp = NULL;
    pic_fp = fopen(filepath, "rb");
    if(pic_fp == NULL) /* 文件打开失败 */
    {
        ALOGE("#Bug3763# decodePNG : File open failed @ %s", filepath);
        return -1;
    }

    /* 初始化各种结构 */
    png_structp png_ptr;
    png_infop  info_ptr;
    char        buf[PNG_BYTES_TO_CHECK];
    int        temp;

    png_ptr  = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
    info_ptr = png_create_info_struct(png_ptr);

    setjmp(png_jmpbuf(png_ptr)); // 这句很重要

    temp = fread(buf,1,PNG_BYTES_TO_CHECK,pic_fp);
    temp = png_sig_cmp((png_const_bytep)((void*)buf), (png_size_t)0, PNG_BYTES_TO_CHECK);

    /*检测是否为png文件*/
    if (temp!=0)
    {
        png_destroy_read_struct(&png_ptr, &info_ptr, 0);
        fclose(pic_fp);
        ALOGE("#Bug3763# decodePNG : Not PNG file @ %s", filepath);
        return -2;
    }

    rewind(pic_fp);
    /*开始读文件*/
    png_init_io(png_ptr, pic_fp);
    // 读文件了
    png_read_png(png_ptr, info_ptr, PNG_TRANSFORM_EXPAND, 0);

	int color_type = png_get_color_type(png_ptr, info_ptr);
	int channels = png_get_channels(png_ptr, info_ptr);
	int bitDepth = png_get_bit_depth(png_ptr, info_ptr);
	
	out->channels = channels;
	out->bit_depth = bitDepth; /* 获取位深 */
	ALOGE("colorType=%d, channels=%d, bitDepth=%d", color_type, out->channels, out->bit_depth);

    int i,j;
    int size, pos = 0;
    /* row_pointers里边就是rgba数据 */
    png_bytep* row_pointers;
    row_pointers = png_get_rows(png_ptr, info_ptr);
    out->width = png_get_image_width(png_ptr, info_ptr);
    out->height = png_get_image_height(png_ptr, info_ptr);
    ALOGE("decodePNG : out->bit_depth = %d, out->channels = %d, out->width = %d, out->height = %d", out->bit_depth, out->channels, out->width, out->height);

    size = out->width * out->height; /* 计算图片的总像素点数量 */
//    ALOGE("channels = %d, bits = %d, withAlpha = %d, width = %d, height = %d, colorType = %d\n", channels, out->bit_depth, out->flag, out->width, out->height, color_type);

    int bytesPerComponent = (out->bit_depth + 7) / 8;
    if(channels == 4 || color_type == PNG_COLOR_TYPE_RGB_ALPHA)
    {/*如果是RGB+alpha通道，或者RGB+其它字节*/
        size *= (bytesPerComponent * 4 * sizeof(unsigned char)); /* 每个像素点占4个字节内存 */
        out->flag = HAVE_ALPHA;    /* 标记 */
        out->rgba = (unsigned char**) malloc(size);
        if(out->rgba == NULL)
        {/* 如果分配内存失败 */
            png_destroy_read_struct(&png_ptr, &info_ptr, 0);
            fclose(pic_fp);
            puts("错误(png):无法分配足够的内存供存储数据!");
            ALOGE("#Bug3763# decodePNG : Not enough memory");
            return -3;
        }

        unsigned char* pDst = (unsigned char*) out->rgba;
        temp = (4 * out->width);/* 每行有3 * out->width个字节 */
        for(i = 0; i < out->height; i++)
        {
            memcpy(pDst, row_pointers[i], temp);
            pDst += temp;
//            for(j = 0; j < temp; j += 4)
//            {/* 一个字节一个字节的赋值 */
//                out->rgba[0][pos] = row_pointers[i][j]; // red
//                out->rgba[1][pos] = row_pointers[i][j+1]; // green
//                out->rgba[2][pos] = row_pointers[i][j+2];  // blue
//                out->rgba[3][pos] = row_pointers[i][j+3]; // alpha
//                ++pos;
//            }
        }
    }
    else if(channels == 3 || color_type == PNG_COLOR_TYPE_RGB)
    {/* 如果是RGB通道 */
        size *= (bytesPerComponent * 3 * sizeof(unsigned char)); /* 每个像素点占3个字节内存 */
        out->flag = NO_ALPHA;    /* 标记 */
        out->rgba = (unsigned char**) malloc(size);
        if(out->rgba == NULL)
        {/* 如果分配内存失败 */
            png_destroy_read_struct(&png_ptr, &info_ptr, 0);
            fclose(pic_fp);
            puts("错误(png):无法分配足够的内存供存储数据!");
            ALOGE("#Bug3763# decodePNG : File open failed 1 @ %s", filepath);
            return -4;
        }

        unsigned char* pDst = (unsigned char*) out->rgba;
        temp = (3 * out->width);/* 每行有3 * out->width个字节 */
        for(i = 0; i < out->height; i++)
        {
            memcpy(pDst, row_pointers[i], temp);
            pDst += temp;
//            for(j = 0; j < temp; j += 3)
//            {/* 一个字节一个字节的赋值 */
//                out->rgba[0][pos] = row_pointers[i][j]; // red
//                out->rgba[1][pos] = row_pointers[i][j+1]; // green
//                out->rgba[2][pos] = row_pointers[i][j+2];  // blue
//                ++pos;
//            }
        }
        ALOGE("HERE!#3 channels = %d, bits = %d, withAlpha = %d, width = %d, height = %d, colorType = %d\n", channels, out->bit_depth, out->flag, out->width, out->height, color_type);

    }
    else if (channels == 1 || color_type == PNG_COLOR_TYPE_GRAY)
    {
        size *= (bytesPerComponent * 2 * sizeof(unsigned char)); /* 每个像素点占2个字节内存 */
        out->flag = NO_ALPHA;
        out->rgba = (unsigned char**) malloc(size);
        if(out->rgba == NULL)
        {/* 如果分配内存失败 */
            png_destroy_read_struct(&png_ptr, &info_ptr, 0);
            fclose(pic_fp);
            puts("错误(png):无法分配足够的内存供存储数据!");
            ALOGE("#Bug3763# decodePNG : File open failed 2 @ %s", filepath);
            return -5;
        }

        unsigned char* pDst = (unsigned char*) out->rgba;
        for(i = 0; i < out->height; i++)
        {
            memcpy(pDst, row_pointers[i], out->width * 2);
            pDst += (out->width * 2);
        }
    }
    else
    {
        png_destroy_read_struct(&png_ptr, &info_ptr, 0);
        fclose(pic_fp);
        ALOGE("#Bug3763# decodePNG : Not handled PNG format : channel = %d, color_type = %d", channels, color_type);
        return -6;
    }

    /* 撤销数据占用的内存 */
    png_destroy_read_struct(&png_ptr, &info_ptr, 0);
    fclose(pic_fp);
    return 0;
}

int createTextureFromPNG(const char* pngPath) {
    pic_data pngData;
    if (0 != decodePNG(pngPath, &pngData))
    {ALOGE("#Bug3763# createTextureFromPNG('%s') failed.\n", pngPath);
        return -2;
    }
    
//    int length = pngData.width * pngData.height;
//    uint32_t* pUInt32 = (uint32_t*) pngData.rgba;
//    for (int j=length; j>0; --j)
//    {
//        // ABGR
//        int A = (((*pUInt32) >> 24) & 0xff);
//        int B = (((*pUInt32) >> 16) & 0xff);
//        int G = (((*pUInt32) >> 8) & 0xff);
//        int R = (((*pUInt32) >> 0) & 0xff);
//        *pUInt32++ = (A << 24) | (B << 16) | (G << 8) | (R << 0);
//    }
    
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST//GL_LINEAR_MIPMAP_LINEAR
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
	glPixelStorei(GL_PACK_ALIGNMENT, 1);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)pngData.width, (GLsizei)pngData.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pngData.rgba);
    free(pngData.rgba);
    return texture;
}

int encodePNG(const char* filename, uint8_t* pixels, int w, int h, int bitdepth)
{
    png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (!png)
        return -1;

    png_infop info = png_create_info_struct(png);
    if (!info) {
        png_destroy_write_struct(&png, &info);
        return -2;
    }

    FILE *fp = fopen(filename, "wb");
    if (!fp) {
        png_destroy_write_struct(&png, &info);
        return -3;
    }

    png_init_io(png, fp);
    if (bitdepth <= 0) bitdepth = 8;
    png_set_IHDR(png, info, w, h, bitdepth /* depth */, PNG_COLOR_TYPE_RGBA, PNG_INTERLACE_NONE,
                 PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_BASE);
    png_colorp palette = (png_colorp)png_malloc(png, PNG_MAX_PALETTE_LENGTH * sizeof(png_color));
    if (!palette) {
        fclose(fp);
        png_destroy_write_struct(&png, &info);
        return -4;
    }
    png_set_PLTE(png, info, palette, PNG_MAX_PALETTE_LENGTH);
    png_write_info(png, info);
    png_set_packing(png);

    png_bytepp rows = (png_bytepp)png_malloc(png, h * sizeof(png_bytep));
    int i;
    for (i = 0; i < h; ++i)
        rows[i] = (png_bytep)(pixels + (h - i - 1) * w * 4);

    png_write_image(png, rows);
    png_write_end(png, info);
    png_free(png, palette);
    png_destroy_write_struct(&png, &info);

    fclose(fp);
//    delete[] rows;
    free(rows);
    return 0;
}

#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
/***************************************************
    To read a jpg image file and download
    it as a texture map for openGL
    Derived from Tom Lane's example.c
    -- Obtain & install jpeg stuff from web
    (jpeglib.h, jerror.h jmore.h, jconfig.h,jpeg.lib)
****************************************************/
//================================
int LoadJPEG(char* FileName)
//================================
{
    unsigned long x, y;
    unsigned int texture_id;
    unsigned long data_size;     // length of the file
    int channels;               //  3 =>RGB   4 =>RGBA
//    unsigned int type;
    unsigned char * rowptr[1];    // pointer to an array
    unsigned char * jdata;        // data for the image
    struct jpeg_decompress_struct info; //for our jpeg info
    struct jpeg_error_mgr err;          //the error handler

    FILE* file = fopen(FileName, "rb");  //open the file

    info.err = jpeg_std_error(& err);
    jpeg_create_decompress(& info);   //fills info structure

    //if the jpeg file doesn't load
    if(!file) {
        fprintf(stderr, "Error reading JPEG file %s!", FileName);
        return 0;
    }

    jpeg_stdio_src(&info, file);
    jpeg_read_header(&info, TRUE);   // read jpeg file header

    jpeg_start_decompress(&info);    // decompress the file

    //set width and height
    x = info.output_width;
    y = info.output_height;
    channels = info.num_components;
//    type = GL_RGB;
//    if(channels == 4) type = GL_RGBA;

    data_size = x * y * 3;

    //--------------------------------------------
    // read scanlines one at a time & put bytes
    //    in jdata[] array. Assumes an RGB image
    //--------------------------------------------
    jdata = (unsigned char *)malloc(data_size);
    while (info.output_scanline < info.output_height) // loop
    {
        // Enable jpeg_read_scanlines() to fill our jdata array
        rowptr[0] = (unsigned char *)jdata +  // secret to method
                    3* info.output_width * info.output_scanline;

        jpeg_read_scanlines(&info, rowptr, 1);
    }
    //---------------------------------------------------

    jpeg_finish_decompress(&info);   //finish decompressing

//    //----- create OpenGL tex map (omit if not needed) --------
//    glGenTextures(1,&texture_id);
//    glBindTexture(GL_TEXTURE_2D, texture_id);
//    gluBuild2DMipmaps(GL_TEXTURE_2D,3,x,y,GL_RGB,GL_UNSIGNED_BYTE,jdata);

    jpeg_destroy_decompress(&info);
    fclose(file);                    //close the file
    free(jdata);

//    return texture_id;    // for OpenGL tex maps
}
#endif
