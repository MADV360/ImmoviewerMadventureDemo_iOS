//
//  MadvGLRenderer_iOS.mm
//  Madv360_v1
//
//  Created by FutureBoy on 4/2/16.
//  Copyright © 2016 Cyllenge. All rights reserved.
//

#ifdef TARGET_OS_WINDOWS

#include "MadvGLRenderer_windows.h"
#include "MadvGLRendererImpl.h"
#include "MadvUtils.h"
#include "OpenGLHelper.h"
#include "GLRenderTexture.h"
#include "GLFilterCache.h"
#include "JPEGUtils.h"
#include "Log.h"
//#include "../Device/CCameraDetect.h"
#include <windows.h>
#include <gl/gl.h>
#include <gl/glext.h> 
#include <gl/glu.h>
#include <fstream>
#include <string>
#include <stdio.h>
#include "Resource.h"

#define RESOURCE_DIRECTORY_ROOT "C:\\MADVPano\\res\\"
#define DEFAULT_LUT_DIR "defaultlut\\"
#define TEMP_VID_LUT_DIR "tmplut_vid\\"
#define TEMP_PIC_LUT_DIR "tmplut_pic\\"
#define GLFILTER_RESOURCE_DIR "filters\\"
/*
#define LUT_DIR "/lut/"
#define TEMP_VID_LUT_DIR "C:\\Madv360\\tmplut\\"
#define TEMP_PIC_LUT_DIR "C:\\Madv360\\tmplut_pic\\"
#define GLFILTER_RESOURCE_DIR "/filters/"
//*/
///!!!#define USE_IMAGE_BLENDER

#ifdef USE_IMAGE_BLENDER
#include "ImageBlender.h"
#endif

static std::string s_resourceRootDirectory = "C:\\MADVPano\\res\\";
static HINSTANCE s_hInstance = NULL;

//#define RENDER_TO_BITMAP

char* string2lpStr(std::string& str) {
	return (char*)str.c_str();
}

/*
char* CString2pChar(CString strData)
{
	int nLength = strData.GetLength();
	//宽字符(unicode)转换为多字节(char*),首先获取长度  
	int nBytes = WideCharToMultiByte(CP_ACP, 0, strData, nLength, NULL, 0, NULL, NULL);
	char* VoicePath = new char[nBytes + 1];
	memset(VoicePath, 0, nLength + 1);
	//真正进行转换  
	WideCharToMultiByte(CP_OEMCP, 0, strData, nLength, VoicePath, nBytes, NULL, NULL);
	VoicePath[nBytes] = 0;
	return VoicePath;
}
//*/

void MadvGLRenderer_windows::initialize(const char* resourceDirectoryRoot, HINSTANCE hInstance) {
	s_resourceRootDirectory = resourceDirectoryRoot;
	s_hInstance = hInstance;
	obtainCameraOrDefaultLUTDirectory();
	obtainTempPhotoLUTDirectory();
	obtainTempVideoLUTDirectory();
	std::string filterResourceDirectory = obtainGLFilterResourceDirectory();
	const char* dstFilenames[] = { "lookup.png", "lookup_soft_elegance_1.png", "lookup_soft_elegance_2.png", "lookup_miss_etikate.png", "lookup_amatorka.png" };
	int resourceIDs[] = { IDB_LOOKUP_PNG, IDB_LOOKUP_SOFT_ELEGANCE_1_PNG, IDB_LOOKUP_SOFT_ELEGANCE_2_PNG, IDB_LOOKUP_MISS_ETIKATE_PNG, IDB_LOOKUP_AMATORKA_PNG };
	const char* dstFilename = NULL;
	for (int i = sizeof(resourceIDs) / sizeof(resourceIDs[0]) - 1; i >= 0; --i)
	{
		std::string cstrFilename = filterResourceDirectory + dstFilenames[i];
		//if (NULL != dstFilename) delete[] dstFilename;
		dstFilename = string2lpStr(cstrFilename);
		int resourceID = resourceIDs[i];
		
		WIN32_FIND_DATAA wfd;
		HANDLE hFind = FindFirstFileA(dstFilename, &wfd);
		if (INVALID_HANDLE_VALUE == hFind)
		{
			HRSRC hRes = FindResource(s_hInstance, MAKEINTRESOURCE(resourceID), TEXT("PNG"));
			if (NULL == hRes)
				continue;
			DWORD dwSize = SizeofResource(s_hInstance, hRes);
			if (0 == dwSize)
				continue;
			HGLOBAL hGlobal = LoadResource(s_hInstance, hRes);
			if (NULL == hGlobal)
				continue;
			const uint8_t* pBuffer = static_cast<const uint8_t*> (LockResource(hGlobal));
			if (NULL == pBuffer)
				continue;
			
			FILE* fp = fopen(dstFilename, "wb+");
			fwrite(pBuffer, dwSize, 1, fp);
			fclose(fp);

			UnlockResource(hGlobal);

			CloseHandle(hFind);
		}
	}
	//if (NULL != dstFilename) delete[] dstFilename;
}

