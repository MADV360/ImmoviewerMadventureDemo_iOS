


//
//  GLRenderTexture.cpp
//  Madv360_v1
//
//  Created by FutureBoy on 4/2/16.
//  Copyright © 2016 Cyllenge. All rights reserved.
//

#include "GLRenderTexture.h"
#include "OpenGLHelper.h"
#include "gles3.h"
#include "gles3ext.h"

void GLRenderTexture::releaseGLObjects() {
    if (_texture && _ownTexture)
    {
        glDeleteTextures(1, &_texture);
        _texture = 0;
    }

    if (_framebuffer)
    {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }

//    if (_pboIDs[0] || _pboIDs[1])
//    {
//        glDeleteBuffers(2, _pboIDs);
//        _pboIDs[0] = _pboIDs[1] = 0;
//    }
    
    if (_enableDepthTest)
    {
        glDeleteRenderbuffers(1, &_depthBuffer);
        _depthBuffer = 0;
    }
}

GLRenderTexture::GLRenderTexture(GLint texture, GLenum textureTarget, GLint width, GLint height, GLenum internalFormat, GLenum format, GLenum dataType, GLenum wrapS, GLenum wrapT, bool enableDepthTest)
: _framebuffer(0)
, _texture(texture)
, _textureTarget(textureTarget)
, _ownTexture(texture <= 0)
, _width(0)
, _height(0)
, _format(format)
, _internalFormat(internalFormat)
, _dataType(dataType)
, _wrapS(wrapS)
, _wrapT(wrapT)
//, _pboIDs{0,0}
//, _pboIndex(0)
, _enableDepthTest(enableDepthTest)
{
#if !defined(TARGET_OS_OSX) || TARGET_OS_OSX == 0
    const char* extensions = (const char*) glGetString(GL_EXTENSIONS);
    ALOGE("GL Extensions : %s", extensions);
//    _isPBOSupported = true;///!!!(NULL != strstr(extensions, "pixel_buffer_object"));
#endif
    if (0 != resizeIfNecessary(width, height))
    {
        releaseGLObjects();
    }
    else
    {
        GLint prevTexture2D, prevTexture3D, prevTextureCubemap;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &prevTexture2D);
        glGetIntegerv(GL_TEXTURE_BINDING_3D, &prevTexture3D);
        glGetIntegerv(GL_TEXTURE_BINDING_CUBE_MAP, &prevTextureCubemap);
#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
        GLint prevTextureExternal;
        glGetIntegerv(GL_TEXTURE_BINDING_EXTERNAL_OES, &prevTextureExternal);
#endif
        GLint prevFramebuffer;
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFramebuffer);

        glBindTexture(_textureTarget, _texture);
        glTexParameteri(_textureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
        glTexParameteri(_textureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
        glTexParameteri(_textureTarget, GL_TEXTURE_WRAP_S, _wrapS);//GL_CLAMP_TO_EDGE);//GL_REPEAT
        glTexParameteri(_textureTarget, GL_TEXTURE_WRAP_T, _wrapT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
        glPixelStorei(GL_PACK_ALIGNMENT, 1);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        
        glBindFramebuffer(GL_FRAMEBUFFER, prevFramebuffer);
        glBindTexture(GL_TEXTURE_2D, prevTexture2D);
        glBindTexture(GL_TEXTURE_3D, prevTexture3D);
        glBindTexture(GL_TEXTURE_CUBE_MAP, prevTextureCubemap);
#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, prevTextureExternal);
#endif
    }
}

GLRenderTexture::GLRenderTexture(GLint texture, GLenum textureTarget, GLint width, GLint height, GLenum internalFormat, GLenum format, GLenum dataType, bool enableDepthTest)
: GLRenderTexture::GLRenderTexture(texture, textureTarget, width, height, GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE, GL_REPEAT, GL_REPEAT, enableDepthTest)
{
    
}

GLRenderTexture::GLRenderTexture(GLint texture, GLenum textureTarget, GLint width, GLint height, bool enableDepthTest)
: GLRenderTexture(texture, textureTarget, width, height, GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE, enableDepthTest)
{
}

GLRenderTexture::GLRenderTexture(GLint width, GLint height, bool enableDepthTest)
: GLRenderTexture(0, GL_TEXTURE_2D, width, height, enableDepthTest)
{
}

int GLRenderTexture::resizeIfNecessary(GLint width, GLint height) {
    if (_width != width || _height != height)
    {
        _width = width;
        _height = height;

        GLint prevTexture2D, prevTexture3D, prevTextureCubemap;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &prevTexture2D);
        glGetIntegerv(GL_TEXTURE_BINDING_3D, &prevTexture3D);
        glGetIntegerv(GL_TEXTURE_BINDING_CUBE_MAP, &prevTextureCubemap);
#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
        GLint prevTextureExternal;
        glGetIntegerv(GL_TEXTURE_BINDING_EXTERNAL_OES, &prevTextureExternal);
#endif
        GLint prevFramebuffer;
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFramebuffer);

        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);

        if (_texture && _ownTexture)
        {
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, _textureTarget, 0, 0);
            glDeleteTextures(1, &_texture);
            _texture = 0;
        }
        CHECK_GL_ERROR();
        if (_enableDepthTest)
        {
            if (_depthBuffer > 0)
            {
                glDeleteRenderbuffers(1, &_depthBuffer);
                CHECK_GL_ERROR();
            }
            _depthBuffer = 0;
        }
        if (0 != _framebuffer)
        {
            glDeleteFramebuffers(1, &_framebuffer);
        }
        CHECK_GL_ERROR();
        glGenFramebuffers(1, &_framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        if (_ownTexture)
        {
            glGenTextures(1, &_texture);
        }
        glBindTexture(_textureTarget, _texture);
        if (_ownTexture)
        {
            glTexParameteri(_textureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
            glTexParameteri(_textureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
            glTexParameteri(_textureTarget, GL_TEXTURE_WRAP_S, _wrapS);//GL_CLAMP_TO_EDGE);//GL_REPEAT
            glTexParameteri(_textureTarget, GL_TEXTURE_WRAP_T, _wrapT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
            glPixelStorei(GL_PACK_ALIGNMENT, 1);
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
            
            //    GLubyte* pixelData = (GLubyte*) malloc(destSize.width * destSize.height * 4);
            glTexImage2D(_textureTarget, 0, _internalFormat, width, height, 0, _format, _dataType, 0);
            CHECK_GL_ERROR();
            GLenum errorNo = glGetError();
            if (GL_OUT_OF_MEMORY == errorNo)
            {
                ALOGE("\nOpenGL error 0x%04X in %s %s %d\n", errorNo, __FILE__, __FUNCTION__, __LINE__);
                glBindFramebuffer(GL_FRAMEBUFFER, prevFramebuffer);
                glBindTexture(GL_TEXTURE_2D, prevTexture2D);
                glBindTexture(GL_TEXTURE_3D, prevTexture3D);
                glBindTexture(GL_TEXTURE_CUBE_MAP, prevTextureCubemap);
#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
                glBindTexture(GL_TEXTURE_EXTERNAL_OES, prevTextureExternal);
#endif
                return -1;
            }
        }
        CHECK_GL_ERROR();
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, _textureTarget, _texture, 0);
        //    GLenum error = glGetError();
        //    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        //    NSLog(@"error = %x, status = %d", error, status);
//        if (_isPBOSupported)
//        {
//            GLint prevPboBinding;
//            glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING, &prevPboBinding);
//
//            if (_pboIDs[0] > 0)
//            {
//                glDeleteBuffers(2, _pboIDs);
//                _pboIDs[0] = _pboIDs[1] = 0;
//            }
//
//            glGenBuffers(2, _pboIDs);
//            for (int i=0; i<2; ++i)
//            {
//                glBindBuffer(GL_PIXEL_PACK_BUFFER, _pboIDs[i]);
//                glBufferData(GL_PIXEL_PACK_BUFFER, width * height * 4, NULL, GL_DYNAMIC_READ);//GL_STREAM_READ);//
//                CHECK_GL_ERROR();
//            }
//
//            glBindBuffer(GL_PIXEL_PACK_BUFFER, prevPboBinding);
//        }
        if (_enableDepthTest)
        {
            GLint prevDepthRenderbuffer = 0;
            glGetIntegerv(GL_RENDERBUFFER_BINDING, &prevDepthRenderbuffer);
            
            glGenRenderbuffers(1, &_depthBuffer);
            glBindRenderbuffer(GL_RENDERBUFFER, _depthBuffer);
            glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);

            glBindRenderbuffer(GL_RENDERBUFFER, prevDepthRenderbuffer);
        }
        
        glBindFramebuffer(GL_FRAMEBUFFER, prevFramebuffer);
        glBindTexture(GL_TEXTURE_2D, prevTexture2D);
        glBindTexture(GL_TEXTURE_3D, prevTexture3D);
        glBindTexture(GL_TEXTURE_CUBE_MAP, prevTextureCubemap);
#if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, prevTextureExternal);
#endif
    }
    return 0;
}

