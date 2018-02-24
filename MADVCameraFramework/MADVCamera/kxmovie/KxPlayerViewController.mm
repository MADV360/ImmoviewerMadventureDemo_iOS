//
//  KxPlayerViewController.m
//  Madv360_v1
//
//  Created by QiuDong on 16/3/21.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "KxPlayerViewController.h"
#import "KxMovieDecoder.h"
#import "KxAudioManager.h"
#import "MadvGLRenderer.h"

enum {
    
    KxMovieInfoSectionGeneral,
    KxMovieInfoSectionVideo,
    KxMovieInfoSectionAudio,
    KxMovieInfoSectionSubtitles,
    KxMovieInfoSectionMetadata,
    KxMovieInfoSectionCount,
};

enum {
    
    KxMovieInfoGeneralFormat,
    KxMovieInfoGeneralBitrate,
    KxMovieInfoGeneralCount,
};


@interface KxPlayerViewController () <UITableViewDataSource, UITableViewDelegate>
{
    BOOL                _hiddenHUD;
    BOOL                _infoMode;
    
    UIView              *_topHUD;
    UIToolbar           *_topBar;
    UIToolbar           *_bottomBar;
    UIButton            *_modeButton;
    UISlider            *_progressSlider;
    
    UIBarButtonItem     *_playBtn;
    UIBarButtonItem     *_pauseBtn;
    UIBarButtonItem     *_rewindBtn;
    UIBarButtonItem     *_fforwardBtn;
    UIBarButtonItem     *_spaceItem;
    UIBarButtonItem     *_fixedSpaceItem;
    
    UIButton            *_doneButton;
    UILabel             *_progressLabel;
    UILabel             *_leftLabel;
    UIButton            *_infoButton;
    UITableView         *_tableView;
    UIActivityIndicatorView *_activityIndicatorView;
    UILabel             *_subtitlesLabel;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
    UITapGestureRecognizer *_doubleTapGestureRecognizer;
    UIPanGestureRecognizer *_panGestureRecognizer;
    
}

@property (nonatomic, strong) KxMovieDecoder* decoder;

@property (nonatomic, strong) NSMutableArray* subtitles;

@property (nonatomic, assign) CGFloat moviePosition;

@end

@implementation KxPlayerViewController

