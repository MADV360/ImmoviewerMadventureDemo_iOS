//
//  cycleView.m
//  cycleView
//
//  Created by 张巧隔 on 16/12/5.
//  Copyright © 2016年 张巧隔. All rights reserved.
//

#import "CycleView.h"

@interface CycleView ()
@property(nonatomic,weak)UILabel * percentLabel;
@end

@implementation CycleView

- (void)loadCycleView
{
    UILabel * percentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    //设置里面字体的大小
    [percentLabel setFont:self.textFont];
    //设置里面字体的颜色
    [percentLabel setTextColor:self.textColor];
    percentLabel.textAlignment=NSTextAlignmentCenter;
    [percentLabel setBackgroundColor:[UIColor clearColor]];
    percentLabel.hidden=!self.isRateShow;
    [self addSubview:percentLabel];
    [self setNeedsDisplay];
    self.percentLabel = percentLabel;
}

- (void)drawRect:(CGRect)rect {
    [self drawLeft];
    [self drawRight];
    
}
- (void)drawRight
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();//获取上下文
    
    CGPoint center = CGPointMake(self.frame.size.width*0.5, self.frame.size.height*0.5);  //设置圆心位置
    CGFloat radius = self.frame.size.width*0.5-2;  //设置半径
    CGFloat startA = - M_PI_2;  //圆起点位置
    CGFloat endA = -M_PI_2 + M_PI * 2 * self.percent;  //圆终点位置
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startA endAngle:endA clockwise:YES];
    CGFloat width = 2;
    if (self.width) {
        width = self.width;
    }
    CGContextSetLineWidth(ctx, width); //设置线条宽度
    [self.rightColor setStroke]; //设置描边颜色
    
    CGContextAddPath(ctx, path.CGPath); //把路径添加到上下文
    
    CGContextStrokePath(ctx);  //渲染
}
- (void)drawLeft
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();//获取上下文
    
    CGPoint center = CGPointMake(self.frame.size.width*0.5, self.frame.size.height*0.5);  //设置圆心位置
    CGFloat radius = self.frame.size.width*0.5-2;  //设置半径
    CGFloat startA = - M_PI_2;  //圆起点位置
    CGFloat endA = -M_PI_2 + M_PI * 2;  //圆终点位置
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startA endAngle:endA clockwise:YES];
    CGFloat width = 2;
    if (self.width) {
        width = self.width;
    }
    CGContextSetLineWidth(ctx, width); //设置线条宽度
    [self.leftColor setStroke]; //设置描边颜色
    
    CGContextAddPath(ctx, path.CGPath); //把路径添加到上下文
    
    CGContextStrokePath(ctx);  //渲染
}
- (void)setPercent:(float)percent
{
    _percent = percent;
    self.percentLabel.text = [NSString stringWithFormat:@"%d%@",(int)(percent*100),@"%"];
    [self setNeedsDisplay];
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
