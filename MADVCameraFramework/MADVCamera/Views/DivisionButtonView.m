//
//  DivisionButtonView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/8/17.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "DivisionButtonView.h"
#import "CenterButton.h"
#import "Masonry.h"

@interface DivisionButtonView()
@property(nonatomic,strong)NSMutableArray * btnArr;
@end

@implementation DivisionButtonView

- (NSMutableArray *)btnArr
{
    if (_btnArr == nil) {
        _btnArr = [[NSMutableArray alloc] init];
    }
    return _btnArr;
}
- (void)loadDivisionButtonView
{
    CGFloat width = (self.width - (self.imageArray.count - 1))/self.imageArray.count;
    for (int i = 0; i < self.imageArray.count; i++) {
        CenterButton * centerBtn = [[CenterButton alloc] init];
        centerBtn.isTop = YES;
        [self addSubview:centerBtn];
        [centerBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(@((width + 1)* i));
            make.width.equalTo(@(width));
            make.height.equalTo(@(self.height));
        }];
        [centerBtn setImage:[UIImage imageNamed:self.imageArray[i]] forState:UIControlStateNormal];
        [centerBtn setTitle:self.nameArray[i] forState:UIControlStateNormal];
        [centerBtn setTitleColor:[UIColor colorWithHexString:@"#000000" alpha:0.9] forState:UIControlStateNormal];
        centerBtn.titleLabel.font = [UIFont systemFontOfSize:11];
        centerBtn.tag = 5000 +i;
        [centerBtn addTarget:self action:@selector(centerBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.btnArr addObject:centerBtn];
        
        if (i != self.imageArray.count - 1) {
            UIView * lineView = [[UIView alloc] init];
            [self addSubview:lineView];
            [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(@20);
                make.left.equalTo(centerBtn.mas_right);
                make.width.equalTo(@1);
                make.bottom.equalTo(@(-20));
            }];
            lineView.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.3];
        }
        
    }
    
}

- (void)setImageIndex:(int)index imageName:(NSString *)imageName
{
    CenterButton * centerBtn = self.btnArr[index];
    [centerBtn setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

- (void)setNameIndex:(int)index name:(NSString *)name
{
    CenterButton * centerBtn = self.btnArr[index];
    [centerBtn setTitle:name forState:UIControlStateNormal];
}

- (void)centerBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(divisionButtonViewClick:index:)]) {
        [self.delegate divisionButtonViewClick:self index:(btn.tag-5000)];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
