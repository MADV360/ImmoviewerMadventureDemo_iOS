//
//  PhoneImageCell.m
//  photoKitImageVideo
//
//  Created by 张巧隔 on 16/7/18.
//  Copyright © 2016年 张巧隔. All rights reserved.
//

#import "PhoneImageCell.h"
#import "Masonry.h"

@implementation PhoneImageCell
- (id)initWithFrame:(CGRect)frame
{
    if (self=[super initWithFrame:frame]) {
        UIImageView * phoneImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:phoneImageView];
        [phoneImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.bottom.equalTo(@0);
        }];
        phoneImageView.image=[UIImage imageNamed:@"image.png"];
        self.phoneImageView=phoneImageView;
        
        
        UIImageView * selectImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:selectImageView];
        [selectImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@10);
            make.top.equalTo(@10);
            make.width.equalTo(@22);
            make.height.equalTo(@22);
        }];
        selectImageView.image=[UIImage imageNamed:@"checked mark_n.png"];
        self.selectImageView=selectImageView;
        
        UILabel * durationLabel=[[UILabel alloc] init];
        [self.contentView addSubview:durationLabel];
        [durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-5);
            make.bottom.equalTo(@-5);
            make.height.equalTo(@12);
            make.width.equalTo(@50);
        }];
        durationLabel.textAlignment=NSTextAlignmentRight;
        durationLabel.textColor=[UIColor whiteColor];
        durationLabel.font=[UIFont systemFontOfSize:12];
        self.durationLabel=durationLabel;
        
        
    }
    return self;
}
@end
