//
//  SetWifiSucView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/22.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SetWifiSucView;
@protocol SetWifiSucViewDelegate <NSObject>

- (void)setWifiSucView:(SetWifiSucView *)setWifiSucView;

@end

@interface SetWifiSucView : UIView
@property(nonatomic,copy)NSString * ssid;
@property(nonatomic,weak)id<SetWifiSucViewDelegate> delegate;
- (void)loadSetWifiSucView;
@end
