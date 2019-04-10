//
//  Quad2DSprite.cpp
//  ClashRoyalHelper
//
//  Created by DOM QIU on 2018/11/12.
//  Copyright © 2018 QiuDong. All rights reserved.
//
#ifdef TARGET_OS_IOS

#include "Quad2DSprite.hpp"

using namespace std;

kmMat4 create2DProjectMatrix(float canvasWidth, float canvasHeight, float referenceWidth, float referenceHeight) {
    // Vertical:Top , Horizontal:Center
    kmMat4 ret;
    if (canvasHeight * referenceWidth > referenceHeight * canvasWidth)
    {
        float rW_2div = 2.f / referenceWidth;
        float cW_div_cH = canvasWidth / canvasHeight;
        float matrixData[] = {rW_2div, 0.f, 0.f, 0.f,
            0.f, rW_2div * cW_div_cH, 0.f, 0.f,
            0.f, 0.f, 1.f, 0.f,
            -1.f, 1.f - referenceHeight * rW_2div * cW_div_cH, 0.f, 1.f,
        };
        kmMat4Fill(&ret, matrixData);
    }
    else
    {
        float rH_2div = 2.f / referenceHeight;
        float cH_div_cW = canvasHeight / canvasWidth;
        float matrixData[] = {rH_2div * cH_div_cW, 0.f, 0.f, 0.f,
            0.f, rH_2div, 0.f, 0.f,
            0.f, 0.f, 1.f, 0.f,
            -0.5f * rH_2div * cH_div_cW * referenceWidth, -1.f, 0.f, 1.f,
        };
        kmMat4Fill(&ret, matrixData);
    }
    return ret;
}

Quad2DSprite::~Quad2DSprite() {
}

Quad2DSprite::Quad2DSprite(float pivotX, float pivotY, float width, float height, float z)
: _width(width)
, _height(height)
, _z(z)
, _colorLT({0.f, 0.f, 0.f, 0.f})
, _colorLB({0.f, 0.f, 0.f, 0.f})
, _colorRB({0.f, 0.f, 0.f, 0.f})
, _colorRT({0.f, 0.f, 0.f, 0.f})
, _texcoordLT({0.f, 1.f})
, _texcoordLB({0.f, 0.f})
, _texcoordRB({1.f, 0.f})
, _texcoordRT({1.f, 1.f})
, _pivotOffset({0.f, 0.f})
{
    invalidateVertices();
    _pivotX.setCurrentProgress(pivotX);
    _pivotY.setCurrentProgress(pivotY);
    _scaleX.setCurrentProgress(1.f);
    _scaleY.setCurrentProgress(1.f);
    _rotateZ.setCurrentProgress(0.f);
    _tiltY.setCurrentProgress(0.f);
    
    _pivotXAction.setTarget(&_pivotX);
    _pivotYAction.setTarget(&_pivotY);
    _scaleXAction.setTarget(&_scaleX);
    _scaleYAction.setTarget(&_scaleY);
    _rotateZAction.setTarget(&_rotateZ);
    _tiltYAction.setTarget(&_tiltY);
}

void Quad2DSprite::setPivotOffsetFromCenter(float dx, float dy) {
    _pivotOffset.x = dx;
    _pivotOffset.y = dy;
}

void Quad2DSprite::updateVerticesIfNecessary() const {
    if (_verticesValid) return;
    
    float halfW = _width / 2.f;
    float halfH = _height / 2.f;
    float radianZ = _rotateZ.getCurrentProgress() * M_PI / 180.f;
    float cosZ = cos(radianZ);
    float sinZ = sin(radianZ);
    float scaleX = _scaleX.getCurrentProgress();
    float scaleY = _scaleY.getCurrentProgress();
    kmVec2 vLB = {-halfW - _pivotOffset.x, -halfH - _pivotOffset.y};
    kmVec2 vLT = {-halfW - _pivotOffset.x, halfH - _pivotOffset.y};
    kmVec2 vRT = {halfW - _pivotOffset.x, halfH - _pivotOffset.y};
    kmVec2 vRB = {halfW - _pivotOffset.x, -halfH - _pivotOffset.y};
    kmScalar rotationAndScaleMatrixData[] = {cosZ * scaleX, sinZ * scaleX, 0.f, -sinZ * scaleY, cosZ * scaleY, 0.f, 0.f, 0.f, 1.f};
    kmMat3 rotationAndScaleMatrix;
    kmMat3Fill(&rotationAndScaleMatrix, rotationAndScaleMatrixData);
    kmVec2Transform(&vLB, &vLB, &rotationAndScaleMatrix);
    kmVec2Transform(&vLT, &vLT, &rotationAndScaleMatrix);
    kmVec2Transform(&vRB, &vRB, &rotationAndScaleMatrix);
    kmVec2Transform(&vRT, &vRT, &rotationAndScaleMatrix);
    float pivotX = _pivotX.getCurrentProgress();
    float pivotY = _pivotY.getCurrentProgress();
    _vLB.x = vLB.x + pivotX;
    _vLB.y = vLB.y + pivotY;
    _vLT.x = vLT.x + pivotX;
    _vLT.y = vLT.y + pivotY;
    _vRB.x = vRB.x + pivotX;
    _vRB.y = vRB.y + pivotY;
    _vRT.x = vRT.x + pivotX;
    _vRT.y = vRT.y + pivotY;
    
    _verticesValid = true;
}

