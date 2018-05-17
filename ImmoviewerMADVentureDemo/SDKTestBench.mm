//
//  SDKTestBench.c
//  ImmoviewerMADVentureDemo
//
//  Created by QiuDong on 2018/5/17.
//  Copyright © 2018年 QiuDong. All rights reserved.
//

#import "SDKTestBench.h"
#import <MadvGLRenderer.h>
#import <MadvGLRenderer_iOS.h>
#import <MADVPano/JPEGUtils.h>
#import <MADVPano/MadvGLRendererBase_iOS.h>

void stitchJPEG(NSString* destPath, NSString* sourcePath) {
    jpeg_decompress_struct jpegInfo = readImageInfoFromJPEG(sourcePath.UTF8String);
    MadvEXIFExtension madvExtension = readMadvEXIFExtensionFromJPEG(sourcePath.UTF8String);
    if (madvExtension.gyroMatrixBytes > 0)
    {
        MadvGLRendererBase_iOS::renderJPEGToJPEG(destPath, sourcePath, jpegInfo.image_width, jpegInfo.image_height, NO, &madvExtension, 0, madvExtension.cameraParams.gyroMatrix, 3);
    }
    else
    {
        MadvGLRendererBase_iOS::renderJPEGToJPEG(destPath, sourcePath, jpegInfo.image_width, jpegInfo.image_height, NO, &madvExtension, 0, NULL, 0);
    }
    
}

void testMADVPanoStitching() {
    NSString* documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSFileManager* fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator* enumerator = [fm enumeratorAtPath:documentPath];
    
    NSMutableArray* files = [[NSMutableArray alloc] init];
    for (NSString* file in enumerator)
    {
        if ([file.pathExtension.lowercaseString isEqualToString:@"jpg"] && ![file hasSuffix:@"stitched.jpg"] && ![file hasSuffix:@"tmp.jpg"])
        {
            [files addObject:file];
        }
    }
    for (NSString* file in files)
    {
        NSString* sourcePath = [ documentPath stringByAppendingPathComponent:file];
        NSString* destPath = [documentPath stringByAppendingPathComponent:[[file stringByDeletingPathExtension] stringByAppendingPathExtension:@"stitched.jpg"]];
        stitchJPEG(destPath, sourcePath);
    }
}
