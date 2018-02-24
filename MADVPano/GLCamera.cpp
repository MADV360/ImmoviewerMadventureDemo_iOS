//
//  GLCamera.cpp
//  Madv360_v1
//
//  Created by QiuDong on 16/4/27.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//
#include "GLCamera.h"
#include "Log.h"
#include <math.h>

#ifdef DEBUGGING_RENDER
float DebugMatrixData[] = DEBUG_MODEL_MATRIX;
#endif

float angleOfVectors(kmVec3* pCrossProduct, const kmVec3* v0, const kmVec3* v1) {
    kmVec3 crossProduct;;
    kmVec3Cross(&crossProduct, v0, v1);
    float sinAlpha = kmVec3Length(&crossProduct) / kmVec3Length(v0) / kmVec3Length(v1);
    if (pCrossProduct)
    {
        kmVec3Assign(pCrossProduct, &crossProduct);
    }
    return asinf(sinAlpha);
}

static kmVec4 _debugPolarAxis;
static kmVec4 _debugNorthPolar;
static kmVec4 _debugSouthPolar;
static kmMat4 _debugCameraRotation;

kmVec4 GLCamera::_debugGetPolarAxis() {
    return _debugPolarAxis;
}

kmVec4 GLCamera::_debugGetNorthPolar() {
    return _debugNorthPolar;
}
kmVec4 GLCamera::_debugGetSouthPolar() {
    return _debugSouthPolar;
}

kmMat4 GLCamera::_debugGetCameraRotation() {
    return _debugCameraRotation;
}

GLCamera::~GLCamera() {
    
}

GLCamera::GLCamera()
: _width(640)
, _height(960)
, _near(CLIP_Z_NEAR)
, _far(CLIP_Z_FAR)
, _fovDegree(80.f)
{
    kmMat4Identity(&_cameraPostRotationMatrix);
    kmMat4Identity(&_cameraPreRotationMatrix);
    kmMat4Identity(&_cameraRotationMatrix);
    kmMat4Identity(&_modelPreRotationMatrix);
    kmMat4Identity(&_modelRotationMatrix);
    _modelPostRotationFromVector = {0.f, 0.f, 0.f};
    _modelPostRotationToVector = _modelPostRotationFromVector;
}

void GLCamera::getProjectionMatrix(kmMat4* projectionMatrix, float zNear, float zFar, float fovDegreeX, float aspectRatio, float zEye, float cutRadius) {
    float thetaX = kmDegreesToRadians(fovDegreeX) / 2.f;
    float t, n;
    if (cutRadius <= 0.f)
    {
        t = tanf(thetaX);
        n = zNear;
    }
    else
    {
        float cosThetaX = cosf(thetaX);
        float sinThetaX = sinf(thetaX);
        t = cutRadius * sinThetaX / (zEye + cutRadius * cosThetaX);
        float t2 = t * t;
        float A = 1.f + t2 + t2 / (aspectRatio * aspectRatio);
        float B = - 2.f * zEye;
        float C = zEye * zEye - cutRadius * cutRadius;
        float Delta2 = B * B - 4.f * A * C;
        if (Delta2 < 0.f)
        {
            n = zEye;
        }
        else
        {
            n = zEye - ((-B + sqrtf(Delta2)) / (2.f * A));
        }
    }
    
    const float mat[] = {
        1.f / t, 0.f, 0.f, 0.f,
        0.f, aspectRatio / t, 0.f, 0.f,
        0.f, 0.f, (n + zFar - 2 * zEye) / (n - zFar), -1,
        0.f, 0.f, zEye + 2 * zFar * (zEye - n) / (n - zFar), zEye};
    kmMat4Fill(projectionMatrix, mat);
}

void GLCamera::getStereoGraphicProjectionMatrix(kmMat4* projectionMatrix) {
    // Here, we use _near as z coordinates of eye (r), and z=_near as near clip plane:
    float e = _near;
    float fovRadians = kmDegreesToRadians(_fovDegree);
    float tanFOVX = tan(fovRadians / 4);
    float tanFOVY = tanFOVX * _height / _width;
    
    ///!!!
    //    float maxZoomFOV = M_PI * 120.f / 180.f;
    //    float tanMaxZoomFOVX = tan(maxZoomFOV / 4);
    //    float tanMaxZoomFOVY = tanMaxZoomFOVX * _height / _width;
    //    float n = e - 2 * e / (1 + tanMaxZoomFOVX*tanMaxZoomFOVX + tanMaxZoomFOVY*tanMaxZoomFOVY);
    float n = e - 2 * e / (1 + tanFOVX*tanFOVX + tanFOVY*tanFOVY);
    float f = _far;
    
    float a00 = 1.f / tanFOVX;//2 * r / w;
    float a11 = 1.f / tanFOVY;//2 * r / h;
    float a22 = (n + f - 2 * e) / (n - f);
    float a23 = e + 2 * f * (e - n) / (n - f);
    float a32 = -1;//-1
    float a33 = e;//r
    const float mat[] = {a00,0,0,0, 0,a11,0,0, 0,0,a22,a32, 0,0,a23,a33};
    kmMat4Fill(projectionMatrix, mat);
}

void GLCamera::getProjectionMatrix(kmMat4* projectionMatrix) {
    //    float scale = (float)REFERENCE_VIEWPORT_WIDTH / (float)_width;
    float zNear = 0;//_near * scale;
    float zFar = _far;// * scale;
    float aspect = (float)_width/(float)_height;
    float fovY = kmRadiansToDegrees(atan(tan(kmDegreesToRadians(_fovDegree / 2)) / aspect)) * 2;
    //    ALOGE("GLCamera: getProjectionMatrix fovDegree=%d", _fovDegree);
    kmMat4PerspectiveProjection(projectionMatrix, fovY, aspect, zNear, zFar);
    //    ALOGE("GLCamera::setProjectionMatrix : (width,height,near,far) = (%d,%d,%d,%d), fovY = %d, scale=%f, zNear=%f, zFar=%f", _width,_height,_near,_far, _fovDegree,scale,zNear,zFar);
}

