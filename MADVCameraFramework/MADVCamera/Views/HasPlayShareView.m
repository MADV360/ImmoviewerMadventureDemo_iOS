//
//  MediaShareView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/7/7.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "HasPlayShareView.h"
#import "Masonry.h"

@interface HasPlayShareView ()
@property (weak, nonatomic) IBOutlet UIButton *wechatBtn;

@property (weak, nonatomic) IBOutlet UIButton *wechatFriendBtn;

@property (weak, nonatomic) IBOutlet UIButton *sinaBtn;
@property (weak, nonatomic) IBOutlet UIButton *qqBtn;
@property (weak, nonatomic) IBOutlet UIButton *linkBtn;
@property (weak, nonatomic) IBOutlet UIButton *facebookBtn;

@end

@implementation HasPlayShareView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)awakeFromNib
{
    [super awakeFromNib];
    UIImageView * closeImageView = [[UIImageView alloc] init];
    [self addSubview:closeImageView];
    [closeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@-30);
        make.top.equalTo(@30);
        make.width.equalTo(@20);
        make.height.equalTo(@20);
    }];
    closeImageView.image = [UIImage imageNamed:@"cancel.png"];
}
- (void)show
{
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    } completion:^(BOOL finished) {
        
    }];
}
- (IBAction)shareClick:(id)sender {
    UIButton * btn=(UIButton *)sender;
//    btn.selected=YES;
    if ([self.delegate respondsToSelector:@selector(mediaShareViewDidClick:andIndex:)]) {
        [self.delegate mediaShareViewDidClick:self andIndex:btn.tag];
    }
    if ([self.delegate respondsToSelector:@selector(mediaShareViewQuit:)]) {
        [self.delegate mediaShareViewQuit:self];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
}
- (IBAction)closeClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(mediaShareViewQuit:)]) {
        [self.delegate mediaShareViewQuit:self];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self.delegate respondsToSelector:@selector(mediaShareViewQuit:)]) {
        [self.delegate mediaShareViewQuit:self];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
}


@end
