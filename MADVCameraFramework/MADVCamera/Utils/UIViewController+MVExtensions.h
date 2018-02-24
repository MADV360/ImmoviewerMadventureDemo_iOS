//
//  UIViewController+MVExtensions.h
//  Madv360_v1
//
//  Created by FutureBoy on 11/23/15.
//  Copyright © 2015 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (MVExtensions)

@property(nonatomic,copy)NSString * isScreencap;

/**Presnet as Popup Model View*/
+ (void)setPresentationStyleForSelfController:(UIViewController *)selfController presentingController:(UIViewController *)presentingController;

- (void)setPresentationStyle:(UIViewController *)presentingController;

- (UIViewController*) presentingViewControllerWithDegree:(int)degree;

- (void) saveTabBarHidden;
- (void) restoreTabBarHidden;

- (void) saveNaviBarAppearance;
- (void) restoreNaviBarAppearance;

- (void) saveNaviBarHidden;
- (void) restoreNaviBarHidden;

- (void) showActivityIndicatorView;

- (void) dismissActivityIndicatorView;

- (void) showToast:(NSString*)msg handler:(void (^ __nullable)(UIAlertAction *action))handler;
- (void) showToast:(NSString*)msg;

@end
