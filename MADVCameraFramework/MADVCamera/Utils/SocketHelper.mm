//
//  SocketHelper.m
//  Madv360_v1
//
//  Created by FutureBoy on 11/23/15.
//  Copyright © 2015 Cyllenge. All rights reserved.
//

#import "SocketHelper.h"
//#import "AMBATCPJSONMessager.h"
//#import "AMBACameraClient.h"
//#import "AMBAGetFileResponseInfo.h"
//#import "TCPDataTransferer.h"
#import "NSString+Extensions.h"
//#import "Enums_AMBA.h"
#import <CommonCrypto/CommonDigest.h>

#include <fstream>
#include <stdio.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <pthread.h>
#include <arpa/inet.h>
#include "fcntl.h"

using namespace std;

//int g_fileServerSocket = -1;
int g_liveServerSocket = -1;

NSString* g_serverAddressIP = nil;
//int g_fileServerAddressPort = 0;

#include <ifaddrs.h>
#include <arpa/inet.h>

NSString* getIPAddress() {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}

void setNonBlockMode(int sock, bool toBeNonBlockMode)
{
    int flags = fcntl(sock, F_GETFL, 0);
    if (toBeNonBlockMode)
        fcntl(sock, F_SETFL, flags | O_NONBLOCK);
    else
        fcntl(sock, F_SETFL, flags & (~O_NONBLOCK));
}

dispatch_queue_t sharedConnectQueue() {
    static dispatch_queue_t g_sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        g_sharedInstance = dispatch_queue_create("com.madv360.sockethelper.connectqueue", DISPATCH_QUEUE_SERIAL);
    });
    return g_sharedInstance;
}

void disconnect(int socket, CallbackBlock callback) {
//    dispatch_async(sharedConnectQueue(), ^{
        NSLog(@"BEFORE disconnect socket #%d", socket);
        int result = 0;
        if (socket > 0)
        {
            result = close(socket);
        }
        NSLog(@"disconnect #%d: result = %d", socket, result);
        if (callback)
        {
            if (result != 0)
            {
                NSError* error = [NSError errorWithDomain:@"com.madv360.exception.socketerror" code:result userInfo:nil];
                callback(nil, error, [NSString stringWithUTF8String:strerror(errno)]);
            }
            else
            {
                callback(nil, nil, nil);
            }
        }
//    });
}

void connectServer(NSString* addressIP, int addressPort, CallbackBlock callback, int timeoutSeconds) {
//    dispatch_async(sharedConnectQueue(), ^{
        NSLog(@"connectServer $ addressIP = %@, addressPort = %d", addressIP, addressPort);
        //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int sockfd;
        struct sockaddr_in server_addr;
        //    struct hostent* host;
        
        NSLog(@"connectServer $ BEFORE socket()");
        sockfd = socket(AF_INET, SOCK_STREAM, 0);
        if (sockfd == -1)
        {
            NSLog(@"Socket error:%s", strerror(errno));
            fprintf(stderr,"Socket error:%s\n",strerror(errno));
            
            close(sockfd);
            
            if (callback)
            {
                NSError* error = [NSError errorWithDomain:@"com.madv360.exception.socketerror" code:-1 userInfo:nil];
                callback(nil, error, [NSString stringWithUTF8String:strerror(errno)]);
            }
            
            return;
        }
        
        bzero(&server_addr, sizeof(server_addr));
        server_addr.sin_family = AF_INET;
        server_addr.sin_port = htons(addressPort);
        server_addr.sin_addr.s_addr = inet_addr(addressIP.UTF8String);
        
        int con_flag;//, res2;
        //    pthread_t thread_write;
        NSLog(@"connectServer $ BEFORE setsockopt(), sockfd = %d", sockfd);
        bool on = true;
        setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(bool)); //其实这个就是阻止服务端一关掉，再启动，运行不了的情况发生
    
    bool dontLinger = false;
    setsockopt(sockfd, SOL_SOCKET, SO_LINGER, &dontLinger, sizeof(bool));
    
    int zero = 0;
    setsockopt(sockfd, SOL_SOCKET, SO_SNDBUF, &zero, sizeof(int));
    setsockopt(sockfd, SOL_SOCKET, SO_RCVBUF, &zero, sizeof(int));
    
        if (timeoutSeconds > 0)
        {
            // Timeout: If recv or send timeout, EWOULDBLOCK will be returned
            struct timeval tv_timeout;
            tv_timeout.tv_sec = timeoutSeconds;
            tv_timeout.tv_usec = 0;
            if (setsockopt(sockfd, SOL_SOCKET, SO_SNDTIMEO, (void*)&tv_timeout, sizeof(struct timeval)) < 0 ||
                setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, (void*)&tv_timeout, sizeof(struct timeval)) < 0)
            {
                NSLog(@"connectServer $ setsockopt error : %s", strerror(errno));
                fprintf(stderr,"setsockopt Error:%s\a\n",strerror(errno));
            }
        }
        
        __block BOOL connectHandled = NO;
        dispatch_source_t timeoutTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        dispatch_source_set_timer(timeoutTimer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * CONNECT_TIMEOUT_SECONDS), DISPATCH_TIME_FOREVER, 0);
        dispatch_source_set_event_handler(timeoutTimer, ^{
            @synchronized(timeoutTimer) {
                if (!connectHandled)
                {
                    connectHandled = YES;
                    dispatch_suspend(timeoutTimer);
                }
                else
                    return;
            }
            
            NSLog(@"connectServer $ Connect time out : %s", strerror(errno));
            fprintf(stderr,"Connect Error:%s\a\n",strerror(errno));
            
            if (callback)
            {
                NSError* error = [NSError errorWithDomain:@"com.madv360.exception.socketerror" code:-1 userInfo:nil];
                callback(nil, error, [NSString stringWithUTF8String:strerror(errno)]);
            }
            
            close(sockfd);
        });
        dispatch_resume(timeoutTimer);
    
        NSLog(@"connectServer $ BEFORE connect(), sockfd = %d", sockfd);
        con_flag = connect(sockfd, (struct sockaddr *)(&server_addr), sizeof(struct sockaddr));   //连接服务端
        @synchronized(timeoutTimer) {
            if (!connectHandled)
            {
                connectHandled = YES;
                dispatch_suspend(timeoutTimer);
            }
            else
                return;
        }
        
        if (con_flag == -1)
        {
            NSLog(@"connectServer $ Connect error : %s", strerror(errno));
            fprintf(stderr,"Connect Error:%s\a\n",strerror(errno));
            
            close(sockfd);
            
            if (callback)
            {
                NSError* error = [NSError errorWithDomain:@"com.madv360.exception.socketerror" code:-1 userInfo:nil];
                callback(nil, error, [NSString stringWithUTF8String:strerror(errno)]);
            }
        }
        else
        {
            NSLog(@"connectServer $ Connect success : %d", sockfd);
            if (callback)
            {
                callback(@(sockfd), nil, nil);
            }
        }
