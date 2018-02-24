//
//  GLVAO.cpp
//  Madv360_v1
//
//  Created by QiuDong on 2017/8/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#include "GLVAO.h"
#include <string.h>

#pragma mark    GLVAO & Impl

class GLVAOImpl {
public:
    virtual ~GLVAOImpl() {
        releaseGLObjects();
    }
    
    GLVAOImpl(AutoRef<Mesh3D> mesh, GLenum usageHint);
    
    void refreshData(AutoRef<Mesh3D> mesh, GLenum usageHint);
    
    void releaseGLObjects();
    
    void draw(int positionSlot, int colorSlot, int texcoordSlot);
    
    void drawMadvMesh(int positionSlot, int vertexRoleSlot, int dstTexcoordSlot);
    
    void drawMadvLUTMappedMesh(int positionSlot, int leftTexcoordSlot, int rightTexcoordSlot, int dstTexcoordSlot);
    
protected:
    
    GLint _vao;
    GLuint _vertexBuffer;
    GLuint* _indexBuffers;
    AutoRef<Mesh3D> _mesh;
};


GLVAO::GLVAO(AutoRef<Mesh3D> mesh, GLenum usageHint) {
    _impl = new GLVAOImpl(mesh, usageHint);
}

void GLVAO::refreshData(AutoRef<Mesh3D> mesh, GLenum usageHint) {
    GLVAOImpl* impl = (GLVAOImpl*) _impl;
    if (!impl) return;
    
    impl->refreshData(mesh, usageHint);
}

void GLVAO::releaseGLObjects() {
    GLVAOImpl* impl = (GLVAOImpl*) _impl;
    if (!impl) return;
    delete impl;
    _impl = NULL;
}

void GLVAO::draw(int positionSlot, int colorSlot, int texcoordSlot) {
    GLVAOImpl* impl = (GLVAOImpl*) _impl;
    if (!impl) return;
    
    impl->draw(positionSlot, colorSlot, texcoordSlot);
}

void GLVAO::drawMadvMesh(int positionSlot, int vertexRoleSlot, int dstTexcoordSlot) {
    GLVAOImpl* impl = (GLVAOImpl*) _impl;
    if (!impl) return;
    
    impl->drawMadvMesh(positionSlot, vertexRoleSlot, dstTexcoordSlot);
}

void GLVAO::drawMadvLUTMappedMesh(int positionSlot, int leftTexcoordSlot, int rightTexcoordSlot, int dstTexcoordSlot) {
    GLVAOImpl* impl = (GLVAOImpl*) _impl;
    if (!impl) return;
    
    impl->drawMadvLUTMappedMesh(positionSlot, leftTexcoordSlot, rightTexcoordSlot, dstTexcoordSlot);
}

void GLVAOImpl::releaseGLObjects() {
    if (NULL != _indexBuffers)
    {
        ALOGE("\nGLVAOImpl::releaseGLObjects() (%lx): _indexBuffers=%lx\n", (long)this, (long)_indexBuffers);///!!!For Debug
        glDeleteBuffers(_mesh->primitiveCount(), _indexBuffers);
        free(_indexBuffers);
        _indexBuffers = NULL;
    }

    if (0 < _vertexBuffer)
    {
        ALOGE("\nGLVAOImpl::releaseGLObjects() (%lx): _vertexBuffer=%d\n", (long)this, _vertexBuffer);///!!!For Debug
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }

    if (0 < _vao)
    {
        ALOGE("\nGLVAOImpl::releaseGLObjects() (%lx): _vao=%d\n", (long)this, _vao);///!!!For Debug
        glDeleteVertexArraysOES(1, (GLuint*)&_vao);
        _vao = 0;
    }
    
    _mesh = NULL;
}

GLVAOImpl::GLVAOImpl(AutoRef<Mesh3D> mesh, GLenum usageHint)
:_vao(0)
, _vertexBuffer(0)
, _indexBuffers(NULL)
, _mesh(NULL)
{
    if (usageHint != GL_STATIC_DRAW && usageHint != GL_DYNAMIC_DRAW && usageHint != GL_STREAM_DRAW)
    {
        usageHint = GL_STATIC_DRAW;
    }
    CHECK_GL_ERROR();
    this->_mesh = mesh;
    
    GLint prevVAO;
    GLint prevElementBuffer;
    GLint prevBuffer;
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &prevVAO);
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &prevElementBuffer);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &prevBuffer);
    CHECK_GL_ERROR();
    _indexBuffers = (GLuint*) malloc(sizeof(GLuint) * _mesh->primitiveCount());
    memset(_indexBuffers, 0, sizeof(GLuint) * _mesh->primitiveCount());
    
    _vao = 0;
    _vertexBuffer = 0;
    glGenVertexArraysOES(1, (GLuint*)&_vao);
    CHECK_GL_ERROR();
    glBindVertexArrayOES(_vao);
    CHECK_GL_ERROR();
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(P4C4T2f) * _mesh->vertexCount(), _mesh->vertices(), usageHint);
    CHECK_GL_ERROR();
    glGenBuffers(_mesh->primitiveCount(), _indexBuffers);
    for (int i=0; i<_mesh->primitiveCount(); ++i)
    {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffers[i]);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * _mesh->primitives()[i]->indexCount, _mesh->primitives()[i]->indices, usageHint);
    }
    CHECK_GL_ERROR();
    glBindVertexArrayOES(prevVAO);
    glBindBuffer(GL_ARRAY_BUFFER, prevBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, prevElementBuffer);
}