void GLCamera::getLittlePlanetProjectionMatrix(kmMat4* projectionMatrix) {
    // Here, we use _near as z coordinates of eye (r), and z=_near as near clip plane:
    float e = _near;
    float fovRadians = kmDegreesToRadians(_fovDegree);
    float tanFOVX = tan(fovRadians / 2);
    float tanFOVY = tanFOVX * _height / _width;
    //    float w = 2 * r * tanFOVX;
    //    float h = _height * w / _width;
    
    float n = e - 2 * e / (1 + tanFOVX*tanFOVX + tanFOVY*tanFOVY);
    float f = _far;
    
    float a00 = 1.f / tanFOVX;//2 * r / w;
    float a11 = 1.f / tanFOVY;//2 * r / h;
    float a22 = (n + f - 2 * e) / (n - f);
    float a23 = e + 2 * f * (e - n) / (n - f);
    float a32 = -1;//-1
    float a33 = e;//r
    const float mat[] = {a00,0,0,0, 0,a11,0,0, 0,0,a22,a32, 0,0,a23,a33};
    kmMat4Fill(projectionMatrix, mat);
}

void GLCamera::calculateDebugAxes() {
    //TODO:
}

/**
 *
 * @param cameraMatrix : 虚拟摄像机的朝向旋转矩阵（在惯性坐标系中）
 * @param orientation :
 * @param considerOrientation :
 */
void calculateCurrentCameraAxes(kmVec3* pBc, kmVec3* pRc, kmVec3* pUc, const kmMat4* cameraMatrix, Orientation2D orientation, bool considerOrientation) {
    kmVec3 Uw = {0,1,0};
    kmVec3 Bc = {0,0,1};//虚拟摄像机（亦即手机）的背向向量
    kmVec3Transform(&Bc, &Bc, cameraMatrix);
    kmVec3Normalize(&Bc, &Bc);
    
    kmVec3 crossProductUwBc = { 1, 0, 0 };//同时垂直于铅垂方向和屏幕背向向量指向屏幕右方的向量
    // It's a weird bug of Visual Studio or its compiler: This line must be left with comment or blank, or angleUwBc will not be recognized as declared variable...WTF?!!
    float angleUwBc = angleOfVectors(&crossProductUwBc, &Uw, &Bc);
    kmVec3 Uc, Rc;
    if (fabsf(angleUwBc) > M_PI / 6.f)
    {
        kmVec3 projectedUw = { 0, 1, 0 };//投影在手机屏幕上的向上方向向量
        kmVec3Cross(&projectedUw, &Bc, &crossProductUwBc);
        Uc = projectedUw;
        kmVec3 UcCandidates[] = {{0,1,0}, {1,0,0}, {0,-1,0}, {-1,0,0}};
        for (int i=0; i<4; ++i)
        {
            kmVec3Transform(UcCandidates + i, UcCandidates + i, cameraMatrix);
            float angle = fabsf(angleOfVectors(NULL, &projectedUw, UcCandidates + i));
            if (angle < M_PI / 6.f)
            {
                Uc = UcCandidates[i];
                break;
            }
        }
        kmVec3Normalize(&Uc, &Uc);
        kmVec3Cross(&Rc, &Uc, &Bc);
    }
    else
    {
        switch (orientation) {
            default:
                Uc = {0,1,0};
                Rc = {1,0,0};
                break;
        }
        kmVec3Transform(&Uc, &Uc, cameraMatrix);
        kmVec3Transform(&Rc, &Rc, cameraMatrix);
    }
    
    if (pBc) kmVec3Assign(pBc, &Bc);
    if (pRc) kmVec3Assign(pRc, &Rc);
    if (pUc) kmVec3Assign(pUc, &Uc);
}

//Vec2f GLCamera::calculateModelMatrix(kmMat4* outModelMatrix, kmMat4* outYawMatrix, kmMat4* outPitchMatrix, const kmMat4* projectionMatrix) {
//    if (!outModelMatrix) return {0,0};
//    // Dragging vector:
//    kmVec3 endDraggingPoint = {_endDraggingPoint.x, _endDraggingPoint.y, 0};
//    kmVec3 startDraggingPoint = {_startDraggingPoint.x, _startDraggingPoint.y, 0};
//    kmVec3 draggingVector;
//    kmVec3Subtract(&draggingVector, &endDraggingPoint, &startDraggingPoint);
//
//    kmMat4 cameraMatrix;
//    calculateCameraMatrix(&cameraMatrix);
//    kmVec3Transform(&draggingVector, &draggingVector, &cameraMatrix);
//
//    kmVec3 Uc, Rc;
//    calculateCurrentCameraAxes(NULL, &Rc, &Uc, &cameraMatrix, OrientationNormal, true);
//
//    float yawComponent = kmVec3Dot(&draggingVector, &Rc);
//    float pitchComponent = kmVec3Dot(&draggingVector, &Uc);
//    //*/
//    _prevYawAngle = -yawComponent * M_PI / _width;
//    _prevPitchAngle = _enablePitchDragging ? pitchComponent * M_PI / _height : _prevPitchAngle;
//    float accumulatedPitchAngle = _accumulatedPitchAngle + _prevPitchAngle;
//    if (accumulatedPitchAngle > M_PI / 2)
//        _prevPitchAngle = M_PI / 2 - _accumulatedPitchAngle;
//    else if (accumulatedPitchAngle < -M_PI / 2)
//        _prevPitchAngle = -M_PI / 2 - _accumulatedPitchAngle;
//    //ALOGE("#DragRange# calculateModelMatrix : _prevPitchAngle=%.3f, _accumulatedPitchAngle=%.3f", _prevPitchAngle, _accumulatedPitchAngle);
//    // Update modelRotationMatrix:
//    kmMat4 yawMatrix, pitchMatrix;
//    if (!outYawMatrix)
//    {
//        outYawMatrix = &yawMatrix;
//    }
//    if (!outPitchMatrix)
//    {
//        outPitchMatrix = &pitchMatrix;
//    }
//
//    kmMat4RotationAxisAngle(outYawMatrix, &_yawAxis0, _prevYawAngle);
////    checkRotationMatrix(outYawMatrix, false);
//    kmMat4RotationAxisAngle(outPitchMatrix, &_pitchAxis0, _prevPitchAngle);
////    checkRotationMatrix(outPitchMatrix, false);
//    kmMat4Multiply(outModelMatrix, outYawMatrix, &_modelRotationMatrix0);
//    kmMat4Multiply(outModelMatrix, outPitchMatrix, outModelMatrix);
//
//    return {_prevYawAngle, _prevPitchAngle};
//}

