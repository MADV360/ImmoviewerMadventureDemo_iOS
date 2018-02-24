//
//  PanoCameraController.cpp
//  Madv360_v1
//
//  Created by DOM QIU on 2017/6/14.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#include "PanoCameraController.h"

#define DEFALUT_ANGLE_VELOCITY_DECELERATION 3.f

kmVec3 rayProjectionOnPlaneFromOrigin(kmVec3* ray, kmVec3* normal) {
    kmVec3 ret = *ray;
    kmVec3 normalizedNormal;
    kmVec3Normalize(&normalizedNormal, normal);
    float lengthInNormal = kmVec3Dot(ray, &normalizedNormal);
    ret.x -= lengthInNormal * normalizedNormal.x;
    ret.y -= lengthInNormal * normalizedNormal.y;
    ret.z -= lengthInNormal * normalizedNormal.z;
    return ret;
}

PanoCameraController::~PanoCameraController() {
    _camera = NULL;
}

PanoCameraController::PanoCameraController(AutoRef<GLCamera> panoCamera)
: _enablePitchDragging(true)
, _startDragPoint({0.f, 0.f})
, _currentDragPoint({0.f, 0.f})
,_angleVelocityDeceleration(DEFALUT_ANGLE_VELOCITY_DECELERATION)
, _camera(panoCamera)
, _state(PanoControlStateIdle)
, _screenOrientation(OrientationNormal)
, _isVirtualCameraRotationInvalid(true)
, _isVirtualCameraPreRotationInvalid(true)
, _isModelRotationInvalid(true)
{
    kmQuaternionIdentity(&_inertialGyroRotation);
    kmQuaternionIdentity(&_startInertialGyroRotation);
    kmQuaternionIdentity(&_baseVirtualGyroRotation);
    kmQuaternionIdentity(&_baseModelRotation);
    kmMat4Identity(&_virtualCameraPreRotationMatrix0);
    kmMat4Identity(&_virtualCameraPreBankRotationMatrix);
    
    if (panoCamera)
    {
        getViewMatrix(NULL);
    }
}

void PanoCameraController::setCamera(AutoRef<GLCamera> panoCamera) {
    _camera = panoCamera;
    if (panoCamera)
    {
        getViewMatrix(NULL);
    }
}

void PanoCameraController::setFOVDegree(int degree) {
    if (_camera)
    {
        _camera->setFOVDegree(degree);
    }
}

void PanoCameraController::setInertiaGyroRotation(kmQuaternion* inertialGyroQuaternion, bool isInversed) {
    if (PanoControlStateGyro != getState())
        return;
    
    if (isInversed)
    {
        kmMat4 inertialGyroMatrix;
        kmMat4RotationQuaternion(&inertialGyroMatrix, inertialGyroQuaternion);
        kmMat4Inverse(&inertialGyroMatrix, &inertialGyroMatrix);
        kmQuaternionRotationMatrix(&_inertialGyroRotation, &inertialGyroMatrix);
    }
    else
    {
        kmQuaternionAssign(&_inertialGyroRotation, inertialGyroQuaternion);
    }
    
    calcAndSetVirtualCameraRotationMatrixIfNecessary(NULL, true);
}

void PanoCameraController::startGyroControl(kmQuaternion* startInertialGyroRotation, bool isInversed) {
    if (PanoControlStateFling == getState())
        return;
    //ALOGE("#GLCamera#setState# PanoControlStateGyro @ startGyroControl:");
    setState(PanoControlStateGyro);
    
    if (isInversed)
    {
        kmMat4 inertialGyroMatrix;
        kmMat4RotationQuaternion(&inertialGyroMatrix, startInertialGyroRotation);
        kmMat4Inverse(&inertialGyroMatrix, &inertialGyroMatrix);
        kmQuaternionRotationMatrix(&_inertialGyroRotation, &inertialGyroMatrix);
    }
    else
    {
        kmQuaternionAssign(&_inertialGyroRotation, startInertialGyroRotation);
    }
    kmQuaternionAssign(&_startInertialGyroRotation, &_inertialGyroRotation);
    
    calcAndSetVirtualCameraRotationMatrixIfNecessary(NULL, true);
}

