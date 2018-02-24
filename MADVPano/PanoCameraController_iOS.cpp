//
//  PanoCameraController_iOS.cpp
//  Madv360_v1
//
//  Created by DOM QIU on 2017/6/21.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#ifdef TARGET_OS_IOS

#import "PanoCameraController_iOS.h"

Orientation2D orientation2DFromUIInterfaceOrientation(UIInterfaceOrientation orientation, UIInterfaceOrientation startOrientation) {
//    switch (startOrientation)
//    {
//        case UIInterfaceOrientationPortrait:
//        {
            switch (orientation) {
                case UIInterfaceOrientationPortrait:
                case UIInterfaceOrientationUnknown:
                    return OrientationNormal;
                case UIInterfaceOrientationPortraitUpsideDown:
                    return OrientationRotate180DegreeMirror;
                case UIInterfaceOrientationLandscapeLeft:
                    return OrientationRotateRight;
                case UIInterfaceOrientationLandscapeRight:
                    return OrientationRotateLeft;
                default:
                    return OrientationNormal;
            }
//        }
//            break;
//        case UIInterfaceOrientationLandscapeLeft:
//        {
//            switch (orientation) {
//                case UIInterfaceOrientationLandscapeLeft:
//                case UIInterfaceOrientationUnknown:
//                    return OrientationNormal;
//                case UIInterfaceOrientationPortraitUpsideDown:
//                    return OrientationRotateRight;
//                case UIInterfaceOrientationPortrait:
//                    return OrientationRotateLeft;
//                case UIInterfaceOrientationLandscapeRight:
//                    return OrientationRotate180DegreeMirror;
//                default:
//                    return OrientationNormal;
//            }
//        }
//            break;
//        case UIInterfaceOrientationLandscapeRight:
//        {
//            switch (orientation) {
//                case UIInterfaceOrientationLandscapeRight:
//                case UIInterfaceOrientationUnknown:
//                    return OrientationNormal;
//                case UIInterfaceOrientationPortraitUpsideDown:
//                    return OrientationRotateLeft;
//                case UIInterfaceOrientationPortrait:
//                    return OrientationRotateRight;
//                case UIInterfaceOrientationLandscapeLeft:
//                    return OrientationRotate180DegreeMirror;
//                default:
//                    return OrientationNormal;
//            }
//        }
//            break;
//        case UIInterfaceOrientationPortraitUpsideDown:
//        {
//            switch (orientation) {
//                case UIInterfaceOrientationPortraitUpsideDown:
//                case UIInterfaceOrientationUnknown:
//                    return OrientationNormal;
//                case UIInterfaceOrientationLandscapeRight:
//                    return OrientationRotateRight;
//                case UIInterfaceOrientationLandscapeLeft:
//                    return OrientationRotateLeft;
//                case UIInterfaceOrientationPortrait:
//                    return OrientationRotate180DegreeMirror;
//                default:
//                    return OrientationNormal;
//            }
//        }
//            break;
//        default:
//            return OrientationNormal;
//            break;
//    }
}

PanoCameraController_iOS::PanoCameraController_iOS(AutoRef<GLCamera> panoCamera)
: PanoCameraController(panoCamera)
, _startOrientation(UIInterfaceOrientationPortrait)
{
    
}

PanoCameraController_iOS::PanoCameraController_iOS(AutoRef<MadvGLRenderer> panoRenderer)
: PanoCameraController(NULL != panoRenderer ? panoRenderer->glCamera() : NULL)
, _startOrientation(UIInterfaceOrientationPortrait)
{

}

