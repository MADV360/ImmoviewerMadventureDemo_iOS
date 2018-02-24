//
//  CameraDeviceCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/22.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "CameraDeviceCell.h"
#import "Masonry.h"

@interface CameraDeviceCell()
@property(nonatomic,weak)UILabel * ssidLabel;
@property(nonatomic,weak)UILabel * decLabel;
@property(nonatomic,weak)UIImageView * wifiImageView;
@property(nonatomic,weak)UIActivityIndicatorView * activityView;
@end

@implementation CameraDeviceCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UIImageView * iconImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:iconImageView];
        [iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@25);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.equalTo(@53);
            make.height.equalTo(@46);
        }];
        iconImageView.image=[UIImage imageNamed:@"madv_icon.png"];
        
        UILabel * ssidLabel=[[UILabel alloc] init];
        [self.contentView addSubview:ssidLabel];
        [ssidLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_centerY).offset(-5);
            make.left.equalTo(iconImageView.mas_right).offset(15);
            make.width.equalTo(@150);
            make.height.equalTo(@16);
        }];
        ssidLabel.font=[UIFont systemFontOfSize:16];
        ssidLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.9];
        self.ssidLabel=ssidLabel;
        
        UILabel * decLabel=[[UILabel alloc] init];
        [self.contentView addSubview:decLabel];
//        [decLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(self.contentView.mas_centerY).offset(5);
//            make.left.equalTo(ssidLabel.mas_left);
//            make.width.equalTo(@200);
//            make.height.equalTo(@13);
//        }];
        decLabel.numberOfLines = 0;
        decLabel.frame = CGRectMake(93, 10, ScreenWidth - 50 - 93, 13);
        decLabel.y = self.contentView.center.y + 5;
        decLabel.font=[UIFont systemFontOfSize:13];
        decLabel.textColor=[UIColor colorWithHexString:@"#000000" alpha:0.5];
        self.decLabel=decLabel;
        
        UIImageView * wifiImageView=[[UIImageView alloc] init];
        [self.contentView addSubview:wifiImageView];
        [wifiImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-25);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@12);
            make.width.equalTo(@18);
        }];
        self.wifiImageView=wifiImageView;
        
        UIActivityIndicatorView * activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:activityView];
        [activityView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-25);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@18);
            make.width.equalTo(@18);
        }];
        activityView.hidden=YES;
        self.activityView=activityView;
        
        
        
    }
    return self;
}

- (void)setCameraDevice:(MVCameraDevice *)cameraDevice
{//Rounded_selected
    _cameraDevice=cameraDevice;
    self.ssidLabel.text=cameraDevice.SSID;
    if (cameraDevice.isConnect) {
        if (cameraDevice.isCharging) {
            self.decLabel.text=FGGetStringWithKeyFromTable(CHARGEING, nil);
        }else
        {
            //self.decLabel.text=[NSString stringWithFormat:@"剩余电量：%d%@",cameraDevice.voltagePercent,@"%"];
            self.decLabel.text=FGGetStringWithKeyFromTable(CONNECTED, nil);
        }
        
    }else
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy/MM/dd"];
        NSString * lastSyncTime = [dateFormatter stringFromDate:cameraDevice.lastSyncTime];
        self.decLabel.text=[NSString stringWithFormat:@"%@：%@",FGGetStringWithKeyFromTable(LASTCONNECTED, nil),lastSyncTime];
    }
    [self.decLabel sizeToFit];
    self.decLabel.y = 58;
    if (self.decLabel.width <= ScreenWidth - 50 - 93) {
        self.decLabel.width = ScreenWidth - 50 - 93;
    }
    if (cameraDevice.isWifiConnect) {
        self.wifiImageView.image=[UIImage imageNamed:@"wifi.png"];
        if (cameraDevice.isConnecting) {
            self.wifiImageView.hidden=YES;
            self.activityView.hidden=NO;
            [self.activityView startAnimating];
        }else
        {
            self.wifiImageView.hidden=NO;
            [self.activityView stopAnimating];
            self.activityView.hidden=YES;
            
        }
    }else
    {
        self.wifiImageView.hidden=NO;
        self.wifiImageView.image=[UIImage imageNamed:@"wifi-hui.png"];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
