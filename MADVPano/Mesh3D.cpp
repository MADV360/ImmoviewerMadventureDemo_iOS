//
//  Mesh3D.cpp
//  Madv360_v1
//
//  Created by QiuDong on 2017/8/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#include "Mesh3D.h"
#include "AutoRef.h"
#include <string.h>

#pragma mark    Mesh3D & Impl

P4C4T2f* Mesh3D::vertices() {
    return _vertices;
}

GLsizei Mesh3D::vertexCount() {
    return _vertexCount;
}

GLsizei Mesh3D::primitiveCount() {
    return _primitiveCount;
}

AutoRef<DrawablePrimitive>* Mesh3D::primitives() {
    return _primitives;
}

Mesh3D::~Mesh3D() {
    if (_vertices)
        free(_vertices);
    
    if (_primitiveCount > 0)
    {
        //        for (int i=0; i<_primitiveCount; ++i)
        //        {
        //            _primitives[i] = NULL;
        //        }
        _primitiveCount = 0;
        delete[] _primitives;
    }
}

Mesh3D::Mesh3D(int vertexCount, int primitiveCount) {
    this->_vertexCount = vertexCount;
    _vertices = (P4C4T2f*) malloc(sizeof(P4C4T2f) * _vertexCount);
    this->_primitiveCount = primitiveCount;
    _primitives = new AutoRef<DrawablePrimitive>[_primitiveCount];
    for (int i=0; i<_primitiveCount; ++i)
    {
        _primitives[i] = new DrawablePrimitive;
    }
}

bool Mesh3D::copy(const Mesh3D& other) {
    bool differ = (_vertexCount != other._vertexCount || _primitiveCount != other._primitiveCount);
    
    if (other._vertexCount > _vertexCount)
    {
        if (_vertices)
        {
            free(_vertices);
        }
        _vertices = (P4C4T2f*) malloc(sizeof(P4C4T2f) * other._vertexCount);
    }
    _vertexCount = other._vertexCount;
    memcpy(_vertices, other._vertices, sizeof(P4C4T2f) * _vertexCount);
    
    if (other._primitiveCount > _primitiveCount)
    {
        if (_primitives)
        {
            for (int i=0; i<_primitiveCount; ++i)
            {
                _primitives[i] = NULL;
            }
            delete[] _primitives;
        }
        
        _primitives = new AutoRef<DrawablePrimitive>[other._primitiveCount];
    }
    _primitiveCount = other._primitiveCount;
    for (int i=0; i<_primitiveCount; ++i)
    {
        _primitives[i] = other._primitives[i];
    }
    
    return differ;
}

