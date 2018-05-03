//
//  ShareManage.m
//  KONKA_MARKET
//
//  Created by wxxu on 14/12/18.
//  Copyright (c) 2014年 archon. All rights reserved.
//  分享管理

#import "ShareManage.h"
#import "UMSocialWechatHandler.h"
#import "UMSocialQQHandler.h"
#import "WXApi.h"
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import "MVPhotosManager.h"
#import <Photos/Photos.h>
#import "z_Sandbox.h"
#import <Social/Social.h>
#import "MMProgressHUD.h"
#import <TwitterKit/TwitterKit.h>
#import <VeeRSDK/VeeRSDK.h>
#import "helper.h"

//
@interface ShareManage()<FBSDKSharingDelegate>

@end


@implementation ShareManage {
    UIViewController *_viewC;
}

static ShareManage *shareManage;

+ (ShareManage *)shareManage
{
    @synchronized(self)
    {
        if (shareManage == nil) {
            shareManage = [[self alloc] init];
        }
        return shareManage;
    }
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self shareConfig];
    }
    return self;
}
#pragma mark 注册友盟分享
- (void)shareConfig
{
    //设置友盟社会化组件appkey
    [[UMSocialManager defaultManager] setUmSocialAppkey:UMeng_APIKey];
    [[UMSocialManager defaultManager] openLog:YES];
    
    //注册微信
    //[WXApi registerApp:WX_APP_KEY];
    //微信AppKey
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_WechatSession appKey:WX_APP_KEY appSecret:WX_APP_SECRET redirectURL:share_url];
    
    //QQAppKey
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_QQ appKey:QQ_APP_ID appSecret:QQ_APP_KEY redirectURL:share_url];
    
    //新浪
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Sina appKey:SINA_APP_KEY appSecret:SINA_APP_SECRET redirectURL:share_url];
    //facebook
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Facebook appKey:FACEBOOK_APP_KEY appSecret:nil redirectURL:share_url];
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_FaceBookMessenger appKey:FACEBOOK_APP_KEY appSecret:nil redirectURL:share_url];
    
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_GooglePlus appKey:@"162362386518-9722kboc232id4spca0kgvhkmqmek6ct.apps.googleusercontent.com" appSecret:nil redirectURL:share_url];
    
    //twitter
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Twitter appKey:TWITTER_APP_KEY appSecret:TWITTER_APP_SECRET redirectURL:nil];
    
//    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Twitter appKey:@"fB5tvRpna1CKK97xZUslbxiet"  appSecret:@"YcbSvseLIwZ4hZg9YmgJPP5uWzd4zr6BpBKGZhf07zzh3oj62K" redirectURL:nil];
}

#pragma mark 微信分享
- (void)wxShareWithViewControll:(UIViewController *)viewC
{
    _viewC = viewC;
    //设置点击分享的链接
    
    
    UMShareWebpageObject * shareWeb = [[UMShareWebpageObject alloc] init];
    shareWeb.webpageUrl = _shared_url;
    shareWeb.title = _shared_title;
    shareWeb.thumbImage = _shared_image;
    shareWeb.descr = _shared_desc;
    UMSocialMessageObject * messageObj = [UMSocialMessageObject messageObjectWithMediaObject:shareWeb];
    messageObj.title = _shared_title;
    messageObj.text = _shared_desc;
    
    [[UMSocialManager defaultManager] shareToPlatform:UMSocialPlatformType_WechatSession messageObject:messageObj currentViewController:viewC completion:^(id result, NSError *error) {
        
    }];
    if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
        [self.delegate shareSuccess];
    }
    
}