/**
 *  In World Coordinate System:
 *  modelMatrix = modelRotationMatrix * modelPreRotationMatrix; --- F1
 *  finalGLTransformMatrix = modelMatrix / cameraMatrix; --- F2
 *  modelRotationMatrix[0] = IdentityMatrix; --- F1.1
 *  modelRotationMatrix[k+1] = modelRotationMatrix[k] rotateAround@By@(yawAxis[k], yawAngle) rotateAround@By@(pitchAxis[k], pitchAngle); --- F1.2
 *  yawAxis[0] = Uw = [0,1,0]; --- F1.2.1
 *  yawAxis[k+1] = yawAxis[k] projectOn Plane{Fc, Uw}, if !(Fc ~~ Uw), when adustAxis on panning begin; --- F1.2.2
 *  yawAxis[k+1] = yawAxis[k] projectOn Plane{Uc, Uw}, if (Fc ~~ Uw), when adustAxis on panning begin; --- F1.2.3
 *  yawAxis[k+1] = yawAxis[k] rotateAround@By@(pitchAxis[k], pitchAngle), when panning; --- F1.2.4
 *  pitchAxis[0] = Rw = [1,0,0]; --- F1.2.5
 *  pitchAxis[k+1] = Fc cross Uw, if !(Fc ~~ Uw), when adustAxis on panning begin; --- F1.2.6
 *  pitchAxis[k+1] = Rc, if (Fc ~~ Uw), when adustAxis on panning begin; --- F1.2.7
 *
 *  Rc = cameraRotationMatrix * Rw; --- F1.2.7.1
 *  Fc = cameraRotationMatrix * Fw = cameraRotationMatrix * [0,0,-1]; --- F1.2.6.1
 *  yawAngle = k1? * length(panComponentInYawAxis) * sgn(panComponentInYawAxis dot Fc); --- F1.2.8.1
 *  panComponentInYawAxis = panDirectionVector cross yawAxis; --- F1.2.8.2
 *  pitchAngle = k2? * length(panComponentInPitchAxis) * sgn(panComponentInPitchAxis dot Fc); --- F1.2.8.3
 *  panComponentInPitchAxis = panDirectionVector cross pitchAxis; --- F1.2.8.4
 *
 *  modelMatrix = cameraMatrix, when reset view position; --- F3
 *
 *  yawAxis[k+1] = yawAxis[k] projectOn Plane{Fc, Uc}, when adustAxis on panning begin; --- F1.2.2B
 *  pitchAxis[k+1] = Fc cross Uc = Rc, when adustAxis on panning begin; --- F1.2.6B
 */
