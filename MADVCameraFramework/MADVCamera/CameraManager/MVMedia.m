//
//  MVMedia.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/10.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVMedia.h"
#import "MVCameraClient.h"
#import "RealmSerialQueue.h"
#import "helper.h"
#import "z_Sandbox.h"
#import "KxMovieDecoder.h"

@implementation MVMedia

static NSMutableDictionary * downloadStatusOfMediaRemoteDict;

- (void) setCameraUUID:(NSString *)cameraUUID {
    self.dbCameraUUID = [MVCameraClient formattedCameraUUID:cameraUUID];
}
-(NSString *) cameraUUID {
    return [self dbValueForKeyPath:@"dbCameraUUID"];
}

- (void) setRemotePath:(NSString *)remotePath {
    self.dbRemotePath = remotePath;
}
-(NSString *) remotePath {
    return [self dbValueForKeyPath:@"dbRemotePath"];
}

- (void) setLocalPath:(NSString *)localPath {
    self.dbLocalPath = localPath;
}
-(NSString *) localPath {
    return [self dbValueForKeyPath:@"dbLocalPath"];
}

- (void) setThumbnailImagePath:(NSString *)thumbnailImagePath {
    self.dbThumbnailImagePath = thumbnailImagePath;
}
-(NSString *) thumbnailImagePath {
    return [self dbValueForKeyPath:@"dbThumbnailImagePath"];
}

- (void) setSnapshotImagePath:(NSString *)snapshotImagePath {
    self.dbSnapshotImagePath = snapshotImagePath;
}
-(NSString *) snapshotImagePath {
    return [self dbValueForKeyPath:@"dbSnapshotImagePath"];
}

- (void) setCreateDate:(NSDate *)createDate {
    self.dbCreateDate = createDate;
}
-(NSDate *) createDate {
    return [self dbValueForKeyPath:@"dbCreateDate"];
}

- (void) setModifyDate:(NSDate *)modifyDate {
    self.dbModifyDate = modifyDate;
}
-(NSDate *) modifyDate {
    return [self dbValueForKeyPath:@"dbModifyDate"];
}

- (void) setSize:(NSInteger)size {
    if (size > 0 && self.dbSize > 0 && size != self.dbSize) {
        NSLog(@"This could not be possible!");
//        @throw [NSString stringWithFormat:@"This could not be possible! : size=%ld, dbSize=%ld", size, self.dbSize];
    }
    self.dbSize = size;
}
-(NSInteger) size {
    return [[self dbValueForKeyPath:@"dbSize"] integerValue];
}

- (void) setDownloadedSize:(NSInteger)downloadedSize {
    self.dbDownloadedSize = downloadedSize;
}
-(NSInteger) downloadedSize {
    NSInteger size=[[self dbValueForKeyPath:@"dbDownloadedSize"] integerValue];
    _finishDownloadedSize=size;
    return size;
}

- (void) setDownloadResumeData:(NSData *)downloadResumeData {
    self.dbDownloadResumeData = downloadResumeData;
}
-(NSData*) downloadResumeData {
    NSData* data = [self dbValueForKeyPath:@"dbDownloadResumeData"];
    return data;
}

- (void) setVideoDuration:(CGFloat)videoDuration {
    NSLog(@"MVMedia$setVideoDuration # videoDuration = %f", videoDuration);
    self.dbVideoDuration = videoDuration;
}
-(CGFloat) videoDuration {
    return [[self dbValueForKeyPath:@"dbVideoDuration"] integerValue];
}

- (void) setFilterID:(NSInteger)filterID {
    self.dbFilterID = filterID;
}
-(NSInteger) filterID {
    return [[self dbValueForKeyPath:@"dbFilterID"] integerValue];
}

- (void) setMediaType:(MVMediaType)mediaType {
    self.dbMediaType = mediaType;
}
- (MVMediaType) mediaType {
    return (MVMediaType)[[self dbValueForKeyPath:@"dbMediaType"] integerValue];
}

- (void) setIsStitched:(BOOL)isStitched {
    self.dbIsStitched = isStitched;
}
-(BOOL) isStitched {
    return [[self dbValueForKeyPath:@"dbIsStitched"] integerValue];
}

- (void) setGyroMatrixString:(NSString*)gyroMatrixString {
    self.dbGyroMatrixString = gyroMatrixString;
}
-(NSString*) gyroMatrixString {
    return (NSString*) [self dbValueForKeyPath:@"dbGyroMatrixString"];
}

- (void) setVideoCaptureResolution:(VideoCaptureResolution)videoCaptureResolution {
    self.dbVideoCaptureResolution = videoCaptureResolution;
}
-(VideoCaptureResolution) videoCaptureResolution {
    return (VideoCaptureResolution) [[self dbValueForKeyPath:@"dbVideoCaptureResolution"] integerValue];
}

