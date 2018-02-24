//
//  UICollectionView+Extensions.m
//  Madv360_v1
//
//  Created by QiuDong on 16/4/11.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "UICollectionView+Extensions.h"

@implementation UICollectionView (Extensions)

- (NSArray *)indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

@end
