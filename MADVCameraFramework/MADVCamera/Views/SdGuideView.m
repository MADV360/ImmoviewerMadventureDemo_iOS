//
//  SdGuideView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/3/20.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "SdGuideView.h"
#import "SdGuideScrollView.h"
#import "Masonry.h"
#import "PlayScrollModel.h"
@implementation SdGuideView
- (void)loadSdGuideView
{
    SdGuideScrollView * scrollView = [[SdGuideScrollView alloc] init];
    [self addSubview:scrollView];
    scrollView.frame = CGRectMake(15, 130, ScreenWidth - 30, ScreenHeight - 260);
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.layer.masksToBounds = YES;
    scrollView.layer.cornerRadius = 10;
    
    PlayScrollModel * firstPlay = [[PlayScrollModel alloc] init];
    firstPlay.filename = @"hand1.png";
    firstPlay.title =FGGetStringWithKeyFromTable(OPENSDCARD, nil);
    
    PlayScrollModel * secPlay = [[PlayScrollModel alloc] init];
    secPlay.filename = @"hand2.png";
    secPlay.title = FGGetStringWithKeyFromTable(INSTALLSDCARD, nil);

    PlayScrollModel * thirdPlay = [[PlayScrollModel alloc] init];
    thirdPlay.filename = @"hand3.png";
    thirdPlay.title = FGGetStringWithKeyFromTable(CLOSESDCARD, nil);

    scrollView.dataSource = @[firstPlay,secPlay,thirdPlay];
    
    
    UIImageView * closeImageView = [[UIImageView alloc] init];
    [self addSubview:closeImageView];
    [closeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(scrollView.mas_right);
        make.bottom.equalTo(scrollView.mas_top);
        make.width.equalTo(@27);
        make.height.equalTo(@43);
    }];
    closeImageView.image = [UIImage imageNamed:@"mistake.png"];
    closeImageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] init];
    [tapGes addTarget:self action:@selector(tapGes:)];
    [closeImageView addGestureRecognizer:tapGes];
}
- (void)tapGes:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(sdGuideViewDidClose:)]) {
        [self.delegate sdGuideViewDidClose:self];
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