void GLCamera::getViewMatrix(kmMat4* viewMatrix) {
    if (NULL == viewMatrix)
        return;
#ifdef USE_DEBUG_MODEL_MATRIX
    kmMat4Fill(viewMatrix, DebugMatrixData);
    //kmMat4Inverse(viewMatrix, viewMatrix);
    //kmMat4RotationX(viewMatrix, M_PI/2.f);
#else //#ifdef DEBUGGING_RENDER
    kmMat4 cameraMatrix;
    kmMat4Multiply(&cameraMatrix, &_cameraPostRotationMatrix, &_cameraRotationMatrix);
    kmMat4Multiply(&cameraMatrix, &cameraMatrix, &_cameraPreRotationMatrix);
    
    kmMat4 modelMatrix;
    if (kmVec3LengthSq(&_modelPostRotationToVector) > 0 && kmVec3LengthSq(&_modelPostRotationFromVector) > 0)
    {
        const float EPSILONG_ANGLE_DEGREE = 0.1f;
        kmVec3 Y0 = _modelPostRotationFromVector, Y1 = _modelPostRotationToVector;
        kmVec3Transform(&Y0, &Y0, &_modelPreRotationMatrix);
        kmVec3 X, Z0, Z1;
        kmVec3 Y1es[] = {{1.f, 0.f, 0.f}, {0.f, 1.f, 0.f}, {0.f, 0.f, 1.f}, _modelPostRotationToVector};
        float angle = 0.f;
        float lengthY0 = kmVec3Length(&Y0);
        for (int i = sizeof(Y1es) / sizeof(Y1es[0]) - 1; i >= 0 && angle <= EPSILONG_ANGLE_DEGREE; --i)
        {
            Y1 = Y1es[i];
            kmVec3Cross(&X, &Y1, &Y0);
            float sinAngleY0Y1 = kmVec3Length(&X) / kmVec3Length(&Y1) / lengthY0;
            angle = kmRadiansToDegrees(fabsf(asin(sinAngleY0Y1)));
//            ALOGE("#FPS120Video# i=%d, Y0={%.5f, %.5f, %.5f}, Y1={%.5f, %.5f, %.5f}, X={%.5f, %.5f, %.5f}, angle=%f\n", i, Y0.x,Y0.y,Y0.z, Y1.x,Y1.y,Y1.z, X.x,X.y,X.z, angle);
        }
        kmVec3Normalize(&X, &X);
        Y1 = _modelPostRotationToVector;

        kmVec3Cross(&Z1, &X, &Y1);
        kmVec3Cross(&Z0, &X, &Y0);
//        ALOGE("#FPS120Video# Z0={%.5f, %.5f, %.5f}, Z1={%.5f, %.5f, %.5f}, X={%.5f, %.5f, %.5f}, angle=%f\n", Z0.x,Z0.y,Z0.z, Z1.x,Z1.y,Z1.z, X.x,X.y,X.z, angle);
        kmMat4 invA0, A1;
        kmScalar A0Data[] = {X.x, X.y, X.z, 0.f, Y0.x, Y0.y, Y0.z, 0.f, Z0.x, Z0.y, Z0.z, 0.f, 0.f, 0.f, 0.f, 1.f};
        kmScalar A1Data[] = {X.x, X.y, X.z, 0.f, Y1.x, Y1.y, Y1.z, 0.f, Z1.x, Z1.y, Z1.z, 0.f, 0.f, 0.f, 0.f, 1.f};
        kmMat4Fill(&invA0, A0Data);
        kmMat4Inverse(&invA0, &invA0);
        kmMat4Fill(&A1, A1Data);
        kmMat4Multiply(&modelMatrix, &invA0, &_modelPreRotationMatrix);
        kmMat4Multiply(&modelMatrix, &A1, &modelMatrix);
        kmMat4Multiply(&modelMatrix, &_modelRotationMatrix, &modelMatrix);
    }
    else
    {
        kmMat4Multiply(&modelMatrix, &_modelRotationMatrix, &_modelPreRotationMatrix);
    }
     
    kmMat4Inverse(&cameraMatrix, &cameraMatrix);
    kmMat4Multiply(viewMatrix, &cameraMatrix, &modelMatrix);
    checkRotationMatrix(viewMatrix, false, "");
    normalizeRotationMatrix(viewMatrix);
#endif //#ifdef DEBUGGING_RENDER
}

void GLCamera::setCameraPostRotation(const kmQuaternion* cameraPostRotationQuaternion) {
    kmMat4 cameraPostRotation;
    kmMat4RotationQuaternion(&cameraPostRotation, cameraPostRotationQuaternion);
    setCameraPostRotationMatrix(&cameraPostRotation);
}

void GLCamera::setCameraPostRotationMatrix(const kmMat4* cameraPostRotation) {
    kmMat4Assign(&_cameraPostRotationMatrix, cameraPostRotation);
    normalizeRotationMatrix(&_cameraPostRotationMatrix);
}

void GLCamera::setCameraPreRotation(const kmQuaternion* cameraPreRotationQuaternion) {
    kmMat4 cameraPreRotation;
    kmMat4RotationQuaternion(&cameraPreRotation, cameraPreRotationQuaternion);
    setCameraPostRotationMatrix(&cameraPreRotation);
}

void GLCamera::setCameraPreRotationMatrix(const kmMat4* cameraPreRotation) {
    kmMat4Assign(&_cameraPreRotationMatrix, cameraPreRotation);
    normalizeRotationMatrix(&_cameraPreRotationMatrix);
}

void GLCamera::setCameraRotation(const kmQuaternion* cameraRotationQuaternion, bool isInversed) {
    kmMat4 cameraRotation;
    kmMat4RotationQuaternion(&cameraRotation, cameraRotationQuaternion);
    setCameraRotationMatrix(&cameraRotation, isInversed);
}

void GLCamera::setCameraRotationMatrix(const kmMat4* cameraRotation, bool isInversed) {
    if (isInversed)
    {
        kmMat4Inverse(&_cameraRotationMatrix, cameraRotation);
    }
    else
    {
        kmMat4Assign(&_cameraRotationMatrix, cameraRotation);
    }
    normalizeRotationMatrix(&_cameraRotationMatrix);
}

void GLCamera::setModelPreRotation(const kmQuaternion* modelPreRotationQuaternion) {
    kmMat4 modelPreRotation;
    kmMat4RotationQuaternion(&modelPreRotation, modelPreRotationQuaternion);
    setModelPreRotationMatrix(&modelPreRotation);
}

void GLCamera::setModelPreRotationMatrix(const kmMat4* modelPreRotation) {
    kmMat4Assign(&_modelPreRotationMatrix, modelPreRotation);
    normalizeRotationMatrix(&_modelPreRotationMatrix);
}

void GLCamera::setModelPostRotation(const kmVec3* fromVector, const kmVec3* toVector) {
    kmVec3Assign(&_modelPostRotationFromVector, fromVector);
    kmVec3Assign(&_modelPostRotationToVector, toVector);
}

void GLCamera::setModelRotation(const kmQuaternion* modelRotationQuaternion) {
    kmMat4 modelRotation;
    kmMat4RotationQuaternion(&modelRotation, modelRotationQuaternion);
    setModelPreRotationMatrix(&modelRotation);
}

void GLCamera::setModelRotationMatrix(const kmMat4* modelRotation) {
    kmMat4Assign(&_modelRotationMatrix, modelRotation);
    normalizeRotationMatrix(&_modelRotationMatrix);
}


