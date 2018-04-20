//
//  main.m
//  ImmoviewerMADVentureDemo
//
//  Created by QiuDong on 2018/1/24.
//  Copyright © 2018年 QiuDong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#import <MadvGLRenderer_iOS.h>
#import <MADVPano/JPEGUtils.h>
void stitchJPEG(NSString* destPath, NSString* sourcePath) {
    MadvEXIFExtension madvExtension = readMadvEXIFExtensionFromJPEG(sourcePath.UTF8String);
    jpeg_decompress_struct jpegInfo = readImageInfoFromJPEG(sourcePath.UTF8String);
    if (madvExtension.gyroMatrixBytes > 0)
    {
        [MVPanoRenderer renderJPEGToJPEG:destPath sourcePath:sourcePath dstWidth:jpegInfo.image_width dstHeight:jpegInfo.image_height forceLUTStitching:NO pMadvEXIFExtension:&madvExtension filterID:0 gyroMatrix:madvExtension.cameraParams.gyroMatrix gyroMatrixRank:3];
    }
    else
    {
        [MVPanoRenderer renderJPEGToJPEG:destPath sourcePath:sourcePath dstWidth:jpegInfo.image_width dstHeight:jpegInfo.image_height forceLUTStitching:NO pMadvEXIFExtension:&madvExtension filterID:0 gyroMatrix:NULL gyroMatrixRank:0];
    }
}

int main(int argc, char * argv[]) {
    @autoreleasepool {
        NSString* documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSFileManager* fm = [NSFileManager defaultManager];
        NSDirectoryEnumerator* enumerator = [fm enumeratorAtPath:documentPath];
        for (NSString* file in enumerator)
        {
            if ([file.pathExtension.lowercaseString isEqualToString:@"jpg"])
            {
                NSString* sourcePath = [documentPath stringByAppendingPathComponent:file];
                NSString* destPath = [documentPath stringByAppendingPathComponent:[[file stringByDeletingPathExtension] stringByAppendingPathExtension:@"stitched.jpg"]];
                stitchJPEG(destPath, sourcePath);
            }
        }
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