//    });
}

void dispatchBlockOnQueueAsync(dispatch_queue_t srcQueue, dispatch_queue_t dstQueue, void(^block)(void)) {
    if (!block) return;
    
    //    static const char* QueueKey = "QueueKey";
    //    static const char* QueueValue = "Value";
    //    static dispatch_once_t once;
    //    dispatch_once(&once, ^{
    //        dispatch_queue_set_specific(dispatch_get_main_queue(), QueueKey, (void*)QueueValue, nil);
    //    });
    
    if (srcQueue == dstQueue)
    {
        block();
    }
    else
    {
        dispatch_async(dstQueue, block);
    }
}

//void sendJSONMessageAsync(dispatch_queue_t msgQueue, int sockfd, int sessionID, MVDeviceRequest* request, dispatch_queue_t callbackQueue, CallbackBlock callback) {
//    NSMutableDictionary* jsonDict = [request mj_keyValues];
//    [jsonDict addEntriesFromDictionary:@{@"token":@(sessionID)}];
//    NSString* jsonStr = [NSString stringWithJSONDictionary:jsonDict];
//    
//    dispatch_async(msgQueue, ^{
//        const char* msg = [jsonStr UTF8String];
//        long writeSize = strlen(msg) + 1;
//        NSLog(@"Request string : (%ld) \"%s\"", writeSize,msg);
//        long status;
//        if ((status = write(sockfd, msg, writeSize)) < 0)
//        {
//            if (callback)
//            {
//                dispatchBlockOnQueueAsync(msgQueue, callbackQueue,^{
//                    NSError* error = [NSError errorWithDomain:@"com.madv360.exception.socketerror" code:-1 userInfo:nil];
//                    callback(nil, error, [NSString stringWithFormat:@"Socket writing failed : %s", strerror(errno)]);
//                });
//            }
//        }
//        else if (status > 0 && status < writeSize)
//        {
//            if (callback)
//            {
//                dispatchBlockOnQueueAsync(msgQueue, callbackQueue,^{
//                    NSError* error = [NSError errorWithDomain:@"com.madv360.exception.socketerror" code:-1 userInfo:nil];
//                    callback(nil, error, [NSString stringWithFormat:@"Socket writing incomplete : %s", strerror(errno)]);
//                });
//            }
//        }
//        NSLog(@"Socket write status : %ld", status);
//        
//        NSDictionary* responseDict = nil;
//        char readBuf[1024];
//        long readSize;
//        if ((readSize = read(sockfd, readBuf, 1024)) >= 1)
//        {
//            readBuf[readSize] = '\0';
//            NSLog(@"Response string : (%ld) \"%s\"", readSize, readBuf);
//            NSError* error = nil;
//            NSData* responseData = [NSData dataWithBytes:readBuf length:readSize];
//            NSString* responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
//            responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
//            MVDeviceResponse* responseObject = [MVDeviceResponse mj_objectWithKeyValues:responseDict];
//            
//            if (callback)
//            {
//                dispatchBlockOnQueueAsync(msgQueue, callbackQueue,^{
//                    callback(responseObject, error, responseString);
//                });
//            }
//        }
//        else if (readSize == -1)
//        {
//            /* Error, check errno, take action... */
//            if (callback)
//            {
//                dispatchBlockOnQueueAsync(msgQueue, callbackQueue,^{
//                    NSError* error = [NSError errorWithDomain:@"com.madv360.exception.socketerror" code:-2 userInfo:nil];
//                    callback(nil, error, [NSString stringWithFormat:@"Socket reading error : %s", strerror(errno)]);
//                });
//            }
//        }
//        else if (readSize == 0)
//        {
//            /* Peer closed the socket, finish the close */
//            close(sockfd);
//            /* Further processing... */
//            if (callback)
//            {
//                dispatchBlockOnQueueAsync(msgQueue, callbackQueue,^{
//                    NSError* error = [NSError errorWithDomain:@"com.madv360.exception.socketerror" code:-2 userInfo:nil];
//                    callback(nil, error, [NSString stringWithFormat:@"Socket reading meet closed peer : %s", strerror(errno)]);
//                });
//            }
//        }
//    });
//}

