//
//  z_Sandbox.m
//  Template
//
//  Created by zhoubl on 13-6-3.
//  Copyright (c) 2013年 cdeledu. All rights reserved.
//

#import "z_Sandbox.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
#import <Photos/Photos.h>

@implementation z_Sandbox

// 程序目录，不能存任何东西
+ (NSString *)appPath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSUserDomainMask, YES);
    
	return [paths objectAtIndex:0];
}
+ (NSString *)getAppPathWithFileName:(NSString *)fileName
{
    NSString * path=[[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    return path;
}
// 文档目录，需要ITUNES同步备份的数据存这里
+ (NSString *)docPath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [paths objectAtIndex:0];
}
// 配置目录，配置文件存这里
+ (NSString *)libPrefPath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	return [[paths objectAtIndex:0] stringByAppendingFormat:@"/Preference"];
}
// 缓存目录，系统永远不会删除这里的文件，ITUNES会删除
+ (NSString *)libCachePath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	return [[paths objectAtIndex:0] stringByAppendingFormat:@"/Caches"];
}
// 缓存目录，APP退出后，系统可能会删除这里的内容
+ (NSString *)tmpPath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	return [[paths objectAtIndex:0] stringByAppendingFormat:@"/tmp"];
}

+ (BOOL)touch:(NSString *)path
{
	if ( NO == [[NSFileManager defaultManager] fileExistsAtPath:path] )
	{
		return [[NSFileManager defaultManager] createDirectoryAtPath:path
										 withIntermediateDirectories:YES
														  attributes:nil
															   error:NULL];
	}
	
	return NO;
}

/**
 *	@brief	判断文件路径是否存在
 *
 *	@param 	fullPathName 	文件完整路径
 *
 *	@return	返回是否存在
 */
+ (BOOL)isFileExists:(NSString *)fullPathName
{
    NSFileManager *file_manager = [NSFileManager defaultManager];
    return [file_manager fileExistsAtPath:fullPathName];
}

/**
 *	@brief	删除文件
 *
 *	@param 	fullPathName 	文件完整路径
 *
 *	@return	是否删除成功
 */
+ (BOOL)remove:(NSString *)fullPathName
{
    NSError *error = nil;
    NSFileManager *file_manager = [NSFileManager defaultManager];
    if ([file_manager fileExistsAtPath:fullPathName]) {
        [file_manager removeItemAtPath:fullPathName error:&error];
    }
    if (error) {
        return NO;
    }
    return YES;
}

/**
 *	@brief	创建文件夹
 *
 *	@param 	dir 	文件夹名字
 */
