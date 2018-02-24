//
//  SetWifiView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/22.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "SetWifiView.h"
#import "Masonry.h"
#import "MMProgressHUD.h"

@interface SetWifiView()<UITextFieldDelegate>
@property(nonatomic,weak)UITextField * wifiNameTextField;
@property(nonatomic,weak)UITextField * pwdTextField;
@property(nonatomic,weak)UIButton * eyeBtn;
@end

@implementation SetWifiView
- (void)loadSetWifiView
{
    UIImageView * backgroundView=[[UIImageView alloc] init];
    [self addSubview:backgroundView];
    [backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    backgroundView.image=[UIImage imageNamed:@"backimage.png"];
    UIView * backView=[[UIView alloc] init];
    [self addSubview:backView];
    [backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    backView.backgroundColor=[UIColor colorWithHexString:@"#414347" alpha:0.85];
    
    
    UIView * wifiNameView=[[UIView alloc] init];
    [self addSubview:wifiNameView];
    [wifiNameView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_centerY).offset(-10);
        make.left.equalTo(@20);
        make.right.equalTo(@-20);
        make.height.equalTo(@50);
    }];
    wifiNameView.backgroundColor=[UIColor colorWithRed:0.23f green:0.24f blue:0.25f alpha:1.00f];
    wifiNameView.layer.borderWidth=1;
    wifiNameView.layer.borderColor=[UIColor colorWithHexString:@"#FFFFFF" alpha:0.3].CGColor;
    wifiNameView.layer.masksToBounds=YES;
    wifiNameView.layer.cornerRadius=5;
    
    UITextField * wifiNameTextField=[[UITextField alloc] init];
    [wifiNameView addSubview:wifiNameTextField];
    [wifiNameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@10);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    wifiNameTextField.borderStyle=UITextBorderStyleNone;
    wifiNameTextField.keyboardType=UIKeyboardTypeASCIICapable;
    wifiNameTextField.font=[UIFont systemFontOfSize:13];
    wifiNameTextField.textColor=[UIColor colorWithHexString:@"#FFFFFF"];
    wifiNameTextField.delegate=self;
    self.wifiNameTextField=wifiNameTextField;

    
    
    UIView * pwdView=[[UIView alloc] init];
    [self addSubview:pwdView];
    [pwdView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_centerY).offset(10);
        make.left.equalTo(@20);
        make.right.equalTo(@-20);
        make.height.equalTo(@50);
    }];
    pwdView.backgroundColor=[UIColor colorWithRed:0.23f green:0.24f blue:0.25f alpha:1.00f];
    pwdView.layer.borderWidth=1;
    pwdView.layer.borderColor=[UIColor colorWithHexString:@"#FFFFFF" alpha:0.3].CGColor;
    pwdView.layer.masksToBounds=YES;
    pwdView.layer.cornerRadius=5;
    
    UIButton * eyeBtn=[[UIButton alloc] init];
    [pwdView addSubview:eyeBtn];
    [eyeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(pwdView.mas_centerY);
        make.right.equalTo(@-10);
        make.width.equalTo(@15);
        make.height.equalTo(@10);
    }];
    [eyeBtn setBackgroundImage:[UIImage imageNamed:@"eye.png"] forState:UIControlStateNormal];
    [eyeBtn setBackgroundImage:[UIImage imageNamed:@"eyeSelect.png"] forState:UIControlStateSelected];
    self.eyeBtn = eyeBtn;
