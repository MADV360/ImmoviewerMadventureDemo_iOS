//
//  h264_iOS8VTHD.hpp
//  kxmovie
//
//  Created by videbo-pengyu on 16/1/12.
//
//

#ifndef h264_iOS8VTHD_hpp
#define h264_iOS8VTHD_hpp

#include <pthread.h>

#include <CoreVideo/CoreVideo.h>
#include <CoreMedia/CoreMedia.h>

// tracks a frame in and output queue in display order
typedef struct frame_queue
{
    int64_t              dts;
    int64_t              pts;
    int                 width;
    int                 height;
    int64_t              sort_time;
    FourCharCode        pixel_buffer_format;
    CVPixelBufferRef    pixel_buffer_ref;
    struct frame_queue*  nextframe;
} frame_queue;

typedef struct avc_nul_head
{
    avc_nul_head()
    {
        sps = NULL;
        sps_len = 0;
        pps = NULL;
        pps_len = 0;
    }
    uint8_t * sps;
    int         sps_len;
    uint8_t * pps;
    int         pps_len;
} avc_nul_head;

static void VTDecoderCallback(
                              void *refCon,
                              CFDictionaryRef    frameInfo,
                              OSStatus status,
                              UInt32 infoFlags,
                              CVImageBufferRef imageBuffer,
                              CMTime presentationTimeStamp,
                              CMTime presentationDuration );

#endif /* h264_iOS8VTHD_hpp */
