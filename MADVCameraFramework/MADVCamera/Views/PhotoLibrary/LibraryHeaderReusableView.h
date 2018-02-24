//
//  LibraryHeaderReusableView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/7/19.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LibraryHeaderReusableView;
@protocol LibraryHeaderReusableViewDelegate <NSObject>

- (void)selectClick:(LibraryHeaderReusableView *) headerView;

@end

@interface LibraryHeaderReusableView : UICollectionReusableView
@property(nonatomic,weak)UILabel * dateLabel;
@property(nonatomic,weak)UIButton * selectBtn;
@property(nonatomic,strong)NSIndexPath * indexPath;
@property(nonatomic,weak)id<LibraryHeaderReusableViewDelegate> delegate;
@end