void Quad2DSprite::setColors(kmVec4 lt, kmVec4 lb, kmVec4 rb, kmVec4 rt) {
    _colorLT = lt;
    _colorLB = lb;
    _colorRB = rb;
    _colorRT = rt;
}

void Quad2DSprite::setTexcoords(kmVec2 lt, kmVec2 lb, kmVec2 rb, kmVec2 rt) {
    _texcoordLT = lt;
    _texcoordLB = lb;
    _texcoordRB = rb;
    _texcoordRT = rt;
}

kmVec2 Quad2DSprite::getVertexLT() const {
    updateVerticesIfNecessary();
    return _vLT;
}

kmVec2 Quad2DSprite::getVertexLB() const {
    updateVerticesIfNecessary();
    return _vLB;
}

kmVec2 Quad2DSprite::getVertexRB() const {
    updateVerticesIfNecessary();
    return _vRB;
}

kmVec2 Quad2DSprite::getVertexRT() const {
    updateVerticesIfNecessary();
    return _vRT;
}

void Quad2DSprite::update(float dt) {
    invalidateVertices();
    _pivotXAction.update(dt);
    _pivotYAction.update(dt);
    _scaleXAction.update(dt);
    _scaleYAction.update(dt);
    _rotateZAction.update(dt);
    _tiltYAction.update(dt);
}

void Quad2DSprite::cancelAllActions() {
    _pivotXAction.cancelAll();
    _pivotYAction.cancelAll();
    _scaleXAction.cancelAll();
    _scaleYAction.cancelAll();
    _rotateZAction.cancelAll();
    _tiltYAction.cancelAll();
}

bool Quad2DSprite::isActionAnimating() const {
    return !(_pivotXAction.isStopped() && _pivotYAction.isStopped() && _scaleXAction.isStopped() && _scaleYAction.isStopped() && _rotateZAction.isStopped() && _tiltYAction.isStopped());
}

void Quad2DSprite::startTranslateXAction(AutoRef<Animator> action) {
    _pivotXAction.addAction(action);
    _pivotXAction.start();
    invalidateVertices();
}
void Quad2DSprite::startTranslateYAction(AutoRef<Animator> action) {
    _pivotYAction.addAction(action);
    _pivotYAction.start();
    invalidateVertices();
}

void Quad2DSprite::startScaleXAction(AutoRef<Animator> action) {
    _scaleXAction.addAction(action);
    _scaleXAction.start();
    invalidateVertices();
}
void Quad2DSprite::startScaleYAction(AutoRef<Animator> action) {
    _scaleYAction.addAction(action);
    _scaleYAction.start();
    invalidateVertices();
}

void Quad2DSprite::startRotateZAction(AutoRef<Animator> action) {
    _rotateZAction.addAction(action);
    _rotateZAction.start();
    invalidateVertices();
}

void Quad2DSprite::startTiltYAction(AutoRef<Animator> action) {
    _tiltYAction.addAction(action);
    action->start();
    invalidateVertices();
}

void Quad2DSprite::moveBy(float dx, float dy, float interval) {
    MoveByAnimator* moveXByAction = new MoveByAnimator;
    moveXByAction->setMoveByValue(dx);
    moveXByAction->setInterval(interval);
    MoveByAnimator* moveYByAction = new MoveByAnimator;
    moveYByAction->setMoveByValue(dy);
    moveYByAction->setInterval(interval);
    startTranslateXAction(moveXByAction);
    startTranslateYAction(moveYByAction);
}

