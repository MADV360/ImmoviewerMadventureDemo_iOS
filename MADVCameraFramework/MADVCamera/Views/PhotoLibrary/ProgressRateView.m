//
//  ProgressRateView.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/7/28.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "ProgressRateView.h"
#import "Masonry.h"
#import "NSString+Extensions.h"

@interface ProgressRateView()
@property(nonatomic,weak)UIView * rateView;
@property(nonatomic,weak)UILabel * rateLabel;
@property(nonatomic,weak)UILabel * finishLabel;


@end

@implementation ProgressRateView

- (void)loadProgressRateView
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadError:) name:UPLOAD_ERROR object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadSuccess:) name:UPLOAD_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadTime_outError:) name:TIME_OUT object:nil];

//    self.closeBtn=closeBtn;
    
    UIView * uploadView=[[UIView alloc] init];
    [self addSubview:uploadView];
    if (self.isUsedAsEncoder) {
        [uploadView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@10);
            make.right.equalTo(@-10);
            make.bottom.equalTo(@-10);
            make.height.equalTo(@100);
        }];
    }
    
    uploadView.backgroundColor=[UIColor colorWithHexString:@"#F7F7F7"];
    uploadView.layer.masksToBounds=YES;
    uploadView.layer.cornerRadius=5;
    self.uploadView=uploadView;
    
    
    
    
    UIView * rateBackView=[[UIView alloc] init];
    [uploadView addSubview:rateBackView];
    [rateBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@20);
        make.right.equalTo(@-20);
        make.top.equalTo(@53);
        make.height.equalTo(@5);
    }];
    rateBackView.layer.masksToBounds=YES;
    rateBackView.layer.cornerRadius=2;
    rateBackView.backgroundColor=[UIColor colorWithRed:0.88f green:0.88f blue:0.88f alpha:1.00f];
    
    
    
    UIView * rateView=[[UIView alloc] init];
    rateView.clipsToBounds=YES;
    [rateBackView addSubview:rateView];
    [rateView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.width.equalTo(@0);
        make.bottom.equalTo(@0);
    }];
    rateView.backgroundColor=[UIColor whiteColor];
    rateView.backgroundColor=[UIColor colorWithRed:0.20f green:0.71f blue:1.00f alpha:1.00f];
    
    self.rateView=rateView;
    
    UILabel * rateTagLabel=[[UILabel alloc] init];
    [uploadView addSubview:rateTagLabel];
//    [rateTagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(rateView.mas_top).offset(-15);
//        make.left.equalTo(rateBackView.mas_left);
//        make.height.equalTo(@15);
//        make.width.equalTo(@70);
//    }];
    rateTagLabel.frame = CGRectMake(20, 23, 70, 15);
    rateTagLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.6];
    rateTagLabel.font=[UIFont systemFontOfSize:15];
    if (self.isUsedAsEncoder) {
        rateTagLabel.text=FGGetStringWithKeyFromTable(TRANSCODING, nil);
    }else
    {
        
        rateTagLabel.attributedText= [[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(MEDIAUPLOADING, nil)];
    }
    [rateTagLabel sizeToFit];
    
    
    UIView * rateLineView=[[UIView alloc] init];
    [uploadView addSubview:rateLineView];
    [rateLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(rateTagLabel.mas_right).offset(6);
        make.top.equalTo(rateTagLabel.mas_top);
        make.bottom.equalTo(rateTagLabel.mas_bottom);
        make.width.equalTo(@1);
    }];
    rateLineView.backgroundColor=[UIColor colorWithRed:0.75f green:0.75f blue:0.75f alpha:1.00f];
    
    UILabel * rateLabel=[[UILabel alloc] init];
    [uploadView addSubview:rateLabel];
    [rateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(rateTagLabel.mas_centerY);
        make.left.equalTo(rateLineView.mas_right).offset(6);
        make.right.equalTo(@100);
        make.height.equalTo(@20);
    }];
    rateLabel.textColor=[UIColor colorWithHexString:@"#33AAFF"];
    rateLabel.font=[UIFont systemFontOfSize:15];
    rateLabel.text=@"0%";
    self.rateLabel=rateLabel;
    
    
    
    
    
    
    UILabel * agreementLabel=[[UILabel alloc] init];
    [uploadView addSubview:agreementLabel];
