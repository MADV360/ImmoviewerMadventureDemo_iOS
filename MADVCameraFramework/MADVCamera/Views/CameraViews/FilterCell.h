//
//  FilterCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/29.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageFilterBean.h"

@interface FilterCell : UICollectionViewCell
@property(nonatomic,strong)ImageFilterBean * imageFilter;
@property(nonatomic,assign)BOOL isSelect;
@end
