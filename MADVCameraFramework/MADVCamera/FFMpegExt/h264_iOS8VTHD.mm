//
//  h264_iOS8VTHD.cpp
//  kxmovie
//
//  Created by videbo-pengyu on 16/1/12.
//
//

#include "h264_iOS8VTHD.h"
#include "DarwinUtils.h"
#include "TimeUtils.h"

extern "C" {
#include "libswscale/swscale.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavformat/avio.h"
#include "libavutil/opt.h"
}

#define MAX_PKT_QUEUE_DEEP   500

static const int kNALUHeaderLength = 4;

#pragma mark - ffmpeg H264VTDecoder implementation
typedef struct H264VTContext {
    int                 _width;
    int                 _height;
    
    void*               _vt_session;    // opaque videotoolbox session
    CMFormatDescriptionRef _fmt_desc;
    
    avc_nul_head        _avcheadinfo;
    int32_t             _queue_depth;
    int32_t             _max_ref_frames;
    
    double              _sort_time_offset;
    pthread_mutex_t     _queue_mutex;
    frame_queue*        _display_queue;
    
    bool                _convert_bytestream;
    bool                _convert_3byteTo4byteNALSize;
    bool                _h264decoder;
    
    int                 _buffer_deep;
    int                 _buffer_keypos;
    AVPacket            _buffer_packet[MAX_PKT_QUEUE_DEEP];
} H264VTContext;

void CreateVTSession(H264VTContext *vtc,int width, int height, CMFormatDescriptionRef fmt_desc);
void DestroyVTSession(H264VTContext *vtc);
void ResetVTSession(H264VTContext *vtc);

#if defined(ENABLE_MONITOR)
@interface BackgroundMonitor : NSObject
{
}

@property (nonatomic, assign) H264VTContext * h264context;
+(BackgroundMonitor*) getInstance;
-(void)RegisterMonitor;
-(void)UnRegisterMonitor;
@end

@implementation BackgroundMonitor
+ (BackgroundMonitor *)getInstance
{
    static BackgroundMonitor *sharedBKMonitorInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedBKMonitorInstance = [[self alloc] init];
    });
    return sharedBKMonitorInstance;
}

-(instancetype) init{
    self = [super init];
    _h264context = NULL;
    return self;
}

-(void)RegisterMonitor
{
    //NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    //[nc addObserver:self selector:@selector(_applicationWillResignActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    //[nc addObserver:self selector:@selector(_applicationDidEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
}

-(void)UnRegisterMonitor
{
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - App NSNotifications
-(void)_applicationWillResignActive:(NSNotification *)aNotfication
{
    NSLog(@"BackgroundMonitor _applicationWillResignActive");
    pthread_mutex_lock(&_h264context->_operation_mutex);
    if (_h264context)
    {
        //if (!_h264context->_vt_session)
        {
            DestroyVTSession(_h264context);
            CreateVTSession(_h264context,_h264context->_width,_h264context->_height,_h264context->_fmt_desc);
            //ResetVTSession(_h264context);
        }
    }
    pthread_mutex_unlock(&_h264context->_operation_mutex);
}

-(void)_applicationDidEnterBackground:(NSNotification *)aNotfication
{
    NSLog(@"BackgroundMonitor _applicationDidEnterBackground");
    pthread_mutex_lock(&_h264context->_operation_mutex);
    if (_h264context)
    {
        //DestroyVTSession(_h264context);
    }
    pthread_mutex_unlock(&_h264context->_operation_mutex);
}
@end
#endif

#if defined(__cplusplus)
extern "C"
{
#endif
    
#pragma pack(push, 4)
    
    //-----------------------------------------------------------------------------------
    // /System/Library/PrivateFrameworks/VideoToolbox.framework
    enum VTFormat {
        kVTFormatJPEG         = 'jpeg', // kCMVideoCodecType_JPEG
        kVTFormatH264         = 'avc1', // kCMVideoCodecType_H264 (MPEG-4 Part 10))
        kVTFormatMPEG4Video   = 'mp4v', // kCMVideoCodecType_MPEG4Video (MPEG-4 Part 2)
        kVTFormatMPEG2Video   = 'mp2v'  // kCMVideoCodecType_MPEG2Video
    };
    enum
    {
        kVTDecoderNoErr = 0,
        kVTDecoderHardwareNotSupportedErr = -12470,
        kVTDecoderFormatNotSupportedErr = -12471,
        kVTDecoderConfigurationError = -12472,
        kVTDecoderDecoderFailedErr = -12473,
        kVTInvalidSessionErr = -12903,
    };
    /*
     enum
     {
     kVTDecodeInfo_Asynchronous = 1UL << 0,
     kVTDecodeInfo_FrameDropped = 1UL << 1
     };
     */
    enum
    {
        // tells the decoder not to bother returning a CVPixelBuffer
        // in the outputCallback. The output callback will still be called.
        //kVTDecoderDecodeFlags_DontEmitFrame = 1 << 0
        kVTDecoderDecodeFlags_DontEmitFrame = 1 << 1, // iOS8 new define
    };
    enum
    {
        // decode and return buffers for all frames currently in flight.
        kVTDecoderFlush_EmitFrames = 1 << 0
    };
    
    typedef UInt32 VTFormatId;
    typedef CFTypeRef VTDecompressionSessionRef;
    
    typedef UInt32 VTDecodeInfoFlags;
    enum {
        kVTDecodeInfo_Asynchronous = 1UL << 0,
        kVTDecodeInfo_FrameDropped = 1UL << 1,
        kVTDecodeInfo_ImageBufferModifiable = 1UL << 2,
    };
    /*
     typedef void (*VTDecompressionOutputCallbackFunc)(
     void*            refCon,
     CFDictionaryRef frameInfo,
     OSStatus        status,
     UInt32          infoFlags,
     CVBufferRef     imageBuffer);
     */
    typedef void (*VTDecompressionOutputCallbackFunc)(
    void *refCon,
    CFDictionaryRef frameInfo,
    OSStatus status,
    UInt32 infoFlags,
    CVImageBufferRef imageBuffer,
    CMTime presentationTimeStamp,
    CMTime presentationDuration );
    
    typedef struct _VTDecompressionOutputCallback VTDecompressionOutputCallback;
    struct _VTDecompressionOutputCallback
    {
        VTDecompressionOutputCallbackFunc callback;
        void* refcon;
    };
    
    extern CFStringRef kVTVideoDecoderSpecification_EnableSandboxedVideoDecoder;
    
    extern OSStatus VTDecompressionSessionCreate(
                                                 CFAllocatorRef allocator,
                                                 CMFormatDescriptionRef videoFormatDescription,
                                                 CFTypeRef sessionOptions,
                                                 CFDictionaryRef destinationPixelBufferAttributes,
                                                 VTDecompressionOutputCallback* outputCallback,
                                                 VTDecompressionSessionRef* session);
    
    extern OSStatus VTDecompressionSessionDecodeFrame(
                                                      VTDecompressionSessionRef session, CMSampleBufferRef sbuf,
                                                      uint32_t decoderFlags, CFDictionaryRef frameInfo, uint32_t unk1);
    
    extern OSStatus VTDecompressionSessionCopyProperty(VTDecompressionSessionRef session, CFTypeRef key, void* unk, CFTypeRef* value);
    extern OSStatus VTDecompressionSessionCopySupportedPropertyDictionary(VTDecompressionSessionRef session, CFDictionaryRef* dict);
    extern OSStatus VTDecompressionSessionSetProperty(VTDecompressionSessionRef session, CFStringRef propName, CFTypeRef propValue);
    extern void VTDecompressionSessionInvalidate(VTDecompressionSessionRef session);
    extern void VTDecompressionSessionRelease(VTDecompressionSessionRef session);
    extern VTDecompressionSessionRef VTDecompressionSessionRetain(VTDecompressionSessionRef session);
    extern OSStatus VTDecompressionSessionWaitForAsynchronousFrames(VTDecompressionSessionRef session);
    
    //-----------------------------------------------------------------------------------
    // /System/Library/Frameworks/CoreMedia.framework
#if 0
    union
    {
        void* lpAddress;
        // iOS <= 4.2
        OSStatus (*FigVideoFormatDescriptionCreateWithSampleDescriptionExtensionAtom1)(
                                                                                       CFAllocatorRef allocator, UInt32 formatId, UInt32 width, UInt32 height,
                                                                                       UInt32 atomId, const UInt8 *data, CFIndex len, CMFormatDescriptionRef *formatDesc);
        // iOS >= 4.3
        OSStatus (*FigVideoFormatDescriptionCreateWithSampleDescriptionExtensionAtom2)(
                                                                                       CFAllocatorRef allocator, UInt32 formatId, UInt32 width, UInt32 height,
                                                                                       UInt32 atomId, const UInt8 *data, CFIndex len, CFDictionaryRef extensions, CMFormatDescriptionRef *formatDesc);
    } FigVideoHack;
    extern OSStatus FigVideoFormatDescriptionCreateWithSampleDescriptionExtensionAtom(
                                                                                      CFAllocatorRef allocator, UInt32 formatId, UInt32 width, UInt32 height,
                                                                                      UInt32 atomId, const UInt8 *data, CFIndex len, CMFormatDescriptionRef *formatDesc);
    
    extern CMSampleBufferRef FigSampleBufferRetain(CMSampleBufferRef buf);
    //-----------------------------------------------------------------------------------#pragma pack(pop)
#endif
#if defined(__cplusplus)
}
#endif

int CheckNP2(unsigned x)
{
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return ++x;
}

//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
// helper function that inserts an int32_t into a dictionary
static void
CFDictionarySetSInt32(CFMutableDictionaryRef dictionary, CFStringRef key, SInt32 numberSInt32)
{
    CFNumberRef number;
    
    number = CFNumberCreate(NULL, kCFNumberSInt32Type, &numberSInt32);
    CFDictionarySetValue(dictionary, key, number);
    CFRelease(number);
}
// helper function that inserts an double into a dictionary
static void
CFDictionarySetDouble(CFMutableDictionaryRef dictionary, CFStringRef key, double numberDouble)
{
    CFNumberRef number;
    
    number = CFNumberCreate(NULL, kCFNumberDoubleType, &numberDouble);
    CFDictionaryAddValue(dictionary, key, number);
    CFRelease(number);
}
// helper function that inserts NULL into a dictionary
static void
CFDictionarySetNil(CFMutableDictionaryRef dictionary, CFStringRef key)
{
    CFDictionaryAddValue(dictionary, key , NULL);
}

// helper function that wraps dts/pts into a dictionary
static CFDictionaryRef
CreateDictionaryWithDisplayTime(double time, int64_t dts, int64_t pts)
{
    CFStringRef key[3] =
    {
        CFSTR("VideoDisplay_TIME"),
        CFSTR("VideoDisplay_DTS"),
        CFSTR("VideoDisplay_PTS")
    };
    CFNumberRef value[3];
    CFDictionaryRef display_time;
    
    value[0] = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &time);
    value[1] = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &dts);
    value[2] = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &pts);
    //value[0] = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &time);
    //value[1] = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &dts);
    //value[2] = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &pts);
    
    
    display_time = CFDictionaryCreate(
                                      kCFAllocatorDefault, (const void**)&key, (const void**)&value, 3,
                                      &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    CFRelease(value[0]);
    CFRelease(value[1]);
    CFRelease(value[2]);
    
    return display_time;
}
// helper function to extract dts/pts from a dictionary
static void
GetFrameDisplayTimeFromDictionary(
                                  CFDictionaryRef inFrameInfoDictionary, frame_queue* frame)
{
    // default to DVD_NOPTS_VALUE
    frame->sort_time = -1.0;
    frame->dts = AV_NOPTS_VALUE;
    frame->pts = AV_NOPTS_VALUE;
    if (inFrameInfoDictionary == NULL)
        return;
    
    CFNumberRef value[3];
    if (CFDictionaryGetCount(inFrameInfoDictionary) <= 0)
        return;
    //
    /*
     value[0] = (CFNumberRef)CFDictionaryGetValue(inFrameInfoDictionary, CFSTR("VideoDisplay_TIME"));
     if (value[0])
     CFNumberGetValue(value[0], kCFNumberDoubleType, &frame->sort_time);
     value[1] = (CFNumberRef)CFDictionaryGetValue(inFrameInfoDictionary, CFSTR("VideoDisplay_DTS"));
     if (value[1])
     CFNumberGetValue(value[1], kCFNumberDoubleType, &frame->dts);
     value[2] = (CFNumberRef)CFDictionaryGetValue(inFrameInfoDictionary, CFSTR("VideoDisplay_PTS"));
     if (value[2])
     CFNumberGetValue(value[2], kCFNumberDoubleType, &frame->pts);
     */
    value[0] = (CFNumberRef)CFDictionaryGetValue(inFrameInfoDictionary, CFSTR("VideoDisplay_TIME"));
    if (value[0])
        CFNumberGetValue(value[0], kCFNumberLongLongType, &frame->sort_time);
    value[1] = (CFNumberRef)CFDictionaryGetValue(inFrameInfoDictionary, CFSTR("VideoDisplay_DTS"));
    if (value[1])
        CFNumberGetValue(value[1], kCFNumberLongLongType, &frame->dts);
    value[2] = (CFNumberRef)CFDictionaryGetValue(inFrameInfoDictionary, CFSTR("VideoDisplay_PTS"));
    if (value[2])
        CFNumberGetValue(value[2], kCFNumberLongLongType, &frame->pts);
    
    return;
}

