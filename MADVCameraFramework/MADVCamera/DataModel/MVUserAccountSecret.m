//
//  MVUserAccountSecret.m
//  Madv360_v1
//
//  Created by QiuDong on 16/5/20.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "MVUserAccountSecret.h"

@implementation MVUserAccountSecret

- (NSString*) description {
    return [NSString stringWithFormat:@"(userID, password, token) = (%@, %@, %@)", self.userID, self.password, self.token];
}

#pragma mark    NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.userID forKey:@"userID"];
    [aCoder encodeObject:self.password forKey:@"password"];
    [aCoder encodeObject:self.token forKey:@"token"];
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [self init])
    {
        self.userID = [aDecoder decodeObjectForKey:@"userID"];
        self.password = [aDecoder decodeObjectForKey:@"password"];
        self.token = [aDecoder decodeObjectForKey:@"token"];
    }
    return self;
}

@end
