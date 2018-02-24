//
//  PublishTitleCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/22.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "PublishTitleCell.h"
#import "Masonry.h"


@interface PublishTitleCell ()

@end
@implementation PublishTitleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UILabel * titleTagLabel = [[UILabel alloc] init];
        [self.contentView addSubview:titleTagLabel];
        titleTagLabel.frame = CGRectMake(15, 15, 40, 16);
//        [titleTagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.left.equalTo(@15);
//            make.centerY.equalTo(self.contentView.mas_centerY);
//            make.width.equalTo(@40);
//            make.height.equalTo(@20);
//        }];
        titleTagLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        titleTagLabel.font = [UIFont systemFontOfSize:16];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",FGGetStringWithKeyFromTable(TITLE, nil)]];
        titleTagLabel.attributedText = attributedString;
        [titleTagLabel sizeToFit];
        
        MyTextView * textView=[[MyTextView alloc] init];
        [self.contentView addSubview:textView];
        [textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(titleTagLabel.mas_right).offset(5);
            make.top.equalTo(@5);
            make.right.equalTo(@-15);
            make.height.equalTo(@40);
        }];
        textView.font=[UIFont systemFontOfSize:16];
        textView.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.8];
        textView.bounces=YES;
        textView.backgroundColor=[UIColor clearColor];
        textView.placeholder=FGGetStringWithKeyFromTable(NOWIDEA, nil);
        self.titleTextView = textView;
        
    }
    return self;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