//void GLCamera::setCameraRotationMatrix(const kmMat4* rotationMatrix, bool isInversed) {
//    bool ok = checkRotationMatrix(rotationMatrix, true);
//    if (!ok)
//    {
//        return;
//    }
//
//    kmMat4 normalizedMat, inversedMat;
//    kmMat4Assign(&normalizedMat, rotationMatrix);
//    normalizeRotationMatrix(&normalizedMat);
//    if (isInversed)
//    {
//        kmMat4Assign(&inversedMat, &normalizedMat);
//        kmMat4Inverse(&normalizedMat, &normalizedMat);
//    }
//    else
//    {
//        kmMat4Inverse(&inversedMat, &normalizedMat);
//    }
//
//    kmVec3 vector0 = {1.f, 1.f, 1.f}, vector1 = {1.f, 1.f, 1.f};
//    kmVec3Transform(&vector1, &vector1, &normalizedMat);
//    kmVec3Transform(&vector0, &vector0, &_rawCameraRotationMatrix);
//    kmMat4Assign(&_rawCameraRotationMatrix, &normalizedMat);
//    kmVec3 crossProduct;
//    kmVec3Cross(&crossProduct, &vector0, &vector1);
//    float sinAngle = kmVec3Length(&crossProduct) / kmVec3Length(&vector0) / kmVec3Length(&vector1);
//    float angle = fabs(asin(sinAngle));
//    if (angle >= M_PI / 18.f)
//    {
//        ALOGE("#GLCamera# v0 = {%.3f, %.3f, %.3f}, v1 = {%.3f, %.3f, %.3f}, angle = %.3f", vector0.x, vector0.y, vector0.z, vector1.x, vector1.y, vector1.z, kmRadiansToDegrees(angle));
//        ///!!!kmMat4Assign(&_cameraPreRotationMatrix, &inversedMat);
//        return;
//    }
//    //ALOGE("#GLCamera# 1 v0 = {%.3f, %.3f, %.3f}, v1 = {%.3f, %.3f, %.3f}, angle = %.3f", vector0.x, vector0.y, vector0.z, vector1.x, vector1.y, vector1.z, kmRadiansToDegrees(angle));
//
//    kmMat4Assign(&_cameraRotationMatrix, &_rawCameraRotationMatrix);
//
//    kmMat4Assign(&_debugCameraRotation, &_cameraRotationMatrix);
//}
//
//void GLCamera::resetCameraRotationMatrix(const kmMat4* rotationMatrix, bool isInversed, Orientation2D orientation) {
//    bool ok = checkRotationMatrix(rotationMatrix, true);
//    if (!ok)
//    {
//        ALOGE("#GLCamera# resetCameraRotationMatrix return");
//        return;
//    }
//
//    kmMat4 normalizedMat, inversedMat;
//    kmMat4Assign(&normalizedMat, rotationMatrix);
//    normalizeRotationMatrix(&normalizedMat);
//    if (isInversed)
//    {
//        kmMat4Assign(&inversedMat, &normalizedMat);
//        kmMat4Inverse(&normalizedMat, &normalizedMat);
//    }
//    else
//    {
//        kmMat4Inverse(&inversedMat, &normalizedMat);
//    }
//
//    kmVec3 vector0 = {1.f, 1.f, 1.f}, vector1 = {1.f, 1.f, 1.f};
//    kmVec3Transform(&vector1, &vector1, &normalizedMat);
//    kmVec3Transform(&vector0, &vector0, &_cameraRotationMatrix);
//    kmVec3 crossProduct;
//    kmVec3Cross(&crossProduct, &vector0, &vector1);
//    float sinAngle = kmVec3Length(&crossProduct) / kmVec3Length(&vector0) / kmVec3Length(&vector1);
//    float angle = fabs(asin(sinAngle));
//    ALOGE("#GLCamera# resetCameraRotationMatrix: v0 = {%.3f, %.3f, %.3f}, v1 = {%.3f, %.3f, %.3f}, angle = %.3f", vector0.x, vector0.y, vector0.z, vector1.x, vector1.y, vector1.z, kmRadiansToDegrees(angle));
//
//    kmMat4Assign(&_cameraRotationMatrix, &normalizedMat);
////    kmMat4Assign(&_cameraPreRotationMatrix, &inversedMat);
//
//    kmMat4Assign(&_debugCameraRotation, &_cameraRotationMatrix);
//
//    /*
//    resetViewPosition(orientation);
//    /*/
//    kmMat4Identity(&_modelRotationMatrix0);
//    resetDragging(_endDraggingPoint);
//    _accumulatedPitchAngle = 0.f;
//    _pitchAxis0 = {1.f, 0.f, 0.f};
//    _yawAxis0 = {0.f, 1.f, 0.f};
//    calculateDebugAxes();
//    //*/
//}

//void GLCamera::commitCameraRotation() {
//    kmMat4 cameraMatrix, inverseStartCameraRotationMat;
//    kmMat4Inverse(&inverseStartCameraRotationMat, &_startCameraRotation);
//    kmMat4Multiply(&cameraMatrix, &inverseStartCameraRotationMat, &_cameraRotationMatrix0);
//    kmMat4Multiply(&cameraMatrix, &_endCameraRotation, &cameraMatrix);
/*
 kmMat4 cameraMatrix = _cameraRotationMatrix;
 kmVec3 Rc = {1,0,0};
 kmVec3Transform(&Rc, &Rc, &cameraMatrix);
 kmVec3Normalize(&_pitchAxis0, &Rc);
 _yawAxis0 = rayProjectionOnPlaneFromOrigin(&_yawAxis0, &Rc);
 kmVec3Normalize(&_yawAxis0, &_yawAxis0);
 //*/
