//
//  KxMovieDecoder_douyin.m
//  kxmovie
//
//  Created by Kolyvan on 15.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#ifdef FOR_DOUYIN

#import "KxMovieDecoder_douyin.h"
#import <UIKit/UIKit.h>
#import <Accelerate/Accelerate.h>
#import <CoreMedia/CoreMedia.h>
#import <VideoToolbox/VideoToolbox.h>

#ifdef __cplusplus
extern "C" {
#endif

#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/pixdesc.h"

#ifdef __cplusplus
}
#endif

#include "h264_iOS8VTHD.h"
#import "KxAudioManager.h"
#import "KxLogger.h"

#define USE_MY_H264_DECODER

#ifdef USE_MY_H264_DECODER
extern AVCodec ff_h264HD_decoder;
extern AVCodec ff_h264VTHD_decoder;
extern AVCodec ff_mpeg4VTHD_decoder; //write by spy 2016.3.28
#endif

//#define USE_iOS8HW_DECODING

////////////////////////////////////////////////////////////////////////////////
NSString * kxmovieErrorDomain = @"ru.kolyvan.kxmovie";
static void FFLog(void* context, int level, const char* format, va_list args);

static NSError * kxmovieError (NSInteger code, id info)
{
    NSDictionary *userInfo = nil;
    
    if ([info isKindOfClass: [NSDictionary class]]) {
        
        userInfo = info;
        
    } else if ([info isKindOfClass: [NSString class]]) {
        
        userInfo = @{ NSLocalizedDescriptionKey : info };
    }
    
    return [NSError errorWithDomain:kxmovieErrorDomain
                               code:code
                           userInfo:userInfo];
}

static NSString * errorMessage (kxMovieError errorCode)
{
    switch (errorCode) {
        case kxMovieErrorNone:
            return @"";
            
        case kxMovieErrorOpenFile:
            return NSLocalizedString(@"Unable to open file", nil);
            
        case kxMovieErrorStreamInfoNotFound:
            return NSLocalizedString(@"Unable to find stream information", nil);
            
        case kxMovieErrorStreamNotFound:
            return NSLocalizedString(@"Unable to find stream", nil);
            
        case kxMovieErrorCodecNotFound:
            return NSLocalizedString(@"Unable to find codec", nil);
            
        case kxMovieErrorOpenCodec:
            return NSLocalizedString(@"Unable to open codec", nil);
            
        case kxMovieErrorAllocateFrame:
            return NSLocalizedString(@"Unable to allocate frame", nil);
            
        case kxMovieErroSetupScaler:
            return NSLocalizedString(@"Unable to setup scaler", nil);
            
        case kxMovieErroReSampler:
            return NSLocalizedString(@"Unable to setup resampler", nil);
            
        case kxMovieErroUnsupported:
            return NSLocalizedString(@"The ability is not supported", nil);
    }
}

////////////////////////////////////////////////////////////////////////////////

static BOOL audioCodecIsSupported(AVCodecContext *audio)
{
    if (audio->sample_fmt == AV_SAMPLE_FMT_S16) {
        
        id<KxAudioManager> audioManager = [KxAudioManager audioManager];
        return  (int)audioManager.samplingRate == audio->sample_rate &&
        audioManager.numOutputChannels == audio->channels;
    }
    return NO;
}

#ifdef DEBUG
static void fillSignal(SInt16 *outData,  UInt32 numFrames, UInt32 numChannels)
{
    static float phase = 0.0;
    
    for (int i=0; i < numFrames; ++i)
    {
        for (int iChannel = 0; iChannel < numChannels; ++iChannel)
        {
            float theta = phase * M_PI * 2;
            outData[i*numChannels + iChannel] = sin(theta) * (float)INT16_MAX;
        }
        phase += 1.0 / (44100 / 440.0);
        if (phase > 1.0) phase = -1;
    }
}

static void fillSignalF(float *outData,  UInt32 numFrames, UInt32 numChannels)
{
    static float phase = 0.0;
    
    for (int i=0; i < numFrames; ++i)
    {
        for (int iChannel = 0; iChannel < numChannels; ++iChannel)
        {
            float theta = phase * M_PI * 2;
            outData[i*numChannels + iChannel] = sin(theta);
        }
        phase += 1.0 / (44100 / 440.0);
        if (phase > 1.0) phase = -1;
    }
}

static void testConvertYUV420pToRGB(AVFrame * frame, uint8_t *outbuf, int linesize, int height)
{
    const int linesizeY = frame->linesize[0];
    const int linesizeU = frame->linesize[1];
    const int linesizeV = frame->linesize[2];
    
    assert(height == frame->height);
    assert(linesize  <= linesizeY * 3);
    assert(linesizeY == linesizeU * 2);
    assert(linesizeY == linesizeV * 2);
    
    uint8_t *pY = frame->data[0];
    uint8_t *pU = frame->data[1];
    uint8_t *pV = frame->data[2];
    
    const int width = linesize / 3;
    
    for (int y = 0; y < height; y += 2) {
        
        uint8_t *dst1 = outbuf + y       * linesize;
        uint8_t *dst2 = outbuf + (y + 1) * linesize;
        
        uint8_t *py1  = pY  +  y       * linesizeY;
        uint8_t *py2  = py1 +            linesizeY;
        uint8_t *pu   = pU  + (y >> 1) * linesizeU;
        uint8_t *pv   = pV  + (y >> 1) * linesizeV;
        
        for (int i = 0; i < width; i += 2) {
            
            int Y1 = py1[i];
            int Y2 = py2[i];
            int Y3 = py1[i+1];
            int Y4 = py2[i+1];
            
            int U = pu[(i >> 1)] - 128;
            int V = pv[(i >> 1)] - 128;
            
            int dr = (int)(             1.402f * V);
            int dg = (int)(0.344f * U + 0.714f * V);
            int db = (int)(1.772f * U);
            
            int r1 = Y1 + dr;
            int g1 = Y1 - dg;
            int b1 = Y1 + db;
            
            int r2 = Y2 + dr;
            int g2 = Y2 - dg;
            int b2 = Y2 + db;
            
            int r3 = Y3 + dr;
            int g3 = Y3 - dg;
            int b3 = Y3 + db;
            
            int r4 = Y4 + dr;
            int g4 = Y4 - dg;
            int b4 = Y4 + db;
            
            r1 = r1 > 255 ? 255 : r1 < 0 ? 0 : r1;
            g1 = g1 > 255 ? 255 : g1 < 0 ? 0 : g1;
            b1 = b1 > 255 ? 255 : b1 < 0 ? 0 : b1;
            
            r2 = r2 > 255 ? 255 : r2 < 0 ? 0 : r2;
            g2 = g2 > 255 ? 255 : g2 < 0 ? 0 : g2;
            b2 = b2 > 255 ? 255 : b2 < 0 ? 0 : b2;
            
            r3 = r3 > 255 ? 255 : r3 < 0 ? 0 : r3;
            g3 = g3 > 255 ? 255 : g3 < 0 ? 0 : g3;
            b3 = b3 > 255 ? 255 : b3 < 0 ? 0 : b3;
            
            r4 = r4 > 255 ? 255 : r4 < 0 ? 0 : r4;
            g4 = g4 > 255 ? 255 : g4 < 0 ? 0 : g4;
            b4 = b4 > 255 ? 255 : b4 < 0 ? 0 : b4;
            
            dst1[3*i + 0] = r1;
            dst1[3*i + 1] = g1;
            dst1[3*i + 2] = b1;
            
            dst2[3*i + 0] = r2;
            dst2[3*i + 1] = g2;
            dst2[3*i + 2] = b2;
            
            dst1[3*i + 3] = r3;
            dst1[3*i + 4] = g3;
            dst1[3*i + 5] = b3;
            
            dst2[3*i + 3] = r4;
            dst2[3*i + 4] = g4;
            dst2[3*i + 5] = b4;
        }
    }
}
#endif

static void avStreamFPSTimeBase(AVStream *st, CGFloat defaultTimeBase, CGFloat *pFPS, CGFloat *pTimeBase)
{
    CGFloat fps, timebase;
    
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else if(st->codec->time_base.den && st->codec->time_base.num)
        timebase = av_q2d(st->codec->time_base);
    else
        timebase = defaultTimeBase;
    
    if (st->codec->ticks_per_frame != 1) {
        LoggerStream(0, @"WARNING: st.codec.ticks_per_frame=%d", st->codec->ticks_per_frame);
        //        timebase *= st->codec->ticks_per_frame;///???
    }
    
    if (st->avg_frame_rate.den && st->avg_frame_rate.num)
        fps = av_q2d(st->avg_frame_rate);
    else if (st->r_frame_rate.den && st->r_frame_rate.num)
        fps = av_q2d(st->r_frame_rate);
    else
        fps = 1.0 / timebase;
    
    if (pFPS)
        *pFPS = fps;
    if (pTimeBase)
        *pTimeBase = timebase;
}

static NSArray *collectStreams(AVFormatContext *formatCtx, enum AVMediaType codecType)
{
    NSMutableArray *ma = [NSMutableArray array];
    for (NSInteger i = 0; i < formatCtx->nb_streams; ++i)
        if (codecType == formatCtx->streams[i]->codec->codec_type)
            [ma addObject: [NSNumber numberWithInteger: i]];
    return [ma copy];
}

static NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height];
    Byte* dst = (Byte*) md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}

static BOOL isNetworkPath (NSString *path)
{
    NSRange r = [path rangeOfString:@":"];
    if (r.location == NSNotFound)
        return NO;
    NSString *scheme = [path substringToIndex:r.length];
    if ([scheme isEqualToString:@"file"])
        return NO;
    return YES;
}