#pragma mark QQ分享
- (void)qqShareWithViewController:(UIViewController *)viewC {

    
    _viewC = viewC;
    UMShareWebpageObject * shareWeb = [[UMShareWebpageObject alloc] init];
    shareWeb.webpageUrl = _shared_url;
    shareWeb.title = _shared_title;
    shareWeb.thumbImage = _shared_image;
    shareWeb.descr = _shared_desc;
    UMSocialMessageObject * messageObj = [UMSocialMessageObject messageObjectWithMediaObject:shareWeb];
    messageObj.title = _shared_title;
    messageObj.text = _shared_desc;
    
    [[UMSocialManager defaultManager] shareToPlatform:UMSocialPlatformType_QQ messageObject:messageObj currentViewController:viewC completion:^(id result, NSError *error) {
        
    }];
    if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
        [self.delegate shareSuccess];
    }
}
#pragma mark Qzone分享
- (void)qzoneShareWithViewController:(UIViewController *)viewC {
    
    _viewC = viewC;
    UMShareWebpageObject * shareWeb = [[UMShareWebpageObject alloc] init];
    shareWeb.webpageUrl = _shared_url;
    shareWeb.title = _shared_title;
    shareWeb.thumbImage = _shared_image;
    shareWeb.descr = _shared_desc;
    UMSocialMessageObject * messageObj = [UMSocialMessageObject messageObjectWithMediaObject:shareWeb];
    messageObj.title = _shared_title;
    messageObj.text = _shared_desc;
    
    [[UMSocialManager defaultManager] shareToPlatform:UMSocialPlatformType_Qzone messageObject:messageObj currentViewController:viewC completion:^(id result, NSError *error) {
        
    }];
    if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
        [self.delegate shareSuccess];
    }
}
#pragma mark 新浪微博分享
- (void)wbShareWithViewControll:(UIViewController *)viewC
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"sinaweibo://"]])
    {
        _viewC = viewC;
        
        UMShareWebpageObject * shareWeb = [[UMShareWebpageObject alloc] init];
        shareWeb.webpageUrl = _shared_url;
        shareWeb.title = _shared_title;
        shareWeb.thumbImage = _shared_image;
        shareWeb.descr = _shared_desc;
        UMSocialMessageObject * messageObj = [UMSocialMessageObject messageObjectWithMediaObject:shareWeb];
        messageObj.title = _shared_title;
        messageObj.text = _shared_desc;
        
        
        [[UMSocialManager defaultManager] shareToPlatform:UMSocialPlatformType_Sina messageObject:messageObj currentViewController:viewC completion:^(id result, NSError *error) {
            if (error) {
                [UIView animateWithDuration:0 animations:^{
                    [MMProgressHUD showWithStatus:@""];
                } completion:^(BOOL finished) {
                    [MMProgressHUD dismissWithSuccess:FGGetStringWithKeyFromTable(SHAREFAIL, nil)];
                }];
            }
        }];
        if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
            [self.delegate shareSuccess];
        }
    }else
    {
        [UIView animateWithDuration:0 animations:^{
            [MMProgressHUD showWithStatus:@""];
        } completion:^(BOOL finished) {
            [MMProgressHUD dismissWithSuccess:[NSString stringWithFormat:@"%@%@",FGGetStringWithKeyFromTable(NOINSTALL, nil),FGGetStringWithKeyFromTable(WEIBO, nil)]];
        }];
    }
    
}

#pragma mark 微信朋友圈分享
- (void)wxpyqShareWithViewControll:(UIViewController *)viewC
{
    _viewC = viewC;
    
    UMShareWebpageObject * shareWeb = [[UMShareWebpageObject alloc] init];
    shareWeb.webpageUrl = _shared_url;
    shareWeb.title = _shared_title;
    shareWeb.thumbImage = _shared_image;
    shareWeb.descr = _shared_desc;
    UMSocialMessageObject * messageObj = [UMSocialMessageObject messageObjectWithMediaObject:shareWeb];
    messageObj.title = _shared_title;
    messageObj.text = _shared_desc;
    
    [[UMSocialManager defaultManager] shareToPlatform:UMSocialPlatformType_WechatTimeLine messageObject:messageObj currentViewController:viewC completion:^(id result, NSError *error) {
        
    }];
    if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
        [self.delegate shareSuccess];
    }
}

