//
//  AvPlayScrollView.m
//  video
//
//  Created by 张巧隔 on 17/3/18.
//  Copyright © 2017年 张巧隔. All rights reserved.
//

#import "AvPlayScrollView.h"
#import <AVFoundation/AVFoundation.h>
#import "Masonry.h"
#import "SdGuideView.h"
#import "MyPageView.h"
#import "helper.h"
#import "NSString+Extensions.h"

@interface AvPlayScrollView ()<UIScrollViewDelegate,SdGuideViewDelegate>
@property(nonatomic,strong)NSMutableArray * playerItemArr;

@property(nonatomic,assign)NSInteger currentIndex;
@property(nonatomic,weak)MyPageView * pageControl;
@end

@implementation AvPlayScrollView
- (NSMutableArray *)playerItemArr
{
    if (_playerItemArr == nil) {
        _playerItemArr = [[NSMutableArray alloc] init];
    }
    return _playerItemArr;
}
- (NSMutableArray *)playerArr
{
    if (_playerArr == nil) {
        _playerArr = [[NSMutableArray alloc] init];
    }
    return _playerArr;
}
- (void)setDataSource:(NSArray *)dataSource
{
    _dataSource = dataSource;
    UIScrollView * scrollView = [[UIScrollView alloc] init];
    [self addSubview:scrollView];
    scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake(self.frame.size.width*dataSource.count, self.frame.size.height);
    scrollView.showsHorizontalScrollIndicator = FALSE;
    scrollView.pagingEnabled=YES;
    scrollView.bounces=NO;
    
    BOOL isEn = false;
    NSString * language = [NSString getAppLessLanguage];
    if ([language isEqualToString:@"en"]) {
        isEn = true;
    }
    
    for (int i = 0; i<dataSource.count; i++) {
        PlayScrollModel * playScroll = dataSource[i];
        UIView * baseView = [[UIView alloc] init];
        [scrollView addSubview:baseView];
        baseView.frame = CGRectMake(self.frame.size.width*i, 0, self.frame.size.width, self.frame.size.height);
        baseView.backgroundColor = [UIColor whiteColor];
        
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:playScroll.filename ofType:nil]]];
        //初始化player对象
        AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:item];
        //设置播放页面
        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player];
        //设置播放页面的大小
        layer.frame = CGRectMake(0, 0, self.width, 200);
        layer.backgroundColor = [UIColor whiteColor].CGColor;
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        //添加播放视图到self.view
        [baseView.layer addSublayer:layer];
        [self.playerItemArr addObject:item];
        [self.playerArr addObject:player];
        if (i == 0 || i == 1) {
            [player play];
        }
        
        UILabel * titleLabel = [[UILabel alloc] init];
        [baseView addSubview:titleLabel];
        CGFloat height;
        if (ScreenWidth > 320) {
            height = 300;
        }else
        {
            height = 250;
        }
        titleLabel.frame = CGRectMake(10, height, 120, 25);
        titleLabel.center = CGPointMake(0.5*self.width, titleLabel.center.y);
