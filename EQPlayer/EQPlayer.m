//
//  EQPlayer.m
//  EQPlayer
//
//  Created by Wildchild on 13/12/23.
//  Copyright (c) 2013年 Wildchild. All rights reserved.
//

#import "EQPlayer.h"

@implementation EQPlayer

// delegate for this class
@synthesize delegate = _delegate;

@synthesize graphSampleRate , displayNumberOfInputChannels , auEffectStreamFormat , interruptedDuringPlayback , playing ,stereoStreamFormat , loading = _loading , duration = _duration;

@synthesize mediaItem = _mediaItem , audioStruct = _audioStruct ;

static OSStatus inputRenderCallback (void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp,  UInt32  inBusNumber,   UInt32  inNumberFrames,  AudioBufferList *ioData );

#pragma mark Mixer input bus 0 & 1 render callback (loops buffers)

//  Callback for guitar and beats loops - mixer channels 0 & 1
//
//  original comments from Apple:

//    This callback is invoked each time a Multichannel Mixer unit input bus requires more audio
//        samples. In this app, the mixer unit has two input buses. Each of them has its own render
//        callback function and its own interleaved audio data buffer to read from.
//
//    This callback is written for an inRefCon parameter that can point to two noninterleaved
//        buffers (for a stereo sound) or to one mono buffer (for a mono sound).
//
//    Audio unit input render callbacks are invoked on a realtime priority thread (the highest
//    priority on the system). To work well, to not make the system unresponsive, and to avoid
//    audio artifacts, a render callback must not:
//
//        * allocate memory
//        * access the file system or a network connection
//        * take locks
//        * waste time
//
//    In addition, it's usually best to avoid sending Objective-C messages in a render callback.
//
//    Declared as AURenderCallback in AudioUnit/AUComponent.h. See Audio Unit Component Services Reference.
static OSStatus inputRenderCallback (
                                     
                                     void                        *inRefCon,      // A pointer to a struct containing the complete audio data
                                     //    to play, as well as state information such as the
                                     //    first sample to play on this invocation of the callback.
                                     AudioUnitRenderActionFlags  *ioActionFlags, // Unused here. When generating audio, use ioActionFlags to indicate silence
                                     //    between sounds; for silence, also memset the ioData buffers to 0.
                                     const AudioTimeStamp        *inTimeStamp,   // Unused here.
                                     UInt32                      inBusNumber,    // The mixer unit input bus that is requesting some new
                                     //        frames of audio data to play.
                                     UInt32                      inNumberFrames, // The number of frames of audio to provide to the buffer(s)
                                     //        pointed to by the ioData parameter.
                                     AudioBufferList             *ioData         // On output, the audio data to play. The callback's primary
                                     //        responsibility is to fill the buffer(s) in the
                                     //        AudioBufferList.
                                     )
{
    
    EQPlayer *player = (__bridge EQPlayer*) inRefCon;
    soundStructPtr    soundStructPointerArray   = player.audioStruct;
    UInt64            frameTotalForSound        = soundStructPointerArray->frameCount;
    BOOL              isStereo                  = soundStructPointerArray->isStereo;
    

                                         
    // Declare variables to point to the audio buffers. Their data type must match the buffer data type.
    AudioUnitSampleType *dataInLeft;
    AudioUnitSampleType *dataInRight;
    

    
    dataInLeft                 = soundStructPointerArray->audioDataLeft;
    if (isStereo) dataInRight  = soundStructPointerArray->audioDataRight;
    
    // Establish pointers to the memory into which the audio from the buffers should go. This reflects
    //    the fact that each Multichannel Mixer unit input bus has two channels, as specified by this app's
    //    graphStreamFormat variable.
    AudioUnitSampleType *outSamplesChannelLeft;
    AudioUnitSampleType *outSamplesChannelRight;
    
    outSamplesChannelLeft                 = (AudioUnitSampleType *) ioData->mBuffers[0].mData;
    if (isStereo) outSamplesChannelRight  = (AudioUnitSampleType *) ioData->mBuffers[1].mData;
    
    // Get the sample number, as an index into the sound stored in memory,
    //    to start reading data from.
    UInt32 sampleNumber = soundStructPointerArray->sampleNumber;

    
    
    
    //printf("busnumber %i sampleNumber %i inNumberFrames %i frameTotal %i\n",inBusNumber,sampleNumber,inNumberFrames,frameTotalForSound);
    if (sampleNumber == 0 ) {
        //sampleNumber = frameTotalForSound / 10 * 9;
        //printf("go back to frame 0\n");
    }


                                         
    // check if the file is loading into memory.
    // if it's loding, assign zero to frame and return
    if (player.isLoading){
        sampleNumber = 0;
        for (UInt32 frameNumber = 0 ; frameNumber < inNumberFrames ; ++frameNumber , sampleNumber++){
            outSamplesChannelLeft[frameNumber]                 = 0;
            if (isStereo) outSamplesChannelRight[frameNumber]  = 0;
            
        }
        return noErr;
    }
                                         

    
    // update current song time, send time to delegate
    if( player.delegate != nil && [player.delegate conformsToProtocol:@protocol(EQPlayerDelegate)]){

        if ( [player.delegate respondsToSelector:@selector(updateCurrentTime:)] ){
            float currentTime = ( (float)sampleNumber/frameTotalForSound ) * player.duration;
            [player.delegate updateCurrentTime:currentTime];
        }
    
    }
    


    // Fill the buffer or buffers pointed at by *ioData with the requested number of samples
    //    of audio from the sound stored in memory.
    for (UInt32 frameNumber = 0 ; frameNumber < inNumberFrames ; ++frameNumber , sampleNumber++) {

        
        // After reaching the end of the sound stored in memory--that is, after
        //    (frameTotalForSound / inNumberFrames) invocations of this callback--loop back to the
        //    start of the sound so playback resumes from there.
        if (sampleNumber >= frameTotalForSound) {
            sampleNumber = 0;
            //printf("go back to frame 0\n");
        }
        
        outSamplesChannelLeft[frameNumber]                 = dataInLeft[sampleNumber];
        if (isStereo) outSamplesChannelRight[frameNumber]  = dataInRight[sampleNumber];
        
        

    }
    
    // Update the stored sample number so, the next time this callback is invoked, playback resumes 
    //    at the correct spot.
    soundStructPointerArray->sampleNumber = sampleNumber;


    
    return noErr;
}



