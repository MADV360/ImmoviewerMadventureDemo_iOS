//
//  MyPageView.h
//  DasBank
//
//  Created by 张巧隔 on 16/4/7.
//  Copyright © 2016年 LXWT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyPageView : UIView
@property(nonatomic,assign)NSInteger numberOfPages;
@property(nonatomic,assign)NSInteger currentPage;
@property(nonatomic,strong)UIColor * borderColor;
@property(nonatomic,strong)UIColor * currentBgColor;
@end