- (void)setLocalIdentifier:(NSString *)localIdentifier
{
    self.dbLocalIdentifier = localIdentifier;
}
- (NSString *)localIdentifier
{
    return [self dbValueForKeyPath:@"dbLocalIdentifier"];
}
- (void)setShareLocalIdentifier:(NSString *)shareLocalIdentifier
{
    self.dbShareLocalIdentifier = shareLocalIdentifier;
}
- (NSString *)shareLocalIdentifier
{
    return [self dbValueForKeyPath:@"dbShareLocalIdentifier"];
}
- (void)setShotDateTime:(NSString *)shotDateTime
{
    self.dbShotDateTime = shotDateTime;
}
- (NSString *)shotDateTime
{
    return [self dbValueForKeyPath:@"dbShotDateTime"];
}

- (void)setModel:(NSString *)model
{
    self.dbModel = model;
}
- (NSString *)model
{
    return [self dbValueForKeyPath:@"dbModel"];
}
- (void)setXResolution:(int)xResolution
{
    self.dbXResolution = xResolution;
}
- (int)xResolution
{
    return [[self dbValueForKeyPath:@"dbXResolution"] intValue];
}
- (void)setYResolution:(int)yResolution
{
    self.dbYResolution = yResolution;
}
- (int)yResolution
{
    return [[self dbValueForKeyPath:@"dbYResolution"] intValue];
}
- (void)setExposureTime:(NSString *)exposureTime
{
    self.dbExposureTime = exposureTime;
}
- (NSString *)exposureTime
{
    return [self dbValueForKeyPath:@"dbExposureTime"];
}
- (void)setISO:(long)ISO
{
    self.dbISO = ISO;
}
- (long)ISO
{
    return [[self dbValueForKeyPath:@"dbISO"] longValue];
}
- (void)setWhiteBalance:(int)whiteBalance
{
    self.dbWhiteBalance = whiteBalance;
}
- (int)whiteBalance
{
    return [[self dbValueForKeyPath:@"dbWhiteBalance"] intValue];
}

- (void)setLongitude:(float)longitude
{
    self.dbLongitude = longitude;
}
- (float)longitude
{
    return [[self dbValueForKeyPath:@"dbLongitude"] floatValue];
}
- (void)setLatitude:(float)latitude
{
    self.dbLatitude = latitude;
}
- (float)latitude
{
    return [[self dbValueForKeyPath:@"dbLatitude"] floatValue];
}
- (void)setAltitude:(float)altitude
{
    self.dbAltitude = altitude;
}
- (float)altitude
{
    return [[self dbValueForKeyPath:@"dbAltitude"] floatValue];
}
- (void)setExposureBiasValue:(NSString *)exposureBiasValue
{
    self.dbExposureBiasValue = exposureBiasValue;
}
- (NSString *)exposureBiasValue
{
    return [self dbValueForKeyPath:@"dbExposureBiasValue"];
}
- (void)setIsTimeElapsedVideo:(BOOL)isTimeElapsedVideo
{
    self.isDbTimeElapsedVideo = isTimeElapsedVideo;
}
- (BOOL)isTimeElapsedVideo
{
    return [[self dbValueForKeyPath:@"dbExposureBiasValue"] boolValue];
}

- (void)setFps:(CGFloat)fps
{
    self.dbFps = fps;
}
- (CGFloat)fps
{
    return [[self dbValueForKeyPath:@"dbFps"] doubleValue];
}

- (id) localFilePathSync:(BOOL)isGetImageData {
    __block BOOL finished = NO;
    __block id ret = nil;
    NSCondition* cond = [[NSCondition alloc] init];
    ret = [self requestLocalFilePath:isGetImageData completion:^(id localPath) {
        finished = YES;
        ret = localPath;
        [cond lock];
        [cond signal];
        [cond unlock];
    }];
    if (ret)
    {
        return ret;
    }
    
    [cond lock];
    while (!finished)
    {
        [cond wait];
    }
    [cond unlock];
    return ret;
}

