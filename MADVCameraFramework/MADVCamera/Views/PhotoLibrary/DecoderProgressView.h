//
//  DecoderProgressView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/8.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DecoderProgressView;
@protocol DecoderProgressViewDelegate <NSObject>

- (void)decoderProgressViewClick:(DecoderProgressView *)decoderProgressView selectTag:(NSInteger)tag;

@end

@interface DecoderProgressView : UIView
@property(nonatomic,weak)id<DecoderProgressViewDelegate> delegate;
@property(nonatomic,weak)UILabel * fileSizeLabel4;
@property(nonatomic,weak)UILabel * fileSizeLabel1080;
- (void)loadDecoderProgressView;
@end