//    kmMat4Assign(&_cameraRotationMatrix, &cameraMatrix);
//    kmMat4Assign(&_startCameraRotation, &_endCameraRotation);
//}
/*
 void GLCamera::setDraggingEndState(kmVec2 endPoint) {
 _endDraggingPoint = endPoint;
 }
 
 kmVec2 GLCamera::getDraggingEndState() {
 return _endDraggingPoint;
 }
 
 void GLCamera::resetDragging(kmVec2 point) {
 _startDraggingPoint = point;
 _endDraggingPoint = point;
 _prevYawAngle = _prevPitchAngle = 0.f;
 _accumulatedPitchAngle = 0.f;
 }
 
 void GLCamera::commitDragging() {
 kmMat4 modelMatrix, yawMatrix, pitchMatrix;
 calculateModelMatrix(&modelMatrix, &yawMatrix, &pitchMatrix, &_projectionMatrix);
 ALOGE("#GLCamera# calculateModelMatrix : yawAngle=%.5f, pitchAngle=%.5f", dragAngles.x, dragAngles.y);
 kmVec3Transform(&_yawAxis0, &_yawAxis0, &pitchMatrix);
 ALOGE("#GLCamera# commitDragging : pitchMatrix :");
 checkRotationMatrix(&pitchMatrix, true);
 ALOGE("#GLCamera# commitDragging : yawMatrix :");
 checkRotationMatrix(&yawMatrix, true);
 kmVec3Normalize(&_yawAxis0, &_yawAxis0);
 kmMat4Assign(&_modelRotationMatrix0, &modelMatrix);
 _accumulatedPitchAngle += _prevPitchAngle;
 resetDragging(_endDraggingPoint);
 }
 
 void GLCamera::resetViewPosition(Orientation2D orientation) {
 kmMat4 cameraMatrix;
 calculateCameraMatrix(&cameraMatrix);
 
 kmVec3 Bc, Rc, Uc;
 calculateCurrentCameraAxes(&Bc, &Rc, &Uc, &cameraMatrix, orientation, true);
 
 float M1Data[] = {Rc.x,Rc.y,Rc.z,0, Uc.x,Uc.y,Uc.z,0, Bc.x,Bc.y,Bc.z,0, 0,0,0,1};
 kmMat4Fill(&_modelRotationMatrix0, M1Data);
 
 resetDragging(_endDraggingPoint);
 _accumulatedPitchAngle = 0.f;
 kmVec3Transform(&_pitchAxis0, &Rw, &cameraMatrix);
 kmVec3Transform(&_yawAxis0, &Uw, &cameraMatrix);
 kmVec3Assign(&_pitchAxis0, &Rc);
 kmVec3Assign(&_yawAxis0, &Uc);
 kmVec3Normalize(&_pitchAxis0, &_pitchAxis0);
 kmVec3Normalize(&_yawAxis0, &_yawAxis0);
 /!!!For Debug
 calculateDebugAxes();
 }
 
 void GLCamera::adjustAxes(Orientation2D orientation) {
 kmMat4 cameraMatrix;
 calculateCameraMatrix(&cameraMatrix);
 *
 kmVec3 Bc, Rc, Uc;
 calculateCurrentCameraAxes(&Bc, &Rc, &Uc, &cameraMatrix, orientation, false);
 
 kmVec3 yawAxis1, rotateAxis, orthogonalAxis0, orthogonalAxis1;
 float angleYawAxis0Rc = fabs(angleOfVectors(NULL, &_yawAxis0, &Rc));
 if (angleYawAxis0Rc > M_PI / 36.f)
 {
 yawAxis1 = rayProjectionOnPlaneFromOrigin(&_yawAxis0, &Rc);
 kmVec3Normalize(&yawAxis1, &yawAxis1);
 }
 else
 {
 yawAxis1 = Uc;
 }
 
 float angleYawAxes = fabs(angleOfVectors(NULL, &_yawAxis0, &yawAxis1));
 if (angleYawAxes > M_PI / 36.f)
 {
 kmVec3Cross(&rotateAxis, &_yawAxis0, &yawAxis1);
 }
 else
 {
 kmVec3Cross(&rotateAxis, &Rc, &yawAxis1);
 }
 
 kmVec3Cross(&orthogonalAxis0, &_yawAxis0, &rotateAxis); R, U, B
 kmVec3Cross(&orthogonalAxis1, &yawAxis1, &rotateAxis);
 
 kmMat4 invY0, Y1;
 kmScalar y0Data[] = {orthogonalAxis0.x, orthogonalAxis0.y, orthogonalAxis0.z, 0.0,
 _yawAxis0.x, _yawAxis0.y, _yawAxis0.z, 0.0,
 rotateAxis.x, rotateAxis.y, rotateAxis.z, 0.0,
 0.0, 0.0, 0.0, 1.0};
 kmScalar y1Data[] = {orthogonalAxis1.x, orthogonalAxis1.y, orthogonalAxis1.z, 0.0,
 yawAxis1.x, yawAxis1.y, yawAxis1.z, 0.0,
 rotateAxis.x, rotateAxis.y, rotateAxis.z, 0.0,
 0.0, 0.0, 0.0, 1.0};
 kmMat4Fill(&invY0, y0Data);
 kmMat4Fill(&Y1, y1Data);
 kmMat4Inverse(&invY0, &invY0);
 kmMat4Multiply(&_modelRotationMatrix0, &invY0, &_modelRotationMatrix0);
 kmMat4Multiply(&_modelRotationMatrix0, &Y1, &_modelRotationMatrix0);
 kmVec3Assign(&_yawAxis0, &yawAxis1);
 kmVec3Assign(&_pitchAxis0, &Rc);
 }
 //*/
