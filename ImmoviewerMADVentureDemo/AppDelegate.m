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

#import <MadvGLRenderer.h>
#import <MadvGLRenderer_iOS.h>
#import <MADVPano/JPEGUtils.h>
//#import <MADVPano/MadvGLRendererBase_iOS.h>

void stitchJPEG(NSString* destPath, NSString* sourcePath) {
    jpeg_decompress_struct jpegInfo = readImageInfoFromJPEG(sourcePath.UTF8String);
    /*
     MadvEXIFExtension madvExtension = readMadvEXIFExtensionFromJPEG(sourcePath.UTF8String);
     if (madvExtension.gyroMatrixBytes > 0)
     {
     MadvGLRenderer_iOS::renderJPEGToJPEG(destPath, sourcePath, jpegInfo.image_width, jpegInfo.image_height, NO, &madvExtension, 0, madvExtension.cameraParams.gyroMatrix, 3);
     }
     else
     {
     MadvGLRenderer_iOS::renderJPEGToJPEG(destPath, sourcePath, jpegInfo.image_width, jpegInfo.image_height, NO, &madvExtension, 0, NULL, 0);
     }
     /*/
    GLint sourceTexture = createTextureWithJPEG(sourcePath.UTF8String);
    MadvGLRenderer::renderTextureToJPEG(destPath.UTF8String, jpegInfo.image_width, jpegInfo.image_height, sourceTexture, NULL, 0, NULL, NULL, 0, 180, 90);
    glDeleteTextures(1, (const GLuint*)&sourceTexture);
    glFinish();
    /*/
     MadvGLRenderer::renderMadvJPEGToJPEG(destPath.UTF8String, sourcePath.UTF8String, jpegInfo.image_width, jpegInfo.image_height, NULL, 0, NULL, NULL, 0, 180, 90);
     //*/
}

void testMADVPanoStitching() {
    NSString* documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSFileManager* fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator* enumerator = [fm enumeratorAtPath:documentPath];
    
    NSMutableArray* files = [[NSMutableArray alloc] init];
    for (NSString* file in enumerator)
    {
        if ([file.pathExtension.lowercaseString isEqualToString:@"jpg"] && ![file hasSuffix:@"stitched.jpg"])
        {
            [files addObject:file];
        }
    }
    //*
    EAGLContext* prevEAGLContext = [EAGLContext currentContext];
    EAGLContext* eaglContext = prevEAGLContext ? prevEAGLContext : [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:eaglContext];
    //*/
    for (NSString* file in files)
    {
        NSString* sourcePath = [ documentPath stringByAppendingPathComponent:file];
        NSString* destPath = [documentPath stringByAppendingPathComponent:[[file stringByDeletingPathExtension] stringByAppendingPathExtension:@"stitched.jpg"]];
        for (int i=0; i<11; ++i)
        {
            
            stitchJPEG(destPath, sourcePath);
            
        }
    }
    //*
    [EAGLContext setCurrentContext:prevEAGLContext];
    //*/
}

@interface AppDelegate () <MVMediaDataSourceObserver, MVMediaDownloadStatusObserver>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    testMADVPanoStitching();/*/!!!For Debug
    g_downloadedFileNames = [[NSMutableArray alloc] init];
    
    MVMediaManager* mediaManager = [MVMediaManager sharedInstance];
    ///!!!mediaManager.downloadMediasIntoDocuments = YES;// :This is necessary
    // Add as observer for media manager:
    [mediaManager addMediaDataSourceObserver:self];
    [mediaManager addMediaDownloadStatusObserver:self];
    //*/
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
    {// When a media file has been successfully downloaded, get its local file name(relative to sandbox document directory) from this callback
        //To download files into sandbox from camera, "Application supports iTunes file sharing" and "App Transport Security Settings"->"Allow Arbitrary Loads" in Info.plist should all be set to YES
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
