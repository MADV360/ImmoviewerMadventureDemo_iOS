//
//  OpenWifiView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/23.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OpenWifiView;
@protocol OpenWifiViewDelegate <NSObject>

- (void)openWifiView:(OpenWifiView *)openWifiView;

@end

@interface OpenWifiView : UIView
@property(nonatomic,weak)id<OpenWifiViewDelegate>delegate;

- (void)loadOpenWifiView;
@end
