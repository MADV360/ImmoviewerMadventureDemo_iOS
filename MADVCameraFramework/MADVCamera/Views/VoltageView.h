//
//  VoltageView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/12/22.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VoltageView : UIView
@property(nonatomic,strong)NSArray * dataSource;
- (void)loadVoltageView;
- (void)refresh;
@end
