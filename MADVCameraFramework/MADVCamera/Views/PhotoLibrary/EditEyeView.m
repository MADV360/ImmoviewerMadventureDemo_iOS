//
//  EditEyeView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "EditEyeView.h"
#import "Masonry.h"
#import "EditEyeCell.h"

@interface EditEyeView ()<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UICollectionViewDelegate,EditEyeCellDelegate>

@property(nonatomic,weak)UICollectionView* collectionView;
@end

@implementation EditEyeView
- (void)loadEditEyeView
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
    collectionView.backgroundColor = [UIColor clearColor];
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
    NSString * identifier=@"EditEye";
    [collectionView registerClass:[EditEyeCell class] forCellWithReuseIdentifier:identifier];
    EditEyeCell * cell=[collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    if (self.selectIndexPath.item == indexPath.item) {
        cell.editImageView.image = [UIImage imageNamed:self.selectImageArr[indexPath.item]];
        cell.titleLabel.textColor = [UIColor colorWithHexString:@"#0091dc"];
    }else
    {
        cell.editImageView.image = [UIImage imageNamed:self.imageArr[indexPath.item]];
        cell.titleLabel.textColor = [UIColor whiteColor];
    }
    if (indexPath.item == 0) {
        cell.lineView.hidden = YES;
    }else
    {
        cell.lineView.hidden = NO;
    }
    cell.titleLabel.text = self.titleArr[indexPath.item];
    [cell.titleLabel sizeToFit];
    CGFloat width;
    width = ScreenWidth/self.imageArr.count;
    if (cell.titleLabel.width < width - 10) {
        cell.titleLabel.width = width - 10;
    }
    cell.indexPath = indexPath;
    cell.delegate = self;
    return cell;
}

#pragma mark    UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width;
    width = ScreenWidth/self.imageArr.count;
    
    return CGSizeMake(width, self.height-1);
}

#pragma mark --EditEyeCellDelegate代理方法的实现--
- (void)editEyeCellClick:(EditEyeCell *)editEyeCell
{
    if (editEyeCell.indexPath.item != self.selectIndexPath.item) {
        NSIndexPath * cancelIndexPath = self.selectIndexPath;
        self.selectIndexPath = editEyeCell.indexPath;
        [self.collectionView reloadItemsAtIndexPaths:@[cancelIndexPath,editEyeCell.indexPath]];
        if ([self.delegate respondsToSelector:@selector(editEyeViewClick:index:)]) {
            [self.delegate editEyeViewClick:self index:editEyeCell.indexPath.item];
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
