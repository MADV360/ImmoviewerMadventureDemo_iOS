//
//  SecondViewController.m
//  ImmoviewerMADVentureDemo
//
//  Created by QiuDong on 2018/1/24.
//  Copyright © 2018年 QiuDong. All rights reserved.
//

#import "SecondViewController.h"
#import <MVMediaManager.h>
#import <MVGLView.h>

@interface SecondViewController () <MVMediaDataSourceObserver, MVMediaDownloadStatusObserver>

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[MVMediaManager sharedInstance] addMediaDataSourceObserver:self];
    [[MVMediaManager sharedInstance] addMediaDownloadStatusObserver:self];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark    MVMediaDataSourceObserver

-(void)didCameraMediasReloaded:(NSArray<MVMedia *> *) medias dataSetEvent:(DataSetEvent)dataSetEvent errorCode:(int)errorCode {
    if (dataSetEvent == DataSetEventAddNew)
    {
        
    }
}

-(void) didLocalMediasReloaded:(NSArray<MVMedia *> *) medias dataSetEvent:(DataSetEvent)dataSetEvent {
    
}

-(void)didFetchThumbnailImage:(UIImage *)image ofMedia:(MVMedia*)media error:(int)error {
    
}

-(void)didFetchMediaInfo:(MVMedia *)media error:(int)error {
    
}

- (void) didFetchRecentMediaThumbnail:(MVMedia*)media image:(UIImage*)image error:(int)error {
    
}

#pragma mark    MVMediaDownloadStatusObserver

- (void) didDownloadStatusChange:(int)downloadStatus errorCode:(int)errorCode ofMedia:(MVMedia*)media {
    
}

- (void) didDownloadProgressChange:(NSInteger)downloadedBytes totalBytes:(NSInteger)totalBytes ofMedia:(MVMedia*)media {
    
}

- (void) didBatchDownloadStatusChange:(int)downloadStatus ofMedias:(NSArray<MVMedia *>*)medias {
    
}

- (void) didDownloadingsHung {
    
}

- (void) didReceiveStorageWarning {
    
}

@end