//    [eyeBtn addTarget:self action:@selector(eyeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIView * eyeView=[[UIView alloc] init];
    [pwdView addSubview:eyeView];
    [eyeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@0);
        make.left.equalTo(eyeBtn.mas_left);
        make.top.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    eyeView.backgroundColor=[UIColor clearColor];
    
    UITapGestureRecognizer * eyeGes=[[UITapGestureRecognizer alloc] init];
    [eyeGes addTarget:self action:@selector(eyeGes:)];
    [eyeView addGestureRecognizer:eyeGes];
    
    UITextField * pwdTextField=[[UITextField alloc] init];
    [pwdView addSubview:pwdTextField];
    [pwdTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@10);
        make.right.equalTo(eyeView.mas_left);
        make.bottom.equalTo(@0);
    }];
    pwdTextField.borderStyle=UITextBorderStyleNone;
    pwdTextField.secureTextEntry=YES;
    pwdTextField.keyboardType=UIKeyboardTypeASCIICapable;
    pwdTextField.font=[UIFont systemFontOfSize:13];
    pwdTextField.placeholder=FGGetStringWithKeyFromTable(WIFIPWD, nil);
    pwdTextField.delegate = self;
    
    // 修改textField的placeholder的字体颜色
    [pwdTextField setValue:[UIColor colorWithHexString:@"#FFFFFF" alpha:0.3] forKeyPath:@"_placeholderLabel.textColor"];
    pwdTextField.textColor=[UIColor colorWithHexString:@"#FFFFFF"];
    self.pwdTextField=pwdTextField;
    
    UILabel * subDescLabel=[[UILabel alloc] init];
    [self addSubview:subDescLabel];
    [subDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(wifiNameView.mas_top).offset(-20);
        make.centerX.equalTo(wifiNameView.mas_centerX);
        make.width.equalTo(@200);
        make.height.equalTo(@13);
    }];
    subDescLabel.font=[UIFont systemFontOfSize:13];
    subDescLabel.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    subDescLabel.textAlignment=NSTextAlignmentCenter;
    subDescLabel.text=FGGetStringWithKeyFromTable(PRESSSAVESET, nil);
    
    UILabel * descLabel=[[UILabel alloc] init];
    [self addSubview:descLabel];
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(subDescLabel.mas_top).offset(-5);
        make.centerX.equalTo(wifiNameView.mas_centerX);
        make.width.equalTo(@300);
        make.height.equalTo(@13);
    }];
    descLabel.font=[UIFont systemFontOfSize:13];
    descLabel.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    descLabel.textAlignment=NSTextAlignmentCenter;
    descLabel.text=FGGetStringWithKeyFromTable(PLEASESETWIFIPWD, nil);
    
    UILabel * titleLabe=[[UILabel alloc] init];
    [self addSubview:titleLabe];
    [titleLabe mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(descLabel.mas_top).offset(-10);
        make.centerX.equalTo(self.mas_centerX);
        make.width.equalTo(@100);
        make.height.equalTo(@20);
    }];
    titleLabe.textAlignment=NSTextAlignmentCenter;
    titleLabe.font=[UIFont systemFontOfSize:20];
    titleLabe.textColor=[UIColor colorWithHexString:@"#F6F6F6"];
    titleLabe.text=FGGetStringWithKeyFromTable(SETWIFI, nil);
    
    UIButton * selectBtn=[[UIButton alloc] init];
    [self addSubview:selectBtn];
    [selectBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@-20);
        make.left.equalTo(@15);
        make.right.equalTo(@-15);
        make.height.equalTo(@44);
    }];
    selectBtn.backgroundColor=[UIColor clearColor];
    selectBtn.layer.borderColor=[UIColor colorWithRed:0.50f green:0.50f blue:0.51f alpha:1.00f].CGColor;
    selectBtn.layer.borderWidth=1;
    selectBtn.layer.masksToBounds=YES;
    selectBtn.layer.cornerRadius=15;
    [selectBtn addTarget:self action:@selector(selectBtn:) forControlEvents:UIControlEventTouchUpInside];
    [selectBtn setTitle:FGGetStringWithKeyFromTable(SAVESETINFO, nil) forState:UIControlStateNormal];
    selectBtn.titleLabel.font=[UIFont systemFontOfSize:15];
    [selectBtn setTitleColor:[UIColor colorWithHexString:@"#FFFFFF" alpha:0.9] forState:UIControlStateNormal];
}

