//
//  KxMovieGLView.m
//  kxmovie
//
//  Created by Kolyvan on 22.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#import "KxMovieGLView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "kazmath.h"
#import "KxMovieDecoder.h"
#import "KxLogger.h"
#import "Macros.h"

//////////////////////////////////////////////////////////

#pragma mark - shaders

NSString *const vertexShaderString = NSSTRINGIZE
(
 attribute vec4 position;
 attribute vec2 texcoord;
 uniform mat4 modelViewProjectionMatrix;
 varying vec2 v_texcoord;
 
 void main()
 {
     gl_Position = modelViewProjectionMatrix * position;
     v_texcoord = texcoord.xy;
 }
);

NSString *const rgbFragmentShaderString = NSSTRINGIZE
(
 varying highp vec2 v_texcoord;
 uniform sampler2D s_texture;
 
 void main()
 {
     gl_FragColor = texture2D(s_texture, v_texcoord);
 }
);

NSString *const yuvFragmentShaderString = NSSTRINGIZE
(
 varying highp vec2 v_texcoord;
 uniform sampler2D s_texture_y;
 uniform sampler2D s_texture_u;
 uniform sampler2D s_texture_v;
 
 void main()
 {
     highp float y = texture2D(s_texture_y, v_texcoord).r;
     highp float u = texture2D(s_texture_u, v_texcoord).r - 0.5;
     highp float v = texture2D(s_texture_v, v_texcoord).r - 0.5;
     
     highp float r = y +             1.402 * v;
     highp float g = y - 0.344 * u - 0.714 * v;
     highp float b = y + 1.772 * u;
     
     gl_FragColor = vec4(r,g,b,1.0);     
 }
);

static BOOL validateProgram(GLuint prog)
{
	GLint status;
	
    glValidateProgram(prog);
    
#ifdef DEBUG
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        LoggerVideo(1, @"Program validate log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE) {
		LoggerVideo(0, @"Failed to validate program %d", prog);
        return NO;
    }
	
	return YES;
}

static GLuint compileShader(GLenum type, NSString *shaderString)
{
	GLint status;
	const GLchar *sources = (GLchar *)shaderString.UTF8String;
	
    GLuint shader = glCreateShader(type);
    if (shader == 0 || shader == GL_INVALID_ENUM) {
        LoggerVideo(0, @"Failed to create shader %d", type);
        return 0;
    }
    
    glShaderSource(shader, 1, &sources, NULL);
    glCompileShader(shader);
	
#ifdef DEBUG
	GLint logLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(shader, logLength, &logLength, log);
        LoggerVideo(1, @"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        glDeleteShader(shader);
		LoggerVideo(0, @"Failed to compile shader:\n");
        return 0;
    }
    
	return shader;
}

static void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout)
{
	float r_l = right - left;
	float t_b = top - bottom;
	float f_n = far - near;
	float tx = - (right + left) / (right - left);
	float ty = - (top + bottom) / (top - bottom);
	float tz = - (far + near) / (far - near);
    
	mout[0] = 2.0f / r_l;
	mout[1] = 0.0f;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = 0.0f;
	mout[5] = 2.0f / t_b;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = 0.0f;
	mout[10] = -2.0f / f_n;
	mout[11] = 0.0f;
	
	mout[12] = tx;
	mout[13] = ty;
	mout[14] = tz;
	mout[15] = 1.0f;
}

//////////////////////////////////////////////////////////

#pragma mark - frame renderers

@protocol KxMovieGLRenderer
- (BOOL) isValid;
- (NSString *) fragmentShader;
- (void) resolveUniforms: (GLuint) program;
- (void) setFrame: (KxVideoFrame *) frame;
- (BOOL) prepareRender;
@end

@interface KxMovieGLRenderer_RGB : NSObject<KxMovieGLRenderer> {
    
    GLint _uniformSampler;
    GLuint _texture;
}
@end

@implementation KxMovieGLRenderer_RGB

- (BOOL) isValid
{
    return (_texture != 0);
}

- (NSString *) fragmentShader
{
    return rgbFragmentShaderString;
}

- (void) resolveUniforms: (GLuint) program
{
    _uniformSampler = glGetUniformLocation(program, "s_texture");
}

- (void) setFrame: (KxVideoFrame *) frame
{
    KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB *)frame;
   
    assert(rgbFrame.rgb.length == rgbFrame.width * rgbFrame.height * 3);

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if (0 == _texture)
        glGenTextures(1, &_texture);
    
    glBindTexture(GL_TEXTURE_2D, _texture);
    
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGB,
                 frame.width,
                 frame.height,
                 0,
                 GL_RGB,
                 GL_UNSIGNED_BYTE,
                 rgbFrame.rgb.bytes);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
}

