//
//  SubAdjustCellView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/12/22.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "SubAdjustCellView.h"
#import "CenterButton.h"

@interface SubAdjustCellView()<AdjustCollectionViewDelegate>
@property(nonatomic,weak)AdjustCollectionView * adjustCollectionView;
@property(nonatomic,weak)CenterButton * leftButton;
@end

@implementation SubAdjustCellView
- (void)loadSubAdjustCellView
{
    CenterButton * leftButton = [[CenterButton alloc] init];
    [self addSubview:leftButton];
    leftButton.frame = CGRectMake(0, 0, 60, self.height);
    [leftButton setTitleColor:[UIColor colorWithHexString:@"#ffffff" alpha:0.5] forState:UIControlStateNormal];
    leftButton.titleLabel.font = [UIFont systemFontOfSize:10];
    leftButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.leftButton = leftButton;
    
    UIView * lineView = [[UIView alloc] init];
    [self addSubview:lineView];
    lineView.frame = CGRectMake(60, 10, 1, self.height - 20);
    lineView.backgroundColor = [UIColor colorWithHexString:@"#464747"];
    
    UIButton * closeBtn = [[UIButton alloc] init];
    [self addSubview:closeBtn];
    closeBtn.frame = CGRectMake(self.width - 40, 0, 40, self.height);
    [closeBtn setImage:[UIImage imageNamed:@"adjust_close.png"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    AdjustCollectionView * adjustCollectionView = [[AdjustCollectionView alloc] init];
    [self addSubview:adjustCollectionView];
    adjustCollectionView.frame = CGRectMake(61, 0, self.width - 61 - 40, self.height);
    adjustCollectionView.dataSource = self.dataSource;
    adjustCollectionView.adjustType = TopPicture_BottomWord;
    [adjustCollectionView loadAdjustCollectionView];
    adjustCollectionView.delegate = self;
    self.adjustCollectionView = adjustCollectionView;
}
- (void)closeBtnClick:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(subAdjustCellViewClose:)]) {
        [self.delegate subAdjustCellViewClose:self];
    }
}

#pragma mark --AdjustCollectionViewDelegate代理方法的实现--
- (void)adjustCollectionView:(AdjustCollectionView *)adjustCollectionView click:(AdjustCameraModel *)adjustCameraModel
{
    if ([self.delegate respondsToSelector:@selector(subAdjustCellView:click:)]) {
        [self.delegate subAdjustCellView:self click:adjustCameraModel];
    }
}
- (void)refresh
{
    self.adjustCollectionView.dataSource = self.dataSource;
    self.adjustCollectionView.adjustType = self.adjustType;
    [self.adjustCollectionView refresh];
}
- (void)setAdjustCameraModel:(AdjustCameraModel *)adjustCameraModel
{
    _adjustCameraModel = adjustCameraModel;
    [self.leftButton setImage:[UIImage imageNamed:adjustCameraModel.imageName] forState:UIControlStateNormal];
    [self.leftButton setTitle:adjustCameraModel.title forState:UIControlStateNormal];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
