//
//  MVMediaManagerCase.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/9/1.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVMediaManagerCase.h"

@interface MVMediaManagerCase()
@property(nonatomic,strong)NSMutableArray<id<MVMediaDataSourceObserver>> * dataSourceObserverArr;
@property(nonatomic,strong)NSMutableArray<id<MVMediaDownloadStatusObserver>> * downloadStatusObserverArr;
@end

@implementation MVMediaManagerCase

- (NSMutableArray<id<MVMediaDataSourceObserver>> *)dataSourceObserverArr
{
    if (_dataSourceObserverArr==nil) {
        _dataSourceObserverArr=[[NSMutableArray alloc] init];
    }
    return _dataSourceObserverArr;
}
- (NSMutableArray<id<MVMediaDownloadStatusObserver>> *)downloadStatusObserverArr
{
    if (_downloadStatusObserverArr==nil) {
        _downloadStatusObserverArr=[[NSMutableArray alloc] init];
    }
    return _downloadStatusObserverArr;
}

- (void)addMediaDataSourceObserver:(id<MVMediaDataSourceObserver>)observer
{
    [self.dataSourceObserverArr addObject:observer];
}
- (void)removeMediaDataSourceObserver:(id<MVMediaDataSourceObserver>)observer
{
    [self.dataSourceObserverArr removeObject:observer];
}

- (void)addMediaDownloadStatusObserver:(id<MVMediaDownloadStatusObserver>)observer
{
    [self.downloadStatusObserverArr addObject:observer];
}

- (void)removeMediaDownloadStatusObserver:(id<MVMediaDownloadStatusObserver>)observer
{
    [self.downloadStatusObserverArr removeObject:observer];
}

- (BOOL)isCameraMediaLibraryAvailable
{
    return true;
}

#pragma mark --获取media--
-(NSArray<MVMedia*>*) cameraMedias:(BOOL)forceRefresh
{
    NSMutableArray * medias=[[NSMutableArray alloc] init];
    MVMedia * media1=[[MVMedia alloc] init];
    media1.mediaType=    MVMediaTypePhoto;
    media1.cameraUUID=@"1";
    media1.remotePath=@"1";
    media1.localPath=@"";
    media1.createDate=[NSDate date];
    media1.size=10223;
    media1.downloadedSize=0;
    media1.downloadStatus=MVMediaDownloadStatusNone;
    [medias addObject:media1];
    
    MVMedia * media2=[[MVMedia alloc] init];
    media2.mediaType=    MVMediaTypePhoto;
    media2.cameraUUID=@"1";
    media2.remotePath=@"2";
    media2.localPath=@"";
    media2.downloadStatus=MVMediaDownloadStatusDownloading;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd"];
    NSDate *destDate= [dateFormatter dateFromString:@"2016-09-12"];
    media2.createDate=destDate;
    media2.size=10227;
    media2.downloadedSize=10000;
    [medias addObject:media2];
    
    MVMedia * media3=[[MVMedia alloc] init];
    media3.mediaType=    MVMediaTypeVideo;
    media3.cameraUUID=@"1";
    media3.remotePath=@"3";
    media3.localPath=@"";
    media3.createDate=[dateFormatter dateFromString:@"2016-09-11"];
    media3.size=10227;
    media3.downloadedSize=3034;
    media3.videoDuration=1000;
    media3.downloadStatus=MVMediaDownloadStatusDownloading;
    [medias addObject:media3];
    
    MVMedia * media4=[[MVMedia alloc] init];
    media4.mediaType=    MVMediaTypeVideo;
    media4.cameraUUID=@"1";
    media4.remotePath=@"4";
    media4.localPath=@"";
    media4.createDate=[dateFormatter dateFromString:@"2016-09-10"];
    media4.size=10227;
    media4.downloadedSize=0;
    media4.videoDuration=100;
    media4.downloadStatus=MVMediaDownloadStatusNone;
    [medias addObject:media4];
    
//    [self performSelector:@selector(didCameraMediasReloaded) withObject:nil afterDelay:10];
    return medias;
}
-(UIImage *) getThumbnailImage:(MVMedia *) media
{
    UIImage * image=[UIImage imageNamed:@"background.png"];
    return image;
}
- (void)didCameraMediasReloaded
{
    for(id<MVMediaDataSourceObserver> delegate in self.dataSourceObserverArr)
    {
        if ([delegate respondsToSelector:@selector(didCameraMediasReloaded:dataSetEvent:errorCode:)]) {

            NSMutableArray * medias=[[NSMutableArray alloc] init];
            MVMedia * media1=[[MVMedia alloc] init];
            media1.mediaType=    MVMediaTypePhoto;
            media1.cameraUUID=@"1";
            media1.remotePath=@"1";
            media1.localPath=@"";
            media1.createDate=[NSDate date];
            media1.size=10223;
            media1.downloadedSize=0;
            media1.downloadStatus=MVMediaDownloadStatusPending;
            [medias addObject:media1];
            
            MVMedia * media2=[[MVMedia alloc] init];
            media2.mediaType=    MVMediaTypePhoto;
            media2.cameraUUID=@"1";
            media2.remotePath=@"2";
            media2.localPath=@"";
            media2.downloadStatus=MVMediaDownloadStatusDownloading;
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat: @"yyyy-MM-dd"];
            NSDate *destDate= [dateFormatter dateFromString:@"2016-09-12"];
            media2.createDate=destDate;
            media2.size=10227;
            media2.downloadedSize=10000;
            [medias addObject:media2];
            
            MVMedia * media3=[[MVMedia alloc] init];
            media3.mediaType=    MVMediaTypeVideo;
            media3.cameraUUID=@"1";
            media3.remotePath=@"3";
            media3.localPath=@"";
            media3.createDate=[dateFormatter dateFromString:@"2016-09-11"];
            media3.size=10227;
            media3.downloadedSize=3034;
            media3.videoDuration=1000;
            media3.downloadStatus=MVMediaDownloadStatusDownloading;
            [medias addObject:media3];
            [delegate didCameraMediasReloaded:[[NSMutableArray alloc] init] dataSetEvent:DataSetEventRefresh errorCode:0];
        }
    }
}

