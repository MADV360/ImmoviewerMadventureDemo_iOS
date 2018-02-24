//
//  SettingTreeNode.m
//  Madv360_v1
//
//  Created by 张巧隔 on 16/8/9.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "SettingTreeNode.h"
@implementation SettingTreeNode

+ (id)settingTreeNodeWithDict:(NSDictionary *)dict
{
    return [[self alloc] initWithDict:dict];
}
- (id)initWithDict:(NSDictionary *)dict
{
    if(self = [super init])
    {
        self.uid = [dict[@"uid"] intValue];
        self.name = dict[@"name"];
        NSArray * listArray  = dict[@"group"];
        NSMutableArray * subOptions = [NSMutableArray array];
        for(NSDictionary * listDict in listArray )
        {
            SettingTreeNode * optionNode = [[SettingTreeNode alloc] init];
            optionNode.uid = [listDict[@"uid"] intValue];
            optionNode.msgID = [listDict[@"msgID"] intValue];
            optionNode.name = listDict[@"name"];
            optionNode.jsonParamKey = listDict[@"jsonParamKey"];
            NSString * type= listDict[@"type"];
            if (type)
            {
                if ([type isEqualToString:@"slider"])
                {
                    optionNode.viewType=ViewTypeSliderSelection;
                }
                else if ([type isEqualToString:@"jump"])
                {
                    optionNode.viewType=ViewTypeJump;
                }
                else if ([type isEqualToString:@"action"])
                {
                    optionNode.viewType=ViewTypeAction;
                }
                else if ([type isEqualToString:@"readonly"])
                {
                    optionNode.viewType=ViewTypeReadOnly;
                }else if ([type isEqualToString:@"switch"])
                {
                    optionNode.viewType = ViewTypeSwitch;
                }
            }
            
            NSArray * paramArray  = listDict[@"option"];
            NSMutableArray * paramOptions = [NSMutableArray array];
            for(NSDictionary * paramDict in paramArray )
            {
                SettingTreeNode * paramNode=[[SettingTreeNode alloc] init];
                paramNode.uid=[paramDict[@"uid"] intValue];
                paramNode.msgID=[paramDict[@"msgID"] intValue];
                paramNode.name=paramDict[@"name"];
                
                [paramOptions addObject:paramNode];
            }
            optionNode.subOptions=paramOptions;
            
            [subOptions addObject:optionNode];
        }
        self.subOptions = subOptions;
    }
    return self;
}
+ (id)cameraModeParamNodeWithDict:(NSDictionary *)dict modeUid:(int)uid subModeUid:(int)subModeUid
{
    return [[self alloc] initWithDict:dict modeUid:uid subModeUid:subModeUid];
}
- (id)initWithDict:(NSDictionary *)dict modeUid:(int)uid subModeUid:(int)subModeUid
{
    if(self = [super init])
    {
        NSArray * listArray  = dict[@"group"];
        for(NSDictionary * listDict in listArray )
        {
            if ([listDict[@"uid"] intValue] == uid) {
                
                NSArray * subModeArr  = listDict[@"mode"];
                for(NSDictionary * subModeDict in subModeArr)
                {
                    if ([subModeDict[@"uid"] intValue] == subModeUid) {
                        self.uid=[subModeDict[@"uid"] intValue];
                        self.msgID=[subModeDict[@"msgID"] intValue];
                        self.name=subModeDict[@"name"];
                        
                        NSArray * paramArray=subModeDict[@"subMode"];
                        NSMutableArray * paramOptions = [NSMutableArray array];
                        for(NSDictionary * paramDict in paramArray )
                        {
                            SettingTreeNode * paramNode=[[SettingTreeNode alloc] init];
                            paramNode.msgID=[paramDict[@"msgID"] intValue];
                            paramNode.name=paramDict[@"name"];
                            paramNode.value=[paramDict[@"value"] floatValue];
                            
                            
                            
                            [paramOptions addObject:paramNode];
                        }
                        
                        self.subOptions = paramOptions;
                        break;
                    }
                }
                
                
                
                break;
            }
            
            
        }
        
    }
    return self;
}

+ (id)cameraModeParamNodeWithDict:(NSDictionary *)dict modeName:(NSString *)modeName subModeName:(NSString *)subModeName
{
    return [[self alloc] initWithDict:dict modeName:modeName subModeName:subModeName];
}
- (id)initWithDict:(NSDictionary *)dict modeName:(NSString *)modeName subModeName:(NSString *)subModeName
{
    if(self = [super init])
    {
        NSArray * listArray  = dict[@"group"];
        for(NSDictionary * listDict in listArray )
        {
            if ([listDict[@"name"] isEqualToString:modeName]) {
                
                NSArray * subModeArr  = listDict[@"mode"];
                for(NSDictionary * subModeDict in subModeArr)
                {
                    if ([subModeDict[@"name"] isEqualToString:subModeName]) {
                        self.uid=[subModeDict[@"uid"] intValue];
                       self.msgID=[subModeDict[@"msgID"] intValue];
                        self.name=subModeDict[@"name"];
                        
                        NSArray * paramArray=subModeDict[@"subMode"];
                        NSMutableArray * paramOptions = [NSMutableArray array];
                        for(NSDictionary * paramDict in paramArray )
                        {
                            SettingTreeNode * paramNode=[[SettingTreeNode alloc] init];
                           paramNode.msgID=[paramDict[@"msgID"] intValue];
                             paramNode.name=paramDict[@"name"];
                            paramNode.value=[paramDict[@"value"] floatValue];
                            
                            
                            
                            [paramOptions addObject:paramNode];
                        }
                        
                        self.subOptions = paramOptions;
                        break;
                    }
                }

                
                
                break;
            }
            
            
        }
            
    }
    return self;
}
- (SettingTreeNode *)findSubOptionByUID:(int)subOptionUID
{
    SettingTreeNode * treeNode;
    for(SettingTreeNode * node in self.subOptions)
    {
        if (node.uid==subOptionUID) {
            treeNode=node;
            break;
        }
    }
    return treeNode;
}

- (SettingTreeNode *)findSubOptionByMsgID:(int)subOptionMsgID
{
    SettingTreeNode * treeNode;
    for(SettingTreeNode * node in self.subOptions)
    {
        if (node.msgID==subOptionMsgID) {
            treeNode=node;
            break;
        }
    }
    return treeNode;
}
- (BOOL)isSupportSlowMotionParameter:(int)parameter
{
    BOOL flag = true;
    if (parameter == 4) {
        if ([self.name containsString:@"30fps"]) {
            flag = false;
        }
    }
    if (parameter == 8) {
        if ([self.name containsString:@"30fps"] || [self.name containsString:@"60fps"]) {
            flag = false;
        }
    }
    return flag;
}
- (BOOL)isSupportVideoTimelapse
{
    BOOL flag = true;
    if ([self.name containsString:@"120fps"]) {
        flag = false;
    }
    return flag;
}
- (BOOL)isSupportBracketing
{
    BOOL flag = true;
    if ([self.name containsString:@"Raw"]) {
        flag = false;
    }
    return flag;
}

@end
