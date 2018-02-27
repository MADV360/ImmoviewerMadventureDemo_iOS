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

#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
#include <direct.h>
#include <io.h>
#define ACCESS _access  
#define MKDIR(a) _mkdir((a))
#else
#include <unistd.h>
#endif

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
void extractLUTFiles(const char* destDirectory, const char* lutBinFilePath, uint32_t fileOffset) {
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