#pragma mark -
#pragma mark Initialize

//////////////////////////////////
// Get the app ready for playback.
- (id) init {
    
    
    self = [super init];
    
    if (!self) return nil;
    
    self.interruptedDuringPlayback = NO;
    loading = false;
    [self setupAudioSession];
    
    //[self obtainSoundFileURLs];
    [self setupStereoStreamFormat];
   
	[self readAudioFilesIntoMemory];
    
    [self configureAndInitializeAudioProcessingGraph];
    
    
	
	return self;
}

#pragma mark -
#pragma mark Audio processing graph setup

// This method does the audio processing graph:


- (void) configureAndInitializeAudioProcessingGraph {
    
    NSLog (@"Configuring and then initializing audio processing graph");
    OSStatus result = noErr;
    
//    UInt16 busNumber;           // mixer input bus number (starts with 0)
    
    // instantiate and setup audio processing graph by setting component descriptions and adding nodes
    
    
    [self setupAudioProcessingGraph];
    
	
    
    ///////////////////////////////////////////////////////////////////
    //............................................................................
    // Open the audio processing graph
    
    // Following this call, the audio units are instantiated but not initialized
    //    (no resource allocation occurs and the audio units are not in a state to
    //    process audio).
    result = AUGraphOpen (processingGraph);
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphOpen" withStatus: result]; return;}
    
    
    //
    //  at this point we set all the audio units individually
    //
    //  - get unit instance from audio graph node
    //  - set bus io params
    //  - set other params
    //  - set ASBD's
    //
    
    
    //............................................................................
    // Obtain the I/O unit instance from the corresponding node.
	result =	AUGraphNodeInfo (
								 processingGraph,
								 iONode,
								 NULL,
								 &ioUnit
								 );
	
	if (result) {[self printErrorMessage: @"AUGraphNodeInfo - I/O unit" withStatus: result]; return;}
    
    
    /////////////////////////////
    // I/O Unit Setup (input bus)
	
	
    //////////////////////////////////////////////////////////////
    // Obtain the mixer unit instance from its corresponding node.
    
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 mixerNode,
                                 NULL,
                                 &mixerUnit
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo" withStatus: result]; return;}
    
    /////////////////////////////////
    // Multichannel Mixer unit Setup
    
    
    
    UInt32 busCount   = 6;    // bus count for mixer unit input
    UInt32 guitarBus  = 0;    // mixer unit bus 0 will be stereo and will take the guitar sound
	UInt32 micBus	  = 2;    // mixer unit bus 2 will be mono and will take the microphone input
    //    UInt32 samplerBus   = 4;
    //    UInt32 filePlayerBus = 5;
    
    NSLog (@"Setting mixer unit input bus count to: %lu", busCount);
    result = AudioUnitSetProperty (
                                   mixerUnit,
                                   kAudioUnitProperty_ElementCount,
                                   kAudioUnitScope_Input,
                                   0,
                                   &busCount,
                                   sizeof (busCount)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit bus count)" withStatus: result]; return;}
    
    
    NSLog (@"Setting kAudioUnitProperty_MaximumFramesPerSlice for mixer unit global scope");
    // Increase the maximum frames per slice allows the mixer unit to accommodate the
    //    larger slice size used when the screen is locked.
    UInt32 maximumFramesPerSlice = 4096;
    
    result = AudioUnitSetProperty (
                                   mixerUnit,
                                   kAudioUnitProperty_MaximumFramesPerSlice,
                                   kAudioUnitScope_Global,
                                   0,
                                   &maximumFramesPerSlice,
                                   sizeof (maximumFramesPerSlice)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit input stream format)" withStatus: result]; return;}
    
    
    UInt16 fileCount = 1;	// number of 'file' busses to init on the mixer
    // Attach the input render callback and context to each input bus
	// this is for the two file players
	// subtract 2 from bus count because we're not including mic & synth bus for now...  tz
    for (UInt16 busNumber = 0; busNumber < fileCount; ++busNumber) {
        /*
        // Setup the structure that contains the input render callback
        AURenderCallbackStruct inputCallbackStruct;
        inputCallbackStruct.inputProc        = &inputRenderCallback;
        inputCallbackStruct.inputProcRefCon  = _soundStruct;
        */
        
        // Setup the structure that contains the input render callback
        AURenderCallbackStruct inputCallbackStruct;
        inputCallbackStruct.inputProc        = &inputRenderCallback;
        inputCallbackStruct.inputProcRefCon  = (__bridge void *)(self);

        
        NSLog (@"Registering the render callback with mixer unit input bus %u", busNumber);
        // Set a callback for the specified node's specified input
        result = AUGraphSetNodeInputCallback (
                                              processingGraph,
                                              mixerNode,
                                              busNumber,
                                              &inputCallbackStruct
                                              );
        
        if (noErr != result) {[self printErrorMessage: @"AUGraphSetNodeInputCallback" withStatus: result]; return;}
    }
    
    
    ///////////////////////////////////////////////
    // set all the ASBD's for the mixer input buses
    //
    // each mixer input bus needs an asbd that matches the asbd of the output bus its pulling data from
    //
    // In the case of the synth bus, which generates its own data, the asbd can be anything reasonable that
    // works on the input bus.
    //
    // The asbd of the mixer input bus does not have to match the asbd of the mixer output bus.
    // In that sense, the mixer acts as a format converter. But I don't know to what extent this will work.
    // It does sample format conversions, but I don't know that it can do sample rate conversions.
    
    
    NSLog (@"Setting stereo stream format for mixer unit 0 (stereo guitar loop) input bus");
    result = AudioUnitSetProperty (
                                   mixerUnit,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   guitarBus,
                                   &stereoStreamFormat,
                                   sizeof (stereoStreamFormat)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit bus 0 (stereo guitar loop) stream format)" withStatus: result];return;}
    


 
    if(displayNumberOfInputChannels > 1) {  // do the stereo asbd
        NSLog (@"Setting stereoStreamFormat for mixer unit bus 2 mic/lineIn input");
        result = AudioUnitSetProperty (
                                       mixerUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       micBus,
                                       &stereoStreamFormat,
                                       sizeof (stereoStreamFormat)
                                       );
        
        if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit bus 2 mic/line stream format stereo)" withStatus: result];return;}
        
    }
	
	
	
    // ok this is where things change up a little because we're using audio unit effects. otherwise we
    // would just set the sample rate on the mixer output scope and be done...
    
    // we're going to need to set the mixer output scope to match
    // the effects input scope asbd - but had to move it up in the code because
    // the effects asbd not defined yet
    
    // we'll postpone any settings for the sampler, and fileplayer until we take care of setting up the
    // effects unit asbd in the next step.
    
    // but if you have no effects after the mixer, just uncomment the next little section here...  and life will be easier
    
    
    
    /*
     
     NSLog (@"Setting sample rate for mixer unit output scope");
     // Set the mixer unit's output sample rate format. This is the only aspect of the output stream
     //    format that must be explicitly set.
     result = AudioUnitSetProperty (
     mixerUnit,
     kAudioUnitProperty_SampleRate,
     kAudioUnitScope_Output,
     0,
     &graphSampleRate,
     sizeof (graphSampleRate)
     );
     
     if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit output stream format)" withStatus: result]; return;}
     
     */
    
    //
    
    
    
    
    
 	
    /////////////////////////////////////////////////////////////////////////
    //
    // Obtain the au effect unit instance from its corresponding node.
    
    NSLog (@"Getting effect Node Info...");
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 auEffectNode,
                                 NULL,
                                 &auEffectUnit
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo - auEffect" withStatus: result]; return;}
    
    // setup ASBD for effects unit
    
    // This section is very confusing but important to getting things working
    //
    // The output of the mixer is now feeding the input of an effects au
    //
    // if the effects au wasn't there, you would just set the sample rate on the output scope of the mixer
    // as is explained in the Apple docs, and be done with it. Essesntially letting the system handle the
    // rest of the asbd setup for the mixer output
    //
    // But... in our setup, since the mixer ouput is not at the end of the chain, we set the sample rate on the
    // effects output scope instead.
    
    // and for the effects unit input scope... we need to obtain the default asbd from the the effects unit - this is
    // where things are weird because the default turns out to be 32bit float packed 2 channel, non interleaved
    //
    // and we use the asbd we obtain (auEffectStreamFormat) to apply to the output scope of the mixer. and any
    // other effects au's that we set up.
    //
    // The critical thing here is that you need to 1)set the audio unit description for auEffectUnit, 2)add it to the audio graph, then
    // 3) get the instance of the unit from its node in the audio graph (see just prior to this comment)
    // at that point the asbd has been initialized to the proper default. If you try to do the AudioUnitGetProperty before
    // that point you'll get an error -50
    //
    // As an alternative you could manually set the effects unit asbd to 32bit float, packed 2 channel, non interleaved -
    // ahead of time, like we did with the other asbd's.
    //
    
    
    // get default asbd properties of au effect unit,
    // this sets up the auEffectStreamFormat asbd
    
	UInt32 asbdSize = sizeof (auEffectStreamFormat);
	memset (&auEffectStreamFormat, 0, sizeof (auEffectStreamFormat ));
	result = AudioUnitGetProperty(auEffectUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &auEffectStreamFormat,
                                  &asbdSize);
			   
    if (noErr != result) {[self printErrorMessage: @"Couldn't get aueffectunit ASBD" withStatus: result]; return;}
    
    // debug print to find out what's actually in this asbd
    
    NSLog (@"The stream format for the effects unit:");
    [self printASBD: auEffectStreamFormat];
    
    auEffectStreamFormat.mSampleRate = graphSampleRate;      // make sure the sample rate is correct
    
    // now set this asbd to the effect unit input scope
    // note: if the asbd sample rate is already equal to graphsamplerate then this next statement is not
    // necessary because we derived the asbd from what it was already set to.
    
    
	result = AudioUnitSetProperty(auEffectUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &auEffectStreamFormat,
                                  sizeof(auEffectStreamFormat));
    
    if (noErr != result) {[self printErrorMessage: @"Couldn't set ASBD on effect unit input" withStatus: result]; return;}
    
    
    // set the sample rate on the effect unit output scope...
    //
    // Here
    // i'm just doing for the effect the same thing that worked for the
    // mixer output when there was no effect
    //
    
    NSLog (@"Setting sample rate for au effect unit output scope");
    // Set the mixer unit's output sample rate format. This is the only aspect of the output stream
    //    format that must be explicitly set.
    result = AudioUnitSetProperty (
                                   auEffectUnit,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Output,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set au effect unit output stream format)" withStatus: result]; return;}
    
    
    
    // and finally... set our new effect stream format on the output scope of the mixer.
    // app will blow up at runtime without this
    
    
    result = AudioUnitSetProperty(mixerUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  0,
                                  &auEffectStreamFormat,
                                  sizeof(auEffectStreamFormat));

    
    
    if (noErr != result) {[self printErrorMessage: @"Couldn't set ASBD on mixer output"withStatus: result]; return;}


 
    // Connect the nodes of the audio processing graph
    
    
    [self connectAudioProcessingGraph];
    
    
    
    
    //............................................................................
    // Initialize audio processing graph
    
    // Diagnostic code
    // Call CAShow if you want to look at the state of the audio processing
    //    graph.
    NSLog (@"Audio processing graph state immediately before initializing it:");
    CAShow (processingGraph);
    
    NSLog (@"Initializing the audio processing graph");
    // Initialize the audio processing graph, configure audio data stream formats for
    //    each input and output, and validate the connections between audio units.
    result = AUGraphInitialize (processingGraph);
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphInitialize" withStatus: result]; return;}
    
    ////////////////////////////////////////////////
    // post-init configs
    //
    // set fx parameters, and various initial settings for things
    
	
    
    

    // Frequency bands
    NSArray *frequency = @[ @32.0f , @64.0f, @125.0f, @250.0f, @500.0f, @1000.0f, @2000.0f, @4000.0f, @8000.0f, @16000.0f ];
    eqFrequencies = [[NSMutableArray alloc] initWithArray:frequency];
    UInt32 noBands = [eqFrequencies count];
    
    
    // Set the number of bands first
    result = AudioUnitSetProperty(auEffectUnit,
                                  kAUNBandEQProperty_NumberOfBands,
                                  kAudioUnitScope_Global,
                                  0,
                                  &noBands,
                                  sizeof(noBands));

    if (noErr != result) {[self printErrorMessage: @"set NumberOfBands Property" withStatus: result]; return;}
    
    // Set the frequencies
    for (NSUInteger i=0; i<noBands; i++) {
        result = AudioUnitSetParameter(auEffectUnit,
                                       kAUNBandEQParam_Frequency+i,
                                       kAudioUnitScope_Global,
                                       0,
                                       (AudioUnitParameterValue)[[eqFrequencies objectAtIndex:i] floatValue],
                                       0);
        
        if (noErr != result) {[self printErrorMessage: @"set NumberOfBands Property" withStatus: result]; return;}
        
    }
    
    // By default the equalizer isn't enabled! You need to set bypass
    // to zero so the equalizer actually does something
    // Set the bypass
    for (NSUInteger i=0; i<noBands; i++) {
        result = AudioUnitSetParameter(auEffectUnit,
                                       kAUNBandEQParam_BypassBand+i,
                                       kAudioUnitScope_Global,
                                       0,
                                       (AudioUnitParameterValue)0,
                                       0);
        if (noErr != result) {[self printErrorMessage: @"set NumberOfBands Property" withStatus: result]; return;}
    }
    

    // wow - this completes all the audiograph setup and initialization
}



