//
//  EditFilterView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EditFilterView;
@protocol EditFilterViewDelegate <NSObject>

- (void)editFilterView:(EditFilterView *)editFilterView index:(NSInteger)index;

@end

@interface EditFilterView : UIView
@property(nonatomic,strong)NSArray * imageArr;
@property(nonatomic,strong)NSArray * titleArr;
@property(nonatomic,assign)BOOL isPhoto;
@property(nonatomic,weak)id<EditFilterViewDelegate> delegate;
- (void)loadEditFilterViewl;
@end
