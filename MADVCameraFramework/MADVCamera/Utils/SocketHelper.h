//
//  SocketHelper.h
//  Madv360_v1
//
//  Created by FutureBoy on 11/23/15.
//  Copyright © 2015 Cyllenge. All rights reserved.
//

#ifndef SocketHelper_h
#define SocketHelper_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define CHUNK_WAIT_SECONDS 0.0f
#define FileChunkSize 1048576

#define CONNECT_TIMEOUT_SECONDS 3

#ifdef __cplusplus
extern "C" {
#endif
    
//    extern int g_fileServerSocket;
    extern int g_liveServerSocket;
    
    extern NSString* g_serverAddressIP;
//    extern int g_fileServerAddressPort;
    
    typedef id (^CallbackBlock) (id responseObject, NSError* error, NSString* errMsg);
    
    NSString* getIPAddress();
    
    extern dispatch_queue_t sharedConnectQueue();
    
    void dispatchBlockOnQueueAsync(dispatch_queue_t srcQueue, dispatch_queue_t dstQueue, void(^block)(void));
    
    void setNonBlockMode(int sock, bool toBeNonBlockMode);
    
    void connectServer(NSString* addressIP, int addressPort, CallbackBlock callback, int timeoutSeconds);
    void disconnect(int socket, CallbackBlock callback);
    
    NSString* md5sum(unsigned char* data, UInt32 length);
    
    int loadFileChunk(uint8_t* data, int dataOffset, NSString* filepath, int fileOffset, int size);
    
    bool saveFileChunk(NSString* filepath, int fileOffset, const char* data, int bufferLength, int dataOffset, int size);
    
    NSArray* segmentRanges(NSInteger totalSize, NSInteger segmentSize, NSInteger offset);
    
//    void downloadFileChunk(NSString* localFilePath, NSString* remoteFilePath, NSRange chunkRange, int sessionID, dispatch_queue_t callbackQueue, CallbackBlock callback, void(^progressCallback)(NSValue* chunk, NSUInteger coveredChunkBytes));
//    
//    void uploadFileChunk(NSString* remoteFilePath, NSString* localFilePath, NSMutableArray* notUploadedChunks, int sessionID, dispatch_queue_t callbackQueue, CallbackBlock callback, void(^progressCallback)(NSValue* chunk, NSUInteger coveredChunkBytes));
//    
//    UIAlertController* alertWithResponse(UIViewController* parentViewController, id responseObject, NSError* error, NSString* errMsg);
    
#ifdef __cplusplus
}
#endif

#endif /* SocketHelper_h */