static BOOL isRTSPPreviewPath (NSString *path)
{
    NSRange r = [path rangeOfString:@"rtsp://"];
    if (r.location == NSNotFound)
        return NO;
    else {
        NSRange liver = [path rangeOfString:@"live"];
        if (liver.location == NSNotFound)
            return YES;
        else
            return NO;
    }
}

static BOOL isRTSPLivePath (NSString *path)
{
    NSRange r = [path rangeOfString:@"rtsp://"];
    if (r.location == NSNotFound)
        return NO;
    else {
        NSRange liver = [path rangeOfString:@"live"];
        if (liver.location == NSNotFound)
            return NO;
        else
            return YES;
    }
}


static int interrupt_callback(void *ctx);

////////////////////////////////////////////////////////////////////////////////

@interface KxMovieFrame()
@property (readwrite, nonatomic) CGFloat position;
@property (readwrite, nonatomic) CGFloat duration;
@end

@implementation KxMovieFrame
@end

@interface KxAudioFrame()
@property (readwrite, nonatomic, strong) NSData *samples;
@end

@implementation KxAudioFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeAudio; }
@end

@interface KxVideoFrame()
@property (readwrite, nonatomic) NSUInteger width;
@property (readwrite, nonatomic) NSUInteger height;
@end

@implementation KxVideoFrame

#ifdef DEBUG_VIDEOFRAME_LEAKING
+ (NSUInteger) liveObjectsAfterAction:(BOOL)isCreateOrRelease {
    static NSUInteger s_liveObjectCount = 0;
    static NSUInteger s_maxLivingObjects = 0;
    @synchronized (KxVideoFrame.class)
    {
        if (isCreateOrRelease)
            s_liveObjectCount++;
        else
            s_liveObjectCount--;
        if (s_liveObjectCount > s_maxLivingObjects) s_maxLivingObjects = s_liveObjectCount;
        //NSLog(@"VideoLeak : liveObjectsAfterAction:%d = %ld, max = %ld", isCreateOrRelease, (long)s_liveObjectCount, (long)s_maxLivingObjects);
        return s_liveObjectCount;
    }
}

- (void) dealloc {
    [self.class liveObjectsAfterAction:NO];
    //NSLog(@"KxMovieDecoder dealloc");
    //NSLog(@"VideoLeak : KxVideoFrame $ dealloc @ %@", self);
}

- (instancetype) init {
    if (self = [super init])
    {
        //NSLog(@"VideoLeak : KxVideoFrame $ init @ %@", self);
        [self.class liveObjectsAfterAction:YES];
    }
    return self;
}
#endif

- (KxMovieFrameType) type { return KxMovieFrameTypeVideo; }
@end

@interface KxVideoFrameRGB ()
@property (readwrite, nonatomic) NSUInteger linesize;
@property (readwrite, nonatomic, strong) NSData *rgb;
@end

@implementation KxVideoFrameRGB
- (KxVideoFrameFormat) format { return KxVideoFrameFormatRGB; }
- (UIImage *) asImage
{
    UIImage *image = nil;
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(_rgb));
    if (provider) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace) {
            CGImageRef imageRef = CGImageCreate(self.width,
                                                self.height,
                                                8,
                                                24,
                                                self.linesize,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault,
                                                provider,
                                                NULL,
                                                YES, // NO
                                                kCGRenderingIntentDefault);
            
            if (imageRef) {
                image = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }
            CGColorSpaceRelease(colorSpace);
        }
        CGDataProviderRelease(provider);
    }
    
    return image;
}
@end

@interface KxVideoFrameYUV()
@end

@implementation KxVideoFrameYUV
- (KxVideoFrameFormat) format { return KxVideoFrameFormatYUV; }
@end

//ios vt decoder frame by spy
@interface KxVideoFrameCVBuffer()//2016.3.3 spy
@end

@implementation KxVideoFrameCVBuffer

- (void) releasePixelBuffer {
    @synchronized (self)
    {
        if (_cvBufferRef)
            CVBufferRelease(_cvBufferRef);
        _cvBufferRef = NULL;
    }
}

- (KxVideoFrameFormat) format { return KxVideoFrameFormatCVBuffer; }
-(void)dealloc{ //2016.3.3 spy
    [self releasePixelBuffer];
}
@end


@interface KxArtworkFrame()
@property (readwrite, nonatomic, strong) NSData *picture;
@end

@implementation KxArtworkFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeArtwork; }
- (UIImage *) asImage
{
    UIImage *image = nil;
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(_picture));
    if (provider) {
        
        CGImageRef imageRef = CGImageCreateWithJPEGDataProvider(provider,
                                                                NULL,
                                                                YES,
                                                                kCGRenderingIntentDefault);
        if (imageRef) {
            
            image = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
        }
        CGDataProviderRelease(provider);
    }
    
    return image;
    
}
@end

@interface KxSubtitleFrame()
@property (readwrite, nonatomic, strong) NSString *text;
@end

@implementation KxSubtitleFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeSubtitle; }
@end

////////////////////////////////////////////////////////////////////////////////

@interface KxMovieDecoder () {
    
    AVFormatContext     *_formatCtx;
    AVCodecContext      *_videoCodecCtx;
    AVCodecContext      *_audioCodecCtx;
    AVCodecContext      *_subtitleCodecCtx;
    AVFrame             *_videoFrame;
    AVFrame             *_audioFrame;
    NSInteger           _videoStream;
    NSInteger           _audioStream;
    NSInteger           _subtitleStream;
    AVPicture           _picture;
    BOOL                _pictureValid;
    struct SwsContext   *_swsContext;
    CGFloat             _videoTimeBase;
    CGFloat             _audioTimeBase;
    CGFloat             _position;
    NSArray             *_videoStreams;
    NSArray             *_audioStreams;
    NSArray             *_subtitleStreams;
    SwrContext          *_swrContext;
    void                *_swrBuffer;
    NSUInteger          _swrBufferSize;
    NSDictionary        *_info;
    KxVideoFrameFormat  _videoFrameFormat;
    NSUInteger          _artworkStream;
    NSInteger           _subtitleASSEvents;
    
#ifdef USE_iOS8HW_DECODING
    CMVideoFormatDescriptionRef videoFormatDescr;
    VTDecompressionSessionRef session;
    OSStatus status;
    NSData *spsData;
    NSData *ppsData;
#endif
}
@end

@implementation KxMovieDecoder

@dynamic duration;
@dynamic position;
@dynamic frameWidth;
@dynamic frameHeight;
@dynamic sampleRate;
@dynamic audioStreamsCount;
@dynamic subtitleStreamsCount;
@dynamic selectedAudioStream;
@dynamic selectedSubtitleStream;
@dynamic validAudio;
@dynamic validVideo;
@dynamic validSubtitles;
@dynamic info;
@dynamic videoStreamFormatName;
@dynamic startTime;

- (CGFloat) duration
{
    if (!_formatCtx)
        return 0;
    if (_formatCtx->duration == AV_NOPTS_VALUE)
        return MAXFLOAT;
    return (CGFloat)_formatCtx->duration / AV_TIME_BASE;
}

- (CGFloat) position
{
    return _position;
}

- (void) setPosition: (CGFloat)seconds
{
    _position = seconds;
    //NSLog(@"#Codec# KxMovieDecoder setPosition: %f isEOF = NO @ %@", seconds, self);
    _isEOF = NO;
	   
    if (_videoStream != -1) {
        int64_t ts = (int64_t)(seconds / _videoTimeBase);
        avformat_seek_file(_formatCtx, (int)_videoStream, ts, ts, ts, AVSEEK_FLAG_FRAME);
        avcodec_flush_buffers(_videoCodecCtx);
    }
#if 0
    if (_audioStream != -1) {
        int64_t ts = (int64_t)(seconds / _audioTimeBase);
        avformat_seek_file(_formatCtx, _audioStream, ts, ts, ts, AVSEEK_FLAG_FRAME);
        avcodec_flush_buffers(_audioCodecCtx);
    }
#endif
}

- (NSUInteger) frameWidth
{
    return _videoCodecCtx ? _videoCodecCtx->width : 0;
}

- (NSUInteger) frameHeight
{
    return _videoCodecCtx ? _videoCodecCtx->height : 0;
}

- (CGFloat) sampleRate
{
    return _audioCodecCtx ? _audioCodecCtx->sample_rate : 0;
}

- (NSUInteger) audioStreamsCount
{
    return [_audioStreams count];
}

- (NSUInteger) subtitleStreamsCount
{
    return [_subtitleStreams count];
}

- (NSInteger) selectedAudioStream
{
    NSLog(@"selectedAudioStream");
    if (_audioStream == -1)
        return -1;
    NSNumber *n = [NSNumber numberWithInteger:_audioStream];
    return [_audioStreams indexOfObject:n];
}

- (void) setSelectedAudioStream:(NSInteger)selectedAudioStream
{
    
    NSLog(@"setSelectedAudioStream %ld", (long)selectedAudioStream);
    NSInteger audioStream = [_audioStreams[selectedAudioStream] integerValue];
    [self closeAudioStream];
    kxMovieError errCode = [self openAudioStream: audioStream];
    if (kxMovieErrorNone != errCode) {
        LoggerAudio(0, @"%@", errorMessage(errCode));
    }
}

- (NSInteger) selectedSubtitleStream
{
    
    NSLog(@"selectedSubtitleStream");
    if (_subtitleStream == -1)
        return -1;
    return [_subtitleStreams indexOfObject:@(_subtitleStream)];
}

- (void) setSelectedSubtitleStream:(NSInteger)selected
{
    
    NSLog(@"setSelectedSubtitleStream %d", selected);
    [self closeSubtitleStream];
    
    if (selected == -1) {
        
        _subtitleStream = -1;
        
    } else {
        
        NSInteger subtitleStream = [_subtitleStreams[selected] integerValue];
        kxMovieError errCode = [self openSubtitleStream:subtitleStream];
        if (kxMovieErrorNone != errCode) {
            LoggerStream(0, @"%@", errorMessage(errCode));
        }
    }
}