#pragma mark --facebook分享--
- (void)facebookShareWithViewControll:(UIViewController *)viewC isShareH5:(BOOL)isShareH5 isVideo:(BOOL)isVideo
{
    _viewC = viewC;
    
    FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
    dialog.delegate = self;
    if (isShareH5) {
        
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbauth2:/"]])
        {
            FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
            content.contentURL = [NSURL URLWithString:_shared_url];
            content.contentTitle = _shared_title;
            content.imageURL = _shared_image_Url;
            content.contentDescription = _shared_desc;
            dialog.shareContent = content;
            dialog.fromViewController = viewC;
            dialog.mode = FBSDKShareDialogModeNative;
            if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
                [self.delegate shareSuccess];
            }
            [dialog show];
        }else
        {
            [UIView animateWithDuration:0 animations:^{
                [MMProgressHUD showWithStatus:@""];
            } completion:^(BOOL finished) {
                [MMProgressHUD dismissWithSuccess:[NSString stringWithFormat:@"%@Facebook",FGGetStringWithKeyFromTable(NOINSTALL, nil)]];
            }];
        }
        
        
    }else
    {
        if (isVideo) {
//            FBSDKShareVideoContent * shareVideoContent = [[FBSDKShareVideoContent alloc] init];
//            FBSDKShareVideo * shareVideo = [[FBSDKShareVideo alloc] init];
//            shareVideo.videoURL = [NSURL fileURLWithPath:_shared_url];
//            shareVideoContent.video =shareVideo;
//            dialog.shareContent = shareVideoContent;
            
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbauth2:/"]])
            {
                FBSDKShareVideoContent * shareVideoContent = [[FBSDKShareVideoContent alloc] init];
                FBSDKShareVideo * shareVideo = [[FBSDKShareVideo alloc] init];
                _url_new = [NSURL URLWithString:self.shared_url];
                shareVideo.videoURL = self.url_new;
                shareVideoContent.video =shareVideo;
                dialog.shareContent = shareVideoContent;
                dialog.fromViewController = viewC;
                dialog.mode = FBSDKShareDialogModeNative;
                if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
                    [self.delegate shareSuccess];
                }
                [dialog show];
            }else
            {
                [UIView animateWithDuration:0 animations:^{
                    [MMProgressHUD showWithStatus:@""];
                } completion:^(BOOL finished) {
                    [MMProgressHUD dismissWithSuccess:[NSString stringWithFormat:@"%@Facebook",FGGetStringWithKeyFromTable(NOINSTALL, nil)]];
                }];
            }
            
            
            /*
            NSURL *videoURL=[NSURL fileURLWithPath:_shared_url];
            //[self saveToCameraRoll:videoURL];
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            ALAssetsLibraryWriteVideoCompletionBlock videoWriteCompletionBlock = ^(NSURL *newURL, NSError *error) {
                if (error)
                {
                    NSLog( @"Error writing image with metadata to Photo Library: %@", error );
                } else {
                    NSLog( @"Wrote image with metadata to Photo Library %@", newURL.absoluteString);
                    _url_new = newURL;
                    shareVideo.videoURL = self.url_new;
                    shareVideoContent.video =shareVideo;
                    dialog.shareContent = shareVideoContent;
                    dialog.fromViewController = viewC;
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbauth2:/"]])
                    {
                        dialog.mode = FBSDKShareDialogModeNative;
                        if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
                            [self.delegate shareSuccess];
                        }
                    }
                    
                    [dialog show];
                } };
            if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:videoURL])
            {
                [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:videoWriteCompletionBlock];
            }*/
        }else
        {
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbauth2:/"]])
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fbauth2:/"]];
                if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
                    [self.delegate shareSuccess];
                }
                
            }else
            {
                [UIView animateWithDuration:0 animations:^{
                    [MMProgressHUD showWithStatus:@""];
                } completion:^(BOOL finished) {
                    [MMProgressHUD dismissWithSuccess:[NSString stringWithFormat:@"%@Facebook",FGGetStringWithKeyFromTable(NOINSTALL, nil)]];
                }];
            }
            /*
            if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
                NSLog(@"不可用");
                return;
            }
            
             //*****可以分享的平台*****
             //SOCIAL_EXTERN NSString *const SLServiceTypeTwitter NS_AVAILABLE(10_8, 6_0);//Twitter
             //SOCIAL_EXTERN NSString *const SLServiceTypeFacebook NS_AVAILABLE(10_8, 6_0);//Facebook
             //SOCIAL_EXTERN NSString *const SLServiceTypeSinaWeibo NS_AVAILABLE(10_8, 6_0);//新浪微博
             //SOCIAL_EXTERN NSString *const SLServiceTypeTencentWeibo NS_AVAILABLE(10_9, 7_0);//腾讯微博
             //SOCIAL_EXTERN NSString *const SLServiceTypeLinkedIn NS_AVAILABLE(10_9, NA);//领英
             
            
            // 创建控制器，并设置ServiceType（指定分享平台）
            SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            //CIImage * iamge  = [CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:_shared_url]];
            // 添加要分享的图片
            
            //[composeVC addImage:[UIImage imageWithCIImage:iamge]];
            // 添加要分享的文字
            [composeVC setInitialText:@"share to PUTClub"];
            
            // 添加要分享的url
            [composeVC addURL:[NSURL URLWithString:@"assets-library://asset/asset.JPG?id=BC406371-0EF2-4D26-885E-AD9918EFEE56&ext=JPG"]];
            // 弹出分享控制器
            [viewC presentViewController:composeVC animated:YES completion:nil];
            // 监听用户点击事件
            composeVC.completionHandler = ^(SLComposeViewControllerResult result){
                if (result == SLComposeViewControllerResultDone) {
                    NSLog(@"点击了发送");
                }
                else if (result == SLComposeViewControllerResultCancelled)
                {
                    NSLog(@"点击了取消");
                }
            };*/
            //创建图片内容对象