void GLCamera::normalizeRotationMatrix(kmMat4* rotationMat) {
    kmVec3 b = {0,0,0};
    kmVec3Transform(&b, &b, rotationMat);
    
    kmVec3 x = {1,0,0}, y = {0,1,0}, z = {0,0,1};
    kmVec3Transform(&x, &x, rotationMat);
    kmVec3Transform(&y, &y, rotationMat);
    kmVec3Transform(&z, &z, rotationMat);
    //    kmVec3 x1 = x, y1 = y, z1 = z;
    
    kmVec3Subtract(&x, &x, &b);
    kmVec3Subtract(&y, &y, &b);
    kmVec3Subtract(&z, &z, &b);
    //    kmVec3 x2 = x, y2 = y, z2 = z;
    
    // Schmidt orthogonalization
    kmVec3Normalize(&x, &x);
    float xy = kmVec3Dot(&x, &y);
    y.x -= xy * x.x;
    y.y -= xy * x.y;
    y.z -= xy * x.z;
    kmVec3Normalize(&y, &y);
    //    float xz = kmVec3Dot(&x, &z);
    //    float yz = kmVec3Dot(&y, &z);
    //    z.x -= (xz * x.x + yz * y.x);
    //    z.y -= (xz * x.y + yz * y.y);
    //    z.z -= (xz * x.z + yz * y.z);
    //    kmVec3Normalize(&z, &z);
    kmVec3Cross(&z, &x, &y);
    //    kmVec3 x3 = x, y3 = y, z3 = z;
    
    float matData[] = {
        x.x, x.y, x.z, 0.f,
        y.x, y.y, y.z, 0.f,
        z.x, z.y, z.z, 0.f,
        0.f, 0.f, 0.f, 1.f,
    };
    kmMat4Fill(rotationMat, matData);
    
    //    float det = kmMat4Determinant(rotationMat);
    //    if (abs(abs(det) - 1.f) > 0.01)
    //    {
    //        kmVec3 x1y1, x1z1, z1y1, x2y2, x2z2, z2y2, x3y3, x3z3, z3y3;
    //        kmVec3Cross(&x1y1, &x1, &y1); kmVec3Cross(&x1z1, &x1, &z1); kmVec3Cross(&z1y1, &z1, &y1);
    //        kmVec3Cross(&x2y2, &x2, &y2); kmVec3Cross(&x2z2, &x2, &z2); kmVec3Cross(&z2y2, &z2, &y2);
    //        kmVec3Cross(&x3y3, &x3, &y3); kmVec3Cross(&x3z3, &x3, &z3); kmVec3Cross(&z3y3, &z3, &y3);
    //        ALOGE("Matrix : det = %f\n[%.5f, %.5f, %.5f, %.5f;\n %.5f, %.5f, %.5f, %.5f;\n %.5f, %.5f, %.5f, %.5f;\n %.5f, %.5f, %.5f, %.5f]\n\n"
    //                      "b = {%.5f, %.5f, %.5f}(%.5f)\n"
    //                      "After Transform : x1 = {%.5f, %.5f, %.5f}(%.5f), y1 = {%.5f, %.5f, %.5f}(%.5f), z1 = {%.5f, %.5f, %.5f}(%.5f)\n"
    //                      "x1 * y1 = %.5f, x1 * z1 = %.5f, z1 * y1 = %.5f\n"
    //                      "After Translate : x2 = {%.5f, %.5f, %.5f}(%.5f), y2 = {%.5f, %.5f, %.5f}(%.5f), z2 = {%.5f, %.5f, %.5f}(%.5f)\n"
    //                      "x2 * y2 = %.5f, x2 * z2 = %.5f, z2 * y2 = %.5f\n"
    //                      "After Normalize : x3 = {%.5f, %.5f, %.5f}(%.5f), y3 = {%.5f, %.5f, %.5f}(%.5f), z3 = {%.5f, %.5f, %.5f}(%.5f)"
    //                      "x3 * y3 = %.5f, x3 * z3 = %.5f, z3 * y3 = %.5f\n\n\n\n",
    //              det, x.x,y.x,z.x,0.f, x.y,y.y,z.y,0.f, x.z,y.z,z.z,0.f, 0.f,0.f,0.f,1.f,
    //              b.x,b.y,b.z,kmVec3Length(&b),
    //              x1.x,x1.y,x1.z,kmVec3Length(&x1), y1.x,y1.y,y1.z,kmVec3Length(&y1), z1.x,z1.y,z1.z,kmVec3Length(&z1),
    //              kmVec3Length(&x1y1), kmVec3Length(&x1z1), kmVec3Length(&z1y1),
    //              x2.x,x2.y,x2.z,kmVec3Length(&x2), y2.x,y2.y,y2.z,kmVec3Length(&y2), z2.x,z2.y,z2.z,kmVec3Length(&z2),
    //              kmVec3Length(&x2y2), kmVec3Length(&x2z2), kmVec3Length(&z2y2),
    //              x3.x,x3.y,x3.z,kmVec3Length(&x3), y3.x,y3.y,y3.z,kmVec3Length(&y3), z3.x,z3.y,z3.z,kmVec3Length(&z3),
    //              kmVec3Length(&x3y3), kmVec3Length(&x3z3), kmVec3Length(&z3y3)
    //        );
    //    }
}

bool GLCamera::checkQuaternion(const kmQuaternion* quaternion) {
    if (isnan(quaternion->x) || isnan(quaternion->y) || isnan(quaternion->z) || isnan(quaternion->w))
    {
        ALOGE("checkQuaternion failed : {%f, %f, %f, %f}", quaternion->x, quaternion->y, quaternion->z, quaternion->w);
        return false;
    }
    return true;
}

void GLCamera::normalizeQuaternion(kmQuaternion* quaternion) {
    if (isnan(quaternion->x) || isnan(quaternion->y) || isnan(quaternion->z) || isnan(quaternion->w))
    {
        kmQuaternionIdentity(quaternion);
    }
    else
    {
        kmQuaternionNormalize(quaternion, quaternion);
    }
}

bool GLCamera::checkVector(const kmVec3* vec) {
    if (isnan(vec->x) || isnan(vec->y) || isnan(vec->z)) return false;
    return true;
}

