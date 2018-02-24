/*
 * Copyright (c) 2012 Stefano Sabatini
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

/**
 * @file
 * Demuxing and decoding example.
 *
 * Show how to use the libavformat and libavcodec API to demux and
 * decode audio and video data.
 * @example demuxing_decoding.c
 */

#include <stdint.h>
#include <stdbool.h>
#include "libavutil/imgutils.h"
#include "libavutil/samplefmt.h"
#include "libavutil/timestamp.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"

#pragma pack(1)

static AVFormatContext *fmt_ctx = NULL;
static AVCodecContext *video_dec_ctx = NULL;
static int width, height;
static enum AVPixelFormat pix_fmt;
static AVStream *video_stream = NULL;
static const char *src_filename = NULL;
///qiudong: static const char *video_dst_filename = NULL;
///qiudong: static FILE *video_dst_file = NULL;

static uint8_t *video_dst_data[4] = {NULL};
static int      video_dst_linesize[4];
static int video_dst_bufsize;

static int video_stream_idx = -1;
static AVFrame *frame = NULL;
static AVPacket pkt;
static int video_frame_count = 0;

static void pgm_save(AVCodecContext *p_codec_ctx, AVFrame *p_frame, char *filename);
static void bmp_save(AVCodecContext *p_codec_ctx, AVFrame *p_frame, char *filename);
static bool jpg_save(AVCodecContext *pCodecCtx, AVFrame *pFrame, char *filename);

static int decode_packet(const char* dstFilePathBaseName, int *got_frame, int cached)
{
    int ret = 0;
    int decoded = pkt.size;
    
    *got_frame = 0;
    
    if (pkt.stream_index == video_stream_idx) {
        /* decode video frame */
        ret = avcodec_decode_video2(video_dec_ctx, frame, got_frame, &pkt);
        if (ret < 0) {
            fprintf(stderr, "Error decoding video frame (%s)\n", av_err2str(ret));
            return ret;
        }
        
        if (*got_frame) {
            if (frame->width != width || frame->height != height ||
                frame->format != pix_fmt) {
                /* To handle this change, one could call av_image_alloc again and
                 * decode the following frames into another rawvideo file. */
                fprintf(stderr, "Error: Width, height and pixel format have to be "
                        "constant in a rawvideo file, but the width, height or "
                        "pixel format of the input video changed:\n"
                        "old: width = %d, height = %d, format = %s\n"
                        "new: width = %d, height = %d, format = %s\n",
                        width, height, av_get_pix_fmt_name(pix_fmt),
                        frame->width, frame->height,
                        av_get_pix_fmt_name(frame->format));
                return -1;
            }
            
            printf("video_frame%s n:%d coded_n:%d pts:%s\n",
                   cached ? "(cached)" : "",
                   video_frame_count++, frame->coded_picture_number,
                   av_ts2timestr(frame->pts, &video_dec_ctx->time_base));
            
            /* copy decoded frame to destination buffer:
             * this is required since rawvideo expects non aligned data */
            av_image_copy(video_dst_data, video_dst_linesize,
                          (const uint8_t **)(frame->data), frame->linesize,
                          pix_fmt, width, height);
            ///qiudong:
//            /* write to rawvideo file */
//            fwrite(video_dst_data[0], 1, video_dst_bufsize, video_dst_file);
            
            printf("");
            
            // pgm_save(video_dec_ctx, frame, "test.pgm");  # issue exists for pgm
            int length = (int) strlen(dstFilePathBaseName) + 4;
            char* filePathName = (char*) malloc(length + 1);
            
            sprintf(filePathName, "%s.bmp", dstFilePathBaseName);
            bmp_save(video_dec_ctx, frame, filePathName);
            
            free(filePathName);
//            sprintf(filePathName, "%s.jpg", dstFilePathBaseName);
//            jpg_save(video_dec_ctx, frame, filePathName);
        }
        /*
        else {
            printf("Something Wrong! #1");
            exit(-2);
        }
        //*/
    }
    
    return decoded;
}

