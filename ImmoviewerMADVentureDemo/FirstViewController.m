//
//  FirstViewController.m
//  ImmoviewerMADVentureDemo
//
//  Created by QiuDong on 2018/1/24.
//  Copyright © 2018年 QiuDong. All rights reserved.
//

#import "FirstViewController.h"
#import <MVCameraClient.h>

@interface FirstViewController () <MVCameraClientObserver>

@property (nonatomic, strong) IBOutlet UIButton* connectButton;
@property (nonatomic, strong) IBOutlet UIButton* shootButton;
@property (nonatomic, strong) IBOutlet UISwitch* bracketingSwitch;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.connectButton.tag = 0;
    
    [[MVCameraClient sharedInstance] addObserver:self];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UI Events

-(IBAction)connectButtonClicked:(id)sender {
    if (0 == self.connectButton.tag)
    {
        self.connectButton.enabled = NO;
        [[MVCameraClient sharedInstance] connectCamera];
    }
    else
    {
        [[MVCameraClient sharedInstance] disconnectCamera];
    }
}

-(IBAction)shootButtonClicked:(id)sender {
    [[MVCameraClient sharedInstance] startShooting];
}

-(IBAction)switchValueChanged:(id)sender {
    if (self.bracketingSwitch.on)
    {
        [[MVCameraClient sharedInstance] setCameraMode:CameraModePhoto subMode:CameraSubmodePhotoSurroundExp param:0];
    }
    else
    {
        [[MVCameraClient sharedInstance] setCameraMode:CameraModePhoto subMode:CameraSubmodePhotoNormal param:0];
    }
}

#pragma mark MVCameraClientObserver

-(void) didConnectSuccess:(MVCameraDevice *)device {
    self.connectButton.enabled = YES;
    self.connectButton.tag = 1;
    [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    
    self.shootButton.hidden = NO;
    self.bracketingSwitch.hidden = NO;
    
    //[self switchValueChanged:self.bracketingSwitch];
}

-(void) didConnectFail:(NSString *)errorMessage {
    self.connectButton.enabled = YES;
}

-(void) didDisconnect:(CameraDisconnectReason)reason {
    self.connectButton.enabled = YES;
    self.connectButton.tag = 0;
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    
    self.shootButton.hidden = YES;
    self.bracketingSwitch.hidden = YES;
}

-(void) didCameraModeChange:(CameraMode)mode subMode:(CameraSubMode)subMode param:(NSInteger)param {
    if (self.bracketingSwitch.on)
    {
        if (mode != CameraModePhoto)
        {
            [[MVCameraClient sharedInstance] setCameraMode:CameraModePhoto subMode:CameraSubmodePhotoSurroundExp param:0];
        }
        else if (subMode != CameraSubmodePhotoSurroundExp)
        {
            [[MVCameraClient sharedInstance] setCameraMode:CameraModePhoto subMode:CameraSubmodePhotoSurroundExp param:6];
        }
        else if (param != 6)
        {
            [[MVCameraClient sharedInstance] setCameraMode:CameraModePhoto subMode:CameraSubmodePhotoSurroundExp param:6];
        }
    }
    else if (mode != CameraModePhoto)
    {
        [[MVCameraClient sharedInstance] setCameraMode:CameraModePhoto subMode:CameraSubmodePhotoNormal param:0];
    }
}

@end
