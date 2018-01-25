//
//  AppDelegate.m
//  ImmoviewerMADVentureDemo
//
//  Created by QiuDong on 2018/1/24.
//  Copyright © 2018年 QiuDong. All rights reserved.
//

#import "AppDelegate.h"
#import <MVMediaManager.h>

NSString* kNotificationDownloadedListUpdated = @"NSString* kNotificationDownloadedListUpdated";

NSMutableArray<NSString* >* g_downloadedFileNames = nil;

@interface AppDelegate () <MVMediaDataSourceObserver, MVMediaDownloadStatusObserver>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    g_downloadedFileNames = [[NSMutableArray alloc] init];
    
    MVMediaManager* mediaManager = [MVMediaManager sharedInstance];
    mediaManager.downloadMediasIntoDocuments = YES;// :This is necessary
    // Add as observer for media manager:
    [mediaManager addMediaDataSourceObserver:self];
    [mediaManager addMediaDownloadStatusObserver:self];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark    MVMediaDataSourceObserver

-(void)didCameraMediasReloaded:(NSArray<MVMedia *> *) medias dataSetEvent:(DataSetEvent)dataSetEvent errorCode:(int)errorCode {
    if (dataSetEvent == DataSetEventAddNew)
    {// As new picture file(s) generated by the camera, immediately start downloading:
        [[MVMediaManager sharedInstance] addDownloadingOfMedias:medias completion:^{
            NSLog(@"Batch downloading done");
        } progressBlock:^(int completedCount, int totalCount, BOOL *cancel) {
            NSLog(@"Batch downloading progress : %d/%d", completedCount, totalCount);
        }];
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
    if (!errorCode && downloadStatus == MVMediaDownloadStatusFinished)
    {// When a media file has been successfully downloaded, get its local file name(relative to sandbox document directory) from this callback:
        NSLog(@"Media downloaded, localPath = %@", media.localPath);
        [g_downloadedFileNames addObject:media.localPath];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDownloadedListUpdated object:g_downloadedFileNames];
    }
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