void PanoCameraController::startGyroControl() {
    if (PanoControlStateFling == getState())
        return;
    //ALOGE("#GLCamera#setState# PanoControlStateGyro @ startGyroControl");
    setState(PanoControlStateGyro);
    
    kmQuaternionIdentity(&_startInertialGyroRotation);
    kmQuaternionIdentity(&_baseVirtualGyroRotation);
    
    calcAndSetVirtualCameraRotationMatrixIfNecessary(NULL, true);
}

void PanoCameraController::stopGyroControl() {
    if (PanoControlStateGyro != getState())
        return;
    
    kmMat4 virtualCameraRotationMatrix;
    calculateVirtualCameraRotationMatrix(&virtualCameraRotationMatrix);
    kmQuaternionRotationMatrix(&_baseVirtualGyroRotation, &virtualCameraRotationMatrix);

    kmQuaternionIdentity(&_startInertialGyroRotation);
    kmQuaternionIdentity(&_inertialGyroRotation);
    //ALOGE("#GLCamera#setState# PanoControlStateIdle @ stopGyroControl");
    setState(PanoControlStateIdle);
}

void PanoCameraController::setGyroRotationQuaternion(kmQuaternion* inertialGyroQuaternion, bool isInversed) {
    switch (getState())
    {
        case PanoControlStateIdle:
            startGyroControl();
            break;
        case PanoControlStateGyro:
            setInertiaGyroRotation(inertialGyroQuaternion, isInversed);
            break;
        default:
            break;
    }
}

void PanoCameraController::startTouchControl(kmVec2 normalizedTouchPoint) {
    if (PanoControlStateFling == getState())
        return;
    
    adjustDragAxis();
    //ALOGE("#GLCamera#setState# PanoControlStateTouch @ startTouchControl:");
    setState(PanoControlStateTouch);
    
    _startDragPoint = normalizedTouchPoint;
    _currentDragPoint = normalizedTouchPoint;
    
    calcAndSetModelRotationMatrixIfNecessary(NULL, NULL, true);
}

void PanoCameraController::setDragPoint(kmVec2 normalizedTouchPoint) {
    if (PanoControlStateTouch != getState())
        return;
    
    _currentDragPoint = normalizedTouchPoint;
    
    calcAndSetModelRotationMatrixIfNecessary(NULL, NULL, true);
}

void PanoCameraController::stopTouchControl(kmVec2 normalizedVelocity) {
    if (PanoControlStateTouch != getState())
        return;
    
    // Calculate differencial rotation quaternion:
    kmQuaternion diffRotation;
    kmMat4 startRotationMatrix, endRotationMatrix, diffRotationMatrix;
    kmMat4RotationQuaternion(&startRotationMatrix, &_baseModelRotation);
    calculateModelRotationMatrix(&endRotationMatrix, NULL);
    kmMat4Inverse(&diffRotationMatrix, &startRotationMatrix);
    kmMat4Multiply(&diffRotationMatrix, &endRotationMatrix, &diffRotationMatrix);
    kmQuaternionRotationMatrix(&diffRotation, &diffRotationMatrix);
    // Diff rotation angle:
    _diffAngle = fabsf(acosf(diffRotation.w) * 2);
    _accumulatedAngle = _diffAngle;
    // Differential drag:
    kmVec2 diffDrag;
    kmVec2Subtract(&diffDrag, &_currentDragPoint, &_startDragPoint);
    float dragDistance = kmVec2Length(&diffDrag);
    float scalarVelocity = kmVec2Length(&normalizedVelocity);
    float anglePerNormalizedPixel = _diffAngle / dragDistance;
    if (0.f == dragDistance || isnan(anglePerNormalizedPixel))
    {
        anglePerNormalizedPixel = M_PI / 2;
    }
    _angleVelocity = scalarVelocity * anglePerNormalizedPixel;
    
//    ALOGE("#GLCamera#Fling# dragDistance=%f, _diffAngle=%f, anglePerNormalizedPixel=%f, _angleVelocity=%f, _angleVelocityDeceleration=%f", dragDistance, _diffAngle, anglePerNormalizedPixel, _angleVelocity, _angleVelocityDeceleration);
    
    _currentDragPoint = _startDragPoint;
    
//    if (_angleVelocityDeceleration < _angleVelocity)
    {//ALOGE("#GLCamera#setState# PanoControlStateFling @ stopTouchControl");
        setState(PanoControlStateFling);
    }
//    else
//    {ALOGE("#GLCamera#setState# PanoControlStateIdle @ stopTouchControl");
//        kmQuaternionRotationMatrix(&_baseModelRotation, &endRotationMatrix);
//        setState(PanoControlStateIdle);
//    }
}

