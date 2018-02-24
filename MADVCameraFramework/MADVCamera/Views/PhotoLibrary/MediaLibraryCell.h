//
//  MediaLibraryCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/9/12.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CycleView.h"

@class MediaLibraryCell;

@protocol MediaLibraryCellDelegate <NSObject>

- (void)mediaLibraryCell:(MediaLibraryCell *)mediaLibraryCell downloadIndexPath:(NSIndexPath *)indexPath;

@end

@interface MediaLibraryCell : UICollectionViewCell
@property(nonatomic,weak)UIImageView * defaultImageView;
@property(nonatomic,weak)UIImageView * thumbnailImageView;
@property(nonatomic,weak)UIImageView * playImageView;
@property(nonatomic,weak)UILabel * durationLabel;
@property(nonatomic,weak)UIView * maskView;
@property(nonatomic,weak)UIImageView * selectImageView;
@property(nonatomic,weak)CycleView * progressView;
@property(nonatomic,strong)UIImageView * downloadImageView;
@property(nonatomic,weak)UIImageView * downloadIconImageView;
@property(nonatomic,assign)BOOL isLocal;
@property(nonatomic,copy)NSString * identifier;
@property(nonatomic,strong)NSIndexPath * indexPath;
@property(nonatomic,weak)id<MediaLibraryCellDelegate> delegate;
@property(nonatomic,weak)UIView * downloadView;
@property(nonatomic,weak)UIImageView * stitchImageView;
@end