static void
FreeFrameDisplayTimeFromDictionary(
                                   CFDictionaryRef inFrameInfoDictionary)
{
    if (inFrameInfoDictionary == NULL)
        return;
    
    CFNumberRef value[3];
    if (CFDictionaryGetCount(inFrameInfoDictionary) <= 0)
        return;
    //
    value[0] = (CFNumberRef)CFDictionaryGetValue(inFrameInfoDictionary, CFSTR("VideoDisplay_TIME"));
    if (value[0])
        CFRelease(value[0]);
    value[1] = (CFNumberRef)CFDictionaryGetValue(inFrameInfoDictionary, CFSTR("VideoDisplay_DTS"));
    if (value[1])
        CFRelease(value[1]);
    value[2] = (CFNumberRef)CFDictionaryGetValue(inFrameInfoDictionary, CFSTR("VideoDisplay_PTS"));
    if (value[2])
        CFRelease(value[2]);
    
    CFRelease(inFrameInfoDictionary);
    return;
}

// helper function to create a format descriptor
static CMFormatDescriptionRef
CreateFormatDescription(VTFormatId format_id, int width, int height)
{
    CMFormatDescriptionRef fmt_desc;
    OSStatus status;
    
    //CMVideoFormatDescriptionCreateFromH264ParameterSets
    
    status = CMVideoFormatDescriptionCreate(
                                            NULL,             // CFAllocatorRef allocator
                                            format_id,
                                            width,
                                            height,
                                            NULL,             // CFDictionaryRef extensions
                                            &fmt_desc);
    
    if (status == kVTDecoderNoErr)
        return fmt_desc;
    else
        return NULL;
}
// helper function to create a avcC atom format descriptor
static CMFormatDescriptionRef
CreateFormatDescriptionFromCodecData(VTFormatId format_id, int width, int height, const uint8_t* extradata, int extradata_size, uint32_t atom,avc_nul_head * avchead)
{
    //CMFormatDescriptionRef
    CMFormatDescriptionRef fmt_desc = NULL;
    OSStatus status;
    
    if (!avchead)
        return NULL;
    
    if (avchead->sps_len <= 0)
        return NULL;
    
    const uint8_t* const parameterSetPointers[2] = { (const uint8_t*)avchead->sps, (const uint8_t*)avchead->pps };
    const size_t parameterSetSizes[2] = { static_cast<size_t>(avchead->sps_len), static_cast<size_t>(avchead->pps_len) };
    status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
                                                                 kCFAllocatorDefault,
                                                                 2,
                                                                 parameterSetPointers,
                                                                 parameterSetSizes,
                                                                 kNALUHeaderLength,
                                                                 &fmt_desc);
    if (status == kVTDecoderNoErr)
        return fmt_desc;
    else
        return NULL;
}

#if 0
static CMFormatDescriptionRef
CreateFormatDescriptionFromCodecData(VTFormatId format_id, int width, int height, const uint8_t* extradata, int extradata_size, uint32_t atom)
{
    //CMFormatDescriptionRef
    CMFormatDescriptionRef fmt_desc = NULL;
    OSStatus status;
    
    if (!extradata)
        return NULL;
    
    if (extradata_size <= 0)
        return NULL;
    
    FigVideoHack.lpAddress = (void*)FigVideoFormatDescriptionCreateWithSampleDescriptionExtensionAtom;
    
    
    status = FigVideoHack.FigVideoFormatDescriptionCreateWithSampleDescriptionExtensionAtom2(
                                                                                             NULL,
                                                                                             format_id,
                                                                                             width,
                                                                                             height,
                                                                                             atom,
                                                                                             extradata,
                                                                                             extradata_size,
                                                                                             NULL,
                                                                                             &fmt_desc);
    if (status == kVTDecoderNoErr)
        return fmt_desc;
    else
        return NULL;
}
#endif

// helper function to create a CMSampleBufferRef from demuxer data
static CMSampleBufferRef
CreateSampleBufferFrom(CMFormatDescriptionRef fmt_desc, void* demux_buff, size_t demux_size)
{
    OSStatus status;
    CMBlockBufferRef newBBufOut = NULL;
    CMSampleBufferRef sBufOut = NULL;
    
    status = CMBlockBufferCreateWithMemoryBlock(
                                                NULL,             // CFAllocatorRef structureAllocator
                                                demux_buff,       // void *memoryBlock
                                                demux_size,       // size_t blockLengt
                                                kCFAllocatorNull, // CFAllocatorRef blockAllocator
                                                NULL,             // const CMBlockBufferCustomBlockSource *customBlockSource
                                                0,                // size_t offsetToData
                                                demux_size,       // size_t dataLength
                                                FALSE,            // CMBlockBufferFlags flags
                                                &newBBufOut);     // CMBlockBufferRef *newBBufOut
    if (!status && newBBufOut)
    {
        status = CMSampleBufferCreate(
                                      NULL,           // CFAllocatorRef allocator
                                      newBBufOut,     // CMBlockBufferRef dataBuffer
                                      TRUE,           // Boolean dataReady
                                      0,              // CMSampleBufferMakeDataReadyCallback makeDataReadyCallback
                                      0,              // void *makeDataReadyRefcon
                                      fmt_desc,       // CMFormatDescriptionRef formatDescription
                                      1,              // CMItemCount numSamples
                                      0,              // CMItemCount numSampleTimingEntries
                                      NULL,           // const CMSampleTimingInfo *sampleTimingArray
                                      0,              // CMItemCount numSampleSizeEntries
                                      NULL,           // const size_t *sampleSizeArray
                                      &sBufOut);      // CMSampleBufferRef *sBufOut
    }
    if (newBBufOut)
        CFRelease(newBBufOut);
    
    /*
     CLog::Log(LOGDEBUG, "%s - CreateSampleBufferFrom size %ld demux_buff [0x%08x] sBufOut [0x%08x]",
     __FUNCTION__, demux_size, (unsigned int)demux_buff, (unsigned int)sBufOut);
     */
    
    return sBufOut;
}