static int open_codec_context(int *stream_idx,
                              AVFormatContext *fmt_ctx, enum AVMediaType type)
{
    int ret, stream_index;
    AVStream *st;
    AVCodecContext *dec_ctx = NULL;
    AVCodec *dec = NULL;
    AVDictionary *opts = NULL;
    
    ret = av_find_best_stream(fmt_ctx, type, -1, -1, NULL, 0);
    if (ret < 0) {
        fprintf(stderr, "Could not find %s stream in input file '%s'\n",
                av_get_media_type_string(type), src_filename);
        return ret;
    } else {
        stream_index = ret;
        st = fmt_ctx->streams[stream_index];
        
        /* find decoder for the stream */
        dec_ctx = st->codec;
        dec = avcodec_find_decoder(dec_ctx->codec_id);
        if (!dec) {
            fprintf(stderr, "Failed to find %s codec\n",
                    av_get_media_type_string(type));
            return AVERROR(EINVAL);
        }
        
        /* Init the decoders, with or without reference counting */
        if ((ret = avcodec_open2(dec_ctx, dec, &opts)) < 0) {
            fprintf(stderr, "Failed to open %s codec\n",
                    av_get_media_type_string(type));
            return ret;
        }
        *stream_idx = stream_index;
    }
    
    return 0;
}

int decodeIDR(const char* srcFilePathName, const char* dstFilePathBaseName)
{
    int ret = 0, got_frame;
    
    src_filename = srcFilePathName;
///qiudong:     video_dst_filename = dstFilePathBaseName;
    
    /* register all formats and codecs */
    av_register_all();
    
    /* open input file, and allocate format context */
    if (avformat_open_input(&fmt_ctx, src_filename, NULL, NULL) < 0) {
        fprintf(stderr, "Could not open source file %s\n", src_filename);
//        exit(1);
        return -1;
    }
    
    /* retrieve stream information */
    if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
        fprintf(stderr, "Could not find stream information\n");
//        exit(1);
    }
    
    if (open_codec_context(&video_stream_idx, fmt_ctx, AVMEDIA_TYPE_VIDEO) >= 0) {
        video_stream = fmt_ctx->streams[video_stream_idx];
        video_dec_ctx = video_stream->codec;
        ///qiudong:
//        video_dst_file = fopen(video_dst_filename, "wb");
//        if (!video_dst_file) {
//            fprintf(stderr, "Could not open destination file %s\n", video_dst_filename);
//            ret = 1;
//            goto end;
//        }
        if (fmt_ctx->metadata)
        {
            AVDictionaryEntry* m = NULL;
            while((m = av_dict_get(fmt_ctx->metadata,"", m ,AV_DICT_IGNORE_SUFFIX)))
            {
                printf("MetaData: (key, value) = (\"%s\", \"%s\")\n", m->key, m->value);
            }
        }
        
        
        /* allocate image where the decoded image will be put */
        width = video_dec_ctx->width;
        height = video_dec_ctx->height;
        pix_fmt = video_dec_ctx->pix_fmt;
        ret = av_image_alloc(video_dst_data, video_dst_linesize,
                             width, height, pix_fmt, 1);
        if (ret < 0) {
            fprintf(stderr, "Could not allocate raw video buffer\n");
            goto end;
        }
        video_dst_bufsize = ret;
    }
    else {
        printf("Something Wrong! #0");
    }
    
    /* dump input information to stderr */
    av_dump_format(fmt_ctx, 0, src_filename, 0);
    
    if (!video_stream) {
        fprintf(stderr, "Could not find video stream in the input, aborting\n");
        ret = 1;
        goto end;
    }
    
    frame = av_frame_alloc();
    if (!frame) {
        fprintf(stderr, "Could not allocate frame\n");
        ret = AVERROR(ENOMEM);
        goto end;
    }
    
    /* initialize packet, set data to NULL, let the demuxer fill it */
    av_init_packet(&pkt);
    pkt.data = NULL;
    pkt.size = 0;
    