Mesh3D* Mesh3D::createSphere(GLfloat radius, int longitudeSegments, int latitudeSegments, bool flipX, bool flipY) {
    // 2 Polars, (longitudeSegments + 1) Longitude circles, (latitudeSegments - 1) Latitude circles:
    // 2 Polar fans, (latitudeSegments - 2) strips:
    Mesh3D* mesh = new Mesh3D(2 + (longitudeSegments + 1) * (latitudeSegments - 1), latitudeSegments);
    // Vertices:
    mesh->_vertices[mesh->_vertexCount - 2] = P4C4T2fMake(0,radius,0,1, 0,1,0,1, 0.5,0);//North
    mesh->_vertices[mesh->_vertexCount - 1] = P4C4T2fMake(0,-radius,0,1, 0,1,0,1, 0.5,1);//South
    int iVertex = 0;
    for (int iLat=1; iLat<latitudeSegments; ++iLat)
    {
        GLfloat theta = M_PI * iLat / latitudeSegments;
        GLfloat y = radius * cos(theta);
        GLfloat t = flipY ? (GLfloat)iLat / (GLfloat)latitudeSegments : 1.f - (GLfloat)iLat / (GLfloat)latitudeSegments;
        GLfloat xzRadius = radius * sin(theta);
        for (int iLon=0; iLon<=longitudeSegments; ++iLon)
        {
            GLfloat phi = 2 * M_PI * iLon / longitudeSegments + M_PI / 2.f;
            GLfloat x = -xzRadius * sin(phi);
            GLfloat z = xzRadius * cos(phi);
            GLfloat s = flipX ? 1 - (GLfloat)iLon / (GLfloat)longitudeSegments : (GLfloat)iLon / (GLfloat)longitudeSegments;
            mesh->_vertices[iVertex++] = P4C4T2fMake(x,y,z,1, 0,1,0,1, s,t);
        }
    }
    // Indices:
    // North&South polar fan:
    for (int i=0; i<2; i++)
    {
        mesh->_primitives[i]->type = GL_TRIANGLE_FAN;
        mesh->_primitives[i]->indexCount = longitudeSegments + 2;
        mesh->_primitives[i]->indices = (GLuint*) malloc(sizeof(GLuint) * (longitudeSegments + 2));
        mesh->_primitives[i]->indices[0] = mesh->_vertexCount - 2 + i;
        GLuint* pDst = &mesh->_primitives[i]->indices[1];
        int index = (i == 0 ? 0 : mesh->_vertexCount - 3 - longitudeSegments);
        for (int i=longitudeSegments; i>=0; --i) *pDst++ = index++;
    }
    // Strips parallel with latitude circles:
    for (int i=2; i<mesh->_primitiveCount; ++i)
    {
        mesh->_primitives[i]->type = GL_TRIANGLE_STRIP;
        mesh->_primitives[i]->indexCount = 2 * (longitudeSegments + 1);
        mesh->_primitives[i]->indices = (GLuint*) malloc(sizeof(GLuint) * mesh->_primitives[i]->indexCount);
        GLuint* pDst = mesh->_primitives[i]->indices;
        GLuint index = (i - 2) * (longitudeSegments + 1);
        for (int j=longitudeSegments; j>=0; --j)
        {
            *pDst++ = index;
            *pDst++ = (index + longitudeSegments + 1);
            ++index;
        }
    }
    return mesh;
}

