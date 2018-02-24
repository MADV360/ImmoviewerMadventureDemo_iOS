//
//  PublishDescCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/23.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyTextView.h"
#import "TagScroView.h"

@interface PublishDescCell : UITableViewCell
@property(nonatomic,weak)MyTextView * descrTextView;
@property(nonatomic,weak)TagScroView * tagView;
@end
