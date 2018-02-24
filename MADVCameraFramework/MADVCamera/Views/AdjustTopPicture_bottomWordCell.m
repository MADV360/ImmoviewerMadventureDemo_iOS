//
//  AdjustTopPicture_bottomWordCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/12/21.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AdjustTopPicture_bottomWordCell.h"
#import "CenterButton.h"
#import "Masonry.h"

@interface AdjustTopPicture_bottomWordCell()
@property(nonatomic,weak)CenterButton * centerButton;
@end

@implementation AdjustTopPicture_bottomWordCell
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        CenterButton * centerButton = [[CenterButton alloc] init];
        [self.contentView addSubview:centerButton];
        [centerButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.bottom.equalTo(@0);
        }];
        [centerButton setTitleColor:[UIColor colorWithHexString:@"#ffffff" alpha:0.5] forState:UIControlStateNormal];
        centerButton.titleLabel.font = [UIFont systemFontOfSize:10];
        centerButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        centerButton.userInteractionEnabled = NO;
        self.centerButton = centerButton;
    }
    return self;
}
- (void)setAdjustCameraModel:(AdjustCameraModel *)adjustCameraModel
{
    _adjustCameraModel = adjustCameraModel;
    [self.centerButton setImage:[UIImage imageNamed:adjustCameraModel.imageName] forState:UIControlStateNormal];
    [self.centerButton setTitle:adjustCameraModel.title forState:UIControlStateNormal];
    if (adjustCameraModel.isSelect) {
        [self.centerButton setTitleColor:[UIColor colorWithHexString:@"#1288C5"] forState:UIControlStateNormal];
        [self.centerButton setImage:[UIImage imageNamed:adjustCameraModel.selectImageName] forState:UIControlStateNormal];
    }else
    {
        [self.centerButton setTitleColor:[UIColor colorWithHexString:@"#ffffff" alpha:0.5] forState:UIControlStateNormal];
        [self.centerButton setImage:[UIImage imageNamed:adjustCameraModel.imageName] forState:UIControlStateNormal];
    }
}


@end
