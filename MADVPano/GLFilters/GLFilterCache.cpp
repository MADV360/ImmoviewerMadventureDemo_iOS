//
//  GLFilterCache.cpp
//  Madv360_v1
//
//  Created by QiuDong on 16/7/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#include "mat4.h"
#include "../PNGUtils.h"
#include "GLFilterCache.h"
#include "AutoRef.h"
#include <map>
#include "GLSimpleBeautyFilter.h"
#include "GLInverseColorFilter.h"
#include "GLBilateralFilter.h"
#include "GLKuwaharaFilter.h"
#include "GLColorMatrixFilter.h"
#include "GLColorLookupFilter.h"
#include "GLRGB2YUVFilter.h"
#include "GLSobelEdgeDetectSketchFilter.h"
#include "GLToonFilter.h"
#include "GLPlainFilter.h"
#include "GLTestFilter.h"
#include <stdio.h>
#include <string.h>

using namespace std;

typedef AutoRef<GLFilter> GLFilterRef;

std::map<int, GLFilterRef>* filtersOfID(void* ptrMap) {
    return (std::map<int, GLFilterRef>*) ptrMap;
}

GLFilterCache::~GLFilterCache() {
    releaseGLObjects();
    if (NULL != _resourceDirectory)
    {
        free((void*)_resourceDirectory);
    }
}

GLFilterCache::GLFilterCache(const char* resourceDirectory) {
    if (NULL != resourceDirectory)
    {
        _resourceDirectory = (char*) malloc(strlen(resourceDirectory) + 1);
        strcpy((char*)_resourceDirectory, resourceDirectory);
    }
    
    _filtersOfIDMap = new std::map<int, GLFilterRef>;
}

void GLFilterCache::releaseGLObjects() {
    std::map<int, GLFilterRef>* filtersOfIDMap = filtersOfID(_filtersOfIDMap);
    if (!filtersOfIDMap)
        return;

    for (std::map<int,GLFilterRef>::iterator iter = filtersOfIDMap->begin();
            iter != filtersOfIDMap->end();
            iter++)
    {
        GLFilterRef filter = iter->second;
        if (filter != NULL)
        {
            filter->releaseGLObjects();
        }
    }
    filtersOfIDMap->clear();
    delete (std::map<int, GLFilterRef>*) _filtersOfIDMap;
    _filtersOfIDMap = NULL;
}

void GLFilterCache::render(int filterID, GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget) {
    GLFilterRef filter = obtainFilter(filterID);
    if (filter)
    {
        filter->render(ptrVAO, sourceTexture, sourceTextureTarget);
    }
}

void GLFilterCache::render(int filterID, GLfloat x, GLfloat y, GLfloat width, GLfloat height, GLint sourceTexture, GLenum sourceTextureTarget) {
    GLFilterRef filter = obtainFilter(filterID);
    if (filter)
    {
        filter->render(x,y, width,height, sourceTexture, sourceTextureTarget);
    }
}

void GLFilterCache::render(int filterID, GLfloat x, GLfloat y, GLfloat width, GLfloat height, GLint sourceTexture, GLenum sourceTextureTarget, Orientation2D sourceOrientation, Vec2f texcoordOrigin, Vec2f texcoordSize) {
    GLFilterRef filter = obtainFilter(filterID);
    if (filter)
    {
        filter->render(x,y,width,height, sourceTexture, sourceTextureTarget, sourceOrientation, texcoordOrigin, texcoordSize);
    }
    CHECK_GL_ERROR();
}

GLFilter* GLFilterCache::obtainFilter(int filterID) {
    GLFilterRef filter;
    std::map<int, GLFilterRef>* filtersOfIDMap = filtersOfID(_filtersOfIDMap);
    map<int,GLFilterRef>::iterator found = filtersOfIDMap->find(filterID);
    if (found == filtersOfIDMap->end())
    {
        filter = createFilter(filterID);
        filtersOfIDMap->insert(make_pair(filterID, filter));
    }
    else
    {
        filter = found->second;
    }
    return filter;
}