- (BOOL) prepareRender
{
    if (_texture == 0)
        return NO;
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(_uniformSampler, 0);
    
    return YES;
}

- (void) dealloc
{
    if (_texture) {
        glDeleteTextures(1, &_texture);
        _texture = 0;
    }
}

@end

@interface KxMovieGLRenderer_YUV : NSObject<KxMovieGLRenderer> {
    
    GLint _uniformSamplers[3];
    GLuint _textures[3];
}
@end

@implementation KxMovieGLRenderer_YUV

- (BOOL) isValid
{
    return (_textures[0] != 0);
}

- (NSString *) fragmentShader
{
    return yuvFragmentShaderString;
}

- (void) resolveUniforms: (GLuint) program
{
    _uniformSamplers[0] = glGetUniformLocation(program, "s_texture_y");
    _uniformSamplers[1] = glGetUniformLocation(program, "s_texture_u");
    _uniformSamplers[2] = glGetUniformLocation(program, "s_texture_v");
}

- (void) setFrame: (KxVideoFrame *) frame
{
    KxVideoFrameYUV *yuvFrame = (KxVideoFrameYUV *)frame;
    
    assert(yuvFrame.luma.length == yuvFrame.width * yuvFrame.height);
    assert(yuvFrame.chromaB.length == (yuvFrame.width * yuvFrame.height) / 4);
    assert(yuvFrame.chromaR.length == (yuvFrame.width * yuvFrame.height) / 4);

    const NSUInteger frameWidth = frame.width;
    const NSUInteger frameHeight = frame.height;    
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if (0 == _textures[0])
        glGenTextures(3, _textures);

    const UInt8 *pixels[3] = { (UInt8*)yuvFrame.luma.bytes, (UInt8*)yuvFrame.chromaB.bytes, (UInt8*)yuvFrame.chromaR.bytes };
    const NSUInteger widths[3]  = { frameWidth, frameWidth / 2, frameWidth / 2 };
    const NSUInteger heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
    
    for (int i = 0; i < 3; ++i) {
        
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE,
                     widths[i],
                     heights[i],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     pixels[i]);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    }     
}

- (BOOL) prepareRender
{
    if (_textures[0] == 0)
        return NO;
    
    for (int i = 0; i < 3; ++i) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        glUniform1i(_uniformSamplers[i], i);
    }
    
    return YES;
}

- (void) dealloc
{
    if (_textures[0])
        glDeleteTextures(3, _textures);
}

@end

//core video buffer render by spy
@interface KxMovieGLRenderer_CVBuffer : NSObject<KxMovieGLRenderer> {
    EAGLContext* _context;
    GLint _uniformSampler;
    GLuint _texture;
    struct __CVOpenGLESTextureCache * _videoTextureCache;
    struct __CVOpenGLESTexture *      _videoDestTexture;
}
-(void)setEGLContext:(EAGLContext*)context;
@end

@implementation KxMovieGLRenderer_CVBuffer

-(void)setEGLContext:(EAGLContext*)context
{
    _context = context;
}

- (BOOL) isValid{
    return (_texture != 0);
}

- (NSString *) fragmentShader{
    return rgbFragmentShaderString;//@"";
}

- (void) resolveUniforms: (GLuint) program{
    
    _uniformSampler = glGetUniformLocation(program, "s_texture");
}

- (void) setFrame: (KxVideoFrame *) frame{
    KxVideoFrameCVBuffer *cvbFrame = (KxVideoFrameCVBuffer *)frame;
    
    CVBufferRef cvBufferRef = cvbFrame.cvBufferRef;
    
    if (!_videoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, (CVOpenGLESTextureCacheRef *)&_videoTextureCache);
        if (err != noErr) {
            [cvbFrame releasePixelBuffer];
            return;
        }
        //CFRetain(_videoTextureCache);//2016.3.3 spy
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    /* cleanUp Textures*/
    if (_videoDestTexture) {
        CFRelease(_videoDestTexture);
        _videoDestTexture = NULL;
    }
    
    glActiveTexture(GL_TEXTURE0);
    CVReturn err;
    
    int frameWidth = (int)CVPixelBufferGetWidth(cvBufferRef);
    int frameHeight = (int)CVPixelBufferGetHeight(cvBufferRef);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       cvBufferRef,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       frameWidth,
                                                       frameHeight,
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       (CVOpenGLESTextureRef*)&_videoDestTexture);
    if (err) {
        [cvbFrame releasePixelBuffer];
        return;
    }
    
    _texture = CVOpenGLESTextureGetName((CVOpenGLESTextureRef)_videoDestTexture);
    
    glBindTexture(CVOpenGLESTextureGetTarget((CVOpenGLESTextureRef)_videoDestTexture), CVOpenGLESTextureGetName((CVOpenGLESTextureRef)_videoDestTexture));
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    
}