void GLVAOImpl::refreshData(AutoRef<Mesh3D> mesh, GLenum usageHint) {
    if (usageHint != GL_STATIC_DRAW && usageHint != GL_DYNAMIC_DRAW && usageHint != GL_STREAM_DRAW)
    {
        usageHint = GL_STATIC_DRAW;
    }
    
    this->_mesh = mesh;
    
    GLint prevVAO;
    GLint prevElementBuffer;
    GLint prevBuffer;
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &prevVAO);
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &prevElementBuffer);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &prevBuffer);
    
    glBindVertexArrayOES(_vao);
    CHECK_GL_ERROR();
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(P4C4T2f) * _mesh->vertexCount(), _mesh->vertices(), usageHint);
    CHECK_GL_ERROR();
    for (int i=0; i<_mesh->primitiveCount(); ++i)
    {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffers[i]);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * _mesh->primitives()[i]->indexCount, _mesh->primitives()[i]->indices, usageHint);
    }
    CHECK_GL_ERROR();
    glBindVertexArrayOES(prevVAO);
    glBindBuffer(GL_ARRAY_BUFFER, prevBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, prevElementBuffer);
}

void GLVAOImpl::draw(int positionSlot, int colorSlot, int texcoordSlot) {
    GLint prevVAO;
    GLint prevElementBuffer;
    GLint prevBuffer;
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &prevVAO);
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &prevElementBuffer);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &prevBuffer);
    
    glBindVertexArrayOES(_vao);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    CHECK_GL_ERROR();
    // Enable the "aPosition" vertex attribute.
    if (positionSlot >= 0)
    {
        glEnableVertexAttribArray(positionSlot);
        //        GlUtil.checkGlError("glEnableVertexAttribArray");
        glVertexAttribPointer(positionSlot, 4, GL_FLOAT, false, sizeof(GLfloat) * 10, 0);
    }
    if (colorSlot >= 0) {
        glEnableVertexAttribArray(colorSlot);
        //        GlUtil.checkGlError("glEnableVertexAttribArray");
        glVertexAttribPointer(colorSlot, 4, GL_FLOAT, false, sizeof(GLfloat) * 10, (const GLvoid*) (sizeof(GLfloat) * 4));
    }
    if (texcoordSlot >= 0)
    {
        // Enable the "aTextureCoord" vertex attribute.
        glEnableVertexAttribArray(texcoordSlot);
        //        GlUtil.checkGlError("glEnableVertexAttribArray");
        glVertexAttribPointer(texcoordSlot, 2, GL_FLOAT, false, sizeof(GLfloat) * 10, (const GLvoid*) (sizeof(GLfloat) * 8));
    }
    
    for (int i = 0; i < _mesh->primitiveCount(); ++i)
    {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffers[i]);
        glDrawElements(_mesh->primitives()[i]->type, _mesh->primitives()[i]->indexCount, GL_UNSIGNED_INT, 0);
    }
    CHECK_GL_ERROR();
    
    if (positionSlot >= 0) glDisableVertexAttribArray(positionSlot);
    if (colorSlot >= 0) glDisableVertexAttribArray(colorSlot);
    if (texcoordSlot >= 0) glDisableVertexAttribArray(texcoordSlot);
    
    glBindVertexArrayOES(prevVAO);
    glBindBuffer(GL_ARRAY_BUFFER, prevBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, prevElementBuffer);
}