- (void) setupAudioSession {
    
    // some debugging to find out about ourselves
    
#if !CA_PREFER_FIXED_POINT
	NSLog(@"not fixed point");
#else
	NSLog(@"fixed point");
#endif
	
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        NSLog(@"running iphone or ipod touch...\n");
    }
	
	NSString *deviceType = [UIDevice currentDevice].model;
    NSLog(@"device type is: %@", deviceType);
    
    
    //    NSString *deviceUniqueId = [UIDevice currentDevice ].uniqueIdentifier;
    //    NSLog(@"device Id is: %@", deviceUniqueId);
    
    
    NSString *operatingSystemVersion = [UIDevice currentDevice].systemVersion;
    NSLog(@"OS version is: %@", operatingSystemVersion);
    
    //////////////////////////
    // setup the session
	
    mySession = [AVAudioSession sharedInstance];
    
    // Specify that this object is the delegate of the audio session, so that
    //    this object's endInterruption method will be invoked when needed.
    
    // this method deprecated in ios6.0
    // replaced with sharedInstance 'notification'
    //
    // [mySession setDelegate: self];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    // tz change to playback
	// Assign the Playback category to the audio session.
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback
                     error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        NSLog (@"Error setting audio session category.");
        
    }
	
    
    
    
    // Request the desired hardware sample rate.
    self.graphSampleRate = 44100.0;    // Hertz
    //self.graphSampleRate = 22050.0;    // Hertz

    // deprecated in ios 6.0
    // [mySession setPreferredHardwareSampleRate: graphSampleRate
    //                                    error: &audioSessionError];
    
    [mySession setPreferredSampleRate: graphSampleRate
                                error: &audioSessionError];
    
    
    if (audioSessionError != nil) {
        NSLog (@"Error setting preferred hardware sample rate.");
        
    }
	
	// refer to IOS developer library : Audio Session Programming Guide
	// set preferred buffer duration to 1024 using
	//  try ((buffer size + 1) / sample rate) - due to little arm6 floating point bug?
	// doesn't seem to help - the duration seems to get set to whatever the system wants...
	
