//
//  GLVAO.hpp
//  Madv360_v1
//
//  Created by QiuDong on 2017/8/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#ifndef GLVAO_hpp
#define GLVAO_hpp

#include "OpenGLHelper.h"
#include "AutoRef.h"
#include "Mesh3D.h"

class GLVAO {
public:
    virtual ~GLVAO() {
        releaseGLObjects();
    }
    
    GLVAO(AutoRef<Mesh3D> mesh, GLenum usageHint);
    
    void refreshData(AutoRef<Mesh3D> mesh, GLenum usageHint);
    
    void releaseGLObjects();
    
    void draw(int positionSlot, int colorSlot, int texcoordSlot);
    
    void drawMadvMesh(int positionSlot, int vertexRoleSlot, int dstTexcoordSlot);
    
    void drawMadvLUTMappedMesh(int positionSlot, int leftTexcoordSlot, int rightTexcoordSlot, int dstTexcoordSlot);
    
private:
    
    void* _impl = NULL;
};

//typedef AutoRef<GLVAO> GLVAORef;

#endif /* GLVAO_hpp */
