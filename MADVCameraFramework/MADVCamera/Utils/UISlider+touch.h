//
//  UISlider+touch.h
//  不固定UISlider
//
//  Created by 张巧隔 on 16/8/25.
//  Copyright © 2016年 张巧隔. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UISlider (touch)
// 单击手势
- (void)addTapGestureWithTarget: (id)target
                         action: (SEL)action;
@end