- (id) requestLocalFilePath:(BOOL)isGetImageData completion:(void(^)(id filePath))completionHandler{
    if (self.localPath && self.localPath.length > 0 && [z_Sandbox isFileExists:[z_Sandbox documentPath:self.localPath]])
    {
        NSString* documentFilePath = [z_Sandbox documentPath:self.localPath];
        return documentFilePath;
    }
    else if (self.localIdentifier && self.localIdentifier.length > 0)
    {
        PHImageManager* phIM = [PHImageManager defaultManager];
        NSArray* identifiers = [self.localIdentifier componentsSeparatedByString:@";"];
        if (!identifiers || 0 == identifiers.count)
        {
            if (completionHandler)
            {
                completionHandler(nil);
            }
            return nil;
        }
        
        __block BOOL anyAssetExists = NO;
        if (self.mediaType == MVMediaTypeVideo && self.videoPath && [z_Sandbox isFileExists:self.videoPath])
        {
            anyAssetExists = YES;
            return self.videoPath;
        }else
        {
            [identifiers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString* identifier = (NSString*) obj;
                if (![helper isNull:identifier]) {
                    PHAsset* asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil].firstObject;
                    if (asset)
                    {
                        *stop = YES;
                        anyAssetExists = YES;
                        if (MVMediaTypeVideo == self.mediaType)
                        {
                            PHVideoRequestOptions * options = [[PHVideoRequestOptions alloc] init];
                            options.networkAccessAllowed = YES;
                            [phIM requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                NSString * sandboxExtensionTokenKey = info[@"PHImageFileSandboxExtensionTokenKey"];
                                NSArray * arr = [sandboxExtensionTokenKey componentsSeparatedByString:@";"];
                                NSString * videoPath = [arr[arr.count - 1] substringFromIndex:9];
                                if (videoPath && videoPath.length > 0 && [z_Sandbox isFileExists:videoPath])
                                {
                                    self.avAsset = asset;
                                    self.videoPath = videoPath;
                                    if (completionHandler)
                                    {
                                        completionHandler(videoPath);
                                    }
                                }else
                                {
                                    if (completionHandler)
                                    {
                                        completionHandler(nil);
                                    }
                                }
                            }];
                            
                        }
                        else if (MVMediaTypePhoto == self.mediaType)
                        {
                            PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
                            options.networkAccessAllowed = YES;
                            [phIM requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                                if (downloadFinined)
                                {
                                    if (isGetImageData) {
                                        if (completionHandler)
                                        {
                                            completionHandler(imageData);
                                        }
                                    }else
                                    {
                                        UIImage * image = [UIImage imageWithData:imageData];
                                        if (completionHandler)
                                        {
                                            completionHandler(image);
                                        }
                                    }
                                    
                                }else
                                {
                                    if (completionHandler)
                                    {
                                        completionHandler(nil);
                                    }
                                }
                            }];
                        }
                    }
                }
                
            }];
        }
        
        
        if (!anyAssetExists)
        {
            if (completionHandler)
            {
                completionHandler(nil);
            }
            return nil;
        }
    }
    else
    {
        if (completionHandler)
        {
            completionHandler(nil);
        }
    }
    return nil;
}

+ (void) initialize {
    downloadStatusOfMediaRemoteDict = [[NSMutableDictionary alloc] init];
}

- (void) setDownloadStatus:(MVMediaDownloadStatus)downloadStatus {
    @synchronized (downloadStatusOfMediaRemoteDict)
    {
        [downloadStatusOfMediaRemoteDict setObject:@(downloadStatus) forKey:[self storageKey]];
    }
}

- (MVMediaDownloadStatus) downloadStatus {
    @synchronized (downloadStatusOfMediaRemoteDict)
    {
        id downloadStatus = [downloadStatusOfMediaRemoteDict objectForKey:[self storageKey]];
        if (downloadStatus)
        {
            return (MVMediaDownloadStatus)[downloadStatus integerValue];
        }
        else
        {
            return MVMediaDownloadStatusNone;
        }
    }
}