LRESULT CALLBACK window_proc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	LRESULT  ret = 0;
	//*
	switch (msg)
	{
	case WM_CREATE:
	{
		//g_windows_hwnd = hWnd;//保存窗口句柄  
	}
	break;
	case WM_PAINT:
	{
	}
	break;
	case WM_DESTROY:
	{
		::PostQuitMessage(0);
		ALOGE("\nMadvGLRenderer_windows $ window_proc() : PostQuitMessage\n");
	}
	break;
	default:
		ret = ::DefWindowProc(hWnd, msg, wParam, lParam);
		break;
	}
	//*/
	return ret;
}
HWND WGLContext::createWindow(int width, int height, HINSTANCE hInstance) {
	WNDCLASS wndclass;
	HWND hwnd;
	MSG msg;

	///!!!For Debug:
	//width = 8192;
	//height = 4096;

	wndclass.style = CS_HREDRAW || CS_VREDRAW;
	wndclass.lpfnWndProc = window_proc;
	wndclass.cbClsExtra = 0;
	wndclass.cbWndExtra = 0;
	wndclass.hInstance = hInstance;///!!! AfxGetInstanceHandle();
	wndclass.hIcon = LoadIcon(NULL, IDI_APPLICATION);
	wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
	wndclass.hbrBackground = (HBRUSH)COLOR_WINDOW;
	wndclass.lpszMenuName = NULL;
	wndclass.lpszClassName = TEXT("BackgroundOpenGLWindow");
	/*
	if (!RegisterClass(&wndclass))         //此为注册类的函数
	{
		return NULL;    //注册不成功,返回false
	}
	/*/
	RegisterClass(&wndclass);
	//*/
	hwnd = CreateWindow(TEXT("BackgroundOpenGLWindow"), L"BackgroundOpenGLWindow", WS_OVERLAPPEDWINDOW, 0, 0, width, height, NULL, NULL, wndclass.hInstance, NULL);
	/*
	hwnd = CreateWindowA("BackgroundOpenGLWindow",     //窗口类名为"Windows窗口创建"
		"BackgroundOpenGLWindow",   //窗口的名称为“Windows窗口创建”，即窗口标题栏显示的窗口名称
		WS_OVERLAPPEDWINDOW, //重叠式窗口
		CW_USEDEFAULT, CW_USEDEFAULT,    //窗口左上角在屏幕上的默认位置
		width, height,    //窗口的宽度和高度
		NULL,      //窗口无父类窗口
		NULL,      //窗口无主菜单
		wndclass.hInstance,        //创建此窗口的实例句柄
		NULL        //此窗口无创建参数
		);
		//*/
	return hwnd;
	/*
	ShowWindow(hwnd, nCmdShow); //显示窗口
	UpdateWindow(hwnd);          //不断的更新窗口的客户区

	while (GetMessage(&msg, NULL, 0, 0))    //捕获消息
	{
		TranslateMessage(&msg);              //键盘消息转换
		DispatchMessage(&msg);               //派送消息给窗口函数
	}
	returnmsg.wParam;       //返回退出值
}
//*/
}

WGLContext::~WGLContext() {
	release();
}

