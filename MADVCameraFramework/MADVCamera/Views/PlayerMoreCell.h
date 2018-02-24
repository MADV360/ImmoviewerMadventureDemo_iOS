//
//  PlayerMoreCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerMoreModel.h"
@class PlayerMoreCell;
@protocol PlayerMoreCellDelegate <NSObject>

- (void)playerMoreCell:(PlayerMoreCell *)playerMoreCell switchOn:(BOOL)on;

@end

@interface PlayerMoreCell : UITableViewCell
@property(nonatomic,weak)id<PlayerMoreCellDelegate> delegate;
@property(nonatomic,strong)PlayerMoreModel * playerMoreModel;

@end
