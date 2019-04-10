//
//  Quad2DSprite.hpp
//  ClashRoyalHelper
//
//  Created by DOM QIU on 2018/11/12.
//  Copyright © 2018 QiuDong. All rights reserved.
//

#ifndef Quad2DSprite_hpp
#define Quad2DSprite_hpp

#include "Animator.hpp"
#include "kazmath.h"
#include "Mesh3D.h"
#include "OpenGLHelper.h"
#include "GLVAO.h"
#include "AutoRef.h"
#include <map>

#ifdef __cplusplus
extern "C" {
#endif

kmMat4 create2DProjectMatrix(float canvasWidth, float canvasHeight, float referenceWidth, float referenceHeight);

#ifdef __cplusplus
}
#endif

class Quad2DSprite {
public:
    
    virtual ~Quad2DSprite();
    
    Quad2DSprite(float pivotX, float pivotY, float width, float height, float z);//Pivot(x,y), Size(width, height)
    
    void setColors(kmVec4 lt, kmVec4 lb, kmVec4 rb, kmVec4 rt);
    
    inline kmVec4 getColorLT() {return _colorLT;}
    inline kmVec4 getColorLB() {return _colorLB;}
    inline kmVec4 getColorRB() {return _colorRB;}
    inline kmVec4 getColorRT() {return _colorRT;}
    
    void setTexcoords(kmVec2 lt, kmVec2 lb, kmVec2 rb, kmVec2 rt);
    
    inline kmVec2 getTexcoordLT() {return _texcoordLT;}
    inline kmVec2 getTexcoordLB() {return _texcoordLB;}
    inline kmVec2 getTexcoordRB() {return _texcoordRB;}
    inline kmVec2 getTexcoordRT() {return _texcoordRT;}
    
    kmVec2 getVertexLT() const;
    kmVec2 getVertexLB() const;
    kmVec2 getVertexRB() const;
    kmVec2 getVertexRT() const;
    
    inline float getWidth() const {return _width;}
    inline float getHeight() const {return _height;}
    
    inline float getZ() const {return _z;}
    inline void setZ(float z) {_z = z;}
    
    void update(float dt);
    
    inline void invalidateVertices() {_verticesValid = false;}
    
    bool isActionAnimating() const;
    
    void cancelAllActions();
    
    void startTranslateXAction(AutoRef<Animator> action);
    void startTranslateYAction(AutoRef<Animator> action);
    
    void startScaleXAction(AutoRef<Animator> action);
    void startScaleYAction(AutoRef<Animator> action);
    
    void startRotateZAction(AutoRef<Animator> action);
    
    void startTiltYAction(AutoRef<Animator> action);
    
    
    void moveBy(float dx, float dy, float interval);// Move pivot by
    
    void moveTo(float x, float y, float interval);// Move pivot to
    
    void moveToRect(float x0, float y0, float width, float height, float interval);
    
    void scaleBy(float dScaleX, float dScaleY, float interval);
    
    void scaleTo(float scaleX, float scaleY, float interval);
    
    void rotateZBy(float dDegree, float interval);
    
    void rotateZTo(float degree, float interval);
    
    void rotateZRepeatedly(float dDegree, float interval, int count);
    
    void shakeRepeatedly(float dX, float dY, float interval, int count);
    
    void tiltYBy(float dTilt, float interval);
    
    void tiltYTo(float tilt, float interval);

    void setPivotOffsetFromCenter(float dx, float dy);
    
    int tag = 0;
    
private:
    
    void updateVerticesIfNecessary() const;
    
    AnimationTarget _pivotX;
    AnimationTarget _pivotY;
    AnimationTarget _scaleX;
    AnimationTarget _scaleY;
    AnimationTarget _rotateZ;
    AnimationTarget _tiltY;
    float _width;
    float _height;
    float _z;
    
    AnimatorQueue _pivotXAction;
    AnimatorQueue _pivotYAction;
    AnimatorQueue _scaleXAction;
    AnimatorQueue _scaleYAction;
    AnimatorQueue _rotateZAction;
    AnimatorQueue _tiltYAction;
    
    kmVec4 _colorLT;
    kmVec4 _colorLB;
    kmVec4 _colorRB;
    kmVec4 _colorRT;
    
    kmVec2 _texcoordLT;
    kmVec2 _texcoordLB;
    kmVec2 _texcoordRB;
    kmVec2 _texcoordRT;
    
    kmVec2 _pivotOffset;
    
    mutable kmVec2 _vLT;
    mutable kmVec2 _vLB;
    mutable kmVec2 _vRB;
    mutable kmVec2 _vRT;
    mutable bool _verticesValid;
};

class SpriteBatch {
public:
    
    virtual ~SpriteBatch();
    
    SpriteBatch();
    
    inline int spriteCount() const {return _spriteCount;}
    
    inline int quadsCount() const {return _spriteCount;}
    
    Quad2DSprite* addNewSprite(float x, float y, float width, float height, float z, kmVec2 texcoordLT, kmVec2 texcoordLB, kmVec2 texcoordRB, kmVec2 texcoordRT);
    
    void removeSprite(Quad2DSprite* sprite);
    
    void removeAllSprites();
    
    void update(float dt);
    
    GLVAO* prepareVAOForDrawing(GLuint* quadParamSlots);
    
    //    void draw();
    
protected:
    
    std::map<int, Quad2DSprite*> _quadIndex2SpriteMap;
    int _spriteCount;
    
    Quads2D* _quads;
    
    GLVAO* _glVAO;
    GLint _glVBO;
};

#endif /* Quad2DSprite_hpp */