@dynamic decoder;
@dynamic moviePosition;
@dynamic subtitles;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect bounds = [[UIScreen mainScreen] applicationFrame];
    self.view.frame = bounds;
    
    // Do any additional setup after loading the view.
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicatorView.center = self.view.center;
    _activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    [self.view addSubview:_activityIndicatorView];
    
    CGFloat width = bounds.size.width;
    CGFloat height = bounds.size.height;
    
    CGFloat topH = 50;
    CGFloat botH = 50;
    _topHUD    = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    _topBar    = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, width, topH)];
    _bottomBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, height-botH, width, botH)];
    _bottomBar.tintColor = [UIColor blackColor];
    
    _modeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _modeButton.backgroundColor = [UIColor blueColor];
    [_modeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_modeButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    //[_modeButton setTitle:[NSString stringWithUTF8String:DisplayModeString[self.displayModeIndex]] forState:UIControlStateNormal];
    [_modeButton sizeToFit];
    
    _modeButton.center = CGPointMake(CGRectGetMaxX(_bottomBar.frame) - _modeButton.bounds.size.width / 2, CGRectGetMidY(_bottomBar.frame));
    [_modeButton addTarget:self action:@selector(onModeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _modeButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    _topHUD.frame = CGRectMake(0,0,width,_topBar.frame.size.height);
    
    _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _bottomBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:_topBar];
    [self.view addSubview:_topHUD];
    [self.view addSubview:_bottomBar];
    [self.view addSubview:_modeButton];
    
    // top hud
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(0, 1, 50, topH);
    _doneButton.backgroundColor = [UIColor clearColor];
    //    _doneButton.backgroundColor = [UIColor redColor];
    [_doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_doneButton setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:18];
    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch:)
          forControlEvents:UIControlEventTouchUpInside];
    //    [_doneButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    
    _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(46, 1, 50, topH)];
    _progressLabel.backgroundColor = [UIColor clearColor];
    _progressLabel.opaque = NO;
    _progressLabel.adjustsFontSizeToFitWidth = NO;
    _progressLabel.textAlignment = NSTextAlignmentRight;
    _progressLabel.textColor = [UIColor blackColor];
    _progressLabel.text = @"";
    _progressLabel.font = [UIFont systemFontOfSize:12];
    
    _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(100, 2, width-197, topH)];
    _progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _progressSlider.continuous = NO;
    _progressSlider.value = 0;
        [_progressSlider setThumbImage:[UIImage imageNamed:@"kxmovie.bundle/sliderthumb"]
                              forState:UIControlStateNormal];
    
    _leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(width-92, 1, 60, topH)];
    _leftLabel.backgroundColor = [UIColor clearColor];
    _leftLabel.opaque = NO;
    _leftLabel.adjustsFontSizeToFitWidth = NO;
    _leftLabel.textAlignment = NSTextAlignmentLeft;
    _leftLabel.textColor = [UIColor blackColor];
    _leftLabel.text = @"";
    _leftLabel.font = [UIFont systemFontOfSize:12];
    _leftLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    _infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    _infoButton.frame = CGRectMake(width-31, (topH-20)/2+1, 20, 20);
    _infoButton.showsTouchWhenHighlighted = YES;
    _infoButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [_infoButton addTarget:self action:@selector(infoDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    
    [_topHUD addSubview:_doneButton];
    [_topHUD addSubview:_progressLabel];
    [_topHUD addSubview:_progressSlider];
    [_topHUD addSubview:_leftLabel];
    [_topHUD addSubview:_infoButton];
    
    // bottom hud
    
    _spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                               target:nil
                                                               action:nil];
    
    _fixedSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                    target:nil
                                                                    action:nil];
    _fixedSpaceItem.width = 30;
    
    _rewindBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                                               target:self
                                                               action:@selector(rewindDidTouch:)];
    
    _playBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                             target:self
                                                             action:@selector(playDidTouch:)];
    _playBtn.width = 50;
    
    _pauseBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                              target:self
                                                              action:@selector(playDidTouch:)];
    _pauseBtn.width = 50;
    
    _fforwardBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward
                                                                 target:self
                                                                 action:@selector(forwardDidTouch:)];
    
    [self updateBottomBar];
    
    if (!self.decoder)
    {
        _progressLabel.hidden = YES;
        _progressSlider.hidden = YES;
        _leftLabel.hidden = YES;
        _infoButton.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_infoMode)
        [self showInfoView:NO animated:NO];

    if (!self.decoder)
    {
        [_activityIndicatorView startAnimating];
    }
    
    [self showHUD: YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:[UIApplication sharedApplication]];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_activityIndicatorView stopAnimating];
    
}

- (void) applicationWillResignActive: (NSNotification *)notification
{
    [self showHUD:YES];
    [self pause];
    
//    LoggerStream(1, @"applicationWillResignActive");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return KxMovieInfoSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case KxMovieInfoSectionGeneral:
            return NSLocalizedString(@"General", nil);
        case KxMovieInfoSectionMetadata:
            return NSLocalizedString(@"Metadata", nil);
        case KxMovieInfoSectionVideo: {
            NSArray *a = self.decoder.info[@"video"];
            return a.count ? NSLocalizedString(@"Video", nil) : nil;
        }
        case KxMovieInfoSectionAudio: {
            NSArray *a = self.decoder.info[@"audio"];
            return a.count ?  NSLocalizedString(@"Audio", nil) : nil;
        }
        case KxMovieInfoSectionSubtitles: {
            NSArray *a = self.decoder.info[@"subtitles"];
            return a.count ? NSLocalizedString(@"Subtitles", nil) : nil;
        }
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case KxMovieInfoSectionGeneral:
            return KxMovieInfoGeneralCount;
            
        case KxMovieInfoSectionMetadata: {
            NSDictionary *d = [self.decoder.info valueForKey:@"metadata"];
            return d.count;
        }
            
        case KxMovieInfoSectionVideo: {
            NSArray *a = self.decoder.info[@"video"];
            return a.count;
        }
            
        case KxMovieInfoSectionAudio: {
            NSArray *a = self.decoder.info[@"audio"];
            return a.count;
        }
            
        case KxMovieInfoSectionSubtitles: {
            NSArray *a = self.decoder.info[@"subtitles"];
            return a.count ? a.count + 1 : 0;
        }
            
        default:
            return 0;
    }
}