- (BOOL) validAudio
{
    return _audioStream != -1;
}

- (BOOL) validVideo
{
    return _videoStream != -1;
}

- (BOOL) validSubtitles
{
    return _subtitleStream != -1;
}

- (NSDictionary *) info
{
    
    NSLog(@"info");
    if (!_info) {
        
        NSMutableDictionary *md = [NSMutableDictionary dictionary];
        
        if (_formatCtx) {
            
            const char *formatName = _formatCtx->iformat->name;
            [md setValue: [NSString stringWithCString:formatName encoding:NSUTF8StringEncoding]
                  forKey: @"format"];
            
            if (_formatCtx->bit_rate) {
                
                [md setValue: [NSNumber numberWithInt:_formatCtx->bit_rate]
                      forKey: @"bitrate"];
            }
            
            if (_formatCtx->metadata) {
                
                NSMutableDictionary *md1 = [NSMutableDictionary dictionary];
                
                AVDictionaryEntry *tag = NULL;
                while((tag = av_dict_get(_formatCtx->metadata, "", tag, AV_DICT_IGNORE_SUFFIX))) {
                    
                    [md1 setValue: [NSString stringWithCString:tag->value encoding:NSUTF8StringEncoding]
                           forKey: [NSString stringWithCString:tag->key encoding:NSUTF8StringEncoding]];
                }
                
                [md setValue: [md1 copy] forKey: @"metadata"];
            }
            
            char buf[256];
            
            if (_videoStreams.count) {
                NSMutableArray *ma = [NSMutableArray array];
                for (NSNumber *n in _videoStreams) {
                    AVStream *st = _formatCtx->streams[n.integerValue];
                    ///!!!qiudong: Metadata
                    if (st->metadata)
                    {
                        NSMutableDictionary *md1 = [NSMutableDictionary dictionary];
                        
                        AVDictionaryEntry *tag = NULL;
                        while((tag = av_dict_get(st->metadata, "", tag, AV_DICT_IGNORE_SUFFIX))) {
                            
                            [md1 setValue: [NSString stringWithCString:tag->value encoding:NSUTF8StringEncoding]
                                   forKey: [NSString stringWithCString:tag->key encoding:NSUTF8StringEncoding]];
                        }
                        
                        [md setValue: [md1 copy] forKey: @"metadata"];
                    }
                    
                    avcodec_string(buf, sizeof(buf), st->codec, 1);
                    NSString *s = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
                    if ([s hasPrefix:@"Video: "])
                        s = [s substringFromIndex:@"Video: ".length];
                    [ma addObject:s];
                }
                md[@"video"] = ma.copy;
            }
            
            if (_audioStreams.count) {
                NSMutableArray *ma = [NSMutableArray array];
                for (NSNumber *n in _audioStreams) {
                    AVStream *st = _formatCtx->streams[n.integerValue];
                    
                    NSMutableString *ms = [NSMutableString string];
                    AVDictionaryEntry *lang = av_dict_get(st->metadata, "language", NULL, 0);
                    if (lang && lang->value) {
                        [ms appendFormat:@"%s ", lang->value];
                    }
                    
                    avcodec_string(buf, sizeof(buf), st->codec, 1);
                    NSString *s = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
                    if ([s hasPrefix:@"Audio: "])
                        s = [s substringFromIndex:@"Audio: ".length];
                    [ms appendString:s];
                    
                    [ma addObject:ms.copy];
                }
                md[@"audio"] = ma.copy;
            }
            
            if (_subtitleStreams.count) {
                NSMutableArray *ma = [NSMutableArray array];
                for (NSNumber *n in _subtitleStreams) {
                    AVStream *st = _formatCtx->streams[n.integerValue];
                    ///!!!qiudong: Metadata
                    if (st->metadata)
                    {
                        NSMutableDictionary *md1 = [NSMutableDictionary dictionary];
                        
                        AVDictionaryEntry *tag = NULL;
                        while((tag = av_dict_get(st->metadata, "", tag, AV_DICT_IGNORE_SUFFIX))) {
                            
                            [md1 setValue: [NSString stringWithCString:tag->value encoding:NSUTF8StringEncoding]
                                   forKey: [NSString stringWithCString:tag->key encoding:NSUTF8StringEncoding]];
                        }
                        
                        [md setValue: [md1 copy] forKey: @"metadata"];
                    }
                    
                    NSMutableString *ms = [NSMutableString string];
                    AVDictionaryEntry *lang = av_dict_get(st->metadata, "language", NULL, 0);
                    if (lang && lang->value) {
                        [ms appendFormat:@"%s ", lang->value];
                    }
                    
                    avcodec_string(buf, sizeof(buf), st->codec, 1);
                    NSString *s = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
                    if ([s hasPrefix:@"Subtitle: "])
                        s = [s substringFromIndex:@"Subtitle: ".length];
                    [ms appendString:s];
                    
                    [ma addObject:ms.copy];
                }
                md[@"subtitles"] = ma.copy;
            }
            
        }
        
        _info = [md copy];
    }
    
    return _info;
}

- (NSString *) videoStreamFormatName
{
    NSLog(@"videoStreamFormatName");
    if (!_videoCodecCtx)
        return nil;
    
    if (_videoCodecCtx->pix_fmt == AV_PIX_FMT_NONE)
        return @"";
    
    const char *name = av_get_pix_fmt_name(_videoCodecCtx->pix_fmt);
    return name ? [NSString stringWithCString:name encoding:NSUTF8StringEncoding] : @"?";
}

- (CGFloat) startTime
{
    
    //NSLog(@"startTime");
    
    if (_videoStream != -1) {
        
        AVStream *st = _formatCtx->streams[_videoStream];
        if (AV_NOPTS_VALUE != st->start_time)
            return st->start_time * _videoTimeBase;
        return 0;
    }
    
    if (_audioStream != -1) {
        
        AVStream *st = _formatCtx->streams[_audioStream];
        if (AV_NOPTS_VALUE != st->start_time)
            return st->start_time * _audioTimeBase;
        return 0;
    }
    
    return 0;
}

+ (void)initialize
{
    NSLog(@"initialize");
    av_log_set_callback(FFLog);
    av_register_all();
#ifdef USE_MY_H264_DECODER
    //avcodec_register(&ff_h264HD_decoder);
    avcodec_register(&ff_h264VTHD_decoder);
#endif
    
    avformat_network_init();
}

+ (id) movieDecoderWithContentPath: (NSString *) path
                             error: (NSError **) perror
{
    NSLog(@"movieDecoderWithContentPath %@", path);
    KxMovieDecoder *mp = [[KxMovieDecoder alloc] init];
    if (mp) {
        [mp openFile:path error:perror];
    }
    return mp;
}

- (void) dealloc
{
    LoggerStream(2, @"%@ dealloc closeFile", self);
    [self closeFile];
}

#pragma mark - private

- (BOOL) openFile: (NSString *) path
            error: (NSError **) perror
{
///!!!qiudong 20160414
    ///!!!NSAssert(path, @"nil path");
    ///!!!NSAssert(!_formatCtx, @"already open");
    NSLog(@"openFile %@ with perror", path);
    if ( isRTSPPreviewPath(path)) {
        path = [path stringByReplacingOccurrencesOfString:@"rtsp" withString:@"http"];
        path = [path stringByReplacingOccurrencesOfString:@"/tmp/SD0/DCIM" withString:@":50422"];
        NSLog(@"path replaced to %@", path);
    }
    _isNetwork = isNetworkPath(path);
    _isRTSPLive = isRTSPLivePath(path);
    
    static BOOL needNetworkInit = YES;
    if (needNetworkInit && _isNetwork) {
        
        needNetworkInit = NO;
        avformat_network_init();
    }
    
    _path = path;
    
    LoggerStream(1, @"openFile: openInput");
    kxMovieError errCode = [self openInput: path];
    
    if (errCode == kxMovieErrorNone) {
        
        kxMovieError videoErr = [self openVideoStreams];
        kxMovieError audioErr = [self openAudioStreams];
        
        _subtitleStream = -1;
        
        if (videoErr != kxMovieErrorNone &&
            audioErr != kxMovieErrorNone) {
            
            errCode = videoErr; // both fails
            
        } else {
            
            _subtitleStreams = collectStreams(_formatCtx, AVMEDIA_TYPE_SUBTITLE);
        }
    }
    
    if (errCode != kxMovieErrorNone) {
        NSLog(@"OpenFile closeFile");
        [self closeFile];
        NSString *errMsg = errorMessage(errCode);
        LoggerStream(0, @"%@, %@", errMsg, path.lastPathComponent);
        if (perror)
            *perror = kxmovieError(errCode, errMsg);
        return NO;
    }
    
#ifdef USE_iOS8HW_DECODING
    spsData = nil;
    ppsData = nil;
    videoFormatDescr = NULL;
    session = NULL;
#endif
    return YES;
}

- (kxMovieError) openInput: (NSString *) path
{
    
    NSLog(@"openInput %s", path);
    
    
    AVFormatContext *formatCtx = NULL;
    
    if (_interruptCallback) {
        
        formatCtx = avformat_alloc_context();
        if (!formatCtx)
            return kxMovieErrorOpenFile;
        
        AVIOInterruptCB cb = {interrupt_callback, (__bridge void *)(self)};
        formatCtx->interrupt_callback = cb;
    }
    
    LoggerStream(1, @"openInput: avformat_open_input");

    //有三种传输方式：tcp udp_multicast udp，强制采用tcp传输
    AVDictionary* options = NULL;
    //av_dict_set(&options, "rtsp_transport", "tcp", 0);
    
    //if (avformat_open_input(&formatCtx, [path cStringUsingEncoding: NSUTF8StringEncoding], NULL, &options) < 0) {
    int nerror = avformat_open_input(&formatCtx, [path UTF8String], NULL, &options);
    if (nerror < 0) {
        if (formatCtx)
            avformat_free_context(formatCtx);
        return kxMovieErrorOpenFile;
    }
    
    LoggerStream(1, @"openInput: avformat_find_stream_info");
    if (avformat_find_stream_info(formatCtx, NULL) < 0) {
        
        avformat_close_input(&formatCtx);
        return kxMovieErrorStreamInfoNotFound;
    }
    
    av_dump_format(formatCtx, 0, [path.lastPathComponent cStringUsingEncoding: NSUTF8StringEncoding], false);///???
    
    _formatCtx = formatCtx;
    return kxMovieErrorNone;
}