bool GLCamera::checkRotationMatrix(const kmMat4* matrix, bool completeCheck, const char* tag) {
    const float EPSILON_LENGTH = 0.001f;
    const float EPSILON_DET = 0.01f;
    const float EPSILON_ANGLE_DEGREE = 0.5f;
    
    if (NULL == tag) tag = "";
    
    float det = kmMat4Determinant(matrix);
    if (fabsf(fabsf(det) - 1.f) >= EPSILON_DET)
    {
        ALOGE("GLCamera::checkRotationMatrix'%s' : Determinant=%.5f, diff = %f", tag, det, fabsf(fabsf(det) - 1.f));
        return false;
    }
    if (!completeCheck)
    {
        return true;
    }
    
    kmVec3 bias = {0,0,0};
    kmVec3Transform(&bias, &bias, matrix);
    if (kmVec3Length(&bias) >= EPSILON_LENGTH)
    {
        ALOGE("GLCamera::checkRotationMatrix'%s' : bias={%.5f, %.5f, %.5f}", tag, bias.x, bias.y, bias.z);
        return false;
    }
    
    kmVec3 x = {1,0,0}, y = {0,1,0}, z = {0,0,1};
    kmVec3Transform(&x, &x, matrix);
    kmVec3Transform(&y, &y, matrix);
    kmVec3Transform(&z, &z, matrix);
    kmVec3Subtract(&x, &x, &bias);
    kmVec3Subtract(&y, &y, &bias);
    kmVec3Subtract(&z, &z, &bias);
    float lx = kmVec3Length(&x);
    float ly = kmVec3Length(&y);
    float lz = kmVec3Length(&z);
    if (fabsf(lx - 1.f) >= EPSILON_LENGTH || fabsf(lx - 1.f) >= EPSILON_LENGTH || fabsf(lx - 1.f) >= EPSILON_LENGTH)
    {
        ALOGE("GLCamera::checkRotationMatrix'%s' : After transform and translate to origin: "
              "x' = (%.5f){%.5f, %.5f, %.5f}, y' = (%.5f){%.5f, %.5f, %.5f}, z' = (%.5f){%.5f, %.5f, %.5f}\n", tag,
              lx, x.x, x.y, x.z,
              ly, y.x, y.y, y.z,
              lz, z.x, z.y, z.z);
        return false;
    }
    
    kmVec3 xy, xz, zy;
    kmVec3Cross(&xy, &x, &y);
    kmVec3Cross(&xz, &x, &z);
    kmVec3Cross(&zy, &z, &y);
    float sinA = kmVec3Length(&xy) / lx / ly;
    float sinB = kmVec3Length(&xz) / lx / lz;
    float sinC = kmVec3Length(&zy) / lz / ly;
    float angleDegreeA = fabsf(kmRadiansToDegrees(asin(sinA)));
    float angleDegreeB = fabsf(kmRadiansToDegrees(asin(sinB)));
    float angleDegreeC = fabsf(kmRadiansToDegrees(asin(sinC)));
    if (fabsf(angleDegreeA - 90.f) >= EPSILON_ANGLE_DEGREE || fabsf(angleDegreeB - 90.f) >= EPSILON_ANGLE_DEGREE || fabsf(angleDegreeC - 90.f) >= EPSILON_ANGLE_DEGREE)
    {
        ALOGE("GLCamera::checkRotationMatrix'%s' : SinA=%.5f, A=%.5f\n"
              "GLCamera::checkRotationMatrix'%s' : SinB=%.5f, B=%.5f\n"
              "GLCamera::checkRotationMatrix'%s' : SinC=%.5f, C=%.5f\n",
              tag, sinA, angleDegreeA,
              tag, sinB, angleDegreeB,
              tag, sinC, angleDegreeC);
        return false;
    }
    
    return true;
}

//kmVec2 GLCamera::sphereCoordinateOfProjectedPoint(kmVec2 projectedPoint) {
//    kmVec3 v0 = {
//        (projectedPoint.x - _width / 2.f) * CLIP_WIDTH / _width,
//        (_height / 2.f - projectedPoint.y) * CLIP_WIDTH / _width,
//        -CLIP_Z_NEAR};
//
//    kmMat4 matrix = _currentMatrix;
//
//    kmVec3 v1;
//    kmVec3InverseTransform(&v1, &v0, &matrix);
//
//    GLfloat longitudeRadius = atanf(-v1.x / v1.z);
//    if (v1.z < 0)
//        longitudeRadius += M_PI;
//    else if (v1.x > 0)
//        longitudeRadius += (2.f * M_PI);
//
//    GLfloat latitudeRadius = atanf(sqrtf(v1.x * v1.x + v1.z * v1.z) / v1.y);
//    if (v1.y < 0)
//        latitudeRadius += M_PI;
//
//    kmVec2 ret = {longitudeRadius, latitudeRadius};
//    return ret;
//}
//
//void GLCamera::rotationByProjectedPoints(kmVec2 fromPoint, kmVec2 toPoint) {
//    kmVec2 fromSphereCoord = sphereCoordinateOfProjectedPoint(fromPoint);
//    kmVec2 toSphereCoord = sphereCoordinateOfProjectedPoint(toPoint);
//
//    _diffYawRadius = (fromSphereCoord.x - toSphereCoord.x);
//    _diffPitchRadius = (fromSphereCoord.y - toSphereCoord.y);
//    if (fabsf(_diffYawRadius) > fabsf(_diffPitchRadius))
//    {
//        _diffPitchRadius = 0;
//    }
//    else
//    {
//        _diffYawRadius = 0;
//    }
//
//    _yawRadius += _diffYawRadius;
//    _pitchRadius += _diffPitchRadius;
//}