void PanoCameraController_iOS::setGyroRotationQuaternion(CMAttitude* cmAttitude, UIInterfaceOrientation orientation, UIInterfaceOrientation startOrientation) {
    _startOrientation = startOrientation;
    kmQuaternion quaternion = {(float)cmAttitude.quaternion.x, (float)cmAttitude.quaternion.y, (float)cmAttitude.quaternion.z, (float)cmAttitude.quaternion.w};
    
    kmMat4 gyroMatrix;
    kmMat4RotationQuaternion(&gyroMatrix, &quaternion);
    //ALOGE("setGyroRotationQuaternion: orientation = %d", (int)orientation);
//*
    kmMat4Inverse(&gyroMatrix, &gyroMatrix);
    kmMat4 T;
    switch (startOrientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
        {
            //float data[] = {0.f,1.f,0.f,0.f, 0.f,0.f,1.f,0.f, 1.f,0.f,0.f,0.f, 0.f,0.f,0.f,1.f};
            float data[] = {0.f,0.f,1.f,0.f, 1.f,0.f,0.f,0.f, 0.f,1.f,0.f,0.f, 0.f,0.f,0.f,1.f};
            kmMat4Fill(&T, data);
        }
            break;
        case UIInterfaceOrientationLandscapeRight:
        {
            //float data[] = {0.f,-1.f,0.f,0.f, 0.f,0.f,1.f,0.f, -1.f,0.f,0.f,0.f, 0.f,0.f,0.f,1.f};
            float data[] = {0.f,0.f,-1.f,0.f, -1.f,0.f,0.f,0.f, 0.f,1.f,0.f,0.f, 0.f,0.f,0.f,1.f};
            kmMat4Fill(&T, data);
        }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            //float data[] = {-1.f,0.f,0.f,0.f, 0.f,0.f,1.f,0.f, 0.f,1.f,0.f,0.f, 0.f,0.f,0.f,1.f};
            float data[] = {-1.f,0.f,0.f,0.f, 0.f,0.f,1.f,0.f, 0.f,1.f,0.f,0.f, 0.f,0.f,0.f,1.f};
            kmMat4Fill(&T, data);
        }
            break;
        case UIInterfaceOrientationPortrait:
        default:
        {
            //float data[] = {1.f,0.f,0.f,0.f, 0.f,0.f,1.f,0.f, 0.f,-1.f,0.f,0.f, 0.f,0.f,0.f,1.f};
            float data[] = {1.f,0.f,0.f,0.f, 0.f,0.f,-1.f,0.f, 0.f,1.f,0.f,0.f, 0.f,0.f,0.f,1.f};
            kmMat4Fill(&T, data);
        }
            break;
    }
    //kmMat4Multiply(&gyroMatrix, &gyroMatrix, &T);
    kmMat4Multiply(&gyroMatrix, &T, &gyroMatrix);
    kmQuaternionRotationMatrix(&quaternion, &gyroMatrix);
/*/
    kmMat4 pitchMatrix;
    kmMat4RotationX(&pitchMatrix, M_PI/2);
    kmMat4Multiply(&gyroMatrix, &gyroMatrix, &pitchMatrix);
    kmQuaternionRotationMatrix(&quaternion, &gyroMatrix);
//*/
    setUIOrientation(orientation);
    PanoCameraController::setGyroRotationQuaternion(&quaternion, false);
}

void PanoCameraController_iOS::setUIOrientation(UIInterfaceOrientation orientation) {
    setScreenOrientation(orientation2DFromUIInterfaceOrientation(orientation, _startOrientation));
}

void PanoCameraController_iOS::startDragging(CGPoint pointInView, CGSize viewSize) {
    startTouchControl({(float)pointInView.x / (float)viewSize.width - 0.5f, 0.5f - (float)pointInView.y / (float)viewSize.height});
}

void PanoCameraController_iOS::dragTo(CGPoint pointInView, CGSize viewSize) {
    setDragPoint({(float)pointInView.x / (float)viewSize.width - 0.5f, 0.5f - (float)pointInView.y / (float)viewSize.height});
}

void PanoCameraController_iOS::stopDraggingAndFling(CGPoint velocityInView, CGSize viewSize) {
    stopTouchControl({(float)velocityInView.x / (float)viewSize.width - 0.5f, 0.5f - (float)velocityInView.y / (float)viewSize.height});
}

#endif //#ifdef TARGET_OS_IOS

