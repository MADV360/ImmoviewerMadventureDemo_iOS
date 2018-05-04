//
//  MadvUtils.cpp
//  Madv360_v1
//
//  Created by QiuDong on 2017/5/10.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#include "MadvUtils.h"
#include "Log.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <sys/types.h>
#include <sys/stat.h>

#ifdef WIN32
#include <windows.h>
#include <direct.h>
#include <io.h>
#else
#include <unistd.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#endif // !WIN32

#include <cstring>
#include <string>

#ifdef WIN32
#define STRDUP(a) _strdup((a))
#define ACCESS _access
#define MKDIR(a) _mkdir((a))
#define RMDIR(a) _rmdir((a))
#else
#define STRDUP(a) strdup((a))
#define ACCESS access
#define MKDIR(a) mkdir((a), 0755)
#define RMDIR(a) remove((a))
#endif

struct BASE_DIR
{
#ifdef WIN32
    HANDLE dir;
    WIN32_FIND_DATAA file;
    bool eof;
#else
    DIR *dir;
    struct dirent *file;
#endif
    
    bool file_is_dir;
    std::string dir_name;
    std::string file_name;
};

using namespace std;

int copyGyroMatrixFromString(float* matrix, const char* gyroString) {
    int length = 0;
    if (NULL != gyroString)
    {
        length = (int) strlen(gyroString);
    }
    if (NULL == gyroString || 0 >= length)
    {
        
        float identity[] = {1.f, 0.f, 0.f, 0.f, 1.f, 0.f, 0.f, 0.f, 1.f};
        memcpy(matrix, identity, sizeof(float) * 9);
        return 0;
    }
    
    uint8_t* pByte = (uint8_t*) matrix;
    for (int readChars = 0; readChars < length; readChars += 2)
    {
        int value;
        sscanf(gyroString + readChars, "%02x", &value);
        *(pByte++) = value;
    }
//    ALOGE("#GyroThumb# copyGyroMatrixFromString('%s') = [%.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %.5f]", gyroString, matrix[0],matrix[1],matrix[2],matrix[3],matrix[4],matrix[5],matrix[6],matrix[7],matrix[8]);
    return 3;
}
#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
int createDirectories(const char *pDir)
{
	int i = 0;
	int iRet;
	int iLen;
	char* pszDir;

	if (NULL == pDir)
	{
		return 0;
	}

	pszDir = strdup((char*)pDir);
	iLen = strlen(pszDir);

	// 创建中间目录  
	for (i = 0; i < iLen; i++)
	{
		if (pszDir[i] == '\\' || pszDir[i] == '/')
		{
			pszDir[i] = '\0';

			//如果不存在,创建  
			iRet = ACCESS(pszDir, 0);
			if (iRet != 0)
			{
				iRet = MKDIR(pszDir);
				if (iRet != 0)
				{
					return -1;
				}
			}
			//支持linux,将所有\换成/  
			pszDir[i] = '/';
		}
	}

	iRet = MKDIR(pszDir);
	free(pszDir);
	return iRet;
}
#else
int createDirectories(const char* sPathName)
{
    char DirName[256];
    strcpy(DirName, sPathName);
    size_t i, len = strlen(DirName);
    if (DirName[len-1] != '/')
        strcat(DirName, "/");
    
    len = strlen(DirName);
    for (i=1; i<len; i++)
    {
        if (DirName[i] == '/')
        {
            DirName[i] = 0;
            if (access(DirName, 0) != 0)
            {
                if (mkdir(DirName, 0755) == -1)
                {
                    perror("mkdir error");
                    return -1;
                }
            }
            DirName[i] = '/';
        }
    }
    
    return   0;
}
#endif

bool openDirectory(const char* dir_name, BASE_DIR& base_dir)
{
    if (NULL == dir_name || '\0' == dir_name[0])
        return false;
    
    base_dir.dir_name = dir_name;
    if ('/' != *base_dir.dir_name.rbegin())
    {
        base_dir.dir_name += "/";
    }
    
#ifdef WIN32
    base_dir.file_name = base_dir.dir_name + "*";
    base_dir.dir = FindFirstFileA(base_dir.file_name.c_str(), &base_dir.file);
    if (INVALID_HANDLE_VALUE == base_dir.dir) {
        return false;
    }
    base_dir.eof = false;
#else
    base_dir.dir = opendir(dir_name);
    if (NULL == base_dir.dir)
        return false;
    
    base_dir.file = readdir(base_dir.dir);
#endif // WIN32
    
    return true;
}