- (id) mkCell: (NSString *) cellIdentifier
    withStyle: (UITableViewCellStyle) style
{
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier];
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == KxMovieInfoSectionGeneral) {
        
        if (indexPath.row == KxMovieInfoGeneralBitrate) {
            
            int bitrate = [self.decoder.info[@"bitrate"] intValue];
            cell = [self mkCell:@"ValueCell" withStyle:UITableViewCellStyleValue1];
            cell.textLabel.text = NSLocalizedString(@"Bitrate", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d kb/s",bitrate / 1000];
            
        } else if (indexPath.row == KxMovieInfoGeneralFormat) {
            
            NSString *format = self.decoder.info[@"format"];
            cell = [self mkCell:@"ValueCell" withStyle:UITableViewCellStyleValue1];
            cell.textLabel.text = NSLocalizedString(@"Format", nil);
            cell.detailTextLabel.text = format ? format : @"-";
        }
        
    } else if (indexPath.section == KxMovieInfoSectionMetadata) {
        
        NSDictionary *d = self.decoder.info[@"metadata"];
        NSString *key = d.allKeys[indexPath.row];
        cell = [self mkCell:@"ValueCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.text = key.capitalizedString;
        cell.detailTextLabel.text = [d valueForKey:key];
        
    } else if (indexPath.section == KxMovieInfoSectionVideo) {
        
        NSArray *a = self.decoder.info[@"video"];
        cell = [self mkCell:@"VideoCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.text = a[indexPath.row];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 2;
        
    } else if (indexPath.section == KxMovieInfoSectionAudio) {
        
        NSArray *a = self.decoder.info[@"audio"];
        cell = [self mkCell:@"AudioCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.text = a[indexPath.row];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 2;
        BOOL selected = self.decoder.selectedAudioStream == indexPath.row;
        cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
    } else if (indexPath.section == KxMovieInfoSectionSubtitles) {
        
        NSArray *a = self.decoder.info[@"subtitles"];
        
        cell = [self mkCell:@"SubtitleCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 1;
        
        if (indexPath.row) {
            cell.textLabel.text = a[indexPath.row - 1];
        } else {
            cell.textLabel.text = NSLocalizedString(@"Disable", nil);
        }
        
        const BOOL selected = self.decoder.selectedSubtitleStream == (indexPath.row - 1);
        cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == KxMovieInfoSectionAudio) {
        
        NSInteger selected = self.decoder.selectedAudioStream;
        
        if (selected != indexPath.row) {
            
            self.decoder.selectedAudioStream = indexPath.row;
            NSInteger now = self.decoder.selectedAudioStream;
            
            if (now == indexPath.row) {
                
                UITableViewCell *cell;
                
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                indexPath = [NSIndexPath indexPathForRow:selected inSection:KxMovieInfoSectionAudio];
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        
    } else if (indexPath.section == KxMovieInfoSectionSubtitles) {
        
        NSInteger selected = self.decoder.selectedSubtitleStream;
        
        if (selected != (indexPath.row - 1)) {
            
            self.decoder.selectedSubtitleStream = indexPath.row - 1;
            NSInteger now = self.decoder.selectedSubtitleStream;
            
            if (now == (indexPath.row - 1)) {
                
                UITableViewCell *cell;
                
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                indexPath = [NSIndexPath indexPathForRow:selected + 1 inSection:KxMovieInfoSectionSubtitles];
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            // clear subtitles
            _subtitlesLabel.text = nil;
            _subtitlesLabel.hidden = YES;
            @synchronized(self.subtitles) {
                [self.subtitles removeAllObjects];
            }
        }
    }
}

#pragma mark - gesture recognizer

- (void) handleTap: (UITapGestureRecognizer *) sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        if (sender == _tapGestureRecognizer) {
            
            [self showHUD: _hiddenHUD];
            
        } else if (sender == _doubleTapGestureRecognizer) {
            
            UIView *frameView = [self frameView];
            
            if (frameView.contentMode == UIViewContentModeScaleAspectFit)
                frameView.contentMode = UIViewContentModeScaleAspectFill;
            else
                frameView.contentMode = UIViewContentModeScaleAspectFit;
            
        }
    }
}

- (void) handlePan: (UIPanGestureRecognizer *) sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        const CGPoint vt = [sender velocityInView:self.view];
        const CGPoint pt = [sender translationInView:self.view];
        const CGFloat sp = MAX(0.1, log10(fabsf(vt.x)) - 1.0);
        const CGFloat sc = fabsf(pt.x) * 0.33 * sp;
        if (sc > 10) {
            
            const CGFloat ff = pt.x > 0 ? 1.0 : -1.0;
            [self setMoviePosition: self.moviePosition + ff * MIN(sc, 600.0)];
        }
        //LoggerStream(2, @"pan %.2f %.2f %.2f sec", pt.x, vt.x, sc);
    }
}

#pragma mark - actions

- (void) doneDidTouch: (id) sender
{
    if (self.presentingViewController || !self.navigationController)
        [self dismissViewControllerAnimated:YES completion:nil];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void) infoDidTouch: (id) sender
{
    [self showInfoView: !_infoMode animated:YES];
}

- (void) playDidTouch: (id) sender
{
    if (self.playing)
        [self pause];
    else
        [self play];
    /*
    if (self.playing){
        NSLog(@"playDidTouch:pause");
        [self pause];
    }
    else if (_decoder.isEOF) {
        NSLog(@"playDidTouch:restorePlay");
        [self restorePlay];
    }
    else {
        NSLog(@"playDidTouch:play");
        [self play];
    }*/
}

- (void) forwardDidTouch: (id) sender
{
    [self setMoviePosition: self.moviePosition + 10];
}

- (void) rewindDidTouch: (id) sender
{
    NSLog(@"rewindDidTouch");
    [self setMoviePosition: self.moviePosition - 10];
}

- (void) progressDidChange: (id) sender
{
    NSAssert(self.decoder.duration != MAXFLOAT, @"bugcheck");
    UISlider *slider = sender;
    [self setMoviePosition:slider.value * self.decoder.duration];
}

- (void) onModeButtonPressed:(id)sender {
    //self.displayModeIndex = (self.displayModeIndex + 1) % DisplayModesCount;
}

- (void) showWaitView {
    [_activityIndicatorView startAnimating];
}

- (void) dismissWaitView {
    [_activityIndicatorView stopAnimating];
}

- (void) showHUD: (BOOL) show
{
    _hiddenHUD = !show;
    _panGestureRecognizer.enabled = _hiddenHUD;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:_hiddenHUD];
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                     animations:^{
                         
                         CGFloat alpha = _hiddenHUD ? 0 : 1;
                         _topBar.alpha = alpha;
                         _topHUD.alpha = alpha;
                         _bottomBar.alpha = alpha;
                         _modeButton.alpha = alpha;
                     }
                     completion:nil];
    
}

#pragma mark    MVKxMovieViewController Callbacks

- (void) didSetMovieDecoder:(KxMovieDecoder*)decoder withError:(NSError*)error {
    if (!error && decoder)
    {
        if (self.isViewLoaded) {
            _progressLabel.hidden   = NO;
            _progressSlider.hidden  = NO;
            _leftLabel.hidden       = NO;
            _infoButton.hidden      = NO;
            
            if (_activityIndicatorView.isAnimating) {
                [_activityIndicatorView stopAnimating];
                // if (self.view.window)
                
                NSLog(@"didSetMovieDecoder restorePlay");
                [self restorePlay];
            }
        }
    }
    else
    {
        if (self.isViewLoaded && self.view.window) {
            [_activityIndicatorView stopAnimating];
        }
    }
}

- (void) didSetupPresentView:(UIView*)presentView {
    presentView.contentMode = UIViewContentModeScaleAspectFit;
    presentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.view insertSubview:presentView atIndex:0];
    
    if (self.decoder.duration == MAXFLOAT) {
        
        _leftLabel.text = @"\u221E"; // infinity
        _leftLabel.font = [UIFont systemFontOfSize:14];
        
        CGRect frame;
        
        frame = _leftLabel.frame;
        frame.origin.x += 40;
        frame.size.width -= 40;
        _leftLabel.frame = frame;
        
        frame =_progressSlider.frame;
        frame.size.width += 40;
        _progressSlider.frame = frame;
        
    } else {
        
        [_progressSlider addTarget:self
                            action:@selector(progressDidChange:)
                  forControlEvents:UIControlEventValueChanged];
    }
    
    if (self.decoder.subtitleStreamsCount) {
        
        CGSize size = self.view.bounds.size;
        
        _subtitlesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, size.height, size.width, 0)];
        _subtitlesLabel.numberOfLines = 0;
        _subtitlesLabel.backgroundColor = [UIColor clearColor];
        _subtitlesLabel.opaque = NO;
        _subtitlesLabel.adjustsFontSizeToFitWidth = NO;
        _subtitlesLabel.textAlignment = NSTextAlignmentCenter;
        _subtitlesLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _subtitlesLabel.textColor = [UIColor whiteColor];
        _subtitlesLabel.font = [UIFont systemFontOfSize:16];
        _subtitlesLabel.hidden = YES;
        
        [self.view addSubview:_subtitlesLabel];
    }
}

