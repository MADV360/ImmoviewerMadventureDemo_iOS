//
//  GLCamera.hpp
//  Madv360_v1
//
//  Created by QiuDong on 16/4/27.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#ifndef GLCamera_hpp
#define GLCamera_hpp

#include "gles2.h"

#include "AutoRef.h"
#include "kazmath.h"
#include "OpenGLHelper.h"

#ifdef DEBUGGING_RENDER

#define USE_DEBUG_MODEL_MATRIX

extern float DebugMatrixData[];

#define DEBUG_MODEL_MATRIX {0.19950, 0.72679, -0.65725, 0.00000, -0.00000, 0.67073, 0.74170, 0.00000, 0.97990, -0.14797, 0.13381, 0.00000, 0.00000, 0.00000, 0.00000, 1.00000}
// {0.98461, -0.01282, -0.17429, 0.00000, -0.00000, 0.99731, -0.07335, 0.00000, 0.17476, 0.07222, 0.98196, 0.00000, 0.00000, 0.00000, 0.00000, 1.00000}
//float DebugMatrixData[] = {1.00000, 0.00000, 0.00000, 0.00000, 0.00000, 1.00000, 0.00000, 0.00000, 0.00000, 0.00000, 1.00000, 0.00000, 0.00000, 0.00000, 0.00000, 1.00000};
//float DebugMatrixData[] = {0.57908, 0.64683, 0.49626, 0.00000, 0.00000, 0.60871, -0.79340, 0.00000, -0.81527, 0.45944, 0.35249, 0.00000, 0.00000, 0.00000, 0.00000, 1.00000};
//{0.84012, 0.50222, 0.20486, 0.00000, 0.00000, 0.37769, -0.92593, 0.00000, -0.54240, 0.77790, 0.31730, 0.00000, 0.00000, 0.00000, 0.00000, 1.00000};
//{-0.55442, 0.49393, 0.66981, 0.00000, -0.00000, 0.80483, -0.59350, 0.00000, -0.83223, -0.32905, -0.44622, 0.00000, 0.00000, 0.00000, 0.00000, 1.00000}
//{-0.99922, -0.03378, 0.02036, 0.00000, -0.00000, 0.51632, 0.85640, 0.00000, -0.03944, 0.85573, -0.51592, 0.00000, 0.00000, 0.00000, 0.00000, 1.00000}
//{0.79427, -0.54766, 0.26306, 0.00000, -0.00000, 0.43297, 0.90141, 0.00000, -0.60756, -0.71596, 0.34390, 0.00000, 0.00000, 0.00000, 0.00000, 1.00000}

#endif

#define CLIP_WIDTH    6
#define CLIP_Z_NEAR   0
#define CLIP_Z_FAR    65536

#define REFERENCE_VIEWPORT_WIDTH    375
#define REFERENCE_VIEWPORT_HEIGHT   667

class GLCamera {
    friend class PanoCameraController;
    
public:
    
    virtual ~GLCamera();
    
    GLCamera();
    
    static void getProjectionMatrix(kmMat4* projectionMatrix, float zNear, float zFar, float fovDegreeX, float aspectRatio, float zEye, float cutRadius);
    
    void getProjectionMatrix(kmMat4* projectionMatrix);
    void getStereoGraphicProjectionMatrix(kmMat4* projectionMatrix);
    void getLittlePlanetProjectionMatrix(kmMat4* projectionMatrix);
    
    inline void setProjectionFrustum(GLint width, GLint height, GLint zNear, GLint zFar) {
        _width = width;
        _height = height;
        _near = zNear;
        _far = zFar;
    }
    
    inline GLint getWidth() {return _width;}
    inline void setWidth(GLint width) {_width = width;}
    
    inline GLint getHeight() {return _height;}
    inline void setHeight(GLint height) {_height = height;}
    
    inline GLfloat getZNear() {return _near;}
    inline void setZNear(GLfloat zNear) {_near = zNear;}
    
    inline GLfloat getZFar() {return _far;}
    inline void setZFar(GLfloat zFar) {_far = zFar;}
    
    inline GLint getFOVDegree() {return _fovDegree;}
    inline void setFOVDegree(GLint fovDegree) {_fovDegree = fovDegree;}
    
    void getViewMatrix(kmMat4* viewMatrix);
    
    void setCameraPostRotation(const kmQuaternion* cameraPostRotationQuaternion);
    void setCameraPostRotationMatrix(const kmMat4* cameraPostRotation);
    
    void setCameraPreRotation(const kmQuaternion* cameraPreRotationQuaternion);
    void setCameraPreRotationMatrix(const kmMat4* cameraPreRotation);
    
    void setCameraRotation(const kmQuaternion* cameraRotationQuaternion, bool isInversed);
    void setCameraRotationMatrix(const kmMat4* cameraRotation, bool isInversed);
    
    void setModelPreRotation(const kmQuaternion* modelPreRotationQuaternion);
    void setModelPreRotationMatrix(const kmMat4* modelPreRotation);
    
    void setModelPostRotation(const kmVec3* fromVector, const kmVec3* toVector);
    
    void setGyroMatrix(float* matrix, int rank);
    
    void setModelRotation(const kmQuaternion* modelRotationQuaternion);
    void setModelRotationMatrix(const kmMat4* modelRotation);
    
    static void normalizeRotationMatrix(kmMat4* rotationMat);
    
    static bool checkVector(const kmVec3* vec);
    
    static bool checkRotationMatrix(const kmMat4* matrix, bool completeCheck, const char* tag);
    
    static bool checkQuaternion(const kmQuaternion* quaternion);
    
    static void normalizeQuaternion(kmQuaternion* quaternion);
    
    static kmVec3 rotationMatrixToEulerAngles(kmMat3* mat3);
    static kmVec3 rotationMatrixToEulerAngles(kmMat4* mat4);
    
    kmVec4 _debugGetPolarAxis();
    kmVec4 _debugGetNorthPolar();
    kmVec4 _debugGetSouthPolar();
    kmMat4 _debugGetCameraRotation();
    
protected:
    
    //    void calculateCameraMatrix(kmMat4* outCameraMatrix);
    //    Vec2f calculateModelMatrix(kmMat4* outModelMatrix, kmMat4* outYawMatrix, kmMat4* outPitchMatrix, const kmMat4* projectionMatrix);
    
private:
    
    void calculateDebugAxes();
    
    kmMat4 _cameraPreRotationMatrix;
    kmMat4 _cameraPostRotationMatrix;
    kmMat4 _cameraRotationMatrix;
    
    kmMat4 _modelPreRotationMatrix;
    kmMat4 _modelRotationMatrix;
    
    kmVec3 _modelPostRotationFromVector;
    kmVec3 _modelPostRotationToVector;
    
    float _gyroMatrix[16];
    int _gyroMatrixRank = 0;
    
    GLint _width;
    GLint _height;
    GLint _near;
    GLint _far;
    GLint _fovDegree;
};

typedef AutoRef<GLCamera> GLCameraRef;

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
// F1: setModelPreRotation
// F2: setCameraRotationEndState, commitCameraRotation
// F1.2, F1.2.4|8: rotateModelByDragging, setDraggingEndState, commitDragging
// F1.2.2|3|6|7: adustAxis
// F3: resetViewPosition
#endif /* GLCamera_hpp */
