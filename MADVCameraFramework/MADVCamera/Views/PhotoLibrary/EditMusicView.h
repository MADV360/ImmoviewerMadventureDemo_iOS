//
//  EditMusicView.h
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/9.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EditMusicView;

@protocol EditMusicViewDelegate <NSObject>

- (void)editMusicViewAddMusic:(EditMusicView *)editMusicView;
- (void)editMusicViewSliderValueChange:(EditMusicView *)editMusicView isMusicVoice:(BOOL)isMusicVoice;
@end

@interface EditMusicView : UIView
@property(nonatomic,weak)UIImageView * voiceImageView;
@property(nonatomic,weak)UISlider * voiceSlider;
@property(nonatomic,weak)UIImageView * musicImageView;
@property(nonatomic,weak)UILabel * addLabel;
@property(nonatomic,weak)UISlider * musicSlider;
@property(nonatomic,weak)id<EditMusicViewDelegate> delegate;
- (void)loadEditMusicView;
@end