- (kxMovieError) openVideoStreams
{
    
    NSLog(@"openVideoStreams");
    
    kxMovieError errCode = kxMovieErrorStreamNotFound;
    _videoStream = -1;
    _artworkStream = -1;
    _videoStreams = collectStreams(_formatCtx, AVMEDIA_TYPE_VIDEO);
    for (NSNumber *n in _videoStreams) {
        
        const NSUInteger iStream = n.integerValue;
        
        if (0 == (_formatCtx->streams[iStream]->disposition & AV_DISPOSITION_ATTACHED_PIC)) {
            
            errCode = [self openVideoStream: iStream];
            if (errCode == kxMovieErrorNone)
                break;
            
        } else {
            
            _artworkStream = iStream;
        }
    }
    
    return errCode;
}

- (kxMovieError) openVideoStream: (NSInteger) videoStream
{
    
    NSLog(@"openVideoStream %d", videoStream);
    
    // get a pointer to the codec context for the video stream
    AVCodecContext *codecCtx = _formatCtx->streams[videoStream]->codec;
    
    // find the decoder for the video stream
    AVCodec *codec = NULL;
#ifdef USE_MY_H264_DECODER
    if (AV_CODEC_ID_H264 == codecCtx->codec_id || AV_CODEC_ID_MPEG4 == codecCtx->codec_id ) //write by spy 2016.3.28
    {
        //codec = &ff_h264HD_decoder;
        if (AV_CODEC_ID_H264 == codecCtx->codec_id)
            codec = &ff_h264VTHD_decoder;
        else
            codec = &ff_mpeg4VTHD_decoder;
        
        codecCtx->codec = codec;
    }
    else
#endif
    {
        codec = avcodec_find_decoder(codecCtx->codec_id);
    }
    
    if (!codec)
        return kxMovieErrorCodecNotFound;
    
    // inform the codec that we can handle truncated bitstreams -- i.e.,
    // bitstreams where frame boundaries can fall in the middle of packets
    //if(codec->capabilities & CODEC_CAP_TRUNCATED)
    //    _codecCtx->flags |= CODEC_FLAG_TRUNCATED;
    
    // open codec
    if (avcodec_open2(codecCtx, codec, NULL) < 0)
        return kxMovieErrorOpenCodec;
    
    _videoFrame = av_frame_alloc();
    
    if (!_videoFrame) {
        avcodec_close(codecCtx);
        return kxMovieErrorAllocateFrame;
    }
    
    _videoStream = videoStream;
    _videoCodecCtx = codecCtx;
    
    // determine fps
    
    AVStream *st = _formatCtx->streams[_videoStream];
    avStreamFPSTimeBase(st, 0.04, &_fps, &_videoTimeBase);
    
    float original_bitrate_pixel_ratio = 40000000.0 / (3456.0 * 1728.0);
    float content_bitrate_pixel_ration = _formatCtx->bit_rate / (self.frameWidth * self.frameHeight);
    _formatCtx->is_share_bitrate_content = (content_bitrate_pixel_ration < (original_bitrate_pixel_ratio / 2.5));
    NSLog(@"original_bitrate_pixel_ratio %f content_bitrate_pixel_ration %f is_share_bitrate_content: %d",
          original_bitrate_pixel_ratio, content_bitrate_pixel_ration, _formatCtx->is_share_bitrate_content);
           
    LoggerVideo(1, @"video codec size: %ld:%ld fps: %.3f tb: %f",
                self.frameWidth,
                self.frameHeight,
                _fps,
                _videoTimeBase);
    
    LoggerVideo(1, @"video start time %f", st->start_time * _videoTimeBase);
    LoggerVideo(1, @"video disposition %d", st->disposition);
    
    return kxMovieErrorNone;
}

- (kxMovieError) openAudioStreams
{
    kxMovieError errCode = kxMovieErrorStreamNotFound;
    _audioStream = -1;
    _audioStreams = collectStreams(_formatCtx, AVMEDIA_TYPE_AUDIO);
    for (NSNumber *n in _audioStreams) {
        
        errCode = [self openAudioStream: n.integerValue];
        if (errCode == kxMovieErrorNone)
            break;
    }
    return errCode;
}

- (kxMovieError) openAudioStream: (NSInteger) audioStream
{
    AVCodecContext *codecCtx = _formatCtx->streams[audioStream]->codec;
    SwrContext *swrContext = NULL;
    
    AVCodec *codec = avcodec_find_decoder(codecCtx->codec_id);
    if(!codec)
        return kxMovieErrorCodecNotFound;
    
    if (avcodec_open2(codecCtx, codec, NULL) < 0)
        return kxMovieErrorOpenCodec;
    
    if (!audioCodecIsSupported(codecCtx)) {
        
        id<KxAudioManager> audioManager = [KxAudioManager audioManager];
        swrContext = swr_alloc_set_opts(NULL,
                                        av_get_default_channel_layout(audioManager.numOutputChannels),
                                        AV_SAMPLE_FMT_S16,
                                        audioManager.samplingRate,
                                        av_get_default_channel_layout(codecCtx->channels),
                                        codecCtx->sample_fmt,
                                        codecCtx->sample_rate,
                                        0,
                                        NULL);
        
        if (!swrContext ||
            swr_init(swrContext)) {
            
            if (swrContext)
                swr_free(&swrContext);
            avcodec_close(codecCtx);
            
            return kxMovieErroReSampler;
        }
    }
    
    _audioFrame = av_frame_alloc();
    
    if (!_audioFrame) {
        if (swrContext)
            swr_free(&swrContext);
        avcodec_close(codecCtx);
        return kxMovieErrorAllocateFrame;
    }
    
    _audioStream = audioStream;
    _audioCodecCtx = codecCtx;
    _swrContext = swrContext;
    
    AVStream *st = _formatCtx->streams[_audioStream];
    avStreamFPSTimeBase(st, 0.025, 0, &_audioTimeBase);
    
    LoggerAudio(1, @"audio codec smr: %.d fmt: %d chn: %d tb: %f %@",
                _audioCodecCtx->sample_rate,
                _audioCodecCtx->sample_fmt,
                _audioCodecCtx->channels,
                _audioTimeBase,
                _swrContext ? @"resample" : @"");
    
    return kxMovieErrorNone;
}

- (kxMovieError) openSubtitleStream: (NSInteger) subtitleStream
{
    AVCodecContext *codecCtx = _formatCtx->streams[subtitleStream]->codec;
    
    AVCodec *codec = avcodec_find_decoder(codecCtx->codec_id);
    if(!codec)
        return kxMovieErrorCodecNotFound;
    
    const AVCodecDescriptor *codecDesc = avcodec_descriptor_get(codecCtx->codec_id);
    if (codecDesc && (codecDesc->props & AV_CODEC_PROP_BITMAP_SUB)) {
        // Only text based subtitles supported
        return kxMovieErroUnsupported;
    }
    
    if (avcodec_open2(codecCtx, codec, NULL) < 0)
        return kxMovieErrorOpenCodec;
    
    _subtitleStream = subtitleStream;
    _subtitleCodecCtx = codecCtx;
    
    LoggerStream(1, @"subtitle codec: '%s' mode: %d enc: %s",
                 codecDesc->name,
                 codecCtx->sub_charenc_mode,
                 codecCtx->sub_charenc);
    
    _subtitleASSEvents = -1;
    
    if (codecCtx->subtitle_header_size) {
        
        NSString *s = [[NSString alloc] initWithBytes:codecCtx->subtitle_header
                                               length:codecCtx->subtitle_header_size
                                             encoding:NSASCIIStringEncoding];
        
        if (s.length) {
            
            NSArray *fields = [KxMovieSubtitleASSParser parseEvents:s];
            if (fields.count && [fields.lastObject isEqualToString:@"Text"]) {
                _subtitleASSEvents = fields.count;
                LoggerStream(2, @"subtitle ass events: %@", [fields componentsJoinedByString:@","]);
            }
        }
    }
    
    return kxMovieErrorNone;
}

-(void) closeFile
{
    
    //NSLog(@"KxMovieDecoder closeFile");
    [self closeAudioStream];
    [self closeVideoStream];
    [self closeSubtitleStream];
    
    _videoStreams = nil;
    _audioStreams = nil;
    _subtitleStreams = nil;
    
    if (_formatCtx) {
        
        _formatCtx->interrupt_callback.opaque = NULL;
        _formatCtx->interrupt_callback.callback = NULL;
        
        avformat_close_input(&_formatCtx);
            //NSLog(@"KxMovieDecoder closeFile avformat_close_input");
        _formatCtx = NULL;
    }
}

- (void) closeVideoStream
{
    
    NSLog(@"closeVideoStream");
    
    _videoStream = -1;
    
    [self closeScaler];
    
    if (_videoFrame) {
        
        av_free(_videoFrame);
        _videoFrame = NULL;
    }
    
    if (_videoCodecCtx) {
        
        avcodec_close(_videoCodecCtx);
        _videoCodecCtx = NULL;
    }
}

