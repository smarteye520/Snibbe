//
//  MusicViewController.m
//  Gravilux
//
//  Created by Colin Roache on 10/26/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "MusicViewController.h"
#import "RotationController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "TSLibraryImport.h"
#import "FlurryAnalytics.h"

#define TRANSITION_LENGTH_S .5

@interface MusicViewController (Private)
- (void)updateUI;
- (void)exportAssetAtURL:(NSURL*)assetURL withTitle:(NSString*)title;
@end

@implementation MusicViewController
#pragma mark - Class Methods
#pragma mark Object Lifecycle
- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self) {
	}
	return self;
}

- (void)dealloc {
	[pickButton release];
	[playPauseButton release];
	[autoButton release];
	[repeatButton release];
	[visualizerTableVC release];
    [super dealloc];
}

#pragma mark View Lifecycle
- (void)viewDidLoad {
	
    [super viewDidLoad];
	self.view.frame = CGRectMake(0, 0, 320, 270);
	
	NSString *reqSysVer = @"5.0";
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	useModal = ([currSysVer compare:reqSysVer options:NSNumericSearch] == NSOrderedAscending); // Use modal presentation when in iOS 4
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI) name:@"updateUIVisualizer" object:nil];
	
	[self updateUI];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[pickButton release];
	pickButton = nil;
	[playPauseButton release];
	playPauseButton = nil;
	[autoButton release];
	autoButton = nil;
	[repeatButton release];
	repeatButton = nil;
	[visualizerTableVC.view release];
	visualizerTableVC = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
	colorDriftControl.render = YES;
	[colorDriftControl setNeedsDisplay];
}

- (void) viewDidDisappear:(BOOL)animated
{
	colorDriftControl.render = NO;
}

#pragma mark - Delegate Methods
#pragma mark MPMediaPickerControllerDelegate
- (void)mediaPicker:(MPMediaPickerController *)mediaPicker 
  didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
	__block NSURL* assetURL;
	[UIView animateWithDuration:useModal?0.:TRANSITION_LENGTH_S animations:^{
		MPMediaItem* selectedItem = [mediaItemCollection.items objectAtIndex:0];
		assetURL = [selectedItem valueForProperty:MPMediaItemPropertyAssetURL];
		
		/**
		 * !!!: When MPMediaItemPropertyAssetURL is nil, it typically means the file
		 * in question is protected by DRM. (old m4p files)
		 */
		if (assetURL) {
			[self exportAssetAtURL:assetURL withTitle:@"visualizer"];
			if (!useModal) {
				mediaPicker.view.alpha = 0.;
			}
		}
	} completion:^(BOOL finished) {
		if (finished) {
			UIResponder *responder = self;
			if (useModal) {
				// Find the fullscreen 
				while (responder && ![responder isKindOfClass:[RotationController class]]) {
					responder = [responder nextResponder];
				}
				[((UIViewController*)responder) dismissModalViewControllerAnimated:NO];
			}
			if (assetURL) { // we have the file
				if (!useModal) {
					[mediaPicker.view removeFromSuperview];
					[mediaPicker release];
				}
			} else { // Cannot play file
				UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Could not play song" message:@"This song appears to have DRM (copy protection). Please use a MP3 or an unprotected AAC file" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
				[alert release];
				if (useModal) {
					[self performSelector:@selector(pickSong:) withObject:self afterDelay:.55f];
				}
			}
		}
	}];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
	if (useModal) {
		// Find the fullscreen 
		UIResponder *responder = self;
		while (responder && ![responder isKindOfClass:[RotationController class]]) {
			responder = [responder nextResponder];
		}
		
		[((UIViewController*)responder) dismissModalViewControllerAnimated:NO];
	} else {
		[UIView animateWithDuration:TRANSITION_LENGTH_S animations:^{
			mediaPicker.view.alpha = 0.;
		} completion:^(BOOL finished) {
			if (finished) {
				[mediaPicker.view removeFromSuperview];
				[mediaPicker release];
			}
		}];
	}
}

#pragma mark - IB Actions
- (IBAction)pickSong:(id)sender
{
	[FlurryAnalytics logEvent:@"Visualizer Pick Song"];
	//	gGravilux->visualizer()->stop();
	
	// Bring up the media picker
	MPMediaPickerController* mediaPicker = [[[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic] retain];
	mediaPicker.delegate = self;
	
	// Find the fullscreen 
	UIResponder *responder = self;
    while (responder && ![responder isKindOfClass:[RotationController class]]) {
        responder = [responder nextResponder];
    }
	
	if (useModal) {
		[((UIViewController*)responder) presentModalViewController:mediaPicker animated:NO];
	} else {
		[((UIViewController *)responder).view addSubview:mediaPicker.view];
		
		mediaPicker.view.autoresizingMask = 0xFFFFFFFF;
		
		mediaPicker.view.alpha = 0.;
		[UIView animateWithDuration:TRANSITION_LENGTH_S animations:^{
			mediaPicker.view.alpha = 1.;
		} completion:nil];
	}
		
}

- (IBAction)togglePause:(id)sender
{
	if (gGravilux->visualizer()->loaded()) {
		if (gGravilux->visualizer()->running()) {
			gGravilux->visualizer()->stop();
		} else {
			gGravilux->visualizer()->start();
		}
	}
}

- (IBAction)toggleRepeat:(id)sender
{
	gGravilux->visualizer()->repeat(!gGravilux->visualizer()->repeat());
	
	[FlurryAnalytics logEvent:@"Visualizer Toggle Repeat" withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:gGravilux->visualizer()->repeat()] forKey:@"Enabled"]];
}