#pragma mark --UITextFieldDelegate代理方法的实现--
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (range.location < 20) {
        if (self.wifiNameTextField==textField) {
            NSString * text = [NSString stringWithFormat:@"%@%@",textField.text,string];
#ifdef NOLIMITWIFI
            if ([text isEqualToString:WIFIHASPREFIX] || [text isEqualToString:LASTWIFIHASPREFIX] || [text isEqualToString:MADVWIFIHASPREFIX]) {
#else
            if ([text isEqualToString:WIFIHASPREFIX] || [text isEqualToString:LASTWIFIHASPREFIX]) {    
#endif
                return NO;
            }
            if (![self isAccord:string]) {
                [UIView animateWithDuration:0 animations:^{
                    [MMProgressHUD showWithStatus:@""];
                } completion:^(BOOL finished) {
                    [MMProgressHUD dismissWithError:FGGetStringWithKeyFromTable(NOSUPPORTCHARTFORMAT, nil)];
                }];
                return NO;
            }
        }else
        {
            if (![self isAccord:string]) {
                [UIView animateWithDuration:0 animations:^{
                    [MMProgressHUD showWithStatus:@""];
                } completion:^(BOOL finished) {
                    [MMProgressHUD dismissWithError:FGGetStringWithKeyFromTable(NOSUPPORTCHARTFORMAT, nil)];
                }];
                return NO;
            }
        }
    }else
    {
        [UIView animateWithDuration:0 animations:^{
            [MMProgressHUD showWithStatus:@""];
        } completion:^(BOOL finished) {
            [MMProgressHUD dismissWithError:FGGetStringWithKeyFromTable(WIFINAMEMORE, nil)];
        }];
        return NO;
    }
    return YES;
}
- (BOOL)isAccord:(NSString *)str
{
    //NSString *regex = @"^[A-Za-z]+[0-9]+[A-Za-z0-9]*|[0-9]+[A-Za-z]+[A-Za-z0-9]*$";
    
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    NSString *mystring = [NSString stringWithString:str];
    NSCharacterSet *disallowedCharacters = [[NSCharacterSet
                                             characterSetWithCharactersInString:@"0123456789QWERTYUIOPLKJHGFDSAZXCVBNMqwertyuioplkjhgfdsazxcvbnm"] invertedSet];
    NSRange foundRange = [mystring rangeOfCharacterFromSet:disallowedCharacters];
    
    if (foundRange.location == NSNotFound || [str isEqualToString:@"-"] || [str isEqualToString:@"_"] || [str isEqualToString:@"#"]) {
        return YES;
    }else
    {
        return NO;
    }
}
- (BOOL)isAccordPWD:(NSString *)str
{
    //NSString *regex = @"^[A-Za-z]+[0-9]+[A-Za-z0-9]*|[0-9]+[A-Za-z]+[A-Za-z0-9]*$";
    
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    NSString *mystring = [NSString stringWithString:str];
    NSCharacterSet *disallowedCharacters = [[NSCharacterSet
                                             characterSetWithCharactersInString:@"0123456789QWERTYUIOPLKJHGFDSAZXCVBNMqwertyuioplkjhgfdsazxcvbnm "] invertedSet];
    NSRange foundRange = [mystring rangeOfCharacterFromSet:disallowedCharacters];
    
    if (foundRange.location == NSNotFound || [str isEqualToString:@"-"] || [str isEqualToString:@"_"] || [str isEqualToString:@"#"]) {
        return YES;
    }else
    {
        return NO;
    }
}
#pragma mark --明文显示按钮--
- (void)eyeGes:(UITapGestureRecognizer *)ges
{
    self.eyeBtn.selected = !self.eyeBtn.selected;
    self.pwdTextField.secureTextEntry = !self.eyeBtn.selected;
}

#pragma mark --保存设置--
- (void)selectBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(setWifiViewDidSet:wifiName:password:)]) {
        [self.delegate setWifiViewDidSet:self wifiName:self.wifiNameTextField.text password:self.pwdTextField.text];
    }
}

- (void)setSsid:(NSString *)ssid
{
    _ssid=ssid;
    self.wifiNameTextField.text=[NSString stringWithFormat:@"  %@",ssid];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.pwdTextField resignFirstResponder];
    [self.wifiNameTextField resignFirstResponder];
}

@end