//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
/* MPEG-4 esds (elementary stream descriptor) */
typedef struct {
    int version;
    long flags;
    
    uint16_t esid;
    uint8_t  stream_priority;
    
    uint8_t  objectTypeId;
    uint8_t  streamType;
    uint32_t bufferSizeDB;
    uint32_t maxBitrate;
    uint32_t avgBitrate;
    
    int      decoderConfigLen;
    uint8_t* decoderConfig;
} quicktime_esds_t;

int quicktime_write_mp4_descr_length(AVIOContext *pb, int length, int compact)
{
    int i;
    uint8_t b;
    int numBytes;
    
    if (compact)
    {
        if (length <= 0x7F)
        {
            numBytes = 1;
        }
        else if (length <= 0x3FFF)
        {
            numBytes = 2;
        }
        else if (length <= 0x1FFFFF)
        {
            numBytes = 3;
        }
        else
        {
            numBytes = 4;
        }
    }
    else
    {
        numBytes = 4;
    }
    
    for (i = numBytes-1; i >= 0; i--)
    {
        b = (length >> (i * 7)) & 0x7F;
        if (i != 0)
        {
            b |= 0x80;
        }
        avio_w8(pb, b);
    }
    
    return numBytes;
}

void quicktime_write_esds(AVIOContext *pb, quicktime_esds_t *esds)
{
    avio_w8(pb, 0);     // Version
    avio_wb24(pb, 0);     // Flags
    
    // elementary stream descriptor tag
    avio_w8(pb, 0x03);
    quicktime_write_mp4_descr_length(pb,
                                     3 + 5 + (13 + 5 + esds->decoderConfigLen) + 3, false);
    // 3 bytes + 5 bytes for tag
    avio_wb16(pb, esds->esid);
    avio_w8(pb, esds->stream_priority);
    
    // decoder configuration description tag
    avio_w8(pb, 0x04);
    quicktime_write_mp4_descr_length(pb,
                                     13 + 5 + esds->decoderConfigLen, false);
    // 13 bytes + 5 bytes for tag
    avio_w8(pb, esds->objectTypeId); // objectTypeIndication
    avio_w8(pb, esds->streamType);   // streamType
    avio_wb24(pb, esds->bufferSizeDB); // buffer size
    avio_wb32(pb, esds->maxBitrate);   // max bitrate
    avio_wb32(pb, esds->avgBitrate);   // average bitrate
    
    // decoder specific description tag
    avio_w8(pb, 0x05);
    quicktime_write_mp4_descr_length(pb, esds->decoderConfigLen, false);
    avio_write(pb, esds->decoderConfig, esds->decoderConfigLen);
    
    // sync layer configuration descriptor tag
    avio_w8(pb, 0x06);  // tag
    avio_w8(pb, 0x01);  // length
    avio_w8(pb, 0x7F);  // no SL
    
    /* no IPI_DescrPointer */
    /* no IP_IdentificationDataSet */
    /* no IPMP_DescriptorPointer */
    /* no LanguageDescriptor */
    /* no QoS_Descriptor */
    /* no RegistrationDescriptor */
    /* no ExtensionDescriptor */
    
}

quicktime_esds_t* quicktime_set_esds(const uint8_t * decoderConfig, int decoderConfigLen)
{
    // ffmpeg's codec->avctx->extradata, codec->avctx->extradata_size
    // are decoderConfig/decoderConfigLen
    quicktime_esds_t *esds;
    
    esds = (quicktime_esds_t*)malloc(sizeof(quicktime_esds_t));
    memset(esds, 0, sizeof(quicktime_esds_t));
    
    esds->version         = 0;
    esds->flags           = 0;
    
    esds->esid            = 0;
    esds->stream_priority = 0;      // 16 ? 0x1f
    
    esds->objectTypeId    = 32;     // 32 = AV_CODEC_ID_MPEG4, 33 = AV_CODEC_ID_H264
    // the following fields is made of 6 bits to identify the streamtype (4 for video, 5 for audio)
    // plus 1 bit to indicate upstream and 1 bit set to 1 (reserved)
    esds->streamType      = 0x11;
    esds->bufferSizeDB    = 64000;  // Hopefully not important :)
    
    // Maybe correct these later?
    esds->maxBitrate      = 200000; // 0 for vbr
    esds->avgBitrate      = 200000;
    
    esds->decoderConfigLen = decoderConfigLen;
    esds->decoderConfig = (uint8_t*)malloc(esds->decoderConfigLen);
    memcpy(esds->decoderConfig, decoderConfig, esds->decoderConfigLen);
    return esds;
}

void quicktime_esds_dump(quicktime_esds_t * esds)
{
    int i;
    printf("esds: \n");
    printf(" Version:          %d\n",       esds->version);
    printf(" Flags:            0x%06lx\n",  esds->flags);
    printf(" ES ID:            0x%04x\n",   esds->esid);
    printf(" Priority:         0x%02x\n",   esds->stream_priority);
    printf(" objectTypeId:     %d\n",       esds->objectTypeId);
    printf(" streamType:       0x%02x\n",   esds->streamType);
    printf(" bufferSizeDB:     %d\n",       esds->bufferSizeDB);
    
    printf(" maxBitrate:       %d\n",       esds->maxBitrate);
    printf(" avgBitrate:       %d\n",       esds->avgBitrate);
    printf(" decoderConfigLen: %d\n",       esds->decoderConfigLen);
    printf(" decoderConfig:");
    for(i = 0; i < esds->decoderConfigLen; i++)
    {
        if(!(i % 16))
            printf("\n ");
        printf("%02x ", esds->decoderConfig[i]);
    }
    printf("\n");
}

//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
// TODO: refactor this so as not to need these ffmpeg routines.
// These are not exposed in ffmpeg's API so we dupe them here.
// AVC helper functions for muxers,
//  * Copyright (c) 2006 Baptiste Coudurier <baptiste.coudurier@smartjog.com>
// This is part of FFmpeg
//  * License as published by the Free Software Foundation; either
//  * version 2.1 of the License, or (at your option) any later version.
#define VDA_RB16(x)                          \
((((const uint8_t*)(x))[0] <<  8) |        \
((const uint8_t*)(x)) [1])

#define VDA_RB24(x)                          \
((((const uint8_t*)(x))[0] << 16) |        \
(((const uint8_t*)(x))[1] <<  8) |        \
((const uint8_t*)(x))[2])

#define VDA_RB32(x)                          \
((((const uint8_t*)(x))[0] << 24) |        \
(((const uint8_t*)(x))[1] << 16) |        \
(((const uint8_t*)(x))[2] <<  8) |        \
((const uint8_t*)(x))[3])

inline void VDA_WB32(uint8_t* pdata, int val)
{
    *pdata++ = val >> 24;
    *pdata++ = val >> 16;
    *pdata++ = val >> 8;
    *pdata++ = val;
}

static const uint8_t* avc_find_startcode_internal(const uint8_t* p, const uint8_t* end)
{
    const uint8_t* a = p + 4 - ((intptr_t)p & 3);
    
    for (end -= 3; p < a && p < end; p++)
    {
        if (p[0] == 0 && p[1] == 0 && p[2] == 1)
            return p;
    }
    
    for (end -= 3; p < end; p += 4)
    {
        uint32_t x = *(const uint32_t*)p;
        if ((x - 0x01010101) & (~x) & 0x80808080) // generic
        {
            if (p[1] == 0)
            {
                if (p[0] == 0 && p[2] == 1)
                    return p;
                if (p[2] == 0 && p[3] == 1)
                    return p + 1;
            }
            if (p[3] == 0)
            {
                if (p[2] == 0 && p[4] == 1)
                    return p + 2;
                if (p[4] == 0 && p[5] == 1)
                    return p + 3;
            }
        }
    }
    
    for (end += 3; p < end; p++)
    {
        if (p[0] == 0 && p[1] == 0 && p[2] == 1)
            return p;
    }
    
    return end + 3;
}

const uint8_t* avc_find_startcode(const uint8_t* p, const uint8_t* end)
{
    const uint8_t* out = avc_find_startcode_internal(p, end);
    if (p < out && out < end && !out[-1])
        out--;
    return out;
}

const int avc_parse_nal_units(AVIOContext* pb, const uint8_t* buf_in, int size)
{
    const uint8_t* p = buf_in;
    const uint8_t* end = p + size;
    const uint8_t* nal_start, *nal_end;
    
    size = 0;
    nal_start = avc_find_startcode(p, end);
    while (nal_start < end)
    {
        while (!*(nal_start++));
        nal_end = avc_find_startcode(nal_start, end);
        avio_wb32(pb, nal_end - nal_start);
        avio_write(pb, nal_start, nal_end - nal_start);
        size += 4 + nal_end - nal_start;
        nal_start = nal_end;
    }
    return size;
}