+ (NSString*) storageKeyWithCameraUUID:(NSString*)cameraUUID remotePath:(NSString*)remotePath localPath:(NSString*)localPath {
    NSMutableString* str = [[NSMutableString alloc] init];
    if (![helper isNull:cameraUUID])
    {
        [str appendString:cameraUUID];
    }
    if (![helper isNull:remotePath])
    {
        [str appendString:remotePath];
    }
    NSString* name = [NSString stringWithString:str];
    if ([helper isNull:name])
    {
        name = [NSString stringWithFormat:@"__%@",localPath];
    }
    name = [name stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    name = [name stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    name = [name stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    return name;
}

- (NSString*) storageKey {
    return [MVMedia storageKeyWithCameraUUID:self.cameraUUID remotePath:self.remotePath localPath:self.localPath];
}

+ (NSString*) uniqueLocalPathWithCameraUUID:(NSString*)cameraUUID remotePath:(NSString*)remotePath {
    NSString* baseName = [remotePath lastPathComponent];
    
    NSString* localFilePath = baseName;
    int prefix = 0;
    while (true)
    {
        __block BOOL exists = NO;
        [[RealmSerialQueue shareRealmQueue] sync:^{
            NSString* where = [NSString stringWithFormat:@"dbLocalPath == '%@'", localFilePath];
            RLMResults* results = [MVMedia objectsWhere:where];
            if (results && results.count > 0)
            {
                exists = YES;
            }
        }];
        
        if (!exists)
        {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[z_Sandbox documentPath:localFilePath]])
            {
                exists = YES;
            }
        }
        
        if (exists)
        {
            localFilePath = [NSString stringWithFormat:@"%d%@", prefix, baseName];
            prefix++;
        }
        else
        {
            break;
        }
    }
    return localFilePath;
}

- (BOOL) isEqualRemoteMedia:(MVMedia*)other {
    if (!other)
    {
        return false;
    }
    return ([other.cameraUUID isEqualToString:self.cameraUUID] && [other.remotePath isEqualToString:self.remotePath]);
}

+ (instancetype) create {
    __block MVMedia* ret = nil;
    [[RealmSerialQueue shareRealmQueue] sync:^{
        ret = [[MVMedia alloc] init];
    }];
    return ret;
}

+ (NSDate*) dateFromFileName:(NSString*)lowerFileName {
    NSString* extension = [lowerFileName pathExtension];
    NSString* patternString = [NSString stringWithFormat:@"[^0-9]+([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2}).*\\.%@$", extension];
    NSRegularExpression* regEx = [NSRegularExpression regularExpressionWithPattern:patternString options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray* matches = [regEx matchesInString:lowerFileName options:0 range:NSMakeRange(0, lowerFileName.length)];
    NSTextCheckingResult* result = nil;
    if (matches && matches.count > 0 && (result = matches[0]) && result.numberOfRanges > 0)
    {
        NSMutableString* dateString = [[NSMutableString alloc] init];
        for (int i=1; i<=6; ++i)
        {
            [dateString appendString:[lowerFileName substringWithRange:[result rangeAtIndex:i]]];
        }
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
        NSDate* date = [dateFormatter dateFromString:dateString];
        return date;
    }
    else
    {
        patternString = [NSString stringWithFormat:@"([0-9]{2})([0-9]{2})([0-9]{2}).*_([0-9]{2})([0-9]{2})([0-9]{2}).*\\.%@$", extension];
        regEx = [NSRegularExpression regularExpressionWithPattern:patternString options:NSRegularExpressionCaseInsensitive error:nil];
        matches = [regEx matchesInString:lowerFileName options:0 range:NSMakeRange(0, lowerFileName.length)];
        if (matches && matches.count > 0 && (result = matches[0]) && result.numberOfRanges > 0)
        {
            NSMutableString* dateString = [@"20" mutableCopy];
            for (int i=1; i<=6; ++i)
            {
                [dateString appendString:[lowerFileName substringWithRange:[result rangeAtIndex:i]]];
            }
            NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
            NSDate* date = [dateFormatter dateFromString:dateString];
            return date;
        }
    }
    return nil;
}

+ (instancetype) createWithCameraUUID:(NSString*)cameraUUID remoteFullPath:(NSString*)remoteFullPath {
    MVMedia* media = [MVMedia create];
    [media transactionWithBlock:^{
        media.remotePath = remoteFullPath;
        media.cameraUUID = cameraUUID;
        media.size = 0;
        media.downloadedSize = 0;
        
        NSString* remotePathExtension = [[remoteFullPath pathExtension] lowercaseString];
        if ([remotePathExtension isEqualToString:@"mp4"] || [remotePathExtension isEqualToString:@"mov"])
        {
            media.mediaType = MVMediaTypeVideo;
        }
        else if ([remotePathExtension isEqualToString:@"jpg"]
                 || [remotePathExtension isEqualToString:@"bmp"]
                 || [remotePathExtension isEqualToString:@"png"])
        {
            media.mediaType = MVMediaTypePhoto;
        }
        
        if (remoteFullPath)
        {
            media.createDate = [self dateFromFileName:remoteFullPath.lowercaseString];
        }
        if (!media.createDate)
        {
            media.createDate = [NSDate date];
        }
        media.modifyDate = media.createDate;
    }];
    return media;
}

+ (instancetype) querySavedMediaWithRemotePath:(NSString*)remotePath localPath:(NSString*)localPath {
    __block MVMedia* localMedia = nil;
    [[RealmSerialQueue shareRealmQueue] sync:^{
        if (![helper isNull:remotePath])
        {
            NSString* where = [NSString stringWithFormat:@"dbRemotePath == '%@'", remotePath];
            if (![helper isNull:localPath])
            {
                where = [NSString stringWithFormat:@"%@ AND dbLocalPath == '%@'",where,localPath];
            }
            else
            {
                where = [NSString stringWithFormat:@"%@ AND dbLocalPath == '%@'",where,@""];
            }
            RLMResults* results = [MVMedia objectsWhere:where];
            if (results.count > 0)
            {
                localMedia = results[0];
            }
        }
        else
        {
            NSString* where = [NSString stringWithFormat:@"dbLocalPath == '%@'",localPath];
            RLMResults* results = [MVMedia objectsWhere:where];
            if (results.count > 0)
            {
                localMedia = results[0];
            }
        }
    }];
    return localMedia;
}

+ (instancetype) querySavedMediaWithCameraUUID:(NSString*)cameraUUID remotePath:(NSString*)remotePath localPath:(NSString*)localPath {
    __block MVMedia* localMedia = nil;
    [[RealmSerialQueue shareRealmQueue] sync:^{
        if (![helper isNull:remotePath])
        {
            NSString* where = [NSString stringWithFormat:@"dbCameraUUID == '%@' AND dbRemotePath == '%@'",cameraUUID,remotePath];
            if (![helper isNull:localPath])
            {
                where = [NSString stringWithFormat:@"%@ AND dbLocalPath == '%@'",where,localPath];
            }
            else
            {
                where = [NSString stringWithFormat:@"%@ AND dbLocalPath == '%@'",where,@""];
            }
            RLMResults* results = [MVMedia objectsWhere:where];
            if (results.count > 0)
            {
                localMedia = results[0];
            }
        }
        else
        {
            NSString* where = [NSString stringWithFormat:@"dbLocalPath == '%@'",localPath];
            RLMResults* results = [MVMedia objectsWhere:where];
            if (results.count > 0)
            {
                localMedia = results[0];
            }
        }
    }];
    return localMedia;
}


+ (NSArray<MVMedia*> *) querySavedMediasWithCameraUUID:(NSString*)cameraUUID remotePath:(NSString*)remotePath localPath:(NSString*)localPath {
    NSMutableArray* localMediaArr = [[NSMutableArray alloc] init];
    [[RealmSerialQueue shareRealmQueue] sync:^{
        RLMResults* localMedias;
        if (![helper isNull:remotePath])
        {
            localMedias = [[MVMedia objectsWhere:[NSString stringWithFormat:@"dbCameraUUID == '%@' AND dbRemotePath == '%@'",cameraUUID,remotePath]] sortedResultsUsingProperty:@"dbDownloadedSize" ascending:YES];
        }
        else
        {
            localMedias = [MVMedia objectsWhere:[NSString stringWithFormat:@"dbLocalPath == '%@'",localPath]];
        }
        for (MVMedia* media in localMedias)
        {
            [localMediaArr addObject:media];
        }
    }];
    return [NSArray arrayWithArray:localMediaArr];
}

+ (NSDictionary<NSString*, MVMedia* >*) querySavedMediasWithCameraUUID:(NSString*)cameraUUID {
    NSMutableDictionary<NSString*, MVMedia* >* ret = [[NSMutableDictionary alloc] init];
    NSMutableArray<MVMedia* >* localMediasArray = [[NSMutableArray alloc] init];
    [[RealmSerialQueue shareRealmQueue] sync:^{
        RLMResults* localMedias = [[MVMedia objectsWhere:[NSString stringWithFormat:@"dbCameraUUID == '%@'",cameraUUID]] sortedResultsUsingProperty:@"dbDownloadedSize" ascending:YES];
        for (MVMedia* m in localMedias)
        {
            [localMediasArray addObject:m];
        }
    }];
    for (MVMedia* m in localMediasArray)
    {
        MVMedia* hit = [ret objectForKey:m.remotePath];
        if (!hit || hit.downloadedSize > m.downloadedSize)
        {
            [ret setObject:m forKey:m.remotePath];
        }
    }
    return ret;
}

+ (NSArray<MVMedia*> *) queryDownloadedMedias {
    NSMutableArray* mediaArr = [[NSMutableArray alloc] init];
    NSFileManager* fm = [NSFileManager defaultManager];
    [[RealmSerialQueue shareRealmQueue] sync:^{
        NSPredicate* predictate = [NSPredicate predicateWithFormat:@"dbSize > 0 AND dbDownloadedSize >= dbSize"];
        @try
        {
            RLMResults* results = [[MVMedia objectsWithPredicate:predictate] sortedResultsUsingProperty:@"dbCreateDate" ascending:NO];
            for (MVMedia * media in results)
            {
                //NSInteger size = media.size;
                //NSInteger fileSize = fileSizeAtPath([z_Sandbox documentPath:media.localPath]);
                //if (size == fileSize)
                //if ([fm fileExistsAtPath:[z_Sandbox documentPath:media.localPath]])
                {
                    [mediaArr addObject:media];
                }
            }
        }
        @catch (id ex)
        {
            NSLog(@"Exception : %@", ex);
        }
    }];
    
    NSMutableArray* mediaArr1 = [[NSMutableArray alloc] init];
    NSString * isStitchedRefresh = [helper readProfileString:@"ISSTITCHEDREFRESH"];
    for (MVMedia * media in mediaArr)
    {
        __block BOOL anyAssetExists = NO;
        NSArray* identifiers = [media.localIdentifier componentsSeparatedByString:@";"];
        [identifiers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString* identifier = (NSString*) obj;
            if (![helper isNull:identifier]) {
                PHAsset* asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil].firstObject;
                if (asset) {
                    anyAssetExists = YES;
                    *stop = YES;
                }
            }
        }];
        if ([fm fileExistsAtPath:[z_Sandbox documentPath:media.localPath]] || anyAssetExists)
        {
            if ([helper isNull:isStitchedRefresh] && media.mediaType == MVMediaTypeVideo) {
                KxMovieDecoder* decoder = [[KxMovieDecoder alloc] init];
                [decoder openFile:[media localFilePathSync:NO] error:nil];
                int64_t LutzOffset = [decoder getLutzOffset];
                int64_t LutzSize = [decoder getLutzSize];
                int xResolution = [[NSNumber numberWithUnsignedInteger:decoder.frameWidth] intValue];
                int yResolution = [[NSNumber numberWithUnsignedInteger:decoder.frameHeight] intValue];
                BOOL isTimeElapsedVideo = [decoder isTimeElapsedVideo];
                CGFloat fps = decoder.fps;
                CGFloat duration = decoder.duration;
                [decoder closeFile];
                if (LutzOffset >= 0 && LutzSize > 0)//未编辑
                {
                    [media transactionWithBlock:^{
                        media.videoDuration = duration;
                        media.fps = fps;
                        media.isStitched = NO;
                        media.xResolution = xResolution;
                        media.yResolution = yResolution;
                        media.isTimeElapsedVideo = isTimeElapsedVideo;
                    }];
                }else
                {
                    [media transactionWithBlock:^{
                        media.videoDuration = duration;
                        media.fps = fps;
                        media.isStitched = YES;
                        media.xResolution = xResolution;
                        media.yResolution = yResolution;
                        media.isTimeElapsedVideo = isTimeElapsedVideo;
                    }];
                }
                
            }
            [mediaArr1 addObject:media];
        }else
        {
            /*
          [[RealmSerialQueue shareRealmQueue] sync:^{
          [[RLMRealm defaultRealm] transactionWithBlock:^{
          [[RLMRealm defaultRealm] deleteObject:media];
          }];
          }];*/
        }
    }
    [helper writeProfileString:@"ISSTITCHEDREFRESH" value:@"1"];
    return [NSArray arrayWithArray:mediaArr1];
}