- (BOOL)getMediaInfo:(MVMedia *)media
{
    return true;
}

- (NSArray<MVMedia*>*) localMedias:(BOOL)forceRefresh
{
    NSMutableArray * medias=[[NSMutableArray alloc] init];
    MVMedia * media1=[[MVMedia alloc] init];
    media1.mediaType=    MVMediaTypePhoto;
    media1.cameraUUID=@"";
    media1.remotePath=@"";
    media1.localPath=@"1";
    media1.createDate=[NSDate date];
    media1.modifyDate=[NSDate date];
    media1.size=10223;
    media1.downloadedSize=1023;
    [medias addObject:media1];
    
    MVMedia * media2=[[MVMedia alloc] init];
    media2.mediaType=    MVMediaTypePhoto;
    media2.cameraUUID=@"";
    media2.remotePath=@"";
    media2.localPath=@"2";
    media2.downloadStatus=MVMediaDownloadStatusDownloading;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd"];
    NSDate *destDate= [dateFormatter dateFromString:@"2016-09-12"];
    media2.createDate=destDate;
    media2.modifyDate=destDate;
    media2.size=10227;
    [medias addObject:media2];
    
    MVMedia * media3=[[MVMedia alloc] init];
    media3.mediaType=    MVMediaTypeVideo;
    media3.cameraUUID=@"";
    media3.remotePath=@"";
    media3.localPath=@"3";
    media3.createDate=[dateFormatter dateFromString:@"2016-09-12"];
    media3.modifyDate=media3.createDate;
    media3.size=10227;
    media3.videoDuration=1000;
    [medias addObject:media3];
    
    MVMedia * media4=[[MVMedia alloc] init];
    media4.mediaType=    MVMediaTypeVideo;
    media4.cameraUUID=@"";
    media4.remotePath=@"";
    media4.localPath=@"4";
    media4.createDate=[dateFormatter dateFromString:@"2016-09-11"];
    media4.modifyDate=media4.createDate;
    media4.size=10227;
    media4.videoDuration=100;
    [medias addObject:media4];
    [self performSelector:@selector(didLocalMediasReloaded) withObject:nil afterDelay:10];
    return medias;
}