//        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(@(height));
//            make.centerX.equalTo(baseView.mas_centerX);
//            make.width.equalTo(@120);
//            make.height.equalTo(@25);
//        }];
        if (isEn) {
            titleLabel.font = [UIFont systemFontOfSize:20];
        }else
        {
            titleLabel.font = [UIFont systemFontOfSize:23];
        }
        
        titleLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        NSMutableAttributedString * attributedStr = [[NSMutableAttributedString alloc] initWithString:playScroll.title];
        titleLabel.attributedText = attributedStr;
        [titleLabel sizeToFit];
        titleLabel.x = self.width*0.5 - titleLabel.width*0.5;
        
        
        UILabel * tagLabel = [[UILabel alloc] init];
        [baseView addSubview:tagLabel];
        [tagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(titleLabel.mas_left).offset(-10);
            make.centerY.equalTo(titleLabel.mas_centerY);
            make.width.equalTo(@30);
            make.height.equalTo(@30);
        }];
        tagLabel.layer.masksToBounds = YES;
        tagLabel.layer.cornerRadius = 15;
        tagLabel.backgroundColor = [UIColor colorWithHexString:@"#46a4ea"];
        tagLabel.textColor = [UIColor whiteColor];
        tagLabel.font = [UIFont systemFontOfSize:19];
        tagLabel.text = [NSString stringWithFormat:@"%d",i+1];
        tagLabel.textAlignment = NSTextAlignmentCenter;
        
        
        
        UILabel * descLabel = [[UILabel alloc] init];
        [baseView addSubview:descLabel];
        
        descLabel.textAlignment = NSTextAlignmentCenter;
        if (isEn) {
            descLabel.font = [UIFont systemFontOfSize:15];
        }else
        {
            descLabel.font = [UIFont systemFontOfSize:17];
        }
        
        descLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        
        
        if (playScroll.linkStr) {
            
            if (isEn) {
//                [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//                    make.top.equalTo(titleLabel.mas_bottom).offset(40);
//                    make.centerX.equalTo(baseView.mas_centerX);
//                    make.width.equalTo(@250);
//                    make.height.equalTo(@40);
//                }];
                descLabel.frame = CGRectMake((ScreenWidth - 250) * 0.5, CGRectGetMaxY(titleLabel.frame) +40, 250, 40);
                descLabel.numberOfLines = 0;
            }else
            {
                [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(titleLabel.mas_bottom).offset(40);
                    make.centerX.equalTo(baseView.mas_centerX);
                    make.width.equalTo(@250);
                    make.height.equalTo(@19);
                }];
            }
            descLabel.text = playScroll.desc;
            if (isEn) {
                [descLabel sizeToFit];
            }
            if ([helper isNull:playScroll.type]) {
                UILabel * linkLabel = [[UILabel alloc] init];
                [baseView addSubview:linkLabel];
                [linkLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(descLabel.mas_bottom).offset(30);
                    make.centerX.equalTo(baseView.mas_centerX);
                    make.width.equalTo(@200);
                    make.height.equalTo(@30);
                }];
                linkLabel.textAlignment = NSTextAlignmentCenter;
                linkLabel.font = [UIFont systemFontOfSize:13];
                linkLabel.textColor = [UIColor colorWithHexString:@"#46a4ea"];
                NSMutableAttributedString * attributedStr=[[NSMutableAttributedString alloc] initWithString:playScroll.linkStr];
                [attributedStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#46a4ea"] range:NSMakeRange(0, playScroll.linkStr.length)];
                [attributedStr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(0, playScroll.linkStr.length)];
                linkLabel.attributedText = attributedStr;
                [linkLabel sizeToFit];
                
                linkLabel.userInteractionEnabled = YES;
                
                
                UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] init];
                [tapGes addTarget:self action:@selector(tapGes:)];
                [linkLabel addGestureRecognizer:tapGes];
            }else
            {
                UIButton * knowBtn = [[UIButton alloc] init];
                [baseView addSubview:knowBtn];
                [knowBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(descLabel.mas_bottom).offset(25);
                    make.centerX.equalTo(baseView.mas_centerX);
                    make.width.equalTo(@100);
                    make.height.equalTo(@33);
                }];
                [knowBtn setTitle:FGGetStringWithKeyFromTable(COURSEKNOWED, nil) forState:UIControlStateNormal];
                [knowBtn setTitleColor:[UIColor colorWithHexString:@"#46a4ea"] forState:UIControlStateNormal];
                [knowBtn addTarget:self action:@selector(knowBtn:) forControlEvents:UIControlEventTouchUpInside];
                if (isEn) {
                    knowBtn.titleLabel.font = [UIFont systemFontOfSize:15];
                }else
                {
                    knowBtn.titleLabel.font = [UIFont systemFontOfSize:17];
                }
                
                knowBtn.layer.masksToBounds = YES;
                knowBtn.layer.cornerRadius = 5;
                knowBtn.layer.borderColor = [UIColor colorWithHexString:@"#000000" alpha:0.4].CGColor;
                knowBtn.layer.borderWidth = 0.5;
            }
            
            
            
            
            
        }else
        {
            if (isEn) {
                descLabel.frame = CGRectMake(10, height+25+40, 200, 70);
                descLabel.numberOfLines = 0;
                descLabel.text = playScroll.desc;
                [descLabel sizeToFit];
                descLabel.center = CGPointMake(self.width*0.5, descLabel.center.y);
                
            }else
            {
                descLabel.frame = CGRectMake(10, height+25+40, 160, 70);
                descLabel.center = CGPointMake(self.width*0.5, descLabel.center.y);
                descLabel.numberOfLines = 2;
                descLabel.text = playScroll.desc;
            }
            
            
        }
        
        
        
        
        
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [self createMyPageView];
    
}
#pragma mark --知道了--
- (void)knowBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(avPlayScrollViewKnowClick:)]) {
        [self.delegate avPlayScrollViewKnowClick:self];
    }
}

