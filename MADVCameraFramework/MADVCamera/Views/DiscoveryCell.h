//
//  DiscoveryCell.h
//  Madv360_v1
//
//  Created by QiuDong on 16/5/13.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MVCloudMedia.h"
#import "DivisionButtonView.h"

@class DiscoveryCell;
@protocol DiscoveryCellDelegate <NSObject>

- (void)discoveryCellDidFavor:(DiscoveryCell *)discoveryCell andIsFavor:(NSString *)isFavor andFileName:(NSString *)fileName andImageView:(DivisionButtonView *) imageView andFavorNum:(int)favorNum title:(NSString *)title;
- (void)discoveryCellClick:(DiscoveryCell *)discoveryCell;
- (void)discoveryCellAuthorClick:(DiscoveryCell *)discoveryCell;
@end

@interface DiscoveryCell : UITableViewCell
@property(nonatomic,weak)id<DiscoveryCellDelegate> delegate;
@property(nonatomic,strong)MVCloudMedia * cloudMedia;
@property(nonatomic,strong)NSIndexPath *indexPath;

@property(nonatomic,assign)BOOL isFavor;
@property(nonatomic,assign)BOOL isMine;

//
- (void) setViewWithTitle:(NSString*)title imageURL:(NSString*)imageURL;

@end
