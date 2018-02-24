//
//  TagScroView.m
//
//
//  Created by 张巧隔 on 14-1-7.
//  Copyright (c) 2014年 MS. All rights reserved.
//

#import "TagScroView.h"
#import "Masonry.h"
#import "UIView+Frame.h"
#define WIDTH self.frame.size.width

@interface TagScroView()
//@property(nonatomic,weak)UILabel * lastLable;
@property(nonatomic,assign)CGFloat leftPos;
@property(nonatomic,assign)int line;
@property(nonatomic,assign)int i;

@end

@implementation TagScroView

- (id)initWithFrame:(CGRect)frame
{
    if (self=[super initWithFrame:frame]) {
        self.leftPos=0;
        self.line=0;
        self.i=5000;
    }
    return self;
}

- (NSMutableDictionary *)selectDict
{
    if (_selectDict==nil) {
        _selectDict=[[NSMutableDictionary alloc] init];
    }
    return _selectDict;
}

- (void)setDataArr:(NSArray *)dataArr
{
    for(UIView * view in self.subviews)
    {
        [view removeFromSuperview];
    }
    _dataArr=dataArr;
    
    if (self.titleFont == 0) {
        self.titleFont = 12;
    }
    if (self.titleColor == nil) {
        self.titleColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    }
    if (self.borderColor == nil) {
        self.borderColor = [UIColor colorWithHexString:@"#000000" alpha:0.15];
    }
    CGFloat leftPos=0;
    int line=0;
    for (int i=0; i<dataArr.count; i++) {
        NSString * dataStr=dataArr[i];
        if (dataStr.length>0) {
            if (leftPos!=0) {
                leftPos=leftPos+5;
            }
            NSString * title=dataArr[i];
            CGSize size = CGSizeMake(self.width, self.titleFont);
            NSDictionary * attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:self.titleFont] };
            size = [title boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
            
            UIView * view=[[UIView alloc] init];
            [self addSubview:view];
            if (leftPos+size.width+20<=self.width) {
                view.frame=CGRectMake(leftPos, line*30, size.width+20, 25);
            }else
            {
                line++;
                leftPos=0;
                view.frame=CGRectMake(0, line*30, size.width+20, 25);
            }
            if (self.contentBackgroundColor) {
                view.backgroundColor=self.contentBackgroundColor;
            }else
            {
                view.backgroundColor=[UIColor whiteColor];
            }
            
            view.layer.borderWidth=1;
            view.layer.borderColor=self.borderColor.CGColor;
            view.layer.masksToBounds=YES;
            view.layer.cornerRadius=3.0f;
            UITapGestureRecognizer * tapGes=[[UITapGestureRecognizer alloc] init];
            [tapGes addTarget:self action:@selector(tapGes:)];
            [view addGestureRecognizer:tapGes];
            view.tag=5000+i;
            
            UILabel * label=[[UILabel alloc] init];
            [view addSubview:label];
            [label mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(@8);
                make.top.equalTo(@6.5);
                make.bottom.equalTo(@-6.5);
                make.right.equalTo(@-8);
            }];
            label.text=title;
            
            label.font=[UIFont systemFontOfSize:self.titleFont];
            if (i == self.dataArr.count-1 && self.lastTitleColor) {
                label.textColor=self.lastTitleColor;
            }else
            {
                label.textColor=self.titleColor;
            }
            
            label.textAlignment=NSTextAlignmentCenter;
            leftPos=leftPos+size.width+20;
        }
        
        
    }
    
    if (line==0) {
        self.height=(line+1)*25;
    }else
    {
        self.height=(line+1)*25+5*line;
    }
}

- (void)tapGes:(UITapGestureRecognizer *)ges
{
    if ([self.delegate respondsToSelector:@selector(TagScroViewDidSelected:andTagIndex:)]) {
        [self.delegate TagScroViewDidSelected:self andTagIndex:ges.view.tag-5000];
    }
    
}

