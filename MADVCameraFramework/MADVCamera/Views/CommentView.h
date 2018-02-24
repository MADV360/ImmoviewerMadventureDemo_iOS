//
//  CommentView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/20.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CommentView;
@protocol CommentViewDelegate <NSObject>

- (void)commentViewPublish:(CommentView *)commentView;
- (void)commentViewContentChange:(CommentView *)commentView;
- (void)commentViewClose:(CommentView *)commentView;
@end

@interface CommentView : UIView
@property(nonatomic,weak)id<CommentViewDelegate> delegate;
@property(nonatomic,weak)UITextView * contentTextView;
@property(nonatomic,weak)UILabel * numLabel;
- (void)loadCommentView;
@end