const int avc_parse_nal_units_buf(const uint8_t* buf_in, uint8_t** buf, int* size)
{
    AVIOContext* pb;
    int ret = avio_open_dyn_buf(&pb);
    if (ret < 0)
        return ret;
    
    avc_parse_nal_units(pb, buf_in, *size);
    
    av_freep(buf);
    *size = avio_close_dyn_buf(pb, buf);
    return 0;
}

/*
 * if extradata size is greater than 7, then have a valid quicktime
 * avcC atom header.
 *
 *      -: avcC atom header :-
 *  -----------------------------------
 *  1 byte  - version
 *  1 byte  - h.264 stream profile
 *  1 byte  - h.264 compatible profiles
 *  1 byte  - h.264 stream level
 *  6 bits  - reserved set to 63
 *  2 bits  - NAL length
 *            ( 0 - 1 byte; 1 - 2 bytes; 3 - 4 bytes)
 *  3 bit   - reserved
 *  5 bits  - number of SPS
 *  for (i=0; i < number of SPS; i++) {
 *      2 bytes - SPS length
 *      SPS length bytes - SPS NAL unit
 *  }
 *  1 byte  - number of PPS
 *  for (i=0; i < number of PPS; i++) {
 *      2 bytes - PPS length
 *      PPS length bytes - PPS NAL unit
 *  }
 
 how to detect the interlacing used on an existing stream:
 - progressive is signalled by setting
 frame_mbs_only_flag: 1 in the SPS.
 - interlaced is signalled by setting
 frame_mbs_only_flag: 0 in the SPS and
 field_pic_flag: 1 on all frames.
 - paff is signalled by setting
 frame_mbs_only_flag: 0 in the SPS and
 field_pic_flag: 1 on all frames that get interlaced and
 field_pic_flag: 0 on all frames that get progressive.
 - mbaff is signalled by setting
 frame_mbs_only_flag: 0 in the SPS and
 mb_adaptive_frame_field_flag: 1 in the SPS and
 field_pic_flag: 0 on the frames,
 (field_pic_flag: 1 would indicate a normal interlaced frame).
 */
const int isom_write_avcc(AVIOContext* pb, const uint8_t* data, int len)
{
    // extradata from bytestream h264, convert to avcC atom data for bitstream
    if (len > 6)
    {
        /* check for h264 start code */
        if (VDA_RB32(data) == 0x00000001 || VDA_RB24(data) == 0x000001)
        {
            uint8_t* buf = NULL, *end, *start;
            uint32_t sps_size = 0, pps_size = 0;
            uint8_t* sps = 0, *pps = 0;
            
            int ret = avc_parse_nal_units_buf(data, &buf, &len);
            if (ret < 0)
                return ret;
            start = buf;
            end = buf + len;
            
            /* look for sps and pps */
            while (buf < end)
            {
                unsigned int size;
                uint8_t nal_type;
                size = VDA_RB32(buf);
                nal_type = buf[4] & 0x1f;
                if (nal_type == 7) /* SPS */
                {
                    sps = buf + 4;
                    sps_size = size;
                    
                }
                else if (nal_type == 8) /* PPS */
                {
                    pps = buf + 4;
                    pps_size = size;
                    
                }
                buf += size + 4;
            }
            assert(sps);
            
            avio_w8(pb, 1); /* version */
            avio_w8(pb, sps[1]); /* profile */
            avio_w8(pb, sps[2]); /* profile compat */
            avio_w8(pb, sps[3]); /* level */
            avio_w8(pb, 0xff); /* 6 bits reserved (111111) + 2 bits nal size length - 1 (11) */
            avio_w8(pb, 0xe1); /* 3 bits reserved (111) + 5 bits number of sps (00001) */
            
            avio_wb16(pb, sps_size);
            avio_write(pb, sps, sps_size);
            if (pps)
            {
                avio_w8(pb, 1); /* number of pps */
                avio_wb16(pb, pps_size);
                avio_write(pb, pps, pps_size);
            }
            av_free(start);
        }
        else
        {
            avio_write(pb, data, len);
        }
    }
    return 0;
}

//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
// GStreamer h264 parser
// Copyright (C) 2005 Michal Benes <michal.benes@itonis.tv>
//           (C) 2008 Wim Taymans <wim.taymans@gmail.com>
// gsth264parse.c:
//  * License as published by the Free Software Foundation; either
//  * version 2.1 of the License, or (at your option) any later version.
typedef struct
{
    const uint8_t* data;
    const uint8_t* end;
    int head;
    uint64_t cache;
} nal_bitstream;

static void
nal_bs_init(nal_bitstream* bs, const uint8_t* data, size_t size)
{
    bs->data = data;
    bs->end  = data + size;
    bs->head = 0;
    // fill with something other than 0 to detect
    //  emulation prevention bytes
    bs->cache = 0xffffffff;
}

static uint32_t
nal_bs_read(nal_bitstream* bs, int n)
{
    uint32_t res = 0;
    int shift;
    
    if (n == 0)
        return res;
    
    // fill up the cache if we need to
    while (bs->head < n)
    {
        uint8_t a_byte;
        bool check_three_byte;
        
        check_three_byte = TRUE;
    next_byte:
        if (bs->data >= bs->end)
        {
            // we're at the end, can't produce more than head number of bits
            n = bs->head;
            break;
        }
        // get the byte, this can be an emulation_prevention_three_byte that we need
        // to ignore.
        a_byte = *bs->data++;
        if (check_three_byte && a_byte == 0x03 && ((bs->cache & 0xffff) == 0))
        {
            // next byte goes unconditionally to the cache, even if it's 0x03
            check_three_byte = FALSE;
            goto next_byte;
        }
        // shift bytes in cache, moving the head bits of the cache left
        bs->cache = (bs->cache << 8) | a_byte;
        bs->head += 8;
    }
    
    // bring the required bits down and truncate
    if ((shift = bs->head - n) > 0)
        res = bs->cache >> shift;
    else
        res = bs->cache;
    
    // mask out required bits
    if (n < 32)
        res &= (1 << n) - 1;
    
    bs->head = shift;
    
    return res;
}

static bool
nal_bs_eos(nal_bitstream* bs)
{
    return (bs->data >= bs->end) && (bs->head == 0);
}

// read unsigned Exp-Golomb code
static int
nal_bs_read_ue(nal_bitstream* bs)
{
    int i = 0;
    
    while (nal_bs_read(bs, 1) == 0 && !nal_bs_eos(bs) && i < 32)
        i++;
    
    return ((1 << i) - 1 + nal_bs_read(bs, i));
}


typedef struct
{
    int profile_idc;
    int level_idc;
    int sps_id;
    
    int chroma_format_idc;
    int separate_colour_plane_flag;
    int bit_depth_luma_minus8;
    int bit_depth_chroma_minus8;
    int qpprime_y_zero_transform_bypass_flag;
    int seq_scaling_matrix_present_flag;
    
    int log2_max_frame_num_minus4;
    int pic_order_cnt_type;
    int log2_max_pic_order_cnt_lsb_minus4;
    
    int max_num_ref_frames;
    int gaps_in_frame_num_value_allowed_flag;
    int pic_width_in_mbs_minus1;
    int pic_height_in_map_units_minus1;
    
    int frame_mbs_only_flag;
    int mb_adaptive_frame_field_flag;
    
    int direct_8x8_inference_flag;
    
    int frame_cropping_flag;
    int frame_crop_left_offset;
    int frame_crop_right_offset;
    int frame_crop_top_offset;
    int frame_crop_bottom_offset;
} sps_info_struct;