void PanoCameraController::setVirtualCameraPreRotationMatrix(const kmMat4* virtualCameraPreRotationMatrix) {
    kmMat4Assign(&_virtualCameraPreRotationMatrix0, virtualCameraPreRotationMatrix);
    
    calcAndSetVirtualCameraPreRotationMatrixIfNecessary(NULL, true);
}

void PanoCameraController::setScreenOrientation(Orientation2D orientation) {
    if (_screenOrientation == orientation)
        return;
    
    _screenOrientation = orientation;
    
    switch (orientation)
    {
        case OrientationNormal:
            kmMat4Identity(&_virtualCameraPreBankRotationMatrix);
            break;
        case OrientationRotateRight:
            kmMat4RotationZ(&_virtualCameraPreBankRotationMatrix, M_PI / 2);
            break;
        case OrientationRotateLeft:
            kmMat4RotationZ(&_virtualCameraPreBankRotationMatrix, -M_PI / 2);
            break;
        case OrientationRotate180DegreeMirror:
            kmMat4RotationZ(&_virtualCameraPreBankRotationMatrix, M_PI);
            break;
        default:
            break;
    }
    
    calcAndSetVirtualCameraPreRotationMatrixIfNecessary(NULL, true);
}

bool PanoCameraController::getViewMatrix(kmMat4* viewMatrix) {
    kmMat4 modelMatrix, cameraMatrix0, cameraPreRotationMatrix;
    calcAndSetVirtualCameraPreRotationMatrixIfNecessary(&cameraPreRotationMatrix, true);
    calcAndSetVirtualCameraRotationMatrixIfNecessary(&cameraMatrix0, true);
    calcAndSetModelRotationMatrixIfNecessary(&modelMatrix, &cameraMatrix0, true);
    if (_camera)
    {
        _camera->getViewMatrix(viewMatrix);
    }
    return false;
}

void PanoCameraController::update(float dtSeconds) {
    switch (getState())
    {
        case PanoControlStateFling:
        {
            _accumulatedAngle += _angleVelocity * dtSeconds;
            float t = _accumulatedAngle / _diffAngle;
            if (0.f == _diffAngle || isnan(t))
            {
                t = 1.f;
            }
            float yawAngle = _diffYawAndPitch.x * t;
            float pitchAngle = _diffYawAndPitch.y * t;
            
            kmMat4 modelRotationMatrix;
            kmMat4RotationQuaternion(&modelRotationMatrix, &_baseModelRotation);
            kmMat4RotationAxisAngleBy(&modelRotationMatrix, &_yawAxis, yawAngle);
            kmMat4RotationAxisAngleBy(&modelRotationMatrix, &_pitchAxis, pitchAngle);
            
            GLCamera::normalizeRotationMatrix(&modelRotationMatrix);
            
            if (_camera)
            {
                _camera->setModelRotationMatrix(&modelRotationMatrix);
            }
            //GLCamera::checkRotationMatrix(&modelRotationMatrix, true, "modelRotationMatrix@update");
            _angleVelocity -= _angleVelocityDeceleration * dtSeconds;
//            ALOGE("#GLCamera#Fling# accAngle=%f, _diffAngle=%f, _angleVelocity=%f, _angleVelocityDeceleration=%f, dtSeconds=%f", _accumulatedAngle, _diffAngle, _angleVelocity, _angleVelocityDeceleration, dtSeconds);
            if (_angleVelocity < 0.f)
            {//ALOGE("#GLCamera#setState#Fling# PanoControlStateIdle @ update");
                kmQuaternionRotationMatrix(&_baseModelRotation, &modelRotationMatrix);
                
                _isModelRotationInvalid = false;
                setState(PanoControlStateIdle);
            }
        }
            break;
        default:
            break;
    }
}

