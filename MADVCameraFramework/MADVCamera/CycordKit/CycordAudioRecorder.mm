//
//  CycordAudioRecorder.m
//  ClumsyCopter
//
//  Created by FutureBoy on 12/24/14.
//
//
#ifdef TARGET_OS_IOS

#import "CycordAudioRecorder.h"

#define checkStatus(...) assert(0 == __VA_ARGS__)

#define kChannels 1

static CycordAudioRecorder* g_sharedInstance = nil;

@interface CycordAudioRecorder ()

- (ExtAudioFileRef) audioFileRef;

@end

static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    // TODO: Use inRefCon to access our interface object to do stuff
    CycordAudioRecorder* audioRecorder = (__bridge CycordAudioRecorder*)inRefCon;
    // Then, use inNumberFrames to figure out how much data is available, and make
    // that much space available in buffers in an AudioBufferList.
    
    //double timeInSeconds = inTimeStamp->mSampleTime / kSampleRate;
    //printf("\n%fs inBusNumber:%lu inNumberFrames:%lu", timeInSeconds, inBusNumber, inNumberFrames);
    
    AudioBufferList bufferList;
    UInt16 numSamples = inNumberFrames*kChannels;
    int16_t samples[numSamples];
    memset(&samples, 0, sizeof(samples));
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = samples;
    bufferList.mBuffers[0].mNumberChannels = kChannels;
    bufferList.mBuffers[0].mDataByteSize = numSamples*sizeof(int16_t);
    
    // Then:
    // Obtain recorded samples
    
    OSStatus status;
    status = AudioUnitRender(audioRecorder.audioUnit,
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             &bufferList);
    checkStatus(status);
    
    // Now, we have the samples we just read sitting in buffers in bufferList
//    int16_t maxValue = INT16_MIN, minValue = INT16_MAX;
//    int mean = 0;
//    int abssum = 0;
//    for (int i=0; i<numSamples; i++)
//    {
//        int16_t value = ((int16_t*)bufferList.mBuffers[0].mData)[i];
//        mean += value;
//        abssum += abs(value);
//        if (maxValue < value) maxValue = value;
//        if (minValue > value) minValue = value;
//    }
//    mean = (int)((float)mean / (float)numSamples);
//    printf("Mean = %d; AbsSum = %d\n", mean, abssum);
//    DoStuffWithTheRecordedAudio(bufferList);
    ExtAudioFileWriteAsync([audioRecorder audioFileRef], inNumberFrames, &bufferList);
    
    return noErr;
}

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
    return noErr;
}

@implementation CycordAudioRecorder

@synthesize audioUnit = _audioUnit;

+ (CycordAudioRecorder*) sharedInstance {
    if (nil == g_sharedInstance)
    {
        g_sharedInstance = [[CycordAudioRecorder alloc] init];
    }
    return g_sharedInstance;
}

- (ExtAudioFileRef) audioFileRef {
    return _audioFileRef;
}

- (void) dealloc {
    AudioComponentInstanceDispose(_audioUnit);
}