- (BOOL) prepareRender{
    if (_texture == 0)
        return NO;
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(_uniformSampler, 0);
    return YES;
}

- (void) dealloc
{
    if (_texture && glIsTexture(_texture))
        glDeleteTextures(1, &_texture);
    _texture = 0;
    
    if(_videoDestTexture) {
        CFRelease(_videoDestTexture);
        _videoDestTexture = NULL;
    }
    
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
}

@end

//////////////////////////////////////////////////////////

#pragma mark - gl view

enum {
	ATTRIBUTE_VERTEX,
   	ATTRIBUTE_TEXCOORD,
};

@implementation KxMovieGLView {
    
    KxMovieDecoder  *_decoder;
    EAGLContext     *_context;
    GLuint          _framebuffer;
    GLuint          _renderbuffer;
    GLint           _backingWidth;
    GLint           _backingHeight;
    GLuint          _program;
    GLint           _uniformMatrix;
    GLfloat         _vertices[12];
    
    KxVideoFrameFormat    _rendererFormat;
    id<KxMovieGLRenderer> _renderer;
    
    ///qiudong:
    CGFloat _focalLength;
    CGFloat _prevFocalLength;
    CGPoint _offset;
    CGPoint _prevOffset;
}

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (id) initWithFrame:(CGRect)frame
             decoder: (KxMovieDecoder *) decoder
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _decoder = decoder;
        
        //if ([decoder setupVideoFrameFormat:KxVideoFrameFormatYUV]) {
        [decoder setupVideoFrameFormat:KxVideoFrameFormatYUV];
        _rendererFormat = [decoder getVideoFrameFormat];
        if (_rendererFormat == KxVideoFrameFormatYUV){
            
            _renderer = [[KxMovieGLRenderer_YUV alloc] init];
            LoggerVideo(1, @"OK use YUV GL renderer");
            
        }
        else if (_rendererFormat == KxVideoFrameFormatCVBuffer){
            
            _renderer = [[KxMovieGLRenderer_CVBuffer alloc] init];
            LoggerVideo(1, @"OK use CVBuffer renderer");
        }
        else {
            
            _renderer = [[KxMovieGLRenderer_RGB alloc] init];
            LoggerVideo(1, @"OK use RGB GL renderer");
        }
                
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
        
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!_context ||
            ![EAGLContext setCurrentContext:_context]) {
            
            LoggerVideo(0, @"failed to setup EAGLContext");
            self = nil;
            return nil;
        }
        
        glGenFramebuffers(1, &_framebuffer);
        glGenRenderbuffers(1, &_renderbuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
        [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            
            LoggerVideo(0, @"failed to make complete framebuffer object %x", status);
            self = nil;
            return nil;
        }
        
        GLenum glError = glGetError();
        if (GL_NO_ERROR != glError) {
            
            LoggerVideo(0, @"failed to setup GL %x", glError);
            self = nil;
            return nil;
        }
        
        if (_rendererFormat == KxVideoFrameFormatCVBuffer){
            KxMovieGLRenderer_CVBuffer * cvb_render = (KxMovieGLRenderer_CVBuffer *)_renderer;
            [cvb_render setEGLContext:_context];
        }
        
        if (![self loadShaders]) {
            self = nil;
            return nil;
        }
        
        const float z = 0;
        _vertices[0] = -1.0f;  // x0
        _vertices[1] = -1.0f;  // y0
        _vertices[2] = z;
        
        _vertices[3] =  1.0f;  // ..
        _vertices[4] = -1.0f;
        _vertices[5] = z;
        
        _vertices[6] = -1.0f;
        _vertices[7] =  1.0f;
        _vertices[8] = z;
        
        _vertices[9] =  1.0f;  // x3
        _vertices[10] =  1.0f;  // y3
        _vertices[11] = z;
        
        LoggerVideo(1, @"OK setup GL");
        
        ///qiudong:
        _focalLength = 1;
        _offset = CGPointMake(0, 0);
        
        UIPinchGestureRecognizer* pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinchRecognized:)];
        [self addGestureRecognizer:pinchRecognizer];
        
        UIPanGestureRecognizer* panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanRecognized:)];
        [self addGestureRecognizer:panGR];
    }
    
    return self;
}

- (void)dealloc
{
    _renderer = nil;

    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
	
	if ([EAGLContext currentContext] == _context) {
		[EAGLContext setCurrentContext:nil];
	}
    
	_context = nil;
}

- (void)layoutSubviews
{
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
	
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
	if (status != GL_FRAMEBUFFER_COMPLETE) {
		
        LoggerVideo(0, @"failed to make complete framebuffer object %x", status);
        
	} else {
        
        LoggerVideo(1, @"OK setup GL framebuffer %d:%d", _backingWidth, _backingHeight);
    }
    
    [self updateVertices];
    [self render: nil];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    [self updateVertices];
    if (_renderer.isValid)
        [self render:nil];
}

