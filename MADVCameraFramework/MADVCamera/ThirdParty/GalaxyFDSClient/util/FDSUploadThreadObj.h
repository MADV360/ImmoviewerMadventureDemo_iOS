//
// Created by ss on 15-2-28.
// Copyright (c) 2015 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FDSObjectInputStream.h"
#import "GalaxyFDSClientException.h"
@class GalaxyFDSClient;

@interface FDSUploadThreadObj : NSObject
@property(nonatomic,assign)BOOL isAbort;
@property (readonly)NSArray *results;
@property (readonly)GalaxyFDSClientException *exception;

- (id)initWithClient:(GalaxyFDSClient *)client bucketName:(NSString *)bucketName
    objectName:(NSString *)objectName fromStream:(FDSObjectInputStream *)input
    uploadId:(NSString *)uploadId objectLength:(long long)length
    partSize:(long long)partSize baseurl:(NSString *)baseurl signatures:(NSArray *)signatures completeurl:(NSString *)completeurl ;
- (id)initWithClient:(GalaxyFDSClient *)client FileToken:(NSString *)fileToken
        access_token:(NSString *)access_token fromStream:(FDSObjectInputStream *)input
            uploadId:(NSString *)uploadId objectLength:(long long)length
            partSize:(long long)partSize;

- (void)upload:(id)unused;
- (void)weiboUpload:(id)unused;
@end