- (void) didSetupUserInteraction {
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    
    _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    
    [_tapGestureRecognizer requireGestureRecognizerToFail: _doubleTapGestureRecognizer];
    
    UIView * view = [self frameView];
    [view addGestureRecognizer:_doubleTapGestureRecognizer];
    [view addGestureRecognizer:_tapGestureRecognizer];
    
    //    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    //    _panGestureRecognizer.enabled = NO;
    //
    //    [view addGestureRecognizer:_panGestureRecognizer];
}

- (void) didPlay {
    [self updatePlayButton];
}

- (void) didPause {
    [self updatePlayButton];
}

#pragma mark    MVKxMovieViewController Protected Methods

- (void) updatePositionView {
    const CGFloat duration = self.decoder.duration;
    const CGFloat position = self.moviePosition -self.decoder.startTime;
    
    if (_progressSlider.state == UIControlStateNormal)
        _progressSlider.value = position / duration;
    _progressLabel.text = formatTimeInterval(position, NO);
    
    if (self.decoder.duration != MAXFLOAT)
        _leftLabel.text = formatTimeInterval(duration - position, YES);

}

- (void) showSubtitleText:(NSString*)text {
    if (text)
    {
        if (![_subtitlesLabel.text isEqualToString:text]) {
            
            CGSize viewSize = self.view.bounds.size;
            CGSize size = [text sizeWithFont:_subtitlesLabel.font
                         constrainedToSize:CGSizeMake(viewSize.width, viewSize.height * 0.5)
                             lineBreakMode:NSLineBreakByTruncatingTail];
            _subtitlesLabel.text = text;
            _subtitlesLabel.frame = CGRectMake(0, viewSize.height - size.height - 10,
                                               viewSize.width, size.height);
            _subtitlesLabel.hidden = NO;
        }
    }
    else
    {
        _subtitlesLabel.text = nil;
        _subtitlesLabel.hidden = YES;
    }
}