- (BOOL)loadShaders
{
    BOOL result = NO;
    GLuint vertShader = 0, fragShader = 0;
    
	_program = glCreateProgram();
	
    vertShader = compileShader(GL_VERTEX_SHADER, vertexShaderString);
	if (!vertShader)
        goto exit;
    
    
    if (![_renderer.fragmentShader isEqualToString:@""]){
        fragShader = compileShader(GL_FRAGMENT_SHADER, _renderer.fragmentShader);
        if (!fragShader)
            goto exit;
    }
    
	glAttachShader(_program, vertShader);
    if (fragShader)
        glAttachShader(_program, fragShader);
	glBindAttribLocation(_program, ATTRIBUTE_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIBUTE_TEXCOORD, "texcoord");
	
	glLinkProgram(_program);
    
    GLint status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
		LoggerVideo(0, @"Failed to link program %d", _program);
        goto exit;
    }
    
    result = validateProgram(_program);
        
    _uniformMatrix = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    [_renderer resolveUniforms:_program];
	
exit:
    
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (result) {
        
        LoggerVideo(1, @"OK setup GL programm");
        
    } else {
        
        glDeleteProgram(_program);
        _program = 0;
    }
    
    return result;
}

- (void)updateVertices
{
    const BOOL fit      = (self.contentMode == UIViewContentModeScaleAspectFit);
    const float width   = _decoder.frameWidth;
    const float height  = _decoder.frameHeight;
    const float dH      = (float)_backingHeight / height;
    const float dW      = (float)_backingWidth	  / width;
    const float dd      = fit ? MIN(dH, dW) : MAX(dH, dW);
    const float h       = (height * dd / (float)_backingHeight);
    const float w       = (width  * dd / (float)_backingWidth );
    
    const float z       = 0;
    
    _vertices[0] = - w;
    _vertices[1] = - h;
    _vertices[2] = z;
    
    _vertices[3] =   w;
    _vertices[4] = - h;
    _vertices[5] = z;
    
    _vertices[6] = - w;
    _vertices[7] =   h;
    _vertices[8] = z;
    
    _vertices[9] =   w;
    _vertices[10] =   h;
    _vertices[11] = z;
    
}

- (void)render: (KxVideoFrame *) frame
{        
    static const GLfloat texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
	
    [EAGLContext setCurrentContext:_context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
	glUseProgram(_program);
        
    if (frame) {
        [_renderer setFrame:frame];        
    }
    
    if ([_renderer prepareRender]) {
        //*
//        CC3GLMatrix* projection = [CC3GLMatrix identity];
//        [projection populateFromFrustumLeft:-1 andRight:1 andBottom:-1 andTop:1 andNear:-1 andFar:1];
        GLfloat modelviewProj[16];
        mat4f_LoadOrtho(-1, 1, -1, 1, -1, 1, modelviewProj);
        
        kmMat4 model;
        kmMat4Fill(&model, modelviewProj);
        kmMat4Translation(&model, _offset.x / self.bounds.size.width * 2, _offset.y / self.bounds.size.height * 2, 0);
        kmMat4Scaling(&model, _focalLength, _focalLength, _focalLength);
        
//        [model multiplyByMatrix:projection];
        
        glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, model.mat);
        /*/
        GLfloat modelviewProj[16];
        mat4f_LoadOrtho(-1, 1, -1, 1, -1, 1, modelviewProj);
        glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
        //*/
        glVertexAttribPointer(ATTRIBUTE_VERTEX, 3, GL_FLOAT, 0, 0, _vertices);
        glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
        glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
        
    #if 0
        if (!validateProgram(_program))
        {
            LoggerVideo(0, @"Failed to validate program");
            return;
        }
    #endif
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);        
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void) onPinchRecognized:(UIPinchGestureRecognizer*)pinchRecognizer {
    switch (pinchRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            _prevFocalLength = _focalLength;
            break;
        case UIGestureRecognizerStateChanged:
        {
            _focalLength = _prevFocalLength * pinchRecognizer.scale;
//            [self requestRedraw];
            NSLog(@"_focalLength = %f", _focalLength);
        }
            break;
        default:
            break;
    }
}

- (void) onPanRecognized:(UIPanGestureRecognizer*)panRecognizer {
    switch (panRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            _prevOffset = _offset;
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint diff = [panRecognizer translationInView:self];
            _offset.x = _prevOffset.x + diff.x;
            _offset.y = _prevOffset.y - diff.y;
            
            [self render:nil];
        }
            break;
        default:
            break;
    }
}

@end
