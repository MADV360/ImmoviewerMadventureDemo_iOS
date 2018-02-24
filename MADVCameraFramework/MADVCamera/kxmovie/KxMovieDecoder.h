//
//  KxMovieDecoder.h
//  kxmovie
//
//  Created by Kolyvan on 15.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#ifndef FOR_DOUYIN

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>

@class UIImage;

extern NSString * kxmovieErrorDomain;

typedef enum {
    
    kxMovieErrorNone,
    kxMovieErrorOpenFile,
    kxMovieErrorStreamInfoNotFound,
    kxMovieErrorStreamNotFound,
    kxMovieErrorCodecNotFound,
    kxMovieErrorOpenCodec,
    kxMovieErrorAllocateFrame,
    kxMovieErroSetupScaler,
    kxMovieErroReSampler,
    kxMovieErroUnsupported,
    
} kxMovieError;

typedef enum {
    
    KxMovieFrameTypeAudio,
    KxMovieFrameTypeVideo,
    KxMovieFrameTypeArtwork,
    KxMovieFrameTypeSubtitle,
    
} KxMovieFrameType;

typedef enum {
    
    KxVideoFrameFormatRGB,
    KxVideoFrameFormatYUV,
    KxVideoFrameFormatCVBuffer, //core video buffer format by spy
    
} KxVideoFrameFormat;

typedef struct _MADV_MP4_CAMERA_INFO_t_
{
        char Date[16];
        char Res[32]; //视频分辨率id，以字符串形式保存
        char DeviceId[16];
        char Version[32];
} MADV_MP4_CAMERA_INFO_t;

@interface KxMovieFrame : NSObject
@property (readonly, nonatomic) KxMovieFrameType type;
@property (readonly, nonatomic) CGFloat position;
@property (readonly, nonatomic) CGFloat duration;
@property (readwrite, nonatomic) CGFloat timestamp;//2016.12.1 chen
@end

@interface KxAudioFrame : KxMovieFrame
@property (readonly, nonatomic, strong) NSData *samples;
@end

@interface KxVideoFrame : KxMovieFrame
@property (readonly, nonatomic) KxVideoFrameFormat format;
@property (readonly, nonatomic) NSUInteger width;
@property (readonly, nonatomic) NSUInteger height;
@property (nonatomic, strong) NSData* gyroData;
@property (nonatomic, assign) NSInteger frameNumber;
@end

@interface KxVideoFrameRGB : KxVideoFrame
@property (readonly, nonatomic) NSUInteger linesize;
@property (nonatomic, strong) NSData *rgb;
//- (UIImage *) asImage;
@end

@interface KxVideoFrameYUV : KxVideoFrame
@property (nonatomic, strong) NSData *luma;
@property (nonatomic, strong) NSData *chromaB;
@property (nonatomic, strong) NSData *chromaR;
@end

//ios vt decoder frame by spy
@interface KxVideoFrameCVBuffer : KxVideoFrame
@property (readwrite, nonatomic) CVBufferRef cvBufferRef;//2016.3.3 spy

- (void) releasePixelBuffer;
@end


@interface KxArtworkFrame : KxMovieFrame
@property (readonly, nonatomic, strong) NSData *picture;
- (UIImage *) asImage;
@end

@interface KxSubtitleFrame : KxMovieFrame
@property (readonly, nonatomic, strong) NSString *text;
@end

@interface KxAVPacket : NSObject
@end

typedef BOOL(^KxMovieDecoderInterruptCallback)();

@interface KxMovieDecoder : NSObject

@property (readonly, nonatomic, strong) NSString *path;
@property (readonly, nonatomic) BOOL isEOF;
@property (readwrite,nonatomic) CGFloat position;
@property (readwrite,nonatomic) CGFloat positionAudio;
@property (readonly, nonatomic) CGFloat duration;
@property (readonly, nonatomic) CGFloat fps;
@property (readonly, nonatomic) CGFloat sampleRate;
@property (readonly, nonatomic) NSUInteger frameWidth;
@property (readonly, nonatomic) NSUInteger frameHeight;
@property (readonly, nonatomic) NSUInteger audioStreamsCount;
@property (readwrite,nonatomic) NSInteger selectedAudioStream;
@property (readonly, nonatomic) NSUInteger subtitleStreamsCount;
@property (readwrite,nonatomic) NSInteger selectedSubtitleStream;
@property (readonly, nonatomic) BOOL validVideo;
@property (readonly, nonatomic) BOOL validAudio;
@property (readonly, nonatomic) BOOL validSubtitles;
@property (readonly, nonatomic, strong) NSDictionary *info;
@property (readonly, nonatomic, strong) NSString *videoStreamFormatName;
@property (readonly, nonatomic) BOOL isNetwork;
@property (readonly, nonatomic) BOOL isRTSPPreview;
@property (readonly, nonatomic) BOOL isRTSPLive;
@property (readonly, nonatomic) CGFloat startTime;
@property (readwrite, nonatomic) BOOL disableDeinterlacing;
@property (readwrite, nonatomic, strong) KxMovieDecoderInterruptCallback interruptCallback;
@property (readwrite, nonatomic) CGFloat minDuration;
@property (readwrite, nonatomic) CGFloat maxDuration;

+ (id) movieDecoderWithContentPath: (NSString *) path
                             error: (NSError **) perror;

- (void) setUsedForEncoder;

- (BOOL) openFile: (NSString *) path
            error: (NSError **) perror;

-(void) closeFile;

- (BOOL) setupVideoFrameFormat: (KxVideoFrameFormat) format;
- (KxVideoFrameFormat) getVideoFrameFormat;
- (int64_t) getLutzOffset;
- (int64_t) getLutzSize;
- (uint8_t*) getGyroData;
- (int) getGyroSize;
- (int) getGyroSizePerFrame;
- (int) getDispMode;
- (int) getCutCount;
- (int) getCutSizePerPoint;
- (uint8_t*) getCutData;
- (uint8_t*) getGpsxData;
- (uint8_t*) getCaifData;
- (int) getGpsxSize;
- (int) getCaifSize;
- (int) getVideoCaptureResolutionID;
- (boolean_t) isMadVContent;
- (boolean_t) isShareBitrateContent;
- (boolean_t) isTimeElapsedVideo;
- (int64_t) getMoovBoxSizeOffset;
- (int64_t) getVideoTrakBoxSizeOffset;
- (int64_t) getVideoTrakBoxEndOffset;

- (NSArray *) decodeFrames: (CGFloat) minDuration;
- (boolean_t) readPackets: (CGFloat) minDuration;
- (void) setBufferDuration: (CGFloat) minDuration maxDuration: (CGFloat)maxDuration;
- (CGFloat) getBufferedPacketDuration;
- (int) getBufferedPacketCount;

@end

@interface KxMovieSubtitleASSParser : NSObject

+ (NSArray *) parseEvents: (NSString *) events;
+ (NSArray *) parseDialogue: (NSString *) dialogue
                  numFields: (NSUInteger) numFields;
+ (NSString *) removeCommandsFromEventText: (NSString *) text;

@end

#endif //#ifndef FOR_DOUYIN
