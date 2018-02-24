//
//  EditProgressView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditProgressView : UIView
@property(nonatomic,weak)UILabel * durationLabel;
@property(nonatomic,weak)UISlider * progressSlider;
- (void)loadEditProgressView;
@end
