//
//  UIPlaceholderTextView.h
//  Madv360_v1
//
//  Created by QiuDong on 16/5/6.
//  Reference: http://stackoverflow.com/questions/1328638/placeholder-in-uitextview
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface UIPlaceholderTextView : UITextView

@property (nonatomic, retain) IBInspectable NSString *placeholder;
@property (nonatomic, retain) IBInspectable UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end