Mesh3D* Mesh3D::createRedundantGrids(GLfloat width, GLfloat height, int columns, int rows0, int rows1, bool flipX, bool flipY) {
    typedef enum : int {
        LT0 = 0,
        LB1 = 1,
        RT2 = 2,
        RT3 = 3,
        LB4 = 4,
        RB5 = 5,
    } VertexRole;
    GLfloat roles[6];
    for (int i=0; i<6; ++i)
    {
        roles[i] = (float)i / 5;
    }
    
    GLfloat minX = width / 2.f;
    GLfloat maxX = -minX;
    GLfloat minY = height / 2.f;
    GLfloat maxY = -minY;
    Mesh3D* mesh = new Mesh3D(6 * columns * rows0, 1);
    GLfloat shrinkRatio0 = (float)rows0 / (float)rows1;
    int iVertex = 0;
    for (int iRow=0; iRow<rows0; ++iRow)
    {
        GLfloat rowT = (GLfloat) (flipY ? iRow : rows0 - iRow);
        GLfloat rowB = (GLfloat) (flipY ? iRow + 1 : rows0 - iRow - 1);
        
        GLfloat tT = rowT / (GLfloat)rows0;
        GLfloat sinAlphaT = sinf(M_PI * tT);
        GLfloat shrinkRatioT = (1.f - sinAlphaT) * shrinkRatio0 + sinAlphaT;
//        ALOGE("Before shrink: tT=%f, shrinkRatio=%f", tT, shrinkRatioT);
        tT = (tT < 0.5f ? shrinkRatioT * tT : 1.f - shrinkRatioT * (1.f - tT));
//        ALOGE("After shrink: tT=%f", tT);
        
        GLfloat tB = rowB / (GLfloat)rows0;
        GLfloat sinAlphaB = sinf(M_PI * tB);
        GLfloat shrinkRatioB = (1.f - sinAlphaB) * shrinkRatio0 + sinAlphaB;
//        ALOGE("Before shrink: tB=%f, shrinkRatio=%f", tB, shrinkRatioB);
        tB = (tB < 0.5f ? shrinkRatioB * tB : 1.f - shrinkRatioB * (1.f - tB));
//        ALOGE("After shrink: tB=%f", tB);
        
        GLfloat yT = height / 2.f - height * (flipY ? tT : 1.f - tT);
        GLfloat yB = height / 2.f - height * (flipY ? tB : 1.f - tB);
        
        if (yT > maxY) maxY = yT;
        if (yB < minY) minY = yB;
        
        for (int iCol=0; iCol<columns; ++iCol)
        {
            GLfloat colL = (GLfloat) (flipX ? columns - iCol : iCol);
            GLfloat colR = (GLfloat) (flipX ? columns - iCol - 1 : iCol + 1);
            
            GLfloat xL = width * iCol / columns - width / 2.f;
            GLfloat sL = colL / (GLfloat)columns;
            GLfloat xR = width * (iCol + 1) / columns - width / 2.f;
            GLfloat sR = colR / (GLfloat)columns;
            
            if (xR > maxX) maxX = xR;
            if (xL < minX) minX = xL;
            //*
            //LT-LB-RT
            mesh->_vertices[iVertex++] = P4C4T2fMake(xL,yT,0.f,1.f, 0,1,0,roles[LT0], sL,tT);
            mesh->_vertices[iVertex++] = P4C4T2fMake(xL,yB,0.f,1.f, 0,1,0,roles[LB1], sL,tB);
            mesh->_vertices[iVertex++] = P4C4T2fMake(xR,yT,0.f,1.f, 0,1,0,roles[RT2], sR,tT);
            //RT-LB-RB
            mesh->_vertices[iVertex++] = P4C4T2fMake(xR,yT,0.f,1.f, 0,1,0,roles[RT3], sR,tT);
            mesh->_vertices[iVertex++] = P4C4T2fMake(xL,yB,0.f,1.f, 0,1,0,roles[LB4], sL,tB);
            mesh->_vertices[iVertex++] = P4C4T2fMake(xR,yB,0.f,1.f, 0,1,0,roles[RB5], sR,tB);
            /*/
            //LT-LB-RT
            mesh->_vertices[iVertex++] = P4C4T2fMake(xL,yT,0.f,1.f, 0,1,0,roles[LT0], colL,rowT);
            mesh->_vertices[iVertex++] = P4C4T2fMake(xL,yB,0.f,1.f, 0,1,0,roles[LB1], colL,rowB);
            mesh->_vertices[iVertex++] = P4C4T2fMake(xR,yT,0.f,1.f, 0,1,0,roles[RT2], colR,rowT);
            //RT-LB-RB
            mesh->_vertices[iVertex++] = P4C4T2fMake(xR,yT,0.f,1.f, 0,1,0,roles[RT3], colR,rowT);
            mesh->_vertices[iVertex++] = P4C4T2fMake(xL,yB,0.f,1.f, 0,1,0,roles[LB4], colL,rowB);
            mesh->_vertices[iVertex++] = P4C4T2fMake(xR,yB,0.f,1.f, 0,1,0,roles[RB5], colR,rowB);
            //*/
        }
    }
    ALOGE("\nminX=%f, maxX=%f, minY=%f, maxY=%f\n", minX, maxX, minY, maxY);
    mesh->_primitives[0]->type = GL_TRIANGLES;
    mesh->_primitives[0]->indexCount = mesh->_vertexCount;
    mesh->_primitives[0]->indices = (GLuint*) malloc(sizeof(GLuint) * mesh->_primitives[0]->indexCount);
    GLuint* pDst = mesh->_primitives[0]->indices;
    for (int iI=0; iI<mesh->_primitives[0]->indexCount; ++iI)
    {
        *(pDst++) = iI;
    }
    
    return mesh;
}

