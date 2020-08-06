//
//  MusicViewController.h
//  Gravilux
//
//  Created by Colin Roache on 10/26/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//
//#pragma once

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "VisualizerTableViewController.h"
#import "RotatingColorButton.h"
#include "Parameters.h"
#include "Visualizer.h"

@class RotationController;

@interface MusicViewController : UIViewController <MPMediaPickerControllerDelegate> {
	IBOutlet UIButton* pickButton;
	IBOutlet UIButton* playPauseButton;
	IBOutlet UIButton* autoButton;
	IBOutlet UIButton* repeatButton;
	IBOutlet RotatingColorButton* colorDriftControl;
	IBOutlet VisualizerTableViewController* visualizerTableVC;
	@private
	NSTimeInterval startTime;
	AVAudioPlayer* player;
	bool			useModal;
}

- (IBAction)pickSong:(id)sender;
- (IBAction)togglePause:(id)sender;
- (IBAction)toggleRepeat:(id)sender;
- (IBAction)toggleColorDrift:(id)sender;
- (IBAction)toggleAuto:(id)sender;

@end