NSString* md5sum(unsigned char* data, UInt32 length) {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data, length, result);
    
    char md5str[CC_MD5_DIGEST_LENGTH * 2 + 1];
    md5str[CC_MD5_DIGEST_LENGTH * 2] = '\0';
    char* pDst = md5str;
    unsigned char* pSrc = result;
    for (int i=0; i<CC_MD5_DIGEST_LENGTH; ++i)
    {
        sprintf(pDst, "%02x", *pSrc);
        pDst += 2;
        pSrc++;
    }
    
    return [NSString stringWithUTF8String:md5str];
}

bool saveFileChunk(NSString* filepath, int fileOffset, const char* data, int bufferLength, int dataOffset, int size) {
    FILE* fp = fopen(filepath.UTF8String, "ab+");
    int ferr = errno;//ferror(fp);//
    if (0 == fp)
    {
        NSLog(@"CreateIfExist file %@ : fp=%ld, ferr=%d, strerr=%s", filepath, (long)fp, ferr, strerror(ferr));
        return false;
    }
    //    ALOGE("CreateIfExist file %s OK: fp=%ld, ferr=%d, strerr=%s", filepath, (long)fp, ferr, strerror(ferr));
    fclose(fp);
    
    ofstream ofs(filepath.UTF8String, ios::out | ios::in | ios::binary);
    //*
    const uint64_t Limit2G = 0x80000000;
    if (fileOffset >= Limit2G)
    {
        //        ALOGV("#0 : fileOffset = %ld", fileOffset);
        ofs.seekp(0x40000000, ios::beg);
        ofs.seekp(0x40000000, ios::cur);
        for (fileOffset -= Limit2G; fileOffset >= Limit2G; fileOffset -= Limit2G)
        {
            ofs.seekp(0x40000000, ios::cur);
            ofs.seekp(0x40000000, ios::cur);
            //            ALOGV("#1 : fileOffset = %ld", fileOffset);
        }
        //        ALOGV("#2 : fileOffset = %ld", fileOffset);
        ofs.seekp(fileOffset, ios::cur);
    }
    else
    {
        //        ALOGV("#3 : fileOffset = %ld", fileOffset);
        ofs.seekp(fileOffset, ios::beg);
        fileOffset = 0;
    }
    /*/
     ofs.seekp(0x40000000, ios::beg);
     ofs.seekp(0x40000000, ios::cur);
     ofs.seekp(0x40000000, ios::cur);
     ofs.seekp(0x40000000, ios::cur);
     ofs.seekp(fileOffset, ios::cur);
     //*/
    //ALOGV("saveFileChunk #4 : bytes=%lx, dataOffset=%ld, length=%ld", (long)bytes, dataOffset, length);
    if (size > 0)
    {
        size = (size > bufferLength ? bufferLength : size);
        ofs.write((const char*)data + dataOffset, (int)size);
    }
    //    ALOGV("saveFileChunk #5");
    ofs.flush();
    //    ALOGV("saveFileChunk #6");
    ofs.close();
    //    ALOGV("saveFileChunk #7");
    return true;
}

int loadFileChunk(uint8_t* data, int dataOffset, NSString* filepath, int fileOffset, int size) {
    ifstream ifs(filepath.UTF8String);
    ifs.seekg(fileOffset, ios::beg);
    long g0 = ifs.tellg();
    ifs.read((char*)data + dataOffset, size);
    long g1 = ifs.tellg();
    ifs.close();
    
    if (g1 >= 0)
    {
        return (int)(g1 - g0);
    }
    else
    {
        FILE* fp = fopen(filepath.UTF8String, "rb");
        fseek(fp, 0, SEEK_END);
        long size = ftell(fp);
        fclose(fp);
        return (int)(size - g0);
    }
}

