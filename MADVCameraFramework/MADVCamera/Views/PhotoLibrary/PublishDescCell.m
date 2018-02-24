//
//  PublishDescCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/23.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "PublishDescCell.h"
#import "Masonry.h"
#import "NSString+Extensions.h"
@implementation PublishDescCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UILabel * describeLabel=[[UILabel alloc] init];
        [self.contentView addSubview:describeLabel];
        describeLabel.frame = CGRectMake(15, 15, 40, 16);
        describeLabel.font=[UIFont systemFontOfSize:14];
        describeLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.8];
        
        NSString * language = [NSString getAppLessLanguage];
        if ([language isEqualToString:@"en"]) {
            describeLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",FGGetStringWithKeyFromTable(DESCRIBE, nil)]];
            [describeLabel sizeToFit];
            describeLabel.width = describeLabel.width;
        }else
        {
            describeLabel.text=[NSString stringWithFormat:@"%@:",FGGetStringWithKeyFromTable(DESCRIBE, nil)];
        }
        
        
        
        MyTextView * descrTextView=[[MyTextView alloc] init];
        [self.contentView addSubview:descrTextView];
        [descrTextView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@6);
            make.left.equalTo(describeLabel.mas_right).offset(5);
            make.right.equalTo(@-15);
            make.height.equalTo(@149);
        }];
        
        descrTextView.viewWidth = ScreenWidth - 30 -describeLabel.width-5;
        descrTextView.backgroundColor=[UIColor clearColor];
        descrTextView.font=[UIFont systemFontOfSize:14];
        descrTextView.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.8];
        descrTextView.placeholder=FGGetStringWithKeyFromTable(LOOKWORLD, nil);
        descrTextView.bounces=YES;
        self.descrTextView=descrTextView;
        
        TagScroView * tagView=[[TagScroView alloc] init];
        [self.contentView addSubview:tagView];
        tagView.width=ScreenWidth-30;
        tagView.frame=CGRectMake(15, 165, ScreenWidth-30, 25);
        tagView.titleFont = 14;
        tagView.borderColor = [UIColor colorWithHexString:@"#000000" alpha:0.2];
        tagView.titleColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
        tagView.lastTitleColor = [UIColor colorWithHexString:@"#46a4ea"];
        self.tagView = tagView;
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