#pragma mark --如何安装sd卡--
- (void)tapGes:(UITapGestureRecognizer *)tap
{
    NSLog(@"如何安装sd卡");
    SdGuideView * sdGuideView = [[SdGuideView alloc] init];
    [sdGuideView loadSdGuideView];
    [[UIApplication sharedApplication].keyWindow addSubview:sdGuideView];
    sdGuideView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    sdGuideView.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.7];
    sdGuideView.delegate = self;
    for (int i = 0; i < self.playerArr.count ; i++) {
        AVPlayer * player = self.playerArr[i];
        [player pause];
    }
}

#pragma mark --SdGuideViewDelegate代理方法的实现--
- (void)sdGuideViewDidClose:(SdGuideView *)sdGuideView
{
    AVPlayer * player = self.playerArr[self.currentIndex];
    [player seekToTime:CMTimeMake(0, 1)];
    [player play];
    if (self.currentIndex == 0) {
        AVPlayer * player = self.playerArr[self.currentIndex + 1];
        [player play];
        
    }
    [sdGuideView removeFromSuperview];
}

# pragma mark --添加页数控制条--
- (void)createMyPageView
{
    MyPageView * pageView = [[MyPageView alloc] init];
    [self addSubview:pageView];
    pageView.frame = CGRectMake(10, ScreenHeight-70-10-64, 25 * (self.dataSource.count -1) + 10, 10);
    pageView.center = CGPointMake(self.center.x, pageView.center.y);
    pageView.numberOfPages = self.dataSource.count;
    pageView.currentPage = 0;
    self.pageControl = pageView;
    /*
    UIPageControl * pageControl = [[UIPageControl alloc] init];
    [self addSubview:pageControl];
    [pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@-75);
        make.centerX.equalTo(self.mas_centerX);
        make.width.equalTo(@100);
        make.height.equalTo(@30);
    }];
    pageControl.numberOfPages = self.dataSource.count;
    pageControl.currentPage = 0;
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    pageControl.pageIndicatorTintColor = [UIColor grayColor];
    self.pageControl = pageControl;
     */
}
- (void)playbackFinished:(NSNotification *)noti
{
    for (int i = 0;i<self.playerItemArr.count;i++) {
        AVPlayerItem * item = self.playerItemArr[i];
        if (item == noti.object) {
            if (i==self.currentIndex || i == self.currentIndex - 1 || i == self.currentIndex + 1) {
                AVPlayer * player = self.playerArr[i];
                [player seekToTime:CMTimeMake(0, 1)];
                [player play];
            }else
            {
                AVPlayer * player = self.playerArr[i];
                [player seekToTime:CMTimeMake(0, 1)];
                [player pause];
            }
            
            break;
        }
    }
}

#pragma mark --UIScrollViewDelegate代理方法的实现--
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int index=scrollView.contentOffset.x/self.frame.size.width;
    if (self.currentIndex != index) {
        self.currentIndex = index;
        self.pageControl.currentPage = index;
        AVPlayer * player = self.playerArr[index];
        [player seekToTime:CMTimeMake(0, 1)];
        [player play];
        if (index == 0) {
            AVPlayer * player = self.playerArr[index + 1];
            [player play];
            for (int i = index + 2; i < self.playerArr.count ; i++) {
                AVPlayer * player = self.playerArr[i];
                [player pause];
            }
        }else if(index == self.playerArr.count-1)
        {
            AVPlayer * player = self.playerArr[index - 1];
            [player play];
            for (int i = index - 2; i >= 0 ; i--) {
                AVPlayer * player = self.playerArr[i];
                [player pause];
            }
        }else
        {
            AVPlayer * leftPlayer = self.playerArr[index - 1];
            [leftPlayer play];
            AVPlayer * rightPlayer = self.playerArr[index + 1];
            [rightPlayer play];
            for (int i = index - 2; i >= 0 ; i--) {
                AVPlayer * player = self.playerArr[i];
                [player pause];
            }
            for (int i = index + 2; i < self.playerArr.count ; i++) {
                AVPlayer * player = self.playerArr[i];
                [player pause];
            }
        }
    }
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