//            UMShareImageObject *shareObject = [[UMShareImageObject alloc] init];
            //如果有缩略图，则设置缩略图本地
            //    shareObject.thumbImage = [NSURL fileURLWithPath:[z_Sandbox documentPath:@"IMG_20170425_165911.JPG"]];
            //    shareObject.shareImage = [NSURL fileURLWithPath:[z_Sandbox documentPath:@"IMG_20170430_140527.JPG"]];
            //    shareObject.thumbImage = [UIImage imageWithContentsOfFile:[z_Sandbox documentPath:@"IMG_20170425_165911.JPG"]];
//            shareObject.shareImage = [NSURL fileURLWithPath:_shared_url];
            //[UIImage imageWithContentsOfFile:[z_Sandbox documentPath:@"IMG_20170430_140527.JPG"]];
            
            
            
            
            
          
            /*
            FBSDKSharePhotoContent * sharePhotoContent = [[FBSDKSharePhotoContent alloc] init];
            FBSDKSharePhoto * sharePhoto = [[FBSDKSharePhoto alloc] init];
            sharePhoto.image = [UIImage imageWithContentsOfFile:_shared_url];
            sharePhoto.userGenerated = NO;
            sharePhotoContent.photos = @[sharePhoto];
            dialog.shareContent = sharePhotoContent;
            dialog.fromViewController = viewC;
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbauth2:/"]])
            {
                dialog.mode = FBSDKShareDialogModeNative;
                if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
                    [self.delegate shareSuccess];
                }
            }
            
            [dialog show];*/
            
            /*
            FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
            content.contentURL = [NSURL URLWithString:_shared_url];
            content.contentTitle = _shared_title;
            content.imageURL = _shared_image_Url;
            content.contentDescription = _shared_desc;
            dialog.shareContent = content;
            dialog.fromViewController = viewC;
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbauth2:/"]])
            {
                dialog.mode = FBSDKShareDialogModeNative;
                if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
                    [self.delegate shareSuccess];
                }
            }
            
            [dialog show];*/
            
            
            
       
            
//            NSURL *imageURL=[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"origin.png" ofType:nil]];
            //[self saveToCameraRoll:videoURL];
            
//            NSData * imageData = [NSData dataWithContentsOfFile:_shared_url];
//            
//            
//            sharePhoto.image = [UIImage imageWithData:imageData];
//            sharePhoto.userGenerated = YES;
//            sharePhotoContent.photos = @[sharePhoto];
//            NSLog(@"+++++++++++%@",[NSThread currentThread]);
//            dialog.shareContent = sharePhotoContent;
//            dialog.fromViewController = viewC;
//            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbauth2:/"]])
//            {
//                dialog.mode = FBSDKShareDialogModeNative;
//                if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
//                    [self.delegate shareSuccess];
//                }
//            }
//            
//            [dialog show];
            
            
            /*
            FBSDKSharePhotoContent * sharePhotoContent = [[FBSDKSharePhotoContent alloc] init];
            FBSDKSharePhoto * sharePhoto = [[FBSDKSharePhoto alloc] init];
          
             ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            NSData * imageData = [NSData dataWithContentsOfFile:_shared_url];
            [library writeImageDataToSavedPhotosAlbum:imageData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                if (error)
                {
                    NSLog( @"Error writing image with metadata to Photo Library: %@", error );
                } else {
                    NSLog( @"Wrote image with metadata to Photo Library %@", assetURL.absoluteString);
                    _url_new = assetURL;
                   
//                    NSData * imageData = [NSData dataWithContentsOfURL:assetURL];
//                    sharePhoto.image = [UIImage imageWithData:imageData];
                    sharePhoto.imageURL = assetURL;
                    sharePhoto.userGenerated = NO;
                    sharePhotoContent.photos = @[sharePhoto];
                    NSLog(@"+++++++++++%@",[NSThread currentThread]);
                    dialog.shareContent = sharePhotoContent;
                    dialog.fromViewController = viewC;
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbauth2:/"]])
                    {
                        dialog.mode = FBSDKShareDialogModeNative;
                        if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
                            [self.delegate shareSuccess];
                        }
                    }
                    
                    [dialog show];
                }
            }];
            
            */
        }
    }
    
    
    
    