//	Float32 currentBufferDuration =  (Float32) (1024.0 / self.graphSampleRate);
    Float32 currentBufferDuration =  (Float32) (1024.0 / self.graphSampleRate);
	UInt32 sss = sizeof(currentBufferDuration);
	
	AudioSessionSetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, sizeof(currentBufferDuration), &currentBufferDuration);
	NSLog(@"setting buffer duration to: %f", currentBufferDuration);
	
	
    
	// note: this is where ipod touch (w/o mic) erred out when mic (ie earbud thing) was not plugged - before we added
	// the code above to check for mic available
    // Activate the audio session
    [mySession setActive: YES
                   error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        NSLog (@"Error activating audio session during initial setup.");
        
    }
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
    
    // deprecated with ios6.0
    // self.graphSampleRate = [mySession currentHardwareSampleRate];
	
    
    self.graphSampleRate = [mySession sampleRate];
    NSLog(@"Actual sample rate is: %f", self.graphSampleRate );
	
	// find out the current buffer duration
	// to calculate duration use: buffersize / sample rate, eg., 512 / 44100 = .012
	
	// Obtain the actual buffer duration - this may be necessary to get fft stuff working properly in passthru
	AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, &sss, &currentBufferDuration);
	NSLog(@"Actual current hardware io buffer duration: %f ", currentBufferDuration );
	
	
    /*
    // Register the audio route change listener callback function with the audio session.
    AudioSessionAddPropertyListener (
                                     kAudioSessionProperty_AudioRouteChange,
                                     audioRouteChangeListenerCallback,
                                     self
                                     );
    
    */
    
    // find out how many input channels are available
    
    // deprecated with ios6.0
    // NSInteger numberOfChannels = [mySession currentHardwareInputNumberOfChannels];
    
    NSInteger numberOfChannels = [mySession inputNumberOfChannels];
    
    NSLog(@"number of channels: %d", numberOfChannels );
    displayNumberOfInputChannels = numberOfChannels;    // set instance variable for display
    
    return ;   // everything ok
    
}


