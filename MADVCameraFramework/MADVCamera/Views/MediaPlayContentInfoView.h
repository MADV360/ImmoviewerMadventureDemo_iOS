//
//  MediaPlayContentInfo.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/8/28.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MVCloudMedia.h"
@class MediaPlayContentInfoView;

@protocol MediaPlayContentInfoViewDelegate <NSObject>

- (void)mediaPlayContentInfoViewClose:(MediaPlayContentInfoView *)mediaPlayContentInfoView;

@end

@interface MediaPlayContentInfoView : UIView
@property(nonatomic,weak)id<MediaPlayContentInfoViewDelegate> delegate;
@property(nonatomic,assign)BOOL isPortrait;
@property(nonatomic,strong)MVCloudMedia * cloudMedia;
@property(nonatomic,strong)NSArray * sourceArr;
@property(nonatomic,assign)BOOL isLocal;
- (void)loadMediaPlayContentInfoView;
@end