Mesh3D* Mesh3D::createGrids(GLfloat width, GLfloat height, int columns, int rows, bool flipX, bool flipY) {
    Mesh3D* mesh = new Mesh3D((columns + 1) * (rows + 1), 1);
    int iVertex = 0;
    for (int iRow=0; iRow<=rows; ++iRow)
    {
        GLfloat y = height / 2.f - height * iRow / rows;
        GLfloat t = flipY ? (GLfloat)iRow / (GLfloat)rows : 1.f - (GLfloat)iRow / (GLfloat)rows;
        for (int iCol=0; iCol<=columns; ++iCol)
        {
            GLfloat x = width * iCol / columns - width / 2.f;
            GLfloat z = 0;
            GLfloat s = flipX ? 1 - (GLfloat)iCol / (GLfloat)columns : (GLfloat)iCol / (GLfloat)columns;
            mesh->_vertices[iVertex++] = P4C4T2fMake(x,y,z,1, 0,1,0,1, s,t);
        }
    }
    // Indices:
    // Strips parallel with latitude circles:
    // And we use degenerate triangles: http://www.learnopengles.com/tag/triangle-strips/
    mesh->_primitives[0]->type = GL_TRIANGLE_STRIP;
    mesh->_primitives[0]->indexCount = 2 * (columns + 2) * rows;
    mesh->_primitives[0]->indices = (GLuint*) malloc(sizeof(GLuint) * mesh->_primitives[0]->indexCount);
    GLuint index = 0;
    GLuint* pDst = mesh->_primitives[0]->indices;
    for (int i=0; i<rows; ++i)
    {
        for (int j=columns; j>=0; --j)
        {
            *pDst++ = index;
            *pDst++ = (index + columns + 1);
            ++index;
        }
        *pDst++ = (index + columns);
        *pDst++ = index;
    }
    return mesh;
}

Mesh3D* Mesh3D::createSphereV0(GLfloat radius, int longitudeSegments, int latitudeSegments, bool flipX, bool flipY) {
    // (longitudeSegments + 1) Longitude circles, (latitudeSegments + 1) Latitude circles:
    // (latitudeSegments) strips:
    Mesh3D* mesh = new Mesh3D((longitudeSegments + 1) * (latitudeSegments + 1), 1);
    // Vertices:
    int iVertex = 0;
    for (int iLat=0; iLat<=latitudeSegments; ++iLat)
    {
        GLfloat row = (GLfloat) (flipY ? iLat : latitudeSegments - iLat);
        
        GLfloat theta = M_PI * iLat / latitudeSegments;
        GLfloat y = radius * cos(theta);
        GLfloat t = row / (GLfloat)latitudeSegments;
        GLfloat xzRadius = radius * sin(theta);
        for (int iLon=0; iLon<longitudeSegments; ++iLon)
        {
            GLfloat col = (GLfloat) (flipX ? longitudeSegments - iLon : iLon);
            
            GLfloat phi = 2*M_PI * iLon / longitudeSegments;
            GLfloat x = -xzRadius * sin(phi);
            GLfloat z = xzRadius * cos(phi);
            GLfloat s = col / (GLfloat)longitudeSegments;
            //            ///!!!For Debug:
            //            s += 0.5f;
            //            if (s > 1.0) s -= 1.0;
            //            ///!!!:For Debug
            mesh->_vertices[iVertex++] = P4C4T2fMake(x,y,z,1, 0,1,0,1, s,t);
        }
        GLfloat col = (GLfloat) (flipX ? 0 : longitudeSegments);
        GLfloat s = col / (GLfloat)longitudeSegments;
        /*/!!!For Debug:
         mesh->_vertices[iVertex++] = P4C4T2fMake(0,y,xzRadius,1, 0,1,0,1, 0.5,t);
         /*/
        mesh->_vertices[iVertex++] = P4C4T2fMake(0,y,xzRadius,1, 0,1,0,1, s,t);
        //*/
    }
    // Indices:
    // Strips parallel with latitude circles,
    // And we use degenerate triangles: http://www.learnopengles.com/tag/triangle-strips/
    mesh->_primitives[0]->type = GL_TRIANGLE_STRIP;
    mesh->_primitives[0]->indexCount = 2 * (longitudeSegments + 2) * latitudeSegments;
    mesh->_primitives[0]->indices = (GLuint*) malloc(sizeof(GLuint) * mesh->_primitives[0]->indexCount);
    GLuint index = 0;
    GLuint* pDst = mesh->_primitives[0]->indices;
    for (int i=0; i<latitudeSegments; ++i)
    {
        for (int j=longitudeSegments; j>=0; --j)
        {
            *pDst++ = index;
            *pDst++ = (index + longitudeSegments + 1);
            ++index;
        }
        *pDst++ = (index + longitudeSegments);
        *pDst++ = index;
    }
    return mesh;
}

