//
//  SubAdjustPickerView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/12/26.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "SubAdjustPickerView.h"
#import "CenterButton.h"
#import "SettingTreeNode.h"

@interface SubAdjustPickerView()<MyPickerViewDelegate>
@property(nonatomic,weak)CenterButton * leftButton;
@property(nonatomic,weak)CustomPickerView * customPickerView;
@property(nonatomic,weak)UIView * frontView;
@end

@implementation SubAdjustPickerView
- (void)loadSubAdjustPickerView
{
    CenterButton * leftButton = [[CenterButton alloc] init];
    [self addSubview:leftButton];
    leftButton.frame = CGRectMake(0, 0, 60, self.height);
    [leftButton setTitleColor:[UIColor colorWithHexString:@"#ffffff" alpha:0.5] forState:UIControlStateNormal];
    leftButton.titleLabel.font = [UIFont systemFontOfSize:10];
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
    
    CustomPickerView * customPickerView = [[CustomPickerView alloc] initWithFrame:CGRectMake(61, 17, self.width - 61 - 40, 40)];
    customPickerView.pickerType = self.pickerType;
    customPickerView.delegate = self;
    [self addSubview:customPickerView];
    self.customPickerView = customPickerView;
    
    UIView * frontView = [[UIView alloc] init];
    [self addSubview:frontView];
    frontView.frame = CGRectMake(61, 17, self.width - 61 - 40, 40);
    frontView.userInteractionEnabled = NO;
    frontView.backgroundColor = [UIColor clearColor];
    self.frontView = frontView;
    
    UIPanGestureRecognizer * frontPan = [[UIPanGestureRecognizer alloc] init];
    [frontPan addTarget:self action:@selector(frontPan:)];
    [frontView addGestureRecognizer:frontPan];
    
    UITapGestureRecognizer * frontTap = [[UITapGestureRecognizer alloc] init];
    [frontTap addTarget:self action:@selector(frontTap:)];
    [frontView addGestureRecognizer:frontTap];
    
}
- (void)setPickerType:(PickerType)pickerType
{
    _pickerType = pickerType;
    self.customPickerView.pickerType = pickerType;
}
- (void)setAdjustCameraModel:(AdjustCameraModel *)adjustCameraModel
{
    _adjustCameraModel = adjustCameraModel;
    [self.leftButton setImage:[UIImage imageNamed:adjustCameraModel.imageName] forState:UIControlStateNormal];
    [self.leftButton setTitle:adjustCameraModel.title forState:UIControlStateNormal];
}
- (void)closeBtnClick:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(subAdjustPickerViewClose:)]) {
        [self.delegate subAdjustPickerViewClose:self];
    }
}
- (void)setDataSource:(NSArray *)dataSource
{
    _dataSource = dataSource;
    NSMutableArray * arr = [[NSMutableArray alloc] init];
    for(int i = 0;i < dataSource.count; i++)
    {
        AdjustCameraModel * adjustCameraModel = dataSource[i];
        [arr addObject:FGGetStringWithKeyFromTable(adjustCameraModel.subSettingTreeNode.name, nil)];
        if (adjustCameraModel.settingTreeNode.selectedSubOptionUID == adjustCameraModel.subSettingTreeNode.uid) {
            self.scrollToIndex = i;
        }
        
    }
    self.customPickerView.dataModel = arr;
}
- (void)setScrollToIndex:(NSInteger)scrollToIndex
{
    _scrollToIndex = scrollToIndex;
    self.customPickerView.scrollToIndex = scrollToIndex;
}

- (void)refresh
{
    [self.customPickerView refresh];
}

- (void)frontPan:(UIPanGestureRecognizer *)pan
{
    if ([self.delegate respondsToSelector:@selector(subAdjustPickerView:click:error:)]) {
        [self.delegate subAdjustPickerView:self click:nil error:1];
    }
}
- (void)frontTap:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(subAdjustPickerView:click:error:)]) {
        [self.delegate subAdjustPickerView:self click:nil error:1];
    }
}

#pragma mark --MyPickerViewDelegate代理方法的实现--
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
{
    if ([self.delegate respondsToSelector:@selector(subAdjustPickerView:click:error:)]) {
        AdjustCameraModel * adjustCameraModel = self.dataSource[row];
        [self.delegate subAdjustPickerView:self click:adjustCameraModel error:0];
    }
}

- (void)setIsEnabled:(BOOL)isEnabled
{
    _isEnabled = isEnabled;
    self.frontView.userInteractionEnabled = !isEnabled;
    self.customPickerView.isEnabled = isEnabled;
}


@end
