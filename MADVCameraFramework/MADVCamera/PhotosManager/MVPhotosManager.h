//
//  MVPhotosManager.h
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/15.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^CompletionHandler)(BOOL success, NSError * error, NSString * assetId);
@interface MVPhotosManager : NSObject
+ (id)sharedInstance;
- (void)saveVideoWithUrl:(NSURL *)videoUrl collectionTitle:(NSString *)collectionTitle completionHandler:(CompletionHandler)completionHandler;
- (void)saveImageWithUrl:(NSURL *)imageUrl collectionTitle:(NSString *)collectionTitle completionHandler:(CompletionHandler)completionHandler;
@end
