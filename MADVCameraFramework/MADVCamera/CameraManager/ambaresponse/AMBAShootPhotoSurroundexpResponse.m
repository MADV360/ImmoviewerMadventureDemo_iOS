//
//  AMBAShootPhotoSurroundexpResponse.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/10/25.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "AMBAShootPhotoSurroundexpResponse.h"

@implementation AMBAShootPhotoSurroundexpResponse
+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    NSArray* myArray = @[@"sur_exp"];
    mergeJsonSerializablePropertyNames(array, myArray);
    return array;
}
@end