///qiudong:     if (video_stream)
//        printf("Demuxing video from file '%s' into '%s'\n", src_filename, video_dst_filename);
    
    /* read frames from the file */
    while (av_read_frame(fmt_ctx, &pkt) >= 0) {
        AVPacket orig_pkt = pkt;
        do {
            ret = decode_packet(dstFilePathBaseName, &got_frame, 0);
            if (ret < 0)
                break;
            pkt.data += ret;
            pkt.size -= ret;
        } while (pkt.size > 0);
        av_free_packet(&orig_pkt);
    }
    
    /* flush cached frames */
    pkt.data = NULL;
    pkt.size = 0;
    do {
        decode_packet(dstFilePathBaseName, &got_frame, 1);
    } while (got_frame);
    
    printf("Demuxing succeeded.\n");
    
///qiudong:     if (video_stream) {
//        printf("Play the output video file with the command:\n"
//               "ffplay -f rawvideo -pix_fmt %s -video_size %dx%d %s\n",
//               av_get_pix_fmt_name(pix_fmt), width, height,
//               video_dst_filename);
//    }
    
end:
    if (video_dec_ctx) avcodec_close(video_dec_ctx);
    if (fmt_ctx) avformat_close_input(&fmt_ctx);
///qiudong:    if (video_dst_file)
//        fclose(video_dst_file);
    if (frame) av_frame_free(&frame);
    if (video_dst_data[0]) av_free(video_dst_data[0]);
    
    fmt_ctx = NULL;
    video_dec_ctx = NULL;
    video_stream = NULL;
    src_filename = NULL;
    video_stream_idx = -1;
    frame = NULL;
    video_frame_count = 0;
    video_dst_data[0] = NULL;
    video_dst_data[1] = NULL;
    video_dst_data[2] = NULL;
    video_dst_data[3] = NULL;
    video_dst_linesize[0] = 0;
    video_dst_linesize[1] = 0;
    video_dst_linesize[2] = 0;
    video_dst_linesize[3] = 0;
    video_dst_bufsize = 0;
    
    return ret < 0;
}


static void pgm_save(AVCodecContext *p_codec_ctx, AVFrame *p_frame, char *filename) {
    FILE *p_file = fopen(filename,"w");
    fprintf(p_file, "P6\n%d %d\n255\n", p_codec_ctx->width, p_codec_ctx->height);
    
    int i;
    for (i = 0; i < p_codec_ctx->height; i++)
        fwrite(p_frame->data[0] + i * p_frame->linesize[0], 1, p_codec_ctx->width*3, p_file);
    
    fclose(p_file);
}

typedef struct {
    uint16_t bfType;
    uint32_t bfSize;
    uint16_t bfReserved1;
    uint16_t bfReserved2;
    uint32_t bfOffBits;
} BITMAPFILEHEADER;

typedef struct {
    uint32_t biSize;
    uint32_t biWidth;
    uint32_t biHeight;
    uint16_t biPlanes;
    uint16_t biBitCount;
    uint32_t biCompression;
    uint32_t biSizeImage;
    uint32_t biXPelsPerMeter;
    uint32_t biYPelsPerMeter;
    uint32_t biClrUsed;
    uint32_t biClrImportant;
} BITMAPINFOHEADER;