- (void)didLocalMediasReloaded
{
    for(id<MVMediaDataSourceObserver> delegate in self.dataSourceObserverArr)
    {
        if ([delegate respondsToSelector:@selector(didLocalMediasReloaded:dataSetEvent:)]) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat: @"yyyy-MM-dd"];
            NSMutableArray * medias=[[NSMutableArray alloc] init];
            
//            MVMedia * media0=[[MVMedia alloc] init];
//            media0.mediaType=    MVMediaTypePhoto;
//            media0.cameraUUID=@"";
//            media0.remotePath=@"";
//            media0.localPath=@"0";
//            media0.createDate=[dateFormatter dateFromString:@"2016-09-12"];
//            media0.modifyDate=[dateFormatter dateFromString:@"2016-09-12"];
//            media0.size=10223;
//            media0.downloadedSize=1023;
//            [medias addObject:media0];
//            
//            MVMedia * media1=[[MVMedia alloc] init];
//            media1.mediaType=    MVMediaTypePhoto;
//            media1.cameraUUID=@"";
//            media1.remotePath=@"";
//            media1.localPath=@"1";
//            media1.createDate=[NSDate date];
//            media1.modifyDate=[NSDate date];
//            media1.size=10223;
//            media1.downloadedSize=1023;
//            [medias addObject:media1];
//            
//            MVMedia * media2=[[MVMedia alloc] init];
//            media2.mediaType=    MVMediaTypePhoto;
//            media2.cameraUUID=@"";
//            media2.remotePath=@"";
//            media2.localPath=@"2";
//            media2.downloadStatus=MVMediaDownloadStatusDownloading;
//            
//            NSDate *destDate= [dateFormatter dateFromString:@"2016-09-12"];
//            media2.createDate=destDate;
//            media2.modifyDate=destDate;
//            media2.size=10227;
//            [medias addObject:media2];
//            
//            MVMedia * media3=[[MVMedia alloc] init];
//            media3.mediaType=    MVMediaTypeVideo;
//            media3.cameraUUID=@"";
//            media3.remotePath=@"";
//            media3.localPath=@"3";
//            media3.createDate=[dateFormatter dateFromString:@"2016-09-12"];
//            media3.modifyDate=media3.createDate;
//            media3.size=10227;
//            media3.videoDuration=1000;
//            [medias addObject:media3];
            
            MVMedia * media4=[[MVMedia alloc] init];
            media4.mediaType=    MVMediaTypeVideo;
            media4.cameraUUID=@"";
            media4.remotePath=@"";
            media4.localPath=@"4";
            media4.createDate=[dateFormatter dateFromString:@"2016-09-11"];
            media4.modifyDate=media4.createDate;
            media4.size=10227;
            media4.videoDuration=600;
            [medias addObject:media4];
            
//            MVMedia * media5=[[MVMedia alloc] init];
//            media5.mediaType=    MVMediaTypeVideo;
//            media5.cameraUUID=@"";
//            media5.remotePath=@"";
//            media5.localPath=@"5";
//            media5.createDate=[dateFormatter dateFromString:@"2016-09-10"];
//            media5.modifyDate=media5.createDate;
//            media5.size=10227;
//            media5.videoDuration=100;
//            [medias addObject:media5];
            
            [delegate didLocalMediasReloaded:medias dataSetEvent:DataSetEventReplace];
        }
    }
}
- (BOOL)addDownloading:(MVMedia *)media
{
    [self performSelector:@selector(didDownloadStatusChange) withObject:nil afterDelay:1];
//    [self performSelector:@selector(didDownloadProgressChange) withObject:nil afterDelay:7];
    return true;
}

- (void)didDownloadStatusChange
{
    for(id<MVMediaDownloadStatusObserver> delegate in self.downloadStatusObserverArr)
    {
        if ([delegate respondsToSelector:@selector(didDownloadStatusChange:errorCode:ofMedia:)]) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat: @"yyyy-MM-dd"];
            MVMedia * media4=[[MVMedia alloc] init];
            media4.mediaType=    MVMediaTypeVideo;
            media4.cameraUUID=@"1";
            media4.remotePath=@"/Users/zhangqiaoge/Desktop/madvttttt.mp4";
            media4.localPath=@"";
            media4.createDate=[dateFormatter dateFromString:@"2016-09-10"];
            media4.size=10227*1024;
            media4.downloadedSize=0;
            media4.videoDuration=100;
            media4.downloadStatus=MVMediaDownloadStatusDownloading;
            [delegate didDownloadStatusChange:MVMediaDownloadStatusDownloading errorCode:0 ofMedia:media4];
        }
    }
}
- (void)didDownloadProgressChange
{
    for(id<MVMediaDownloadStatusObserver> delegate in self.downloadStatusObserverArr)
    {
        if ([delegate respondsToSelector:@selector(didDownloadProgressChange:totalBytes:ofMedia:)]) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat: @"yyyy-MM-dd"];
            MVMedia * media4=[[MVMedia alloc] init];
            media4.mediaType=    MVMediaTypeVideo;
            media4.cameraUUID=@"1";
            media4.remotePath=@"4";
            media4.localPath=@"";
            media4.createDate=[dateFormatter dateFromString:@"2016-09-10"];
            media4.size=10227;
            media4.downloadedSize=0;
            media4.videoDuration=100;
            media4.downloadStatus=MVMediaDownloadStatusDownloading;
            [delegate didDownloadProgressChange:5000 totalBytes:10227 ofMedia:media4];
        }
    }
}
- (void)deleteCameraMedias:(NSArray *)medias
{
    [self performSelector:@selector(didCameraMediasReloaded) withObject:nil afterDelay:2];
}