//    [agreementLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(rateView.mas_bottom).offset(10);
//        make.centerX.equalTo(self.mas_centerX);
//        make.height.equalTo(@15);
//        make.width.equalTo(@300);
//    }];
    agreementLabel.frame = CGRectMake(20, 68, ScreenWidth - 60, 15);
    agreementLabel.numberOfLines = 0;
    agreementLabel.textColor=[UIColor colorWithHexString:@"#666666"];
    agreementLabel.textAlignment=NSTextAlignmentCenter;
    agreementLabel.font=[UIFont systemFontOfSize:13];
    
    NSString * language = [NSString getAppLanguage];
    NSMutableAttributedString * agreement;
    if ([language isEqualToString:@"en"]) {
        agreement=[[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRIVACYPOLICY, nil)];
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRIVACYPOLICY, nil).length - 31, 31)];
        [agreement addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRIVACYPOLICY, nil).length - 31, 31)];
    }else if ([language isEqualToString:@"zh-Hans"])
    {
        agreement=[[NSMutableAttributedString alloc] initWithString: FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRO, nil)];
        
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRO, nil).length - FGGetStringWithKeyFromTable(USERPROTOCOL, nil).length-6, FGGetStringWithKeyFromTable(USERPROTOCOL, nil).length+6)];
        [agreement addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRO, nil).length - FGGetStringWithKeyFromTable(USERPROTOCOL, nil).length-6, FGGetStringWithKeyFromTable(USERPROTOCOL, nil).length+6)];
    }else if ([language hasPrefix:@"id"])
    {
        agreement=[[NSMutableAttributedString alloc] initWithString: @"Jika Anda memublikasikan konten, Anda akan dipertimbangkan telah menyetujui semua persyaratan Kebijakan Privasi Mi Sphere Camera"];
        
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(@"Jika Anda memublikasikan konten, Anda akan dipertimbangkan telah menyetujui semua persyaratan Kebijakan Privasi Mi Sphere Camera".length - 34, 34)];
        [agreement addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(@"Jika Anda memublikasikan konten, Anda akan dipertimbangkan telah menyetujui semua persyaratan Kebijakan Privasi Mi Sphere Camera".length - 34, 34)];
    }else if ([language isEqualToString:@"es"])
    {
        agreement=[[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRO, nil)];
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRO, nil).length - 39, 39)];
        [agreement addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRO, nil).length - 39, 39)];
    }else if ([language isEqualToString:@"ru"])
    {
        agreement=[[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRO, nil)];
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRO, nil).length - 46, 46)];
        [agreement addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRO, nil).length - 46, 46)];
    }else if ([language isEqualToString:@"ar"])
    {
        agreement=[[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRIVACYPOLICY, nil)];
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRIVACYPOLICY, nil).length - 31, 31)];
        [agreement addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRIVACYPOLICY, nil).length - 31, 31)];
    }
    else
    {
        agreement=[[NSMutableAttributedString alloc] initWithString:FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRIVACYPOLICY, nil)];
        
        [agreement addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRO, nil).length - FGGetStringWithKeyFromTable(PRIVACYPOLICY, nil).length-6, FGGetStringWithKeyFromTable(PRIVACYPOLICY, nil).length+6)];
        [agreement addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(FGGetStringWithKeyFromTable(UPLOADAGREEMJXJPRO, nil).length - FGGetStringWithKeyFromTable(PRIVACYPOLICY, nil).length-6, FGGetStringWithKeyFromTable(PRIVACYPOLICY, nil).length+6)];
    }
    
    agreementLabel.attributedText=agreement;
    agreementLabel.userInteractionEnabled=YES;
    [agreementLabel sizeToFit];
    if (!self.isUsedAsEncoder) {
        [uploadView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@10);
            make.right.equalTo(@-10);
            make.bottom.equalTo(@-10);
            make.height.equalTo(@(150 - 15 + agreementLabel.height));
        }];
    }
    
    
    NSLog(@"+++++++++++++++++%f",agreementLabel.height);
    UITapGestureRecognizer * agreementTapGes=[[UITapGestureRecognizer alloc] init];
    [agreementTapGes addTarget:self action:@selector(agreementTapGes:)];
    [agreementLabel addGestureRecognizer:agreementTapGes];
    
    
    
    if (!self.isUsedAsEncoder) {
        UIButton * closeBtn=[[UIButton alloc] init];
        [uploadView addSubview:closeBtn];
        [closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.height.equalTo(@50);
        }];
        closeBtn.backgroundColor=[UIColor colorWithHexString:@"#F2F2F2"];
        [closeBtn setTitle:FGGetStringWithKeyFromTable(NOUPLOAD, nil) forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor colorWithHexString:@"#000000" alpha:0.7] forState:UIControlStateNormal];
        closeBtn.titleLabel.font=[UIFont systemFontOfSize:15];
        [closeBtn addTarget:self action:@selector(closeBtn:) forControlEvents:UIControlEventTouchUpInside];
        UIView * closeLineView=[[UIView alloc] init];
        [uploadView addSubview:closeLineView];
        [closeLineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.bottom.equalTo(closeBtn.mas_top);
            make.height.equalTo(@1);
        }];
        closeLineView.backgroundColor=[UIColor colorWithHexString:@"#000000" alpha:0.2];
    }
    
    
    
    
    
    UIView * finishView=[[UIView alloc] init];
    [self addSubview:finishView];
    [finishView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@-10);
        make.left.equalTo(@10);
        make.right.equalTo(@-10);
        make.height.equalTo(@200);
    }];
    finishView.backgroundColor=[UIColor colorWithHexString:@"#F7F7F7"];
    finishView.layer.masksToBounds=YES;
    finishView.layer.cornerRadius=5;
    finishView.hidden=YES;
    self.finishView=finishView;
    
    UIView * finishMidLineView = [[UIView alloc] init];
    [finishView addSubview:finishMidLineView];
    [finishMidLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@0);
        make.centerX.equalTo(finishView.mas_centerX);
        make.height.equalTo(@50);
        make.width.equalTo(@1);
    }];
    finishMidLineView.backgroundColor=[UIColor colorWithHexString:@"#000000" alpha:0.2];
    
    UIButton * finishBtn=[[UIButton alloc] init];
    [finishView addSubview:finishBtn];
    [finishBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(finishMidLineView.mas_left);
        make.height.equalTo(@50);
    }];
    finishBtn.backgroundColor=[UIColor colorWithHexString:@"#F2F2F2"];
    [finishBtn setTitle:FGGetStringWithKeyFromTable(FINISH, nil) forState:UIControlStateNormal];
    [finishBtn setTitleColor:[UIColor colorWithHexString:@"#000000" alpha:0.7] forState:UIControlStateNormal];
    finishBtn.titleLabel.font=[UIFont systemFontOfSize:15];
    finishBtn.tag=5000+0;
    [finishBtn addTarget:self action:@selector(finishBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton * backCmaeraBtn=[[UIButton alloc] init];
    [finishView addSubview:backCmaeraBtn];
    [backCmaeraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(finishMidLineView.mas_right);
        make.right.equalTo(@0);
        make.bottom.equalTo(@0);
        make.height.equalTo(@50);
    }];
    backCmaeraBtn.backgroundColor=[UIColor colorWithHexString:@"#F2F2F2"];
    if (self.isEdit || self.isScreencap) {
        [backCmaeraBtn setTitle:FGGetStringWithKeyFromTable(FINISHANDSHARE, nil) forState:UIControlStateNormal];
    }else
    {
        [backCmaeraBtn setTitle:FGGetStringWithKeyFromTable(BACKCAMAER, nil) forState:UIControlStateNormal];
    }
    
    [backCmaeraBtn setTitleColor:[UIColor colorWithHexString:@"#000000" alpha:0.7] forState:UIControlStateNormal];
    backCmaeraBtn.titleLabel.font=[UIFont systemFontOfSize:15];
    backCmaeraBtn.tag=5000+1;
    [backCmaeraBtn addTarget:self action:@selector(finishBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    UIView * finishLineView=[[UIView alloc] init];
    [finishView addSubview:finishLineView];
    [finishLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(finishBtn.mas_top);
        make.height.equalTo(@1);
    }];
    finishLineView.backgroundColor=[UIColor colorWithHexString:@"#000000" alpha:0.2];
    
    UIImageView * finishImageView=[[UIImageView alloc] init];
    [finishView addSubview:finishImageView];
    [finishImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(finishBtn.mas_top).offset(-30);
        make.centerX.equalTo(finishView.mas_centerX);
        make.width.equalTo(@50);
        make.height.equalTo(@50);
    }];
    finishImageView.image=[UIImage imageNamed:@"complete.png"];
    
    UILabel * finishLabel=[[UILabel alloc] init];
    [finishView addSubview:finishLabel];
    finishLabel.frame = CGRectMake(10, 200 -151 -15, ScreenWidth - 40, 15);
//    [finishLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(finishImageView.mas_top).offset(-20);
//        make.centerX.equalTo(finishView.mas_centerX);
//        make.height.equalTo(@15);
//        make.width.equalTo(@250);
//    }];
    finishLabel.numberOfLines = 0;
    finishLabel.textAlignment=NSTextAlignmentCenter;
    finishLabel.font=[UIFont systemFontOfSize:15];
    finishLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.9];
    
    if (self.isEdit) {
        finishLabel.text=FGGetStringWithKeyFromTable(SAVESUC, nil);
    }else
    {
        if (self.isScreencap) {
            finishLabel.text=FGGetStringWithKeyFromTable(SCREENCAPSUC, nil);
        }else
        {
            finishLabel.text=FGGetStringWithKeyFromTable(UPLOADSUC, nil);
        }
        
    }
    [finishLabel sizeToFit];
    self.finishLabel = finishLabel;
    if (self.finishLabel.width < self.width - 40) {
        self.finishLabel.x = (self.width - 20)*0.5 - self.finishLabel.width * 0.5;
    }
    self.finishLabel.y = 200 -151 - self.finishLabel.height;
    
    if (self.finishLabel.y <= 0) {
        self.finishLabel.y = 5;
    }

    
    
    
}

