//
//  CustomPickerView.h
//  eCamera
//
//  Created by wsg on 2017/4/18.
//  Copyright © 2017年 wsg. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum : NSInteger {
    ShutterSetting = 0,
    EVSetting = 1,
} PickerType;

@protocol MyPickerViewDelegate <NSObject>

/**
 pickerView选中item代理
 @param row 选中的row
 */
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row;
/** PickerView 开始滚动 */
- (void)pickerViewBeginScroll;
@end

@interface CustomPickerView : UIView

/** PickerView 数据源 */
@property (nonatomic,strong) NSArray *dataModel;
/** 当前选择器选择的元素 （NSDictionary 类型， name：选择元素名称  index：选择元素位置）*/
@property (nonatomic,strong,readonly) NSDictionary *selectedItem;
/** 滑动到指定位置 */
@property (nonatomic,assign,setter=scrollToIndex:) NSInteger scrollToIndex;
/** pickerView代理 */
@property (nonatomic,weak) id<MyPickerViewDelegate> delegate;
@property(nonatomic,assign)PickerType pickerType;
@property(nonatomic,assign)BOOL isEnabled;
- (void)refresh;
@end