+ (MVMedia*) obtainDownloadedMedia:(MVMedia*)media {
    NSArray* localMedias = [self querySavedMediasWithCameraUUID:media.cameraUUID remotePath:media.remotePath localPath:media.localPath];
    if (!localMedias || localMedias.count == 0)
    {
        return nil;
    }
    else
    {
        for (int i=(int)localMedias.count-1; i>=0; --i)
        {
            MVMedia* localMedia = localMedias[i];
            if (![helper isNull:localMedia.localPath] && localMedia.downloadedSize >= localMedia.size && localMedia.size > 0)
            {
                __block BOOL anyAssetExists = NO;
                NSArray* identifiers = [localMedia.localIdentifier componentsSeparatedByString:@";"];
                [identifiers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString* identifier = (NSString*) obj;
                    if (![helper isNull:identifier]) {
                        PHAsset* asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil].firstObject;
                        if (asset) {
                            anyAssetExists = YES;
                            *stop = YES;
                        }
                    }
                }];
                
                if ([z_Sandbox fileExistInDocumentPath:localMedia.localPath] || anyAssetExists)
                {
                    return localMedia;
                }
                else
                {
                    [localMedia remove];
                }
            }
        }
        return nil;
    }
}

- (MVMedia*) obtainDownloadedOrThisMedia
{
    MVMedia* downloaded = [MVMedia obtainDownloadedMedia:self];
    if (downloaded)
    {
        return downloaded;
    }
    else
    {
        return self;
    }
}