//    UMShareWebpageObject * shareWeb = [[UMShareWebpageObject alloc] init];
//    shareWeb.webpageUrl = _shared_url;
//    shareWeb.title = _shared_title;
//    shareWeb.thumbImage = _shared_image;
//    shareWeb.descr = _shared_desc;
//    UMSocialMessageObject * messageObj = [UMSocialMessageObject messageObjectWithMediaObject:shareWeb];
//    messageObj.title = _shared_title;
//    messageObj.text = _shared_desc;
//    
//    [[UMSocialManager defaultManager] shareToPlatform:UMSocialPlatformType_Facebook messageObject:messageObj currentViewController:viewC completion:^(id result, NSError *error) {
//        if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
//            [self.delegate shareSuccess];
//        }
//    }];
}
 - (void)saveToCameraRoll:(NSURL *)srcURL {
     NSLog(@"srcURL: %@", srcURL);
     ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
     ALAssetsLibraryWriteVideoCompletionBlock videoWriteCompletionBlock = ^(NSURL *newURL, NSError *error) {
         if (error)
         {
             NSLog( @"Error writing image with metadata to Photo Library: %@", error );
         } else {
             NSLog( @"Wrote image with metadata to Photo Library %@", newURL.absoluteString); _url_new = newURL;
         } };
     if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:srcURL])
     {
         [library writeVideoAtPathToSavedPhotosAlbum:srcURL completionBlock:videoWriteCompletionBlock];
     }
 }
#pragma mark --facebookMessenger分享--
- (void)facebookMessengerShareWithViewControll:(UIViewController *)viewC
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb-messenger-api:/"]]) {
        
        UMShareWebpageObject * shareWeb = [[UMShareWebpageObject alloc] init];
        shareWeb.webpageUrl = _shared_url;
        shareWeb.title = _shared_title;
        shareWeb.thumbImage = _shared_image_str;
        
        shareWeb.descr = _shared_desc;
        UMSocialMessageObject * messageObj = [UMSocialMessageObject messageObjectWithMediaObject:shareWeb];
        messageObj.title = _shared_title;
        messageObj.text = _shared_desc;
        
        [[UMSocialManager defaultManager] shareToPlatform:UMSocialPlatformType_FaceBookMessenger messageObject:messageObj currentViewController:viewC completion:^(id result, NSError *error) {
            
        }];
        if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
            [self.delegate shareSuccess];
        }
    }else
    {
        [UIView animateWithDuration:0 animations:^{
            [MMProgressHUD showWithStatus:@""];
        } completion:^(BOOL finished) {
            [MMProgressHUD dismissWithSuccess:[NSString stringWithFormat:@"%@Messenger",FGGetStringWithKeyFromTable(NOINSTALL, nil)]];
        }];
    }
    
}

