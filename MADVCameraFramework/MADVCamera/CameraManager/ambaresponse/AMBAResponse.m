//
//  AMBAResponse.m
//  Madv360_v1
//
//  Created by DOM QIU on 16/9/5.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "AMBAResponse.h"

@implementation AMBAResponse

+ (NSArray<NSString* >*) jsonSerializablePropertyNames {
    return @[@"token", @"rval", @"msgID", @"rval", @"type", @"param"];
}

+ (NSDictionary<NSString*, NSString* >*) propertyNameToJsonKeyMap {
    return @{@"msgID":@"msg_id"};
}

- (NSString*) requestKey {
    return [@(self.msgID) stringValue];
}

- (BOOL) isRvalOK {
    return self.rval == AMBA_COMMAND_OK || self.rval == AMBA_NOTIFICATION_OK;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"AMBAResponse(%lx) : rval=%ld, msgID=%ld, param='%@', type='%@', token=%ld", (long)self.hash, (long)self.rval, self.msgID, self.param, self.type, self.token];
}

@end
