//
//  UIImage+FixOrientation.h
//  Madv360
//
//  Created by FutureBoy on 11/4/15.
//  Copyright © 2015 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (FixOrientation)

- (UIImage *)fixOrientation;
+ (UIImage *)resizeImageWithName:(NSString *)name;
@end
