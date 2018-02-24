//
//  MessageHeaderView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/11/11.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageDetail.h"

@class MessageHeaderView;

@protocol MessageHeaderViewDelegate <NSObject>

- (void)messageHeaderView:(MessageHeaderView *)messageHeaderView;

@end

@interface MessageHeaderView : UITableViewHeaderFooterView
@property(nonatomic,strong)MessageDetail * msgDetail;
@property(nonatomic,weak)id<MessageHeaderViewDelegate> delegate;
@end
