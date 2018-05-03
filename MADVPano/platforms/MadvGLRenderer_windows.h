//
//  MadvGLRenderer_iOS.mm
//  Madv360_v1
//
//  Created by FutureBoy on 4/2/16.
//  Copyright © 2016 Cyllenge. All rights reserved.
//

#ifdef TARGET_OS_WINDOWS

#ifndef MADVGLRENDERER_WINDOWS_H
#define MADVGLRENDERER_WINDOWS_H

#include "MadvGLRenderer.h"
#include "EXIFParser.h"
#include <GL/wglext.h>
#include <atlstr.h>
#include <string>

#ifdef MADVPANO_DLL

#ifdef MADVPANO_EXPORTS
#define MADVPANO_API _declspec(dllexport)
#else
#define MADVPANO_API _declspec(dllimport)
#endif

#else // MADVPANO_DLL
#define MADVPANO_API
#endif // MADVPANO_DLL
/*
#ifdef __cplusplus
extern "C" {
#endif

	MADVPANO_API char* CString2pChar(std::string& strData);

#ifdef __cplusplus
}
#endif
//*/
class MADVPANO_API WGLContext {
public:
	virtual ~WGLContext();

	WGLContext(HWND hWindow, HINSTANCE hInstance, int width, int height);

	void makeCurrent();

	void flush();

	void release();

	static HWND createWindow(int width, int height, HINSTANCE hInstance);

	HWND _hWnd = NULL;
	HDC _hPrevDC = NULL;
	HGLRC _hPrevRC = NULL;
	//HGDIOBJ _hGDIObj = NULL;
	//HBITMAP _hBitmap = NULL;
	HPBUFFERARB _hBuffer = NULL;
	HDC _hpBufDC = NULL;
	HGLRC _pBufGLCtx = NULL;
	
	GLuint _framebuffer = 0;
	GLuint _rendertexture = 0;
	GLuint _depthbuffer = 0;
};

/** 
 *
 */
class MADVPANO_API MadvGLRenderer_windows : public MadvGLRenderer {
public:
	virtual ~MadvGLRenderer_windows();

	MadvGLRenderer_windows(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments);

	static void initialize(const char* resourceDirectoryRoot, HINSTANCE hInstance);

	static std::string cameraOrDefaultLUTDirectory();
	static std::string obtainCameraOrDefaultLUTDirectory();

	static std::string tempVideoLUTDirectory();
	static std::string obtainTempVideoLUTDirectory();

	static std::string tempPhotoLUTDirectory();
	static std::string obtainTempPhotoLUTDirectory();

	static std::string glFilterResourceDirectory();
	static std::string obtainGLFilterResourceDirectory();

	static void renderJPEGToJPEG(const char* destJpegPath, const char* sourcePath, int dstWidth, int dstHeight, bool forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank);

	static void exportJPEGFromMadvJPEG(const char* destJPEGPath, const char* sourceJPEGPath, int filterID, bool enableGyroTransform, HWND hWndForCreatingWGLContext, MVProgressClosure progressClosure = {NULL, NULL});

	static void exportDngFromMadvDNG(const char* destDngPath, const char* sourceDngPath, bool enableGyroTransform, HWND hWndForCreatingWGLContext, MVProgressClosure progressClosure = {NULL, NULL});

	static bool ensureDirectory(const char* directory);

	static void debugJPEGEncode(HWND hWndForCreatingWGLContext, HINSTANCE hInstance);
};

#endif //#ifndef MADVGLRENDERER_WINDOWS_H
#endif //#ifdef TARGET_OS_WINDOWS