void PanoCameraController::resetViewPosition() {
    /*
    kmMat4 virtualCameraRotationMatrix;
    if (getEnablePitchDragging())
    {
        calculateVirtualCameraRotationMatrix(&virtualCameraRotationMatrix);
        kmMat4 cameraPreRotationMat;
        calculateVirtualCameraPreRotationMatrix(&cameraPreRotationMat);
        kmMat4Multiply(&virtualCameraRotationMatrix, &virtualCameraRotationMatrix, &cameraPreRotationMat);
    }
    else
    {
        kmMat4Identity(&virtualCameraRotationMatrix);
    }
    kmQuaternionRotationMatrix(&_baseModelRotation, &virtualCameraRotationMatrix);
    
    _currentDragPoint = _startDragPoint;
    if (_camera)
    {
        _camera->setModelRotationMatrix(&virtualCameraRotationMatrix);
        _isModelRotationInvalid = false;
    }
    /*/
    lookAt(0.f, 0.f, 0.f);
    //*/
}

void PanoCameraController::lookAt(float yawDegrees, float pitchDegrees, float bankDegrees) {
    ALOGE("#lookAt# yaw=%.3f, pitch=%.3f, bank=%.3f", yawDegrees,pitchDegrees,bankDegrees);
    kmMat4 virtualCameraRotationMatrix;
    if (getEnablePitchDragging())
    {
        calculateVirtualCameraRotationMatrix(&virtualCameraRotationMatrix);
        kmMat4 cameraPreRotationMat;
        calculateVirtualCameraPreRotationMatrix(&cameraPreRotationMat);
        kmMat4Multiply(&virtualCameraRotationMatrix, &virtualCameraRotationMatrix, &cameraPreRotationMat);
    }
    else
    {
        kmMat4Identity(&virtualCameraRotationMatrix);
    }
    
    if (pitchDegrees > 90.f)
        pitchDegrees = 90.f;
    else if (pitchDegrees < -90.f)
        pitchDegrees = -90.f;
    float yawRadians = kmDegreesToRadians(yawDegrees);
    float pitchRadians = kmDegreesToRadians(pitchDegrees);
    float bankRadians = kmDegreesToRadians(bankDegrees);
    
    kmVec3 forwardVector;// -z
    // Pitch rotation: X':-Z, Y':Y
    forwardVector.y = sinf(pitchRadians);
    float radiusOnXZ = cosf(pitchRadians);
    // Yaw rotation: X':-Z, Y':X
    forwardVector.z = -cosf(yawRadians) * radiusOnXZ;
    forwardVector.x = sinf(yawRadians) * radiusOnXZ;
    kmVec3Normalize(&forwardVector, &forwardVector);
    kmVec3 rightVector;// x
    // Yaw rotation: X':X, Y':Z
    rightVector.x = cosf(yawRadians);
    rightVector.z = sinf(yawRadians);
    rightVector.y = 0.f;
    kmVec3 upwardVector;// y
    kmVec3Cross(&upwardVector, &rightVector, &forwardVector);
    kmVec3Normalize(&upwardVector, &upwardVector);
    
    float rotationMatrixData[] = {
        rightVector.x, rightVector.y, rightVector.z, 0.f,
        upwardVector.x, upwardVector.y, upwardVector.z, 0.f,
        -forwardVector.x, -forwardVector.y, -forwardVector.z, 0.f,
        0.f, 0.f, 0.f, 1.f
    };
    kmMat4 rotationMatrix;
    kmMat4Fill(&rotationMatrix, rotationMatrixData);
    kmMat4RotationAxisAngleBy(&rotationMatrix, &forwardVector, bankRadians);
    
    kmMat4Inverse(&rotationMatrix, &rotationMatrix);
    kmMat4Multiply(&rotationMatrix, &rotationMatrix, &virtualCameraRotationMatrix);

    kmQuaternionRotationMatrix(&_baseModelRotation, &rotationMatrix);
    
    _currentDragPoint = _startDragPoint;
    if (_camera)
    {
        _camera->setModelRotationMatrix(&rotationMatrix);
        _isModelRotationInvalid = false;
    }
}