bool isDirectoryOpened(const BASE_DIR& base_dir)
{
#ifdef WIN32
    return (INVALID_HANDLE_VALUE != base_dir.dir);
#else
    return (NULL != base_dir.dir);
#endif // WIN32
}

void closeDirectory(BASE_DIR& base_dir)
{
    if (!isDirectoryOpened(base_dir))
        return;
    
#ifdef WIN32
    FindClose(base_dir.dir);
    base_dir.dir = INVALID_HANDLE_VALUE;
#else
    closedir(base_dir.dir);
    base_dir.dir = NULL;
#endif // WIN32
}

bool removeDirectory(const char* dir_name)
{
    ALOGE("#removeDirectory# %s\n", dir_name);
    BASE_DIR base_dir;
    
    if (!openDirectory(dir_name, base_dir))
        return false;
    
#ifdef WIN32
    while (!base_dir.eof)
    {
        WIN32_FIND_DATAA file = base_dir.file;
        base_dir.eof = !FindNextFileA(base_dir.dir, &base_dir.file);
        
        if (0 != strcmp(file.cFileName, ".") && 0 != strcmp(file.cFileName, ".."))
        {
            base_dir.file_name = base_dir.dir_name + file.cFileName;
            base_dir.file_is_dir = (0 != (file.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY));
            if (base_dir.file_is_dir)
            {
                removeDirectory(base_dir.file_name.c_str());
                RMDIR(base_dir.file_name.c_str());
            }
            else
            {
                remove(base_dir.file_name.c_str());
            }
        }
    }
#else
    while (NULL != base_dir.file)
    {
        struct dirent* file = base_dir.file;
        base_dir.file = readdir(base_dir.dir);
        
        if (0 != strcmp(file->d_name, ".") && 0 != strcmp(file->d_name, ".."))
        {
            base_dir.file_name = base_dir.dir_name + file->d_name;
            base_dir.file_is_dir = false;
            
            struct stat stat_buf;
            if (-1 != lstat(base_dir.file_name.c_str(), &stat_buf) && 0 != (S_IFDIR & stat_buf.st_mode))
            {
                base_dir.file_is_dir = true;
            }
            if (base_dir.file_is_dir)
            {
                removeDirectory(base_dir.file_name.c_str());
                RMDIR(base_dir.file_name.c_str());
            }
            else
            {
                remove(base_dir.file_name.c_str());
            }
        }
    }
#endif // WIN32
    
    closeDirectory(base_dir);
    RMDIR(base_dir.dir_name.c_str());
    
    return true;
}

void extractLUTFiles(const char* destDirectory, const char* lutBinFilePath, uint32_t fileOffset) {
    ALOGE("#GLRenderLoopState#TempLUT# extractLUTFiles:%s\n", destDirectory);
    ifstream ifs(lutBinFilePath, ios::in | ios::binary);
    //DoctorLog(@"#Bug3763# extractLUTFiles : fileOffset=%u, destDirectory='%s', lutBinFilePath='%s'", fileOffset, destDirectory, lutBinFilePath);
    //    fseek(fp, fileOffset, SEEK_CUR);
    const uint32_t Limit2G = 0x80000000;
    if (fileOffset >= Limit2G)
    {
        uint32_t fileOffsetLeft = fileOffset;
        //        ALOGE("extractLUTFiles : #0 fileOffsetLeft = %u", fileOffsetLeft);
        ifs.seekg(0x40000000, ios::beg);
        ifs.seekg(0x40000000, ios::cur);
        for (fileOffsetLeft -= Limit2G; fileOffsetLeft >= Limit2G; fileOffsetLeft -= Limit2G)
        {
            //            ALOGE("extractLUTFiles : #1 fileOffsetLeft = %u", fileOffsetLeft);
            ifs.seekg(0x40000000, ios::cur);
            ifs.seekg(0x40000000, ios::cur);
        }
        //        ALOGE("extractLUTFiles : #2 fileOffsetLeft = %u", fileOffsetLeft);
        ifs.seekg(fileOffsetLeft, ios::cur);
    }
    else
    {
        ifs.seekg(fileOffset, ios::beg);
    }
    
    uint32_t offsets[8];
    uint32_t sizes[8];
    uint32_t totalSize = 0;
    uint32_t maxSize = 0;
    for (int i=0; i<8; ++i)
    {
        ifs.read((char*)&offsets[i], sizeof(uint32_t));
        ifs.read((char*)&sizes[i], sizeof(uint32_t));
        //DoctorLog(@"#Bug3763# offsets[%d] = %u, sizes[%d] = %u", i,offsets[i], i,sizes[i]);
        if (sizes[i] > maxSize) maxSize = sizes[i];
        totalSize += sizes[i];
    }
    ifs.close();
    //    ALOGV("totalSize = %u", totalSize);
    
    const char* pngFileNames[] = {"/r_x_int.png", "/r_x_min.png",
        "/r_y_int.png", "/r_y_min.png",
        "/l_x_int.png", "/l_x_min.png",
        "/l_y_int.png", "/l_y_min.png"};
    char* pngFilePath = (char*) malloc(strlen(destDirectory) + strlen(pngFileNames[0]) + 1);
    
    uint8_t* pngData = (uint8_t*) malloc(maxSize);
    fstream ofs(lutBinFilePath, ios::out | ios::in | ios::binary);
    if (fileOffset >= Limit2G)
    {
        ofs.seekp(0x40000000, ios::beg);
        ofs.seekp(0x40000000, ios::cur);
        for (fileOffset -= Limit2G; fileOffset >= Limit2G; fileOffset -= Limit2G)
        {
            ofs.seekp(0x40000000, ios::cur);
            ofs.seekp(0x40000000, ios::cur);
        }
        ofs.seekp(fileOffset, ios::cur);
    }
    else
    {
        ofs.seekp(fileOffset, ios::beg);
    }
    
    uint64_t currentOffset = 0;
    for (int i=0; i<8; ++i)
    {
        ofs.seekp(offsets[i] - currentOffset, ios::cur);
        ofs.read((char*)pngData, sizes[i]);
        sprintf(pngFilePath, "%s%s", destDirectory, pngFileNames[i]);
        FILE* fout = fopen(pngFilePath, "wb");
        fwrite(pngData, sizes[i], 1, fout);
        fflush(fout);
        fclose(fout);
        ALOGE("#Bug3763# Written pngData into '%s'\n", pngFilePath);
        currentOffset = offsets[i] + sizes[i];
    }
    ofs.close();
    free(pngData);
    free(pngFilePath);
}