static void bmp_save(AVCodecContext *p_codec_ctx, AVFrame *p_frame, char *filename) {
    int width = p_codec_ctx->width;
    int height = p_codec_ctx->height;
    printf("w:h %dx%d %d %d\n", width, height, sizeof(BITMAPFILEHEADER), sizeof(BITMAPINFOHEADER));
    
    struct SwsContext* pSwsCxt = sws_getContext(
                                                width, height,
                                                PIX_FMT_YUV420P,
                                                width, height,
                                                PIX_FMT_RGB32,
                                                SWS_BILINEAR, NULL, NULL, NULL);
    
    uint8_t *rgb_data = (uint8_t*) av_malloc(width*height*4);
    uint8_t *rgb_src[3] = {rgb_data, NULL, NULL};
    int rgb_stride[3]={4*width, 0, 0};
    sws_scale(pSwsCxt, p_frame->data, p_frame->linesize, 0, height, rgb_src, rgb_stride);
    
    FILE *p_file = fopen(filename, "w");
    int bpp = 32;
    BITMAPFILEHEADER bmpheader;
    BITMAPINFOHEADER bmpinfo;
    bmpheader.bfType = ('M'<<8)|'B';
    bmpheader.bfReserved1 = 0;
    bmpheader.bfReserved2 = 0;
    bmpheader.bfOffBits = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER);
    bmpheader.bfSize = bmpheader.bfOffBits + width*height*bpp/8;
    
    bmpinfo.biSize = sizeof(BITMAPINFOHEADER);
    bmpinfo.biWidth = width;
    bmpinfo.biHeight = 0 - height;
    bmpinfo.biPlanes = 1;
    bmpinfo.biBitCount = bpp;
    bmpinfo.biCompression = 0;
    bmpinfo.biSizeImage = 0;
    bmpinfo.biXPelsPerMeter = 100;
    bmpinfo.biYPelsPerMeter = 100;
    bmpinfo.biClrUsed = 0;
    bmpinfo.biClrImportant = 0;
    
    fwrite(&bmpheader, sizeof(BITMAPFILEHEADER),1, p_file);
    fwrite(&bmpinfo, sizeof(BITMAPINFOHEADER), 1, p_file);
    fwrite(rgb_data, width*height*bpp/8,1,p_file);
    fclose(p_file);
    
    av_freep(&rgb_data);
    sws_freeContext(pSwsCxt);
}


bool SaveFrame(int nszBuffer, uint8_t *buffer, char *filename) {
    //printf("SaveFrame nszBuffer = %d, filename = %s\n", nszBuffer, filename);
    bool bRet = false;
    
    if ( nszBuffer > 0 ) {
        FILE *pFile = fopen(filename, "wb");
        if(pFile) {
            fwrite(buffer, sizeof(uint8_t), nszBuffer, pFile);
            bRet = true;
            fclose(pFile);
        }
    }
    return bRet;
}

bool jpg_save(AVCodecContext *pCodecCtx, AVFrame *pFrame, char *filename) {
    int numBytes = avpicture_get_size(PIX_FMT_YUVJ420P, pCodecCtx->width, pCodecCtx->height);
    uint8_t *buffer=(uint8_t *)av_malloc(numBytes*sizeof(uint8_t));
    
    bool bRet = false;
    AVCodec *pMJPEGCodec = avcodec_find_encoder(AV_CODEC_ID_MJPEG);
    if (!pMJPEGCodec) {
        printf("AV_CODEC_ID_MJPEG not found\n");
        return false;
    }
    
    AVCodecContext *pMJPEGCtx = avcodec_alloc_context3(pMJPEGCodec);
    if (pMJPEGCtx) {
        pMJPEGCtx->bit_rate = pCodecCtx->bit_rate;
        pMJPEGCtx->width = pCodecCtx->width;
        pMJPEGCtx->height = pCodecCtx->height;
        pMJPEGCtx->pix_fmt = PIX_FMT_YUVJ420P;
        pMJPEGCtx->codec_id = CODEC_ID_MJPEG;
        pMJPEGCtx->codec_type = AVMEDIA_TYPE_VIDEO;
        pMJPEGCtx->time_base.num = pCodecCtx->time_base.num;
        pMJPEGCtx->time_base.den = pCodecCtx->time_base.den;
        
        if ( pMJPEGCodec && (avcodec_open2( pMJPEGCtx, pMJPEGCodec, NULL) >= 0) ) {
            pMJPEGCtx->qmin = pMJPEGCtx->qmax = 3;
            pMJPEGCtx->mb_lmin = pMJPEGCtx->lmin = pMJPEGCtx->qmin * FF_QP2LAMBDA;
            pMJPEGCtx->mb_lmax = pMJPEGCtx->lmax = pMJPEGCtx->qmax * FF_QP2LAMBDA;
            pMJPEGCtx->flags |= CODEC_FLAG_QSCALE;
            pFrame->quality = 10;
            pFrame->pts = 0;
            
            int szBufferActual = avcodec_encode_video(pMJPEGCtx, buffer, numBytes, pFrame);
            
            if( SaveFrame(szBufferActual, buffer, filename ) )
                bRet = true;
            
            avcodec_close(pMJPEGCtx);
        }
    }
    return bRet;
}
