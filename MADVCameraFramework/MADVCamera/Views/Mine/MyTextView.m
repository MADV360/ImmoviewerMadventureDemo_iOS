//
//  MyTextView.m
//  MoonBox
//
//  Created by jch_wen on 16/4/11.
//  Copyright © 2016年 LXWT. All rights reserved.
//

#import "MyTextView.h"
#import "UIView+Frame.h"
#import "Masonry.h"
@interface MyTextView()
@property (nonatomic, weak) UILabel *placeholderLabel;
@end


@implementation MyTextView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
        [self setTintColor:[UIColor blueColor]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
        [self setTintColor:[UIColor blueColor]];
    }
    return self;
}

- (void)setup
{
    // 1.创建UILabel
   
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)textChange
{
    self.placeholderLabel.hidden = (self.text.length > 0);
    if (self.text==nil) {
        self.placeholderLabel.hidden=NO; 
    }
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;
    UILabel *label = [[UILabel alloc] init];
//    label.text = FGGetStringWithKeyFromTable(INPUTFUNCONTENT, nil);
    label.textColor = [UIColor colorWithHexString:@"#C7C7CD"];
    label.font = self.font;
    label.x = 5;
    label.y = 3;
    //[label sizeToFit];
    if (self.viewWidth == 0) {
        label.frame=CGRectMake(5, 10, ScreenWidth-85, 130);
    }else
    {
        label.frame=CGRectMake(5, 10, self.viewWidth-20, 130);
    }
    
    
    label.numberOfLines=0;
    self.placeholderLabel = label;
    [self addSubview:label];
    
    // 2.监听自己有没有输入内容, 监听自己内容的变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChange) name:UITextViewTextDidChangeNotification object:nil];
   //label.attributedText = [[NSMutableAttributedString alloc] initWithString:_placeholder] ;
    label.text = _placeholder;
    // 每次设置完提示文本 , 应该重新计算frame
   [label sizeToFit];
    NSLog(@"%f",label.width);
    
}

//- (void)setFont:(UIFont *)font
//{
//    [super setFont:font];
//    
//    // 重新设置提示文本的字体大小
//    self.placeholderLabel.font = font;
//    [self.placeholderLabel sizeToFit];
//}





@end
