//
//  PhoneImageCell.h
//  photoKitImageVideo
//
//  Created by 张巧隔 on 16/7/18.
//  Copyright © 2016年 张巧隔. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhoneImageCell : UICollectionViewCell
@property(nonatomic,weak)UIImageView * phoneImageView;
@property(nonatomic,weak)UIImageView * selectImageView;
@property(nonatomic,copy)NSString * identifier;
@property(nonatomic,weak)UILabel * durationLabel;
@end
