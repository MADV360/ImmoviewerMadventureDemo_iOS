//
//  MadvGLRenderer.h
//  Madv360_v1
//  全景渲染器，封装了与渲染全景内容有关的OpenGL调用，
//  本身不包含与OpenGL context创建/切换/销毁相关的代码，这部分内容由调用者完成
//  Created by QiuDong on 16/2/26.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//
#if defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0

#ifndef MadvGLRenderer_debug_hpp
#define MadvGLRenderer_debug_hpp

#include "MadvGLRendererImpl.h"
#include "MadvGLRenderer.h"

/** 全景渲染器，封装了与渲染全景内容有关的OpenGL调用，
 * 本身不包含与OpenGL context创建/切换/销毁相关的代码，这部分内容由调用者完成
 */
class MadvGLRendererImpl_debug : public MadvGLRendererImpl {
    
public:
    
    virtual ~MadvGLRendererImpl_debug();
    
    /** 构造函数：基于拼接查找表文件参数创建渲染器
     * 拼接查找表文件用于将MADV相机拍摄的双鱼眼照片/视频拼接为全景
     * 查找表文件通过MADV相机下发或在MADV相机采集视频的MP4 box中获得
     * 获取和解压缩查找表文件的有关API在MADVCamera SDK中
     * @param lutPath 拼接双鱼眼图所用查找表文件的本地路径
     * @param leftSrcSize 左鱼眼图的查找表源尺寸，目前统一为3456x1728
     * @param leftSrcSize 左鱼眼图的查找表源尺寸，目前统一为3456x1728
     */
    MadvGLRendererImpl_debug(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments);

protected:
    
    virtual void prepareGLPrograms();
};

//typedef AutoRef<MadvGLRendererImpl_debug> MadvGLRendererDebugImplRef;

class MadvGLRenderer_debug : public MadvGLRenderer {
    friend class PanoCameraController;
    
public:
    
    MadvGLRenderer_debug(const char* lutPath, Vec2f leftSrcSize, Vec2f rightSrcSize, GLuint longitudeSegments, GLuint latitudeSegments)
    : MadvGLRenderer(new MadvGLRendererImpl_debug(lutPath, leftSrcSize, rightSrcSize, longitudeSegments, latitudeSegments))
    {
        
    }
};

#endif //MadvGLRenderer_debug_hpp

#endif //#if defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0
