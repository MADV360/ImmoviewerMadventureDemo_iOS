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
@property (readonly, nonatomic, assign) int channels;
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

//cwq 2018/03/16
typedef enum : NSInteger {
    Speed_1x = 0,//4k,
    Speed_1p2x = 1,
    Speed_1p4x = 2,
    Speed_1p8x = 3,
    Speed_2x = 4,
    Speed_4x = 5,
    Speed_8x = 6,
} EnumChangePlaySpeed;
////

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

//cwq 2018/03/16
@property (readwrite, nonatomic) int64_t ori_duration;
@property (readwrite, nonatomic) int ori_den;
@property (readwrite, nonatomic) int ori_a_den;
@property (readwrite, nonatomic) int ori_num;
@property (readwrite, nonatomic) CGFloat ori_fps;
@property (readwrite, nonatomic) CGFloat ori_cNum;
@property (readwrite, nonatomic) BOOL isFirstChangeSpeed;
@property (readwrite, nonatomic)FILE * pAACFile;
////


+ (id) movieDecoderWithContentPath: (NSString *) path
                             error: (NSError **) perror;

- (void) setUsedForEncoder;

- (BOOL) openFile: (NSString *) path
            error: (NSError **) perror;

-(void) closeFile;
-(void) addADTStoPacket: (Byte[]) packet :(int) packetLen;

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

- (UInt32) getOriAudioChannel;
- (FILE *) getAACFilePointer;
- (void) createAACFilePointer:(NSString *) path;
//cwq 2018/03/16
- (void) changePlaySpeed:(EnumChangePlaySpeed)eChangePlaySpeed;
- (CGFloat) getChangeSpeedKeyNum;
- (CGFloat) getOriDuration;
- (CGFloat) getOriFPS;
- (BOOL) getIsFirstChangeSpeed;
- (void) setIsFirstChangeSpeedFalse;

- (BOOL) isCanDoublePlaySpeed;
- (int) getPlaybackSupportedMaxNum: (int)width : (int)height : (float)framerate;
////
@end

@interface KxMovieSubtitleASSParser : NSObject

+ (NSArray *) parseEvents: (NSString *) events;
+ (NSArray *) parseDialogue: (NSString *) dialogue
                  numFields: (NSUInteger) numFields;
+ (NSString *) removeCommandsFromEventText: (NSString *) text;

@end

#endif //#ifndef FOR_DOUYIN
