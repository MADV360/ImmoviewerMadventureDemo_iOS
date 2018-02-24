//
//  EditFilterView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "EditFilterView.h"
#import "Masonry.h"
#import "EditFilterCell.h"

@interface EditFilterView ()<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UICollectionViewDelegate,EditFilterCellDelegate>
@property(nonatomic,strong)NSIndexPath * selectIndexPath;
@property(nonatomic,weak)UICollectionView* collectionView;
@end

@implementation EditFilterView
- (void)loadEditFilterViewl
{
    self.selectIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UIView * lineView = [[UIView alloc] init];
    [self addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@1);
    }];
    if (self.isPhoto) {
        lineView.backgroundColor = [UIColor colorWithHexString:@"#FFFFFF" alpha:0.3];
    }else
    {
        lineView.backgroundColor = [UIColor colorWithHexString:@"#FFFFFF" alpha:0.2];
    }
    
    
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;

    
    UICollectionView* collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) collectionViewLayout:flowLayout];
    [self addSubview:collectionView];
    [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lineView.mas_bottom);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    collectionView.backgroundColor = self.backgroundColor;
//    collectionView. = YES;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    self.collectionView = collectionView;
}

#pragma mark --UICollectionViewDataSource代理方法的实现--
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.imageArr.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * identifier=@"EditFilterView";
    [collectionView registerClass:[EditFilterCell class] forCellWithReuseIdentifier:identifier];
    EditFilterCell * cell=[collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    if (self.selectIndexPath.item == indexPath.item) {
        cell.filterImageview.alpha = 1;
        cell.filterImageview.layer.borderColor = [UIColor colorWithHexString:@"#0091dc"].CGColor;
        cell.titleLabel.alpha = 1;
        cell.titleLabel.textColor = [UIColor colorWithHexString:@"#0091dc"];
    }else
    {
        cell.filterImageview.alpha = 0.5;
        cell.filterImageview.layer.borderColor = [UIColor clearColor].CGColor;
        cell.titleLabel.alpha = 0.5;
        cell.titleLabel.textColor = [UIColor whiteColor];
    }
        
    cell.filterImageview.image = [UIImage imageNamed:self.imageArr[indexPath.item]];
    cell.titleLabel.text = self.titleArr[indexPath.item];
    cell.indexPath = indexPath;
    cell.delegate = self;
    return cell;
}
#pragma mark --EditFilterCellDelegate代理方法的实现--
- (void)editFilterCellClick:(EditFilterCell *)editFilterCell
{
    if (editFilterCell.indexPath.item != self.selectIndexPath.item) {
        NSIndexPath * cancelIndexPath = self.selectIndexPath;
        self.selectIndexPath = editFilterCell.indexPath;
        if (cancelIndexPath.item == -1) {
            [self.collectionView reloadItemsAtIndexPaths:@[editFilterCell.indexPath]];
        }else
        {
            [self.collectionView reloadItemsAtIndexPaths:@[cancelIndexPath,editFilterCell.indexPath]];
        }
        if ([self.delegate respondsToSelector:@selector(editFilterView:index:)]) {
            [self.delegate editFilterView:self index:editFilterCell.indexPath.item];
        }
    }
    
    
}
#pragma mark    UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width;
    if (self.imageArr.count > 5) {
        width = 82;
    }else
    {
        width = ScreenWidth/self.imageArr.count;
    }
    
    return CGSizeMake(width, self.height-1);
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
