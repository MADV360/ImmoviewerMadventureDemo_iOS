//
//  CommentCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/20.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommentDetail.h"
@class CommentCell;
@protocol CommentCellDelegate <NSObject>

- (void)commentCellDeleteCom:(CommentCell *)commentCell;

@end
@interface CommentCell : UITableViewCell
@property(nonatomic,strong)NSIndexPath * indexPath;
@property(nonatomic,weak)id<CommentCellDelegate> delegate;
@property(nonatomic,weak)CommentDetail * commentDetail;
@end
