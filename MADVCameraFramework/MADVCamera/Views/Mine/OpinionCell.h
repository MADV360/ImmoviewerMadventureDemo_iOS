//
//  OpinionCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/7/4.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyTextView.h"

@interface OpinionCell : UITableViewCell
@property(nonatomic,copy)NSString * placeholder;
@property(nonatomic,weak)MyTextView * textView;
@property(nonatomic,weak)MyTextView * mailTextField;
- (void)hiddenKeyboard;
@end
