//
//  PanoCameraController_iOS.hpp
//  Madv360_v1
//
//  Created by DOM QIU on 2017/6/21.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#ifdef TARGET_OS_IOS

#ifndef PanoCameraController_iOS_hpp
#define PanoCameraController_iOS_hpp

#import "PanoCameraController.h"
//#import "MadvGLRenderer_iOS.h"
#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

class PanoCameraController_iOS : public PanoCameraController {
public:
    /** 继承自父类的构造函数 */
    PanoCameraController_iOS(AutoRef<MadvGLRenderer> panoRenderer);
    
    PanoCameraController_iOS(AutoRef<GLCamera> panoCamera);
    
    /** 手机陀螺仪控制，在CMMotionMonitor的startDeviceMotionUpdatesToQueue:withHandler:方法回调block中调用
     * @param cmAttitude 由CMMotionMonitor给出的姿态对象
     * @param orientation 全景View所在UIViewController当前的朝向，由willRotateToInterfaceOrientation:回调方法得到
     * @param startOrientation 刚开启MotionMonitor时，全景View所在UIViewController的朝向，由willRotateToInterfaceOrientation:回调方法得到
     */
    void setGyroRotationQuaternion(CMAttitude* cmAttitude, UIInterfaceOrientation orientation, UIInterfaceOrientation startOrientation);
    
    /** 设置全景View的当前朝向（目前的操控方式下可以不调用，只需在调用#setGyroRotationQuaternion#方法时传即可）
     * @param orientation 全景View所在UIViewController当前的朝向，由willRotateToInterfaceOrientation:回调方法得到
     */
    void setUIOrientation(UIInterfaceOrientation orientation);
    
    /** 开始屏幕拖动。应在UIPanGestureRecognizer发生UIGestureRecognizerStateBegan事件时调用
     * @param pointInView 触摸点在全景View中的位置，通过UIPanGestureRecognizer对象的locationInView:方法获得
     * @param viewSize 全景View的大小
     */
    void startDragging(CGPoint pointInView, CGSize viewSize);
    
    /** 屏幕拖动中。应在UIPanGestureRecognizer发生UIGestureRecognizerStateChanged事件时调用
     * @param pointInView 触摸点在全景View中的位置，通过UIPanGestureRecognizer对象的locationInView:方法获得
     * @param viewSize 全景View的大小
     */
    void dragTo(CGPoint pointInView, CGSize viewSize);
    
    /** 结束屏幕拖动。应在UIPanGestureRecognizer发生UIGestureRecognizerStateEnded或UIGestureRecognizerStateCancelled事件时调用
     * @param velocityInView 滑动末速度，通过UIPanGestureRecognizer对象的velocityInView:方法获得
     * @param viewSize 全景View的大小
     */
    void stopDraggingAndFling(CGPoint velocityInView, CGSize viewSize);
    
private:
    
    UIInterfaceOrientation _startOrientation;
};

#endif /* PanoCameraController_iOS_hpp */

#endif // #ifdef TARGET_OS_IOS
