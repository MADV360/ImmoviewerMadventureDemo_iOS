//
//  GLFilter.cpp
//  Madv360_v1
//
//  Created by QiuDong on 16/7/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#include "GLFilter.h"
#include "mat4.h"
#include "string.h"

static AutoRef<Mesh3D> s_normalQuad = NULL;

GLFilter::~GLFilter() {
    releaseGLObjects();
    releaseShaderSources();
}

GLFilter::GLFilter(const GLchar** vertexShaderSources, int vertexShaderSourceCount, const GLchar** fragmentShaderSources, int fragmentShaderSourceCount) {
#if defined(TARGET_OS_WINDOWS)
    const GLchar* VersionDirectiveStatement = GLSLPredefinedMacros();
	_vertexShaderSourceCount = vertexShaderSourceCount + 1;
	_fragmentShaderSourceCount = fragmentShaderSourceCount + 1;
#else
    const GLchar* VersionDirectiveStatement = GLSLPredefinedMacros();
    _vertexShaderSourceCount = vertexShaderSourceCount + 1;
    _fragmentShaderSourceCount = fragmentShaderSourceCount + 1;
#endif
    size_t predefinedMacrosSize = (size_t)strlen(VersionDirectiveStatement) + 1;

	_vertexShaderSources = (GLchar**) malloc(sizeof(GLchar*) * _vertexShaderSourceCount);
	_fragmentShaderSources = (GLchar**)malloc(sizeof(GLchar*) * _fragmentShaderSourceCount);

	int iSource;
	_vertexShaderSources[0] = (GLchar*) malloc(predefinedMacrosSize);
	memcpy(_vertexShaderSources[0], VersionDirectiveStatement, predefinedMacrosSize);
	iSource = 1;
	for (int i = 0; i < vertexShaderSourceCount; ++i, ++iSource)
	{
		int length = (int) strlen(vertexShaderSources[i]);
		_vertexShaderSources[iSource] = (GLchar*) malloc(length + 1);
		_vertexShaderSources[iSource][length] = '\0';
		strcpy(_vertexShaderSources[iSource], vertexShaderSources[i]);
	}

	_fragmentShaderSources[0] = (GLchar*)malloc(predefinedMacrosSize);
	memcpy(_fragmentShaderSources[0], VersionDirectiveStatement, predefinedMacrosSize);
	iSource = 1;
	for (int i = 0; i < fragmentShaderSourceCount; ++i, ++iSource)
	{
		int length = (int) strlen(fragmentShaderSources[i]);
		_fragmentShaderSources[iSource] = (GLchar*)malloc(length + 1);
		_fragmentShaderSources[iSource][length] = '\0';
		strcpy(_fragmentShaderSources[iSource], fragmentShaderSources[i]);
	}
}

void GLFilter::render(GLVAO* ptrVAO, GLint sourceTexture, GLenum sourceTextureTarget) {

}

void GLFilter::prepareGLProgramSlots(GLint program) {

}

void GLFilter::render(GLfloat x, GLfloat y, GLfloat width, GLfloat height, GLint sourceTexture, GLenum sourceTextureTarget) {
    render(x,y,width,height, sourceTexture, sourceTextureTarget, OrientationNormal, Vec2f{0,0}, Vec2f{1,1});
}

void GLFilter::render(GLfloat x, GLfloat y, GLfloat width, GLfloat height, GLint sourceTexture, GLenum sourceTextureTarget, Orientation2D sourceOrientation, Vec2f texcoordOrigin, Vec2f texcoordSize) {
    if (_glProgram < 0)
    {
        initGLObjects();
    }

    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    CHECK_GL_ERROR();

    Vec2f viewportOrigin = {(GLfloat)viewport[0], (GLfloat)viewport[1]};
    Vec2f viewportSize = {(GLfloat)viewport[2], (GLfloat)viewport[3]};
    _boundRectOrigin = {(GLfloat)x, (GLfloat)y};
    _boundRectSize = {(GLfloat)width, (GLfloat)height};
    kmMat4 screenMatrix;
    transformMatrix4InNormalizedCoordSystem2D(screenMatrix.mat, viewportOrigin, viewportSize, _boundRectOrigin, _boundRectSize, sourceOrientation);

    _texcoordOrigin = texcoordOrigin;
    _texcoordSize = texcoordSize;
    
    if (!_vao)
    {
        if (!s_normalQuad)
        {
            s_normalQuad = Mesh3D::createTrivialQuad();
        }
        _vao = new GLVAO(s_normalQuad, GL_DYNAMIC_DRAW);
    }
    CHECK_GL_ERROR();

    if (sourceTextureTarget == GL_TEXTURE_2D)
    {
        prepareGLProgram();
        glUseProgram( _glProgram);
    }
    else if (sourceTextureTarget == GL_TEXTURE_EXTERNAL_OES)
    {
        prepareExtGLProgram();
        glUseProgram(_glExtProgram);
    }

    glUniformMatrix4fv(_uniScreenMatrix, 1, false, screenMatrix.mat);
    glUniform2f(_uniTexcoordOrigin, texcoordOrigin.s, texcoordOrigin.t);
    glUniform2f(_uniTexcoordSize, texcoordSize.width, texcoordSize.height);

    glDisable(GL_CULL_FACE);
    
    render(_vao, sourceTexture, sourceTextureTarget);
}

