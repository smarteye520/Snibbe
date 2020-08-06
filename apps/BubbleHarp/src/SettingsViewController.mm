//
//  SettingsViewController.mm
//  Bubble Harp
//
//  Created by Scott Snibbe on 2/24/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#include "defs.h"
#include "Parameters.h"
#import "SettingsViewController.h"
#import <QuartzCore/QuartzCore.h>

#undef BOOL

@implementation SettingsViewController

@synthesize streamSlider, pointsSlider, streamLabel, pointsLabel, gallerySwitch, galleryButton;

#pragma mark-

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	[super viewDidLoad];
	
	pointsSlider.maximumValue = Parameters::params().maxPointsSliderMax();
	
	[self updateUIFields:NO];	 
}

- (void)viewWillAppear:(BOOL)animated
{
	[self updateUIFields:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
	//NSLog(@"SettingsViewController:viewWillDisappear: save Parameters::params()");
	//Parameters::params().save();
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


// Fill in text and graphic fields based on current values
- (void)updateUIFields:(bool)animate
{
	
	gBubbleHarp->resetIdleTimer(YES);
	
	streamLabel.text = [NSString stringWithFormat:@"%0.2f", (Parameters::params().streamPeriod() / 60.0)];	
	[streamSlider setValue:Parameters::params().streamPeriod() animated:animate];
	
	pointsLabel.text = [NSString stringWithFormat:@"%4d", Parameters::params().maxPoints()];
	[pointsSlider setValue:Parameters::params().maxPoints() animated:animate];
	
	gallerySwitch.on = Parameters::params().galleryMode();
	
	[self.view setNeedsDisplay];
}

// eat touches to prevent them from being passed to window below
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

// handle the link button
- (IBAction)galleryModeAction:(id)sender
{
	if (sender == galleryButton) {
		// lock gallery mode
		Parameters::params().setGalleryModeLocked(YES);
		[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
		[galleryButton setTitle:@"No Sleep Lock" forState:UIControlStateNormal];

	} else if (!Parameters::params().galleryModeLocked()) { // sender is switch
		if (gallerySwitch.isOn) {
			Parameters::params().setGalleryMode(YES);
			[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
		} else {
			Parameters::params().setGalleryMode(NO);
			[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
		}
	}
	[self updateUIFields:NO];
}

- (IBAction)setStreamTime:(UISlider *)sender
{
	Parameters::params().setStreamPeriod(sender.value);
	[self updateUIFields:NO];
}

- (IBAction)setMaxPoints:(UISlider *)sender
{
	Parameters::params().setMaxPoints(sender.value);
	[self updateUIFields:NO];
}

// handle the reset button
- (IBAction)resetAction:(id)sender
{
	Parameters::params().setDefaults(true);
	[self updateUIFields:YES];
}

// for done button
- (IBAction)doneAction:(id)sender {
	// for iPhone only
	// dismiss this modal window
	[self dismissModalViewControllerAnimated:YES];	
	// rotate fixes a bug where view is resized and transparent part overlays interaction area, disabling interaction
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RotateViewToCurrent" object:nil];
}


@end

