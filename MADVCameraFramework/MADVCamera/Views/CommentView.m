//
//  CommentView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/20.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "CommentView.h"
#import "Masonry.h"

@interface CommentView()<UITextViewDelegate>


@end
@implementation CommentView
- (void)loadCommentView
{
    UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] init];
    [tapGes addTarget:self action:@selector(tapGes:)];
    [self addGestureRecognizer:tapGes];
    UIView * bottomView = [[UIView alloc] init];
    [self addSubview:bottomView];
    [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
        make.height.equalTo(@190);
    }];
    bottomView.backgroundColor = [UIColor whiteColor];
    
    UITextView * contentTextView = [[UITextView alloc] init];
    [bottomView addSubview:contentTextView];
    [contentTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@0);
        make.left.equalTo(@15);
        make.right.equalTo(@-15);
        make.height.equalTo(@180);
    }];
    contentTextView.delegate = self;
    contentTextView.font = [UIFont systemFontOfSize:13];
    contentTextView.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
    self.contentTextView = contentTextView;
    
    UILabel * numLabel = [[UILabel alloc] init];
    [bottomView addSubview:numLabel];
    [numLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@-15);
        make.bottom.equalTo(@-10);
        make.height.equalTo(@15);
        make.width.equalTo(@50);
    }];
    numLabel.textAlignment = NSTextAlignmentRight;
    numLabel.font = [UIFont systemFontOfSize:12];
    numLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
    numLabel.text = @"140";
    self.numLabel = numLabel;
    
    UIView * lineView = [[UIView alloc] init];
    [self addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(bottomView.mas_top);
        make.height.equalTo(@1);
    }];
    lineView.backgroundColor = [UIColor colorWithRed:0.81f green:0.82f blue:0.81f alpha:1.00f];
    
    UIButton * topView = [[UIButton alloc] init];
    [self addSubview:topView];
    [topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(lineView.mas_top);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@55);
    }];
    topView.backgroundColor = [UIColor whiteColor];
    
    
    UIButton * backBtn = [[UIButton alloc] init];
    [topView addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@15);
        make.centerY.equalTo(topView.mas_centerY);
        make.width.equalTo(@50);
        make.height.equalTo(@30);
    }];
    [backBtn setImage:[UIImage imageNamed:@"com_back.png"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    backBtn.imageEdgeInsets = UIEdgeInsetsMake(0, -25, 0, 0);
    
    UILabel * commentLabel = [[UILabel alloc] init];
    [topView addSubview:commentLabel];
    [commentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(topView.mas_centerX);
        make.centerY.equalTo(topView.mas_centerY);
        make.width.equalTo(@50);
        make.height.equalTo(@16);
    }];
    commentLabel.textAlignment = NSTextAlignmentCenter;
    commentLabel.font = [UIFont systemFontOfSize:15];
    commentLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
    commentLabel.text = FGGetStringWithKeyFromTable(COMMENT, nil);
    
    UIButton * commentPublishBtn = [[UIButton alloc] init];
    [topView addSubview:commentPublishBtn];
    [commentPublishBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@-15);
        make.top.equalTo(@0);
        make.width.equalTo(@50);
        make.bottom.equalTo(@0);
    }];
    [commentPublishBtn setTitle:FGGetStringWithKeyFromTable(PUBLISH, nil) forState:UIControlStateNormal];
    [commentPublishBtn setTitleColor:[UIColor colorWithHexString:@"#46a4ea"] forState:UIControlStateNormal];
    [commentPublishBtn addTarget:self action:@selector(commentPublishBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    commentPublishBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    commentPublishBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -20);
    
    
    
}
#pragma mark --UITextViewDelegate代理方法的实现--
- (void)textViewDidChange:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(commentViewContentChange:)]) {
        [self.delegate commentViewContentChange:self];
    }
}

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView{     //其实你可以加在这个代理方法中。当你将要编辑的时候。先执行这个代理方法的时候就可以改变间距了。这样之后输入的内容也就有了行间距。
    
    if (textView.text.length < 1) {
        textView.text = @"间距";
    }
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    
    paragraphStyle.lineSpacing = 11;// 字体的行间距
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName:[UIFont systemFontOfSize:13],
                                 NSParagraphStyleAttributeName:paragraphStyle
                                 
                                 };
    
    textView.attributedText = [[NSAttributedString alloc] initWithString:textView.text attributes:attributes];
    if ([textView.text isEqualToString:@"间距"]) {           //之所以加这个判断是因为再次编辑的时候还会进入这个代理方法，如果不加，会把你之前输入的内容清空。你也可以取消看看效果。
        textView.attributedText = [[NSAttributedString alloc] initWithString:@"" attributes:attributes];//主要是把“间距”两个字给去了。
    }
    return YES;
}

- (void)tapGes:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(commentViewClose:)]) {
        [self.delegate commentViewClose:self];
    }
    [self.contentTextView resignFirstResponder];
    [self removeFromSuperview];
}
- (void)backBtnClick:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(commentViewClose:)]) {
        [self.delegate commentViewClose:self];
    }
    [self.contentTextView resignFirstResponder];
    [self removeFromSuperview];
}
- (void)commentPublishBtnClick:(UIButton *)btn
{
    NSLog(@"发布");
    if ([self.delegate respondsToSelector:@selector(commentViewPublish:)]) {
        [self.delegate commentViewPublish:self];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
