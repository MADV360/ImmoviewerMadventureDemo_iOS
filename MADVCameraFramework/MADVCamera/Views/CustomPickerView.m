//
//  CustomPickerView.m
//  eCamera
//
//  Created by wsg on 2017/4/18.
//  Copyright © 2017年 wsg. All rights reserved.
//

#import "CustomPickerView.h"

#define itemHeight 50
@interface CustomPickerView ()<UIPickerViewDelegate,UIPickerViewDataSource>

@end

@implementation CustomPickerView{
    UIPickerView *picker;
    NSArray *dataArray;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self performSelector:@selector(initPickerView)];
    }
    return self;
}
/**
 *  初始化 选择器
 */
-(void)initPickerView{
    CGAffineTransform rotate = CGAffineTransformMakeRotation(-M_PI/2);
    rotate = CGAffineTransformScale(rotate, 0.1, 1);
    //旋转 -π/2角度
    picker = [[UIPickerView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.height*10, self.frame.size.width)];
    
    [picker setTag: 10086];
    picker.delegate = self;
    picker.dataSource = self;
    picker.showsSelectionIndicator = false;
    [picker setBackgroundColor:[UIColor clearColor]];
    
    UIImageView *imageV = [[UIImageView alloc]initWithFrame:CGRectMake(self.frame.size.width/2-2.5, (self.frame.size.height- 60)/2, 5, 10)];
    imageV.image = [UIImage imageNamed:@"adjust_point.png"];
    UIView *bgV = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width,self.frame.size.height)];
    [bgV addSubview:picker];
    [bgV addSubview:imageV];
    [self addSubview:bgV];
    [picker setTransform:rotate];
    picker.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    
}
/**
 *  pickerView代理方法
 *
 *  @param component
 *
 *  @return pickerView有多少个元素
 */
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return self.dataModel.count;
}
/**
 *  pickerView代理方法
 *
 *  @return pickerView 有多少列
 */
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}
/**
 *  pickerView代理方法
 *
 *  @param row
 *  @param component
 *  @param view
 *
 *  @return 每个 item 显示的 视图
 */
-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    
    if ([self.delegate respondsToSelector:@selector(pickerViewBeginScroll)]) {
        [self.delegate pickerViewBeginScroll];
    }
    
    CGAffineTransform rotateItem = CGAffineTransformMakeRotation(M_PI/2);
    rotateItem = CGAffineTransformScale(rotateItem, 1, 10);
    CGFloat width = 30;
    if (self.pickerType == ShutterSetting) {
        width = 60;
    }
    UIView *itemView = [[UIView alloc]initWithFrame:CGRectMake(20, 0, width, 50)];
    UIView * circleView = [[UIView alloc]initWithFrame:CGRectMake(width/2-1.5, (self.frame.size.height -20)/2, 3, 3)];
    circleView.layer.masksToBounds = YES;
    circleView.layer.cornerRadius = 1.5;
    circleView.backgroundColor = [UIColor whiteColor];
    [itemView addSubview:circleView];
    
    UILabel * titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake(0, (self.frame.size.height -20)/2 + 6,width, 20);
    titleLabel.font = [UIFont systemFontOfSize:13];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = self.dataModel[row];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [itemView addSubview:titleLabel];

    itemView.transform = rotateItem;
    return itemView;
}

/**
 *  pickerVie代理方法
 *
 *  @param component
 *
 *  @return 每个item的宽度
 */
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component __TVOS_PROHIBITED{
    if (self.pickerType == ShutterSetting) {
        return self.frame.size.height+60;
    }
    return self.frame.size.height+30;
    
}
/**
 *  pickerView代理方法
 *
 *  @param component
 *
 *  @return 每个item的高度
 */
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    if (self.pickerType == ShutterSetting) {
        return self.frame.size.height + 20;
    }else
    {
        return self.frame.size.height;
    }
    
}


/**
 *  pickerView滑动到指定位置
 *
 *  @param scrollToIndex 指定位置
 */
-(void)scrollToIndex:(NSInteger)scrollToIndex{
    [picker selectRow:scrollToIndex inComponent:0 animated:true];
}
/**
 *  查询当前选择元素Getter方法
 *
 *  @return pickerView当前选择元素 （index：选择位置  name：元素名称）
 */
-(NSDictionary *)selectedItem{
    NSInteger index = [picker selectedRowInComponent:0];
    NSString *contaxt = dataArray[index];
    return @{@"name":contaxt,@"index":[NSString stringWithFormat:@"%ld",index]};
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if ([self.delegate respondsToSelector:@selector(pickerView:didSelectRow:)]) {
        [self.delegate pickerView:pickerView didSelectRow:row];
    }
}

- (void)refresh
{
    [picker reloadAllComponents];
}
- (void)setIsEnabled:(BOOL)isEnabled
{
    _isEnabled = isEnabled;
    picker.userInteractionEnabled = isEnabled;
}

@end
