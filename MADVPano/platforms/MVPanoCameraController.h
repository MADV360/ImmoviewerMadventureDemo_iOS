//
//  MVPanoCameraController.h
//  Madv360_v1
//
//  Created by DOM QIU on 2017/8/27.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#ifndef MVPanoCameraController_h
#define MVPanoCameraController_h

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "kazmath.h"

//@class MVPanoRenderer;

@interface MVPanoCameraController : NSObject

/** 继承自父类的构造函数 */
- (instancetype) initWithPanoRenderer:(id)panoRenderer;

/** 手机陀螺仪控制，在CMMotionMonitor的startDeviceMotionUpdatesToQueue:withHandler:方法回调block中调用
 * @param cmAttitude 由CMMotionMonitor给出的姿态对象
 * @param orientation 全景View所在UIViewController当前的朝向，由willRotateToInterfaceOrientation:回调方法得到
 * @param startOrientation 刚开启MotionMonitor时，全景View所在UIViewController的朝向，由willRotateToInterfaceOrientation:回调方法得到
 */
- (void) setGyroRotationQuaternion:(CMAttitude*)cmAttitude orientation:(UIInterfaceOrientation)orientation startOrientation:(UIInterfaceOrientation)startOrientation;

/** 设置全景View的当前朝向（目前的操控方式下可以不调用，只需在调用#setGyroRotationQuaternion#方法时传即可）
 * @param orientation 全景View所在UIViewController当前的朝向，由willRotateToInterfaceOrientation:回调方法得到
 */
- (void) setUIOrientation:(UIInterfaceOrientation)orientation;

/** 开始屏幕拖动。应在UIPanGestureRecognizer发生UIGestureRecognizerStateBegan事件时调用
 * @param pointInView 触摸点在全景View中的位置，通过UIPanGestureRecognizer对象的locationInView:方法获得
 * @param viewSize 全景View的大小
 */
- (void) startDragging:(CGPoint)pointInView viewSize:(CGSize)viewSize;

/** 屏幕拖动中。应在UIPanGestureRecognizer发生UIGestureRecognizerStateChanged事件时调用
 * @param pointInView 触摸点在全景View中的位置，通过UIPanGestureRecognizer对象的locationInView:方法获得
 * @param viewSize 全景View的大小
 */
- (void) dragTo:(CGPoint)pointInView viewSize:(CGSize)viewSize;

/** 结束屏幕拖动。应在UIPanGestureRecognizer发生UIGestureRecognizerStateEnded或UIGestureRecognizerStateCancelled事件时调用
 * @param velocityInView 滑动末速度，通过UIPanGestureRecognizer对象的velocityInView:方法获得
 * @param viewSize 全景View的大小
 */
- (void) stopDraggingAndFling:(CGPoint)velocityInView viewSize:(CGSize)viewSize;

- (void) setEnablePitchDragging:(BOOL)enable;

- (void) lookAtYaw:(float)yaw pitch:(float)pitch bank:(float)bank;

- (void) update:(float)seconds;

- (void) setFOVDegree:(int)fovDegree;

- (void) resetViewPosition;

- (void) setGyroMatrix:(float*)matrix rank:(int)rank;

- (void) setModelPostRotationFrom:(kmVec3)fromVector to:(kmVec3)toVector;

-(void) setAsteroidMode:(BOOL)toSetOrUnset;

-(kmVec3) currentRotationEulerAngles;
+(void) setGlobalCurrentEulerAngles:(kmVec3)eulerAngles;
+(kmVec3) globalCurrentEulerAngles;

+(void) setGlobalFOVDegrees:(float)fov;

+(float) globalFOVDegrees;

+(kmVec3) globalCurrentEulerAnglesForU2VR;

@end

#endif /* MVPanoCameraController_h */