// setup asbd stream formats

- (void) setupStereoStreamFormat {
    
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    //    units. This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    //     NSLog (@"size of AudioUnitSampleType: %lu", bytesPerSample);
    
    // Fill the application audio format struct's fields to define a linear PCM,
    //        stereo, noninterleaved stream at the hardware sample rate.
    stereoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    stereoStreamFormat.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    stereoStreamFormat.mBytesPerPacket    = bytesPerSample;
    stereoStreamFormat.mFramesPerPacket   = 1;
    stereoStreamFormat.mBytesPerFrame     = bytesPerSample;
    stereoStreamFormat.mChannelsPerFrame  = 2;                    // 2 indicates stereo
    stereoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    stereoStreamFormat.mSampleRate        = graphSampleRate;
    
    
    NSLog (@"The stereo stream format:");
    [self printASBD: stereoStreamFormat];
}

////////////////////////////////////////////////////////////////////////////////////////////
// create and setup audio processing graph by setting component descriptions and adding nodes

- (void) setupAudioProcessingGraph {
    
    OSStatus result = noErr;
    
    
    // Create a new audio processing graph.
    result = NewAUGraph (&processingGraph);
    
    if (noErr != result) {[self printErrorMessage: @"NewAUGraph" withStatus: result]; return;}
    
    
    //............................................................................
    // Specify the audio unit component descriptions for the audio units to be
    //    added to the graph.
    
    // remote I/O unit connects both to mic/lineIn and to speaker
    AudioComponentDescription iOUnitDescription;
    iOUnitDescription.componentType          = kAudioUnitType_Output;
    iOUnitDescription.componentSubType       = kAudioUnitSubType_RemoteIO;
    iOUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    iOUnitDescription.componentFlags         = 0;
    iOUnitDescription.componentFlagsMask     = 0;
    
    
    
    // Multichannel mixer unit
    AudioComponentDescription MixerUnitDescription;
    MixerUnitDescription.componentType          = kAudioUnitType_Mixer;
    MixerUnitDescription.componentSubType       = kAudioUnitSubType_MultiChannelMixer;
    MixerUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    MixerUnitDescription.componentFlags         = 0;
    MixerUnitDescription.componentFlagsMask     = 0;
    
    // au unit effect for mixer output - NBandEQ
    
    AudioComponentDescription auEffectUnitDescription;
    auEffectUnitDescription.componentType = kAudioUnitType_Effect;
    auEffectUnitDescription.componentSubType = kAudioUnitSubType_NBandEQ;
    auEffectUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    
    ///////////////////////////////////////////////
    // Add the nodes to the audio processing graph
    ///////////////////////////////////////////////
    
    
    NSLog (@"Adding nodes to audio processing graph");
    
    
    
    // io unit
    
    result =    AUGraphAddNode (
                                processingGraph,
                                &iOUnitDescription,
                                &iONode);
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNewNode failed for I/O unit" withStatus: result]; return;}
    
	
    
    // mixer unit
    
    result =    AUGraphAddNode (
                                processingGraph,
                                &MixerUnitDescription,
                                &mixerNode
                                );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNewNode failed for Mixer unit" withStatus: result]; return;}
    
    // au effect unit
    
    result =    AUGraphAddNode(
                              processingGraph,
                              &auEffectUnitDescription,
                              &auEffectNode);
    

    if (noErr != result) {[self printErrorMessage: @"AUGraphNewNode failed for Effect unit" withStatus: result]; return;}
    
    
}