void PanoCameraController::adjustDragAxis() {
    kmMat4 finalCameraMat, cameraMatrix, cameraPreRotationMatrix;
    calculateVirtualCameraPreRotationMatrix(&cameraPreRotationMatrix);
    calculateVirtualCameraRotationMatrix(&cameraMatrix);
    kmMat4Multiply(&finalCameraMat, &cameraMatrix, &cameraPreRotationMatrix);
    
    // Rc is right-direction-of-screen vector in inertia coordsystem, i.e. Pitch axis:
    kmVec3 Uw = {0.f, 1.f, 0.f}, Bc = {0.f, 0.f, 1.f}, Rc, Uc;
    kmVec3Transform(&Bc, &Bc, &cameraMatrix);
    kmVec3Cross(&Rc, &Uw, &Bc);
    float sinAngle = kmVec3Length(&Rc) / kmVec3Length(&Bc);///  / kmVec3Length(&Uw) = 1.f
    float angle = kmRadiansToDegrees(asinf(fabsf(sinAngle)));
    if (angle <= 30.f)
    {
        Rc = {1.f, 0.f, 0.f};
        kmVec3Transform(&Rc, &Rc, &finalCameraMat);
    }
    kmVec3Normalize(&Rc, &Rc);
    kmVec3Cross(&Uc, &Bc, &Rc);
    
    // Calculate Um's 'pitch-down' angle:
    float pitchDownAngle;
    kmVec3 Um = {0.f, 1.f, 0.f}, Rm, Bm;
    kmMat4 modelMatrix;
    kmMat4RotationQuaternion(&modelMatrix, &_baseModelRotation);
    kmVec3Transform(&Um, &Um, &modelMatrix);
    kmVec3 pitchPlaneNormal;
    kmVec3Cross(&pitchPlaneNormal, &Um, &Uc);
    float sinUmUc = kmVec3Length(&pitchPlaneNormal) / kmVec3Length(&Um) / kmVec3Length(&Uc);
    if (asinf(sinUmUc) < M_PI / 18.f)
    {
        
    }
    else
    {
        kmVec3 pitchPlaneOrthogonalAxis;
        kmVec3Cross(&pitchPlaneOrthogonalAxis, &Uc, &pitchPlaneNormal);
        if (kmVec3Dot(&pitchPlaneOrthogonalAxis, &Bc) > 0.f)
        {
            kmVec3Scale(&pitchPlaneOrthogonalAxis, &pitchPlaneOrthogonalAxis, -1.f);
        }
        float xPitch = kmVec3Dot(&Um, &Uc);
        float yPitch = kmVec3Dot(&Um, &pitchPlaneOrthogonalAxis);
        pitchDownAngle = atan2f(yPitch, xPitch);
    }
    
    
//    calculateCameraMatrix(&cameraMatrix);
//    *
//    kmVec3 Bc, Rc, Uc;
//    calculateCurrentCameraAxes(&Bc, &Rc, &Uc, &cameraMatrix, orientation, false);
//    
//    kmVec3 yawAxis1, rotateAxis, orthogonalAxis0, orthogonalAxis1;
//    float angleYawAxis0Rc = fabs(angleOfVectors(NULL, &_yawAxis0, &Rc));
//    if (angleYawAxis0Rc > M_PI / 36.f)
//    {
//        yawAxis1 = rayProjectionOnPlaneFromOrigin(&_yawAxis0, &Rc);
//        kmVec3Normalize(&yawAxis1, &yawAxis1);
//    }
//    else
//    {
//        yawAxis1 = Uc;
//    }
//    
//    float angleYawAxes = fabs(angleOfVectors(NULL, &_yawAxis0, &yawAxis1));
//    if (angleYawAxes > M_PI / 36.f)
//    {
//        kmVec3Cross(&rotateAxis, &_yawAxis0, &yawAxis1);
//    }
//    else
//    {
//        kmVec3Cross(&rotateAxis, &Rc, &yawAxis1);
//    }
//    
//    kmVec3Cross(&orthogonalAxis0, &_yawAxis0, &rotateAxis); R, U, B
//    kmVec3Cross(&orthogonalAxis1, &yawAxis1, &rotateAxis);
//    
//    kmMat4 invY0, Y1;
//    kmScalar y0Data[] = {orthogonalAxis0.x, orthogonalAxis0.y, orthogonalAxis0.z, 0.0,
//        _yawAxis0.x, _yawAxis0.y, _yawAxis0.z, 0.0,
//        rotateAxis.x, rotateAxis.y, rotateAxis.z, 0.0,
//        0.0, 0.0, 0.0, 1.0};
//    kmScalar y1Data[] = {orthogonalAxis1.x, orthogonalAxis1.y, orthogonalAxis1.z, 0.0,
//        yawAxis1.x, yawAxis1.y, yawAxis1.z, 0.0,
//        rotateAxis.x, rotateAxis.y, rotateAxis.z, 0.0,
//        0.0, 0.0, 0.0, 1.0};
//    kmMat4Fill(&invY0, y0Data);
//    kmMat4Fill(&Y1, y1Data);
//    kmMat4Inverse(&invY0, &invY0);
//    kmMat4Multiply(&_modelRotationMatrix0, &invY0, &_modelRotationMatrix0);
//    kmMat4Multiply(&_modelRotationMatrix0, &Y1, &_modelRotationMatrix0);
//    kmVec3Assign(&_yawAxis0, &yawAxis1);
//    kmVec3Assign(&_pitchAxis0, &Rc);
}