void Quad2DSprite::moveTo(float x, float y, float interval) {
    MoveToAnimator* moveXToAction = new MoveToAnimator;
    moveXToAction->setMoveToValue(x);
    moveXToAction->setInterval(interval);
    MoveToAnimator* moveYToAction = new MoveToAnimator;
    moveYToAction->setMoveToValue(y);
    moveYToAction->setInterval(interval);
    startTranslateXAction(moveXToAction);
    startTranslateYAction(moveYToAction);
}

void Quad2DSprite::moveToRect(float x0, float y0, float width, float height, float interval) {
    moveTo(x0 + width/2 + _pivotOffset.x * width / getWidth(), y0 + height/2 + _pivotOffset.y * height / getHeight(), interval);
    scaleTo(width / getWidth(), height / getHeight(), interval);
}

void Quad2DSprite::scaleBy(float dScaleX, float dScaleY, float interval) {
    MultiplyByAnimator* scaleXByAction = new MultiplyByAnimator;
    scaleXByAction->setMultiplyByValue(dScaleX);
    scaleXByAction->setInterval(interval);
    MultiplyByAnimator* scaleYByAction = new MultiplyByAnimator;
    scaleYByAction->setMultiplyByValue(dScaleY);
    scaleYByAction->setInterval(interval);
    startScaleXAction(scaleXByAction);
    startScaleYAction(scaleYByAction);
}

void Quad2DSprite::scaleTo(float scaleX, float scaleY, float interval) {
    MoveToAnimator* scaleXToAction = new MoveToAnimator;
    scaleXToAction->setMoveToValue(scaleX);
    scaleXToAction->setInterval(interval);
    MoveToAnimator* scaleYToAction = new MoveToAnimator;
    scaleYToAction->setMoveToValue(scaleY);
    scaleYToAction->setInterval(interval);
    startScaleXAction(scaleXToAction);
    startScaleYAction(scaleYToAction);
}

void Quad2DSprite::rotateZBy(float dDegree, float interval) {
    MoveByAnimator* rotateZByAction = new MoveByAnimator;
    rotateZByAction->setMoveByValue(dDegree);
    rotateZByAction->setInterval(interval);
    startRotateZAction(rotateZByAction);
}

void Quad2DSprite::rotateZTo(float degree, float interval) {
    MoveToAnimator* rotateZToAction = new MoveToAnimator;
    rotateZToAction->setMoveToValue(degree);
    rotateZToAction->setInterval(interval);
    startRotateZAction(rotateZToAction);
}

void Quad2DSprite::rotateZRepeatedly(float dDegree, float interval, int count) {
    MoveByAnimator* rotateZByAction = new MoveByAnimator;
    rotateZByAction->setMoveByValue(dDegree);
    rotateZByAction->setInterval(interval);
    RepeatAnimator* repeatAction = new RepeatAnimator(rotateZByAction);
    repeatAction->setLoopCount(count);
    startRotateZAction(repeatAction);
}

void Quad2DSprite::shakeRepeatedly(float dX, float dY, float interval, int count) {
    MoveByAnimator* moveXByAction0 = new MoveByAnimator;
    moveXByAction0->setMoveByValue(dX);
    moveXByAction0->setInterval(interval);
    MoveByAnimator* moveXByAction1 = new MoveByAnimator;
    moveXByAction1->setMoveByValue(-dX);
    moveXByAction1->setInterval(interval);
    
    AnimatorSequence* moveXSequence = new AnimatorSequence;
    moveXSequence->addAction(moveXByAction0).addAction(moveXByAction1);
    RepeatAnimator* shakeXAction = new RepeatAnimator(moveXSequence);
    shakeXAction->setLoopCount(count);
    startTranslateXAction(shakeXAction);
    
    MoveByAnimator* moveYByAction0 = new MoveByAnimator;
    moveYByAction0->setMoveByValue(dY);
    moveYByAction0->setInterval(interval);
    MoveByAnimator* moveYByAction1 = new MoveByAnimator;
    moveYByAction1->setMoveByValue(-dY);
    moveYByAction1->setInterval(interval);
    
    AnimatorSequence* moveYSequence = new AnimatorSequence;
    moveYSequence->addAction(moveYByAction0).addAction(moveYByAction1);
    RepeatAnimator* shakeYAction = new RepeatAnimator(moveYSequence);
    shakeYAction->setLoopCount(count);
    startTranslateYAction(shakeYAction);
}

void Quad2DSprite::tiltYBy(float dTilt, float interval) {
    MoveByAnimator* tiltYByAction = new MoveByAnimator;
    tiltYByAction->setMoveByValue(dTilt);
    tiltYByAction->setInterval(interval);
    startRotateZAction(tiltYByAction);
}

