//
//  VideoExportView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/20.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum : NSInteger {
    Cancel = 0,
    Finish = 1,
    Retry = 2,
    EditFinish = 3,
    EditShare = 4,
} ClickType;

@class VideoExportView;
@protocol VideoExportViewDelegate <NSObject>

- (void)videoExportView:(VideoExportView *)videoExportView clickType:(ClickType)clicktype;

@end

@interface VideoExportView : UIView 
@property(nonatomic,weak)id<VideoExportViewDelegate> delegate;
@property(nonatomic,assign)BOOL isSuc;
@property(nonatomic,assign)BOOL isEdit;
@property(nonatomic,assign)BOOL isSystemShare;
@property(nonatomic,assign)BOOL isBatchExport;
@property(nonatomic,assign)int totalNum;
@property(nonatomic,assign)int finishNum;
@property(nonatomic,weak)UILabel * sumLabel;

- (void)loadVideoExportView;
- (void)setPercent:(int)percent animated:(BOOL)animated;
@end
