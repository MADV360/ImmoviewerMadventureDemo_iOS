//
//  VoltageView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/12/22.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "VoltageView.h"
#import "AdjustCollectionView.h"

@interface VoltageView()
@property(nonatomic,weak)AdjustCollectionView * adjustCollectionView;

@end

@implementation VoltageView
- (void)loadVoltageView
{
    UILabel * cameraLabel = [[UILabel alloc] init];
    [self addSubview:cameraLabel];
    cameraLabel.frame = CGRectMake(0, (self.height - 16) * 0.5, 60, 16);
    cameraLabel.textColor = [UIColor colorWithHexString:@"#ffffff" alpha:0.7];
    cameraLabel.textAlignment = NSTextAlignmentCenter;
    cameraLabel.font = [UIFont systemFontOfSize:10];
    cameraLabel.numberOfLines = 0;
    cameraLabel.attributedText = [[NSAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(CAMERASTATE, nil)];
    [cameraLabel sizeToFit];
    if (cameraLabel.width < 60) {
        cameraLabel.width = 60;
    }
    cameraLabel.y = (self.height - cameraLabel.height) * 0.5;
    
    UIView * lineView = [[UIView alloc] init];
    [self addSubview:lineView];
    lineView.frame = CGRectMake(60, 10, 1, self.height - 20);
    lineView.backgroundColor = [UIColor colorWithHexString:@"#464747"];
    
    AdjustCollectionView * adjustCollectionView = [[AdjustCollectionView alloc] init];
    [self addSubview:adjustCollectionView];
    adjustCollectionView.frame = CGRectMake(61, 0, self.width - 61, self.height);
    adjustCollectionView.dataSource = self.dataSource;
    adjustCollectionView.adjustType = TopBottomWord;
    [adjustCollectionView loadAdjustCollectionView];
    self.adjustCollectionView = adjustCollectionView;
}
- (void)refresh
{
    self.adjustCollectionView.dataSource = self.dataSource;
    [self.adjustCollectionView refresh];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
