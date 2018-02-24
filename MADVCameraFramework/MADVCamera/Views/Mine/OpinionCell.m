//
//  OpinionCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/7/4.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "OpinionCell.h"
#import "Masonry.h"


@interface OpinionCell()

@end

@implementation OpinionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor=[UIColor clearColor];
        
        UIView * backView=[[UIView alloc] init];
        [self.contentView addSubview:backView];
        [backView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@15);
            make.right.equalTo(@-15);
            make.top.equalTo(@10);
            make.height.equalTo(@130);
        }];
        backView.backgroundColor=[UIColor whiteColor];
        backView.layer.borderColor=[UIColor colorWithRed:0.84f green:0.84f blue:0.85f alpha:1.00f].CGColor;
        backView.layer.borderWidth=1;
        backView.layer.masksToBounds=YES;
        backView.layer.cornerRadius=5;
        
        
        
        MyTextView * textView=[[MyTextView alloc] init];
        [backView addSubview:textView];
        [textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@10);
            make.right.equalTo(@-10);
            make.top.equalTo(@0);
            make.height.equalTo(@130);
        }];
        if (ScreenWidth < 375) {
            textView.font=[UIFont systemFontOfSize:12];
        }else
        {
            textView.font=[UIFont systemFontOfSize:15];
        }

        self.textView=textView;
        
        UILabel * emailLabel = [[UILabel alloc] init];
        [self.contentView addSubview:emailLabel];
        [emailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@15);
            make.right.equalTo(@-10);
            make.top.equalTo(backView.mas_bottom).offset(12.5);
            make.height.equalTo(@20);
        }];
        emailLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.7];
        emailLabel.font = [UIFont systemFontOfSize:14];
        emailLabel.text = FGGetStringWithKeyFromTable(EMAIL, nil);
        
//        UIView * lineView=[[UIView alloc] init];
//        [self.contentView addSubview:lineView];
//        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.left.equalTo(@15);
//            make.right.equalTo(@0);
//            make.top.equalTo(textView.mas_bottom);
//            make.height.equalTo(@1);
//        }];
//        lineView.backgroundColor=[UIColor colorWithRed:0.84f green:0.84f blue:0.85f alpha:1.00f];
        
        UIView * emailBackView=[[UIView alloc] init];
        [self.contentView addSubview:emailBackView];
        [emailBackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@15);
            make.right.equalTo(@-15);
            make.top.equalTo(backView.mas_bottom).offset(45);
            make.bottom.equalTo(@0);
        }];
        emailBackView.backgroundColor=[UIColor whiteColor];
        emailBackView.layer.borderColor=[UIColor colorWithRed:0.84f green:0.84f blue:0.85f alpha:1.00f].CGColor;
        emailBackView.layer.borderWidth=1;
        emailBackView.layer.masksToBounds=YES;
        emailBackView.layer.cornerRadius=5;
        
        
        
        
        MyTextView * mailTextField=[[MyTextView alloc] init];
        [emailBackView addSubview:mailTextField];
        [mailTextField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@10);
            make.right.equalTo(@-10);
            make.top.equalTo(@0);
            make.height.equalTo(@60);
        }];
        
        //mailTextField.placeholder=FGGetStringWithKeyFromTable(PLEASEEMAILWECANREPLY, nil);
//        NSDictionary *attributes = @{
//
//                                     NSFontAttributeName:[UIFont systemFontOfSize:10],
//
//                                     };
        
        if (ScreenWidth < 375) {
            mailTextField.font = [UIFont systemFontOfSize:12];
        }else
        {
            mailTextField.font = [UIFont systemFontOfSize:15];
        }
        mailTextField.placeholder = FGGetStringWithKeyFromTable(PLEASEEMAILWECANREPLY, nil);
        self.mailTextField=mailTextField;
        
    }
    return self;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder=placeholder;
    self.textView.placeholder=placeholder;
}

- (void)hiddenKeyboard
{
    [self.textView resignFirstResponder];
    [self.mailTextField resignFirstResponder];
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
