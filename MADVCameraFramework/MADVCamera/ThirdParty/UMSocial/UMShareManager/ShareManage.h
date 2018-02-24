//
//  ShareManage.h
//  KONKA_MARKET
//
//  Created by wxxu on 14/12/18.
//  Copyright (c) 2014年 archon. All rights reserved.
//  分享管理

// 友盟APIKey
#define UMeng_APIKey        @"57709d19e0f55a883d00175f"
#define WX_APP_KEY          @"wxd5322d965af2f7ed"
#define WX_APP_SECRET       @"b081f4396a695043cd716745bd2102d6"
#define QQ_APP_KEY          @"cBSHdtlQXapf0EnN"
#define QQ_APP_ID           @"1105501878"

//新浪
#define SINA_APP_KEY          @"4080217621"
#define SINA_APP_SECRET       @"3c36b68a9466441b20e5d6a1cf8d80c6"

#define FACEBOOK_APP_KEY     @"1074080299359719"
#define FACEBOOK_APP_SECRET  @"5ad2928643dba97a8cef0c0683cc61c1"

#define TWITTER_APP_KEY @"lino65S0JjTwvBYMvEATH10LQ"
#define TWITTER_APP_SECRET  @"AnzBtcCoYLakt2CUKHi6vSrxbBd0GncbqgA9e8zUOr7ktA4FoX"

#define share_title         @"友盟分享"
#define share_content       @"可以分享"
#define share_url           @"https://api.weibo.com/oauth2/default.html"//回调地址

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <UMSocialCore/UMSocialCore.h>

@protocol ShareManageDelegate <NSObject>

- (void)shareSuccess;

- (void)loginSuccess:(UMSocialUserInfoResponse *)entity loginIndex:(NSInteger)loginIndex;
- (void)loginCancel;

@end

typedef  void (^success)();

@interface ShareManage : NSObject <MFMessageComposeViewControllerDelegate>

@property (nonatomic,copy)NSString * shared_title;
@property (nonatomic,strong)UIImage * shared_image;
@property (nonatomic,copy)NSString * shared_url;
@property (nonatomic,copy)NSString * shared_desc;
@property(nonatomic,strong)NSURL * shared_image_Url;
@property(nonatomic,weak)id<ShareManageDelegate> delegate;
@property(nonatomic,strong)NSURL * url_new ;
@property(nonatomic,assign)NSInteger loginIndex;
@property(nonatomic,copy)NSString * shared_image_str;
@property(nonatomic,copy)NSString * localIdentifier;

+ (ShareManage *)shareManage;

- (void)shareConfig;

/**微信分享**/
- (void)wxShareWithViewControll:(UIViewController *)viewC;

/**微信朋友圈分享**/
- (void)wxpyqShareWithViewControll:(UIViewController *)viewC;

/**QQ分享**/
- (void)qqShareWithViewController:(UIViewController *)viewC;

/**Qzone分享**/
- (void)qzoneShareWithViewController:(UIViewController *)viewC ;

/**新浪微博分享**/
- (void)wbShareWithViewControll:(UIViewController *)viewC;

#pragma mark --facebook分享--
- (void)facebookShareWithViewControll:(UIViewController *)viewC isShareH5:(BOOL)isShareH5 isVideo:(BOOL)isVideo;

#pragma mark --FaceBookMessenger分享--
- (void)facebookMessengerShareWithViewControll:(UIViewController *)viewC;

#pragma mark --line分享--
- (void)lineShareWithViewControll:(UIViewController *)viewC isShareH5:(BOOL)isShareH5 isVideo:(BOOL)isVideo;

#pragma mark --youtube分享--
- (void)youtubeShareWithViewControll:(UIViewController *)viewC;
#pragma mark --Twitter分享--
- (void)twitterShareWithViewControll:(UIViewController *)viewC;
#pragma mark --veer分享--
- (void)veerShareWithViewControll:(UIViewController *)viewC;


/**短信分享,目前有点bug**/
- (void)smsShareWithViewControll:(UIViewController *)viewC;

#pragma mark --微信登录--
- (void)wxLoginWithViewControll:(UIViewController *)viewC;
#pragma mark --qq登录--
- (void)qqLoginWithViewControll:(UIViewController *)viewC;
#pragma mark --微博登录--
- (void)wbLoginWithViewControll:(UIViewController *)viewC;

#pragma mark --Twitter登录--
- (void)twitterLoginWithViewControll:(UIViewController *)viewC;

- (void)getAuthWithUserInfoFromFacebook;
- (void)getAuthWithUserInfoFromGoogle;

-(BOOL) isSupport:(UMSocialPlatformType)platformType;

@end
