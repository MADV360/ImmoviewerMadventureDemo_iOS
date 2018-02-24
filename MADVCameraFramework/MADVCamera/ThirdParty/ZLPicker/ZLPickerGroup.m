//
//  PickerGroup.m
//  ZLAssetsPickerDemo
//
//  Created by 张磊 on 14-11-11.
//  Copyright (c) 2014年 com.zixue101.www. All rights reserved.
//

#import "ZLPickerGroup.h"

@implementation ZLPickerGroup

- (NSString*) description {
    return [NSString stringWithFormat:@"ZLPickerGroup(%lx): groupName=%@, realGroupName=%@, assetsCount=%ld, type=%@, group=%@", (long)self, _groupName, _realGroupName, _assetsCount, _type, _group];
}

@end
