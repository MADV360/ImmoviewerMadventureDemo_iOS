//
//  ImageSlider.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/7.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "ImageSlider.h"
#import "UIImage+Blur.h"
#import "z_Sandbox.h"
#import "MadvGLRenderer_iOS.h"
#import <MadvUtils.h>
#import "UIDevice+DeviceModel.h"

@interface ImageSlider ()
@property(nonatomic,strong)dispatch_queue_t queue;
@property(nonatomic,strong)NSMutableArray * imageViewArr;
@property(nonatomic,weak)UIImageView * leftImageView;
@property(nonatomic,weak)UIImageView * rightImageView;
@property(nonatomic,weak)UIView * progressView;
@property(nonatomic,weak)UIView * leftMaskView;
@property(nonatomic,weak)UIView * rightMaskView;
@property(nonatomic,weak)UIView * progressPanView;
@property(nonatomic,assign)BOOL isPanGestureing;
@property(nonatomic,strong)NSCondition * stopCondition;
@property(nonatomic,assign)BOOL toStop;
@property(nonatomic,assign)BOOL hasStopped;
@property(nonatomic,assign)BOOL isFinishGetThumbnail;
@end

@implementation ImageSlider

- (NSMutableArray *)imageViewArr
{
    if (_imageViewArr == nil) {
        _imageViewArr = [[NSMutableArray alloc] init];
    }
    return _imageViewArr;
}
- (void)loadImageSlider
{
    self.queue =  dispatch_queue_create("EditThumbnailImage", NULL);
    CGFloat width = (self.width-60)/6;
    for (int i = 0; i<6; i++) {
        UIImageView * imageView = [[UIImageView alloc] init];
        [self.imageViewArr addObject:imageView];
        [self addSubview:imageView];
        imageView.frame = CGRectMake(30+width*i, 6.5, width, self.bounds.size.height-13);
        UIImage* thumbnailImage = nil;
        if ([UIDevice is6Above]) {
            thumbnailImage = [self getThumbnailImage:self.media index:i];
        }
        if (thumbnailImage == nil) {
            imageView.image = [UIImage imageNamed:@"time_line_default_image.png"];
        }else
        {
            imageView.image = thumbnailImage;
        }
        
    }
    UIImageView * leftImageView = [[UIImageView alloc] init];
    [self addSubview:leftImageView];
    leftImageView.frame = CGRectMake(20, 5.5, 10, self.bounds.size.height-11);
    leftImageView.image = [UIImage imageNamed:@"video-left.png"];
    self.leftImageView = leftImageView;
    
    UIView * leftMaskView = [[UIView alloc] init];
    [self addSubview:leftMaskView];
    leftMaskView.frame = CGRectMake(30, 6.5, 0, self.bounds.size.height-13);
    leftMaskView.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    self.leftMaskView = leftMaskView;
    
    UIView * rightMaskView = [[UIView alloc] init];
    [self addSubview:rightMaskView];
    rightMaskView.frame = CGRectMake(self.width-30, 6.5, 0, self.bounds.size.height-13);
    rightMaskView.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    self.rightMaskView = rightMaskView;
    
    UIImageView * rightImageView = [[UIImageView alloc] init];
    [self addSubview:rightImageView];
    rightImageView.frame = CGRectMake(self.bounds.size.width-30, 5.5, 10, self.bounds.size.height-11);
    rightImageView.image = [UIImage imageNamed:@"video-right.png"];
    
    self.rightImageView = rightImageView;
    
    UIView * progressView = [[UIView alloc] init];
    [self addSubview:progressView];
    progressView.frame = CGRectMake(30, 0, 2, self.bounds.size.height);
    progressView.backgroundColor = [UIColor colorWithRed:0.02f green:0.66f blue:1.00f alpha:1.00f];
    self.progressView = progressView;
    
    UIView * progressPanView = [[UIView alloc] init];
    [self addSubview:progressPanView];
    progressPanView.frame = CGRectMake(20, 0, 40, self.bounds.size.height);
    progressPanView.center = progressView.center;
    progressPanView.backgroundColor = [UIColor clearColor];
    self.progressPanView = progressPanView;
    
    UIPanGestureRecognizer * progressPanGes = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(progressPanGes:)];
    //无论最大还是最小都只允许一个手指
    progressPanGes.minimumNumberOfTouches = 1;
    progressPanGes.maximumNumberOfTouches = 1;
    [progressPanView addGestureRecognizer:progressPanGes];
    
    
    UIView * leftPanView = [[UIView alloc] init];
    [self addSubview:leftPanView];
    leftPanView.frame = CGRectMake(-10, 0, 60, self.bounds.size.height);
    leftPanView.backgroundColor = [UIColor clearColor];
    
    UIPanGestureRecognizer * leftPanGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(leftPanGes:)];
    leftPanGes.minimumNumberOfTouches = 1;
    leftPanGes.maximumNumberOfTouches = 1;
    [leftPanView addGestureRecognizer:leftPanGes];
    
    
    UIView * rightPanView = [[UIView alloc] init];
    [self addSubview:rightPanView];
    rightPanView.frame = CGRectMake(self.width-30, 0, 60, self.bounds.size.height);
    rightPanView.backgroundColor = [UIColor clearColor];
    
    UIPanGestureRecognizer * rightPanGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rightPanGes:)];
    rightPanGes.minimumNumberOfTouches = 1;
    rightPanGes.maximumNumberOfTouches = 1;
    [rightPanView addGestureRecognizer:rightPanGes];
    
    
}
#pragma mark --右边--
- (void)rightPanGes:(UIPanGestureRecognizer *)paramSender
{
    if (paramSender.state != UIGestureRecognizerStateEnded && paramSender.state != UIGestureRecognizerStateFailed){
        //通过使用 locationInView 这个方法,来获取到手势的坐标
        CGPoint location = [paramSender locationInView:paramSender.view.superview];
        if (location.x <= self.width-30 && location.x >= CGRectGetMaxX(self.progressView.frame)) {
            self.rightImageView.x=location.x;
            paramSender.view.x = location.x;
            
        }else if (location.x < CGRectGetMaxX(self.progressView.frame) && location.x >=CGRectGetMaxX(self.leftImageView.frame)+2)
        {
            self.progressView.x=location.x-2;
            self.progressPanView.center = self.progressView.center;
            self.rightImageView.x=location.x;
            paramSender.view.x = location.x;
        }
        if (CGRectGetMaxX(self.rightImageView.frame)<self.width-30) {
            self.rightMaskView.width = self.width-30-CGRectGetMaxX(self.rightImageView.frame);
            self.rightMaskView.x = self.width-30 -self.rightMaskView.width;
        }else
        {
            self.rightMaskView.width = 0;
        }
        
        if ([self.delegate respondsToSelector:@selector(imageSlider:rightValue:)]) {
            float rightValue = (CGRectGetMaxX(self.rightImageView.frame)-40)/(self.width-62);
            _rightValue = rightValue;
            [self.delegate imageSlider:self rightValue:rightValue];
        }
//        _value = (self.progressView.center.x-CGRectGetMaxX(self.leftImageView.frame)-1)/(CGRectGetMaxX(self.rightImageView.frame)-10-CGRectGetMaxX(self.leftImageView.frame) - 2);
        _value = (self.progressView.center.x-30-1)/(self.width-30-30 - 2);
        
        
    }
    
}
#pragma mark --左边--
- (void)leftPanGes:(UIPanGestureRecognizer *)paramSender
{
    if (paramSender.state != UIGestureRecognizerStateEnded && paramSender.state != UIGestureRecognizerStateFailed){
        //通过使用 locationInView 这个方法,来获取到手势的坐标
        CGPoint location = [paramSender locationInView:paramSender.view.superview];
        if (location.x >= 30 && location.x <= CGRectGetMaxX(self.progressView.frame)-2) {
            self.leftImageView.x=location.x-10;
            paramSender.view.x = location.x-40;
            
        }else if (location.x > CGRectGetMaxX(self.progressView.frame)-2 && location.x <= CGRectGetMaxX(self.rightImageView.frame)-12)
        {
            self.progressView.x=location.x;
            self.progressPanView.center = self.progressView.center;
            self.leftImageView.x=location.x-10;
            paramSender.view.x = location.x-40;
        }
        if (CGRectGetMaxX(self.leftImageView.frame)>40) {
            self.leftMaskView.width = CGRectGetMaxX(self.leftImageView.frame)-40;
        }else
        {
            self.leftMaskView.width = 0;
        }
        
        if ([self.delegate respondsToSelector:@selector(imageSlider:leftValue:)]) {
            float leftValue = (CGRectGetMaxX(self.leftImageView.frame)-30)/(self.width-62);
            _leftValue = leftValue;
            [self.delegate imageSlider:self leftValue:leftValue];
        }
       // _value = (self.progressView.center.x-CGRectGetMaxX(self.leftImageView.frame)-1)/(CGRectGetMaxX(self.rightImageView.frame)-10-CGRectGetMaxX(self.leftImageView.frame) - 2);
        _value = (self.progressView.center.x-30-1)/(self.width-30-30 - 2);
        
        
    }

}
#pragma mark --进度--
- (void)progressPanGes:(UIPanGestureRecognizer *)paramSender{
    if (paramSender.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(imageSliderProgressBeginChange:)]) {
            [self.delegate imageSliderProgressBeginChange:self];
        }
    }
    if (paramSender.state != UIGestureRecognizerStateEnded && paramSender.state != UIGestureRecognizerStateFailed){
        //self.isPanGestureing = YES;
        //通过使用 locationInView 这个方法,来获取到手势的坐标
        CGPoint location = [paramSender locationInView:paramSender.view.superview];
        if (location.x >= CGRectGetMaxX(self.leftImageView.frame)+1 && location.x <= CGRectGetMaxX(self.rightImageView.frame)-10-1) {
            if (location.x-(CGRectGetMaxX(self.leftImageView.frame)+1)<3) {
                paramSender.view.center = CGPointMake(CGRectGetMaxX(self.leftImageView.frame)+1, paramSender.view.center.y);
                self.progressView.center = CGPointMake(CGRectGetMaxX(self.leftImageView.frame)+1, paramSender.view.center.y);
            }else if ((CGRectGetMaxX(self.rightImageView.frame)-10-1)-location.x < 3)
            {
                paramSender.view.center = CGPointMake(CGRectGetMaxX(self.rightImageView.frame)-10-1, paramSender.view.center.y);
                self.progressView.center = CGPointMake(CGRectGetMaxX(self.rightImageView.frame)-10-1, paramSender.view.center.y);
            }else
            {
                paramSender.view.center = CGPointMake(location.x, paramSender.view.center.y);
                self.progressView.center = CGPointMake(location.x, paramSender.view.center.y);
            }
//            _value = (self.progressView.center.x-CGRectGetMaxX(self.leftImageView.frame)-1)/(CGRectGetMaxX(self.rightImageView.frame)-10-CGRectGetMaxX(self.leftImageView.frame) - 2);
            _value = (self.progressView.center.x-30-1)/(self.width-30-30 - 2);
            if ([self.delegate respondsToSelector:@selector(imageSliderProgressValueChange:)]) {
                [self.delegate imageSliderProgressValueChange:self];
            }
            
        }
        
    }else
    {
        if (paramSender.state == UIGestureRecognizerStateEnded) {
            if ([self.delegate respondsToSelector:@selector(imageSliderProgressDidChange:)]) {
                [self.delegate imageSliderProgressDidChange:self];
            }
        }
       // self.isPanGestureing = NO;
    }
}