- (id) init {
    if (g_sharedInstance) return g_sharedInstance;
    
    self = [super init];
    if (self)
    {
#define kOutputBus 0
#define kInputBus 1
        
        // ...
        
        
        OSStatus status;
        
        // Describe audio component
        AudioComponentDescription desc;
        desc.componentType = kAudioUnitType_Output;
        desc.componentSubType = kAudioUnitSubType_RemoteIO;
        desc.componentFlags = 0;
        desc.componentFlagsMask = 0;
        desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        
        // Get component
        AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
        
        // Get audio units
        status = AudioComponentInstanceNew(inputComponent, &_audioUnit);
        checkStatus(status);
        
        // Enable IO for recording
        UInt32 flag = 1;
        status = AudioUnitSetProperty(_audioUnit,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Input,
                                      kInputBus,
                                      &flag,
                                      sizeof(flag));
        checkStatus(status);
        
        // Enable IO for playback
        status = AudioUnitSetProperty(_audioUnit,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Output,
                                      kOutputBus,
                                      &flag,
                                      sizeof(flag));
        checkStatus(status);
        
        // Describe format
        size_t bytesPerSample = 2;
//        size_t bytesPerSample = sizeof(AudioUnitSampleType);
        // Fill the application audio format struct's fields to define a linear PCM,
        //        stereo, noninterleaved stream at the hardware sample rate.
        _audioFormat.mFormatID          = kAudioFormatLinearPCM;
        _audioFormat.mFormatFlags       = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;//kAudioFormatFlagsAudioUnitCanonical;
        _audioFormat.mBytesPerPacket    = bytesPerSample;
        _audioFormat.mFramesPerPacket   = 1;
        _audioFormat.mBytesPerFrame     = bytesPerSample;
        _audioFormat.mChannelsPerFrame  = kChannels;                  // 1 indicates mono
        _audioFormat.mBitsPerChannel    = 8 * bytesPerSample;
        _audioFormat.mSampleRate        = 44100.00;
        
        // Apply format
        status = AudioUnitSetProperty(_audioUnit,
                                      kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Output,
                                      kInputBus,
                                      &_audioFormat,
                                      sizeof(_audioFormat));
        checkStatus(status);
        status = AudioUnitSetProperty(_audioUnit,
                                      kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Input,
                                      kOutputBus,
                                      &_audioFormat,
                                      sizeof(_audioFormat));
        checkStatus(status);
        
        
        // Set input callback
        AURenderCallbackStruct callbackStruct;
        callbackStruct.inputProc = recordingCallback;
        callbackStruct.inputProcRefCon = (__bridge void*)self;
        status = AudioUnitSetProperty(_audioUnit,
                                      kAudioOutputUnitProperty_SetInputCallback,
                                      kAudioUnitScope_Output,
                                      kOutputBus,
                                      &callbackStruct,
                                      sizeof(callbackStruct));
        checkStatus(status);
        
//        // Set output callback
//        callbackStruct.inputProc = playbackCallback;
//        callbackStruct.inputProcRefCon = (__bridge void*)self;
//        status = AudioUnitSetProperty(_audioUnit,
//                                      kAudioUnitProperty_SetRenderCallback,
//                                      kAudioUnitScope_Global,
//                                      kOutputBus,
//                                      &callbackStruct, 
//                                      sizeof(callbackStruct));
//        checkStatus(status);
        
        // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
        flag = 0;
        status = AudioUnitSetProperty(_audioUnit,
                                      kAudioUnitProperty_ShouldAllocateBuffer,
                                      kAudioUnitScope_Output, 
                                      kInputBus,
                                      &flag, 
                                      sizeof(flag));
        
        // TODO: Allocate our own buffers if we want
        
//        AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
//        [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord
//                         withOptions:AVAudioSessionCategoryOptionMixWithOthers
//                               error:NULL];
//        
//        [sessionInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];

        
        // Initialise
        status = AudioUnitInitialize(_audioUnit);
        checkStatus(status);

//        _aeController = [[AEAudioController alloc]
//                           initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription]
//                           inputEnabled:YES]; // don't forget to autorelease if you don't use ARC!
//        AEBlockAudioReceiverBlock block = ^(void                     *source,
//                      const AudioTimeStamp     *time,
//                      UInt32                    frames,
//                      AudioBufferList          *audio) {
//            // Do something with 'audio'
//            CycordAudioRecorder* audioRecorder = (CycordAudioRecorder*)source;
//            int16_t maxValue = INT16_MIN, minValue = INT16_MAX;
//            int mean = 0;
//            int abssum = 0;
//            int numSamples = audio->mBuffers[0].mDataByteSize / sizeof(int16_t);
//            int inNumberFrames = numSamples / kChannels;
//            for (int i=0; i<numSamples; i++)
//            {
//                int16_t value = ((int16_t*)audio->mBuffers[0].mData)[i];
//                mean += value;
//                abssum += abs(value);
//                if (maxValue < value) maxValue = value;
//                if (minValue > value) minValue = value;
//            }
//            mean = (int)((float)mean / (float)numSamples);
//            printf("Mean = %d; AbsSum = %d\n", mean, abssum);
//            //    DoStuffWithTheRecordedAudio(bufferList);
//            ExtAudioFileWriteAsync([audioRecorder audioFileRef], inNumberFrames, audio);
//        };
//        id<AEAudioReceiver> receiver = [AEBlockAudioReceiver audioReceiverWithBlock:block
//                                        ];
//        [_aeController addOutputReceiver:receiver];
        
        
    }
    return self;
}

- (void) startRecording {
    //Create an audio file for recording
    NSString *destinationFilePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"test.caf"];
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)destinationFilePath, kCFURLPOSIXPathStyle, false);
    OSStatus status = ExtAudioFileCreateWithURL(destinationURL, kAudioFileCAFType, &_audioFormat, NULL, kAudioFileFlags_EraseFile, &_audioFileRef);
    checkStatus(status);
    CFRelease(destinationURL);
    
    status = AudioOutputUnitStart(_audioUnit);
    checkStatus(status);
    
//    NSError *error = NULL;
//    BOOL result = [_aeController start:&error];
//    if ( !result ) {
//        // Report error
//    }
//    // Init recorder
//    _aeRecorder = [[AERecorder alloc] initWithAudioController:_aeController];
//    NSString *documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
//                                 objectAtIndex:0];
//    NSString *filePath = [documentsFolder stringByAppendingPathComponent:@"Recording.caf"];
//    // Start the recording process
//    if ( ![_aeRecorder beginRecordingToFileAtPath:filePath
//                                         fileType:kAudioFileCAFType
//                                            error:&error] ) {
//        // Report error
//        return;
//    }
//    // Receive both audio input and audio output. Note that if you're using
//    // AEPlaythroughChannel, mentioned above, you may not need to receive the input again.
////    [_aeController addInputReceiver:_aeRecorder];
//    [_aeController addOutputReceiver:_aeRecorder];
}

- (void) stopRecording {
    OSStatus status = AudioOutputUnitStop(_audioUnit);
    checkStatus(status);
    status = ExtAudioFileDispose(_audioFileRef);
    checkStatus(status);

////    [_aeController stop];
//    
//    [_aeController removeInputReceiver:_aeRecorder];
//    [_aeController removeOutputReceiver:_aeRecorder];
//    [_aeRecorder finishRecording];
////    [_aeRecorder release];
//    _aeRecorder = nil;
}

@end

#endif //#ifdef TARGET_OS_IOS
