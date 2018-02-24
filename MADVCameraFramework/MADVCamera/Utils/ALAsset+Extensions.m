//
//  ALAsset+Extensions.m
//  Madv360_v1
//
//  Created by QiuDong on 16/4/12.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "ALAsset+Extensions.h"

@implementation ALAsset (Extensions)

+ (NSString*) writeToTempFile:(NSURL*)assetURL
{
    
    NSString * surl = [assetURL absoluteString];
    NSString * ext = [surl substringFromIndex:[surl rangeOfString:@"ext="].location + 4];
    NSTimeInterval ti = [[NSDate date]timeIntervalSinceReferenceDate];
    NSString * filename = [NSString stringWithFormat: @"%f.%@",ti,ext];
    NSString * tmpfile = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        
        ALAssetRepresentation * rep = [myasset defaultRepresentation];
        
        NSUInteger size = [rep size];
        const int bufferSize = 8192;
        
        NSLog(@"Writing to %@",tmpfile);
        FILE* f = fopen([tmpfile cStringUsingEncoding:1], "wb+");
        if (f == NULL) {
            NSLog(@"Can not create tmp file.");
            return;
        }
        
        Byte * buffer = (Byte*)malloc(bufferSize);
        int read = 0, offset = 0, written = 0;
        NSError* err;
        if (size != 0) {
            do {
                read = [rep getBytes:buffer
                          fromOffset:offset
                              length:bufferSize
                               error:&err];
                written = fwrite(buffer, sizeof(char), read, f);
                offset += read;
            } while (read != 0);
            
            
        }
        free(buffer);
        fclose(f);
    };
    
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
        NSLog(@"Can not get asset - %@",[myerror localizedDescription]);
        
    };
    
    if(assetURL)
    {
        ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:assetURL
                       resultBlock:resultblock
                      failureBlock:failureblock];
    }
    
    return tmpfile;
}

@end
