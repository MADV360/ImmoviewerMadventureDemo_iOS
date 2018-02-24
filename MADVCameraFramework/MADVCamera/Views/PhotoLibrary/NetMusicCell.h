//
//  NetMusicCell.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/11.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicInfo.h"

@class NetMusicCell;

@protocol NetMusicCellDelegate <NSObject>

- (void)netMusicCellDownload:(NetMusicCell *)netMusicCell isStart:(BOOL)isStart;

@end

@interface NetMusicCell : UITableViewCell
@property(nonatomic,weak)id<NetMusicCellDelegate> delegate;
@property(nonatomic,strong)MusicInfo * musicInfo;
@property(nonatomic,strong)NSIndexPath * indexPath;
@end
