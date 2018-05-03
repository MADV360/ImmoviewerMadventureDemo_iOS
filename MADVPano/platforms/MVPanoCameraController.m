//
//  MVPanoCameraController.m
//  Madv360_v1
//
//  Created by DOM QIU on 2017/8/27.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "MVPanoCameraController.h"
#import "PanoCameraController_iOS.h"

@interface MVPanoCameraController ()
{
    PanoCameraController_iOS* _impl;
}
@end

static kmVec3 g_globalCurrentEulerAngles = {0.f, 0.f, 0.f};
static float g_fov = 90.f;

@implementation MVPanoCameraController

- (void) dealloc {
    delete _impl;
}

- (instancetype) initWithPanoRenderer:(id)panoRenderer {
    if (self = [super init])
    {
        SEL internalInstanceSelector = NSSelectorFromString(@"internalInstance");
        IMP internalInstanceImp = [panoRenderer methodForSelector:internalInstanceSelector];
        void*(*panoRendererFunc)(id, SEL) = (void* (*)(id,SEL)) internalInstanceImp;
        AutoRef<MadvGLRenderer>* refImplPtr = (AutoRef<MadvGLRenderer>*) panoRendererFunc(panoRenderer, internalInstanceSelector);
        AutoRef<MadvGLRenderer> rendererImplRef = *refImplPtr; //*((AutoRef<MadvGLRenderer> *) panoRenderer.internalInstance);
        _impl = new PanoCameraController_iOS(rendererImplRef);
    }
    return self;
}

- (void) setGyroRotationQuaternion:(CMAttitude*)cmAttitude orientation:(UIInterfaceOrientation)orientation startOrientation:(UIInterfaceOrientation)startOrientation {
    if (!_impl)
        return;
    
    _impl->setGyroRotationQuaternion(cmAttitude, orientation, startOrientation);
}

- (void) setUIOrientation:(UIInterfaceOrientation)orientation {
    if (!_impl)
        return;
    
    _impl->setUIOrientation(orientation);
}

- (void) startDragging:(CGPoint)pointInView viewSize:(CGSize)viewSize {
    if (!_impl)
        return;
    
    _impl->startDragging(pointInView, viewSize);
}

- (void) dragTo:(CGPoint)pointInView viewSize:(CGSize)viewSize {
    if (!_impl)
        return;
    
    _impl->dragTo(pointInView, viewSize);
}

- (void) stopDraggingAndFling:(CGPoint)velocityInView viewSize:(CGSize)viewSize {
    if (!_impl)
        return;
    
    _impl->stopDraggingAndFling(velocityInView, viewSize);
}

- (void) setEnablePitchDragging:(BOOL)enable {
    if (!_impl)
        return;
    
    _impl->setEnablePitchDragging(enable);
}

- (void) lookAtYaw:(float)yaw pitch:(float)pitch bank:(float)bank {
    if (!_impl)
        return;
    
    _impl->lookAt(yaw, pitch, bank);
}

- (void) update:(float)seconds {
    if (!_impl)
        return;
    
    _impl->update(seconds);
}

- (void) setFOVDegree:(int)fovDegree {
    if (!_impl)
        return;
    
    _impl->setFOVDegree(fovDegree);
}

- (void) resetViewPosition {
    if (!_impl)
        return;
    
    _impl->resetViewPosition();
}

- (void) setGyroMatrix:(float*)matrix rank:(int)rank {
    if (!_impl)
        return;
    
    _impl->setGyroMatrix(matrix, rank);
}

-(void) setAsteroidMode:(BOOL)toSetOrUnset {
    if (!_impl)
        return;
    
    _impl->setAsteroidMode(toSetOrUnset);
}

- (void) setModelPostRotationFrom:(kmVec3)fromVector to:(kmVec3)toVector {
    if (!_impl)
        return;
    
    _impl->setModelPostRotation(fromVector, toVector);
}

-(kmVec3) currentRotationEulerAngles {
    if (!_impl)
        return {0.f, 0.f, 0.f};
    
    return _impl->getEulerAnglesFromViewMatrix();
}

+(void) setGlobalCurrentEulerAngles:(kmVec3)eulerAngles {
    g_globalCurrentEulerAngles = eulerAngles;
}

+(kmVec3) globalCurrentEulerAngles {
    return g_globalCurrentEulerAngles;
}

+(void) setGlobalFOVDegrees:(float)fov {
    g_fov = fov;
}

+(float) globalFOVDegrees {
    return g_fov;
}

+(kmVec3) globalCurrentEulerAnglesForU2VR {
    float pan = 180.f - 180.f * g_globalCurrentEulerAngles.x / M_PI;
    if (pan > 360.f)
        pan -= 360.f;
    else if (pan < 0.f)
        pan += 360.f;
    
    float tilt = 180.f * g_globalCurrentEulerAngles.y / M_PI;
    NSLog(@"#ViewAngles# globalCurrentEulerAnglesForU2VR(pan, tilt, fov) = (%f, %f, %f)", pan, tilt, g_fov);
    return kmVec3{pan, tilt, g_fov};
}

@end