static void
parseh264_sps(uint8_t* sps, uint32_t sps_size,  int* level, int* profile, bool* interlaced, int32_t* max_ref_frames)
{
    nal_bitstream bs;
    sps_info_struct sps_info = {0};
    
    nal_bs_init(&bs, sps, sps_size);
    
    sps_info.profile_idc  = nal_bs_read(&bs, 8);
    nal_bs_read(&bs, 1);  // constraint_set0_flag
    nal_bs_read(&bs, 1);  // constraint_set1_flag
    nal_bs_read(&bs, 1);  // constraint_set2_flag
    nal_bs_read(&bs, 1);  // constraint_set3_flag
    nal_bs_read(&bs, 4);  // reserved
    sps_info.level_idc    = nal_bs_read(&bs, 8);
    sps_info.sps_id       = nal_bs_read_ue(&bs);
    
    if (sps_info.profile_idc == 100 ||
        sps_info.profile_idc == 110 ||
        sps_info.profile_idc == 122 ||
        sps_info.profile_idc == 244 ||
        sps_info.profile_idc == 44  ||
        sps_info.profile_idc == 83  ||
        sps_info.profile_idc == 86)
    {
        sps_info.chroma_format_idc                    = nal_bs_read_ue(&bs);
        if (sps_info.chroma_format_idc == 3)
            sps_info.separate_colour_plane_flag         = nal_bs_read(&bs, 1);
        sps_info.bit_depth_luma_minus8                = nal_bs_read_ue(&bs);
        sps_info.bit_depth_chroma_minus8              = nal_bs_read_ue(&bs);
        sps_info.qpprime_y_zero_transform_bypass_flag = nal_bs_read(&bs, 1);
        
        sps_info.seq_scaling_matrix_present_flag = nal_bs_read(&bs, 1);
        if (sps_info.seq_scaling_matrix_present_flag)
        {
            /* TODO: unfinished */
        }
    }
    sps_info.log2_max_frame_num_minus4 = nal_bs_read_ue(&bs);
    if (sps_info.log2_max_frame_num_minus4 > 12)
    {
        // must be between 0 and 12
        // don't early return here - the bits we are using (profile/level/interlaced/ref frames)
        // might still be valid - let the parser go on and pray.
        //return;
    }
    
    sps_info.pic_order_cnt_type = nal_bs_read_ue(&bs);
    if (sps_info.pic_order_cnt_type == 0)
    {
        sps_info.log2_max_pic_order_cnt_lsb_minus4 = nal_bs_read_ue(&bs);
    }
    else if (sps_info.pic_order_cnt_type == 1)
    {
        // TODO: unfinished
        /*
         delta_pic_order_always_zero_flag = gst_nal_bs_read (bs, 1);
         offset_for_non_ref_pic = gst_nal_bs_read_se (bs);
         offset_for_top_to_bottom_field = gst_nal_bs_read_se (bs);
         
         num_ref_frames_in_pic_order_cnt_cycle = gst_nal_bs_read_ue (bs);
         for( i = 0; i < num_ref_frames_in_pic_order_cnt_cycle; i++ )
         offset_for_ref_frame[i] = gst_nal_bs_read_se (bs);
         */
    }
    
    sps_info.max_num_ref_frames             = nal_bs_read_ue(&bs);
    sps_info.gaps_in_frame_num_value_allowed_flag = nal_bs_read(&bs, 1);
    sps_info.pic_width_in_mbs_minus1        = nal_bs_read_ue(&bs);
    sps_info.pic_height_in_map_units_minus1 = nal_bs_read_ue(&bs);
    
    sps_info.frame_mbs_only_flag            = nal_bs_read(&bs, 1);
    if (!sps_info.frame_mbs_only_flag)
        sps_info.mb_adaptive_frame_field_flag = nal_bs_read(&bs, 1);
    
    sps_info.direct_8x8_inference_flag      = nal_bs_read(&bs, 1);
    
    sps_info.frame_cropping_flag            = nal_bs_read(&bs, 1);
    if (sps_info.frame_cropping_flag)
    {
        sps_info.frame_crop_left_offset       = nal_bs_read_ue(&bs);
        sps_info.frame_crop_right_offset      = nal_bs_read_ue(&bs);
        sps_info.frame_crop_top_offset        = nal_bs_read_ue(&bs);
        sps_info.frame_crop_bottom_offset     = nal_bs_read_ue(&bs);
    }
    
    *level = sps_info.level_idc;
    *profile = sps_info.profile_idc;
    *interlaced = !sps_info.frame_mbs_only_flag;
    *max_ref_frames = sps_info.max_num_ref_frames;
}

bool validate_avcC_spc(uint8_t* extradata, uint32_t extrasize, int32_t* max_ref_frames, int* level, int* profile,avc_nul_head &avc_head)
{
    // check the avcC atom's sps for number of reference frames and
    // bail if interlaced, VDA does not handle interlaced h264.
    bool interlaced = true;
    
    uint8_t* spc = extradata + 6;
    uint32_t sps_size = VDA_RB16(spc);
    
    uint8_t nal_type;
    uint8_t nal_size;
    
    avc_head.sps_len = sps_size;
    avc_head.sps = (uint8_t *)malloc(avc_head.sps_len);
    memcpy(avc_head.sps ,spc + 2 ,avc_head.sps_len);
    
    uint8_t* pps = spc + sps_size + 2;
    if (*pps == 1)
    {
        while (*pps == 1)
        {
            nal_type = *(pps + 3) & 0x1f;
            if (nal_type == 8) // find out pps lable
            {
                avc_head.pps_len = VDA_RB16(pps + 1);
                avc_head.pps = (uint8_t *)malloc(avc_head.pps_len);
                memcpy(avc_head.pps,pps + 3 ,avc_head.pps_len);
                break;
            }
            else if (nal_type == 7) // find out sps lable
            {
                nal_size = VDA_RB16(pps + 1);
                pps += 3;
                pps += nal_size;
            }
        }
    }
    
    if (sps_size)
        parseh264_sps(spc + 3, sps_size - 1, level, profile, &interlaced, max_ref_frames);
    
    if (interlaced)
        return false;
    
    return true;
}

const int parse_avc_data(AVIOContext* pb, const uint8_t* data, int len,avc_nul_head *avc_head)
{
    long nal_size = 0;
    long nal_type = 0;
    const uint8_t* p = data;
    const uint8_t* end = p + len;
    const uint8_t* nal_start = p;
    const uint8_t* nal_end = NULL;
    const uint8_t* nal_cur = NULL;
    bool  bsegment = false;
    
    if (len > 4)
    {
        /* check for nal start code */
        while (p < end)
        {
            nal_size = VDA_RB32(p);
            if (nal_size > len || nal_size < 0)
                return -1;
            //nal_size = len;
            nal_start = p + 4;
            nal_cur = nal_start;
            nal_end = nal_start + nal_size;
            bsegment = false;
            
            if (!bsegment)
            {
                avio_wb32(pb, nal_size);
                avio_write(pb, nal_start ,nal_size);
                p += (nal_size + 4);
            }
            else
            {
                nal_size = nal_end - nal_start;
                if (nal_size > 0)
                {
                    avio_wb32(pb, nal_size);
                    avio_write(pb, nal_start ,nal_size);
                }
                p = nal_cur;
            }
        }
    }
    else
        return -1;
    
    return 0;
}

static void h264VTHD_flush(AVCodecContext *avctx);

void DisplayQueuePop(H264VTContext *vtc)
{
    if (!vtc->_display_queue || vtc->_queue_depth == 0)
        return;
    
    // pop the top frame off the queue
    pthread_mutex_lock(&vtc->_queue_mutex);
    frame_queue* top_frame = vtc->_display_queue;
    vtc->_display_queue = vtc->_display_queue->nextframe;
    vtc->_queue_depth--;
    pthread_mutex_unlock(&vtc->_queue_mutex);
    
    // and release it
    if (top_frame->pixel_buffer_ref)
        CVBufferRelease(top_frame->pixel_buffer_ref);
    free(top_frame);
}

void CreateVTSession(H264VTContext *vtc,int width, int height, CMFormatDescriptionRef fmt_desc)
{
    
    NSLog(@"CreateVTSession");
    VTDecompressionSessionRef vt_session = NULL;
    CFMutableDictionaryRef destinationPixelBufferAttributes;
    VTDecompressionOutputCallback outputCallback;
    OSStatus status;
    
    //2016.3.3 spy
    /*
     double scale = 0.0;
     
     // decoding, scaling and rendering above 1920 x 800 runs into
     // some bandwidth limit. detect and scale down to reduce
     // the bandwidth requirements.
     int width_clamp = 1280;
     if ((width * height) > (1920 * 800))
     width_clamp = 960;
     
     // for retina devices it should be safe [tm] to
     // loosen the clamp a bit to 1280 pixels width
     if (DeviceHasRetina(scale))
     {
     if (scale == 1.0f)
     width_clamp = 1280;
     else if (scale == 2.0f)
     width_clamp = 1920;
     else if (scale == 3.0f)
     width_clamp = 2560;
     }
     int new_width = CheckNP2(width);
     if (width != new_width)
     {
     // force picture width to power of two and scale up height
     // we do this because no GL_UNPACK_ROW_LENGTH in OpenGLES
     // and the CVPixelBufferPixel gets created using some
     // strange alignment when width is non-standard.
     double w_scaler = (double)new_width / width;
     width = new_width;
     height = height * w_scaler;
     }
     // scale output pictures down to 720p size for display
     if (width > width_clamp)
     {
     double w_scaler = (float)width_clamp / width;
     width = width_clamp;
     height = height * w_scaler;
     }
     */
    
    destinationPixelBufferAttributes = CFDictionaryCreateMutable(
                                                                 NULL, // CFAllocatorRef allocator
                                                                 0,    // CFIndex capacity
                                                                 &kCFTypeDictionaryKeyCallBacks,
                                                                 &kCFTypeDictionaryValueCallBacks);
    
    // The recommended pixel format choices are
    //  kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange or kCVPixelFormatType_32BGRA.
    //  figure out what we need.
    CFDictionarySetSInt32(destinationPixelBufferAttributes,
                          kCVPixelBufferPixelFormatTypeKey, kCVPixelFormatType_32BGRA);
    //CFDictionarySetSInt32(destinationPixelBufferAttributes,
    //                      kCVPixelBufferPixelFormatTypeKey, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
    
    CFDictionarySetSInt32(destinationPixelBufferAttributes,
                          kCVPixelBufferWidthKey, width);
    CFDictionarySetSInt32(destinationPixelBufferAttributes,
                          kCVPixelBufferHeightKey, height);
    
    CFDictionarySetValue(destinationPixelBufferAttributes,
                         kCVPixelBufferOpenGLCompatibilityKey, kCFBooleanFalse);
    
    outputCallback.callback = VTDecoderCallback;
    outputCallback.refcon = vtc;
    
    status = VTDecompressionSessionCreate(
                                          NULL, // CFAllocatorRef allocator
                                          fmt_desc,
                                          NULL, // CFTypeRef sessionOptions
                                          destinationPixelBufferAttributes,
                                          &outputCallback,
                                          &vt_session);
    if (status != noErr)
    {
        vtc->_vt_session = NULL;
    }
    else
    {
        //vtdec_session_dump_properties(vt_session);
        vtc->_vt_session = (void*)vt_session;
    }
    
    CFRelease(destinationPixelBufferAttributes);
}