#pragma mark --line分享--
- (void)lineShareWithViewControll:(UIViewController *)viewC isShareH5:(BOOL)isShareH5 isVideo:(BOOL)isVideo
{
    /*
    UMShareWebpageObject * shareWeb = [[UMShareWebpageObject alloc] init];
    shareWeb.webpageUrl = _shared_url;
    shareWeb.title = _shared_title;
    shareWeb.thumbImage = _shared_image;
    shareWeb.descr = _shared_desc;
    UMSocialMessageObject * messageObj = [UMSocialMessageObject messageObjectWithMediaObject:shareWeb];
    messageObj.title = _shared_title;
    messageObj.text = _shared_desc;
     */
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"line://"]])
    {
        UMSocialMessageObject *messageObject = [UMSocialMessageObject messageObject];
        if (isShareH5) {
            
            messageObject.title = _shared_title;
            messageObject.text = [NSString stringWithFormat:@"%@%@",_shared_url,_shared_desc];
            [[UMSocialManager defaultManager] shareToPlatform:UMSocialPlatformType_Line messageObject:messageObject currentViewController:viewC completion:^(id result, NSError *error) {
                
            }];
            if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
                [self.delegate shareSuccess];
            }
        }else
        {
            //line:/
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"line://"]];
            if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
                [self.delegate shareSuccess];
            }
            
            /*
             UMShareImageObject *shareObject = [[UMShareImageObject alloc] init];
             
             shareObject.shareImage = [NSData dataWithContentsOfFile:_shared_url];
             
             messageObject.shareObject = shareObject;*/
        }
    }else
    {
        [UIView animateWithDuration:0 animations:^{
            [MMProgressHUD showWithStatus:@""];
        } completion:^(BOOL finished) {
            [MMProgressHUD dismissWithSuccess:[NSString stringWithFormat:@"%@LINE",FGGetStringWithKeyFromTable(NOINSTALL, nil)]];
        }];
    }

}
#pragma mark --youtube分享--
- (void)youtubeShareWithViewControll:(UIViewController *)viewC
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"youtube://"]])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"youtube://"]];
        if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
            [self.delegate shareSuccess];
        }
    }else
    {
        [UIView animateWithDuration:0 animations:^{
            [MMProgressHUD showWithStatus:@""];
        } completion:^(BOOL finished) {
            [MMProgressHUD dismissWithSuccess:[NSString stringWithFormat:@"%@YouTube",FGGetStringWithKeyFromTable(NOINSTALL, nil)]];
        }];
    }
}

#pragma mark --FBSDKSharingDelegate代理方法的实现--
- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
    
}
- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
    NSLog(@"###########");
}
- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
    
}

#pragma mark --Twitter分享--
- (void)twitterShareWithViewControll:(UIViewController *)viewC
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"Twitter://"]])
    {
        _viewC = viewC;
        UMShareImageObject *shareObject = [[UMShareImageObject alloc] init];
        shareObject.thumbImage = _shared_image;
        [shareObject setShareImage:_shared_image];
        
        UMSocialMessageObject * messageObj = [UMSocialMessageObject messageObjectWithMediaObject:shareObject];
        messageObj.text = [NSString stringWithFormat:@"%@%@",_shared_desc,_shared_url];
        
        [[UMSocialManager defaultManager] shareToPlatform:UMSocialPlatformType_Twitter messageObject:messageObj currentViewController:viewC completion:^(id result, NSError *error) {
            if (error) {
                [MMProgressHUD dismissWithError:FGGetStringWithKeyFromTable(SHAREFAILLOGIN, nil)];
            }else
            {
                if ([self.delegate respondsToSelector:@selector(shareSuccess)]) {
                    [self.delegate shareSuccess];
                }
                [MMProgressHUD dismissWithError:FGGetStringWithKeyFromTable(SHARESUC, nil)];
                
                
            }
            
        }];
    }else
    {
        [MMProgressHUD dismissWithSuccess:[NSString stringWithFormat:@"%@Twitter",FGGetStringWithKeyFromTable(NOINSTALL, nil)]];
    }
    
}

#pragma mark --veer分享--
- (void)veerShareWithViewControll:(UIViewController *)viewC
{
    [VeeRSDK sharePHAssetToVeeR:self.localIdentifier tags:@[@"Madv360"] stereoType:VeeRSDKStereoTypeMono FOVHorizontalDegree:0 FOVVerticalDegree:0];
}


#pragma mark 短信分享
- (void)smsShareWithViewControll:(UIViewController *)viewC
{
    _viewC = viewC;
    Class messageClass = (NSClassFromString(@"MFMessageComposeViewController"));
    if (messageClass != nil) {
        if ([messageClass canSendText]) {
            [self displaySMSComposerSheet];
        }
        else {
            //@"设备没有短信功能"
        }
    }
    else {
        //@"iOS版本过低,iOS4.0以上才支持程序内发送短信"
    }
}

#pragma mark 短信的代理方法
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
    [controller dismissViewControllerAnimated:YES completion:nil];
    switch (result)
    {
        case MessageComposeResultCancelled:
            NSLog(@"取消");
            break;
        case MessageComposeResultSent:
            //@"感谢您的分享!"
            break;
        case MessageComposeResultFailed:
            
            break;
        default:
            break;
    }
}