void Quad2DSprite::tiltYTo(float tilt, float interval) {
    MoveToAnimator* tiltYToAction = new MoveToAnimator;
    tiltYToAction->setMoveToValue(tilt);
    tiltYToAction->setInterval(interval);
    startRotateZAction(tiltYToAction);
}

SpriteBatch::~SpriteBatch() {
    for (map<int, Quad2DSprite*>::iterator iter = _quadIndex2SpriteMap.begin();
         iter != _quadIndex2SpriteMap.end();
         iter++)
    {
        delete iter->second;
    }
    _quadIndex2SpriteMap.clear();
    if (_quads)
    {
        delete _quads;
        _quads = NULL;
    }
    glDeleteBuffers(1, (GLuint*)&_glVBO);
    if (_glVAO)
    {
        delete _glVAO;
        _glVAO = NULL;
    }
}

SpriteBatch::SpriteBatch()
: _spriteCount(0)
, _quads(NULL)
, _glVAO(NULL)
, _glVBO(-1)
{
    
}

Quad2DSprite* SpriteBatch::addNewSprite(float x, float y, float width, float height, float z, kmVec2 texcoordLT, kmVec2 texcoordLB, kmVec2 texcoordRB, kmVec2 texcoordRT) {
    Quad2DSprite* ret = new Quad2DSprite(x, y, width, height, z);
    ret->setTexcoords(texcoordLT, texcoordLB, texcoordRB, texcoordRT);
    ret->tag = _spriteCount++;
    _quadIndex2SpriteMap.insert(make_pair(ret->tag, ret));
    if (!_quads)
    {
        _quads = new Quads2D(0);
    }
    return ret;
}

void SpriteBatch::removeSprite(Quad2DSprite* sprite) {
    if (NULL == sprite || sprite->tag < 0 || sprite->tag >= _spriteCount) return;
    
    if (_quads)
    {
        _quads->removeQuad(sprite->tag);
    }
    _quadIndex2SpriteMap.erase(sprite->tag);
    for (int i = sprite->tag + 1; i < _spriteCount; ++i)
    {
        map<int, Quad2DSprite* >::iterator found = _quadIndex2SpriteMap.find(i);
        if (found != _quadIndex2SpriteMap.end() && found->second != NULL)
        {
            Quad2DSprite* toBeRelocated = found->second;
            _quadIndex2SpriteMap.erase(found);
            _quadIndex2SpriteMap.insert(make_pair(--toBeRelocated->tag, toBeRelocated));
        }
    }
    _spriteCount--;
}

void SpriteBatch::removeAllSprites() {
    if (_quads)
    {
        _quads->removeQuads(0, _spriteCount);
    }
    _quadIndex2SpriteMap.clear();
    _spriteCount = 0;
}

void SpriteBatch::update(float dt) {
    for (map<int, Quad2DSprite*>::iterator iter = _quadIndex2SpriteMap.begin();
         iter != _quadIndex2SpriteMap.end();
         iter++)
    {
        Quad2DSprite* sprite = iter->second;
        sprite->update(dt);
    }
}