GLint GLRenderTexture::bytesLength() {
    return _width * _height * ComponentsOfColorSpace(_format) * BytesOfBitFormat(_dataType);//TODO:
}

void GLRenderTexture::blit() {
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &_prevFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    CHECK_GL_ERROR();
}

void GLRenderTexture::unblit() {
    glBindFramebuffer(GL_FRAMEBUFFER, _prevFramebuffer);
    CHECK_GL_ERROR();
}

int GLRenderTexture::copyPixelData(uint8_t* data, int offset, int length) {
    if (_width <= 0 || _height <= 0)
    {
        ALOGE("GLRenderTexture::copyPixelData() Error : _width = %d, _height = %d", _width, _height);
    }
    glReadPixels(0, 0, _width, _height, _format, _dataType, data + offset);///!!!
    CHECK_GL_ERROR();
    glFlush();
    return bytesLength();
}

GLubyte* GLRenderTexture::copyPixelDataFromPBO(int offset, int length) {
    GLboolean success = GL_FALSE;
    GLubyte* pixels = NULL;
//    if (_isPBOSupported)
//    {
//        GLint prevPboBinding;
//        glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING, &prevPboBinding);
//
//        glReadBuffer(GL_COLOR_ATTACHMENT0);
//        glBindBuffer(GL_PIXEL_PACK_BUFFER, _pboIDs[_pboIndex]);
//        glReadPixels(0, 0, _width, _height, GL_RGBA, GL_UNSIGNED_BYTE, 0);
//
//        _pboIndex = (_pboIndex + 1) % 2;
//        glBindBuffer(GL_PIXEL_PACK_BUFFER, _pboIDs[_pboIndex]);
//        pixels = (GLubyte*) glMapBufferRange(GL_PIXEL_PACK_BUFFER, 0, bytesLength(), GL_MAP_READ_BIT);
//        CHECK_GL_ERROR();
//        if (pixels)
//        {
//            success = glUnmapBufferOES(GL_PIXEL_PACK_BUFFER);
//        }
//        CHECK_GL_ERROR();
//        glBindBuffer(GL_PIXEL_PACK_BUFFER, prevPboBinding);
//    }
    ALOGE("GLRenderTexture::copyPixelDataFromPBO : success = %d", success);
    return  (GL_TRUE == success) ? pixels : NULL;
}
