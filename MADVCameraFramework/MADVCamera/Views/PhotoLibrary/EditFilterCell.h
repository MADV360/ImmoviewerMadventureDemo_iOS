//
//  EditFilterCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EditFilterCell;

@protocol EditFilterCellDelegate <NSObject>

- (void)editFilterCellClick:(EditFilterCell *)editFilterCell;

@end

@interface EditFilterCell : UICollectionViewCell
@property(nonatomic,weak)UIImageView * filterImageview;
@property(nonatomic,weak)UILabel * titleLabel;
@property(nonatomic,strong)NSIndexPath * indexPath;
@property(nonatomic,weak)id<EditFilterCellDelegate> delegate;
@end