- (void)displaySMSComposerSheet
{
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
    picker.messageComposeDelegate = self;
    picker.navigationBar.tintColor = [UIColor blackColor];
    //    picker.recipients = [NSArray arrayWithObject:@"10086"];
    picker.body = share_content;
    [_viewC presentViewController:picker animated:YES completion:nil];
}

#pragma mark --微信登录--
- (void)wxLoginWithViewControll:(UIViewController *)viewC
{
    [[UMSocialManager defaultManager] getUserInfoWithPlatform:UMSocialPlatformType_WechatSession currentViewController:nil completion:^(id result, NSError *error) {
        if (error) {
            if ([self.delegate respondsToSelector:@selector(loginCancel)]) {
                [self.delegate loginCancel];
            }
        }else
        {
            UMSocialUserInfoResponse *resp = result;
            
            // 第三方登录数据(为空表示平台未提供)
            // 授权数据
            NSLog(@" uid: %@", resp.uid);
            NSLog(@" openid: %@", resp.openid);
            NSLog(@" accessToken: %@", resp.accessToken);
            NSLog(@" refreshToken: %@", resp.refreshToken);
            NSLog(@" expiration: %@", resp.expiration);
            
            // 用户数据
            NSLog(@" name: %@", resp.name);
            NSLog(@" iconurl: %@", resp.iconurl);
            NSLog(@" gender: %@", resp.gender);
            
            // 第三方平台SDK原始数据
            NSLog(@" originalResponse: %@", resp.originalResponse);
            if ([self.delegate respondsToSelector:@selector(loginSuccess:loginIndex:)]) {
                [self.delegate loginSuccess:resp loginIndex:self.loginIndex];
            }
        }
        
        
    }];
}

#pragma mark --qq登录--
- (void)qqLoginWithViewControll:(UIViewController *)viewC
{
    [[UMSocialManager defaultManager] getUserInfoWithPlatform:UMSocialPlatformType_QQ currentViewController:nil completion:^(id result, NSError *error) {
        if (error) {
            if ([self.delegate respondsToSelector:@selector(loginCancel)]) {
                [self.delegate loginCancel];
            }
        }else
        {
            UMSocialUserInfoResponse *resp = result;
            
            // 第三方登录数据(为空表示平台未提供)
            // 授权数据
            NSLog(@" uid: %@", resp.uid);
            NSLog(@" openid: %@", resp.openid);
            NSLog(@" accessToken: %@", resp.accessToken);
            NSLog(@" refreshToken: %@", resp.refreshToken);
            NSLog(@" expiration: %@", resp.expiration);
            
            // 用户数据
            NSLog(@" name: %@", resp.name);
            NSLog(@" iconurl: %@", resp.iconurl);
            NSLog(@" gender: %@", resp.gender);
            
            // 第三方平台SDK原始数据
            NSLog(@" originalResponse: %@", resp.originalResponse);
            if ([self.delegate respondsToSelector:@selector(loginSuccess:loginIndex:)]) {
                [self.delegate loginSuccess:resp loginIndex:self.loginIndex];
            }
        }
        
    }];
}

#pragma mark --微博登录--
- (void)wbLoginWithViewControll:(UIViewController *)viewC
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"sinaweibo://"]]) {
        [[UMSocialManager defaultManager] getUserInfoWithPlatform:UMSocialPlatformType_Sina currentViewController:nil completion:^(id result, NSError *error) {
            if (error) {
                if ([self.delegate respondsToSelector:@selector(loginCancel)]) {
                    [self.delegate loginCancel];
                }
            }else
            {
                UMSocialUserInfoResponse *resp = result;
                
                // 第三方登录数据(为空表示平台未提供)
                // 授权数据
                [helper writeProfileString:WEIBOACCESS_TOKEN value:resp.accessToken];
                [helper writeProfileString:WEIBO_UID value:resp.uid];
                NSLog(@" uid: %@", resp.uid);
                NSLog(@" openid: %@", resp.openid);
                NSLog(@" accessToken: %@", resp.accessToken);
                NSLog(@" refreshToken: %@", resp.refreshToken);
                NSLog(@" expiration: %@", resp.expiration);
                
                // 用户数据
                NSLog(@" name: %@", resp.name);
                NSLog(@" iconurl: %@", resp.iconurl);
                NSLog(@" gender: %@", resp.gender);
                
                // 第三方平台SDK原始数据
                NSLog(@" originalResponse: %@", resp.originalResponse);
                if ([self.delegate respondsToSelector:@selector(loginSuccess:loginIndex:)]) {
                    [self.delegate loginSuccess:resp loginIndex:self.loginIndex];
                }
            }
            
        }];
    }else
    {
        [UIView animateWithDuration:0 animations:^{
            [MMProgressHUD showWithStatus:@""];
        } completion:^(BOOL finished) {
            [MMProgressHUD dismissWithSuccess:[NSString stringWithFormat:@"%@%@",FGGetStringWithKeyFromTable(NOINSTALL, nil),FGGetStringWithKeyFromTable(WEIBO, nil)]];
        }];
    }
    
}