+ (void)makeDirs:(NSString *)dir
{
    NSFileManager *file_manager = [NSFileManager defaultManager];
    [file_manager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
}

/**
 *	@brief	判断Document文件路径是否存在
 *
 *	@param 	fileName 	文件名
 *
 *	@return	返回是否存在文件路径
 */
+ (BOOL)fileExistInDocumentPath:(NSString*)fileName

{
	if(fileName == nil || [fileName isEqualToString:@""])
		return NO;
	NSString* documentsPath = [self documentPath:fileName];
	return [[NSFileManager defaultManager] fileExistsAtPath: documentsPath];
}

/**
 *	@brief	通过文件名，获取Document完整路径，如果不存在返回为nil
 *
 *	@param 	fileName 	文件名
 *
 *	@return	返回完整路径
 */
+ (NSString*)documentPath:(NSString*)fileName

{
	if(fileName == nil)
		return nil;
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentsDirectory = [paths objectAtIndex: 0];
	NSString* documentsPath = [documentsDirectory stringByAppendingPathComponent: fileName];
	return documentsPath;
}

/**
 *	@brief	通过文件名，获取NSCachesDirectory完整路径，如果不存在返回为nil
 *
 *	@param 	fileName 	文件名
 *
 *	@return	返回缓存文件的完整路径
 */
+ (NSString*)documentCachesPath:(NSString*)fileName

{
	if(fileName == nil)
		return nil;
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString* documentsDirectory = [paths objectAtIndex: 0];
	NSString* documentsPath = [documentsDirectory stringByAppendingPathComponent: fileName];
	return documentsPath;
}

/**
 *	@brief	删除Document文件
 *
 *	@param 	fileName 	文件名
 *
 *	@return	是否成功删除
 */
+ (BOOL)deleteDocumentFile:(NSString*)fileName

{
    BOOL del = NO;
	if(fileName == nil)
		return del;
	NSString* documentsPath = [self documentPath:fileName];
	if( [[NSFileManager defaultManager] fileExistsAtPath: documentsPath])
	{
		
		del = [[NSFileManager defaultManager] removeItemAtPath: documentsPath error:nil];
	}
	return del;
}

+ (BOOL)deleteFile:(NSString*)filePath
{
    BOOL del = NO;
    if(filePath == nil)
        return del;
    
    if( [[NSFileManager defaultManager] fileExistsAtPath: filePath])
    {
        
        del = [[NSFileManager defaultManager] removeItemAtPath: filePath error:nil];
    }
    return del;
}

/**
 *	@brief	判断Cache是否存在
 *
 *	@param 	fileName 	文件名
 *
 *	@return	是否存在文件
 */
+ (BOOL)fileExistInCachesPath:(NSString*)fileName

{
	if(fileName == nil)
		return NO;
	NSString* cachesPath = [self cachesFilePath:fileName];
	return [[NSFileManager defaultManager] fileExistsAtPath: cachesPath];
}

/**
 *	@brief	通过文件名返回完整的Caches目录下的路径，如果不存在该路径返回nil
 *
 *	@param 	fileName 	文件名
 *
 *	@return	返回Caches完整路径
 */
+ (NSString* )cachesFilePath:(NSString*)fileName
{
	if(fileName == nil)
		return nil;
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString* cachesDirectory = [paths objectAtIndex: 0];
	NSString* cachesPath = [cachesDirectory stringByAppendingPathComponent: fileName];
	return cachesPath;
}

/**
 *	@brief	删除Caches文件
 *
 *	@param 	fileName 	文件名
 *
 *	@return	删除是否成功
 */
+ (BOOL)deleteCachesFile:(NSString*)fileName

{
    BOOL del = NO;
	if(fileName == nil)
		return del;
	NSString* cachesPath = [self cachesFilePath:fileName];
	if( [[NSFileManager defaultManager] fileExistsAtPath: cachesPath])
	{
		del = [[NSFileManager defaultManager] removeItemAtPath: cachesPath error:nil];
	}
	return del;
}

+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

+ (long long)getFileSizePath:(NSString *)filePath
{
    NSFileManager* fm = [NSFileManager defaultManager];
    long long size = [[fm attributesOfItemAtPath:filePath error:nil] fileSize];
    return size;
}

+ (double) freeDiskSpace
{
    NSDictionary *fattributes = [[ NSFileManager defaultManager ] attributesOfFileSystemForPath : NSHomeDirectory () error : nil ];
    return [[fattributes objectForKey : NSFileSystemFreeSize] doubleValue] - 300 * 1024 * 1024;
}
+ (long long)getFolderSize:(NSString *)folderPath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [z_Sandbox getFileSizePath:fileAbsolutePath];
    }
    return folderSize;
}
+ (void)deleteFolder:(NSString *)folderPath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return ;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        [z_Sandbox remove:fileAbsolutePath];
    }
}
//是否有权限访问相册
+ (BOOL)isVisitPhotoLibrary
{
    BOOL flag = false;
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusRestricted || status ==PHAuthorizationStatusDenied)
    {
        //无权限
        flag = false;
    }else
    {
        flag = true;
    }
    return flag;
}
//是否有权限访问相机
+ (BOOL)isVisitCamera
{
    BOOL flag = false;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
    {
        //无权限
        flag = false;
    }else
    {
        flag = true;
    }
    return flag;
}
+ (BOOL)isPhotoLibraryStatusNotDetermined
{
    BOOL flag = false;
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusNotDetermined) {
        flag = true;
    }
    return flag;
}
@end

NSInteger fileSizeAtPath(NSString* filePath) {
    struct stat st;
    if(lstat([filePath cStringUsingEncoding:NSUTF8StringEncoding], &st) == 0){
        return (NSInteger) st.st_size;
    }
    return 0;
}

