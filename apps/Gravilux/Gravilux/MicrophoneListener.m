//
//  MicrophoneListener.m
//  Gravilux
//
//  Created by Colin Roache on 10/13/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "MicrophoneListener.h"

@interface MicrophoneListener (Private)

- (void)setCategory:(NSString *const)category active:(BOOL)act;
@end

@implementation MicrophoneListener

- (id) init
{
	self = [super init];
	if(self) {
		
		session = [AVAudioSession sharedInstance];
		
		[self setCategory:AVAudioSessionCategoryAmbient active:NO];
		
		/*
		// THIS MAY BE THE ROUTE
		musicPlayerController = [MPMusicPlayerController iPodMusicPlayer];
		MPMediaItem* now = musicPlayerController.nowPlayingItem;
		NSURL* urlAsset = [now valueForProperty:MPMediaItemPropertyAssetURL];
		NSLog(@"URL: %@", [urlAsset absoluteURL]);
		musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:urlAsset error:nil];
		musicPlayer.meteringEnabled = YES;
		*/
		
		
		
		// Set prefered buffer rate
		NSError *err = nil;
		NSTimeInterval preferredBufferDuration = 0.005;
		[session setPreferredIOBufferDuration: preferredBufferDuration
										error: &err];
		if (err) {
			NSLog(@"Error setting buffer duration prference");
		}
		
		// Look up buffer rate based on the device's abilities
		sampleRate = [session currentHardwareSampleRate];
		
		NSMutableDictionary * recordSetting = [[NSMutableDictionary alloc] init];
		
		[recordSetting setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
		[recordSetting setValue:[NSNumber numberWithFloat:8000.0] forKey:AVSampleRateKey]; // $$$ 8kHz
		[recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
		
		[recordSetting setValue :[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
		[recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
		[recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];

		recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/test.caf", [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]]] settings:recordSetting error:&err];
		if(!recorder){
			NSLog(@"recorder: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
		}
		[recorder setDelegate:self];
		[recorder prepareToRecord];
		recorder.meteringEnabled = YES;
		
		BOOL audioHWAvailable = session.inputIsAvailable;
		if (! audioHWAvailable) {
			
		}
	}
	return self;
}

/*- (void) dealloc
{
	[super dealloc];
}*/

- (void)record
{
	
	/*[musicPlayer play];
	[musicPlayerController play];
	*/
	[self setCategory:AVAudioSessionCategoryRecord active:YES];
	
	NSError *activityError = nil;
	[session setActive:YES error:&activityError];
	if(activityError) {
		NSLog(@"Error setting audio session activity state");
	}
	
	[recorder prepareToRecord];
	recorder.meteringEnabled = YES;
	[recorder record];
}

- (void)stop
{
/*	
	[musicPlayer pause];
	[musicPlayerController pause];*/
	[recorder stop];
	NSError *activityError = nil;
	[session setActive:NO error:&activityError];
	if(activityError) {
		NSLog(@"Error setting audio session activity state");
	}
	[self setCategory:AVAudioSessionCategoryAmbient active:NO];

}

- (void)printVolume
{
//	[musicPlayer updateMeters];
//	NSLog(@"Average power %f", [musicPlayer averagePowerForChannel:0]);
	
	[recorder updateMeters];
	NSLog(@"Average power %f", [recorder averagePowerForChannel:0]);
}

- (float)currentVolume
{
	[self printVolume];
//	[musicPlayer updateMeters];
//	return [musicPlayer averagePowerForChannel:0];
	[recorder updateMeters];
	return [recorder averagePowerForChannel:0];
}

#pragma mark - Protocol Methods

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder
{
	//[self setCategory:AVAudioSessionCategoryRecord active:YES];
}

#pragma mark Private Methods

- (void)setCategory:(NSString *const)category active:(BOOL)act
{
	/*NSError* error = nil;
	if(![session setCategory:category error:&error]) {
		NSLog(@"Couldn't set audio session category: %@", error);
	}	
	if(![session setActive:act error:&error]) {
		NSLog(@"Couldn't make audio session active: %@", error);
	}*/
}
@end
