//
//  ALAsset+Extensions.h
//  Madv360_v1
//
//  Created by QiuDong on 16/4/12.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface ALAsset (Extensions)

+ (NSString*) writeToTempFile:(NSURL*)assetURL;

@end