- (IBAction)toggleColorDrift:(id)sender
{
	colorDriftControl.selected = !colorDriftControl.selected;
	// This method in Visualizer takes care of setting the global state in Parameters
	gGravilux->visualizer()->colorWalk(colorDriftControl.selected);
	
	[FlurryAnalytics logEvent:@"Visualizer Toggle Color Drift" withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:gGravilux->visualizer()->colorWalk()] forKey:@"Enabled"]];
}

- (IBAction)toggleAuto:(id)sender
{
	gGravilux->visualizer()->automatic(!gGravilux->visualizer()->automatic());
	
	[FlurryAnalytics logEvent:@"Visualizer Toggle Automation" withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:gGravilux->visualizer()->automatic()] forKey:@"Enabled"]];
}

#pragma mark - Private Methods

- (void)updateUI
{
	bool loaded = gGravilux->visualizer()->loaded();
	bool running = gGravilux->visualizer()->running();
	bool automatic = gGravilux->visualizer()->automatic();
	bool repeat = gGravilux->visualizer()->repeat();
	bool colorWalk = gGravilux->visualizer()->colorWalk();
	
	// Only enable the table view when we are running in manual
	bool visualizerTableEnabled = running && !automatic;
	
	NSLog(@"%c%c%c%c%c", running?'R':' ', automatic?'A':' ', repeat?'r':' ', colorWalk?'C':' ', visualizerTableEnabled?'V':' ');
	
	[UIView animateWithDuration:0.25
						  delay:0.0
						options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionOverrideInheritedDuration | UIViewAnimationOptionOverrideInheritedCurve
					 animations:^{
						 visualizerTableVC.view.userInteractionEnabled = visualizerTableEnabled;
						 visualizerTableVC.view.alpha = visualizerTableEnabled?1.:.5;
						 
						 playPauseButton.userInteractionEnabled = loaded;
						 playPauseButton.alpha = loaded?1.:.5;
						 playPauseButton.selected = running;
						 
						 repeatButton.userInteractionEnabled = loaded;
						 repeatButton.alpha = loaded?1.:.5;
						 repeatButton.selected = repeat;
						 
						 colorDriftControl.userInteractionEnabled = running;
						 colorDriftControl.alpha = running?1.:.5;
						 colorDriftControl.selected = colorWalk;
						 
						 autoButton.userInteractionEnabled = running;
						 autoButton.alpha = running?1.:.5;
						 autoButton.selected = automatic;
					 }
					 completion:^(BOOL finished) {
						 if (finished) {
							 [visualizerTableVC.view setNeedsDisplay];
							 [playPauseButton setNeedsDisplay];
							 [colorDriftControl setNeedsDisplay];
							 [autoButton setNeedsDisplay];
						 }
					 }];
}

- (void)progressTimer:(NSTimer*)timer {
	TSLibraryImport* exporter = (TSLibraryImport*)timer.userInfo;
	switch (exporter.status) {
		case AVAssetExportSessionStatusExporting:
		case AVAssetExportSessionStatusCancelled:
		case AVAssetExportSessionStatusCompleted:
		case AVAssetExportSessionStatusFailed:
			[timer invalidate];
			break;
		default:
			break;
	}
}

- (void)exportAssetAtURL:(NSURL*)assetURL withTitle:(NSString*)title {
	
	// create destination URL
	NSString* ext = [TSLibraryImport extensionForAssetURL:assetURL];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSURL* outURL = [[NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:title]] URLByAppendingPathExtension:ext];	
	// we're responsible for making sure the destination url doesn't already exist
	[[NSFileManager defaultManager] removeItemAtURL:outURL error:nil];
	
	// create the import object
	TSLibraryImport* import = [[TSLibraryImport alloc] init];
	startTime = [NSDate timeIntervalSinceReferenceDate];
	NSTimer* timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(progressTimer:) userInfo:import repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[import importAsset:assetURL toURL:outURL completionBlock:^(TSLibraryImport* import) {
		/*
		 * If the export was successful (check the status and error properties of 
		 * the TSLibraryImport instance) you know have a local copy of the file
		 * at `outURL` You can get PCM samples for processing by opening it with 
		 * ExtAudioFile. Yay!
		 *
		 * Here we're just playing it with AVPlayer
		 */
		if (import.status != AVAssetExportSessionStatusCompleted) {
			// something went wrong with the import
			NSLog(@"Error importing: %@", import.error);
			[import release];
			import = nil;
			return;
		}
		
		// import completed
		
		gGravilux->visualizer()->load([[outURL path] UTF8String]);
		gGravilux->visualizer()->start();
		
		[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
		//		[self updateUI];
	}];
}
@end
