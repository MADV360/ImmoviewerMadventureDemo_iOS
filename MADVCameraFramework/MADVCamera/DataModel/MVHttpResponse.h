//
//  MVHttpResponse.h
//  Madv360_v1
//
//  Created by QiuDong on 16/5/23.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <MJExtension/MJExtension.h>

@interface MVHttpResponse : NSObject

@property (nonatomic, strong) id result;
@property (nonatomic, copy) NSString* cmd;
@property (nonatomic, assign) NSInteger rval;

@end


@interface MVGetFilenameResponse : MVHttpResponse
//{"rval":0, "filename":文件名,"region":区域,"bucket":文件夹,"url":地址前缀,"mac_key":key,"access_token":token}

@property (nonatomic, copy) NSString* filename;

@property (nonatomic, copy) NSString* region;

@property (nonatomic, copy) NSString* bucket;

@property (nonatomic, copy) NSString* url;
@property(nonatomic,copy)NSString * mac_key;
@property(nonatomic,copy)NSString * access_token;

@end
