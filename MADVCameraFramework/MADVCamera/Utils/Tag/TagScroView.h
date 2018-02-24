//
//  TagScroView.h
//  
//
//  Created by 张巧隔 on 14-1-7.
//  Copyright (c) 2014年 MS. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TagScroView;
@protocol TagScroViewDelegate <NSObject>

- (void)TagScroViewDidSelected:(TagScroView *)tagScroView andTagIndex:(NSInteger)tagIndex;

@end

@interface TagScroView : UIView
@property(nonatomic,weak)id<TagScroViewDelegate> delegate;
@property(nonatomic,strong)NSArray * dataArr;
@property(nonatomic,assign)CGFloat width;
@property(nonatomic,assign)CGFloat titleFont;
@property(nonatomic,strong)UIColor * titleColor;
@property(nonatomic,strong)UIColor * borderColor;
@property(nonatomic,strong)UIColor * lastTitleColor;
@property(nonatomic,strong)UIColor * contentBackgroundColor;

//是否选择后变样式
@property(nonatomic,assign)BOOL isSelected;
@property(nonatomic,strong)NSMutableDictionary * selectDict;
@property(nonatomic,strong)NSMutableArray * selectDataArr;
@property(nonatomic,assign)BOOL isAdd;

- (void)addTag:(NSString *)tag;

- (void)setTagSelected:(int)index;
- (void)tagClick:(NSInteger)index isSelect:(BOOL)isSelect;
@end