GLFilter* GLFilterCache::createFilter(int filterID) {
    switch (filterID)
    {
        case GLFilterTestID:
            return new GLTestFilter;
        case GLFilterSimpleBeautyID:
            return new GLSimpleBeautyFilter;
        case GLFilterInverseColorID:
            return new GLInverseColorFilter;
        case GLFilterBilateralID:
            return new GLBilateralFilter;
        case GLFilterKuwaharaID:
            return new GLKuwaharaFilter;
        case GLFilterSepiaToneID:
        {
            kmMat4 colorMatrix;
            float matData[] = {0.3588, 0.7044, 0.1368, 0.0,
                               0.2990, 0.5870, 0.1140, 0.0,
                               0.2392, 0.4696, 0.0912 ,0.0,
                               0,0,0,1.0};
            kmMat4Fill(&colorMatrix, matData);
            return new GLColorMatrixFilter(colorMatrix, 1.0f);
        }
        case GLFilterAmatorkaID:
        case GLFilterMissEtikateID:
        {
            const char* lookupImageName = "lookup_amatorka.png";//
            switch (filterID)
            {
                case GLFilterAmatorkaID:
                    lookupImageName = "lookup_amatorka.png";
                    break;
                case GLFilterMissEtikateID:
                    lookupImageName = "lookup_miss_etikate.png"; // ST_BUG #1200 by Qiudong
//                    lookupImageName = "lookup_amatorka.png";
                    break;
            }
            char* lookupImagePath = (char*) malloc(strlen(_resourceDirectory) + strlen(lookupImageName) + 2);
            sprintf(lookupImagePath, "%s/%s", _resourceDirectory, lookupImageName);
            pic_data lookupImage;
            decodePNG(lookupImagePath, &lookupImage);

            GLint format = GL_RGBA;
            switch (lookupImage.channels)
            {
                case 4:
                    format = GL_RGBA;
                    break;
                case 3:
                    format = GL_RGB;
                    break;
                case 1:
                    format = GL_LUMINANCE;
                    break;
            }
            GLenum type = GL_UNSIGNED_BYTE;
            switch (lookupImage.bit_depth)
            {
                case 16:
                    format = GL_UNSIGNED_SHORT;
                    break;
            }
            GLuint lookupTexture;
            GLint prevTextureBinding;
            glGetIntegerv(GL_TEXTURE_BINDING_2D, &prevTextureBinding);
            glGenTextures(1, &lookupTexture);
            glBindTexture(GL_TEXTURE_2D, lookupTexture);
            glTexImage2D(GL_TEXTURE_2D, 0, format, lookupImage.width, lookupImage.height, 0, format, type, lookupImage.rgba);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);//GL_CLAMP_TO_EDGE);//
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);//GL_CLAMP_TO_EDGE);//
            glPixelStorei(GL_PACK_ALIGNMENT, 1);
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
            glBindTexture(GL_TEXTURE_2D, prevTextureBinding);

            GLColorLookupFilter* filter = new GLColorLookupFilter;
            filter->setIntensity(1.0f);
            filter->setLookupTexture(lookupTexture);
            free(lookupImagePath);

            return filter;
        }
        case GLFilterRGB2YUVID:
        {
            GLRGB2YUVFilter* filter = new GLRGB2YUVFilter;
            return filter;
        }
        case GLFilterSobelEdgeDetectSketchID:
        {
            GLSobelEdgeDetectSketchFilter* filter = new GLSobelEdgeDetectSketchFilter;
            filter->setEdgeStrength(1.f);
            return filter;
        }
        case GLFilterToonID:
        {
            GLToonFilter* filter = new GLToonFilter;
            filter->setThreshold(0.25f);
            return filter;
        }
        default:
            return new GLPlainFilter;
    }
}