#pragma mark --关闭--
- (void)closeBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(progressRateViewaClose:)]) {
        [self.delegate progressRateViewaClose:self];
    }
}

#pragma mark --用户协议--
- (void)agreementTapGes:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(progressRateViewaGreementDidClick:)]) {
        [self.delegate progressRateViewaGreementDidClick:self];
    }
}
#pragma mark --改变上传进度--
- (void)updateRate:(CGFloat)rate
{
    if (_rate==rate) {
        self.rateView.width=rate*(ScreenWidth-60)/100;
    }else
    {
        _rate = rate;
        if (rate!=100) {
            NSString * rateStr=[NSString stringWithFormat:@"%d%@",(int)rate,@"%"];
            self.rateLabel.text=rateStr;
            [UIView animateWithDuration:0.5 animations:^{
                self.rateView.width=rate*(ScreenWidth-60)/100;
            }];
        }else{
            //分享
            
            self.rateLabel.text=FGGetStringWithKeyFromTable(PROCESSING, nil);
            [UIView animateWithDuration:0.5 animations:^{
                self.rateView.width=rate*(ScreenWidth-60)/100;
            }];
        }
    }
    
}

#pragma mark --上传失败--
- (void)uploadError:(NSNotification *)not
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(progressRateViewUploadError:)]) {
            self.errorType = Error_Upload;
            [self.delegate progressRateViewUploadError:self];
        }
    });
    
}
#pragma mark --上传超时--
- (void)uploadTime_outError:(NSNotification *)not
{
    dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(progressRateViewUploadError:)]) {
                       self.errorType = Error_UploadTimeOut;
                    [self.delegate progressRateViewUploadError:self];
                }
        });
}
#pragma mark --上传成功--
- (void)uploadSuccess:(NSNotification *)not
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString * name=not.object;
        if ([self.fileName isEqualToString:name]) {
            if ([self.delegate respondsToSelector:@selector(progressRateViewUploadSuc:)]) {
                [self.delegate progressRateViewUploadSuc:self];
            }
//            self.uploadView.hidden=YES;
//            self.finishView.hidden=NO;
//            if ([self.delegate respondsToSelector:@selector(progressRateViewaStartShare:)]) {
//                [self.delegate progressRateViewaStartShare:self];
//            }
        }
    });
    
    
}

- (void)caprefresh
{
    self.finishLabel.frame = CGRectMake(15, 200 -151 -15, self.width - 50, 15);
    [self.finishLabel sizeToFit];
    if (self.finishLabel.width < self.width - 50) {
        self.finishLabel.x = (self.width - 20)*0.5 - self.finishLabel.width * 0.5;
    }
    self.finishLabel.y = 200 -151 - self.finishLabel.height;
    if (self.finishLabel.y <= 0) {
        self.finishLabel.y = 5;
    }

}

#pragma mark --上传完成--
- (void)finishBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(progressRateViewaDidFinish:index:)]) {
        [self.delegate progressRateViewaDidFinish:self index:btn.tag];
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
