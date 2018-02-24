//
//  UITableViewCell+LXCellInit.m
//  DasBank
//
//  Created by 张巧隔 on 16/3/31.
//  Copyright © 2016年 LXWT. All rights reserved.
//

#import "UITableViewCell+LXCellInit.h"

@implementation UITableViewCell (LXCellInit)
+ (id)cellWithTableview:(UITableView *)tableView
{
    NSString * className=NSStringFromClass([self class]);
    [tableView registerClass:[self class] forCellReuseIdentifier:className];
    return [tableView dequeueReusableCellWithIdentifier:className];
    return nil;
}
@end
