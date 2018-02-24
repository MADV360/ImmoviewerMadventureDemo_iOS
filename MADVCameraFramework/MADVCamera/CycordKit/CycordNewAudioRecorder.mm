//
//  CycordNewAudioRecorder.m
//  ClumsyCopter
//
//  Created by FutureBoy on 12/24/14.
//
//
#ifdef TARGET_OS_IOS

#import "CycordNewAudioRecorder.h"

#define checkStatus(...) assert(0 == __VA_ARGS__)

#define kChannels 1

static CycordNewAudioRecorder* g_sharedInstance = nil;

@interface CycordNewAudioRecorder ()
{
    NSString* _outputAudioBaseName;
    AVAudioRecorder * _audioRecorder;
}

@end


@implementation CycordNewAudioRecorder


+ (CycordNewAudioRecorder*) sharedInstance {
    if (nil == g_sharedInstance)
    {
        g_sharedInstance = [[CycordNewAudioRecorder alloc] init];
    }
    return g_sharedInstance;
}


- (void) dealloc {

}

- (id) init {
    if (g_sharedInstance) return g_sharedInstance;
    
    self = [super init];
    if (self)
    {

        
    }
    return self;
}

- (void) startRecording {
    //Create an audio file for recording
    [self prepareToRecordAudio];
    //[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:(AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionMixWithOthers)
                                     error:nil];
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [_audioRecorder record];

}

- (void) stopRecording {
    [_audioRecorder stop];
    _audioRecorder = nil;
    //[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    //[[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void) pauseRecording {
    if(_audioRecorder)
        [_audioRecorder pause];
    //[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    //[[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void) resumeRecording {
    //[[AVAudioSession sharedInstance] setActive:YES error:nil];
    //[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    if(_audioRecorder)
        [_audioRecorder record];
}

- (void) setOutputAudioBaseName:(NSString*) audioBaseName {
    _outputAudioBaseName = [audioBaseName stringByAppendingFormat:@"%@", @".aac"];
    //_outputAudioBaseName = @"capture_sound.caf";
}

- (void) prepareToRecordAudio
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];//!!!It matters AVAudioSessionCategoryAmbient
    if (err)
    {
       NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
       return;
    }
 
    err = nil;
    [audioSession setActive:YES error:&err];
    if (err)
    {
       NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
       return;
    }
 
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    //[recordSetting setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    //[recordSetting setValue :[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //[recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    //[recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
 
    //Create a new dated file
    NSString * recorderFilePath = [NSString stringWithFormat:@"%@/%@", [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], _outputAudioBaseName];
    NSURL *url = [NSURL fileURLWithPath:recorderFilePath];
    err = nil;
    _audioRecorder = [[ AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:&err];
    if (!_audioRecorder)
    {
       NSLog(@"recorder: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
       UIAlertView *alert =
       [[UIAlertView alloc] initWithTitle: @"Warning"
       message: [err localizedDescription]
       delegate: nil
       cancelButtonTitle:@"OK"
       otherButtonTitles:nil];
       [alert show];
      // [alert release];
        return;
    }
    //prepare to record
    [_audioRecorder setDelegate:self];
    [_audioRecorder prepareToRecord];
    _audioRecorder.meteringEnabled = YES;
    BOOL audioHWAvailable = audioSession.inputIsAvailable;
    if (! audioHWAvailable)
    {
       UIAlertView *cantRecordAlert =
       [[UIAlertView alloc] initWithTitle: @"Warning"
       message: @"Audio input hardware not available"
       delegate: nil
       cancelButtonTitle:@"OK"
       otherButtonTitles:nil];
       [cantRecordAlert show];
      // [cantRecordAlert release];
       return;
    }
 }
 
 
 //代理 这里可以监听录音成功
 - (void)audioRecorderDidFinishRecording:(AVAudioRecorder *) aRecorder successfully:(BOOL)flag
 {
     NSLog(@"audio recorder succeed");
    
     //UIAlertView *recorderSuccessful = [[UIAlertView alloc] initWithTitle:@"" message:@"录音成功"
     //                                                            delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
     //[recorderSuccessful show];
     //[recorderSuccessful release];
 }
 
 
 //代理 这里可以监听录音失败
 - (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)arecorder error:(NSError *)error
 {
     NSLog(@"audio recorder fail");
 
     //UIAlertView *recorderFailed = [[UIAlertView alloc] initWithTitle:@"" message:@"发生错误"
     //                                                        delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
     //[recorderFailed show];
     //[recorderFailed release];
 }
 //

@end

#endif //#ifdef TARGET_OS_IOS