void PanoCameraController::calculateVirtualCameraPreRotationMatrix(kmMat4* virtualCameraPreRotationMatrix) {
    if (NULL == virtualCameraPreRotationMatrix)
        return;
    
    kmMat4Multiply(virtualCameraPreRotationMatrix, &_virtualCameraPreRotationMatrix0, &_virtualCameraPreBankRotationMatrix);
    //GLCamera::checkRotationMatrix(virtualCameraPreRotationMatrix, true, "virtualCameraPreRotationMatrix");
    GLCamera::normalizeRotationMatrix(virtualCameraPreRotationMatrix);
}

void PanoCameraController::calculateVirtualCameraRotationMatrix(kmMat4* virtualCameraRotationMatrix) {
    if (NULL == virtualCameraRotationMatrix)
        return;
    
    kmMat4 invStartInertiaGyroMat, currentInertiaGyroMat;
    
    kmMat4RotationQuaternion(&invStartInertiaGyroMat, &_startInertialGyroRotation);
    kmMat4Inverse(&invStartInertiaGyroMat, &invStartInertiaGyroMat);
    kmMat4RotationQuaternion(&currentInertiaGyroMat, &_inertialGyroRotation);
    kmMat4RotationQuaternion(virtualCameraRotationMatrix, &_baseVirtualGyroRotation);
    
    kmMat4Multiply(virtualCameraRotationMatrix, &invStartInertiaGyroMat, virtualCameraRotationMatrix);
    kmMat4Multiply(virtualCameraRotationMatrix, &currentInertiaGyroMat, virtualCameraRotationMatrix);
    //GLCamera::checkRotationMatrix(virtualCameraRotationMatrix, true, "virtualCameraRotationMatrix");
    GLCamera::normalizeRotationMatrix(virtualCameraRotationMatrix);
}

float calculatePitchDownAngle(const kmMat4* modelRotationMatrix, const kmVec3* Uc, const kmVec3* Bc) {
    // Calculate Um's 'pitch-down' angle:
    float pitchDownAngle;
    kmVec3 Um = {0.f, 1.f, 0.f};
    kmVec3Transform(&Um, &Um, modelRotationMatrix);
    kmVec3 pitchPlaneNormal;
    kmVec3Cross(&pitchPlaneNormal, &Um, Uc);
    float sinUmUc = kmVec3Length(&pitchPlaneNormal) / kmVec3Length(&Um) / kmVec3Length(Uc);
    if (asinf(sinUmUc) < M_PI / 180.f)
    {
        if (kmVec3Dot(&Um, Uc) > 0.f)
            return M_PI / 2;
        else
            return -M_PI / 2;
    }
    else
    {
        kmVec3 pitchPlaneOrthogonalAxis;
        kmVec3Cross(&pitchPlaneOrthogonalAxis, Uc, &pitchPlaneNormal);
        if (kmVec3Dot(&pitchPlaneOrthogonalAxis, Bc) > 0.f)
        {
            kmVec3Scale(&pitchPlaneOrthogonalAxis, &pitchPlaneOrthogonalAxis, -1.f);
        }
        float yPitch = kmVec3Dot(&Um, Uc);
        float xPitch = kmVec3Dot(&Um, &pitchPlaneOrthogonalAxis);
        pitchDownAngle = atan2f(yPitch, xPitch);
//        if (pitchDownAngle < 0.f)
//            pitchDownAngle += 2 * M_PI;
        return pitchDownAngle;
    }
}

