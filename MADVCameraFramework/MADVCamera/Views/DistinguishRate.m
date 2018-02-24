//
//  DistinguishRate.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "DistinguishRate.h"
#import "Masonry.h"

@interface DistinguishRate()

@property (weak, nonatomic) IBOutlet UIButton *heightBtn;
@property (weak, nonatomic) IBOutlet UIButton *superBtn;
@property (weak, nonatomic) IBOutlet UIButton *fluentBtn;

@property (weak, nonatomic) IBOutlet UIButton *autoBtn;

@property(nonatomic,weak)UIButton * selectBtn;

@end

@implementation DistinguishRate

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
    [self.heightBtn setTitle:FGGetStringWithKeyFromTable(HIGHDEFINITION, nil) forState:UIControlStateNormal];
    [self.heightBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [self.heightBtn setTitleColor:[UIColor colorWithHexString:@"#0091DC"] forState:UIControlStateSelected];
    self.heightBtn.tag=5002;
    [self.heightBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.superBtn setTitle:FGGetStringWithKeyFromTable(SUPERDEFINITION, nil) forState:UIControlStateNormal];
    [self.superBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [self.superBtn setTitleColor:[UIColor colorWithHexString:@"#0091DC"] forState:UIControlStateSelected];
    self.superBtn.tag=5003;
    [self.superBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.fluentBtn setTitle:FGGetStringWithKeyFromTable(FLUENT, nil) forState:UIControlStateNormal];
    [self.fluentBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    self.fluentBtn.tag=5001;
    [self.fluentBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.autoBtn setTitle:FGGetStringWithKeyFromTable(AUTO, nil) forState:UIControlStateNormal];
    [self.autoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [self.autoBtn setTitleColor:[UIColor colorWithHexString:@"#0091DC"] forState:UIControlStateSelected];
    self.autoBtn.tag=5000;
    [self.autoBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
}


- (void)btnClick:(UIButton *)btn
{
    if (self.selectBtn!=btn) {

        [self.heightBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.heightBtn.layer.borderWidth=0;
        
        [self.superBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.superBtn.layer.borderWidth=0;
        
        self.fluentBtn.layer.borderWidth=0;
        [self.fluentBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        self.autoBtn.layer.borderWidth=0;
        [self.autoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        btn.layer.borderWidth=1;
        btn.layer.borderColor=[UIColor colorWithHexString:@"#0091DC"].CGColor;
        btn.layer.masksToBounds=YES;
        btn.layer.cornerRadius=15;
        btn.titleLabel.backgroundColor=[UIColor clearColor];
        [btn setTitleColor:[UIColor colorWithHexString:@"#0091DC"] forState:UIControlStateNormal];
        
        if ([self.delegate respondsToSelector:@selector(distinguishRate:rateType:)]) {
            [self.delegate distinguishRate:self rateType:btn.tag-5000];
        }
        if (self.selectBtn) {
            self.selectBtn=btn;
            [self quit];
        }else
        {
            self.selectBtn=btn;
        }
        
    }
}

- (void)selectRateType:(DistinguishRateType)type
{
    UIButton * btn=[self viewWithTag:(type+5000)];
    [self btnClick:btn];
}
- (void)disableUserInteractionType:(DistinguishRateType)type
{
    UIButton * btn=[self viewWithTag:(type+5000)];
    btn.userInteractionEnabled=NO;
    [btn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self quit];
    
}

- (void)quit
{
    if ([self.delegate respondsToSelector:@selector(distinguishRateQuit:)]) {
        [self.delegate distinguishRateQuit:self];
    }
    
    [UIView animateWithDuration:.3 animations:^{
        self.y=ScreenHeight;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