#pragma mark    Private

- (void) updateBottomBar
{
    UIBarButtonItem *playPauseBtn = self.playing ? _pauseBtn : _playBtn;
    [_bottomBar setItems:@[_spaceItem, _rewindBtn, _fixedSpaceItem, playPauseBtn,
                           _fixedSpaceItem, _fforwardBtn, _spaceItem] animated:NO];
}

- (void) updatePlayButton
{
    [self updateBottomBar];
}

- (void) showInfoView: (BOOL) showInfo animated: (BOOL)animated
{
    if (!_tableView)
        [self createTableView];
    
    [self pause];
    
    CGSize size = self.view.bounds.size;
    CGFloat Y = _topHUD.bounds.size.height;
    
    if (showInfo) {
        
        _tableView.hidden = NO;
        
        if (animated) {
            
            [UIView animateWithDuration:0.4
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                             animations:^{
                                 
                                 _tableView.frame = CGRectMake(0,Y,size.width,size.height - Y);
                             }
                             completion:nil];
        } else {
            
            _tableView.frame = CGRectMake(0,Y,size.width,size.height - Y);
        }
        
    } else {
        
        if (animated) {
            
            [UIView animateWithDuration:0.4
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                             animations:^{
                                 
                                 _tableView.frame = CGRectMake(0,size.height,size.width,size.height - Y);
                                 
                             }
                             completion:^(BOOL f){
                                 
                                 if (f) {
                                     _tableView.hidden = YES;
                                 }
                             }];
        } else {
            
            _tableView.frame = CGRectMake(0,size.height,size.width,size.height - Y);
            _tableView.hidden = YES;
        }
    }
    
    _infoMode = showInfo;
}

- (void) createTableView
{
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.hidden = YES;
    
    CGSize size = self.view.bounds.size;
    CGFloat Y = _topHUD.bounds.size.height;
    _tableView.frame = CGRectMake(0,size.height,size.width,size.height - Y);
    
    [self.view addSubview:_tableView];
}

@end
