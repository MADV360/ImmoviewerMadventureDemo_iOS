//
//  AdjustCollectionView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/12/21.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AdjustCollectionView.h"
#import "Masonry.h"
#import "AdjustTopPicture_bottomWordCell.h"
#import "AdjustCircleWordCell.h"
#import "AdjustTopBottomWordCell.h"

@interface AdjustCollectionView()<UICollectionViewDelegate,UICollectionViewDataSource>
@property(nonatomic,weak)UICollectionView* collectionView;
@end

@implementation AdjustCollectionView
- (void)loadAdjustCollectionView
{
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = 0;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumInteritemSpacing = 0;
    
    
    
    UICollectionView* collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) collectionViewLayout:flowLayout];
    [self addSubview:collectionView];
    [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView = collectionView;
}
#pragma mark --UICollectionViewDataSource代理方法的实现--
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataSource.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AdjustCameraModel * adjustCameraModel = self.dataSource[indexPath.item];
    NSString * identifier;
    Class class;
    if (self.adjustType == TopPicture_BottomWord) {
        identifier = @"TopPicture_BottomWord";
        class = [AdjustTopPicture_bottomWordCell class];
    }else if(self.adjustType == TopBottomWord)
    {
        identifier = @"TopBottomWord";
        class = [AdjustTopBottomWordCell class];
    }else
    {
        identifier = @"CircleWord";
        class = [AdjustCircleWordCell class];
    }
    
    [collectionView registerClass:class forCellWithReuseIdentifier:identifier];
    UICollectionViewCell * cell=[collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    if (self.adjustType == TopPicture_BottomWord) {
        AdjustTopPicture_bottomWordCell * adjustCell = (AdjustTopPicture_bottomWordCell *)cell;
        adjustCell.adjustCameraModel = adjustCameraModel;
    }else if(self.adjustType == TopBottomWord)
    {
        AdjustTopBottomWordCell * adjustCell = (AdjustTopBottomWordCell *)cell;
        adjustCell.adjustCameraModel = adjustCameraModel;
    }else
    {
        AdjustCircleWordCell * adjustCell = (AdjustCircleWordCell *)cell;
        adjustCell.adjustCameraModel = adjustCameraModel;
        
    }
    
    return cell;
}

#pragma mark    UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width;
    width = self.width/self.dataSource.count;
    if (width < 60) {
        width = 60;
    }
    
    return CGSizeMake(width, self.height);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.adjustType != TopBottomWord) {
        if ([self.delegate respondsToSelector:@selector(adjustCollectionView:click:)]) {
            AdjustCameraModel * adjustCameraModel = self.dataSource[indexPath.item];
            [self.delegate adjustCollectionView:self click:adjustCameraModel];
        }
    }
}

- (void)refresh
{
    [self.collectionView reloadData];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