WGLContext::WGLContext(HWND hWindow, HINSTANCE hInstance, int width, int height) {
	//wglMakeCurrent(NULL, NULL);
	HDC prevDC = wglGetCurrentDC();
#ifndef RENDER_TO_BITMAP
	//HWND hDesktopWindow = GetDesktopWindow();
	//*pDC = wglGetCurrentDC();
	if (hWindow)
		_hDC = GetDC(hWindow);
	else
	{
		_hWnd = createWindow(width, height, hInstance); ///!!! GetDesktopWindow(); ///!!! 
		_hDC = GetDC(_hWnd);
	}
	//GetDesktopWindow());
#else
	// Ref: http://blog.csdn.net/sin_geek/article/details/38750357
	hDC = CreateCompatibleDC(0);
	if (NULL == hDC)
	{
		ALOGE("Could not create memory device context");
	}
	// Create a bitmap compatible with the DC  
	// must use CreateDIBSection(), and this means all pixel ops must be synchronised  
	// using calls to GdiFlush() (see CreateDIBSection() docs)  
	BITMAPINFO bmi = {
		{ sizeof(BITMAPINFOHEADER), width, height, 1, 32, BI_RGB, 0, 0, 0, 0, 0 },
		{ 0 }
	};
	unsigned char *pbits; // pointer to bitmap bits  
	hBitmap = CreateDIBSection(hDC, &bmi, DIB_RGB_COLORS, (void **)&pbits, 0, 0);
	//HDC hdcScreen = GetDC(0);  
	//m_hBitmap = CreateCompatibleBitmap(m_hDC, width, height);  
	if (NULL == hBitmap)
	{
		ALOGE("Could not create bitmap");
	}

	// Select the bitmap into the DC  
	hGDIObj = SelectObject(hDC, hBitmap);
	if (NULL == hGDIObj)
	{
		ALOGE("Could not select bitmap into DC");
	}

	// Choose the pixel format  
	PIXELFORMATDESCRIPTOR pfd = {
		sizeof(PIXELFORMATDESCRIPTOR), // struct size  
		1, // Version number  
		PFD_DRAW_TO_BITMAP | PFD_SUPPORT_OPENGL, // use OpenGL drawing to BM  
		PFD_TYPE_RGBA, // RGBA pixel values  
		24, // color bits  
		0, 0, 0, // RGB bits shift sizes...  
		0, 0, 0, // Don't care about them  
		0, 0, // No alpha buffer info  
		0, 0, 0, 0, 0, // No accumulation buffer  
		0, // depth buffer bits  
		0, // No stencil buffer  
		0, // No auxiliary buffers  
		PFD_MAIN_PLANE, // Layer type  
		0, // Reserved (must be 0)  
		0, // No layer mask  
		0, // No visible mask  
		0, // No damage mask  
	};
	int pfid = ChoosePixelFormat(hDC, &pfd);
	if (pfid == 0)
	{
		ALOGE("Pixel format selection failed");
	}

	// Set the pixel format  
	// - must be done *after* the bitmap is selected into DC  
	BOOL b = SetPixelFormat(hDC, pfid, &pfd);
	if (!b)
	{
		ALOGE("Pixel format set failed");
	}
#endif
	//ALOGE("#CMp4Join# (@%lx) InitGLComponents : m_hDC = %lx", (long)this, (long)m_hDC);

#ifdef RENDER_TO_BITMAP
	///m_hRC = wglGetCurrentContext();
	// Create the OpenGL resource context (RC) and make it current to the thread  
	hRC = wglCreateContext(hDC);
	if (NULL == hRC)
	{
		ALOGE("OpenGL resource context creation failed");
	}
	//wglMakeCurrent(hDC, hRC);
	//ALOGE("#CMp4Join# (@%lx) InitGLComponents : #0 m_hRC = %lx", (long)this, (long)m_hRC);
#else
	PIXELFORMATDESCRIPTOR pfd;
	memset(&pfd, 0, sizeof(PIXELFORMATDESCRIPTOR));
	pfd.nVersion = 1;
	pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
	pfd.cColorBits = 32;
	pfd.cDepthBits = 0;///!!! 16;
	pfd.cStencilBits = 0;
	pfd.iPixelType = PFD_TYPE_RGBA;
	pfd.iLayerType = PFD_MAIN_PLANE;
	pfd.dwFlags = PFD_SUPPORT_OPENGL;///!!! | PFD_DOUBLEBUFFER | PFD_DRAW_TO_WINDOW;

	int pixelFormat = ChoosePixelFormat(_hDC, &pfd);
	SetPixelFormat(_hDC, pixelFormat, &pfd);

	HGLRC prevHRC = wglGetCurrentContext();
	_hRC = wglCreateContext(_hDC);
	wglMakeCurrent(_hDC, _hRC);
	if (0 == _framebuffer)
	{
		GLint prevFramebuffer, prevRenderbuffer, prevTexture;
		glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFramebuffer);
		glGetIntegerv(GL_RENDERBUFFER_BINDING, &prevRenderbuffer);
		glGetIntegerv(GL_TEXTURE_BINDING_2D, &prevTexture);
		CHECK_GL_ERROR();
		glGenFramebuffers(1, &_framebuffer);
		glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
		CHECK_GL_ERROR();
		glGenTextures(1, &_rendertexture);
		glBindTexture(GL_TEXTURE_2D, _rendertexture);
		CHECK_GL_ERROR();
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST//GL_LINEAR_MIPMAP_LINEAR
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
		CHECK_GL_ERROR();
		glPixelStorei(GL_PACK_ALIGNMENT, 4);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
		CHECK_GL_ERROR();
		//glFramebufferRenderbuffer(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _rendertexture, 0);
		CHECK_GL_ERROR();
		glGenRenderbuffers(1, &_depthbuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, _depthbuffer);
		CHECK_GL_ERROR();
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
		CHECK_GL_ERROR();
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthbuffer);
		//*/
		GLuint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
		if (GL_FRAMEBUFFER_COMPLETE != status)
		{
			ALOGE("\nError in framebuffer setup: 0x%x\n", status);
			CHECK_GL_ERROR();
		}

		glBindFramebuffer(GL_FRAMEBUFFER, prevFramebuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, prevRenderbuffer);
		glBindTexture(GL_TEXTURE_2D, prevTexture);
	}

	wglMakeCurrent(prevDC, prevHRC);
	//ALOGE("#CMp4Join# (@%lx) InitGLComponents : #1 m_hRC = %lx", (long)this, (long)m_hRC);
	//setup opengl context complete
