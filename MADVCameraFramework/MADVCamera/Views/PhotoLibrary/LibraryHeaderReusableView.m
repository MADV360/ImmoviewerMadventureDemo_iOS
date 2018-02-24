//
//  LibraryHeaderReusableView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/7/19.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "LibraryHeaderReusableView.h"
#import "Masonry.h"

@implementation LibraryHeaderReusableView
-(id)initWithFrame:(CGRect)frame
{
    if (self=[super initWithFrame:frame]) {
        UILabel * dateLabel=[[UILabel alloc] init];
        [self addSubview:dateLabel];
        [dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@3);
            make.height.equalTo(@15);
            make.bottom.equalTo(@-10);
            make.width.equalTo(@200);
        }];
        dateLabel.font=[UIFont systemFontOfSize:14];
        dateLabel.textColor=[UIColor colorWithHexString:@"#000000"];
        self.dateLabel=dateLabel;
        
        
        UIButton * selectBtn=[[UIButton alloc] init];
        [self addSubview:selectBtn];
        selectBtn.frame = CGRectMake(self.width - 15 - 50, (self.height - 25)*0.5, 50, 25);
//        [selectBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.right.equalTo(@-15);
//            make.centerY.equalTo(self.mas_centerY);
//            make.width.equalTo(@50);
//            make.height.equalTo(@25);
//        }];
        [selectBtn setTitle:FGGetStringWithKeyFromTable(SELECTALL, nil) forState:UIControlStateNormal];
        [selectBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        selectBtn.titleLabel.font=[UIFont systemFontOfSize:12];
        selectBtn.backgroundColor=[UIColor clearColor];
        selectBtn.layer.borderWidth=1;
        selectBtn.layer.borderColor=[UIColor colorWithRed:0.82f green:0.79f blue:0.78f alpha:1.00f].CGColor;
        selectBtn.layer.masksToBounds=YES;
        selectBtn.layer.cornerRadius=10;
        
        [selectBtn addTarget:self action:@selector(selectBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        self.selectBtn=selectBtn;
        
    }
    return self;
}

- (void)selectBtn:(UIButton *)btn
{
    self.selectBtn.selected=!self.selectBtn.selected;
    if (self.selectBtn.selected) {
        self.selectBtn.backgroundColor=[UIColor colorWithHexString:@"#0091DC"];
        [self.selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.selectBtn.layer.borderWidth=0;
        [self.selectBtn setTitle:FGGetStringWithKeyFromTable(DESELECTALL, nil) forState:UIControlStateNormal];
    }else
    {
        self.selectBtn.backgroundColor=[UIColor clearColor];
        [self.selectBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.selectBtn.layer.borderWidth=1;
        [self.selectBtn setTitle:FGGetStringWithKeyFromTable(SELECTALL, nil) forState:UIControlStateNormal];
    }
    if ([self.delegate respondsToSelector:@selector(selectClick:)]) {
        [self.delegate selectClick:self];
    }
}
@end