- (void) connectAudioProcessingGraph {
    
    OSStatus result = noErr;
    
    //............................................................................
    // Connect the nodes of the audio processing graph
    
    // note: you only need to connect nodes which don't have assigned callbacks.
    // So for example, the mic/lineIn channel doesn't need to be connected.
    
	
	NSLog (@"Connecting nodes in audio processing graph");
    
    
    /*
     // this call should only be used if you don't need to process the mic input with a callback
     
     // Connect the output of the input bus of the I/O unit to the Multichannel Mixer unit input.
     result =	AUGraphConnectNodeInput (
     processingGraph,
     iONode,				// source node
     1,					// source node bus number
     mixerNode,			// destination node
     micBus					// destintaion node bus number
     );
     
     if (result) {[self printErrorMessage: @"AUGraphConnectNodeInput - I/O unit to Multichannel Mixer unit" withStatus: result]; return;}
     
     
     */
    
    
    NSLog (@"Connecting the mixer output to the input of mixer effect element");
    
    
    
    result = AUGraphConnectNodeInput (
                                      processingGraph,
                                      mixerNode,         // source node
                                      0,                 // source node output bus number
                                      auEffectNode,            // destination node
                                      0                  // desintation node input bus number
                                      );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphConnectNodeInput" withStatus: result]; return;}
    
    
    
    
    NSLog (@"Connecting the effect output to the input of the I/O unit output element");
    
    
    
    result = AUGraphConnectNodeInput (
                                      processingGraph,
                                      auEffectNode,         // source node
                                      0,                 // source node output bus number
                                      iONode,            // destination node
                                      0                  // desintation node input bus number
                                      );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphConnectNodeInput" withStatus: result]; return;}
    
    
}


//////////////////
// read loop files

#pragma mark -
#pragma mark Read audio files into memory