void DestroyVTSession(H264VTContext *vtc)
{
    
    NSLog(@"DestroyVTSession");
    if (vtc->_vt_session)
    {
        VTDecompressionSessionInvalidate((VTDecompressionSessionRef)vtc->_vt_session);
        CFRelease((VTDecompressionSessionRef)vtc->_vt_session);
        vtc->_vt_session = NULL;
    }
}

void ResetVTSession(H264VTContext *vtc)
{
    
    //NSLog(@"ResetVTSession");
    if (!vtc)
        return;
    
    VTDecompressionSessionWaitForAsynchronousFrames(vtc->_vt_session);
    
    while (vtc->_queue_depth)
        DisplayQueuePop(vtc);
    
    vtc->_sort_time_offset = (CurrentHostCounter() * 1000.0) / CurrentHostFrequency();
}

static inline void ResetPktBuffer(H264VTContext *vtc) {
    
    //NSLog(@"ResetPktBuffer");
    for (int i = 0 ; i < vtc->_buffer_deep; i++) {
        av_packet_unref(&vtc->_buffer_packet[i]);
    }
    vtc->_buffer_deep = 0;
    vtc->_buffer_keypos = 0;
    memset(vtc->_buffer_packet, 0, sizeof(vtc->_buffer_packet));
}

static inline void DuplicatePkt(H264VTContext *vtc, const AVPacket* pkt) {
    
    //NSLog(@"DuplicatePkt");
    if (vtc->_buffer_deep >= MAX_PKT_QUEUE_DEEP) {
        vtc->_buffer_deep = 0;
    }
    
    if (pkt->flags & AV_PKT_FLAG_KEY)
    {
        if (vtc->_buffer_keypos == -1)
            vtc->_buffer_keypos = vtc->_buffer_deep;
        else
        {
            ResetPktBuffer(vtc);
            vtc->_buffer_keypos = vtc->_buffer_deep;
        }
    }
    
    AVPacket* avpkt = &vtc->_buffer_packet[vtc->_buffer_deep];
    av_copy_packet(avpkt, pkt);
    
    vtc->_buffer_deep++;
}

static inline void FlushBufferPkt(H264VTContext *vtc) {
    
    NSLog(@"FlushBufferPkt");
    int keypos = vtc->_buffer_keypos;
    
    while (keypos <vtc->_buffer_deep)
    {
        uint8_t* pData  =  vtc->_buffer_packet[keypos].data;
        int iSize       =  vtc->_buffer_packet[keypos].size;
        int64_t dts     =  vtc->_buffer_packet[keypos].dts;
        int64_t pts     =  vtc->_buffer_packet[keypos].pts;
        keypos++;
        
        if (pData)
        {
            OSStatus status;
            double sort_time;
            uint32_t decoderFlags = 0;
            CFDictionaryRef frameInfo = NULL;;
            CMSampleBufferRef sampleBuff = NULL;
            AVIOContext* pb = NULL;
            int demux_size = 0;
            uint8_t* demux_buff = NULL;
            
            if (vtc->_convert_bytestream)
            {
                // convert demuxer packet from bytestream (AnnexB) to bitstream
                if (avio_open_dyn_buf(&pb) < 0)
                {
                    break;
                }
                
                demux_size = avc_parse_nal_units(pb, pData, iSize);
                demux_size = avio_close_dyn_buf(pb, &demux_buff);
                sampleBuff = CreateSampleBufferFrom(vtc->_fmt_desc, demux_buff, demux_size);
            }
            else if (vtc->_convert_3byteTo4byteNALSize)
            {
                // convert demuxer packet from 3 byte NAL sizes to 4 byte
                if (avio_open_dyn_buf(&pb) < 0)
                {
                    break;
                }
                
                uint32_t nal_size;
                uint8_t* end = pData + iSize;
                uint8_t* nal_start = pData;
                while (nal_start < end)
                {
                    nal_size = VDA_RB24(nal_start);
                    avio_wb32(pb, nal_size);
                    nal_start += 3;
                    avio_write(pb, nal_start, nal_size);
                    nal_start += nal_size;
                }
                
                demux_size = avio_close_dyn_buf(pb, &demux_buff);
                sampleBuff = CreateSampleBufferFrom(vtc->_fmt_desc, demux_buff, demux_size);
            }
            else
            {
                if (vtc->_h264decoder)
                {
                    AVIOContext* pb;
                    if (avio_open_dyn_buf(&pb) < 0)
                    {
                        break;
                    }
                    
                    if (parse_avc_data(pb, pData, iSize,&vtc->_avcheadinfo) < 0)
                    {
                        demux_buff = NULL;
                        demux_size = avio_close_dyn_buf(pb, &demux_buff);
                        if (demux_size)
                            av_free(demux_buff);
                        continue;;
                    }
                    
                    demux_buff = NULL;
                    demux_size = avio_close_dyn_buf(pb, &demux_buff);
                    
                    if (demux_buff)
                        sampleBuff = CreateSampleBufferFrom(vtc->_fmt_desc, demux_buff, demux_size);
                }
                else
                {
                    sampleBuff = CreateSampleBufferFrom(vtc->_fmt_desc, pData, iSize);
                }
            }
            
            if (!sampleBuff)
            {
                if (demux_size)
                    av_free(demux_buff);
                
                break;
            }
            
            sort_time = (CurrentHostCounter() * 1000.0) / CurrentHostFrequency();
            frameInfo = CreateDictionaryWithDisplayTime(sort_time - vtc->_sort_time_offset, dts, pts);
            
            CFRetain(frameInfo);
            status = VTDecompressionSessionDecodeFrame(vtc->_vt_session, sampleBuff, decoderFlags, frameInfo, 0);
            if (status != kVTDecoderNoErr)
            {
                FreeFrameDisplayTimeFromDictionary(frameInfo);
                CFRelease(sampleBuff);
                
                if (demux_size)
                    av_free(demux_buff);
                break;
            }
            
            // wait for decoding to finish
            status = VTDecompressionSessionWaitForAsynchronousFrames(vtc->_vt_session);
            if (status != kVTDecoderNoErr)
            {
                FreeFrameDisplayTimeFromDictionary(frameInfo);
                CFRelease(sampleBuff);
                if (demux_size)
                    av_free(demux_buff);
                break;
            }
            
            FreeFrameDisplayTimeFromDictionary(frameInfo);
            CFRelease(sampleBuff);
            if (demux_size)
                av_free(demux_buff);
        }
        else
            break;
        
        // TODO: queue depth is related to the number of reference frames in encoded h.264.
        // so we need to buffer until we get N ref frames + 1.
        if (vtc->_queue_depth < vtc->_max_ref_frames)
        {
            
        }
        else
        {
            pthread_mutex_lock(&vtc->_queue_mutex);
            if (vtc->_display_queue->pixel_buffer_ref)
                CVBufferRelease(vtc->_display_queue->pixel_buffer_ref);
            vtc->_display_queue->pixel_buffer_ref = NULL;
            pthread_mutex_unlock(&vtc->_queue_mutex);
            
            // now we can pop the top frame
            DisplayQueuePop(vtc);
        }
    }
}

void VTDecoderCallback(
                       void *refCon,
                       CFDictionaryRef    frameInfo,
                       OSStatus status,
                       UInt32 infoFlags,
                       CVImageBufferRef imageBuffer,
                       CMTime presentationTimeStamp,
                       CMTime presentationDuration )
{
    // This is an sync callback due to VTDecompressionSessionWaitForAsynchronousFrames
    H264VTContext* vtc = (H264VTContext *)refCon;
    
    if (status != kVTDecoderNoErr)
    {
        return;
    }
    if (imageBuffer == NULL)
    {
        return;
    }
    
    OSType format_type = CVPixelBufferGetPixelFormatType(imageBuffer);
    //if (format_type != kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) //kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange kCVPixelFormatType_32BGRA
    if (format_type != kCVPixelFormatType_32BGRA) //kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange kCVPixelFormatType_32BGRA
    {
        
        return;
    }
    if (kVTDecodeInfo_FrameDropped & infoFlags)
    {
        return;
    }
    
    // allocate a new frame and populate it with some information.
    // this pointer to a frame_queue type keeps track of the newest decompressed frame
    // and is then inserted into a linked list of frame pointers depending on the display time
    // parsed out of the bitstream and stored in the frameInfo dictionary by the client
    
    
    frame_queue* newFrame = (frame_queue*)calloc(sizeof(frame_queue), 1);
    newFrame->nextframe = NULL;
    if (CVPixelBufferIsPlanar(imageBuffer))
    {
        newFrame->width  = (int)CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
        newFrame->height = (int)CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
    }
    else
    {
        newFrame->width  = (int)CVPixelBufferGetWidth(imageBuffer);
        newFrame->height = (int)CVPixelBufferGetHeight(imageBuffer);
    }
    newFrame->pixel_buffer_format = format_type;
    newFrame->pixel_buffer_ref = CVBufferRetain(imageBuffer);
    
    GetFrameDisplayTimeFromDictionary(frameInfo, newFrame);
    
    // if both dts or pts are good we use those, else use decoder insert time for frame sort
    if ((newFrame->pts != AV_NOPTS_VALUE) || (newFrame->dts != AV_NOPTS_VALUE))
    {
        // if pts is borked (stupid avi's), use dts for frame sort
        if (newFrame->pts == AV_NOPTS_VALUE)
            newFrame->sort_time = newFrame->dts;
        else
            newFrame->sort_time = newFrame->pts;
    }
    
    // since the frames we get may be in decode order rather than presentation order
    // our hypothetical callback places them in a queue of frames which will
    // hold them in display order for display on another thread
    pthread_mutex_lock(&vtc->_queue_mutex);
    //
    frame_queue* queueWalker = vtc->_display_queue;
    if (!queueWalker || (newFrame->sort_time < queueWalker->sort_time))
    {
        // we have an empty queue, or this frame earlier than the current queue head.
        newFrame->nextframe = queueWalker;
        vtc->_display_queue = newFrame;
    }
    else
    {
        // walk the queue and insert this frame where it belongs in display order.
        bool frameInserted = false;
        frame_queue* nextFrame = NULL;
        //
        while (!frameInserted)
        {
            nextFrame = queueWalker->nextframe;
            if (!nextFrame || (newFrame->sort_time < nextFrame->sort_time))
            {
                // if the next frame is the tail of the queue, or our new frame is earlier.
                newFrame->nextframe = nextFrame;
                queueWalker->nextframe = newFrame;
                frameInserted = true;
            }
            queueWalker = nextFrame;
        }
    }
    vtc->_queue_depth++;
    
    pthread_mutex_unlock(&vtc->_queue_mutex);
}