- (void) closeAudioStream
{
    _audioStream = -1;
    
    if (_swrBuffer) {
        
        free(_swrBuffer);
        _swrBuffer = NULL;
        _swrBufferSize = 0;
    }
    
    if (_swrContext) {
        
        swr_free(&_swrContext);
        _swrContext = NULL;
    }
    
    if (_audioFrame) {
        
        av_free(_audioFrame);
        _audioFrame = NULL;
    }
    
    if (_audioCodecCtx) {
        
        avcodec_close(_audioCodecCtx);
        _audioCodecCtx = NULL;
    }
}

- (void) closeSubtitleStream
{
    _subtitleStream = -1;
    
    if (_subtitleCodecCtx) {
        
        avcodec_close(_subtitleCodecCtx);
        _subtitleCodecCtx = NULL;
    }
}

- (void) closeScaler
{
    if (_swsContext) {
        sws_freeContext(_swsContext);
        _swsContext = NULL;
    }
    
    if (_pictureValid) {
        avpicture_free(&_picture);
        _pictureValid = NO;
    }
}

- (BOOL) setupScaler
{
    [self closeScaler];
    
    _pictureValid = avpicture_alloc(&_picture,
                                    PIX_FMT_RGB24,
                                    _videoCodecCtx->width,
                                    _videoCodecCtx->height) == 0;
    
    if (!_pictureValid)
        return NO;
    
    _swsContext = sws_getCachedContext(_swsContext,
                                       _videoCodecCtx->width,
                                       _videoCodecCtx->height,
                                       _videoCodecCtx->pix_fmt,
                                       _videoCodecCtx->width,
                                       _videoCodecCtx->height,
                                       PIX_FMT_RGB24,
                                       SWS_FAST_BILINEAR,
                                       NULL, NULL, NULL);
    
    return _swsContext != NULL;
}

- (KxVideoFrame *) handleVideoFrame
{
    //NSLog(@"handleVideoFrame");
    
    if (!_videoFrame->data[0])
        return nil;
    
    KxVideoFrame *frame;
    
    if (_videoFrameFormat == KxVideoFrameFormatYUV) {
        KxVideoFrameYUV * yuvFrame = [[KxVideoFrameYUV alloc] init];
        
        yuvFrame.luma = copyFrameData(_videoFrame->data[0],
                                      _videoFrame->linesize[0],
                                      _videoCodecCtx->width,
                                      _videoCodecCtx->height);
        
        yuvFrame.chromaB = copyFrameData(_videoFrame->data[1],
                                         _videoFrame->linesize[1],
                                         _videoCodecCtx->width / 2,
                                         _videoCodecCtx->height / 2);
        
        yuvFrame.chromaR = copyFrameData(_videoFrame->data[2],
                                         _videoFrame->linesize[2],
                                         _videoCodecCtx->width / 2,
                                         _videoCodecCtx->height / 2);
        frame = yuvFrame;
    }
    else if (_videoFrameFormat == KxVideoFrameFormatCVBuffer){
        KxVideoFrameCVBuffer * cvBufferFrame = [[KxVideoFrameCVBuffer alloc] init];
        cvBufferFrame.cvBufferRef = (CVBufferRef)_videoFrame->data[0];
        //CVBufferRetain(cvBufferFrame.cvBufferRef);
        frame = cvBufferFrame;
        //cvBufferFrame = nil;
    }
    else {
        
        if (!_swsContext &&
            ![self setupScaler]) {
            
            LoggerVideo(0, @"fail setup video scaler");
            return nil;
        }
        
        sws_scale(_swsContext,
                  (const uint8_t **)_videoFrame->data,
                  _videoFrame->linesize,
                  0,
                  _videoCodecCtx->height,
                  _picture.data,
                  _picture.linesize);
        
        
        KxVideoFrameRGB *rgbFrame = [[KxVideoFrameRGB alloc] init];
        
        rgbFrame.linesize = _picture.linesize[0];
        rgbFrame.rgb = [NSData dataWithBytes:_picture.data[0]
                                      length:rgbFrame.linesize * _videoCodecCtx->height];
        frame = rgbFrame;
    }
    
    frame.timestamp = _videoFrame->best_effort_timestamp * _videoTimeBase * 1000;
    frame.width = _videoCodecCtx->width;
    frame.height = _videoCodecCtx->height;
    frame.position = av_frame_get_best_effort_timestamp(_videoFrame) * _videoTimeBase;///???
    
    const int64_t frameDuration = av_frame_get_pkt_duration(_videoFrame);
    if (frameDuration) {
        
        frame.duration = frameDuration * _videoTimeBase;
        frame.duration += _videoFrame->repeat_pict * _videoTimeBase * 0.5;
        
        //if (_videoFrame->repeat_pict > 0) {
        //    LoggerVideo(0, @"_videoFrame.repeat_pict %d", _videoFrame->repeat_pict);
        //}
        
    } else {
        
        // sometimes, ffmpeg unable to determine a frame duration
        // as example yuvj420p stream from web camera
        frame.duration = 1.0 / _fps;
    }
    
#if 1
//    LoggerVideo(2, @"VFD: %.4f %.4f | %lld ",
//                frame.position,
//                frame.duration,
//                av_frame_get_pkt_pos(_videoFrame));
#endif
    
    return frame;
}

- (KxAudioFrame *) handleAudioFrame
{
    if (!_audioFrame->data[0])
        return nil;
    
    id<KxAudioManager> audioManager = [KxAudioManager audioManager];
    
    const NSUInteger numChannels = audioManager.numOutputChannels;
    NSInteger numFrames;
    
    void * audioData;
    
    if (_swrContext) {
        
        const NSUInteger ratio = MAX(1, audioManager.samplingRate / _audioCodecCtx->sample_rate) *
        MAX(1, audioManager.numOutputChannels / _audioCodecCtx->channels) * 2;
        
        const int bufSize = av_samples_get_buffer_size(NULL,
                                                       audioManager.numOutputChannels,
                                                       (int) (_audioFrame->nb_samples * ratio),
                                                       AV_SAMPLE_FMT_S16,
                                                       1);
        
        if (!_swrBuffer || _swrBufferSize < bufSize) {
            _swrBufferSize = bufSize;
            _swrBuffer = realloc(_swrBuffer, _swrBufferSize);
        }
        
        Byte *outbuf[2] = { (Byte*) _swrBuffer, 0 };
        
        numFrames = swr_convert(_swrContext,
                                outbuf,
                                (int) (_audioFrame->nb_samples * ratio),
                                (const uint8_t **)_audioFrame->data,
                                _audioFrame->nb_samples);
        
        if (numFrames < 0) {
            LoggerAudio(0, @"fail resample audio");
            return nil;
        }
        
        //int64_t delay = swr_get_delay(_swrContext, audioManager.samplingRate);
        //if (delay > 0)
        //    LoggerAudio(0, @"resample delay %lld", delay);
        
        audioData = _swrBuffer;
        
    } else {
        
        if (_audioCodecCtx->sample_fmt != AV_SAMPLE_FMT_S16) {
            NSAssert(false, @"bucheck, audio format is invalid");
            return nil;
        }
        
        audioData = _audioFrame->data[0];
        numFrames = _audioFrame->nb_samples;
    }
    
    const NSUInteger numElements = numFrames * numChannels;
    NSMutableData *data = [NSMutableData dataWithLength:numElements * sizeof(float)];
    
    float scale = 1.0 / (float)INT16_MAX ;
    vDSP_vflt16((SInt16 *)audioData, 1, (float*) data.mutableBytes, 1, numElements);
    vDSP_vsmul((const float*) data.mutableBytes, 1, &scale, (float*) data.mutableBytes, 1, numElements);
    
    KxAudioFrame *frame = [[KxAudioFrame alloc] init];
    frame.position = av_frame_get_best_effort_timestamp(_audioFrame) * _audioTimeBase;
    frame.duration = av_frame_get_pkt_duration(_audioFrame) * _audioTimeBase;
    frame.samples = data;
    
    if (frame.duration == 0) {
        // sometimes ffmpeg can't determine the duration of audio frame
        // especially of wma/wmv format
        // so in this case must compute duration
        frame.duration = frame.samples.length / (sizeof(float) * numChannels * audioManager.samplingRate);
    }
    
#if 0
    LoggerAudio(2, @"AFD: %.4f %.4f | %.4f ",
                frame.position,
                frame.duration,
                frame.samples.length / (8.0 * 44100.0));
#endif
    
    return frame;
}

- (KxSubtitleFrame *) handleSubtitle: (AVSubtitle *)pSubtitle
{
    NSMutableString *ms = [NSMutableString string];
    
    for (NSUInteger i = 0; i < pSubtitle->num_rects; ++i) {
        
        AVSubtitleRect *rect = pSubtitle->rects[i];
        if (rect) {
            
            if (rect->text) { // rect->type == SUBTITLE_TEXT
                
                NSString *s = [NSString stringWithUTF8String:rect->text];
                if (s.length) [ms appendString:s];
                
            } else if (rect->ass && _subtitleASSEvents != -1) {
                
                NSString *s = [NSString stringWithUTF8String:rect->ass];
                if (s.length) {
                    
                    NSArray *fields = [KxMovieSubtitleASSParser parseDialogue:s numFields:_subtitleASSEvents];
                    if (fields.count && [fields.lastObject length]) {
                        
                        s = [KxMovieSubtitleASSParser removeCommandsFromEventText: fields.lastObject];
                        if (s.length) [ms appendString:s];
                    }
                }
            }
        }
    }
    
    if (!ms.length)
        return nil;
    
    KxSubtitleFrame *frame = [[KxSubtitleFrame alloc] init];
    frame.text = [ms copy];
    frame.position = pSubtitle->pts / AV_TIME_BASE + pSubtitle->start_display_time;
    frame.duration = (CGFloat)(pSubtitle->end_display_time - pSubtitle->start_display_time) / 1000.f;
    
#if 0
    LoggerStream(2, @"SUB: %.4f %.4f | %@",
                 frame.position,
                 frame.duration,
                 frame.text);
#endif
    
    return frame;
}

