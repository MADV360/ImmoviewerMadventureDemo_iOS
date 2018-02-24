//
//  LocalSelImportView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/28.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LocalSelImportView;

@protocol LocalSelImportViewDelegate <NSObject>

- (void)localSelImportViewDidClick:(LocalSelImportView *)localSelImportView index:(NSInteger)index;

@end

@interface LocalSelImportView : UIView
@property(nonatomic,weak)id<LocalSelImportViewDelegate> delegate;
@property(nonatomic,strong)NSArray * titleArr;
- (void)loadLocalSelImportView;
- (void)show;
- (void)disMiss;
@end