void GLFilter::initGLObjects() {
    prepareGLProgram();

    _uniScreenMatrix = glGetUniformLocation(_glProgram, "u_screenMatrix");
    _uniTexcoordOrigin = glGetUniformLocation(_glProgram, "u_texcoordOrigin");
    _uniTexcoordSize = glGetUniformLocation(_glProgram, "u_texcoordSize");
    prepareGLProgramSlots(_glProgram);
}

void GLFilter::releaseGLObjects() {
    if (_vao)
    {
        _vao->releaseGLObjects();
        _vao = NULL;
    }
    if (_glProgram >= 0)
    {
        glDeleteProgram(_glProgram);
        _glProgram = -1;
    }
    if (_glExtProgram >= 0)
    {
        glDeleteProgram(_glExtProgram);
        _glExtProgram = -1;
    }
}

void GLFilter::releaseShaderSources() {
	if (_vertexShaderSources)
	{
		for (int i = 0; i < _vertexShaderSourceCount; ++i)
		{
			delete[] _vertexShaderSources[i];
		}
		delete[] _vertexShaderSources;
		_vertexShaderSources = NULL;
	}

	if (_fragmentShaderSources)
	{
		for (int i = 0; i < _fragmentShaderSourceCount; ++i)
		{
			delete[] _fragmentShaderSources[i];
		}
		delete[] _fragmentShaderSources;
		_fragmentShaderSources = NULL;
	}
}

void GLFilter::prepareGLProgram() {
    if (_glProgram >= 0)
		return;

    _glProgram = compileAndLinkShaderProgram(_vertexShaderSources, _vertexShaderSourceCount, _fragmentShaderSources, _fragmentShaderSourceCount);

	releaseShaderSources();
}

void GLFilter::prepareExtGLProgram() {
    if (_glExtProgram >= 0) return;

    GLchar fragmentHeader[] = "#define EXTERNAL\n#define FOR_520\n#extension GL_OES_EGL_image_external : require\n";
    GLchar** mergedFragmentShaderSources = new GLchar*[_fragmentShaderSourceCount + 1];
    memcpy(&mergedFragmentShaderSources[1], _fragmentShaderSources, sizeof(GLchar*) * _fragmentShaderSourceCount);
    mergedFragmentShaderSources[0] = fragmentHeader;
    _glExtProgram = compileAndLinkShaderProgram(_vertexShaderSources, _vertexShaderSourceCount, (const GLchar* const*)mergedFragmentShaderSources, _fragmentShaderSourceCount + 1);

    delete[] mergedFragmentShaderSources;
}

//bool GLFilter::setMesh(Mesh3D& mesh) {
//    if (!_mesh)
//    {
//        _mesh = new Mesh3D(mesh.vertexCount, mesh.primitiveCount);
//    }
//
//    return _mesh->copy(mesh);
//}

//Mesh3DRef GLFilter::transformQuadTexcoords(Mesh3DRef mesh, GLFilterOrientation orientation) {
//    if (!mesh) return NULL;
//
//    P4C4T2f& v0 = mesh->vertices[0];
//    P4C4T2f& v1 = mesh->vertices[1];
//    P4C4T2f& v2 = mesh->vertices[2];
//    P4C4T2f& v3 = mesh->vertices[3];
//    Vec2f texcoord0 = v0.texcoord;
//    Vec2f texcoord1 = v1.texcoord;
//    Vec2f texcoord2 = v2.texcoord;
//
//    switch (orientation)
//    {
//        case GLFilterOrientationNormal:
//            break;
//        case GLFilterOrientationRotateLeft:
//            v0.texcoord = v1.texcoord;
//            v1.texcoord = v2.texcoord;
//            v2.texcoord = v3.texcoord;
//            v3.texcoord = texcoord0;
//            break;
//        case GLFilterOrientationRotateRight:
//            v0.texcoord = v3.texcoord;
//            v2.texcoord = v1.texcoord;
//            v3.texcoord = texcoord2;
//            v1.texcoord = texcoord0;
//            break;
//        case GLFilterOrientationRotate180Degree:
//            v0.texcoord = v2.texcoord;
//            v1.texcoord = v3.texcoord;
//            v3.texcoord = texcoord1;
//            v2.texcoord = texcoord0;
//            break;
//        case GLFilterOrientationFlipHorizontal:
//            v0.texcoord = v3.texcoord;
//            v1.texcoord = v2.texcoord;
//            v2.texcoord = texcoord1;
//            v3.texcoord = texcoord0;
//            break;
//        case GLFilterOrientationRotateLeftFlipHorizontal:
//            v1.texcoord = v2.texcoord;
//            v3.texcoord = texcoord1;
//            break;
//        case GLFilterOrientationRotateRightFlipHorizontal:
//            v0.texcoord = texcoord2;
//            v2.texcoord = texcoord0;
//            break;
//        case GLFilterOrientationFlipVertical:
//            v0.texcoord = v1.texcoord;
//            v1.texcoord = texcoord0;
//            v2.texcoord = v3.texcoord;
//            v3.texcoord = texcoord2;
//            break;
//    }
//    return mesh;
//}