- (void) readAudioFilesIntoMemory {
    
    //NSURL *mp3file   = [[NSBundle mainBundle] URLForResource: @"30sec" withExtension: @"au"];

    NSURL *mp3file   = [[NSBundle mainBundle] URLForResource: @"sol" withExtension: @"mp3"];
    
    if ( audioFile != nil ) {
        mp3file = audioFile;
    }else{
        NSLog(@"First reading file into memory");
    }
    
    CFURLRef sourceURL = (__bridge CFURLRef)mp3file;
    
    
    
    NSLog(@"readAudioFilesIntoMemory - file ");

    // Instantiate an extended audio file object.
    ExtAudioFileRef audioFileObject = 0;
        
    // Open an audio file and associate it with the extended audio file object.
    OSStatus result = ExtAudioFileOpenURL (sourceURL, &audioFileObject);
        
    if (noErr != result || NULL == audioFileObject) {[self printErrorMessage: @"ExtAudioFileOpenURL" withStatus: result]; return;}
    
    
    SInt64 framesInThisFile;
    UInt32 propertySize = sizeof(framesInThisFile);
    ExtAudioFileGetProperty(audioFileObject, kExtAudioFileProperty_FileLengthFrames, &propertySize, &framesInThisFile);
    
    AudioStreamBasicDescription fileStreamFormat;
    propertySize = sizeof(AudioStreamBasicDescription);
    ExtAudioFileGetProperty(audioFileObject, kExtAudioFileProperty_FileDataFormat, &propertySize, &fileStreamFormat);
    
    _duration = (float)framesInThisFile/(float)fileStreamFormat.mSampleRate;
    
    NSLog(@"Duration %f, total frame %d",(float)framesInThisFile/(float)fileStreamFormat.mSampleRate,framesInThisFile);
    NSLog(@"SampleRate %f",(float)fileStreamFormat.mSampleRate);
    
    
    // Get the audio file's length in frames.
    UInt64 totalFramesInFile = 0;
    UInt32 frameLengthPropertySize = sizeof (totalFramesInFile);
        
    result =    ExtAudioFileGetProperty (
                                         audioFileObject,
                                         kExtAudioFileProperty_FileLengthFrames,
                                         &frameLengthPropertySize,
                                         &totalFramesInFile
                                         );
        

    if (noErr != result) {[self printErrorMessage: @"ExtAudioFileGetProperty (audio file length in frames)" withStatus: result]; return;}
        
    
    // Assign the frame count to the soundStructArray instance variable
    _soundStruct =  malloc(sizeof(soundStruct));
    _audioStruct = _soundStruct;
    _soundStruct->frameCount = totalFramesInFile;
        
    // Get the audio file's number of channels.
    AudioStreamBasicDescription fileAudioFormat = {0};
    UInt32 formatPropertySize = sizeof (fileAudioFormat);
        
    result =    ExtAudioFileGetProperty (
                                         audioFileObject,
                                         kExtAudioFileProperty_FileDataFormat,
                                         &formatPropertySize,
                                         &fileAudioFormat
                                        );
    
    if (noErr != result) {[self printErrorMessage: @"ExtAudioFileGetProperty (file audio format)" withStatus: result]; return;}
        
    UInt32 channelCount = fileAudioFormat.mChannelsPerFrame;
    
        
    // Allocate memory in the soundStructArray instance variable to hold the left channel,
    //    or mono, audio data
    _soundStruct->audioDataLeft = (AudioUnitSampleType *) calloc (totalFramesInFile, sizeof (AudioUnitSampleType));
        
    AudioStreamBasicDescription importFormat = {0};
    if (2 == channelCount) {
            
        _soundStruct->isStereo = YES;
        // Sound is stereo, so allocate memory in the soundStructArray instance variable to
        //    hold the right channel audio data
        _soundStruct->audioDataRight =
        (AudioUnitSampleType *) calloc (totalFramesInFile, sizeof (AudioUnitSampleType));
        importFormat = stereoStreamFormat;
    } else if (1 == channelCount) {
        
        // this should be NO
        _soundStruct->isStereo = NO;


        NSLog(@"Mono happeneds");
        exit(1);
            
    } else {
        NSLog (@"*** WARNING: File format not supported - wrong number of channels");
        ExtAudioFileDispose (audioFileObject);
        return;
    }
        
        // Assign the appropriate mixer input bus stream data format to the extended audio
        //        file object. This is the format used for the audio data placed into the audio
        //        buffer in the SoundStruct data structure, which is in turn used in the
        //        inputRenderCallback callback function.
        
        result =    ExtAudioFileSetProperty (
                                             audioFileObject,
                                             kExtAudioFileProperty_ClientDataFormat,
                                             sizeof (importFormat),
                                             &importFormat
                                             );
        
        if (noErr != result) {[self printErrorMessage: @"ExtAudioFileSetProperty (client data format)" withStatus: result]; return;}
        
        // Set up an AudioBufferList struct, which has two roles:
        //
        //        1. It gives the ExtAudioFileRead function the configuration it
        //            needs to correctly provide the data to the buffer.
        //
        //        2. It points to the soundStructArray[audioFile].audioDataLeft buffer, so
        //            that audio data obtained from disk using the ExtAudioFileRead function
        //            goes to that buffer
        
        // Allocate memory for the buffer list struct according to the number of
        //    channels it represents.
        AudioBufferList *bufferList;
        
        bufferList = (AudioBufferList *) malloc (
                                                 sizeof (AudioBufferList) + sizeof (AudioBuffer) * (channelCount - 1)
                                                 );
        
        if (NULL == bufferList) {NSLog (@"*** malloc failure for allocating bufferList memory"); return;}
        
        // initialize the mNumberBuffers member
        bufferList->mNumberBuffers = channelCount;
        
        // initialize the mBuffers member to 0
        AudioBuffer emptyBuffer = {0};
        size_t arrayIndex;
        for (arrayIndex = 0; arrayIndex < channelCount; arrayIndex++) {
            bufferList->mBuffers[arrayIndex] = emptyBuffer;
        }
        
        // set up the AudioBuffer structs in the buffer list
        bufferList->mBuffers[0].mNumberChannels  = 1;
        bufferList->mBuffers[0].mDataByteSize    = totalFramesInFile * sizeof (AudioUnitSampleType);
        bufferList->mBuffers[0].mData            = _soundStruct->audioDataLeft;
        
        if (2 == channelCount) {
            bufferList->mBuffers[1].mNumberChannels  = 1;
            bufferList->mBuffers[1].mDataByteSize    = totalFramesInFile * sizeof (AudioUnitSampleType);
            bufferList->mBuffers[1].mData            = _soundStruct->audioDataRight;
        }
        
        // Perform a synchronous, sequential read of the audio data out of the file and
        //    into the soundStructArray[audioFile].audioDataLeft and (if stereo) .audioDataRight members.
        UInt32 numberOfPacketsToRead = (UInt32) totalFramesInFile;
        
        result = ExtAudioFileRead (
                                   audioFileObject,
                                   &numberOfPacketsToRead,
                                   bufferList
                                   );
        
        free (bufferList);
        
        if (noErr != result) {
            
            [self printErrorMessage: @"ExtAudioFileRead failure - " withStatus: result];
            
            // If reading from the file failed, then free the memory for the sound buffer.
            free (_soundStruct->audioDataLeft);
            _soundStruct->audioDataLeft = 0;
            
            if (2 == channelCount) {
                free (_soundStruct->audioDataRight);
                _soundStruct->audioDataRight = 0;
            }
            
            ExtAudioFileDispose (audioFileObject);            
            return;
        }
        
        NSLog (@"Finished reading file into memory");
        
        // Set the sample index to zero, so that playback starts at the 
        //    beginning of the sound.
        _soundStruct->sampleNumber = 0;
        _loading = false;
    
        // Dispose of the extended audio file object, which also
        //    closes the associated file.
        ExtAudioFileDispose (audioFileObject);
    
}



#pragma mark -
#pragma mark Playback control

/////////////////
// Start playback
//
//  This is the master on/off switch that starts the processing graph
//
- (void) startAUGraph  {
    
    NSLog (@"Starting audio processing graph");
    OSStatus result = AUGraphStart (processingGraph);
    if (noErr != result) {[self printErrorMessage: @"AUGraphStart" withStatus: result]; return;}
    
    self.playing = YES;
}