static int h264VTHD_decode_init(AVCodecContext *avctx)
{
    
    NSLog(@"h264VTHD_decode_init");
    H264VTContext *vtc = (H264VTContext *)avctx->priv_data;
    if (!vtc)
        return -1;
    
    memset(vtc,0,sizeof(H264VTContext));
    if (avctx->codec_id != AV_CODEC_ID_H264 && avctx->codec_id != AV_CODEC_ID_MPEG4)
        return -1;
    
    if (avctx->width == 0 || avctx->height == 0)
        return -1;
    
    if (avctx->extradata_size < 7 || avctx->extradata == NULL)
        return -1;
    
    vtc->_queue_depth = 0;
    vtc->_display_queue = NULL;
    vtc->_max_ref_frames = 4;
    vtc->_sort_time_offset = 0.0f;
    
    pthread_mutex_init(&vtc->_queue_mutex, NULL);
    
    vtc->_width  = avctx->width;
    vtc->_height = avctx->height;
    
    unsigned int extrasize = avctx->extradata_size; // extra data for codec to use
    uint8_t* extradata = (uint8_t*)avctx->extradata; // size of extra data
    
    if (avctx->codec_id == AV_CODEC_ID_H264)
    {
        int level  = avctx->profile;
        int profile = avctx->level;
        
        int spsLevel = level;
        int spsProfile = profile;
        
        if (extradata[0] == 1)
        {
            // check for interlaced and get number of ref frames
            if (!validate_avcC_spc(extradata, extrasize, &vtc->_max_ref_frames, &spsLevel, &spsProfile,vtc->_avcheadinfo))
                return -1;
            
            // overwrite level and profile from the hints
            // if we got something more valid from the extradata
            if (level == 0 && spsLevel > 0)
                level = spsLevel;
            
            if (profile == 0 && spsProfile > 0)
                profile = spsProfile;
            
            // we need to check this early, CreateFormatDescriptionFromCodecData will silently fail
            // with a bogus m_fmt_desc returned that crashes on CFRelease.
            if (profile == FF_PROFILE_H264_MAIN && level == 32 && vtc->_max_ref_frames > 4)
            {
                // Main@L3.2, VTB cannot handle greater than 4 ref frames (ie. flash video)
                return -1;
            }
            
            if (extradata[4] == 0xFE)
            {
                // video content is from some silly encoder that think 3 byte NAL sizes
                // are valid, setup to convert 3 byte NAL sizes to 4 byte.
                extradata[4] = 0xFF;
                vtc->_convert_3byteTo4byteNALSize = true;
            }
            // valid avcC atom data always starts with the value 1 (version)
            vtc->_fmt_desc = CreateFormatDescriptionFromCodecData(
                                                                  kVTFormatH264, vtc->_width, vtc->_height, extradata, extrasize, 'avcC',&vtc->_avcheadinfo); //&m_avcheadinfo
        }
        else
        {
            if ((extradata[0] == 0 && extradata[1] == 0 && extradata[2] == 0 && extradata[3] == 1) ||
                (extradata[0] == 0 && extradata[1] == 0 && extradata[2] == 1))
            {
                // video content is from x264 or from bytestream h264 (AnnexB format)
                // NAL reformating to bitstream format required
                
                AVIOContext* pb;
                if (avio_open_dyn_buf(&pb) < 0)
                    return false;
                
                vtc->_convert_bytestream = true;
                // create a valid avcC atom data from ffmpeg's extradata
                isom_write_avcc(pb, extradata, extrasize);
                // unhook from ffmpeg's extradata
                extradata = NULL;
                // extract the avcC atom data into extradata getting size into extrasize
                extrasize = avio_close_dyn_buf(pb, &extradata);
                
                // check for interlaced and get number of ref frames
                if (!validate_avcC_spc(extradata, extrasize, &vtc->_max_ref_frames, &spsLevel, &spsProfile,vtc->_avcheadinfo))
                {
                    av_free(extradata);
                    return -1;
                }
                
                // overwrite level and profile from the hints
                // if we got something more valid from the extradata
                if (level == 0 && spsLevel > 0)
                    level = spsLevel;
                
                if (profile == 0 && spsProfile > 0)
                    profile = spsProfile;
                
                // we need to check this early, CreateFormatDescriptionFromCodecData will silently fail
                // with a bogus m_fmt_desc returned that crashes on CFRelease.
                if (profile == FF_PROFILE_H264_MAIN && level == 32 && vtc->_max_ref_frames > 4)
                {
                    // Main@L3.2, VTB cannot handle greater than 4 ref frames (ie. flash video)
                    av_free(extradata);
                    return -1;
                }
                
                // CFDataCreate makes a copy of extradata contents
                vtc->_fmt_desc = CreateFormatDescriptionFromCodecData(
                                                                      kVTFormatH264, vtc->_width, vtc->_height, extradata, extrasize, 'avcC',&vtc->_avcheadinfo);
                
                // done with the new converted extradata, we MUST free using av_free
                av_free(extradata);
            }
            else
            {
                return -1;
            }
        }
        
        vtc->_h264decoder = true;
    }
    else if (avctx->codec_id == AV_CODEC_ID_MPEG4)
    {
#if 0
        if (extrasize)
        {
            AVIOContext *pb;
            quicktime_esds_t *esds;
            
            if (avio_open_dyn_buf(&pb) < 0)
                return false;
            
            esds = quicktime_set_esds(extradata, extrasize);
            quicktime_write_esds(pb, esds);
            
            // unhook from ffmpeg's extradata
            extradata = NULL;
            // extract the esds atom decoderConfig from extradata
            extrasize = avio_close_dyn_buf(pb, &extradata);
            free(esds->decoderConfig);
            free(esds);
            
            vtc->_fmt_desc = CreateFormatDescriptionFromCodecData(
                                                                  kVTFormatMPEG4Video, vtc->_width, vtc->_height, extradata, extrasize, 'esds');
            
            // done with the converted extradata, we MUST free using av_free
            av_free(extradata);
        }
        else
        {
            vtc->_fmt_desc = CreateFormatDescription(kVTFormatMPEG4Video, vtc->_width, vtc->_height);
        }
        
        vtc->_h264decoder = false;
#else
        return -1;
#endif
    }
    
    if (vtc->_fmt_desc == NULL)
    {
        return -1;
    }
    
    CreateVTSession(vtc,vtc->_width, vtc->_height, vtc->_fmt_desc);
    if (vtc->_vt_session == NULL)
    {
        if (vtc->_fmt_desc)
        {
            CFRelease(vtc->_fmt_desc);
            vtc->_fmt_desc = NULL;
        }
        return -1;
    }
    
    if (vtc->_max_ref_frames == 0)
        vtc->_max_ref_frames = 2;
    
    //vtc->_max_ref_frames = std::min(vtc->_max_ref_frames, 5);
    vtc->_sort_time_offset = (CurrentHostCounter() * 1000.0) / CurrentHostFrequency();
    
    ResetPktBuffer(vtc);
    vtc->_buffer_keypos = -1;
    return 0;
}

