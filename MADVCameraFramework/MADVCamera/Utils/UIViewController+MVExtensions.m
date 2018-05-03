//
//  UIViewController+MVExtensions.m
//  Madv360_v1
//
//  Created by FutureBoy on 11/23/15.
//  Copyright © 2015 Cyllenge. All rights reserved.
//

#import "UIViewController+MVExtensions.h"
#import <objc/runtime.h>
//#import "Masonry.h"

static const char* kKeyIndicatorView = "IndicatorView";
//static const char* kKeyTabBarHidden = "TabBarHidden";
//static const char* kKeyNaviBarHidden = "NaviBarHidden";
static const char* kKeyPrevTabBarHidden = "PrevTabBarHidden";
static const char* kKeyPrevNaviBarHidden = "PrevNaviBarHidden";
static const char* kKeyPrevNaviBarTitleTextAttributes = "PrevNaviBarTitleTextAttrib";
static const char* kKeyPrevNaviBarTintColor = "PrevNaviBarTintColor";
static const char* kKeyPrevNaviBarBarTintColor = "PrevNaviBarBarTintColor";

@implementation UIViewController (MVExtensions)
static char * screencap = "screencap";
- (void)setIsScreencap:(NSString *)isScreencap
{
    objc_setAssociatedObject(self, screencap, isScreencap, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)isScreencap
{
    return objc_getAssociatedObject(self, screencap);
}

+ (void)setPresentationStyleForSelfController:(UIViewController *)selfController presentingController:(UIViewController *)presentingController
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        presentingController.providesPresentationContextTransitionStyle = YES;
        presentingController.definesPresentationContext = YES;
        
        [presentingController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    }
    else
    {
        [selfController setModalPresentationStyle:UIModalPresentationCurrentContext];
        [selfController.navigationController setModalPresentationStyle:UIModalPresentationCurrentContext];
    }
}

- (void)setPresentationStyle:(UIViewController *)presentingController {
    [self.class setPresentationStyleForSelfController:self presentingController:presentingController];
}

- (UIViewController*) presentingViewControllerWithDegree:(int)degree {
    if (degree < 0) degree = INT_MAX;
    UIViewController* presentingVC = self;
    for (int d=0; d<degree; ++d)
    {
        if (presentingVC.presentingViewController)
        {
            presentingVC = presentingVC.presentingViewController;
        }
        else
        {
            return presentingVC;
        }
    }
    return presentingVC;
}

