//
//  EQPlayer.h
//  EQPlayer
//
//  Created by Wildchild on 13/12/23.
//  Copyright (c) 2013年 Wildchild. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import <MediaPlayer/MediaPlayer.h>


@protocol EQPlayerDelegate <NSObject>

- (void)updateCurrentTime:(float)time;

@end

// Data structure for mono or stereo sound, to pass to the application's render callback function,
//    which gets invoked by a Mixer unit input bus when it needs more audio to play.
//
// Note: this is used by the callbacks for playing looped files (old way)
typedef struct {
    
    BOOL                 isStereo;           // set to true if there is data in the audioDataRight member
    UInt64               frameCount;         // the total number of frames in the audio data
    UInt32               sampleNumber;       // the next audio sample to play
    AudioUnitSampleType  *audioDataLeft;     // the complete left (or mono) channel of audio data read from an audio file
    AudioUnitSampleType  *audioDataRight;    // the complete right channel of audio data read from an audio file
    
} soundStruct, *soundStructPtr;

enum {
    SongTitle                          = 0,
    SongDuration                       = 1,
    SongSampleRate                     = 2,
    SongID                             = 3,
    SongUrl                            = 4
};



@interface EQPlayer : NSObject
{

    AVAudioSession *mySession;
    
    
    // number of frequencys
    NSMutableArray *eqFrequencies;                              // frequency bands for equalizer
    NSURL *audioFile;                                           // audio file URL
    float songTime;                                             // current time
    
    
    Float64 graphSampleRate;                                    // audio graph sample rate
    int displayNumberOfInputChannels;                           // number of input channels detected on startup
    AudioStreamBasicDescription     stereoStreamFormat;         // standard stereo 8.24 fixed point
    AudioStreamBasicDescription     auEffectStreamFormat;		// audio unit Effect format
    
    AUGraph                         processingGraph;            // the main audio graph
    BOOL                            playing;                    // indicates audiograph is running
    BOOL                            interruptedDuringPlayback;  // indicates interruption happened while audiograph running
    BOOL                            loading;                    // indicates the file is loading into memory
    
    // some of the audio units in this app
    AudioUnit                       ioUnit;                  // remote io unit
    AudioUnit                       mixerUnit;                  // multichannel mixer audio unit
    AudioUnit						auEffectUnit;           // this is the master effect on mixer output


    soundStruct *_soundStruct;
    
    // audio graph nodes
    
    AUNode      iONode;             // node for I/O unit speaker
    AUNode      mixerNode;          // node for Multichannel Mixer unit
    AUNode      auEffectNode;       // master mix effect node


}

// configuration methods for the audio graph & unit
- (void) setupAudioSession;
- (void) setupStereoStreamFormat;
- (void) setupAudioProcessingGraph;
- (void) connectAudioProcessingGraph;


// toggle the augraph
- (void) startAUGraph;
- (void) stopAUGraph;

// public method
- (void)setTime:(float)Time;
- (void)setEQ:(int)frequencyTag gain:(float)gainValue;
- (NSArray *)getFrequencyBand;




@property (readwrite) Float64 graphSampleRate;
@property (assign) int displayNumberOfInputChannels;
@property (getter = isPlaying)  BOOL                        playing;
@property                       BOOL                        interruptedDuringPlayback;
@property (readonly,nonatomic,getter = isLoading)  BOOL     loading;
@property (readonly,nonatomic) float duration;
@property (readwrite,nonatomic, setter = setMediaItem: , getter = getSongInfo) MPMediaItem *mediaItem;

@property (readwrite) AudioStreamBasicDescription stereoStreamFormat;
@property (readwrite) AudioStreamBasicDescription auEffectStreamFormat;
@property (readonly,nonatomic) soundStruct *audioStruct;


@property (assign) id <EQPlayerDelegate> delegate;




// debug tools
// print error
- (void) printErrorMessage: (NSString *) errorString withStatus: (OSStatus) result;
- (void) printASBD: (AudioStreamBasicDescription) asbd;

@end
