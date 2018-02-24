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

@end