- (BOOL) interruptDecoder
{
    if (_interruptCallback)
        return _interruptCallback();
    return NO;
}

#ifdef USE_iOS8HW_DECODING
#pragma mark - iOS8 HW decode 相關method

#define USE_DECOMPRESS_BLOCK

#define PIXEL_FORMAT_YUV420

- (void) iOS8HWDecode : (AVPacket*)packet
      decompressBlock : (VTDecompressionOutputHandler)decompressBlock
{
    // 1. get SPS,PPS form stream data, and create CMFormatDescription 和 VTDecompressionSession
    if (spsData == nil && ppsData == nil) {
        uint8_t *data = _videoCodecCtx->extradata;
        int size = _videoCodecCtx->extradata_size;
        NSString *tmp3 = [NSString new];
        for(int i = 0; i < size; i++) {
            NSString *str = [NSString stringWithFormat:@" %.2X",data[i]];
            tmp3 = [tmp3 stringByAppendingString:str];
        }
        
        //        NSLog(@"size ---->>%i",size);
        //        NSLog(@"%@",tmp3);
        
        int startCodeSPSIndex = 0;
        int startCodePPSIndex = 0;
        int spsLength = 0;
        int ppsLength = 0;
        
        for (int i = 0; i < size; i++) {
            if (i >= 3) {
                if (data[i] == 0x01 && data[i-1] == 0x00 && data[i-2] == 0x00 && data[i-3] == 0x00) {
                    if (startCodeSPSIndex == 0) {
                        startCodeSPSIndex = i;
                    }
                    if (i > startCodeSPSIndex) {
                        startCodePPSIndex = i;
                    }
                }
            }
        }
        
        spsLength = startCodePPSIndex - startCodeSPSIndex - 4;
        ppsLength = size - (startCodePPSIndex + 1);
        
        //        NSLog(@"startCodeSPSIndex --> %i",startCodeSPSIndex);
        //        NSLog(@"startCodePPSIndex --> %i",startCodePPSIndex);
        //        NSLog(@"spsLength --> %i",spsLength);
        //        NSLog(@"ppsLength --> %i",ppsLength);
        
        int nalu_type;
        nalu_type = ((uint8_t) data[startCodeSPSIndex + 1] & 0x1F);
        //        NSLog(@"NALU with Type \"%@\" received.", naluTypesStrings[nalu_type]);
        if (nalu_type == 7) {
            spsData = [NSData dataWithBytes:&(data[startCodeSPSIndex + 1]) length: spsLength];
        }
        
        nalu_type = ((uint8_t) data[startCodePPSIndex + 1] & 0x1F);
        //        NSLog(@"NALU with Type \"%@\" received.", naluTypesStrings[nalu_type]);
        if (nalu_type == 8) {
            ppsData = [NSData dataWithBytes:&(data[startCodePPSIndex + 1]) length: ppsLength];
        }
        
        // 2. create  CMFormatDescription
        if (spsData != nil && ppsData != nil) {
            const uint8_t* const parameterSetPointers[2] = { (const uint8_t*)[spsData bytes], (const uint8_t*)[ppsData bytes] };
            const size_t parameterSetSizes[2] = { [spsData length], [ppsData length] };
            status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPointers, parameterSetSizes, 4, &videoFormatDescr);
            //            NSLog(@"Found all data for CMVideoFormatDescription. Creation: %@.", (status == noErr) ? @"successfully." : @"failed.");
        }
        
        // 3. create VTDecompressionSession
#ifndef USE_DECOMPRESS_BLOCK
        VTDecompressionOutputCallbackRecord callback;
        callback.decompressionOutputCallback = didDecompress;
        callback.decompressionOutputRefCon = (__bridge void *)self;
#endif
        
#ifdef PIXEL_FORMAT_YUV420
        NSDictionary *destinationImageBufferAttributes =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],(id)kCVPixelBufferOpenGLESCompatibilityKey,[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8Planar],(id)kCVPixelBufferPixelFormatTypeKey,nil];
#else
        NSDictionary *destinationImageBufferAttributes =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],(id)kCVPixelBufferOpenGLESCompatibilityKey,[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],(id)kCVPixelBufferPixelFormatTypeKey,nil];
#endif
        //        NSDictionary *destinationImageBufferAttributes =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],(id)kCVPixelBufferOpenGLESCompatibilityKey,nil];
        //        NSDictionary *destinationImageBufferAttributes = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey: (id)kCVPixelBufferPixelFormatTypeKey];
#ifdef USE_DECOMPRESS_BLOCK
        status = VTDecompressionSessionCreate(kCFAllocatorDefault, videoFormatDescr, NULL, (__bridge_retained CFDictionaryRef)destinationImageBufferAttributes, NULL, &session);///!!!
#else
        status = VTDecompressionSessionCreate(kCFAllocatorDefault, videoFormatDescr, NULL, (__bridge_retained CFDictionaryRef)destinationImageBufferAttributes, &callback, &session);///!!!
#endif
        //        status = VTDecompressionSessionCreate(kCFAllocatorDefault, videoFormatDescr, NULL, NULL, &callback, &session);
        //        NSLog(@"Creating Video Decompression Session: %@.", (status == noErr) ? @"successfully." : @"failed.");
        
        
        int32_t timeSpan = 90000;
        CMSampleTimingInfo timingInfo;
        timingInfo.presentationTimeStamp = CMTimeMake(0, timeSpan);
        timingInfo.duration =  CMTimeMake(3000, timeSpan);
        timingInfo.decodeTimeStamp = kCMTimeInvalid;
    }
    
    int startCodeIndex = 0;
    for (int i = 0; i < 5; i++) {
        if (packet->data[i] == 0x01) {
            startCodeIndex = i;
            break;
        }
    }
    int nalu_type = ((uint8_t)packet->data[startCodeIndex + 1] & 0x1F);
    //    NSLog(@"NALU with Type \"%@\" received.", naluTypesStrings[nalu_type]);
    
    if (nalu_type == 1 || nalu_type == 5) {
        // 4. get NALUnit payload into a CMBlockBuffer,
        CMBlockBufferRef videoBlock = NULL;
        status = CMBlockBufferCreateWithMemoryBlock(NULL, packet->data, packet->size, kCFAllocatorNull, NULL, 0, packet->size, 0, &videoBlock);
        //        NSLog(@"BlockBufferCreation: %@", (status == kCMBlockBufferNoErr) ? @"successfully." : @"failed.");
        
        // 5.  making sure to replace the separator code with a 4 byte length code (the length of the NalUnit including the unit code)
        int reomveHeaderSize = packet->size - 4;
        const uint8_t sourceBytes[] = {(uint8_t)(reomveHeaderSize >> 24), (uint8_t)(reomveHeaderSize >> 16), (uint8_t)(reomveHeaderSize >> 8), (uint8_t)reomveHeaderSize};
        status = CMBlockBufferReplaceDataBytes(sourceBytes, videoBlock, 0, 4);
        //        NSLog(@"BlockBufferReplace: %@", (status == kCMBlockBufferNoErr) ? @"successfully." : @"failed.");
        
        NSString *tmp3 = [NSString new];
        for(int i = 0; i < sizeof(sourceBytes); i++) {
            NSString *str = [NSString stringWithFormat:@" %.2X",sourceBytes[i]];
            tmp3 = [tmp3 stringByAppendingString:str];
        }
        //        NSLog(@"size = %i , 16Byte = %@",reomveHeaderSize,tmp3);
        
        // 6. create a CMSampleBuffer.
        CMSampleBufferRef sbRef = NULL;
        //        int32_t timeSpan = 90000;
        //        CMSampleTimingInfo timingInfo;
        //        timingInfo.presentationTimeStamp = CMTimeMake(0, timeSpan);
        //        timingInfo.duration =  CMTimeMake(3000, timeSpan);
        //        timingInfo.decodeTimeStamp = kCMTimeInvalid;
        const size_t sampleSizeArray[] = {packet->size};
        
        // 实际测试时，加入time信息后，有不稳定的图像，不加入time信息反而没有，需要进一步研究，这里建议不加入time信息 : http://www.tallmantech.com/archives/206#more-206
        //        status = CMSampleBufferCreate(kCFAllocatorDefault, videoBlock, true, NULL, NULL, videoFormatDescr, 1, 1, &timingInfo, 1, sampleSizeArray, &sbRef);
        status = CMSampleBufferCreate(kCFAllocatorDefault, videoBlock, true, NULL, NULL, videoFormatDescr, 1, 0, NULL, 1, sampleSizeArray, &sbRef);
        
        //        NSLog(@"SampleBufferCreate: %@", (status == noErr) ? @"successfully." : @"failed.");
        
        // 7. use VTDecompressionSessionDecodeFrame
        VTDecodeInfoFlags flagOut;
        
#ifdef USE_DECOMPRESS_BLOCK
        VTDecodeFrameFlags flags = 0;
        status = VTDecompressionSessionDecodeFrameWithOutputHandler(session, sbRef, flags, &flagOut, decompressBlock);
#else
        VTDecodeFrameFlags flags = kVTDecodeFrame_EnableAsynchronousDecompression;
        status = VTDecompressionSessionDecodeFrame(session, sbRef, flags, &sbRef, &flagOut);
#endif
        //        NSLog(@"VTDecompressionSessionDecodeFrame: %@", (status == noErr) ? @"successfully." : @"failed.");
        CFRelease(sbRef);
        
        //        [self.delegate startDecodeData];
        
        //        /* Flush in-process frames. */
        //        VTDecompressionSessionFinishDelayedFrames(session);
        //        /* Block until our callback has been called with the last frame. */
        //        VTDecompressionSessionWaitForAsynchronousFrames(session);
        //
        //        /* Clean up. */
        //        VTDecompressionSessionInvalidate(session);
        //        CFRelease(session);
        //        CFRelease(videoFormatDescr);
        
        
        //        NSLog(@"========================================================================");
        //        NSLog(@"========================================================================");
    }
}


