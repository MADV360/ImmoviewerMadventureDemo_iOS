//
// Created by ss on 15-2-28.
// Copyright (c) 2015 ___FULLUSERNAME___. All rights reserved.
//

#import "FDSUploadThreadObj.h"
#import "FDSUtilities.h"
#import "GalaxyFDSClient.h"

@interface FDSUploadThreadObj()
@property(nonatomic,copy)NSString * baseurl;
@property(nonatomic,strong)NSArray * signatures;
@property(nonatomic,copy)NSString * completeurl;
@end

@implementation FDSUploadThreadObj {
  __weak GalaxyFDSClient *_client;
  NSString *_bucketName;
  NSString *_objectName;
  __weak FDSObjectInputStream *_stream;
  NSString *_uploadId;
  long long _remainingLength;
  long long _partSize;
  int _partId;
  NSMutableArray *_results;
  GalaxyFDSClientException *_exception;
    NSString * _fileToken;
    NSString * _access_token;
    
 
}

@synthesize results = _results;
@synthesize exception = _exception;

- (id)initWithClient:(GalaxyFDSClient *)client bucketName:(NSString *)bucketName
    objectName:(NSString *)objectName fromStream:(FDSObjectInputStream *)input
    uploadId:(NSString *)uploadId objectLength:(long long)length
    partSize:(long long)partSize baseurl:(NSString *)baseurl signatures:(NSArray *)signatures completeurl:(NSString *)completeurl {
  self = [super init];
  if (self) {
    _client = client;
    _bucketName = bucketName;
    _objectName = objectName;
    _stream = input;
    _uploadId = uploadId;
    _remainingLength = length;
    _partSize = partSize;
      _baseurl=baseurl;
      _signatures=signatures;
      _completeurl=completeurl;
    _partId = 0;
    _results = [[NSMutableArray alloc] init];
    _exception = nil;
  }
  return self;
}
- (id)initWithClient:(GalaxyFDSClient *)client FileToken:(NSString *)fileToken
        access_token:(NSString *)access_token fromStream:(FDSObjectInputStream *)input
            uploadId:(NSString *)uploadId objectLength:(long long)length
            partSize:(long long)partSize
{
    self = [super init];
    if (self) {
        _client = client;
        _fileToken = fileToken;
        _access_token = access_token;
        _stream = input;
        _uploadId = uploadId;
        _remainingLength = length;
        _partSize = partSize;
        _partId = 0;
        _results = [[NSMutableArray alloc] init];
        _exception = nil;
    }
    return self;
}

- (void)upload:(id)unused {
//    NSLog(@"=====%@",[NSThread currentThread]);
  long long partSize;
  while (YES) {
    @synchronized (self) {
      if (_exception) {
        return;
      }
      if (_remainingLength == 0) {
        return;
      }
        if (self.isAbort) {
            @throw [GalaxyFDSClientException exceptionWithReason:FGGetStringWithKeyFromTable(STOP, nil) userInfo:nil];
        }
      partSize = [FDSUtilities min:_partSize and:_remainingLength];
      _remainingLength -= partSize;
    }
    @try {
        if (self.isAbort) {
            @throw [GalaxyFDSClientException exceptionWithReason:FGGetStringWithKeyFromTable(STOP, nil) userInfo:nil];
        }
      id result = [_client uploadPart:_objectName intoBucket:_bucketName
          fromStream:_stream withId:_uploadId andPartNumber:&_partId
          andLength:partSize baseurl:_baseurl signatures:_signatures];
      [_results addObject:result];
        if (self.completeurl==nil || [self.completeurl isEqualToString:@""]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:UPLOAD_SUCCESS object:_objectName];
            return;
        }
    } @catch (GalaxyFDSClientException *e) {
      @synchronized (self) {
        if (!_exception) {
          _exception = e;
        }
      }
      return;
    }
  }
}
- (void)weiboUpload:(id)unused
{
    long long partSize;
    while (YES) {
        @synchronized (self) {
            if (_exception) {
                return;
            }
            if (_remainingLength == 0) {
                return;
            }
            if (self.isAbort) {
                @throw [GalaxyFDSClientException exceptionWithReason:FGGetStringWithKeyFromTable(STOP, nil) userInfo:nil];
            }
            partSize = [FDSUtilities min:_partSize and:_remainingLength];
            _remainingLength -= partSize;
        }
        @try {
            if (self.isAbort) {
                @throw [GalaxyFDSClientException exceptionWithReason:FGGetStringWithKeyFromTable(STOP, nil) userInfo:nil];
            }
            id result = [_client uploadPartFileToken:_fileToken access_token:_access_token fromStream:_stream withId:_uploadId andPartNumber:&_partId andLength:partSize andPartSzie:_partSize];
            [_results addObject:result];
        } @catch (GalaxyFDSClientException *e) {
            @synchronized (self) {
                if (!_exception) {
                    _exception = e;
                }
            }
            return;
        }
    }
}

@end
