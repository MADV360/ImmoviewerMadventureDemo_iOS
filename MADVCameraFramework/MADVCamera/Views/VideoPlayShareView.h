//
//  VideoPlayShareView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/24.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MediaShareView.h"

@interface VideoPlayShareView : MediaShareView
@property(nonatomic,strong)NSArray * dataArr;
@property(nonatomic,strong)NSArray * selectDataArr;
@property(nonatomic,strong)NSArray * nameDataArr;
@property(nonatomic,strong)NSArray * indexArr;
- (void)loadVideoPlayShareView;
- (void)show;
- (void)refresh;
@end
