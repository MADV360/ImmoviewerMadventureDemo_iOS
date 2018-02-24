//
//  MesDetailCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/3/2.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SysMesDetail.h"

@class MesDetailCell;
@protocol MesDetailCellDelegate <NSObject>

- (void)mesDetailCellUpdate:(MesDetailCell *)mesDetailCell;

@end

@interface MesDetailCell : UITableViewCell
@property(nonatomic,weak)id<MesDetailCellDelegate> delegate;
@property(nonatomic,strong)SysMesDetail * sysMesDetail;

@end