#endif
}

void WGLContext::makeCurrent() {
	wglMakeCurrent(_hDC, _hRC);
	glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
}

void WGLContext::flush() {
	GdiFlush();
}

void WGLContext::release() {
	// Clean up
	makeCurrent();
	glDeleteTextures(1, &_rendertexture);
	glDeleteRenderbuffers(1, &_depthbuffer);
	glDeleteFramebuffers(1, &_framebuffer);

	wglMakeCurrent(NULL, NULL);
	if (_hRC)
	{
		wglDeleteContext(_hRC); // Delete RC
		_hRC = NULL;
	}
	if (_hGDIObj)
	{
		SelectObject(_hDC, _hGDIObj); // Remove bitmap from DC  
		if (_hBitmap) DeleteObject(_hBitmap); // Delete bitmap  
		if (_hDC) DeleteDC(_hDC); // Delete DC

		_hDC = NULL;
		_hGDIObj = NULL;
		_hBitmap = NULL;
	}
	if (_hWnd)
	{
		ALOGE("\nMadvGLRenderer_windows $ WGLContext::release() : SendMessage\n");
		SendMessage(_hWnd, WM_DESTROY, 0, 0);
		_hWnd = NULL;
	}
}

#include <direct.h>
#include <io.h>
#define ACCESS _access  
#define MKDIR(a) _mkdir((a))

