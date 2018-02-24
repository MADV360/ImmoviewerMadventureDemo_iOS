//
//  EditEyeView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EditEyeView;

@protocol EditEyeViewDelegate <NSObject>

- (void)editEyeViewClick:(EditEyeView *)editEyeView index:(NSInteger)index;

@end

@interface EditEyeView : UIView
@property(nonatomic,strong)NSArray * imageArr;
@property(nonatomic,strong)NSArray * titleArr;
@property(nonatomic,strong)NSArray * selectImageArr;
@property(nonatomic,assign)BOOL isPhoto;
@property(nonatomic,strong)NSIndexPath * selectIndexPath;
@property(nonatomic,weak)id<EditEyeViewDelegate> delegate;
- (void)loadEditEyeView;
- (void)refresh;
@end
