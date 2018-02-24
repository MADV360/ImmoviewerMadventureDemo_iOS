//
//  MVPhotosManager.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/15.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "MVPhotosManager.h"
#import <Photos/Photos.h>
#ifdef MADVPANO_BY_SOURCE
#import "EXIFParser.h"
#else
#import <MADVPano/EXIFParser.h>
#endif
#import "z_Sandbox.h"

@implementation MVPhotosManager
+ (id)sharedInstance
{
    static dispatch_once_t once;
    static MVPhotosManager * instance = nil;
    dispatch_once(&once, ^{
        /*
         if ([MRDIAMABAGER_ENVIRONMENT isEqualToString:ENVIRONMENT_DEVELOPMENT])
         instance = [[MVMediaManagerCase alloc] init];
         else
         //*/
        instance = [[MVPhotosManager alloc] init];
    });
    return instance;
}
- (void)saveVideoWithUrl:(NSURL *)videoUrl collectionTitle:(NSString *)collectionTitle completionHandler:(CompletionHandler)completionHandler
{
    //保存图片
    __block NSString *assetId = nil;
    // 1. 存储图片到"相机胶卷"
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // 新建一个PHAssetCreationRequest对象
        // 返回PHAsset(图片)的字符串标识
       
        assetId = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:videoUrl].placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            // 2. 获得相册对象
            PHAssetCollection *collection = [self getCollectionWithTitle:collectionTitle];
            // 3. 将“相机胶卷”中的图片添加到新的相册
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
                NSLog(@"%@", [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil]);
                // 根据唯一标示获得相片对象
                PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
                // 添加图片到相册中
                [request addAssets:@[asset]];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionHandler) {
                        completionHandler(success,error,assetId);
                    }
                });
            }];
        }else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandler) {
                    completionHandler(success,error,assetId);
                }
            });
        }
        
    }];
}
- (void)saveImageWithUrl:(NSURL *)imageUrl collectionTitle:(NSString *)collectionTitle completionHandler:(CompletionHandler)completionHandler
{
    BOOL flag = false;
    if ([collectionTitle isEqualToString:PHOTOALBUM_NAME]) {
        NSString * filename = [imageUrl.absoluteString lastPathComponent];
        flag =setXmpGPanoPacket([z_Sandbox documentPath:filename].UTF8String);//向图片添加第三方可以识别成全景的标示
    }else
    {
        flag = true;
    }
    //imageUrl.absoluteString
   
    if (flag) {
        //保存图片
        __block NSString *assetId = nil;
        // 1. 存储图片到"相机胶卷"
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            // 新建一个PHAssetCreationRequest对象
            // 返回PHAsset(图片)的字符串标识
            
            assetId = [PHAssetCreationRequest creationRequestForAssetFromImageAtFileURL:imageUrl].placeholderForCreatedAsset.localIdentifier;
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            // 2. 获得相册对象
            if (success) {
                PHAssetCollection *collection = [self getCollectionWithTitle:collectionTitle];
                // 3. 将“相机胶卷”中的图片添加到新的相册
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
                    NSLog(@"%@", [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil]);
                    // 根据唯一标示获得相片对象
                    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
                    // 添加图片到相册中
                    [request addAssets:@[asset]];
                    
                    
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completionHandler) {
                            completionHandler(success,error,assetId);
                        }
                    });
                    
                }];
            }else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionHandler) {
                        completionHandler(success,error,assetId);
                    }
                });
            }
            
        }];
    }
}

- (PHAssetCollection *)getCollectionWithTitle:(NSString *)title {
    // 先获得之前创建过的相册
    PHFetchResult<PHAssetCollection *> *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collectionResult) {
        if ([collection.localizedTitle isEqualToString:title]) {
            return collection;
        }
    }
    
    // 如果相册不存在,就创建新的相册(文件夹)
    __block NSString *collectionId = nil; // __block修改block外部的变量的值
    // 这个方法会在相册创建完毕后才会返回
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        // 新建一个PHAssertCollectionChangeRequest对象, 用来创建一个新的相册
        collectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
    } error:nil];
    
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].firstObject;
}
@end
