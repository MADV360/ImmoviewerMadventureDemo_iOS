#if (defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0) || ( defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0)
#ifndef _IMAGE_BLENDER_H
#define _IMAGE_BLENDER_H
/*
#include <iostream>
#include <opencv2/opencv.hpp>

#include "opencv2/stitching/detail/autocalib.hpp"
#include "opencv2/stitching/detail/blenders.hpp"
#include "opencv2/stitching/detail/timelapsers.hpp"
#include "opencv2/stitching/detail/camera.hpp"
#include "opencv2/stitching/detail/exposure_compensate.hpp"
#include "opencv2/stitching/detail/matchers.hpp"
#include "opencv2/stitching/detail/motion_estimators.hpp"
#include "opencv2/stitching/detail/seam_finders.hpp"
#include "opencv2/stitching/detail/util.hpp"
#include "opencv2/stitching/detail/warpers.hpp"
#include "opencv2/stitching/warpers.hpp"
//*/
#ifdef MADVPANO_DLL

#ifdef MADVPANO_EXPORTS
#define MADVPANO_API _declspec(dllexport)
#else
#define MADVPANO_API _declspec(dllimport)
#endif

#else // MADVPANO_DLL
#define MADVPANO_API
#endif // MADVPANO_DLL

//*
#ifdef __cplusplus
extern "C" {
#endif
//*/
	MADVPANO_API int blendImage(const char* destJPEGPath, const char* sourceJPEGPath, int halfBlendingWidth = 512);
#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
	MADVPANO_API void blendImageV2(const char* destJPEGPath, const char* sourceJPEGPath, float leftOriginX, float leftOriginY, float rightOriginX, float rightOriginY, float ratio, float yaw, float pitch, float roll);
#endif
//*
#ifdef __cplusplus
}
#endif
//*/
#endif //_IMAGE_BLENDER_H
#endif //#if (defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0) || ( defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0)
