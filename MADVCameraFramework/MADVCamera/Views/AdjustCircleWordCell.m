//
//  AdjustCircleWordCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/12/21.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AdjustCircleWordCell.h"
#import "Masonry.h"

@interface AdjustCircleWordCell()
@property(nonatomic,weak)UILabel * titleLabel;
@end

@implementation AdjustCircleWordCell
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        UILabel * titleLabel = [[UILabel alloc] init];
        [self.contentView addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@30);
            make.height.equalTo(@30);
        }];
        titleLabel.font = [UIFont systemFontOfSize:10];
        titleLabel.textColor = [UIColor colorWithHexString:@"#ffffff" alpha:0.7];
        titleLabel.layer.masksToBounds = YES;
        titleLabel.layer.cornerRadius = 15;
        titleLabel.layer.borderColor = [UIColor colorWithHexString:@"#ffffff" alpha:0.5].CGColor;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.layer.borderWidth = 0.5;
        titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.titleLabel = titleLabel;
    }
    return self;
}
- (void)setAdjustCameraModel:(AdjustCameraModel *)adjustCameraModel
{
    _adjustCameraModel = adjustCameraModel;
    self.titleLabel.text = adjustCameraModel.title;
    if (adjustCameraModel.isSelect) {
        self.titleLabel.textColor = [UIColor colorWithHexString:@"#10A4F1"];
        self.titleLabel.layer.borderColor = [UIColor colorWithHexString:@"#10A4F1"].CGColor;
    }else
    {
        self.titleLabel.textColor = [UIColor colorWithHexString:@"#ffffff" alpha:0.7];
        self.titleLabel.layer.borderColor = [UIColor colorWithHexString:@"#ffffff" alpha:0.5].CGColor;
    }
}
@end