void PanoCameraController::calculateModelRotationMatrix(kmMat4* modelRotationMatrix, const kmMat4* virtualCameraRotationMatrix) {
    if (NULL == modelRotationMatrix)
        return;
    
    kmMat4 calculatedVirtualCameraMatrix;
    if (NULL == virtualCameraRotationMatrix)
    {
        virtualCameraRotationMatrix = &calculatedVirtualCameraMatrix;
        calculateVirtualCameraRotationMatrix(&calculatedVirtualCameraMatrix);
    }
    // Drag vector in inertia coordsystem:
    kmVec2 dragVectorOnScreen;
    kmVec2Subtract(&dragVectorOnScreen, &_currentDragPoint, &_startDragPoint);
    kmVec3 dragVector = {dragVectorOnScreen.x, dragVectorOnScreen.y, 0.f};
    kmMat4 cameraMat, cameraPreRotationMat;
    calculateVirtualCameraPreRotationMatrix(&cameraPreRotationMat);
    kmMat4Multiply(&cameraMat, virtualCameraRotationMatrix, &cameraPreRotationMat);
    kmVec3Transform(&dragVector, &dragVector, &cameraMat);
    // Um is up-direction-of-model vector in inertia coordsystem, i.e. Yaw axis:
    kmVec3 Um = {0.f, 1.f, 0.f};
    kmMat4 baseModelRotationMatrix;
    kmMat4RotationQuaternion(&baseModelRotationMatrix, &_baseModelRotation);
    kmVec3Transform(&Um, &Um, &baseModelRotationMatrix);
    // Rc is right-direction-of-screen vector in inertia coordsystem, i.e. Pitch axis:
    kmVec3 Uw = {0.f, 1.f, 0.f}, Bc = {0.f, 0.f, 1.f}, Rc;
    kmVec3Transform(&Bc, &Bc, virtualCameraRotationMatrix);
    kmVec3Cross(&Rc, &Uw, &Bc);
    float sinAngle = kmVec3Length(&Rc) / kmVec3Length(&Bc);///  / kmVec3Length(&Uw) = 1.f
    float angle = kmRadiansToDegrees(asinf(fabsf(sinAngle)));
    if (angle <= 30.f)
    {
        Rc = {1.f, 0.f, 0.f};
        kmVec3Transform(&Rc, &Rc, &cameraMat);
    }
    kmVec3Normalize(&Rc, &Rc);
    // Extract drag vector in Rc & perpendicular Rc:
    float yawDrag = kmVec3Dot(&dragVector, &Rc);
    dragVector.x -= yawDrag * Rc.x;
    dragVector.y -= yawDrag * Rc.y;
    dragVector.z -= yawDrag * Rc.z;
    kmVec3 Uc;
    kmVec3Cross(&Uc, &Bc, &Rc);
    float pitchDrag = getEnablePitchDragging() ? kmVec3Dot(&dragVector, &Uc) : 0.f;
    // Get yaw and pitch angles and axis for flinging:
    _diffYawAndPitch = {(float)(-yawDrag * M_PI / 2), (float)(pitchDrag * M_PI / 2)};
    kmVec3Assign(&_yawAxis, &Um);
    kmVec3Assign(&_pitchAxis, &Rc);
    // Rotate the model:
    kmMat4 modelMatrixWithoutPitch;
    kmMat4Assign(modelRotationMatrix, &baseModelRotationMatrix);
    kmMat4RotationAxisAngleBy(modelRotationMatrix, &Um, _diffYawAndPitch.x);
    kmMat4Assign(&modelMatrixWithoutPitch, modelRotationMatrix);
    kmMat4RotationAxisAngleBy(modelRotationMatrix, &Rc, _diffYawAndPitch.y);
//    ALOGE("#Rotation# getEnablePitchDragging()=%d, pitchAngle=%f, Rc={%.3f, %.3f, %.3f}", (int)getEnablePitchDragging(), _diffYawAndPitch.y * 180.f / M_PI, Rc.x,Rc.y,Rc.z);
//    float pitchDownAngle0 = calculatePitchDownAngle(&modelMatrixWithoutPitch, &Uc, &Bc);
//    float pitchDownAngle1 = calculatePitchDownAngle(modelRotationMatrix, &Uc, &Bc);
//    ALOGE("pitchDown1 = %f, pitchDown0 = %f", pitchDownAngle1, pitchDownAngle0);
//    if (pitchDownAngle1 != pitchDownAngle0 && (pitchDownAngle1 < 0.f || pitchDownAngle1 > M_PI))
//    {
//        kmQuaternion q0, q1, qI;
//        kmQuaternionRotationMatrix(&q0, &modelMatrixWithoutPitch);
//        kmQuaternionRotationMatrix(&q1, modelRotationMatrix);
//        float angleCut = pitchDownAngle1;
//        if (pitchDownAngle1 < M_PI / 6)
//            angleCut = M_PI / 6;
//        else if (pitchDownAngle1 > M_PI * 5 / 6)
//            angleCut = M_PI * 5 / 6;
//        float t = (angleCut - pitchDownAngle0) / (pitchDownAngle1 - pitchDownAngle0);
//        kmQuaternionSlerp(&qI, &q0, &q1, t);
//        kmMat4RotationQuaternion(modelRotationMatrix, &qI);
//    }
    //GLCamera::checkRotationMatrix(modelRotationMatrix, true, "modelRotationMatrix");
    GLCamera::normalizeRotationMatrix(modelRotationMatrix);
}

