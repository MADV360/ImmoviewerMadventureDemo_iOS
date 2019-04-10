//
//  MadvMP4Boxes.h
//  ISOBMFF
//
//  Created by QiuDong on 2018/8/6.
//  Copyright © 2018年 XS-Labs. All rights reserved.
//

#ifndef MadvMP4Boxes_h
#define MadvMP4Boxes_h

#define MADV_MP4_USERDATA_TAG_TYPE (0x6c747563)    //"cutl"
#define MADV_MP4_USERDATA_MADV (0x7664616d)        //"madv"
#define MADV_MP4_USERDATA_BEAUTY_TYPE (0x72746c66) //"fltr"
#define MADV_MP4_USERDATA_CAMERA_INFO_TYPE (0x66696163) //"caif"
#define MADV_MP4_USERDATA_GPS_TYPE (0x78737067)    //gpsx
#define MADV_MP4_USERDATA_LUT_TYPE (0x7a74756c)    //"lutz";
#define MADV_MP4_USERDATA_GYRO_TYPE (0x64796c74)   //"tlyd"

#define MADV_TAG_MAX_NUMBER 20

typedef struct _USERDATA_TAG_t_
{
    uint32_t timestamp;
    uint32_t duration;
} USERDATA_TAG_t;

//mp4文件user data段的路剪信息
typedef struct _MADV_MP4_USERDATA_TAG_t_
{
    uint32_t size;
    uint32_t type;
    uint32_t num;//路剪tag计数，每个视频最大tag数为20
    USERDATA_TAG_t tag[MADV_TAG_MAX_NUMBER];
}MADV_MP4_USERDATA_TAG_t;

//mp4文件user data段的美颜信息
typedef struct _MADV_MP4_USERDATA_BEAUTY_t_
{
    uint32_t size;
    uint32_t type;
    uint32_t beauty_type;
}MADV_MP4_USERDATA_BEAUTY_t;

typedef struct _MADV_CAMERA_GPS_INFO_s_ {
    uint32_t tick_count;
    uint8_t LatitudeRef[2];
    uint8_t Latitude[24];
    uint8_t LongitudeRef[2];
    uint8_t Longitude[24];
    uint8_t AltitudeRef[2];
    uint8_t Altitude[24];
    char  Reserved[512];
} MADV_CAMERA_GPS_INFO_s;

//mp4文件user data段的GPS信息
typedef struct _MADV_MP4_USERDATA_GPS_t_
{
    uint32_t size;
    uint32_t type;
    MADV_CAMERA_GPS_INFO_s GpsInfo;
}MADV_MP4_USERDATA_GPS_t;

//mp4文件user data段的Lut信息
typedef struct _MADV_MP4_USERDATA_LUT_t_
{
    uint32_t size;
    uint32_t type;
    uint32_t lut;
}MADV_MP4_USERDATA_LUT_t;

//mp4文件gyro data段的信息
typedef struct _MADV_MP4_USERDATA_GYRO_t_
{
    uint32_t size;
    uint32_t type;
    uint32_t gyro;
}MADV_MP4_USERDATA_GYRO_t;

typedef struct _MADV_MP4_CAMERA_INFO_t_
{
    char Date[16];
    char Res[4];
    char SpeedEn[4];
    char reserve[24];
    char DeviceId[16];
    char Version[32];
    char SerialNum[32];
} MADV_MP4_CAMERA_INFO_t;

typedef struct _MADV_MP4_USERDATA_CAMERA_INFO_t_
{
    uint32_t size;
    uint32_t type;
    MADV_MP4_CAMERA_INFO_t CameraInfo;
} MADV_MP4_USERDATA_CAMERA_INFO_t;

//mp4文件的user data
typedef struct _MADV_MP4_USERDATA_t_
{
    uint32_t size;
    uint32_t type;
    MADV_MP4_USERDATA_TAG_t tag;
    MADV_MP4_USERDATA_BEAUTY_t beauty;
    MADV_MP4_USERDATA_CAMERA_INFO_t camerainfo;
    MADV_MP4_USERDATA_GPS_t gps;
    MADV_MP4_USERDATA_LUT_t lut;
}MADV_MP4_USERDATA_t;

#endif /* MadvMP4Boxes_h */