NSArray* segmentRanges(NSInteger totalSize, NSInteger segmentSize, NSInteger offset) {
    NSMutableArray* ranges = [@[] mutableCopy];
    NSInteger completeSegs = totalSize / segmentSize;
    NSInteger loc = 0;
    for (NSInteger i=0; i<completeSegs; i++)
    {
        NSRange range = NSMakeRange(loc + offset, segmentSize);
        [ranges addObject:[NSValue valueWithRange:range]];
        loc += segmentSize;
    }
    if (loc < totalSize)
    {
        [ranges addObject:[NSValue valueWithRange:NSMakeRange(loc + offset, totalSize - loc)]];
    }
    return [NSArray arrayWithArray:ranges];
}

/*
 callback will be called for each chunk, with nvActualRange as parameter 0, until error ocurrs
 */
/*
void downloadFileChunk(NSString* localFilePath, NSString* remoteFilePath, NSRange chunkRange, int sessionID, dispatch_queue_t callbackQueue, CallbackBlock callback, void(^progressCallback)(NSValue* chunk, NSUInteger coveredChunkBytes)) {
        int ferr = errno;
    FILE* fp = fopen(localFilePath.UTF8String, "ab");
    int ferr = errno;ferror(fp);//
    if (0 == fp)
    {
        NSLog(@"CreateIfExist file %s : fp=%ld, ferr=%d, strerr=%s", localFilePath.UTF8String, (long)fp, ferr, strerror(ferr));
    }
    fclose(fp);
    
    if (chunkRange.location == -1 || chunkRange.length == -1)
        return;
    
    __block int receivedBytes = 0;
    __block uint8_t* buffer = new uint8_t[chunkRange.length];
    
    static NSString* ErrMsgPrefix_GetFileSend = @"GetFileSend_";
    static NSString* ErrMsgPrefix_GetFileReceive = @"GetFileReceive_";
    static NSString* ErrMsgPrefix_GetFileResponse = @"GetFileResponse_";
    static NSString* ErrMsgPrefix_GetFileResultReceive = @"ResultReceive_";
    static NSString* ErrMsgPrefix_GetFileResultResponse = @"ResultResponse_";
    
    TCPDataTransferer* transferer = [TCPDataTransferer sharedInstance];
    TCPMessageManager* tcpMM = [TCPMessageManager sharedInstance];
    
    TCPDataReceiver* chunkDownloadHandler = [[TCPDataReceiver alloc] initWithReceiveCallback:nil timeoutCallback:nil errorCallback:nil];
    
    __block NSString* md5 = nil;Local MD5
    __block NSString* remoteMD5 = nil;Remote MD5
    __block NSError* messageTaskError = nil;
    __block NSString* messageTaskErrMsg = nil;
    __block NSError* dataTaskError = nil;
    __block NSString* dataTaskErrMsg = nil;
    __block BOOL messageTaskEnded = NO;
    __block BOOL dataTaskEnded = NO;
    __block BOOL callbackInvoked = NO;
    void(^invokeCallbackBlock)(BOOL isFromMessageTask, NSError* error, NSString* errMsg) = ^(BOOL isFromMessageTask, NSError* error, NSString* errMsg) {
        NSLog(@"invokeCallbackBlock(%d, %@, %@), callbackInvoked = %d, in %@", isFromMessageTask, error, errMsg, callbackInvoked, [NSValue valueWithRange:chunkRange]);
        @synchronized (localFilePath)
        {
            if (callbackInvoked)
            {
                NSLog(@"invokeCallbackBlock :: Exit#0");
                return;
            }
            
            if (isFromMessageTask)
            {
                messageTaskEnded = YES;
                messageTaskError = error;
                messageTaskErrMsg = errMsg;
            }
            else
            {
                dataTaskEnded = YES;
                dataTaskError = error;
                dataTaskErrMsg = errMsg;
            }
            
            if (dataTaskEnded && messageTaskEnded)
            {
                NSLog(@"invokeCallbackBlock :: callbackInvoked = YES");
                callbackInvoked = YES;

                TCPDataReceiver* handler = [transferer getReceiver:YES];
                if (handler != chunkDownloadHandler)
                {
                    NSLog(@"handler != chunkDownloadHandler");
                }
                else
                {
                    NSLog(@"cancelReceiver by error #0");
                    [transferer cancelReceiver:handler];
                }
                
                delete[] buffer;
                buffer = NULL;
                
                /!!!TO BE OPTIMIZED:
                if (messageTaskErrMsg)
                {
                    if ([messageTaskErrMsg hasPrefix:ErrMsgPrefix_GetFileResponse])
                    {
                        if (callback)
                        {
                            dispatch_async(callbackQueue, ^{
                                callback([NSValue valueWithRange:chunkRange], messageTaskError, messageTaskErrMsg);
                            });
                        }
                    }
                    else if ([messageTaskErrMsg hasPrefix:ErrMsgPrefix_GetFileSend] || [messageTaskErrMsg hasPrefix:ErrMsgPrefix_GetFileReceive] || [messageTaskErrMsg hasPrefix:ErrMsgPrefix_GetFileResultReceive])
                    {
                        /!!!If any error of TCPMM occurs, reconnectCamera would be called by AMBACameraClient already, sho we do not have to call [[AMBACameraClient sharedInstance] reconnectCamera] again;
                        
                        if (callback)
                        {
                            dispatch_async(callbackQueue, ^{
                                callback([NSValue valueWithRange:chunkRange], messageTaskError, messageTaskErrMsg);
                            });
                        }
                    }
                    else if ([messageTaskErrMsg hasPrefix:ErrMsgPrefix_GetFileResultResponse])
                    {
                        [[TCPDataTransferer sharedInstance] reconnectDataServer];
                        
                        if (callback)
                        {
                            dispatch_async(callbackQueue, ^{
                                callback([NSValue valueWithRange:chunkRange], messageTaskError, messageTaskErrMsg);
                            });
                        }
                    }
                }
                else if (dataTaskErrMsg)
                {
                    [[TCPDataTransferer sharedInstance] reconnectDataServer];
                    
                    if (callback)
                    {
                        dispatch_async(callbackQueue, ^{
                            callback([NSValue valueWithRange:chunkRange], dataTaskError, dataTaskErrMsg);
                        });
                    }
                }
                else
                {
                    if (md5 && remoteMD5 && md5.length > 0 && remoteMD5.length > 0 && [md5 isEqualToString:remoteMD5])
                    {
                        if (callback)
                        {
                            dispatch_async(callbackQueue, ^{
                                callback([NSValue valueWithRange:chunkRange], nil, nil);
                            });
                        }
                    }
                    else
                    {
                        if (callback)
                        {
                            NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
                            if (md5)
                                [userInfo setObject:md5 forKey:@"localMD5"];
                            if (remoteMD5)
                                [userInfo setObject:remoteMD5 forKey:@"remoteMD5"];
                            NSError* error = [NSError errorWithDomain:@"com.madv360.downloading.md5check" code:-1 userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
                            
                            dispatch_async(callbackQueue, ^{
                                callback([NSValue valueWithRange:chunkRange], error, userInfo.description);
                            });
                        }
                    }
                }
            }
        }
    };
    
    __block TCPJSONMessager* chunkCompleteResponse = nil;
    NSDictionary* getFileRequestDict = @{@"token":@(sessionID), @"msg_id":@(1285), @"param":remoteFilePath, @"offset":@(chunkRange.location), @"fetch_size":@(chunkRange.length)};
    TCPJSONMessager* getFileRequest = [[AMBATCPJSONRequest alloc] initWithRequestDict:getFileRequestDict responseClass:AMBAGetFileResponseInfo.class receiveBlock:^BOOL(AMBAResponseInfo* response) {
        NSLog(@"getFileResonse : %@", response);
        
        [transferer refreshTimeoutTimer];
        
        NSInteger rval = response.rval;
        if (rval != AMBA_RVAL_OK)
        {
            NSString* errMsg = [ErrMsgPrefix_GetFileResponse stringByAppendingString:[response description]];
            NSError* error = [NSError errorWithDomain:@"com.madv360.ambacomm.getfilereqeustfailed" code:rval userInfo:@{@"errMsg":errMsg}];
            invokeCallbackBlock(YES, error, errMsg);
        }
        else
        {
             Add GetFileResult listener:
            chunkCompleteResponse = [[AMBATCPJSONRequest alloc] initWithRequestDict:nil receiveBlock:^BOOL(AMBAResponseInfo* response) {
                if (response.msg_id == AMBA_GETFILE_RESULT_MSGID && [response.type containsString:@"get_file"])
                {
                    [transferer refreshTimeoutTimer];
                    
                    if ([response.type containsString:@"get_file_complete"])
                    {
                        @synchronized (localFilePath)
                        {
                            NSArray* resultJSONArray = response.param;
                            NSDictionary* md5JSONDict = resultJSONArray[1];
                            remoteMD5 = md5JSONDict[@"md5sum"];
                            NSLog(@"downloadFileChunk : #1 md5(&%ld, %ld)=%@, remoteMD5(&%ld, %ld)=%@", (long)&md5,(long)md5,md5, (long)&remoteMD5,(long)remoteMD5,remoteMD5);
                        }
                        
                        invokeCallbackBlock(YES, nil, nil);
                    }
                    else
                    {
                        NSError* error = [NSError errorWithDomain:@"com.madv360.getfilefailed" code:-1 userInfo:nil];
                        NSString* errMsg = [ErrMsgPrefix_GetFileResultResponse stringByAppendingString:response.type];
                        invokeCallbackBlock(YES, error, errMsg);
                    }
                    
                    return YES;
                }
                else
                {
                    return NO;
                }
            } sendErrorHandler:nil receiveErrorHandler:^(NSError *error, NSString *errMsg, BOOL *finish) {
                errMsg = [ErrMsgPrefix_GetFileResultReceive stringByAppendingString:errMsg];
                invokeCallbackBlock(YES, error, errMsg);
            }];
            chunkCompleteResponse.identifier = [NSString stringWithFormat:@"chunkCompleteResponse : %@", [NSValue valueWithRange:chunkRange]];
            [tcpMM addMessagerToReadQueue:chunkCompleteResponse];
        }
        
        return YES;
    } sendErrorHandler:^(NSError *error, NSString *errMsg, BOOL *finish)
    {
        errMsg = [ErrMsgPrefix_GetFileSend stringByAppendingString:errMsg];
        invokeCallbackBlock(YES, error, errMsg);
    } receiveErrorHandler:^(NSError *error, NSString *errMsg, BOOL *finish)
    {
        errMsg = [ErrMsgPrefix_GetFileReceive stringByAppendingString:errMsg];
        invokeCallbackBlock(YES, error, errMsg);
    }];
    getFileRequest.identifier = [NSString stringWithFormat:@"getFileRequest : %@", getFileRequestDict];
    
    TCPDataTransfererReceiveCallback dataReceiveBlock = ^int(uint8_t *data, int length, BOOL *finish) {
        if (!buffer)
            return 0;
        
        [getFileRequest refreshTimeoutTimer];
        [chunkCompleteResponse refreshTimeoutTimer];
        
        if (data)
        {
            if (receivedBytes + length > chunkRange.length)
            {
                NSLog(@"Received bytes out of range!");
                length = (int) chunkRange.length - receivedBytes;
            }
            memcpy(buffer + receivedBytes, data, length);
        }
        
        receivedBytes += length;
        
        NSValue* nvRange = [NSValue valueWithRange:chunkRange];
        if (receivedBytes >= chunkRange.length)
        {
            NSLog(@"requestAndDownloadFileChunk $ Success in downloading %@", nvRange);
            if (finish)
            {
                *finish = YES;
            }
            
            saveFileChunk(localFilePath, (int)chunkRange.location, (const char*) buffer, (int)chunkRange.length, 0, (int)chunkRange.length);
            NSString* md5Str = md5sum(buffer, (int)chunkRange.length);
            @synchronized (localFilePath)
            {
                md5 = md5Str;
                NSLog(@"Save chunk to (%ld, %ld), md5sum = %@", chunkRange.location, chunkRange.length, md5);
                NSLog(@"downloadFileChunk : #0 md5(&%ld, %ld)=%@, remoteMD5(&%ld, %ld)=%@", (long)&md5,(long)md5,md5, (long)&remoteMD5,(long)remoteMD5,remoteMD5);
            }
            
            if (progressCallback)
            {
                dispatch_async(callbackQueue, ^{
                    progressCallback(nvRange, receivedBytes);
                });
            }
            
            invokeCallbackBlock(NO, nil, nil);
        }
        else
        {
            NSLog(@"(nvActualRange, receivedBytes) = (%@, %d)", nvRange, receivedBytes);
            if (progressCallback)
            {
                dispatch_async(callbackQueue, ^{
                    progressCallback(nvRange, receivedBytes);
                });
            }
        }
        return length;
    };
    
    TCPDataTransfererTimeoutCallback dataTimeoutBlock = ^{
        NSError* error = [NSError errorWithDomain:@"com.madv360.exception.socketerror.downloading" code:errno userInfo:nil];
        invokeCallbackBlock(NO, error, @"timeout");
    };
    
    TCPDataTransfererErrorCallback dataErrorBlock = ^(NSError* error) {
        NSString* errMsg = [NSString stringWithUTF8String:strerror((int) error.code)];
        NSLog(@"requestAndDownloadFileChunk $ Error in downloading %@, %@", [NSValue valueWithRange:chunkRange], error);
        invokeCallbackBlock(NO, error, errMsg);
    };
    
    chunkDownloadHandler.receiveCallback = dataReceiveBlock;
    chunkDownloadHandler.timeoutCallback = dataTimeoutBlock;
    chunkDownloadHandler.errorCallback = dataErrorBlock;
    
    transferer.receiver = chunkDownloadHandler;
    NSLog(@"Set transfer.handler = %@", chunkDownloadHandler);
    
    [transferer startReceiving:10];
    [tcpMM addRequest:getFileRequest];
    
    NSLog(@"requestAndDownloadFileChunk : offset = %ld", chunkRange.location);
}

void uploadFileChunk(NSString* remoteFilePath, NSString* localFilePath, NSMutableArray* notUploadedChunks, int sessionID, dispatch_queue_t callbackQueue, CallbackBlock callback, void(^progressCallback)(NSValue* chunk, NSUInteger coveredChunkBytes)) {
    if (!notUploadedChunks) return;
    
    NSRange range;
    if (notUploadedChunks.count > 0)
    {
        range = [[notUploadedChunks firstObject] rangeValue];
        [notUploadedChunks removeObjectAtIndex:0];
    }
    else
    {
        FILE* fp = fopen(localFilePath.UTF8String, "rb");
        fseek(fp, 0, SEEK_END);
        range = NSMakeRange(0, ftell(fp));
        fclose(fp);
    }
    
    if (range.length > FileChunkSize)
    {
        [notUploadedChunks addObject:[NSValue valueWithRange:NSMakeRange(range.location + FileChunkSize, range.length - FileChunkSize)]];
        range.length = FileChunkSize;
    }
    
    // File Upload Handler :
    __block BOOL allSent = NO;
    __block NSString* remoteMD5 = nil;
    
    __block int readBytes = 0;
    __block int sentBytes = 0;
    __block NSRange actualRange = NSMakeRange(range.location, range.length);
    NSValue* nvActualRange = [NSValue valueWithRange:actualRange];
    
    uint8_t* data = (uint8_t*) malloc(range.length);
    loadFileChunk(data, 0, localFilePath, (int)range.location, (int)range.length);///!!!TO BE OPTIMIZED
    NSString* md5 = md5sum(data, (int)range.length);
    free(data);
    
    void(^uploadErrorBlock)(NSError* error) = ^(NSError *error) {
        if (callback)
        {
            NSLog(@"requestAndUploadFileChunk $ Error in uploading %@, %@", nvActualRange, error);
            dispatch_async(callbackQueue, ^{
                callback(nvActualRange, error, [NSString stringWithUTF8String:strerror((int) error.code)]);
            });
        }
    };
    
    TCPDataSender* chunkUploader = [[TCPDataSender alloc] initWithDataPrepareBlock:^int(uint8_t *data, int length) {
        int size = (int)range.length - readBytes;
        size = (size > length ? length : size);
        int loadedBytes = (0 >= size ? 0 : loadFileChunk(data, 0, localFilePath, (int)range.location + readBytes, size));
        readBytes += loadedBytes;
        return loadedBytes;
    } sendCallback:^BOOL(uint8_t *data, int length) {
        sentBytes += length;
        if (sentBytes >= range.length)
        {
            if (progressCallback)
            {
                dispatch_async(callbackQueue, ^{
                    progressCallback(nvActualRange, range.length);
                });
            }
            
            @synchronized(nvActualRange)
            {
                allSent = YES;
                NSLog(@"uploadFileChunk : #0 md5(%ld)=%@, remoteMD5(%ld)=%@", (long)&md5,md5, (long)&remoteMD5,remoteMD5);
                if ([md5 isEqualToString:remoteMD5])
                {
                    if (callback)
                    {
                        dispatch_async(callbackQueue, ^{
                            callback(nvActualRange, nil,nil);
                        });
                    }
                    NSLog(@"(nvActualRange, sentBytes) = (%@, DONE)", nvActualRange);
                }
                else if (md5 && remoteMD5)
                {
                    NSLog(@"uploadFileChunk : #0 MD5 Check Failed");
                }
            }
            return YES;
        }
        else
        {
            if (progressCallback)
            {
                dispatch_async(callbackQueue, ^{
                    progressCallback(nvActualRange, sentBytes);
                });
            }
            return NO;
        }
    } timeoutCallback:^{
        NSError* error = [NSError errorWithDomain:@"com.madv360.exception.socketerror.uploading" code:errno userInfo:nil];
        if (callback)
        {
            NSLog(@"requestAndUploadFileChunk $ Timeout in uploading %@", nvActualRange);
            dispatch_async(callbackQueue, ^{
                callback(nvActualRange, error,@"timeout");
            });
        }
    } errorCallback:uploadErrorBlock];
    
    TCPMessageManager* tcpMM = [TCPMessageManager sharedInstance];
    TCPErrorHandlerBlock errorHandler = ^(NSError *error, NSString *errMsg, BOOL *finish) {
        NSValue* nvRange = [NSValue valueWithRange:range];
        if (callback)
        {
            dispatch_async(callbackQueue, ^{
                callback(nvRange, error, errMsg);
            });
        }
    };
    
    // {"token":1,"msg_id":1286,"param":"tmp/SD0/DCIM/140101100/1.JPG","offset":0,"size":2287780,"md5sum":"d1aca017111b42b3b94c79250b0c7a7e"}
    NSDictionary* putFileRequestDict = @{@"token":@(sessionID), @"msg_id":@(1286), @"param":remoteFilePath, @"offset":@(range.location), @"size":@(range.length), @"md5sum":md5};
    TCPJSONMessager* putFileRequest = [[AMBATCPJSONRequest alloc] initWithRequestDict:putFileRequestDict responseClass:AMBAResponseInfo.class receiveBlock:^BOOL(AMBAResponseInfo* response) {
        NSLog(@"putFileResonse : %@", response);
        
        NSInteger rval = response.rval;
        if (rval != 0)
        {
            NSString* errMsg0 = [response description];
            NSError* error0 = [NSError errorWithDomain:@"com.madv360.ambacomm.putfilereqeustfailed" code:rval userInfo:@{@"errMsg":errMsg0}];
            uploadErrorBlock(error0);
        }
        else
        {
            TCPDataTransferer* transferer = [TCPDataTransferer sharedInstance];
            transferer.sender = chunkUploader;
            [transferer startSending];
            NSLog(@"Set transfer.sender = %@", chunkUploader);
        }
        return YES;
    } sendErrorHandler:errorHandler receiveErrorHandler:errorHandler];
    putFileRequest.identifier = [NSString stringWithFormat:@"putFileRequest : %@", putFileRequestDict];
    
    [tcpMM addRequest:putFileRequest];
    
    TCPJSONMessager* chunkCompleteResponse = [[AMBATCPJSONRequest alloc] initWithRequestDict:nil receiveBlock:^BOOL(AMBAResponseInfo* response) {
        if (response.msg_id == 7 && [response.type containsString:@"put_file_"])
        {
            if ([response.type containsString:@"put_file_complete"])
            {
                NSArray* resultJSONArray = response.param;
                NSDictionary* md5JSONDict = resultJSONArray[1];
                remoteMD5 = md5JSONDict[@"md5sum"];
                NSLog(@"uploadFileChunk : #1 md5(%ld)=%@, remoteMD5(%ld)=%@", (long)&md5,md5, (long)&remoteMD5,remoteMD5);
                if ([md5 isEqualToString:remoteMD5])
                {
                    @synchronized(nvActualRange)
                    {
                        if (allSent)
                        {
                            if (callback)
                            {
                                dispatch_async(callbackQueue, ^{
                                    callback(nvActualRange, nil,nil);
                                });
                            }
                            NSLog(@"(nvActualRange, sentBytes) = (%@, DONE)", nvActualRange);
                        }
                    }
                    return YES;
                }
                else if (md5 && remoteMD5)
                {
                    NSLog(@"uploadFileChunk : #1 MD5 Check Failed");
                }
            }
            
            TCPDataTransferer* transferer = [TCPDataTransferer sharedInstance];
            TCPDataSender* sender = [transferer getSender:YES];
            if (sender == chunkUploader) ///???
            {
                NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
                if (remoteMD5)
                {
                    [userInfo setObject:remoteMD5 forKey:@"md5sum"];
                }
                if (md5)
                {
                    [userInfo setObject:md5 forKey:@"myMD5sum"];
                }
                NSError* error = [NSError errorWithDomain:@"com.madv360.exception.socketerror.uploading" code:-17 userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
                if (callback)
                {
                    NSLog(@"requestAndUploadFileChunk $ Upload failure response %@", nvActualRange);
                    dispatch_async(callbackQueue, ^{
                        callback(nvActualRange, error, @"failed");
                    });
                }
            }
            
            return YES;
        }
        return NO;
    } sendErrorHandler:nil receiveErrorHandler:^(NSError *error, NSString *errMsg, BOOL *finish) {
        TCPDataTransferer* transferer = [TCPDataTransferer sharedInstance];
        TCPDataSender* sender = [transferer getSender:YES];
        if (sender == chunkUploader) ///???
        {
            NSError* error = [NSError errorWithDomain:@"com.madv360.exception.socketerror.uploading" code:-18 userInfo:nil];
            if (callback)
            {
                NSLog(@"requestAndUploadFileChunk $ Upload result response not received.%@", nvActualRange);
                dispatch_async(callbackQueue, ^{
                    callback(nvActualRange, error, @"failed");
                });
            }
        }
    }];
    chunkCompleteResponse.identifier = [NSString stringWithFormat:@"chunkCompleteResponse : %@", [NSValue valueWithRange:range]];
    [tcpMM addMessagerToReadQueue:chunkCompleteResponse];
    
    NSLog(@"requestAndUploadFileChunk : offset = %ld", range.location);
}

UIAlertController* alertWithResponse(UIViewController* parentViewController, id responseObject, NSError* error, NSString* errMsg) {
    NSString* str = [NSString stringWithFormat:@"Response:%@\nError:%@\nErrMsg:%@", responseObject, error, errMsg];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:str preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action];
    [parentViewController presentViewController:alert animated:NO completion:nil];
    return alert;
}
//*/