- (void) saveCommonFields
{
    NSArray* savedMedias = [MVMedia querySavedMediasWithCameraUUID:self.cameraUUID remotePath:self.remotePath localPath:self.localPath];
    for(MVMedia* media in savedMedias)
    {
        [media copyCommonFields:self];
        [media update];
    }
}

- (id)copyWithZone:(nullable NSZone *)zone {
    MVMedia* cloned = [[MVMedia allocWithZone:zone] init];
    [cloned copy:self];
    return cloned;
}

- (void) copyCommonFields:(MVMedia*)media
{
    if (!media)
        return;

    [self transactionWithBlock:^{
        self.mediaType = media.mediaType;
        //self.dbMediaType = media.dbMediaType;
        
        if ([helper isNull:self.thumbnailImagePath])
        {
            self.thumbnailImagePath = media.thumbnailImagePath;
            //self.dbThumbnailImagePath = media.dbThumbnailImagePath;
        }
        if ([helper isNull:self.snapshotImagePath])
        {
            self.snapshotImagePath = media.snapshotImagePath;
        }
        
        if ([helper isNull:self.remotePath])
        {
            self.remotePath = media.remotePath;
            //self.dbRemotePath = media.dbRemotePath;
        }
        
        if ([helper isNull:self.cameraUUID])
        {
            self.cameraUUID = media.cameraUUID;
            //self.dbCameraUUID = media.dbCameraUUID;
        }
        
        if (self.size < media.size)
        {
            self.size = media.size;
            ///!!!For Debug
            if (media.size < 1048576)
            {
                DoctorLog(@"#MVMediaWrongSize# copyCommonFields : media.size = %ld", (long)media.size);
            }
            //self.dbSize = media.dbSize;
        }
        
        if (!self.createDate)
        {
            self.createDate = media.createDate;
            //self.dbCreateDate = media.dbCreateDate;
        }
        
        if (self.videoDuration < media.videoDuration)
        {
            self.videoDuration = media.videoDuration;
            //self.dbVideoDuration = media.dbVideoDuration;
        }
        
        if (self.filterID <= 0)
        {
            self.filterID = media.filterID;
            //self.dbFilterID = media.dbFilterID;
        }
        
        self.isStitched = media.isStitched;
        self.gyroMatrixString = media.gyroMatrixString;
        self.videoCaptureResolution = media.videoCaptureResolution;
    }];
}