- (void)deleteLocalMedias:(NSArray *)medias
{
    [self performSelector:@selector(deleteLocalSuccess) withObject:nil afterDelay:2];
}
- (void)deleteLocalSuccess
{
    for(id<MVMediaDataSourceObserver> delegate in self.dataSourceObserverArr)
    {
        if ([delegate respondsToSelector:@selector(didLocalMediasReloaded:dataSetEvent:)]) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat: @"yyyy-MM-dd"];
            NSMutableArray * medias=[[NSMutableArray alloc] init];
            
            MVMedia * media0=[[MVMedia alloc] init];
            media0.mediaType=    MVMediaTypePhoto;
            media0.cameraUUID=@"";
            media0.remotePath=@"";
            media0.localPath=@"0";
            media0.createDate=[dateFormatter dateFromString:@"2016-09-12"];
            media0.modifyDate=[dateFormatter dateFromString:@"2016-09-12"];
            media0.size=10223;
            media0.downloadedSize=1023;
            [medias addObject:media0];
            
            MVMedia * media1=[[MVMedia alloc] init];
            media1.mediaType=    MVMediaTypePhoto;
            media1.cameraUUID=@"";
            media1.remotePath=@"";
            media1.localPath=@"1";
            media1.createDate=[NSDate date];
            media1.modifyDate=[NSDate date];
            media1.size=10223;
            media1.downloadedSize=1023;
            [medias addObject:media1];
            
            MVMedia * media2=[[MVMedia alloc] init];
            media2.mediaType=    MVMediaTypePhoto;
            media2.cameraUUID=@"";
            media2.remotePath=@"";
            media2.localPath=@"2";
            media2.downloadStatus=MVMediaDownloadStatusDownloading;
            
            NSDate *destDate= [dateFormatter dateFromString:@"2016-09-12"];
            media2.createDate=destDate;
            media2.modifyDate=destDate;
            media2.size=10227;
            [medias addObject:media2];
            
            MVMedia * media3=[[MVMedia alloc] init];
            media3.mediaType=    MVMediaTypeVideo;
            media3.cameraUUID=@"";
            media3.remotePath=@"";
            media3.localPath=@"3";
            media3.createDate=[dateFormatter dateFromString:@"2016-09-12"];
            media3.modifyDate=media3.createDate;
            media3.size=10227;
            media3.videoDuration=1000;
            [medias addObject:media3];
            
            MVMedia * media4=[[MVMedia alloc] init];
            media4.mediaType=    MVMediaTypeVideo;
            media4.cameraUUID=@"";
            media4.remotePath=@"";
            media4.localPath=@"4";
            media4.createDate=[dateFormatter dateFromString:@"2016-09-11"];
            media4.modifyDate=media4.createDate;
            media4.size=10227;
            media4.videoDuration=100;
            [medias addObject:media4];
            
            [delegate didLocalMediasReloaded:nil dataSetEvent:DataSetEventRefresh];
        }
    }

}

