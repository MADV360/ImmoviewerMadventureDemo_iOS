//
//  EXIFParser.h
//  Madv360_v1
//
//  Created by QiuDong on 2017/1/17.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#ifndef EXIFParser_h
#define EXIFParser_h

#include <stdio.h>
#include <iostream>
#include <stdbool.h>
#include <list>
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX != 0
#elif defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0
#import <Foundation/Foundation.h>
#endif
#include <stdint.h>
//#define EXV_HAVE_STDINT_H
//*
#ifdef __cplusplus
extern "C" {
#endif

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
typedef enum : int {
	StitchTypeFishEye = 0x54590000,
	StitchTypeStitched = 0,
	StitchTypePreserved = 0,
} StitchType;

#define EXIF_PILOT 0xFF
#define EXIF_MARKER 0xE1

// Exif.Image.ExifTag                           0x8769 Long        1  146
#define TAG_SUB_TIFF 0x8769

// Exif.Photo.UserComment                       0x9286 Undefined  36  charset="InvalidCharsetId" h^\244>\302An\2753\350n\277\377\205\265\276Xפ>3\265\276\354\321`?
#define TAG_USER_COMMENT 0x9286

// Exif.Photo.SceneType                         0xa301 Long        1  1415118848
#define TAG_SCENE_TYPE 0xA301

// Exif.Image.Make                              0x010f Ascii      10  MADV
#define TAG_IMAGE_MAKE 0x010f

// Exif.Image.Model                             0x0110 Ascii      10  MJXJ
#define TAG_IMAGE_MODEL 0x0110

// Exif.Photo.FileSource                        0xa300 Long        1  1493172224
#define TAG_FILE_SOURCE 0xa300

#define TAG_DNG_WIDTH  0x0100
#define TAG_DNG_HEIGHT 0x0101
    
#define TAG_DNG_STITCH_LUT 0x9009

#define TAG_LENS_SERIALNUMBER 0xA435
    
#define ExifKeyDateTime "Exif.Photo.DateTimeOriginal"
#define ExifKeyDeviceModel "Exif.Image.Model"
#define ExifKeyMaker "Exif.Image.Make"
#define ExifKeySoftware "Exif.Image.Software"
#define ExifKeyExposureTime "Exif.Photo.ExposureTime" //Rational
#define ExifKeyExposureBiasValue "Exif.Photo.ExposureBiasValue" //Rational
#define ExifKeyISOSpeed "Exif.Photo.ISOSpeed" //Long
#define ExifKeyWhiteBalance "Exif.Photo.WhiteBalance" //Short
#define ExifKeyWidth "Exif.Photo.PixelXDimension" //Long
#define ExifKeyHeight "Exif.Photo.PixelYDimension" //Long
#define ExifKeyXResolution "Exif.Image.XResolution"
#define ExifKeyYResolution "Exif.Image.YResolution"
#define ExifKeyGPSLatitude "Exif.GPSInfo.GPSLatitude" //Rational
#define ExifKeyGPSLongitude "Exif.GPSInfo.GPSLongitude" //Rational
#define ExifKeyGPSAltitude "Exif.GPSInfo.GPSAltitude" //Rational
#define ExifKeyGPSLatitudeRef "Exif.GPSInfo.GPSLatitudeRef" //Ascii
#define ExifKeyGPSLongitudeRef "Exif.GPSInfo.GPSLongitudeRef" //Ascii
#define ExifKeySceneType "Exif.Photo.SceneType"

/*
 Exif.Image.ImageDescription                  0x010e Ascii      64
 Exif.Image.Make                              0x010f Ascii      22  RICOH
 Exif.Image.Model                             0x0110 Ascii      64  RICOH THETA S
 Exif.Image.Orientation                       0x0112 Short       1  1
 Exif.Image.XResolution                       0x011a Rational    1  72/1
 Exif.Image.YResolution                       0x011b Rational    1  72/1
 Exif.Image.ResolutionUnit                    0x0128 Short       1  2
 Exif.Image.Software                          0x0131 Ascii      32  RICOH THETA S Ver 0.71
 Exif.Image.DateTime                          0x0132 Ascii      20  2015:05:19 20:48:00
 Exif.Image.Copyright                         0x8298 Ascii      46
 Exif.Image.ExifTag                           0x8769 Long        1  422
 Exif.Photo.ExposureTime                      0x829a Rational    1  1/30
 
 Exif.Photo.FNumber                           0x829d Rational    1  2/1
 Exif.Photo.ExposureProgram                   0x8822 Short       1  2
 Exif.Photo.ISOSpeedRatings                   0x8827 Short       1  400
 Exif.Photo.SensitivityType                   0x8830 Short       1  1
 Exif.Photo.ExifVersion                       0x9000 Undefined   4  48 50 51 48
 Exif.Photo.DateTimeOriginal                  0x9003 Ascii      20  2015:05:19 20:48:00
 Exif.Photo.DateTimeDigitized                 0x9004 Ascii      20  2015:05:19 20:48:00
 Exif.Photo.ComponentsConfiguration           0x9101 Undefined   4  1 2 3 0
 Exif.Photo.CompressedBitsPerPixel            0x9102 Rational    1  16/5
 Exif.Photo.ApertureValue                     0x9202 Rational    1  2/1
 Exif.Photo.BrightnessValue                   0x9203 SRational   1  -1/10
 Exif.Photo.ExposureBiasValue                 0x9204 SRational   1  0/1
 Exif.Photo.MaxApertureValue                  0x9205 Rational    1  2/1
 Exif.Photo.MeteringMode                      0x9207 Short       1  5
 Exif.Photo.LightSource                       0x9208 Short       1  0
 Exif.Photo.Flash                             0x9209 Short       1  0
 Exif.Photo.FocalLength                       0x920a Rational    1  131/100
 Exif.Photo.UserComment                       0x9286 Undefined 264  charset="Ascii" r=11585[2015.5.15]<nt authority.system>@ZRFG030058              0xa002 Long        1  4096
 Exif.Photo.PixelYDimension                   0xa003 Long        1  2048
 Exif.Photo.ExposureMode                      0xa402 Short       1  0
 Exif.Photo.WhiteBalance                      0xa403 Short       1  0
 Exif.Photo.SceneCaptureType                  0xa406 Short       1  0
 Exif.Photo.Sharpness                         0xa40a Short       1  0
 Exif.Image.GPSTag                            0x8825 Long        1  1120
 Exif.GPSInfo.GPSVersionID                    0x0000 Byte        4  2 3 0 0
 Exif.GPSInfo.GPSImgDirectionRef              0x0010 Ascii       2  T
 Exif.GPSInfo.GPSImgDirection                 0x0011 Rational    1  45/2
 */

/*
 Exif.Image.ImageDescription                  0x010e Ascii       1
 Exif.Image.Make                              0x010f Ascii      10  MADV
 Exif.Image.Model                             0x0110 Ascii      10  MJXJ
 Exif.Image.XResolution                       0x011a Rational    1  72/1
 Exif.Image.YResolution                       0x011b Rational    1  72/1
 Exif.Image.ResolutionUnit                    0x0128 Short       1  2
 Exif.Image.Software                          0x0131 Ascii      36  14079/00000001;1.3.97.85.5.13333
 Exif.Image.DateTime                          0x0132 Ascii      20
 Exif.Image.YCbCrPositioning                  0x0213 Short       1  1
 Exif.Image.ExifTag                           0x8769 Long        1  238
 Exif.Photo.ExposureTime                      0x829a Rational    1  66666/1000000
 Exif.Photo.FNumber                           0x829d Rational    1  200/100
 Exif.Photo.ExposureProgram                   0x8822 Short       1  0
 Exif.Photo.ISOSpeedRatings                   0x8827 Short       1  74
 Exif.Photo.SensitivityType                   0x8830 Short       1  3
 Exif.Photo.ISOSpeed                          0x8833 Long        1  74
 Exif.Photo.ExifVersion                       0x9000 Undefined   4  48 50 51 48
 Exif.Photo.DateTimeOriginal                  0x9003 Ascii      20  2017:07:15 15:56:40
 Exif.Photo.DateTimeDigitized                 0x9004 Ascii      20
 Exif.Photo.ComponentsConfiguration           0x9101 Undefined   4  1 2 3 0
 Exif.Photo.CompressedBitsPerPixel            0x9102 Rational    1  0/0
 Exif.Photo.ShutterSpeedValue                 0x9201 SRational   1  0/0
 Exif.Photo.ApertureValue                     0x9202 Rational    1  0/0
 Exif.Photo.ExposureBiasValue                 0x9204 SRational   1  0/28
 Exif.Photo.MaxApertureValue                  0x9205 Rational    1  0/0
 Exif.Photo.SubjectDistance                   0x9206 Rational    1  0/0
 Exif.Photo.MeteringMode                      0x9207 Short       1  2
 Exif.Photo.LightSource                       0x9208 Short       1  0
 Exif.Photo.Flash                             0x9209 Short       1  0
 Exif.Photo.FocalLength                       0x920a Rational    1  0/0
 Exif.Photo.MakerNote                         0x927c Undefined  64  65 66 77 65 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 64 0 0 0 1 0
 Exif.Photo.UserComment                       0x9286 Undefined  36  charset="InvalidCharsetId" 0\324\321>g\372%\275\266=\277[\365\205\275\240\335\320>2\234\275\312\351h?
 Exif.Photo.FlashpixVersion                   0xa000 Undefined   4  0 0 0 0
 Exif.Photo.ColorSpace                        0xa001 Short       1  66
 Exif.Photo.PixelXDimension                   0xa002 Long        1  3456
 Exif.Photo.PixelYDimension                   0xa003 Long        1  1728
 Exif.Photo.InteroperabilityTag               0xa005 Long        1  988
 Exif.Iop.InteroperabilityIndex               0x0001 Ascii       4  R98
 Exif.Iop.InteroperabilityVersion             0x0002 Undefined   4  48 49 48 48
 Exif.Photo.ExposureIndex                     0xa215 Rational    1  0/0
 Exif.Photo.SensingMethod                     0xa217 Short       1  0
 Exif.Photo.FileSource                        0xa300 Long        1  0
 Exif.Photo.SceneType                         0xa301 Long        1  0
 Exif.Photo.CustomRendered                    0xa401 Short       1  0
 Exif.Photo.ExposureMode                      0xa402 Short       1  0
 Exif.Photo.WhiteBalance                      0xa403 Short       1  0
 Exif.Photo.DigitalZoomRatio                  0xa404 Rational    1  0/0
 Exif.Photo.FocalLengthIn35mmFilm             0xa405 Short       1  0
 Exif.Photo.SceneCaptureType                  0xa406 Short       1  0
 Exif.Photo.GainControl                       0xa407 Short       1  0
 Exif.Photo.Contrast                          0xa408 Short       1  99
 Exif.Photo.Saturation                        0xa409 Short       1  0
 Exif.Photo.Sharpness                         0xa40a Short       1  0
 Exif.Photo.DeviceSettingDescription          0xa40b Undefined   0
 Exif.Photo.SubjectDistanceRange              0xa40c Short       1  0
 Exif.Image.GPSTag                            0x8825 Long        1  1018
 Exif.GPSInfo.GPSVersionID                    0x0000 Byte        4  2 2 0 0
 Exif.GPSInfo.GPSLatitudeRef                  0x0001 Ascii       2
 Exif.GPSInfo.GPSLatitude                     0x0002 Rational    3  385875968/16777216 587202560/16777216 67960832/1677721600
 Exif.Thumbnail.Compression                   0x0103 Short       1  6
 Exif.Thumbnail.XResolution                   0x011a Rational    1  72/1
 Exif.Thumbnail.YResolution                   0x011b Rational    1  72/1
 Exif.Thumbnail.ResolutionUnit                0x0128 Short       1  2
 Exif.Thumbnail.JPEGInterchangeFormat         0x0201 Long        1  1178
 Exif.Thumbnail.JPEGInterchangeFormatLength   0x0202 Long        1  6966
 */
    /*
     type = 1，byte类型，8位无符号整数
     type = 2，ASCII类型，7位ASCII码加1位二进制0，一般存放字符串
     type = 3，Short类型，16位无符号整数
     type = 4，Long类型，32位无符号整数
     type = 5，rational类型，2个Long类型数据，前四个字节表示分子，后四个字节表示分母
     type = 6，SByte类型，8位有符号整数
     type = 7，Undefined，8位
     type = 8，SShort，16位有符号整数
     type = 9，SLong，32位有符号整数
     type = 10，SRational，2个SLong类型数据，前四个字节表示分子，后四个字节表示分母
     type = 11，Float，单精度浮点
     type = 12，Double，双精度浮点
     //*/
    typedef enum : uint8_t {
        DEByte = 1,
        DEString = 2,
        DEShort = 3,
        DELong = 4,
        DERational = 5,
        DESByte = 6,
        DEUndefined = 7,
        DESShort = 8,
        DESLong = 9,
        DESRational = 10,
        DEFloat = 11,
        DEDouble = 12,
    } DEValueType;
    
    typedef struct {
        uint8_t endian[2];
        uint8_t TIFF_ID[2];
        uint8_t TIFF_offset[4];
    } TIFFHeaderRaw;
    
#define SizeOfTIFFHeaderRaw 8
    
    typedef struct {
        bool isBigEndian;
        int16_t TIFF_ID;
        int32_t TIFF_offset;
    } TIFFHeader;
    
    typedef struct {
        uint8_t tag[2];
        uint8_t type[2];
        uint8_t length[4];
        uint8_t valueOrOffset[4];
    } DirectoryEntryRaw;
    
#define SizeOfDirectoryEntryRaw 12
    
    typedef struct {
        uint16_t tag;
        uint16_t type;
        uint32_t length;
        union {
            uint32_t value;
            uint8_t* valueData;
        };
        unsigned long dataOffsetInFile;
    } DirectoryEntry;
    
    typedef struct {
        uint16_t DE_count;
        uint32_t nextIFDOffset;
    } IFDStructMetaData;
    
#define SizeOfIFDStructMetaData 6
    /*
    typedef struct {
        uint16_t length;
        uint8_t reserved[6];
        union {
            struct {
                uint8_t endian[2];
                uint8_t TIFF_ID[2];
                uint8_t TIFF_offset[4];
            };
            TIFFHeaderRaw tiffHeaderRaw;
        };
    } ExifHeaderRaw;
    
    typedef struct {
        int length;
        union {
            struct {
                bool isBigEndian;
                int TIFF_ID;
                int TIFF_offset;
            };
            TIFFHeader tiffHeader;
        };
    } ExifHeader;
    //*/
/////////////////////////////////
    
    typedef struct {
        union {
            uint8_t data[68];
            struct {
                float gyroMatrix[9];
                float leftX;
                float leftY;
                float rightX;
                float rightY;
                float ratio;
                float yaw;
                float pitch;
                float roll;
            };
        };
    } MadvCameraParams;
    
    typedef struct {
        int gyroMatrixBytes;
        int sceneType;
        bool withEmbeddedLUT;
        long embeddedLUTOffset;
        int width;
        int height;
        MadvCameraParams cameraParams;
    } MadvEXIFExtension;
    
    MADVPANO_API bool readTIFF(TIFFHeader* outTIFFHeader, std::list<std::list<DirectoryEntry> >& outIFDList, FILE* fp);
    
    MADVPANO_API void writeTIFF(FILE* fp, TIFFHeader tiffHeader, void* data, uint32_t dataSessionSize, std::list<std::list<DirectoryEntry> >& IFDList);
    
    MADVPANO_API void releaseIFDList(std::list<std::list<DirectoryEntry> >& IFDList);
    
    MADVPANO_API void DirectoryEntryRelease(DirectoryEntry& DE);
    
    MADVPANO_API void printIFDList(std::ostream& outputStream, TIFFHeader tiffHeader, std::list<std::list<DirectoryEntry> >& IFDList);
    
    MADVPANO_API int int16FromBytes(const uint8_t* bytes, bool isBigEndian);
    MADVPANO_API void int16Bytes(uint8_t* bytes, int16_t value, bool isBigEndian);
    
    MADVPANO_API int int32FromBytes(const uint8_t* bytes, bool isBigEndian);
    MADVPANO_API void int32Bytes(uint8_t* bytes, int32_t value, bool isBigEndian);
    
    MADVPANO_API int64_t int64FromBytes(const uint8_t* bytes, bool isBigEndian);
    MADVPANO_API void int64Bytes(uint8_t* bytes, int64_t value, bool isBigEndian);
    
//	MADVPANO_API bool EXIFHeaderReadFromFile(ExifHeader* outExifHeader, IFDEntryList* outEntryList, IFDEntryList* outSubEntryList, const char* jpegPath);

//    int readIFDEntryList(IFDEntryList* outEntryList, const char* jpegPath);
    
//    MADVPANO_API void IFDEntryListPrint(IFDEntryList* entryList);
//    MADVPANO_API void IFDEntryPrint(IFDEntry* entry);
//
//    MADVPANO_API void IFDEntryRelease(IFDEntry* entry);
//
//    MADVPANO_API bool IFDEntryListInit(IFDEntryList* entryList);
//    MADVPANO_API void IFDEntryListRelease(IFDEntryList* entryList);

	MADVPANO_API MadvEXIFExtension readMadvEXIFExtensionFromJPEG(const char* jpegPath);
	MADVPANO_API int readGyroDataFromJPEG(float* outMatrixData, const char* jpegPath);
	MADVPANO_API int readSceneTypeFromJPEG(const char* jpegPath);
    
    MADVPANO_API MadvEXIFExtension readMadvEXIFExtensionFromRaw(const char* rawPath, TIFFHeader* outTIFFHeader, std::list<std::list<DirectoryEntry> >& outIFDList);
    
	MADVPANO_API int readExtensionFromFile(void** pOutData, const char* filePath);
    
	MADVPANO_API long readLUTOffsetInJPEG(const char* jpegPath);
    
	MADVPANO_API void writeExtensionToFile(const char* filePath, const void* data, int32_t length);
    
	MADVPANO_API int exifPrint(const char* imagePath, std::ostream& output);
    
	MADVPANO_API void copyEXIFData(const char* destImagePath, const char* sourceImagePath);
    
	MADVPANO_API bool setXmpGPanoPacket(const char* imagePath);
    
	MADVPANO_API void setEXIFFileSource(const char* destImagePath, const char* sourceImagePath);
    
	MADVPANO_API long createExivImage(const char* sourceImagePath);

	MADVPANO_API void releaseExivImage(long exivImageHandler);

	MADVPANO_API void copyEXIFDataFromExivImage(const char* destImagePath, long sourceExivImageHandler);

	MADVPANO_API void exivImageEraseGyroData(long exivImageHandler);

	MADVPANO_API void exivImageEraseSceneType(long exivImageHandler);

	MADVPANO_API void exivImageEraseFileSource(long exivImageHandler);

	MADVPANO_API void exivImageSaveMetaData(long exivImageHandler);

#pragma mark    EXIFDataBundle

class MADVPANO_API EXIFDataBundle {
public:
    
    virtual ~EXIFDataBundle();
    
    EXIFDataBundle(const char* jpegPath);
    
    std::string getStringValue(const char* key, int index=0);
    
    long getLongValue(const char* key, int index=0);
    
    int getShortValue(const char* key, int index=0);
    
    std::pair<int32_t, int32_t> getRationalValue(const char* key, int index=0);
    
    std::string getRationalString(const char* key, int index=0);
    std::string getRationalStringFraction(const char* key, int index=0);
    std::string getRationalStringDecimal(const char* key, int index=0);
    
    float getRationalFloatValue(const char* key, int index=0);
    
    float getGPSCoordinate(const char* key);
    
    inline std::string getDateTime() {return getStringValue(ExifKeyDateTime);}
    
    inline std::string getMaker() {return getStringValue(ExifKeyMaker);}
    
    inline std::string getDeviceModel() {return getStringValue(ExifKeyDeviceModel);}
    
    inline std::string getExposureTime() {return getRationalStringFraction(ExifKeyExposureTime);}
    
    inline std::string getExposureBiasValue() {return getRationalStringDecimal(ExifKeyExposureBiasValue);}
    
    inline long getISOSpeed() {return getLongValue(ExifKeyISOSpeed);}
    
    inline int getWhiteBalance() {return getShortValue(ExifKeyWhiteBalance);}
    
    inline int getXDimension() {return (int)getLongValue(ExifKeyWidth);}
    inline int getYDimension() {return (int)getLongValue(ExifKeyHeight);}
    
    inline float getXResolution() {return getRationalFloatValue(ExifKeyXResolution);}
    inline float getYResolution() {return getRationalFloatValue(ExifKeyYResolution);}
    
    inline float getLongitude() {return getGPSCoordinate(ExifKeyGPSLongitude);}
    inline float getLatitude() {return getGPSCoordinate(ExifKeyGPSLatitude);}
    inline float getAltitude() {return getGPSCoordinate(ExifKeyGPSAltitude);}
    inline std::string getLatitudeRef() {return getStringValue(ExifKeyGPSLatitudeRef);}
    inline std::string getLongitudeRef() {return getStringValue(ExifKeyGPSLongitudeRef);}
    
    inline bool isStitchedPicture() {return 0 == getLongValue(ExifKeySceneType);}
    
private:
    
    void* _impl;
};
//*
#ifdef __cplusplus
}
#endif
//*/
#endif /* EXIFParser_h */
