

#import "KDGoalBarPercentLayer.h"
#import <UIKit/UIKit.h>

#define toRadians(x) ((x)*M_PI / 180.0)
#define toDegrees(x) ((x)*180.0 / M_PI)
//设置内环的半径
#define innerRadius    self.frame.size.width*0.5-3
//设置外环的半径
#define outerRadius    self.frame.size.width*0.5

@implementation KDGoalBarPercentLayer
@synthesize percent;

-(void)drawInContext:(CGContextRef)ctx {
    [self drawCentre:ctx];
    [self DrawRight:ctx];
    [self DrawLeft:ctx];
    
    
}
-(void)DrawRight:(CGContextRef)ctx {
    CGPoint center = CGPointMake(self.frame.size.width / (2), self.frame.size.height / (2));
    
    CGFloat delta = toRadians(360 * percent);

    //设置进度的颜色
    CGContextSetFillColorWithColor(ctx, self.rightColor.CGColor);
    
    CGContextSetLineWidth(ctx, 1);
    
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    CGContextSetAllowsAntialiasing(ctx, YES);
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathAddRelativeArc(path, NULL, center.x, center.y, innerRadius, -(M_PI / 2), delta);
    CGPathAddRelativeArc(path, NULL, center.x, center.y, outerRadius, delta - (M_PI / 2), -delta);
    CGPathAddLineToPoint(path, NULL, center.x, center.y-innerRadius);
    
    CGContextAddPath(ctx, path);
    CGContextFillPath(ctx);
    
    CFRelease(path);
}

-(void)DrawLeft:(CGContextRef)ctx {
    CGPoint center = CGPointMake(self.frame.size.width / (2), self.frame.size.height / (2));
    
    CGFloat delta = -toRadians(360 * (1-percent));

    //设置不是进度的颜色
    CGContextSetFillColorWithColor(ctx, self.leftColor.CGColor);
    
    CGContextSetLineWidth(ctx, 1);
    
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    CGContextSetAllowsAntialiasing(ctx, YES);
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathAddRelativeArc(path, NULL, center.x, center.y, innerRadius, -(M_PI / 2), delta);
    CGPathAddRelativeArc(path, NULL, center.x, center.y, outerRadius, delta - (M_PI / 2), -delta);
    CGPathAddLineToPoint(path, NULL, center.x, center.y-innerRadius);
    
    CGContextAddPath(ctx, path);
    CGContextFillPath(ctx);
    
    CFRelease(path);
}

- (void)drawCentre:(CGContextRef)ctx
{
    //1.获取图形上下文
    CGContextSetStrokeColorWithColor(ctx, [UIColor clearColor].CGColor);
    CGContextSetLineWidth(ctx, 2);
    CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
    CGContextAddArc(ctx, 20, 20, 16, 0, 2*M_PI, 0);
    CGContextDrawPath(ctx, kCGPathFillStroke);

}

@end