#pragma mark - VideoToolBox Decompress Frame CallBack
/*
 This callback gets called everytime the decompresssion session decodes a frame
 */
void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef imageBuffer, CMTime presentationTimeStamp, CMTime presentationDuration )
{
    LoggerVideo(1, @"didDecompress %.3f", (float)presentationTimeStamp.value/presentationTimeStamp.timescale);
    
    if (status != noErr || !imageBuffer) {
        // error -8969 codecBadDataErr
        // -12909 The operation couldn’t be completed. (OSStatus error -12909.)
        NSLog(@"Error decompresssing frame at time: %.3f error: %d infoFlags: %u", (float)presentationTimeStamp.value/presentationTimeStamp.timescale, (int)status, (unsigned int)infoFlags);
        return;
    }
    
    NSLog(@"Got frame data.\n");
    NSLog(@"Success decompresssing frame at time: %.3f error: %d infoFlags: %u", (float)presentationTimeStamp.value/presentationTimeStamp.timescale, (int)status, (unsigned int)infoFlags);
    //    __weak __block SuperVideoFrameExtractor *weakSelf = (__bridge SuperVideoFrameExtractor *)decompressionOutputRefCon;
    //    [weakSelf.delegate getDecodeImageData:imageBuffer];
    
}


//- (void) dumpPacketData
//{
//    // Log dump
//    int index = 0;
//    NSString *tmp = [NSString new];
//    for(int i = 0; i < packet.size; i++) {
//        NSString *str = [NSString stringWithFormat:@" %.2X",packet.data[i]];
//        if (i == 4) {
//            NSString *header = [NSString stringWithFormat:@"%.2X",packet.data[i]];
//            NSLog(@" header ====>> %@",header);
//            if ([header isEqualToString:@"41"]) {
//                NSLog(@"P Frame");
//            }
//            if ([header isEqualToString:@"65"]) {
//                NSLog(@"I Frame");
//            }
//        }
//        tmp = [tmp stringByAppendingString:str];
//        index++;
//        if (index == 16) {
//            NSLog(@"%@",tmp);
//            tmp = @"";
//            index = 0;
//        }
//    }
//}

NSString * const naluTypesStrings[] = {
    @"Unspecified (non-VCL)",
    @"Coded slice of a non-IDR picture (VCL)",
    @"Coded slice data partition A (VCL)",
    @"Coded slice data partition B (VCL)",
    @"Coded slice data partition C (VCL)",
    @"Coded slice of an IDR picture (VCL)",
    @"Supplemental enhancement information (SEI) (non-VCL)",
    @"Sequence parameter set (non-VCL)",
    @"Picture parameter set (non-VCL)",
    @"Access unit delimiter (non-VCL)",
    @"End of sequence (non-VCL)",
    @"End of stream (non-VCL)",
    @"Filler data (non-VCL)",
    @"Sequence parameter set extension (non-VCL)",
    @"Prefix NAL unit (non-VCL)",
    @"Subset sequence parameter set (non-VCL)",
    @"Reserved (non-VCL)",
    @"Reserved (non-VCL)",
    @"Reserved (non-VCL)",
    @"Coded slice of an auxiliary coded picture without partitioning (non-VCL)",
    @"Coded slice extension (non-VCL)",
    @"Coded slice extension for depth view components (non-VCL)",
    @"Reserved (non-VCL)",
    @"Reserved (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
    @"Unspecified (non-VCL)",
};
#endif //USE_iOS8HW_DECODING

#pragma mark - public

- (BOOL) setupVideoFrameFormat: (KxVideoFrameFormat) format
{
    if (format == KxVideoFrameFormatYUV &&
        _videoCodecCtx &&
        (_videoCodecCtx->pix_fmt == AV_PIX_FMT_YUV420P || _videoCodecCtx->pix_fmt == AV_PIX_FMT_YUVJ420P)) {
        
        if (_videoCodecCtx->codec)
        {
            if (!strcmp(_videoCodecCtx->codec->name, "h264VTHD"))
            {//qiudong:
                _videoFrameFormat = KxVideoFrameFormatCVBuffer;
                return YES;
            }
        }
        else
            _videoFrameFormat = KxVideoFrameFormatYUV;
        return YES;
    }
    
    _videoFrameFormat = KxVideoFrameFormatRGB;
    return _videoFrameFormat == format;
}

- (KxVideoFrameFormat) getVideoFrameFormat
{
    return _videoFrameFormat;
}

- (int64_t) getLutzOffset
{
    return _formatCtx->lutz.offset;
}

- (int64_t) getLutzSize
{
    return _formatCtx->lutz.size;
}

- (uint8_t*) getGyroData
{
    return _formatCtx->gyro_data;
}

- (int) getGyroSize
{
    if (_formatCtx != NULL)
    {
        NSLog(@"Gyro: getGyroSize = %d", _formatCtx->gyro_size);
        return _formatCtx->gyro_size;
    }
    else
        return 0;
}

- (int) getGyroSizePerFrame
{
    NSLog(@"Gyro: getGyroSizePerFrame = %d", _formatCtx->gyro_size_per_frame);
    return _formatCtx->gyro_size_per_frame;
}

- (int) getDispMode
{
    return _formatCtx->disp_mode;
}

- (int) getCutCount
{
    return _formatCtx->cut_count;
}

- (int) getCutSizePerPoint
{
    return _formatCtx->cut_size_per_point;
}

- (uint8_t*) getCutData
{
    return _formatCtx->cut_data;
}

- (boolean_t) isMadVContent
{
    return _formatCtx->is_madv_content;
}

- (boolean_t) isShareBitrateContent
{
    return _formatCtx->is_share_bitrate_content;
}

- (int64_t) getMoovBoxSizeOffset;
{
    return _formatCtx->moov_box_size_offset;
}

- (int64_t) getVideoTrakBoxSizeOffset;
{
    return _formatCtx->video_trak_box_size_offset;
}

- (int64_t) getVideoTrakBoxEndOffset;
{
    return _formatCtx->video_trak_box_end_offset;
}

- (boolean_t) isTimeElapsedVideo
{
    return ![self validAudio];
}

