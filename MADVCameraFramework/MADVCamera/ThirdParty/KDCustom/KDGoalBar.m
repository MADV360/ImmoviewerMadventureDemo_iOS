
#import "KDGoalBar.h"

@implementation KDGoalBar
@synthesize    percentLabel;

#pragma Init & Setup
- (id)init
{
	if ((self = [super init]))
	{
		[self setup];
	}
    
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder]))
	{
		[self setup];
	}
    
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
//		[self setup];
	}
    
	return self;
}


-(void)layoutSubviews {
    CGRect frame = self.frame;
    int percent = percentLayer.percent * 100;
    [percentLabel setText:[NSString stringWithFormat:@"%i%@", percent,@"%"]];

    
//    CGRect labelFrame = percentLabel.frame;
//    labelFrame.origin.x = frame.size.width / 2 - percentLabel.frame.size.width / 2;
//    labelFrame.origin.y = 10;
//    percentLabel.frame = labelFrame;
    
    [super layoutSubviews];
}

-(void)setup {
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;
    
    thumbLayer = [CALayer layer];
    thumbLayer.contentsScale = [UIScreen mainScreen].scale;
    thumbLayer.contents = (id) thumb.CGImage;
    thumbLayer.frame = CGRectMake(self.frame.size.width / 2 - thumb.size.width/2, 0, thumb.size.width, thumb.size.height);
    thumbLayer.hidden = YES;
    
    
    percentLayer = [KDGoalBarPercentLayer layer];
    percentLayer.innerRadius=21;
    percentLayer.cornerRadius=25;
    percentLayer.rightColor=self.rightColor;
    percentLayer.leftColor=self.leftColor;
    percentLayer.contentsScale = [UIScreen mainScreen].scale;
    percentLayer.percent = 0;
    percentLayer.frame = self.bounds;
    percentLayer.masksToBounds = NO;
    [percentLayer setNeedsDisplay];
    
    [self.layer addSublayer:percentLayer];
    [self.layer addSublayer:thumbLayer];

    
    percentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    //设置里面字体的大小
    [percentLabel setFont:self.textFont];
    //设置里面字体的颜色
    [percentLabel setTextColor:self.textColor];
    percentLabel.textAlignment=NSTextAlignmentCenter;
    [percentLabel setBackgroundColor:[UIColor clearColor]];
    percentLabel.hidden=!self.isRateShow;
    [self addSubview:percentLabel];
    self.percentLabel = percentLabel;

    
    
     
    
}
- (void)setIsRateShow:(BOOL)isRateShow
{
    _isRateShow = isRateShow;
    self.percentLabel.hidden = !isRateShow;
}


#pragma mark - Touch Events
- (void)moveThumbToPosition:(CGFloat)angle {
    CGRect rect = thumbLayer.frame;
    //NSLog(@"%@",NSStringFromCGRect(rect));
    CGPoint center = CGPointMake(self.bounds.size.width/2.0f, self.bounds.size.height/2.0f);
    angle -= (M_PI/2);
    //NSLog(@"%f",angle);

    rect.origin.x = center.x + 75 * cosf(angle) - (rect.size.width/2);
    rect.origin.y = center.y + 75 * sinf(angle) - (rect.size.height/2);
    
    //NSLog(@"%@",NSStringFromCGRect(rect));

    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    thumbLayer.frame = rect;
    
    [CATransaction commit];
}
#pragma mark - Custom Getters/Setters
- (void)setPercent:(int)percent animated:(BOOL)animated {
    
    CGFloat floatPercent = percent / 100.0;
    floatPercent = MIN(1, MAX(0, floatPercent));
    
    percentLayer.percent = floatPercent;
    [self setNeedsLayout];
    [percentLayer setNeedsDisplay];
    
    [self moveThumbToPosition:floatPercent * (2 * M_PI) - (M_PI/2)];
    
}

- (void)dealloc{
    [percentLabel release];
    [super dealloc];
}

@end
