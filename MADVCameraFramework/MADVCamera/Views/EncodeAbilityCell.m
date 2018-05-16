//
//  EncodeAbilityCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/10/20.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "EncodeAbilityCell.h"
#import "avUtils.h"

@implementation EncodeAbilityCell


- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    UILabel * encodeAbilityLabel = [[UILabel alloc] init];
    [self.contentView addSubview:encodeAbilityLabel];
    encodeAbilityLabel.frame = CGRectMake(15, 10, ScreenWidth - 49 - 15 - 15, 20);
    encodeAbilityLabel.font = [UIFont systemFontOfSize:13];
    encodeAbilityLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
    encodeAbilityLabel.numberOfLines = 0;
    encodeAbilityLabel.lineBreakMode = NSLineBreakByCharWrapping;
    encodeAbilityLabel.attributedText = [[NSAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(ENCODEABILITY, nil)];
    [encodeAbilityLabel sizeToFit];
    
    UISwitch * encodeSwitch = [[UISwitch alloc] init];
    [self.contentView addSubview:encodeSwitch];
    encodeSwitch.frame = CGRectMake(ScreenWidth - 49 - 15, 5, 49, 31);
    self.encodeSwitch = encodeSwitch;
    
    
    UILabel * encodeStatementLabel = [[UILabel alloc] init];
    [self.contentView addSubview:encodeStatementLabel];
    CGFloat y = 0;
    if (encodeAbilityLabel.height > 25) {
        y = CGRectGetMaxY(encodeAbilityLabel.frame) + 5;
    }else
    {
        y = CGRectGetMaxY(encodeSwitch.frame) + 5;
    }
    encodeStatementLabel.frame = CGRectMake(15, y, ScreenWidth - 60, 20);
    encodeStatementLabel.numberOfLines = 0;
    encodeStatementLabel.font = [UIFont systemFontOfSize:11];
    encodeStatementLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.7];
    encodeStatementLabel.lineBreakMode = NSLineBreakByCharWrapping;
    NSString * str = @"";
    if (![avUtils isVideoEncodeLimitedTo1080]) {
        str = FGGetStringWithKeyFromTable(DEVICE1080ENCODE, nil);
    }else
    {
        str = FGGetStringWithKeyFromTable(DEVICENO1080ENCODE, nil);
    }
    if (![avUtils isVideoDecodeLimitedTo1080]) {
        str = [NSString stringWithFormat:@"%@%@",str,FGGetStringWithKeyFromTable(DEVICE1080DECODE, nil)];
    }else
    {
        str = [NSString stringWithFormat:@"%@%@",str,FGGetStringWithKeyFromTable(DEVICENO1080DECODE, nil)];
    }
    encodeStatementLabel.attributedText = [[NSAttributedString alloc] initWithString:str];
    [encodeStatementLabel sizeToFit];
    
    self.height = CGRectGetMaxY(encodeStatementLabel.frame) + 10;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
