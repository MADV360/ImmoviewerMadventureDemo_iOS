//
//  MadvUtils.hpp
//  Madv360_v1
//
//  Created by QiuDong on 2017/5/10.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#ifndef MadvUtils_hpp
#define MadvUtils_hpp

#include <inttypes.h>

#ifdef MADVPANO_DLL

#ifdef MADVPANO_EXPORTS
#define MADVPANO_API _declspec(dllexport)
#else
#define MADVPANO_API _declspec(dllimport)
#endif

#else

#define MADVPANO_API

#endif

#ifdef __cplusplus
extern "C" {
#endif

	MADVPANO_API int copyGyroMatrixFromString(float* matrix, const char* gyroString);

	MADVPANO_API int createDirectories(const char* sPathName);
    
	MADVPANO_API bool removeDirectory(const char* pDir);
    
	MADVPANO_API void extractLUTFiles(const char* destDirectory, const char* lutBinFilePath, uint32_t fileOffset);
    
	MADVPANO_API void clearCachedLUT(const char* lutPath);
    
    MADVPANO_API char* createTempLUTDirectory(const char* parentDirectory, const char* suffix);
    
    MADVPANO_API void deleteIfTempLUTDirectory(const char* directory);
    
#ifdef __cplusplus
}
#endif

#if defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0
#import <Foundation/Foundation.h>
NSString* makeTempLUTDirectory(NSString* sourceURI);
#endif

#endif /* MadvUtils_hpp */