- (void)addTag:(NSString *)tag
{
    if (tag.length>0) {
        if (self.leftPos!=0) {
            self.leftPos=self.leftPos+5;
        }
        NSString * title=tag;
        CGSize size = CGSizeMake(self.width, 12);
        NSDictionary * attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12] };
        size = [title boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
        
        UIView * view=[[UIView alloc] init];
        [self addSubview:view];
        if (self.leftPos+size.width+20<=self.width) {
            view.frame=CGRectMake(self.leftPos, self.line*30, size.width+20, 25);
        }else
        {
            self.line++;
            self.leftPos=0;
            view.frame=CGRectMake(0, self.line*30, size.width+20, 25);
        }
        view.backgroundColor=[UIColor whiteColor];
        view.layer.borderWidth=1;
        view.layer.borderColor=[UIColor colorWithRed:0.68f green:0.82f blue:0.92f alpha:1.00f].CGColor;
        view.layer.masksToBounds=YES;
        view.layer.cornerRadius=3.0f;
        
        UITapGestureRecognizer * tapGes=[[UITapGestureRecognizer alloc] init];
        [tapGes addTarget:self action:@selector(tapGes:)];
        [view addGestureRecognizer:tapGes];
        view.tag=self.i;
        
        UILabel * label=[[UILabel alloc] init];
        [view addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@8);
            make.top.equalTo(@6.5);
            make.bottom.equalTo(@-6.5);
            make.right.equalTo(@-8);
        }];
        label.text=title;
        label.font=[UIFont systemFontOfSize:12];
        label.textColor=[UIColor colorWithRed:0.18f green:0.67f blue:0.88f alpha:1.00f];
        label.textAlignment=NSTextAlignmentCenter;
        self.leftPos=self.leftPos+size.width+20;
    }

    
    if (self.line==0) {
        self.height=(self.line+1)*25;
    }else
    {
        self.height=(self.line+1)*25+5*self.line;
    }
    [self.selectDict setObject:@"" forKey:[NSString stringWithFormat:@"%d",self.i-5000]];
    if (self.isAdd) {
        [self.selectDataArr addObject:[NSString stringWithFormat:@"add_%d",self.i-5000]];
    }else
    {
        [self.selectDataArr addObject:[NSString stringWithFormat:@"com_%d",self.i-5000]];
    }
    self.i++;
}
- (void)setTagSelected:(int)index
{
    UIView * tagView=[self viewWithTag:index+5000];
    tagView.layer.borderColor=[UIColor colorWithRed:0.68f green:0.82f blue:0.92f alpha:1.00f].CGColor;
    UILabel * label=tagView.subviews[0];
    label.textColor=[UIColor colorWithRed:0.18f green:0.67f blue:0.88f alpha:1.00f];
}
- (void)tagClick:(NSInteger)index isSelect:(BOOL)isSelect
{
    if (self.isSelected) {
        if (isSelect) {
            UIView * tagView=[self viewWithTag:index+5000];
            tagView.layer.borderColor=[UIColor colorWithRed:0.68f green:0.82f blue:0.92f alpha:1.00f].CGColor;
            UILabel * label=tagView.subviews[0];
            label.textColor=[UIColor colorWithRed:0.18f green:0.67f blue:0.88f alpha:1.00f];
            [self.selectDict setObject:@"" forKey:[NSString stringWithFormat:@"%ld",tagView.tag-5000]];
            if (self.isAdd) {
                [self.selectDataArr addObject:[NSString stringWithFormat:@"add_%ld",tagView.tag-5000]];
            }else
            {
                [self.selectDataArr addObject:[NSString stringWithFormat:@"com_%ld",tagView.tag-5000]];
            }
        }else
        {
            UIView * tagView=[self viewWithTag:index+5000];
            tagView.layer.borderColor=[UIColor colorWithHexString:@"#000000" alpha:0.15].CGColor;
            UILabel * label=tagView.subviews[0];
            label.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.5];
            [self.selectDict removeObjectForKey:[NSString stringWithFormat:@"%ld",tagView.tag-5000]];
            if (self.isAdd) {
                [self.selectDataArr removeObject:[NSString stringWithFormat:@"add_%ld",tagView.tag-5000]];
            }else
            {
                [self.selectDataArr removeObject:[NSString stringWithFormat:@"com_%ld",tagView.tag-5000]];
            }
        }
    }
}
@end