int CreateDirs(const char *pDir)
{
	int i = 0;
	int iRet;
	int iLen;
	char* pszDir;

	if (NULL == pDir)
	{
		return 0;
	}

	pszDir = strdup((char*) pDir);
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

using namespace std;

MadvGLRenderer_windows::~MadvGLRenderer_windows() {
}

MadvGLRenderer_windows::MadvGLRenderer_windows(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments)
	: MadvGLRenderer(lutPath, leftSrcSize, rightSrcSize, longitudeSegments, latitudeSegments)
{
    //prepareLUT(lutPath, leftSrcSize, rightSrcSize);
}

bool MadvGLRenderer_windows::ensureDirectory(const char* directory) {
	return 0 != CreateDirs(directory);
	//std::string strDir = directory;
	//std::string strCmd = "mkdir -p \"" + strDir + std::string("\"");
	//return (0 == system(strCmd.c_str()));
}

std::string MadvGLRenderer_windows::cameraOrDefaultLUTDirectory() {
	//CString AppPath = _T("///!!!For Debug");///!!!CMijiaCameraDevice::getAppPath();
	//AppPath.Replace(_T("\\"), _T("/"));
	//return AppPath + LUT_DIR;
	return s_resourceRootDirectory + DEFAULT_LUT_DIR;
}

std::string MadvGLRenderer_windows::obtainCameraOrDefaultLUTDirectory() {
	std::string directory = cameraOrDefaultLUTDirectory();
	char* cstrDirectory = string2lpStr(directory);
	bool success = ensureDirectory(cstrDirectory);
	//delete[] cstrDirectory;
	return success ? directory : "";
}

std::string MadvGLRenderer_windows::tempVideoLUTDirectory() {
	return s_resourceRootDirectory + TEMP_VID_LUT_DIR;
}

std::string MadvGLRenderer_windows::obtainTempVideoLUTDirectory() {
	std::string directory = tempVideoLUTDirectory();
	char* cstrDirectory = string2lpStr(directory);
	bool success = ensureDirectory(cstrDirectory);
	//delete[] cstrDirectory;
	return success ? directory : "";
}

std::string MadvGLRenderer_windows::tempPhotoLUTDirectory() {
	return s_resourceRootDirectory + TEMP_PIC_LUT_DIR;
}

std::string MadvGLRenderer_windows::obtainTempPhotoLUTDirectory() {
	std::string directory = tempPhotoLUTDirectory();
	char* cstrDirectory = string2lpStr(directory);
	bool success = ensureDirectory(cstrDirectory);
	//delete[] cstrDirectory;
	return success ? directory : "";
}

std::string MadvGLRenderer_windows::glFilterResourceDirectory() {
	return (s_resourceRootDirectory + GLFILTER_RESOURCE_DIR);
}

std::string MadvGLRenderer_windows::obtainGLFilterResourceDirectory() {
	std::string directory = glFilterResourceDirectory();
	char* cstrDirectory = string2lpStr(directory);
	bool success = ensureDirectory(cstrDirectory);
	//delete[] cstrDirectory;
	return success ? directory : "";
}

/*
NSString* MadvGLRenderer_iOS::lutPathOfSourceURI(NSString* sourceURI, BOOL forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension) {
	DoctorLog(@"lutPathOfSourceURI : %@, forceLUTStitching = %d", sourceURI, forceLUTStitching);
#ifdef USE_PRESTORED_LUT
	return prestoredLUTPath();
#endif
	if (!sourceURI || 0 == sourceURI.length)
	{
		if (forceLUTStitching)
			return cameraOrDefaultLUT();
		else
			return nil;
	}

	NSString* lutPath = nil;
	NSString* lowerExt = [[sourceURI pathExtension] lowercaseString];
	if ([@"jpg" isEqualToString:lowerExt] || [@"png" isEqualToString:lowerExt] || [@"gif" isEqualToString:lowerExt] || [@"bmp" isEqualToString:lowerExt])
	{
		MadvEXIFExtension madvEXIFExtension;
		if (NULL != pMadvEXIFExtension)
		{
			madvEXIFExtension = *pMadvEXIFExtension;
		}
		else
		{
			madvEXIFExtension = readMadvEXIFExtensionFromJPEG(NULL, sourceURI.UTF8String);
		}

		if (StitchTypeStitched != madvEXIFExtension.sceneType && !lutPath)
		{
			forceLUTStitching = YES;

			if (madvEXIFExtension.withEmbeddedLUT)
			{
				long offset = readLUTOffsetInJPEG(sourceURI.UTF8String);
				if (offset > 0)
				{
					lutPath = makeTempLUTDirectory();
					extractLUTFiles(lutPath.UTF8String, sourceURI.UTF8String, (uint32_t)offset);
					return lutPath;
				}
			}
		}

		if ([sourceURI hasSuffix : PRESTITCH_PICTURE_EXTENSION] && !lutPath)
		{
			forceLUTStitching = YES;

			NSString* cameraUUID = cameraUUIDOfPreStitchFileName(sourceURI);
			lutPath = [cameraLUTFilePath(cameraUUID) stringByDeletingPathExtension];

			BOOL isDirectory;
			if (![[NSFileManager defaultManager] fileExistsAtPath:[lutPath stringByAppendingPathComponent : @"l_x_int.png"] isDirectory : &isDirectory] || isDirectory)
			{
				return nil;
			}
		}

		if (forceLUTStitching && !lutPath)
		{
			lutPath = cameraOrDefaultLUT();
		}
	}
	else if ([sourceURI hasPrefix : AMBA_CAMERA_RTSP_URL_ROOT] || [sourceURI hasPrefix : HTTP_DOWNLOAD_URL_PREFIX])
	{
		lutPath = cameraOrDefaultLUT();
		DoctorLog(@"lutPathOfSourceURI : #3 lutPath='%@'", lutPath);
	}
	else if ([sourceURI rangeOfString : [z_Sandbox docPath]].location != NSNotFound)
	{
		if ([sourceURI rangeOfString : MADV_DUAL_FISHEYE_VIDEO_TAG].location != NSNotFound)
		{
			lutPath = cameraOrDefaultLUT();
			DoctorLog(@"lutPathOfSourceURI : #3.5 lutPath='%@'", lutPath);
			return lutPath;
		}

		static NSCondition* cond = [[NSCondition alloc] init];
		[cond lock];
		@try
		{
			KxMovieDecoder* decoder = [[KxMovieDecoder alloc] init];
			[decoder openFile : sourceURI error : nil];
			int64_t LutzOffset = [decoder getLutzOffset];
			int64_t LutzSize = [decoder getLutzSize];
			[decoder closeFile];
			NSLog(@"setupPresentViw : lutz offset = %lld size = %lld", LutzOffset, LutzSize);
			if (LutzOffset >= 0 && LutzSize > 0)
			{
				lutPath = makeTempLUTDirectory();
				extractLUTFiles(lutPath.UTF8String, sourceURI.UTF8String, (uint32_t)LutzOffset);
			}
			else if (forceLUTStitching)
			{
				lutPath = cameraOrDefaultLUT();
			}
			else
			{
				lutPath = nil;
			}
		}
		@catch (NSException *exception)
		{

		}
		@finally
		{

		}
		[cond unlock];
		DoctorLog(@"lutPathOfSourceURI : #4 lutPath='%@'", lutPath);
	}
	else if (forceLUTStitching)
	{
		lutPath = cameraOrDefaultLUT();
		DoctorLog(@"lutPathOfSourceURI : #5 lutPath='%@'", lutPath);
	}
	else
	{
		lutPath = nil;
		DoctorLog(@"lutPathOfSourceURI : Video from other stream, no LUT stitching");
	}
	return lutPath;
}
//*/
void MadvGLRenderer_windows::renderJPEGToJPEG(const char* destJpegPath, const char* sourcePath, int dstWidth, int dstHeight, bool forceLUTStitching, MadvEXIFExtension* pMadvEXIFExtension, int filterID, float* gyroMatrix, int gyroMatrixRank) {
	std::string lutPath = "";
	const char* cstrLUTPath = NULL;

	MadvEXIFExtension madvEXIFExtension;
	if (NULL != pMadvEXIFExtension)
	{
		madvEXIFExtension = *pMadvEXIFExtension;
	}
	else
	{
		madvEXIFExtension = readMadvEXIFExtensionFromJPEG(sourcePath);
	}

	if (StitchTypeStitched != madvEXIFExtension.sceneType && (lutPath.length() <= 0))
	{
		forceLUTStitching = true;

		if (madvEXIFExtension.withEmbeddedLUT)
		{
			long offset = readLUTOffsetInJPEG(sourcePath);
			if (offset > 0)
			{
				lutPath = obtainTempPhotoLUTDirectory();
				if (lutPath.length() > 0)
				{
					cstrLUTPath = (const char*)string2lpStr(lutPath);
					extractLUTFiles(cstrLUTPath, sourcePath, (uint32_t)offset);
				}
			}
		}
	}

	if (forceLUTStitching && (lutPath.length() <= 0))
	{
		lutPath = obtainCameraOrDefaultLUTDirectory();
	}
	if (!cstrLUTPath && lutPath.length() > 0)
	{
		cstrLUTPath = (const char*)string2lpStr(lutPath);
	}

	const char* cstrGLFilterResourceDir = NULL;
	if (filterID > 0)
	{
		std::string glFilterResourceDir = glFilterResourceDirectory();
		cstrGLFilterResourceDir = (const char*)string2lpStr(glFilterResourceDir);
	}

	renderMadvJPEGToJPEG(destJpegPath, sourcePath, dstWidth, dstHeight, cstrLUTPath, filterID, cstrGLFilterResourceDir, gyroMatrix, gyroMatrixRank, LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS);
	/*
	if (cstrGLFilterResourceDir)
		delete[] cstrGLFilterResourceDir;
	if (cstrLUTPath)
	{
		delete[] cstrLUTPath;
	}
	//*/
}

void MadvGLRenderer_windows::exportJPEGFromMadvJPEG(const char* destJPEGPath, const char* sourceJPEGPath, int filterID, bool enableGyroTransform, HWND hWndForCreatingWGLContext, MVProgressClosure progressClosure) {
	MadvEXIFExtension madvExtension = readMadvEXIFExtensionFromJPEG(sourceJPEGPath);
#ifdef USE_IMAGE_BLENDER
	if (madvExtension.cameraParams.ratio != 0)
	{
		ALOGE("\nMadvGLRenderer_windows $ exportJPEGFromMadvJPEG() : blendImageV2() left(x,y)=(%f,%f), right(x,y)=(%f,%f), ratio=%f, (yaw,pitch,roll)=(%f,%f,%f)\n", madvExtension.cameraParams.leftX, madvExtension.cameraParams.leftY, madvExtension.cameraParams.rightX, madvExtension.cameraParams.rightY, madvExtension.cameraParams.ratio, madvExtension.cameraParams.yaw, madvExtension.cameraParams.pitch, madvExtension.cameraParams.roll);
		blendImageV2(destJPEGPath, sourceJPEGPath, madvExtension.cameraParams.leftX, madvExtension.cameraParams.leftY, madvExtension.cameraParams.rightX, madvExtension.cameraParams.rightY, madvExtension.cameraParams.ratio, madvExtension.cameraParams.yaw, madvExtension.cameraParams.pitch, madvExtension.cameraParams.roll);
	}
	else
#endif
	{
		jpeg_decompress_struct jpegInfo = readImageInfoFromJPEG(sourceJPEGPath);
		WGLContext* ptrWGLContext = new WGLContext(hWndForCreatingWGLContext, s_hInstance, jpegInfo.image_width, jpegInfo.image_height);
		ptrWGLContext->makeCurrent();
		ALOGE("\nMadvGLRenderer_windows $ exportJPEGFromMadvJPEG() : After ptrWGLContext->makeCurrent()\n");
#ifdef USE_IMAGE_BLENDER
		char tmpJPEGPathExt[] = ".tmp.jpg";
		char* tmpJPEGPath = (char*)malloc(strlen(destJPEGPath) + sizeof(tmpJPEGPathExt));
		sprintf(tmpJPEGPath, "%s%s", destJPEGPath, tmpJPEGPathExt);
		// Stitch:
		renderJPEGToJPEG(tmpJPEGPath, sourceJPEGPath, jpegInfo.image_width, jpegInfo.image_height, false, &madvExtension, filterID, NULL, 0);
		if (NULL != progressClosure.callback)
		{
			progressClosure.callback(33, progressClosure.context);
		}
		// Blend:
		ALOGE("\n#MBB# Before blending\n");
		long sourceExivImageHandler = createExivImage(tmpJPEGPath);
		blendImage(destJPEGPath, tmpJPEGPath, 512);
		copyEXIFDataFromExivImage(destJPEGPath, sourceExivImageHandler);
		releaseExivImage(sourceExivImageHandler);
		remove(tmpJPEGPath);
		free(tmpJPEGPath);
		ALOGE("\n#MBB# After blending, remove '%s'\n", tmpJPEGPath);
		if (NULL != progressClosure.callback)
		{
			progressClosure.callback(67, progressClosure.context);
		}
		// Rotate:
		ALOGE("\nexportJPEGFromMadvJPEG: (enableGyroTransform && madvExtension.gyroMatrixBytes > 0) = %d\n", (enableGyroTransform && madvExtension.gyroMatrixBytes > 0));
		if (enableGyroTransform && madvExtension.gyroMatrixBytes > 0)
		{
			renderJPEGToJPEG(destJPEGPath, destJPEGPath, jpegInfo.image_width, jpegInfo.image_height, false, NULL, 0, madvExtension.cameraParams.gyroMatrix, 3);
		}
		//*/
#else //#ifdef USE_IMAGE_BLENDER
		if (enableGyroTransform && madvExtension.gyroMatrixBytes > 0)
		{
			renderJPEGToJPEG(destJPEGPath, sourceJPEGPath, jpegInfo.image_width, jpegInfo.image_height, false, &madvExtension, filterID, madvExtension.cameraParams.gyroMatrix, 3);
		}
		else
		{
			renderJPEGToJPEG(destJPEGPath, sourceJPEGPath, jpegInfo.image_width, jpegInfo.image_height, false, &madvExtension, filterID, NULL, 0);
		}
#endif //#ifdef USE_IMAGE_BLENDER
		
		if (NULL != progressClosure.callback)
		{
			progressClosure.callback(100, progressClosure.context);
		}
		glFinish();
		ALOGE("\nMadvGLRenderer_windows $ exportJPEGFromMadvJPEG() : After glFinish()\n");
		if (NULL != ptrWGLContext)
		{
			ptrWGLContext->flush();
			ptrWGLContext->release();
			delete ptrWGLContext;
		}
	}
	ALOGE("\nMadvGLRenderer_windows $ exportJPEGFromMadvJPEG() : Done\n");
}

void MadvGLRenderer_windows::exportDngFromMadvDNG(const char* destDngPath, const char* sourceDngPath, bool enableGyroTransform, HWND hWndForCreatingWGLContext, MVProgressClosure progressClosure) {
	TIFFHeader tiffHeader;
	std::list<std::list<DirectoryEntry> > IFDList;
	MadvEXIFExtension madvEXIFExt = readMadvEXIFExtensionFromRaw(sourceDngPath, &tiffHeader, IFDList);
	
	std::string lutPath = "";
	const char* cstrLUTPath = NULL;
	bool forceLUTStitching = false;
	if (StitchTypeStitched != madvEXIFExt.sceneType && (lutPath.length() <= 0))
	{
		forceLUTStitching = true;

		if (madvEXIFExt.withEmbeddedLUT)
		{
			if (madvEXIFExt.embeddedLUTOffset > 0)
			{
				lutPath = obtainTempPhotoLUTDirectory();
				if (lutPath.length() > 0)
				{
					cstrLUTPath = (const char*)string2lpStr(lutPath);
					extractLUTFiles(cstrLUTPath, sourceDngPath, (uint32_t)madvEXIFExt.embeddedLUTOffset);
				}
			}
		}
	}

	if (forceLUTStitching && (lutPath.length() <= 0))
	{
		lutPath = obtainCameraOrDefaultLUTDirectory();
	}
	if (!cstrLUTPath && lutPath.length() > 0)
	{
		cstrLUTPath = (const char*)string2lpStr(lutPath);
	}
	ALOGE("madvEXIFExt = {embeddedLUTOffset:%ld, width:%d, height:%d, sceneType:%x}, lutPath='%s'\n", (long)madvEXIFExt.embeddedLUTOffset, madvEXIFExt.width, madvEXIFExt.height, madvEXIFExt.sceneType, cstrLUTPath);

	//printIFDList(std::cout, tiffHeader, IFDList);
	//*
	
	WGLContext* ptrWGLContext = new WGLContext(hWndForCreatingWGLContext, s_hInstance, madvEXIFExt.width, madvEXIFExt.height);
	ptrWGLContext->makeCurrent();
	renderMadvRawToRaw(destDngPath, sourceDngPath, madvEXIFExt.width, madvEXIFExt.height, lutPath.c_str(), 0, NULL, madvEXIFExt.cameraParams.gyroMatrix, (madvEXIFExt.gyroMatrixBytes > 0 ? 3 : 0), LONGITUDE_SEGMENTS, LATITUDE_SEGMENTS, progressClosure);
	ALOGE("\nMadvGLRenderer_windows $ exportJPEGFromMadvJPEG() : After glFinish()\n");
	if (NULL != ptrWGLContext)
	{
		ptrWGLContext->flush();
		ptrWGLContext->release();
		delete ptrWGLContext;
	}
	ALOGE("\nMadvGLRenderer_windows $ exportJPEGFromMadvJPEG() : Done\n");
}

void MadvGLRenderer_windows::debugJPEGEncode(HWND hWndForCreatingWGLContext, HINSTANCE hInstance) {
	MadvGLRenderer_windows::ensureDirectory("H:\\Madv360\\res");
	initialize("H:\\Madv360\\res", hInstance);
	MadvGLRenderer_windows::exportJPEGFromMadvJPEG("H:\\Madv360\\out0.JPG", "H:\\IMG_20161203_223132.JPG", 0, true, hWndForCreatingWGLContext);
	MadvGLRenderer_windows::exportJPEGFromMadvJPEG("H:\\Madv360\\out1.JPG", "H:\\Madv360\\out0.JPG", GLFilterKuwaharaID, true, hWndForCreatingWGLContext);
}

#endif //#ifdef TARGET_OS_WINDOWS