void clearCachedLUT(const char* lutPath) {
    if (NULL == lutPath) return;
    char* lutFilePath = (char*) malloc(strlen(lutPath) + strlen("/lut.png") + 1);
    sprintf(lutFilePath, "%s/lut.png", lutPath);
    remove(lutFilePath);
    free(lutFilePath);
}

#define TempLUTDirectoryPrefix "tmplut"

char* createTempLUTDirectory(const char* parentDirectory, const char* suffix) {
    char* path = (char*) malloc(strlen(parentDirectory) + 18);
    sprintf(path, "%s/%s%s", parentDirectory, TempLUTDirectoryPrefix, suffix);
    createDirectories(path);
    //free(path);
    return path;
}

void deleteIfTempLUTDirectory(const char* directory) {
    ALOGE("#GLRenderLoopState#TempLUT# deleteIfTempLUTDirectory:%s\n", directory);
    if (strstr(directory, TempLUTDirectoryPrefix))
    {
        removeDirectory(directory);
    }
}

#if defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0

#import "sys/utsname.h"
#import <CommonCrypto/CommonDigest.h>

NSString* md5OfData(unsigned char* data, UInt32 length) {
    unsigned char result[16];
    CC_MD5(data, length, result);
    
    char md5str[16 * 2 + 1];
    md5str[16 * 2] = '\0';
    char* pDst = md5str;
    unsigned char* pSrc = result;
    for (int i=0; i<16; ++i)
    {
        sprintf(pDst, "%02x", *pSrc);
        pDst += 2;
        pSrc++;
    }
    
    return [NSString stringWithUTF8String:md5str];
}

NSString* makeTempLUTDirectory(NSString* sourceURI) {
    NSData* sourceURIData = [sourceURI dataUsingEncoding:NSUTF8StringEncoding];
    NSString* suffix = [md5OfData((unsigned char*)sourceURIData.bytes, (uint32_t)sourceURIData.length) substringToIndex:8];
    NSString* docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    char* cstrLutPath = createTempLUTDirectory(docPath.UTF8String, suffix.UTF8String);
    NSString* lutPath = [NSString stringWithUTF8String:cstrLutPath];
    free(cstrLutPath);
    /*
     NSString* lutPath = [NSString stringWithFormat:@"%@%d", [z_Sandbox documentPath:@"tmplut"], rand()];
     NSFileManager* fm = [NSFileManager defaultManager];
     BOOL isDirectory = YES;
     if (![fm fileExistsAtPath:lutPath isDirectory:&isDirectory] || !isDirectory)
     {
     [fm removeItemAtPath:lutPath error:nil];
     [fm createDirectoryAtPath:lutPath withIntermediateDirectories:YES attributes:nil error:nil];
     }//*/
    return lutPath;
}
#endif