- (void) saveTabBarHidden {
    if (self.tabBarController && self.tabBarController.tabBar)
    {
        UITabBar* bar = self.tabBarController.tabBar;
        objc_setAssociatedObject(bar, kKeyPrevTabBarHidden, @(bar.hidden), OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

- (void) restoreTabBarHidden {
    if (self.tabBarController && self.tabBarController.tabBar)
    {
        UITabBar* bar = self.tabBarController.tabBar;
        id tabBarHidden = objc_getAssociatedObject(bar, kKeyPrevTabBarHidden);
        if (tabBarHidden)
        {
            bar.hidden = [tabBarHidden boolValue];
        }
    }
}

- (void) saveNaviBarAppearance {
    if (self.navigationController && self.navigationController.navigationBar)
    {
        UINavigationBar* bar = self.navigationController.navigationBar;
        objc_setAssociatedObject(bar, kKeyPrevNaviBarTintColor, bar.tintColor, OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(bar, kKeyPrevNaviBarBarTintColor, bar.barTintColor, OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(bar, kKeyPrevNaviBarTitleTextAttributes, bar.titleTextAttributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void) restoreNaviBarAppearance {
    if (self.navigationController && self.navigationController.navigationBar)
    {
        UINavigationBar* bar = self.navigationController.navigationBar;
        id tintColor = objc_getAssociatedObject(bar, kKeyPrevNaviBarTintColor);
        id barTintColor = objc_getAssociatedObject(bar, kKeyPrevNaviBarBarTintColor);
        id titleTextAttributes = objc_getAssociatedObject(bar, kKeyPrevNaviBarTitleTextAttributes);
        bar.tintColor = tintColor;
        bar.barTintColor = barTintColor;
        bar.titleTextAttributes = titleTextAttributes;
    }
}

- (void) saveNaviBarHidden {
    if (self.navigationController && self.navigationController.navigationBar)
    {
        UINavigationBar* bar = self.navigationController.navigationBar;
        objc_setAssociatedObject(bar, kKeyPrevNaviBarHidden, @(bar.hidden), OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

- (void) restoreNaviBarHidden {
    if (self.navigationController && self.navigationController.navigationBar)
    {
        UINavigationBar* bar = self.navigationController.navigationBar;
        id naviBarHidden = objc_getAssociatedObject(bar, kKeyPrevNaviBarHidden);
        if (naviBarHidden)
        {
            self.navigationController.navigationBar.hidden = [naviBarHidden boolValue];
        }
    }
}

- (void) showActivityIndicatorViewInView:(UIView *)view {
    if (view == nil) {
        view = self.view;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIActivityIndicatorView* indicatorView = nil;
        UIView* bgView = objc_getAssociatedObject(self, kKeyIndicatorView);
        NSLog(@"showActivityIndicatorView : %@, bgView = %@", self, bgView);
        if (!bgView)
        {
            bgView = [[UIView alloc] init];///!!!WithFrame:view.bounds];
            bgView.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.5];
            bgView.opaque = NO;
            bgView.userInteractionEnabled = YES;
            
            indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            indicatorView.center = CGPointMake(CGRectGetMidX(bgView.bounds), CGRectGetMidY(bgView.bounds));
            [bgView addSubview:indicatorView];
            bgView.translatesAutoresizingMaskIntoConstraints = NO;
            
            [view addSubview:bgView];
            if ([self.isScreencap isEqualToString:@"1"]) {
//                [view addConstraint:[NSLayoutConstraint constraintWithItem:bgView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
//                [view addConstraint:[NSLayoutConstraint constraintWithItem:bgView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f]];
//                [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
//                    make.centerX.equalTo(self.view.mas_centerX);
//                    make.top.equalTo(@(((ScreenWidth*9)/16)*0.5+64-9));
//                    //                make.height.equalTo(@18);
//                    //                make.width.equalTo(@18);
//                }];
                bgView.center = view.center;
            }else
            {
//                [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
//                    make.centerX.equalTo(self.view.mas_centerX);
//                    make.centerY.equalTo(self.view.mas_centerY);
//                    //                make.height.equalTo(@18);
//                    //                make.width.equalTo(@18);
//                }];
//                [view addConstraint:[NSLayoutConstraint constraintWithItem:bgView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
//                [view addConstraint:[NSLayoutConstraint constraintWithItem:bgView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f]];
                bgView.center = view.center;
            }
            
            
            objc_setAssociatedObject(self, kKeyIndicatorView, bgView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        else
        {
            indicatorView = [bgView subviews][0];
        }
        [view bringSubviewToFront:bgView];
        [indicatorView startAnimating];
    });
}

- (void) dismissActivityIndicatorView {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView* bgView = objc_getAssociatedObject(self, kKeyIndicatorView);
        NSLog(@"dismissActivityIndicatorView : %@, bgView = %@", self, bgView);
        if (bgView)
        {
            UIActivityIndicatorView* indicatorView = [bgView subviews][0];
            [indicatorView stopAnimating];
            [bgView removeFromSuperview];
            objc_setAssociatedObject(self, kKeyIndicatorView, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    });
}

- (void) showToast:(NSString*)msg handler:(void (^ __nullable)(UIAlertAction *action))handler {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController* ac = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:handler];
        [ac addAction:action];
        [self presentViewController:ac animated:NO completion:nil];
    });
}

- (void) showToast:(NSString *)msg {
    [self showToast:msg handler:nil];
}

@end
