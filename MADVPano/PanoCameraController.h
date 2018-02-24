//
//  PanoCameraController.hpp
//  Madv360_v1
//  通过用户输入设备（屏幕触控、陀螺仪）控制全景内容的显示视角
//  Created by DOM QIU on 2017/6/14.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#ifndef PanoCameraController_hpp
#define PanoCameraController_hpp

#include "GLCamera.h"
#include "MadvGLRenderer.h"
#include "AutoRef.h"
//*
#ifdef __cplusplus
extern "C" {
#endif

#ifdef MADVPANO_DLL

#ifdef MADVPANO_EXPORTS
#define MADVPANO_API _declspec(dllexport)
#else
#define MADVPANO_API _declspec(dllimport)
#endif

#else // MADVPANO_DLL
#define MADVPANO_API
#endif // MADVPANO_DLL
//*/
typedef enum {
    PanoControlStateIdle,
    PanoControlStateGyro,
//    PanoControlStatePostGyroAdjust,
    PanoControlStateTouch,
//    PanoControlStatePostTouchAdjust,
    PanoControlStateFling,
} PanoControlState;

/** Panorama View Position Controller */
class MADVPANO_API PanoCameraController {
public:
// 以下凡是不加注释的public方法或者是SDK内部使用，或者是相对低级因而调用者可以不用关心，在平台相关的子类（iOS上是#PanoCameraController_iOS#）中有更好的封装接口
    virtual ~PanoCameraController();
    
    /** Ctor : Create a PanoCameraController instance with a #MadvGLRenderer# (or any concrete subclass of #MadvGLRenderer#) instance which it controls
     * @param panoRenderer  An #AutoRef# pointer to a #MadvGLRenderer# instance
     */
    PanoCameraController(AutoRef<MadvGLRenderer> panoRenderer);
    
    /** Set FOV in X axis */
    void setFOVDegree(int degree);
    
    /** Ctor : Create a PanoCameraController instance with a #GLCamera# instance which it controls
     * @param panoCamera  An #AutoRef# pointer to a #GLCamera# instance. It can be got from a MadvGLRenderer object with glCamera() method
     */
    PanoCameraController(AutoRef<GLCamera> panoCamera);
    
    void setCamera(AutoRef<GLCamera> panoCamera);
    
    bool getViewMatrix(kmMat4* viewMatrix);
    
    /** Enable/Disable vertical dragging which controls pitch angle
     * 目前实践中效果比较好的控制方式是（仿Theta）:
     * In order to avoid some weird problem of tilt yaw axis, we recommend that pitch dragging be disabled while cellphone gyroscope control is enabled simutaneously (just like the way Theta does).
     * But this is not forced.
     * （For VR display mode, there would be some better way to handle this. However we have not fixed some problems in that.）
     */
    inline void setEnablePitchDragging(bool enablePitchDragging) {_enablePitchDragging = enablePitchDragging;}
    
    inline bool getEnablePitchDragging() {return _enablePitchDragging;}
    
    /** Animate the animation if any(e.g., fling for inertia effect)
     * This must be called after stopTouchControl(), otherwise the animation will be freezed.
     * @param dtSeconds 以秒计的帧间隔时间
     */
    void update(float dtSeconds);
    
    void setScreenOrientation(Orientation2D orientation);
    
    void setGyroRotationQuaternion(kmQuaternion* inertialGyroQuaternion, bool isInversed);
    
    void setInertiaGyroRotation(kmQuaternion* inertialGyroQuaternion, bool isInversed);
    
    void startGyroControl(kmQuaternion* startInertialGyroRotation, bool isInversed);
    void startGyroControl();
    
    void stopGyroControl();

    /**
     * Begin a dragging control
     * @param normalizedTouchPoint    Normalized touch begin point in the canvas. For instance, point (100,100) in a 400 * 200 canvas should be normalized to (0.25, 0.5)
     */
    void startTouchControl(kmVec2 normalizedTouchPoint);

    /**
     * Dragging
     * @param normalizedTouchPoint    Normalized dragging point in the canvas. For instance, point (100,100) in a 400 * 200 canvas should be normalized to (0.25, 0.5)
     */
    void setDragPoint(kmVec2 normalizedTouchPoint);

    /**
     * End a dragging control, with final dragging velocity for fling
     * @param normalizedVelocity    Normalized dragging velocity in the canvas. For instance, (100 pixel/sec, 100 pixel/sec) in a 400 * 200 canvas should be normalized to (0.25, 0.5)
     */
    void stopTouchControl(kmVec2 normalizedVelocity);
    
    void setVirtualCameraPreRotationMatrix(const kmMat4* virtualCameraPreRotationMatrix);
    
    /** Set direction of looking with Euler angles */
    void lookAt(float yawDegrees, float pitchDegrees, float bankDegrees);

    /** Reset view position to initial state */
    void resetViewPosition();
    
    void adjustDragAxis();
    
protected:
    
    inline PanoControlState getState() {return _state;}
    inline void setState(PanoControlState state) {_state = state;}
    
private:
    
    void calculateVirtualCameraRotationMatrix(kmMat4* virtualCameraRotationMatrix);
    void calcAndSetVirtualCameraRotationMatrixIfNecessary(kmMat4* virtualCameraRotationMatrix, bool invalidate);
    
    void calculateVirtualCameraPreRotationMatrix(kmMat4* virtualCameraPreRotationMatrix);
    void calcAndSetVirtualCameraPreRotationMatrixIfNecessary(kmMat4* virtualCameraPreRotationMatrix, bool invalidate);
    
    void calculateModelRotationMatrix(kmMat4* modelRotationMatrix, const kmMat4* virtualCameraRotationMatrix);
    void calcAndSetModelRotationMatrixIfNecessary(kmMat4* modelRotationMatrix, const kmMat4* virtualCameraRotationMatrix, bool invalidate);
    
    bool _enablePitchDragging;
    
    AutoRef<GLCamera> _camera;
    PanoControlState _state;
    
    Orientation2D _screenOrientation;
    
    kmMat4 _virtualCameraPreRotationMatrix0;
    kmMat4 _virtualCameraPreBankRotationMatrix;
    
    kmQuaternion _inertialGyroRotation;
    kmQuaternion _startInertialGyroRotation;
    kmQuaternion _baseVirtualGyroRotation;
    
    kmQuaternion _baseModelRotation;
    
    kmVec2 _startDragPoint;
    kmVec2 _currentDragPoint;
    
    float _angleVelocityDeceleration;
    float _angleVelocity;
    float _diffAngle;
    float _accumulatedAngle;
    kmVec2 _diffYawAndPitch;
    kmVec3 _yawAxis;
    kmVec3 _pitchAxis;
    
    bool _isVirtualCameraRotationInvalid;
    bool _isVirtualCameraPreRotationInvalid;
    bool _isModelRotationInvalid;
};
//*
//typedef AutoRef<PanoCameraController> PanoCameraControllerRef;
#ifdef __cplusplus
}
#endif
//*/
#endif /* PanoCameraController_hpp */
