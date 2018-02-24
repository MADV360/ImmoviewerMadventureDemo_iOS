//
//  MyTextView.h
//  MoonBox
//
//  Created by jch_wen on 16/4/11.
//  Copyright © 2016年 LXWT. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface MyTextView : UITextView

// 提示文本
@property (nonatomic, copy) NSString *placeholder;
@property(nonatomic,assign)CGFloat viewWidth;
- (void)textChange;
//// 返回需要发送的文本
//- (NSString *)fullTextStr;
@end
