//
//  CycordNewAudioRecorder.h
//  ClumsyCopter
//
//  Created by FutureBoy on 12/24/14.
//
//
#ifdef TARGET_OS_IOS

#ifndef ClumsyCopter_CycordNewAudioRecorder_h
#define ClumsyCopter_CycordNewAudioRecorder_h

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioUnit/AudioComponent.h>
#import <AudioToolBox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

//#import "AEAudioController.h"
//#import "AEBlockAudioReceiver.h"
//#import "AERecorder.h"

@interface CycordNewAudioRecorder : NSObject
{
    ExtAudioFileRef _audioFileRef;
    AudioStreamBasicDescription _audioFormat;
    AudioComponentInstance _audioUnit;
    
//    AEAudioController* _aeController;
//    AERecorder* _aeRecorder;
}

@property (nonatomic, assign) AudioComponentInstance audioUnit;

+ (CycordNewAudioRecorder*) sharedInstance;

- (void) setOutputAudioBaseName:(NSString*)audioBaseName;

- (void) startRecording;

- (void) stopRecording;

- (void) pauseRecording;

- (void) resumeRecording;

@end

#endif

#endif //#ifdef TARGET_OS_IOS
