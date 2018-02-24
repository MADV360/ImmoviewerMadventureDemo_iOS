//
//  DownloadManagerCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 16/9/20.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadManagerCell : UITableViewCell
@property(nonatomic,weak)UIImageView * thumbnailImageView;
@property(nonatomic,weak)UIImageView * playImageView;
@property(nonatomic,weak)UILabel * filenameLabel;
@property(nonatomic,weak)UILabel * downloadBtyeLabel;
@property(nonatomic,weak)UIImageView * statusImageView;
@property(nonatomic,weak)UIImageView * selectImageView;
@property(nonatomic,assign)CGFloat defaultDownWidth;
@property(nonatomic,weak)UIView * progressView;
@end
