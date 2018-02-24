//
//  EditEyeCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EditEyeCell;

@protocol EditEyeCellDelegate <NSObject>

- (void)editEyeCellClick:(EditEyeCell *)editEyeCell;

@end

@interface EditEyeCell : UICollectionViewCell
@property(nonatomic,weak)id<EditEyeCellDelegate> delegate;
@property(nonatomic,strong)NSIndexPath * indexPath;
@property(nonatomic,weak)UIImageView * editImageView;
@property(nonatomic,weak)UILabel * titleLabel;
@property(nonatomic,weak)UIView * lineView;
@end