- (id) copy:(id)sender
{
    if (!sender)
        return self;
    
    MVMedia* media = (MVMedia*)sender;
    [self copyCommonFields:media];
    
    [self transactionWithBlock:^{
        if (self.downloadedSize < media.downloadedSize)
        {
            self.downloadedSize = media.downloadedSize;
            //self.dbDownloadedSize = media.dbDownloadedSize;
        }
        
        if (media.downloadResumeData)
        {
            self.downloadResumeData = media.downloadResumeData;
        }
        
        if ([helper isNull:self.localPath])
        {
            self.localPath = media.localPath;
            //self.dbLocalPath = media.dbLocalPath;
        }
        
        if (!self.modifyDate)
        {
            self.modifyDate = media.modifyDate;
            //self.dbModifyDate = media.dbModifyDate;
        }
        self.localIdentifier = media.localIdentifier;
        self.finishDownloadedSize = media.finishDownloadedSize;
        self.error = media.error;
        self.shotDateTime = media.shotDateTime;
        self.model = media.model;
        self.xResolution = media.xResolution;
        self.yResolution = media.yResolution;
        self.exposureTime = media.exposureTime;
        self.ISO = media.ISO;
        self.whiteBalance = media.whiteBalance;
        self.longitude = media.longitude;
        self.latitude = media.latitude;
        self.altitude = media.altitude;
        self.resolution = media.resolution;
        self.exposureBiasValue = media.exposureBiasValue;
        self.isTimeElapsedVideo = media.isTimeElapsedVideo;
        self.location = media.location;
        self.isLocationHandled = media.isLocationHandled;
        self.isTimeElapsedVideo = media.isTimeElapsedVideo;
        self.fps = media.fps;
        self.encoderQualityLevel = media.encoderQualityLevel;
        
    }];
    
    return self;
}

- (BOOL)isLocalMediaExistence
{
    if (self.localPath && self.localPath.length > 0 && [z_Sandbox fileExistInDocumentPath:self.localPath]) {
        return true;
    }
    __block BOOL anyAssetExists = NO;
    NSArray* identifiers = [self.localIdentifier componentsSeparatedByString:@";"];
    [identifiers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString* identifier = (NSString*) obj;
        if (![helper isNull:identifier]) {
            PHAsset* asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil].firstObject;
            if (asset) {
                anyAssetExists = YES;
                *stop = YES;
            }
        }
    }];
    if (self.mediaType == MVMediaTypeVideo && ![self localFilePathSync:NO]) {
        anyAssetExists = NO;
    }
    return anyAssetExists;
}

- (PHAsset*)getSystemAlbumAsset
{
    __block PHAsset* asset = nil;
    if (![helper isNull:self.localIdentifier]) {
        NSArray* identifiers = [self.localIdentifier componentsSeparatedByString:@";"];
        [identifiers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString* identifier = (NSString*) obj;
            if (![helper isNull:identifier]) {
                asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil].firstObject;
                if (asset) {
                    *stop = YES;
                }
            }
        }];
    }
    return asset;
}

- (void) update
{
    if (!self.isFromDB) {
        [[RealmSerialQueue shareRealmQueue] sync:^{
            MVMedia* localMedia;
            if (![helper isNull:self.remotePath])
            {
                NSString* where = [NSString stringWithFormat:@"dbCameraUUID == '%@' AND dbRemotePath == '%@'",self.cameraUUID,self.remotePath];
                if (![helper isNull:self.localPath])
                {
                    where = [NSString stringWithFormat:@"%@ AND dbLocalPath == '%@'",where,self.localPath];
                }
                else
                {
                    where = [NSString stringWithFormat:@"%@ AND dbLocalPath == '%@'",where,@""];
                }
                RLMResults* results = [MVMedia objectsWhere:where];
                if (results.count > 0)
                {
                    localMedia = results[0];
                }
            }
            else
            {
                NSString* where = [NSString stringWithFormat:@"dbCameraUUID == '%@' AND dbRemotePath == '%@' AND dbLocalPath == '%@'",@"",@"",self.localPath];
                RLMResults* results = [MVMedia objectsWhere:where];
                if (results.count > 0)
                {
                    localMedia = results[0];
                }
            }
            
            [localMedia copy:self];
        }];
    }
    
}

- (NSUInteger) hash {
    NSString* remotePath = self.remotePath;
    NSString* cameraUUID = self.cameraUUID;
    NSString* localPath = self.localPath;
    if (![helper isNull:remotePath])
    {
        if (![helper isNull:localPath])
        {
            return [NSString stringWithFormat:@"%@%@%@",cameraUUID,remotePath,localPath].hash;
        }
        else
        {
            return [NSString stringWithFormat:@"%@%@",cameraUUID,remotePath].hash;
        }
    }
    else if (![helper isNull:self.localPath])
    {
        return self.localPath.hash;
    }
    else
    {
        return [super hash];
    }
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[MVMedia class]])
        return NO;
    
    MVMedia* other = (MVMedia*)object;
    NSString* remotePath = self.remotePath;
    NSString* cameraUUID = self.cameraUUID;
    NSString* localPath = self.localPath;
    if (![helper isNull:remotePath])
    {
        if (![remotePath isEqualToString:other.remotePath])
            return NO;
    }
    else if (![helper isNull:other.remotePath])
    {
        return NO;
    }
    
    if (![helper isNull:cameraUUID]) {
        if (![cameraUUID isEqualToString:other.cameraUUID])
            return NO;
    }
    else if (![helper isNull:other.cameraUUID])
    {
        return false;
    }
    
    if (![helper isNull:localPath])
    {
        if (![localPath isEqualToString:other.localPath])
            return NO;
    }
    else if (![helper isNull:other.localPath])
    {
        return NO;
    }
    
    return YES;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"MVMedia(%lx:%lx) remotePath='%@', localPath='%@', size=%ld, downloadedSize=%ld, uuid=%@, isFromDB=%d: type=%ld, duration=%ld, modifyDate=%@, createDate=%@, filterID=%ld, isStitched=%d, gyroString=%@, VideoCaptureResolution=%d\n",(unsigned long)[super hash], (unsigned long)[self hash],self.remotePath,self.localPath,(long)self.size,(long)self.downloadedSize,self.cameraUUID,self.isFromDB, (long)self.mediaType,(long)self.videoDuration,self.modifyDate,self.createDate,self.filterID,self.isStitched, self.gyroMatrixString, (int)self.videoCaptureResolution];
    }

