//
// Created by admin on 16/8/24.
//

#ifndef APP_ANDROID_IMAGECODEC_H
#define APP_ANDROID_IMAGECODEC_H

//*
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

#ifdef __cplusplus
extern "C" {
#endif

/******************************图片数据*********************************/
typedef struct _pic_data
{
    int width, height; /* 尺寸 */
    int bit_depth;  /* 位深 */
    int channels; /* 多少个颜色通道 */
    int flag;   /* 一个标志，表示是否有alpha通道 */

    unsigned char **rgba; /* 图片数组 */
} pic_data;
/**********************************************************************/

	MADVPANO_API int decodePNG(const char *filepath, pic_data *out);

	MADVPANO_API int encodePNG(const char* filename, unsigned char* pixels, int w, int h, int bitdepth);

	MADVPANO_API int createTextureFromPNG(const char* pngPath);
    
#ifdef __cplusplus
}
#endif

#endif //APP_ANDROID_IMAGECODEC_H