Mesh3D* Mesh3D::createQuad(P4C4T2f v0, P4C4T2f v1, P4C4T2f v2, P4C4T2f v3) {
    Mesh3D* quad = new Mesh3D(4, 1);
    quad->_vertices[0] = v0;
    quad->_vertices[1] = v1;
    quad->_vertices[2] = v2;
    quad->_vertices[3] = v3;
    
    quad->_primitives[0]->type = GL_TRIANGLE_STRIP;
    quad->_primitives[0]->indexCount = 4;
    quad->_primitives[0]->indices = (GLuint*) malloc(sizeof(GLuint) * 4);
    GLuint indices[] = {1,2,0,3};
    memcpy(quad->_primitives[0]->indices, indices, sizeof(indices));
    return quad;
}

Mesh3D* Mesh3D::createMeshWithContinuousVertices(P4C4T2f* vertices, int count, int primitiveType) {
    Mesh3D* lineStrip = new Mesh3D(count, 1);
    for (int i=0; i<count; ++i)
    {
        lineStrip->_vertices[i] = vertices[i];
    }
    
    lineStrip->_primitives[0]->type = primitiveType;
    lineStrip->_primitives[0]->indexCount = count;
    lineStrip->_primitives[0]->indices = (GLuint*) malloc(sizeof(GLuint) * count);
    for (int i=0; i<count; ++i)
    {
        lineStrip->_primitives[0]->indices[i] = i;
    }
    return lineStrip;
}

Mesh3D* Mesh3D::createTrivialQuad() {
    return createQuad(P4C4T2fMake(-1,1,0,1, 0,0,0,1, 0,1),//1
                      P4C4T2fMake(-1,-1,0,1, 0,0,0,1, 0,0),//0
                      P4C4T2fMake(1,-1,0,1, 0,0,0,1, 1,0),//3
                      P4C4T2fMake(1,1,0,1, 0,0,0,1, 1,1)//2
                      );
};

Mesh3D* Mesh3D::createSphereGaps(GLfloat radius, GLfloat topTheta, GLfloat bottomTheta, GLfloat ratio) {
    Mesh3D* mesh = new Mesh3D(4,1);///(8, 2);
    GLfloat thetas[] = {/*topTheta, */bottomTheta};
    for (int i=0; i<1; ++i)///i<2
    {
        // Vertices:
        GLfloat y = radius * cos(thetas[i]);
        GLfloat halfLength = radius * sin(thetas[i]) * sqrt(2.f) / 2.f;
        mesh->_vertices[i*4+0] = P4C4T2fMake(-halfLength,y,-halfLength/ratio,1, 0,0,0,1, i,0);
        mesh->_vertices[i*4+1] = P4C4T2fMake(-halfLength,y,halfLength/ratio,1, 0,0,0,1, i,1);
        mesh->_vertices[i*4+2] = P4C4T2fMake(halfLength,y,halfLength/ratio,1, 0,0,0,1, 1-i,1);
        mesh->_vertices[i*4+3] = P4C4T2fMake(halfLength,y,-halfLength/ratio,1, 0,0,0,1, 1-i,0);
        
        // Indices:
        mesh->_primitives[i]->type = GL_TRIANGLE_STRIP;
        mesh->_primitives[i]->indexCount = 4;
        mesh->_primitives[i]->indices = (GLuint*) malloc(sizeof(GLuint) * 4);
        mesh->_primitives[i]->indices[0] = i*4 + 0;
        mesh->_primitives[i]->indices[1] = i*4 + 1;
        mesh->_primitives[i]->indices[2] = i*4 + 3;
        mesh->_primitives[i]->indices[3] = i*4 + 2;
    }
    return mesh;
}

//typedef AutoRef<Mesh3D> Mesh3DRef;
