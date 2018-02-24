//
//  SetWifiView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/22.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SetWifiView;
@protocol SetWifiViewDelegate <NSObject>

- (void)setWifiViewDidSet:(SetWifiView *)setWifiView wifiName:(NSString *)wifiName password:(NSString *)password;

@end

@interface SetWifiView : UIView
@property(nonatomic,copy)NSString * ssid;
@property(nonatomic,weak)id<SetWifiViewDelegate> delegate;

- (void)loadSetWifiView;

@end
