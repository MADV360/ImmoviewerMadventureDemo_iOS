//
//  DistinguishRate.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/15.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
/** 分辨率类型 */
typedef enum : NSInteger {
    AutoRate,
    FluentRate,
    HeightRate,
    SuperRate,
}DistinguishRateType;

@class DistinguishRate;

@protocol DistinguishRateDelegate <NSObject>

- (void)distinguishRate:(DistinguishRate *)distinguishRate rateType:(DistinguishRateType)type;

- (void)distinguishRateQuit:(DistinguishRate *)distinguishRate;

@end

@interface DistinguishRate : UIView
@property(nonatomic,weak)id<DistinguishRateDelegate> delegate;
- (void)selectRateType:(DistinguishRateType)type;
- (void)disableUserInteractionType:(DistinguishRateType)type;
@end