////////////////
// Stop playback
- (void) stopAUGraph {
    
    NSLog (@"Stopping audio processing graph");
    Boolean isRunning = false;
    OSStatus result = AUGraphIsRunning (processingGraph, &isRunning);
    if (noErr != result) {[self printErrorMessage: @"AUGraphIsRunning" withStatus: result]; return;}
    
    if (isRunning) {
        
        result = AUGraphStop (processingGraph);
        if (noErr != result) {[self printErrorMessage: @"AUGraphStop" withStatus: result]; return;}
        self.playing = NO;
    }
}

#pragma PUBLIC_METHOD

// public method

- (void)setMediaItem:(MPMediaItem *)mediaItem
{
    // assing url
    _mediaItem = mediaItem;

    NSURL *mediaItemAssetURL = [mediaItem valueForProperty:MPMediaItemPropertyAssetURL];

    
    
    NSString *tempPath = NSTemporaryDirectory();
    
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:mediaItemAssetURL options:nil];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset: songAsset presetName: AVAssetExportPresetPassthrough];
    exporter.outputFileType = @"com.apple.coreaudio-format";
    
    NSString *fname = [[NSString stringWithFormat:@"file"] stringByAppendingString:@".caf"];
    NSString *exportFile = [tempPath stringByAppendingPathComponent:fname];
    
    // update the audiofile Path
    audioFile = [NSURL fileURLWithPath:exportFile];
    exporter.outputURL = audioFile;

    // remove files in tmp directory
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"%@",exportFile);
        _loading = true;
        [self readAudioFilesIntoMemory];
        [self startAUGraph];
    }];
     
    
    //    NSLog(@"%@",[[[NSBundle mainBundle] URLForResource:@"exported" withExtension:@"caf"] absoluteString]);
    //    fileReader.audioFileURL = [[NSBundle mainBundle] URLForResource:@"exported" withExtension:@"caf"];


}

- (void)setTime:(float)Time
{
    // if graph is loading new song, just ignore the request
    if (loading) return;
    
    // set time for the song 
    if ( Time >= 0 || Time < _duration) {
        UInt64 frameTotalForSound = _audioStruct->frameCount;
        _audioStruct->sampleNumber = frameTotalForSound * ( Time / _duration );
    }

//    _audioStruct->sampleNumber
}

- (void)setEQ:(int)frequencyTag gain:(float)gainValue
{

    // To set a parameter for a band you need to add the band number to the revelant enum for that parameter
    AudioUnitParameterID parameterID = kAUNBandEQParam_Gain + frequencyTag;
    OSStatus result = AudioUnitSetParameter(auEffectUnit,
                                            parameterID,
                                            kAudioUnitScope_Global,
                                            0,
                                            gainValue,
                                            0);
    
    if (noErr != result) {[self printErrorMessage: @"setEQ" withStatus: result]; return;}
}

- (NSArray *)getFrequencyBand
{
    return [NSArray arrayWithArray:eqFrequencies];
}

- (float)getCurrentTime
{
    return songTime;
}

/*
- (float)getDuration
{
    
    NSLog(@"getting audio duration");
    NSURL *mp3file   = [[NSBundle mainBundle] URLForResource: @"sol" withExtension: @"mp3"];
    CFURLRef sourceURL = (__bridge CFURLRef)mp3file;

    
    // Instantiate an extended audio file object.
    ExtAudioFileRef audioFileObject = 0;
    
    // Open an audio file and associate it with the extended audio file object.
    OSStatus result = ExtAudioFileOpenURL (sourceURL, &audioFileObject);
    
    if (noErr != result || NULL == audioFileObject) {[self printErrorMessage: @"ExtAudioFileOpenURL" withStatus: result]; return 0;}
    
    // get total frame from the input audio
    SInt64 framesInThisFile;
    UInt32 propertySize = sizeof(framesInThisFile);
    ExtAudioFileGetProperty(audioFileObject, kExtAudioFileProperty_FileLengthFrames, &propertySize, &framesInThisFile);
    
    // get audio format
    AudioStreamBasicDescription fileStreamFormat;
    propertySize = sizeof(AudioStreamBasicDescription);
    ExtAudioFileGetProperty(audioFileObject, kExtAudioFileProperty_FileDataFormat, &propertySize, &fileStreamFormat);
    
    return (float)framesInThisFile/(float)fileStreamFormat.mSampleRate;

}

*/

#pragma DEBUGTOOL


#define DEBUG_MSG 1
// 1 for print , other for disable

// You can use this method during development and debugging to look at the
//    fields of an AudioStreamBasicDescription struct.
- (void) printASBD: (AudioStreamBasicDescription) asbd {
    if ( DEBUG_MSG != 1) {
        return;
    }
    
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';


    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10lu",    asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10lu",    asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10lu",    asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10lu",    asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10lu",    asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10lu",    asbd.mBitsPerChannel);
}

- (void) printErrorMessage: (NSString *) errorString withStatus: (OSStatus) result {
    if ( DEBUG_MSG != 1) {
        return;
    }
    
    char str[20];
	// see if it appears to be a 4-char-code
	*(UInt32 *)(str + 1) = CFSwapInt32HostToBig(result);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else
		// no, format it as an integer
		sprintf(str, "%d", (int)result);
	
    //	fprintf(stderr, "Error: %s (%s)\n", operation, str);
    
    
    NSLog (
           @"*** %@ error: %s\n",
           errorString,
           str
           );
}


@end
