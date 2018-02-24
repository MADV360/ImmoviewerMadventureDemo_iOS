//
//  Mesh3D.hpp
//  Madv360_v1
//
//  Created by QiuDong on 2017/8/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#ifndef Mesh3D_hpp
#define Mesh3D_hpp

#include "OpenGLHelper.h"
#include "AutoRef.h"

class Mesh3D {
    //friend class GLVAOImpl;
    
public:
    virtual ~Mesh3D();
    Mesh3D(int vertexCount, int primitiveCount);
    
    bool copy(const Mesh3D& other);
    
    static Mesh3D* createSphere(GLfloat radius, int longitudeSegments, int latitudeSegments, bool flipX, bool flipY);
    static Mesh3D* createSphereV0(GLfloat radius, int longitudeSegments, int latitudeSegments, bool flipX, bool flipY);
    
    static Mesh3D* createGrids(GLfloat width, GLfloat height, int columns, int rows, bool flipX, bool flipY);
    static Mesh3D* createRedundantGrids(GLfloat width, GLfloat height, int columns, int rows0, int rows1, bool flipX, bool flipY);
    
    static Mesh3D* createQuad(P4C4T2f v0, P4C4T2f v1, P4C4T2f v2, P4C4T2f v3);
    
    static Mesh3D* createTrivialQuad();
    
    static Mesh3D* createMeshWithContinuousVertices(P4C4T2f* vertices, int count, int primitiveType);
    
    static Mesh3D* createSphereGaps(GLfloat radius, GLfloat topTheta, GLfloat bottomTheta, GLfloat ratio);
    
    P4C4T2f* vertices();
    GLsizei vertexCount();
    
    GLsizei primitiveCount();
    AutoRef<DrawablePrimitive>* primitives();
    
protected:
    
    P4C4T2f* _vertices = NULL;
    GLsizei _vertexCount;
    
    AutoRef<DrawablePrimitive>* _primitives = NULL;
    GLsizei _primitiveCount;
};

//typedef AutoRef<Mesh3D> Mesh3DRef;

#endif /* Mesh3D_hpp */
