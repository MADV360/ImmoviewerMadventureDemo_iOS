//
//  cycleView.h
//  cycleView
//
//  Created by 张巧隔 on 16/12/5.
//  Copyright © 2016年 张巧隔. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CycleView : UIView
@property(nonatomic,assign)BOOL isRateShow;
@property(nonatomic,strong)UIColor * rightColor;
@property(nonatomic,strong)UIColor * leftColor;
@property(nonatomic,strong)UIColor * textColor;
@property(nonatomic,strong)UIFont * textFont;
@property(nonatomic,assign)float percent;
@property(nonatomic,assign)CGFloat width;
- (void)loadCycleView;
@end
