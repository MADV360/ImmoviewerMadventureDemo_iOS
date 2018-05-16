//
//  LoadProgressView.h
//
//  Created by MS on 15-12-17.
//  Copyright (c) 2015年 MS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoadProgressView : UIView
- (void)startLoadData;
- (void)finishLoadData:(void (^ __nullable)(BOOL finished))completion;
@end