#pragma mark --Twitter登录--
- (void)twitterLoginWithViewControll:(UIViewController *)viewC
{
    [[UMSocialManager defaultManager] cancelAuthWithPlatform:UMSocialPlatformType_Twitter completion:^(id result, NSError *error) {
        [[UMSocialManager defaultManager] getUserInfoWithPlatform:UMSocialPlatformType_Twitter currentViewController:nil completion:^(id result, NSError *error) {
            if (error) {
                if ([self.delegate respondsToSelector:@selector(loginCancel)]) {
                    [self.delegate loginCancel];
                }
            }else
            {
                UMSocialUserInfoResponse *resp = result;
                
                // 第三方登录数据(为空表示平台未提供)
                // 授权数据
               
                
                // 第三方平台SDK原始数据
                NSLog(@" originalResponse: %@", resp.originalResponse);
                if ([self.delegate respondsToSelector:@selector(loginSuccess:loginIndex:)]) {
                    [self.delegate loginSuccess:resp loginIndex:self.loginIndex];
                }
            }
            
        }];
    }];
   
}

- (void)getAuthWithUserInfoFromFacebook
{
    [[UMSocialManager defaultManager] getUserInfoWithPlatform:UMSocialPlatformType_Facebook currentViewController:nil completion:^(id result, NSError *error) {
        if (error) {
            if ([self.delegate respondsToSelector:@selector(loginCancel)]) {
                [self.delegate loginCancel];
            }
        } else {
            UMSocialUserInfoResponse *resp = result;
            
            // 授权信息
            NSLog(@"Facebook uid: %@", resp.uid);
            NSLog(@"Facebook accessToken: %@", resp.accessToken);
            NSLog(@"Facebook expiration: %@", resp.expiration);
            
            // 用户信息
            NSLog(@"Facebook name: %@", resp.name);
            
            // 第三方平台SDK源数据
            NSLog(@"Facebook originalResponse: %@", resp.originalResponse);
            if ([self.delegate respondsToSelector:@selector(loginSuccess:loginIndex:)]) {
                [self.delegate loginSuccess:resp loginIndex:self.loginIndex];
            }
        }
    }];
}
- (void)getAuthWithUserInfoFromGoogle
{
    [[UMSocialManager defaultManager] getUserInfoWithPlatform:UMSocialPlatformType_GooglePlus currentViewController:nil completion:^(id result, NSError *error) {
        
        UMSocialUserInfoResponse *resp = result;
        
        // 第三方登录数据(为空表示平台未提供)
        // 授权数据
        NSLog(@" uid: %@", resp.uid);
        NSLog(@" openid: %@", resp.openid);
        NSLog(@" accessToken: %@", resp.accessToken);
        NSLog(@" refreshToken: %@", resp.refreshToken);
        NSLog(@" expiration: %@", resp.expiration);
        
        // 用户数据
        NSLog(@" name: %@", resp.name);
        NSLog(@" iconurl: %@", resp.iconurl);
        NSLog(@" gender: %@", resp.gender);
        
        // 第三方平台SDK原始数据
        NSLog(@" originalResponse: %@", resp.originalResponse);
        if ([self.delegate respondsToSelector:@selector(loginSuccess:loginIndex:)]) {
            [self.delegate loginSuccess:resp loginIndex:self.loginIndex];
        }
    }];
}
-(BOOL) isSupport:(UMSocialPlatformType)platformType
{
    return [[UMSocialManager defaultManager] isSupport:platformType];
}
@end