- (void) stopGettingThumbnails {
    
    if (!self.isFinishGetThumbnail) {
        _toStop = YES;
        _hasStopped = NO;
        self.stopCondition = [[NSCondition alloc] init];
        [self.stopCondition lock];
        {
            while (!_hasStopped)
            {
                [self.stopCondition wait];
            }
        }
        [self.stopCondition unlock];
    }
    
}

- (UIImage*) getThumbnailImage:(MVMedia*)media index:(int)index {
    NSInteger time = self.media.videoDuration/6;
    dispatch_async(self.queue, ^{
        if (_toStop) {
            _hasStopped = YES;
            if (self.stopCondition) {
                [self.stopCondition lock];
                {
                    [self.stopCondition signal];
                }
                [self.stopCondition unlock];
            }
            
            return;
        }
        UIImage* originalImage = nil;
        originalImage = [UIImage getVideoImage:[media localFilePathSync:NO] time:time*index];
        if (originalImage) {
            UIImageView* imageView = self.imageViewArr[index];
            UIImage* thumbnailImage;
            //*
            float gyroMatrix[9];
            int rank = copyGyroMatrixFromString(gyroMatrix, media.gyroMatrixString.UTF8String);
            thumbnailImage = [MVPanoRenderer renderImage:originalImage destSize:CGSizeMake(128, 64) forceLUTStitching:YES sourcePath:[media localFilePathSync:NO] pMadvEXIFExtension:NULL filterID:0 gyroMatrix:gyroMatrix gyroMatrixBank:rank videoCaptureResolution:media.videoCaptureResolution];
            /*/
            thumbnailImage = originalImage;
            //*/
            dispatch_async(dispatch_get_main_queue(), ^{
                imageView.image = thumbnailImage;
            });
        }
        NSLog(@"getget+++++++++%d",index);
        
        if (_toStop || index == 5)
        {
            _hasStopped = YES;
            self.isFinishGetThumbnail = YES;
            if (self.stopCondition) {
                [self.stopCondition lock];
                {
                    [self.stopCondition signal];
                }
                [self.stopCondition unlock];
            }
            return;
        }
    });
    
    return nil;
}

- (void)setValue:(float)value
{
    _value = value;
    //self.progressView.x = (CGRectGetMaxX(self.rightImageView.frame)-10-CGRectGetMaxX(self.leftImageView.frame) - 2)*value + 10;
    self.progressView.x = (self.bounds.size.width - 60 -2) * value +30;
    self.progressPanView.center = self.progressView.center;
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
