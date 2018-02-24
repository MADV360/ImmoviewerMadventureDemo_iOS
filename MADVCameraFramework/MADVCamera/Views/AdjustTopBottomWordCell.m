//
//  AdjustTopBottomWordCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/12/21.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AdjustTopBottomWordCell.h"
#import "Masonry.h"

@interface AdjustTopBottomWordCell()
@property(nonatomic,weak)UILabel * titleLabel;
@property(nonatomic,weak)UILabel * subTitleLabel;
@end

@implementation AdjustTopBottomWordCell
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        UILabel * titleLabel = [[UILabel alloc] init];
        [self.contentView addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.contentView.mas_centerY).offset(-2);
            make.left.equalTo(@1);
            make.right.equalTo(@-1);
            make.height.equalTo(@15);
        }];
        titleLabel.textColor = [UIColor colorWithHexString:@"#ffffff" alpha:0.7];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont systemFontOfSize:12];
        titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.titleLabel = titleLabel;
        
        UILabel * subTitleLabel = [[UILabel alloc] init];
        [self.contentView addSubview:subTitleLabel];
        subTitleLabel.numberOfLines = 0;
        subTitleLabel.frame = CGRectMake(1, self.contentView.height * 0.5 + 2, self.contentView.width - 2, 11);
        subTitleLabel.textColor = [UIColor colorWithHexString:@"#ffffff" alpha:0.5];
        subTitleLabel.textAlignment = NSTextAlignmentCenter;
        subTitleLabel.font = [UIFont systemFontOfSize:10];
        self.subTitleLabel = subTitleLabel;
    }
    return self;
}

- (void)setAdjustCameraModel:(AdjustCameraModel *)adjustCameraModel
{
    _adjustCameraModel = adjustCameraModel;
    self.titleLabel.text = adjustCameraModel.title;
    
    self.subTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:adjustCameraModel.subTitle];
    [self.subTitleLabel sizeToFit];
    if (self.subTitleLabel.width < self.contentView.width - 2) {
        self.subTitleLabel.width = self.contentView.width - 2;
    }
}

@end
