//
//  ConnectFailView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/23.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ConnectFailView;
@protocol ConnectFailViewDelegate <NSObject>

- (void)connectFailView:(ConnectFailView *)connectFailView;

- (void)connectFailViewForgetPwd:(ConnectFailView *)connectFailView;
@end

@interface ConnectFailView : UIView
@property(nonatomic,weak)id<ConnectFailViewDelegate> delegate;
@property(nonatomic,copy)NSString * ssid;
- (void)loadConnectFailView;
@end