void GLVAOImpl::drawMadvMesh(int positionSlot, int vertexRoleSlot, int dstTexcoordSlot) {
    GLint prevVAO;
    GLint prevElementBuffer;
    GLint prevBuffer;
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &prevVAO);
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &prevElementBuffer);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &prevBuffer);
    CHECK_GL_ERROR();
    glBindVertexArrayOES(_vao);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    CHECK_GL_ERROR();
    // Enable the "aPosition" vertex attribute.
    if (positionSlot >= 0)
    {
        glEnableVertexAttribArray(positionSlot);
        //        GlUtil.checkGlError("glEnableVertexAttribArray");
        glVertexAttribPointer(positionSlot, 4, GL_FLOAT, false, sizeof(GLfloat) * 10, 0);
    }
    CHECK_GL_ERROR();
    if (vertexRoleSlot >= 0) {
        glEnableVertexAttribArray(vertexRoleSlot);
        //        GlUtil.checkGlError("glEnableVertexAttribArray");
        glVertexAttribPointer(vertexRoleSlot, 1, GL_FLOAT, false, sizeof(GLfloat) * 10, (const GLvoid*) (sizeof(GLfloat) * 7));
    }
    CHECK_GL_ERROR();
    if (dstTexcoordSlot)
    {
        glEnableVertexAttribArray(dstTexcoordSlot);
        glVertexAttribPointer(dstTexcoordSlot, 2, GL_FLOAT, false, sizeof(GLfloat) * 10, (const GLvoid*) (sizeof(GLfloat) * 8));
    }
    CHECK_GL_ERROR();
    for (int i = 0; i < _mesh->primitiveCount(); ++i)
    {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffers[i]);
        glDrawElements(_mesh->primitives()[i]->type, _mesh->primitives()[i]->indexCount, GL_UNSIGNED_INT, 0);
    }
    //    GlUtil.checkGlError("glDrawElements");
    CHECK_GL_ERROR();
    if (positionSlot >= 0) glDisableVertexAttribArray(positionSlot);
    if (vertexRoleSlot >= 0) glDisableVertexAttribArray(vertexRoleSlot);
    if (dstTexcoordSlot >= 0) glDisableVertexAttribArray(dstTexcoordSlot);
    CHECK_GL_ERROR();
    glBindVertexArrayOES(prevVAO);
    glBindBuffer(GL_ARRAY_BUFFER, prevBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, prevElementBuffer);
    CHECK_GL_ERROR();
}

void GLVAOImpl::drawMadvLUTMappedMesh(int positionSlot, int leftTexcoordSlot, int rightTexcoordSlot, int dstTexcoordSlot) {
    //  P4C4T2f: C0~1 LeftTexcoord, C2~3 RightTexcoord
    GLint prevVAO;
    GLint prevElementBuffer;
    GLint prevBuffer;
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &prevVAO);
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &prevElementBuffer);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &prevBuffer);
    CHECK_GL_ERROR();
    glBindVertexArrayOES(_vao);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    CHECK_GL_ERROR();
    // Enable the "aPosition" vertex attribute.
    if (positionSlot >= 0)
    {
        glEnableVertexAttribArray(positionSlot);
        //        GlUtil.checkGlError("glEnableVertexAttribArray");
        glVertexAttribPointer(positionSlot, 4, GL_FLOAT, false, sizeof(GLfloat) * 10, 0);
    }
    if (leftTexcoordSlot >= 0) {
        glEnableVertexAttribArray(leftTexcoordSlot);
        //        GlUtil.checkGlError("glEnableVertexAttribArray");
        glVertexAttribPointer(leftTexcoordSlot, 2, GL_FLOAT, false, sizeof(GLfloat) * 10, (const GLvoid*) (sizeof(GLfloat) * 4));
    }
    if (rightTexcoordSlot >= 0) {
        glEnableVertexAttribArray(rightTexcoordSlot);
        //        GlUtil.checkGlError("glEnableVertexAttribArray");
        glVertexAttribPointer(rightTexcoordSlot, 2, GL_FLOAT, false, sizeof(GLfloat) * 10, (const GLvoid*) (sizeof(GLfloat) * 6));
    }
    if (dstTexcoordSlot)
    {
        glEnableVertexAttribArray(dstTexcoordSlot);
        glVertexAttribPointer(dstTexcoordSlot, 2, GL_FLOAT, false, sizeof(GLfloat) * 10, (const GLvoid*) (sizeof(GLfloat) * 8));
    }
    CHECK_GL_ERROR();
    for (int i = 0; i < _mesh->primitiveCount(); ++i)
    {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffers[i]);
        glDrawElements(_mesh->primitives()[i]->type, _mesh->primitives()[i]->indexCount, GL_UNSIGNED_INT, 0);
    }
    //    GlUtil.checkGlError("glDrawElements");
    CHECK_GL_ERROR();
    if (positionSlot >= 0) glDisableVertexAttribArray(positionSlot);
    if (leftTexcoordSlot >= 0) glDisableVertexAttribArray(leftTexcoordSlot);
    if (rightTexcoordSlot >= 0) glDisableVertexAttribArray(rightTexcoordSlot);
    if (dstTexcoordSlot >= 0) glDisableVertexAttribArray(dstTexcoordSlot);
    CHECK_GL_ERROR();
    glBindVertexArrayOES(prevVAO);
    glBindBuffer(GL_ARRAY_BUFFER, prevBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, prevElementBuffer);
    CHECK_GL_ERROR();
}