static int h264VTHD_decode_frame(AVCodecContext *avctx, void *data,
                                 int *got_frame, AVPacket *avpkt)
{
    //NSLog(@"h264VTHD_decode_frame");
    H264VTContext *vtc = (H264VTContext *)avctx->priv_data;
    if (!vtc)
        return -1;
    
    uint8_t* pData  = avpkt->data;
    int iSize       = avpkt->size;
    int64_t dts     = avpkt->dts;
    int64_t pts     = avpkt->pts;
    int nret = iSize;
    AVFrame *pict   = (AVFrame *)data;
    
    if (pData)
    {
        OSStatus status;
        double sort_time;
        uint32_t decoderFlags = 0;
        CFDictionaryRef frameInfo = NULL;;
        CMSampleBufferRef sampleBuff = NULL;
        AVIOContext* pb = NULL;
        int demux_size = 0;
        uint8_t* demux_buff = NULL;
        
        if (vtc->_convert_bytestream)
        {
            // convert demuxer packet from bytestream (AnnexB) to bitstream
            if (avio_open_dyn_buf(&pb) < 0)
            {
                return -1;
            }
            
            demux_size = avc_parse_nal_units(pb, pData, iSize);
            demux_size = avio_close_dyn_buf(pb, &demux_buff);
            sampleBuff = CreateSampleBufferFrom(vtc->_fmt_desc, demux_buff, demux_size);
        }
        else if (vtc->_convert_3byteTo4byteNALSize)
        {
            // convert demuxer packet from 3 byte NAL sizes to 4 byte
            if (avio_open_dyn_buf(&pb) < 0)
            {
                return -1;
            }
            
            uint32_t nal_size;
            uint8_t* end = pData + iSize;
            uint8_t* nal_start = pData;
            while (nal_start < end)
            {
                nal_size = VDA_RB24(nal_start);
                avio_wb32(pb, nal_size);
                nal_start += 3;
                avio_write(pb, nal_start, nal_size);
                nal_start += nal_size;
            }
            
            demux_size = avio_close_dyn_buf(pb, &demux_buff);
            sampleBuff = CreateSampleBufferFrom(vtc->_fmt_desc, demux_buff, demux_size);
        }
        else
        {
            if (vtc->_h264decoder)
            {
                AVIOContext* pb;
                if (avio_open_dyn_buf(&pb) < 0)
                {
                    return -1;
                }
                
                if (parse_avc_data(pb, pData, iSize,&vtc->_avcheadinfo) < 0)
                {
                    demux_buff = NULL;
                    demux_size = avio_close_dyn_buf(pb, &demux_buff);
                    if (demux_size)
                        av_free(demux_buff);
                    return -1;
                }
                
                demux_buff = NULL;
                demux_size = avio_close_dyn_buf(pb, &demux_buff);
                
                if (demux_buff)
                    sampleBuff = CreateSampleBufferFrom(vtc->_fmt_desc, demux_buff, demux_size);
            }
            else
            {
                sampleBuff = CreateSampleBufferFrom(vtc->_fmt_desc, pData, iSize);
            }
        }
        
        if (!sampleBuff)
        {
            if (demux_size)
                av_free(demux_buff);
            return -1;
        }
        
        sort_time = (CurrentHostCounter() * 1000.0) / CurrentHostFrequency();
        frameInfo = CreateDictionaryWithDisplayTime(sort_time - vtc->_sort_time_offset, dts, pts);
        
        
        //if (m_DropPictures)
        //{
        //    decoderFlags = kVTDecoderDecodeFlags_DontEmitFrame;
        //}
        
        // submit for decoding
        //m_boutput = boutput;
        
        CFRetain(frameInfo);
    redecoding:
        status = VTDecompressionSessionDecodeFrame(vtc->_vt_session, sampleBuff, decoderFlags, frameInfo, 0);
        if (status != kVTDecoderNoErr)
        {
            if (status == kVTInvalidSessionErr)
            {
                DestroyVTSession(vtc);
                CreateVTSession(vtc,vtc->_width,vtc->_height,vtc->_fmt_desc);
                FlushBufferPkt(vtc);
                
                goto redecoding;
            }
            else{
                FreeFrameDisplayTimeFromDictionary(frameInfo);
                CFRelease(sampleBuff);
                
                if (demux_size)
                    av_free(demux_buff);
                return AVERROR_INVALIDDATA;
            }
            // VTDecompressionSessionDecodeFrame returned 8969 (codecBadDataErr)
            // VTDecompressionSessionDecodeFrame returned -12350
            // VTDecompressionSessionDecodeFrame returned -12902
            // VTDecompressionSessionDecodeFrame returned -12911
        }
        
        // wait for decoding to finish
        status = VTDecompressionSessionWaitForAsynchronousFrames(vtc->_vt_session);
        if (status != kVTDecoderNoErr)
        {
            FreeFrameDisplayTimeFromDictionary(frameInfo);
            CFRelease(sampleBuff);
            if (demux_size)
                av_free(demux_buff);
            return AVERROR_INVALIDDATA;
        }
        
        FreeFrameDisplayTimeFromDictionary(frameInfo);
        CFRelease(sampleBuff);
        if (demux_size)
            av_free(demux_buff);
    }
    
    // TODO: queue depth is related to the number of reference frames in encoded h.264.
    // so we need to buffer until we get N ref frames + 1.
    if (vtc->_queue_depth < vtc->_max_ref_frames)
    {
        *got_frame = 0;
        pict->data[0] = NULL;
        DuplicatePkt(vtc, avpkt);
    }
    else
    {
        
        pthread_mutex_lock(&vtc->_queue_mutex);
        pict->data[0] = (uint8_t *)vtc->_display_queue->pixel_buffer_ref;
        vtc->_display_queue->pixel_buffer_ref = NULL;
        pthread_mutex_unlock(&vtc->_queue_mutex);
        
        // now we can pop the top frame
        DisplayQueuePop(vtc);
        *got_frame = 1;
        DuplicatePkt(vtc, avpkt);
    }
    return nret;
}

static int h264VTHD_decode_end(AVCodecContext *avctx)
{
    
    NSLog(@"h264VTHD_decode_end");
    H264VTContext *vtc = (H264VTContext *)avctx->priv_data;
    if (!vtc)
        return -1;
    
    DestroyVTSession(vtc);
    ResetPktBuffer(vtc);
    
    if (vtc->_avcheadinfo.sps_len && vtc->_avcheadinfo.sps)
    {
        free(vtc->_avcheadinfo.sps);
        vtc->_avcheadinfo.sps  = NULL;
    }
    if (vtc->_avcheadinfo.pps_len && vtc->_avcheadinfo.pps)
    {
        free(vtc->_avcheadinfo.pps);
        vtc->_avcheadinfo.pps = NULL;
    }
    
    if (vtc->_fmt_desc)
    {
        CFRelease(vtc->_fmt_desc);
        vtc->_fmt_desc = NULL;
    }
    
    while (vtc->_queue_depth)
        DisplayQueuePop(vtc);
    pthread_mutex_destroy(&vtc->_queue_mutex);
    return 0;
}

/* forget old pics after a seek */
void h264VTHD_flush(AVCodecContext *avctx)
{
    
    //NSLog(@"h264VTHD_flush");
    H264VTContext *vtc = (H264VTContext *)avctx->priv_data;
    if (!vtc)
        return;
    
    ResetVTSession(vtc);
    ResetPktBuffer(vtc);
    return;
}

static const AVProfile profiles[] = {
    { FF_PROFILE_H264_BASELINE,             "Baseline"              },
    { FF_PROFILE_H264_CONSTRAINED_BASELINE, "Constrained Baseline"  },
    { FF_PROFILE_H264_MAIN,                 "Main"                  },
    { FF_PROFILE_H264_EXTENDED,             "Extended"              },
    { FF_PROFILE_H264_HIGH,                 "High"                  },
    { FF_PROFILE_H264_HIGH_10,              "High 10"               },
    { FF_PROFILE_H264_HIGH_10_INTRA,        "High 10 Intra"         },
    { FF_PROFILE_H264_HIGH_422,             "High 4:2:2"            },
    { FF_PROFILE_H264_HIGH_422_INTRA,       "High 4:2:2 Intra"      },
    { FF_PROFILE_H264_HIGH_444,             "High 4:4:4"            },
    { FF_PROFILE_H264_HIGH_444_PREDICTIVE,  "High 4:4:4 Predictive" },
    { FF_PROFILE_H264_HIGH_444_INTRA,       "High 4:4:4 Intra"      },
    { FF_PROFILE_H264_CAVLC_444,            "CAVLC 4:4:4"           },
    { FF_PROFILE_UNKNOWN },
};

AVCodec ff_h264VTHD_decoder = {
    .name                  = "h264VTHD",
    .long_name             = "H.264 Video Toolbox Hardware Decoder",
    .type                  = AVMEDIA_TYPE_VIDEO,
    .id                    = AV_CODEC_ID_H264,
    .priv_data_size        = sizeof(H264VTContext),
    .init                  = h264VTHD_decode_init,
    .close                 = h264VTHD_decode_end,
    .decode                = h264VTHD_decode_frame,
    .capabilities          = /*CODEC_CAP_DRAW_HORIZ_BAND |*/ CODEC_CAP_DR1 |CODEC_CAP_DELAY,
    .flush                 = h264VTHD_flush,
    .init_thread_copy      = NULL,
    .update_thread_context = NULL,
    .profiles              = profiles,
    .priv_class            = NULL,
};

AVCodec ff_mpeg4VTHD_decoder = {
    .name                  = "h264VTHD",
    .long_name             = "H.264 Video Toolbox Hardware Decoder",
    .type                  = AVMEDIA_TYPE_VIDEO,
    .id                    = AV_CODEC_ID_MPEG4,
    .priv_data_size        = sizeof(H264VTContext),
    .init                  = h264VTHD_decode_init,
    .close                 = h264VTHD_decode_end,
    .decode                = h264VTHD_decode_frame,
    .capabilities          = /*CODEC_CAP_DRAW_HORIZ_BAND |*/ CODEC_CAP_DR1 |CODEC_CAP_DELAY,
    .flush                 = h264VTHD_flush,
    .init_thread_copy      = NULL,
    .update_thread_context = NULL,
    .profiles              = profiles,
    .priv_class            = NULL,
};