-(NSArray<MVMedia *> *) mediasInDownloader
{
    NSMutableArray * medias=[[NSMutableArray alloc] init];
    MVMedia * media1=[[MVMedia alloc] init];
    media1.mediaType=    MVMediaTypePhoto;
    media1.cameraUUID=@"1";
    media1.remotePath=@"/Users/zhangqiaoge/Desktop/madv223.jpg";
    media1.localPath=@"";
    media1.createDate=[NSDate date];
    media1.size=10223*1024;
    media1.downloadedSize=0;
    media1.downloadStatus=MVMediaDownloadStatusPending;
    [medias addObject:media1];
    
    MVMedia * media2=[[MVMedia alloc] init];
    media2.mediaType=    MVMediaTypePhoto;
    media2.cameraUUID=@"1";
    media2.remotePath=@"/Users/zhangqiaoge/Desktop/madvrrrr.jpg";
    media2.localPath=@"";
    media2.downloadStatus=MVMediaDownloadStatusDownloading;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd"];
    NSDate *destDate= [dateFormatter dateFromString:@"2016-09-12"];
    media2.createDate=destDate;
    media2.size=10227*1024;
    media2.downloadedSize=10000*1024;
    [medias addObject:media2];
    
    MVMedia * media3=[[MVMedia alloc] init];
    media3.mediaType=    MVMediaTypeVideo;
    media3.cameraUUID=@"1";
    media3.remotePath=@"/Users/zhangqiaoge/Desktop/madv360.mp4";
    media3.localPath=@"";
    media3.createDate=[dateFormatter dateFromString:@"2016-09-11"];
    media3.size=10227*1024;
    media3.downloadedSize=1500*1024;
    media3.videoDuration=1000;
    media3.downloadStatus=MVMediaDownloadStatusStopped;
    [medias addObject:media3];
    
    MVMedia * media4=[[MVMedia alloc] init];
    media4.mediaType=    MVMediaTypeVideo;
    media4.cameraUUID=@"1";
    media4.remotePath=@"/Users/zhangqiaoge/Desktop/madvttttt.mp4";
    media4.localPath=@"";
    media4.createDate=[dateFormatter dateFromString:@"2016-09-10"];
    media4.size=10227*1024;
    media4.downloadedSize=0;
    media4.videoDuration=100;
    media4.downloadStatus=MVMediaDownloadStatusError;
    [medias addObject:media4];
    
//    [self performSelector:@selector(downloadProgressChange) withObject:nil afterDelay:20];
    return medias;
}
- (void)downloadProgressChange
{
    for(id<MVMediaDownloadStatusObserver> delegate in self.downloadStatusObserverArr)
    {
//        if ([delegate respondsToSelector:@selector(didDownloadProgressChange:totalBytes:ofMedia:)]) {
//            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//            [dateFormatter setDateFormat: @"yyyy-MM-dd"];
//            MVMedia * media3=[[MVMedia alloc] init];
//            media3.mediaType=    MVMediaTypeVideo;
//            media3.cameraUUID=@"1";
//            media3.remotePath=@"/Users/zhangqiaoge/Desktop/madv360.mp4";
//            media3.localPath=@"";
//            media3.createDate=[dateFormatter dateFromString:@"2016-09-11"];
//            media3.size=10227*1024;
//            media3.downloadedSize=1500*1024;
//            media3.videoDuration=1000;
//            media3.downloadStatus=MVMediaDownloadStatusStopped;
//            [delegate didDownloadProgressChange:8000*1024 totalBytes:10227*1024 ofMedia:media3];
//        }
        if ([delegate respondsToSelector:@selector(didDownloadStatusChange:errorCode:ofMedia:)]) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat: @"yyyy-MM-dd"];
            MVMedia * media3=[[MVMedia alloc] init];
            media3.mediaType=    MVMediaTypeVideo;
            media3.cameraUUID=@"1";
            media3.remotePath=@"/Users/zhangqiaoge/Desktop/madv360.mp4";
            media3.localPath=@"";
            media3.createDate=[dateFormatter dateFromString:@"2016-09-11"];
            media3.size=10227*1024;
            media3.downloadedSize=1500*1024;
            media3.videoDuration=1000;
            media3.downloadStatus=MVMediaDownloadStatusFinished;
            [delegate didDownloadStatusChange:MVMediaDownloadStatusFinished errorCode:0 ofMedia:media3];
        }
    }
}
- (void)removeDownloading:(MVMedia *)media
{}
- (void)stopDownloading:(MVMedia *)media
{
    [self performSelector:@selector(stopStatusChange) withObject:nil afterDelay:1];
}
- (void)stopStatusChange
{
    for(id<MVMediaDownloadStatusObserver> delegate in self.downloadStatusObserverArr)
    {
        if ([delegate respondsToSelector:@selector(didDownloadStatusChange:errorCode:ofMedia:)]) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat: @"yyyy-MM-dd"];
            MVMedia * media1=[[MVMedia alloc] init];
            media1.mediaType=    MVMediaTypePhoto;
            media1.cameraUUID=@"1";
            media1.remotePath=@"/Users/zhangqiaoge/Desktop/madv223.jpg";
            media1.localPath=@"";
            media1.createDate=[NSDate date];
            media1.size=10223*1024;
            media1.downloadedSize=0;
            media1.downloadStatus=MVMediaDownloadStatusStopped;
            [delegate didDownloadStatusChange:MVMediaDownloadStatusStopped errorCode:0 ofMedia:media1];
        }
    }

}


@end
