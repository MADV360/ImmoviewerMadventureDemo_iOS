//
//  FGLanguageTool.m
//  appswitchlanguage
//
//  Created by 张巧隔 on 17/3/17.
//  Copyright © 2017年 张巧隔. All rights reserved.
//

#import "FGLanguageTool.h"

#ifndef MADVCAMERA_EXPORT
#import "AppDelegate.h"
#endif
#import "FGLanguageTool.h"
#import "NSString+Extensions.h"

static FGLanguageTool *sharedModel;

@interface FGLanguageTool()

@property(nonatomic,strong)NSBundle *bundle;
@property(nonatomic,copy)NSString *language;


@end

@implementation FGLanguageTool

+(id)sharedInstance
{
    if (!sharedModel)
    {
        sharedModel = [[FGLanguageTool alloc]init];
    }
    
    return sharedModel;
}

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        [self initLanguage];
        self.isChangeLanguage = NO;
    }
    
    return self;
}

-(void)initLanguage
{
    NSString *tmp = [[NSUserDefaults standardUserDefaults]objectForKey:LANGUAGE_SET];
    NSString *path;
    //默认是中文
    if (!tmp || [tmp isEqualToString:@""])
    {
        tmp = [NSString getPreferredLanguage];
//        self.language = tmp;
//        if ([tmp hasPrefix:@"id"]) {
//            path = [[NSBundle mainBundle]pathForResource:@"en" ofType:@"lproj"];
//            self.bundle = [NSBundle bundleWithPath:path];
//        }
//        return;
    }
    
    self.language = tmp;
    path = [[NSBundle mainBundle]pathForResource:self.language ofType:@"lproj"];
    self.bundle = [NSBundle bundleWithPath:path];
}

-(NSString *)getStringForKey:(NSString *)key withTable:(NSString *)table
{
    if (table == nil || [table isEqualToString:@""]) {
        table = LANGUAGETABLE;
    }
    if (self.bundle)
    {
        return NSLocalizedStringFromTableInBundle(key, table, self.bundle, @"");
    }
    
    return NSLocalizedStringFromTable(key, table, @"");
}
-(void)setNewLanguage:(NSString *)language
{
    if ([language isEqualToString:self.language])
    {
        return;
    }
    self.isChangeLanguage = YES;
    if ([language isEqualToString:EN] || [language isEqualToString:CNS] || [language isEqualToString:CNT] || [language isEqualToString:ES] || [language isEqualToString:RU])
    {
        NSString *path = [[NSBundle mainBundle]pathForResource:language ofType:@"lproj"];
        self.bundle = [NSBundle bundleWithPath:path];
    }
    
    self.language = language;
#ifndef MADVCAMERA_EXPORT
    [self resetRootViewController];
#endif
}
- (NSString *)getNewLanguage
{
    return _language;
}
#ifndef MADVCAMERA_EXPORT
//重新设置
-(void)resetRootViewController
{
    AppDelegate *appDelegate =
    (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UITabBarController * tabBarCon = [storyboard instantiateViewControllerWithIdentifier:@"BaseTabBar"];
    appDelegate.window.rootViewController = tabBarCon;
    
}
#endif
- (NSString *)getFilePath:(NSString *)fileName
{
    return [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle]pathForResource:self.language ofType:@"lproj"],fileName];
}
@end