static bool waitNextKeyFrame = false;
- (NSArray *) decodeFrames: (CGFloat) minDuration
{
    //NSLog(@"decodeFrames %f", minDuration);
    if (_videoStream == -1 &&
        _audioStream == -1)
        return nil;
    
    NSMutableArray *result = [NSMutableArray array];
    
    AVPacket packet;
    
    __block CGFloat decodedDuration = 0;
    
    __block BOOL finished = NO;
    
    //    ///!!!For Debug
    //    static double totalDecodeTime = 0;
    //    static double totalDecodedDuration = 0;
    
    while (!finished) {
        //NSLog(@"keep looping");
        if (av_read_frame(_formatCtx, &packet) < 0) {
            NSLog(@"#Codec# KxMovieDecoder decodeFrames: isEOF = YES @ %@", self);
            _isEOF = YES;
            break;
        }
        
        if (waitNextKeyFrame) {
            if (packet.flags & AV_PKT_FLAG_KEY) {
                waitNextKeyFrame = false;
                av_log(NULL, AV_LOG_ERROR, "found next Key frame,stop skipping frames");
            } else {
                av_log(NULL, AV_LOG_ERROR, "skipping frames");
                continue;
            }
        }
        if (packet.flags & AV_PKT_FLAG_CORRUPT) {
            av_log(NULL, AV_LOG_ERROR, "start skipping frames");
            waitNextKeyFrame = true;
            continue;
        }
        
        
        if (packet.stream_index ==_videoStream) {
            
            int pktSize = packet.size;
            
            while (pktSize > 0) {
                //                ///!!!For Debug
                //                NSTimeInterval beforeDecode = [NSDate timeIntervalSinceReferenceDate];
                //                static bool drop = false;
                //                if (drop)
                //                {
                //                    _position = packet.pts * _videoTimeBase;
                //                    decodedDuration += packet.duration * _videoTimeBase;
                //                    if (decodedDuration > minDuration)
                //                        finished = YES;
                //
                //                    drop = false;
                //                    break;
                //                }
                //                else
                //                {
                //                    drop = true;
                //                }
#ifdef USE_iOS8HW_DECODING
                [self iOS8HWDecode:&packet decompressBlock:^(OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef  _Nullable buffer, CMTime presentationTimeStamp, CMTime presentationDuration) {
                    CVPixelBufferLockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
                    uint8_t* data = CVPixelBufferGetBaseAddress(buffer);
                    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
                    size_t width = CVPixelBufferGetWidth(buffer);
                    size_t height = CVPixelBufferGetHeight(buffer);
                    OSType pixelFormat = CVPixelBufferGetPixelFormatType(buffer);
                    
                    KxVideoFrameYUV * yuvFrame = [[KxVideoFrameYUV alloc] init];
                    
                    yuvFrame.luma = copyFrameData(CVPixelBufferGetBaseAddressOfPlane(buffer, 0),//_videoFrame->data[0],
                                                  (int)CVPixelBufferGetBytesPerRowOfPlane(buffer, 0),//_videoFrame->linesize[0],
                                                  (int)CVPixelBufferGetWidthOfPlane(buffer, 0),//_videoCodecCtx->width,
                                                  (int)CVPixelBufferGetHeightOfPlane(buffer, 0));//_videoCodecCtx->height);
                    
                    yuvFrame.chromaB = copyFrameData(CVPixelBufferGetBaseAddressOfPlane(buffer, 1),//_videoFrame->data[1],
                                                     (int)CVPixelBufferGetBytesPerRowOfPlane(buffer, 1),//_videoFrame->linesize[1],
                                                     (int)CVPixelBufferGetWidthOfPlane(buffer, 1),//_videoCodecCtx->width / 2,
                                                     (int)CVPixelBufferGetHeightOfPlane(buffer, 1));//_videoCodecCtx->height / 2);
                    
                    yuvFrame.chromaR = copyFrameData(CVPixelBufferGetBaseAddressOfPlane(buffer, 2),//_videoFrame->data[2],
                                                     (int)CVPixelBufferGetBytesPerRowOfPlane(buffer, 2),//_videoFrame->linesize[2],
                                                     (int)CVPixelBufferGetWidthOfPlane(buffer, 2),//_videoCodecCtx->width / 2,
                                                     (int)CVPixelBufferGetHeightOfPlane(buffer, 2));//_videoCodecCtx->height / 2);
                    
                    CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
                    
                    yuvFrame.position = (CGFloat)presentationTimeStamp.value / (CGFloat)presentationTimeStamp.timescale;
                    yuvFrame.duration = (CGFloat)presentationDuration.value / (CGFloat)presentationDuration.timescale;
                    
                    NSLog(@"decompressBlock: %.3f", (float)presentationTimeStamp.value/presentationTimeStamp.timescale);
                           
                    LoggerVideo(1, @"decompressBlock %.3f", (float)presentationTimeStamp.value/presentationTimeStamp.timescale);
                    
                    //                    if (frame) {
                    [result addObject:yuvFrame];
                    _position = yuvFrame.position;
                    decodedDuration += yuvFrame.duration;
                    if (decodedDuration > minDuration)
                        finished = YES;
                    //                    }
                }];
                //                ///!!!For Debug
                //                NSTimeInterval afterDecode = [NSDate timeIntervalSinceReferenceDate];
                //                totalDecodeTime += (afterDecode - beforeDecode);
                int len = packet.size;///!!!

#else
                int gotframe = 0;
                int len = avcodec_decode_video2(_videoCodecCtx,
                                                _videoFrame,
                                                &gotframe,
                                                &packet);
                
                //NSLog(@"pkt %d len %d", packet.size, len);
                //                ///!!!For Debug
                //                NSTimeInterval afterDecode = [NSDate timeIntervalSinceReferenceDate];
                //                totalDecodeTime += (afterDecode - beforeDecode);
                
                if (len < 0) {
                    LoggerVideo(0, @"decode video error, skip packet");
                    break;
                }
                
                //NSLog(@"gotframe %d",gotframe);
                if (gotframe) {
                    
                    if (!_disableDeinterlacing &&
                        _videoFrame->interlaced_frame) {
                        
                        avpicture_deinterlace((AVPicture*)_videoFrame,
                                              (AVPicture*)_videoFrame,
                                              _videoCodecCtx->pix_fmt,
                                              _videoCodecCtx->width,
                                              _videoCodecCtx->height);
                    }
                    
                    KxVideoFrame *frame = [self handleVideoFrame];
                    //LoggerVideo(1, @"decoded v timestamp %f", frame.timestamp);
                    
                    if (frame) {
                        
                        [result addObject:frame];
                        
                        _position = frame.position;
                        decodedDuration += frame.duration;
                        //NSLog(@"decoded duration %f minDuration %f", decodedDuration, minDuration);
                        if (decodedDuration > minDuration) {
                            //NSLog(@"finished v");
                            finished = YES;
                        }
                    }
                }
#endif
                if (len <= 0)
                    break;
                
                pktSize -= len;
            }
            
        } else if (packet.stream_index == _audioStream) {
            int pktSize = packet.size;
            
            while (pktSize > 0) {
                
                int gotframe = 0;
                int len = avcodec_decode_audio4(_audioCodecCtx,
                                                _audioFrame,
                                                &gotframe,
                                                &packet);
                
                if (len < 0) {
                    LoggerAudio(0, @"decode audio error, skip packet");
                    break;
                }
                
                if (gotframe) {
                    
                    KxAudioFrame * frame = [self handleAudioFrame];
                    if (frame) {
                        
                        [result addObject:frame];
                        
                        if (_videoStream == -1) {
                            
                            _position = frame.position;
                            decodedDuration += frame.duration;
                            if (decodedDuration > minDuration)
                                finished = YES;
                        }
                    }
                }
                
                if (0 == len)
                    break;
                
                pktSize -= len;
            }
        } else if (packet.stream_index == _artworkStream) {
            
            if (packet.size) {
                
                KxArtworkFrame *frame = [[KxArtworkFrame alloc] init];
                frame.picture = [NSData dataWithBytes:packet.data length:packet.size];
                [result addObject:frame];
            }
            
        } else if (packet.stream_index == _subtitleStream) {
            
            int pktSize = packet.size;
            
            while (pktSize > 0) {
                
                AVSubtitle subtitle;
                int gotsubtitle = 0;
                int len = avcodec_decode_subtitle2(_subtitleCodecCtx,
                                                   &subtitle,
                                                   &gotsubtitle,
                                                   &packet);
                
                if (len < 0) {
                    LoggerStream(0, @"decode subtitle error, skip packet");
                    break;
                }
                
                if (gotsubtitle) {
                    
                    KxSubtitleFrame *frame = [self handleSubtitle: &subtitle];
                    if (frame) {
                        [result addObject:frame];
                    }
                    avsubtitle_free(&subtitle);
                }
                
                if (0 == len)
                    break;
                
                pktSize -= len;
            }
        }
        
        av_free_packet(&packet);
    }
    
    //    ///!!!For Debug
    //    totalDecodedDuration += decodedDuration;
    //    float ratio = (totalDecodeTime/totalDecodedDuration);
    //    const float DestRatio = 0.8100;
    //    if (ratio < DestRatio)
    //    {
    //        [NSThread sleepForTimeInterval:(totalDecodedDuration * DestRatio - totalDecodeTime)];
    //    }
    //    NSLog(@"totalDecodeTime / totalDecodedDuration = (%lf / %lf) = %lf", totalDecodeTime, totalDecodedDuration, ratio);///!!!
    
    return result;
}

@end

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

static int interrupt_callback(void *ctx)
{
    //NSLog(@"interrupt_callback");
    if (!ctx)
        return 0;
    __unsafe_unretained KxMovieDecoder *p = (__bridge KxMovieDecoder *)ctx;
    const BOOL r = [p interruptDecoder];
    if (r) LoggerStream(1, @"DEBUG: INTERRUPT_CALLBACK!");
    return r;
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

@implementation KxMovieSubtitleASSParser

+ (NSArray *) parseEvents: (NSString *) events
{
    NSRange r = [events rangeOfString:@"[Events]"];
    if (r.location != NSNotFound) {
        
        NSUInteger pos = r.location + r.length;
        
        r = [events rangeOfString:@"Format:"
                          options:0
                            range:NSMakeRange(pos, events.length - pos)];
        
        if (r.location != NSNotFound) {
            
            pos = r.location + r.length;
            r = [events rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]
                                        options:0
                                          range:NSMakeRange(pos, events.length - pos)];
            
            if (r.location != NSNotFound) {
                
                NSString *format = [events substringWithRange:NSMakeRange(pos, r.location - pos)];
                NSArray *fields = [format componentsSeparatedByString:@","];
                if (fields.count > 0) {
                    
                    NSCharacterSet *ws = [NSCharacterSet whitespaceCharacterSet];
                    NSMutableArray *ma = [NSMutableArray array];
                    for (NSString *s in fields) {
                        [ma addObject:[s stringByTrimmingCharactersInSet:ws]];
                    }
                    return ma;
                }
            }
        }
    }
    
    return nil;
}

+ (NSArray *) parseDialogue: (NSString *) dialogue
                  numFields: (NSUInteger) numFields
{
    if ([dialogue hasPrefix:@"Dialogue:"]) {
        
        NSMutableArray *ma = [NSMutableArray array];
        
        NSRange r = {@"Dialogue:".length, 0};
        NSUInteger n = 0;
        
        while (r.location != NSNotFound && n++ < numFields) {
            
            const NSUInteger pos = r.location + r.length;
            
            r = [dialogue rangeOfString:@","
                                options:0
                                  range:NSMakeRange(pos, dialogue.length - pos)];
            
            const NSUInteger len = r.location == NSNotFound ? dialogue.length - pos : r.location - pos;
            NSString *p = [dialogue substringWithRange:NSMakeRange(pos, len)];
            p = [p stringByReplacingOccurrencesOfString:@"\\N" withString:@"\n"];
            [ma addObject: p];
        }
        
        return ma;
    }
    
    return nil;
}

+ (NSString *) removeCommandsFromEventText: (NSString *) text
{
    NSMutableString *ms = [NSMutableString string];
    
    NSScanner *scanner = [NSScanner scannerWithString:text];
    while (!scanner.isAtEnd) {
        
        NSString *s;
        if ([scanner scanUpToString:@"{\\" intoString:&s]) {
            
            [ms appendString:s];
        }
        
        if (!([scanner scanString:@"{\\" intoString:nil] &&
              [scanner scanUpToString:@"}" intoString:nil] &&
              [scanner scanString:@"}" intoString:nil])) {
            
            break;
        }
    }
    
    return ms;
}

@end

static void FFLog(void* context, int level, const char* format, va_list args) {
    @autoreleasepool {
        //Trim time at the beginning and new line at the end
        NSString* message = [[NSString alloc] initWithFormat: [NSString stringWithUTF8String: format] arguments: args];
        switch (level) {
            case 0:
            case 1:
                LoggerStream(0, @"%@", [message stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]);
                break;
            case 2:
                LoggerStream(1, @"%@", [message stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]);
                break;
            case 3:
            case 4:
                LoggerStream(2, @"%@", [message stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]);
                break;
            default:
                LoggerStream(3, @"%@", [message stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]);
                break;
        }
    }
}

#endif //#ifdef FOR_DOUYIN