GLVAO* SpriteBatch::prepareVAOForDrawing(GLuint* quadParamSlots) {
    if (!_quads) return NULL;
    GLint prevVAO, prevVBO;
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &prevVAO);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &prevVBO);
    if (!_glVAO)
    {
        AutoRef<Mesh3D> mesh = Mesh3D::createQuad(P4C4T2fMake(0,0,0,1, 0,0,0,0, 0,1),//LB
                                                  P4C4T2fMake(0,1,0,1, 0,0,0,0, 0,0),//LT
                                                  P4C4T2fMake(1,1,1,1, 0,0,0,0, 1,0),//RT
                                                  P4C4T2fMake(1,0,0,1, 0,0,0,0, 1,1)//RB
                                                  );
        _glVAO = new GLVAO(mesh, GL_STREAM_DRAW);
        GLint vao = _glVAO->getVAO();
        glBindVertexArray(vao);
        // Quads VBO:
        glGenBuffers(1, (GLuint*)&_glVBO);
        glBindBuffer(GL_ARRAY_BUFFER, _glVBO);
        CHECK_GL_ERROR();
        glEnableVertexAttribArray(quadParamSlots[0]);
        glEnableVertexAttribArray(quadParamSlots[1]);
        glEnableVertexAttribArray(quadParamSlots[2]);
        glEnableVertexAttribArray(quadParamSlots[3]);
        glEnableVertexAttribArray(quadParamSlots[4]);
        glEnableVertexAttribArray(quadParamSlots[5]);
        glEnableVertexAttribArray(quadParamSlots[6]);
        glEnableVertexAttribArray(quadParamSlots[7]);
        glEnableVertexAttribArray(quadParamSlots[8]);
        CHECK_GL_ERROR();
        glVertexAttribPointer(quadParamSlots[0], 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 31, (GLvoid*)0);
        glVertexAttribPointer(quadParamSlots[1], 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 31, (GLvoid*)(sizeof(GLfloat) * 3));
        glVertexAttribPointer(quadParamSlots[2], 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 31, (GLvoid*)(sizeof(GLfloat) * 6));
        glVertexAttribPointer(quadParamSlots[3], 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 31, (GLvoid*)(sizeof(GLfloat) * 9));
        glVertexAttribPointer(quadParamSlots[4], 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 31, (GLvoid*)(sizeof(GLfloat) * 12));
        glVertexAttribPointer(quadParamSlots[5], 4, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 31, (GLvoid*)(sizeof(GLfloat) * 15));
        glVertexAttribPointer(quadParamSlots[6], 4, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 31, (GLvoid*)(sizeof(GLfloat) * 19));
        glVertexAttribPointer(quadParamSlots[7], 4, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 31, (GLvoid*)(sizeof(GLfloat) * 23));
        glVertexAttribPointer(quadParamSlots[8], 4, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 31, (GLvoid*)(sizeof(GLfloat) * 27));
        CHECK_GL_ERROR();
        glVertexAttribDivisor(quadParamSlots[0], 1);
        glVertexAttribDivisor(quadParamSlots[1], 1);
        glVertexAttribDivisor(quadParamSlots[2], 1);
        glVertexAttribDivisor(quadParamSlots[3], 1);
        glVertexAttribDivisor(quadParamSlots[4], 1);
        glVertexAttribDivisor(quadParamSlots[5], 1);
        glVertexAttribDivisor(quadParamSlots[6], 1);
        glVertexAttribDivisor(quadParamSlots[7], 1);
        glVertexAttribDivisor(quadParamSlots[8], 1);
    }
    else
    {
        GLint vao = _glVAO->getVAO();
        glBindVertexArray(vao);
    }
    
    for (map<int, Quad2DSprite*>::iterator iter = _quadIndex2SpriteMap.begin();
         iter != _quadIndex2SpriteMap.end();
         iter++)
    {
        Quad2DSprite* sprite = iter->second;
        float z = sprite->getZ();
        kmVec4 colorLT = sprite->getColorLT();
        kmVec4 colorLB = sprite->getColorLB();
        kmVec4 colorRB = sprite->getColorRB();
        kmVec4 colorRT = sprite->getColorRT();
        kmVec2 texcoordLT = sprite->getTexcoordLT();
        kmVec2 texcoordLB = sprite->getTexcoordLB();
        kmVec2 texcoordRB = sprite->getTexcoordRB();
        kmVec2 texcoordRT = sprite->getTexcoordRT();
        kmVec2 vertexLT = sprite->getVertexLT();
        kmVec2 vertexLB = sprite->getVertexLB();
        kmVec2 vertexRB = sprite->getVertexRB();
        kmVec2 vertexRT = sprite->getVertexRT();
        _quads->setQuad(sprite->tag,
                        (P4C4T2f){vertexLB.x, vertexLB.y, z, 1.f, colorLB.x, colorLB.y, colorLB.z, colorLB.w, texcoordLB.x, texcoordLB.y}, //LB
                        (P4C4T2f){vertexLT.x, vertexLT.y, z, 1.f, colorLT.x, colorLT.y, colorLT.z, colorLT.w, texcoordLT.x, texcoordLT.y}, //LT
                        (P4C4T2f){vertexRT.x, vertexRT.y, z, 1.f, colorRT.x, colorRT.y, colorRT.z, colorRT.w, texcoordRT.x, texcoordRT.y}, //RT
                        (P4C4T2f){vertexRB.x, vertexRB.y, z, 1.f, colorRB.x, colorRB.y, colorRB.z, colorRB.w, texcoordRB.x, texcoordRB.y} //RB
                        );
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, _glVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 31 * _spriteCount, _quads->getMatricesForInstancedDrawing(), GL_STREAM_DRAW);
    
    CHECK_GL_ERROR();
    glBindVertexArray(prevVAO);
    glBindBuffer(GL_ARRAY_BUFFER, prevVBO);
    return _glVAO;
}

#endif //#ifdef TARGET_OS_IOS