+ (NSString *)StringOfDownloadStatus:(int)status
{
    switch (status) {
        case MVMediaDownloadStatusDownloading:
            return @"MVMediaDownloadStatusDownloading";
        case MVMediaDownloadStatusNone:
            return @"MVMediaDownloadStatusNone";
        case MVMediaDownloadStatusPending:
            return @"MVMediaDownloadStatusPending";
        case MVMediaDownloadStatusStopped:
            return @"MVMediaDownloadStatusStopped";
        case MVMediaDownloadStatusFinished:
            return @"MVMediaDownloadStatusFinished";
        case MVMediaDownloadStatusError:
            return @"MVMediaDownloadStatusError";
    }
    return @"N/A";
}
//数据库忽略该属性 不操作该属性
+ (NSArray *)ignoredProperties {
    return @[@"downloadStatus",@"dbDownloadStatus",@"mediaType",@"cameraUUID",@"remotePath",@"localPath",@"thumbnailImagePath",@"createDate",@"modifyDate",@"size",@"downloadedSize",@"videoDuration",@"filterID",@"isStitched",@"gyroMatrixString",@"videoCaptureResolution",@"finishDownloadedSize",@"downloadResumeData",@"error",@"localIdentifier",@"shotDateTime",@"model",@"xResolution",@"yResolution",@"exposureTime",@"ISO",@"whiteBalance",@"longitude",@"latitude",@"altitude",@"resolution",@"exposureBiasValue",@"location",@"isLocationHandled",@"avAsset",@"videoPath",@"isTimeElapsedVideo",@"fps",@"encoderQualityLevel",@"shareLocalIdentifier"];
}
//属性的默认值
+ (NSDictionary *)defaultPropertyValues {
    return @{@"dbFilterID":@0, @"dbMediaType":@1, @"dbLocalPath":@"", @"dbDownloadedSize":@0, @"dbSize":@0, @"dbIsStitched":@YES};
}

+ (void) test {
    NSMutableArray* localMedias = [[NSMutableArray alloc] init];
    [[RealmSerialQueue shareRealmQueue] sync:^{
        RLMResults* localMediaResults = [MVMedia objectsWhere:[NSString stringWithFormat:@"dbRemotePath == '%@'", @"/tmp/SD0/DCIM/20161121/VID_20161121_162507AA.MP4"]];
        for (MVMedia* media in localMediaResults)
        {
            [localMedias addObject:media];
        }
    }];
    NSLog(@"Queried local medias : \n%@", localMedias);
    
//    [[RLMRealm defaultRealm] transactionWithBlock:^{
//        [[RLMRealm defaultRealm] deleteAllObjects];
//    }];
//    
//    NSString* cameraUUID = @"SV1_A2_005";
//    NSString* remotePath = @"/tmp/SD0/DCIM/VID_20161221AA.MP4";
//    MVMedia* media0 = [MVMedia createWithCameraUUID:cameraUUID remoteFullPath:remotePath];
//    [media0 transactionWithBlock:^{
//        media0.localPath = @"20161221AA.MP4";
//    }];
//    [media0 insert];
//    
//    MVMedia* media1 = [MVMedia createWithCameraUUID:cameraUUID remoteFullPath:remotePath];
//    [media1 transactionWithBlock:^{
//        media1.localPath = @"1_20161221AA.MP4";
//    }];
//    [media1 insert];
//    
//    NSLog(@"After inserting: media0 = %@\nmedia1 = %@\n", media0, media1);
//    
//    NSArray* queriedMedias = [MVMedia querySavedMediasWithCameraUUID:cameraUUID remotePath:remotePath localPath:nil];
//    NSLog(@"Queried medias : %@", queriedMedias);
//    
//    [media0 transactionWithBlock:^{
//        media0.size = 1024;
//    }];
//    [media1 transactionWithBlock:^{
//        media1.downloadedSize = 1;
//        media1.size = 2;
//        media1.filterID = 3;
//        media1.thumbnailImagePath = @"thumb";
//    }];
//    
//    MVMedia* queryMedia1 = queriedMedias[1];
//    [queryMedia1 remove];
//    NSLog(@"After remove queriedMedias[1] :\nqueriedMedias[1] = %@", queryMedia1);
//    NSLog(@"After remove queriedMedias[1] :\nmedia1 = %@", media1);
}

@end
