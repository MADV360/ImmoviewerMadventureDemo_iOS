
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "KDGoalBarPercentLayer.h"


@interface KDGoalBar : UIView {
    UIImage * thumb;
    
    KDGoalBarPercentLayer *percentLayer;
    CALayer *thumbLayer;
          
}

@property (nonatomic, strong) UILabel *percentLabel;

@property(nonatomic,strong)UIColor * rightColor;
@property(nonatomic,strong)UIColor * leftColor;
@property(nonatomic,assign)BOOL isRateShow;
@property(nonatomic,strong)UIColor * textColor;
@property(nonatomic,strong)UIFont * textFont;

- (void)setPercent:(int)percent animated:(BOOL)animated;

-(void)setup;
@end