void PanoCameraController::calcAndSetVirtualCameraPreRotationMatrixIfNecessary(kmMat4* virtualCameraPreRotationMatrix, bool invalidate) {
    if (_isVirtualCameraPreRotationInvalid || invalidate)
    {
        _isVirtualCameraPreRotationInvalid = true;
        
        kmMat4 matrix;
        if (NULL == virtualCameraPreRotationMatrix)
        {
            virtualCameraPreRotationMatrix = &matrix;
        }
        calculateVirtualCameraPreRotationMatrix(virtualCameraPreRotationMatrix);
        
        if (_camera)
        {
            _camera->setCameraPreRotationMatrix(virtualCameraPreRotationMatrix);
            _isVirtualCameraPreRotationInvalid = false;
        }
    }
}

void PanoCameraController::calcAndSetVirtualCameraRotationMatrixIfNecessary(kmMat4* virtualCameraRotationMatrix, bool invalidate) {
    if (_isVirtualCameraRotationInvalid || invalidate)
    {
        _isVirtualCameraRotationInvalid = true;
        
        kmMat4 matrix;
        if (NULL == virtualCameraRotationMatrix)
        {
            virtualCameraRotationMatrix = &matrix;
        }
        calculateVirtualCameraRotationMatrix(virtualCameraRotationMatrix);
        
        if (_camera)
        {
            _camera->setCameraRotationMatrix(virtualCameraRotationMatrix, false);
            _isVirtualCameraRotationInvalid = false;
        }
    }
}

void PanoCameraController::calcAndSetModelRotationMatrixIfNecessary(kmMat4* modelRotationMatrix, const kmMat4* virtualCameraRotationMatrix, bool invalidate) {
    if (_isModelRotationInvalid || invalidate)
    {
        _isModelRotationInvalid = true;
        
        kmMat4 matrix;
        if (NULL == modelRotationMatrix)
        {
            modelRotationMatrix = &matrix;
        }
        calculateModelRotationMatrix(modelRotationMatrix, virtualCameraRotationMatrix);
        
        if (_camera)
        {
            _camera->setModelRotationMatrix(modelRotationMatrix);
            _isModelRotationInvalid = false;
        }
    }
}
