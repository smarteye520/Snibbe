//
//  MircophoneListener.h
//  Gravilux
//
//  Created by Colin Roache on 10/13/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface MicrophoneListener : NSObject <AVAudioRecorderDelegate> {
	AVAudioSession	*session;
	AVAudioRecorder	*recorder;
	double			sampleRate;
}

- (void)record;
- (void)stop;
- (void)printVolume;
- (float)currentVolume;

@end
