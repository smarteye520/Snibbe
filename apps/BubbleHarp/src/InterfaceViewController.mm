//
//  InterfaceViewController.mm
//  Bubble Harp
//
//  Created by Scott Snibbe on 2/24/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#include "defs.h"
#include "Parameters.h"
#import "InterfaceViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SettingsViewController.h"
//#import "ShareViewController.h"
#import "InfoViewController.h"
#import "MusicViewController.h"

#undef BOOL

#define kTransitionDuration	0.75

#define degreesToRadians(D) ((D) * M_PI / 180.0)

#define RESET_IDLE_TIMER(SET) [self resetIdleTimer:(SET)]


@implementation InterfaceViewController

@synthesize toolbarView, streamingButton, nonStreamingButton, eraserButton, 
musicButton, settingsButton, shareButton, infoButton, infoButton2,
toolView, toolButton, toolButton2, toolButton3, // iPhone only
settingsViewController, infoViewController, shareViewController, musicViewController,
appearing;

#pragma mark-

/*
 // The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Custom initialization
	}
	return self;
}
 */

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {

 }
*/

 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {

	 [super viewDidLoad];
	 
	 // hide music button until implemented $
	 //musicButton.style = UIBarButtonItemStylePlain;
	 //musicButton.image = [UIImage imageNamed: @"blank.png"];
	 //musicButton.enabled = NO;

	 // register to manually catch rotations if on iPad
	 if (IS_IPAD)
	 {
		 self.settingsViewController = 	
		 [[SettingsViewController alloc] initWithNibName:@"settings-iPad" bundle:nil];
		 
//		 self.shareViewController = 	
//		 [[ShareViewController alloc] initWithNibName:@"share-iPad" bundle:nil];
		 
		 self.infoViewController = 	
		 [[InfoViewController alloc] initWithNibName:@"info-iPad" bundle:nil];		 

		 self.musicViewController = 	
		 [[MusicViewController alloc] initWithNibName:@"music-iPad" bundle:nil];	 
		 
		 // iPhone only
		 toolView = nil;
		 
	 } else
	 {
		 self.settingsViewController = 	
		 [[SettingsViewController alloc] initWithNibName:@"settings-iPhone" bundle:nil];
		 //self.settingsViewController.delegate = self;
		 
//		 self.shareViewController = 	
//		 [[ShareViewController alloc] initWithNibName:@"share-iPhone" bundle:nil];
		 //self.shareViewController.delegate = self;
		 
		 self.infoViewController = 	
		 [[InfoViewController alloc] initWithNibName:@"info-iPhone" bundle:nil];		 
		 //self.infoViewController.delegate = self;
		 
		 self.musicViewController = 	
		 [[MusicViewController alloc] initWithNibName:@"music-iPhone" bundle:nil];		 
	 }
 
	 maxIdleTime = MAX_IDLE_TIME;
 }


-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self updateUIFields:NO];
	
	if (IS_IPAD) {
		[[NSNotificationCenter defaultCenter] addObserver:self
		 selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
	}
	
	// these seem to get deleted unless re-done at each appear
	[[NSNotificationCenter defaultCenter] addObserver:self 
	 selector:@selector(dismissPopupsHandler:) name:@"DismissPopups" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
	 selector:@selector(resetTimerHandler:) name:@"ResetTimer" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
	 selector:@selector(rotateViewToCurrent) name:@"RotateViewToCurrent" object:nil];	
}

-(void)viewWillDisappear:(BOOL)animated {
	if (IS_IPAD) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DismissPopups" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"ResetTimer" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"RotateViewToCurrent" object:nil];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {		
		// The device is an iPad running iPhone 3.2 or later, support rotation
		return YES;
	}
	else {
		// The device is an iPhone or iPod touch, only support portrait
		return (interfaceOrientation == UIInterfaceOrientationPortrait);		 
	}
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	[self rotateViewToCurrent];
}

- (bool) rotateViewToCurrent
{
	bool change = true;
	CGSize s = [[[UIApplication sharedApplication] keyWindow] bounds].size;
	
	UIDeviceOrientation orientation = UIDeviceOrientationPortrait;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{	
		orientation = [[UIDevice currentDevice] orientation];
		
		//NSLog(@"orientation = %d", orientation);
		
		float toolbarHeight =[toolbarView bounds].size.height;
		switch (orientation) {
			case UIDeviceOrientationPortrait:
				self.view.frame = CGRectMake(0, s.height - toolbarHeight, 
											 s.width, toolbarHeight);
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				self.view.frame = CGRectMake(0, 0, 
											 s.width, toolbarHeight);
				break;
			case UIDeviceOrientationLandscapeLeft:
				self.view.frame = CGRectMake(0, 0, 
											 toolbarHeight, s.height);
				break;
			case UIDeviceOrientationLandscapeRight:
				self.view.frame = CGRectMake(s.width - toolbarHeight, 0, 
											 toolbarHeight, s.height);
				break;
			default:
				change = false;
				break;
		}
	}
	
	// write out parameters
	Parameters::params().save();
	[self updateUIFields:NO];	// in case of a changed state, e.g. music on/off
	
	return change;
}

- (void) didRotate:(NSNotification *)notification
{		
	// if hidden, just jump to correct rotation
	if (self.view.hidden) {
		if ([self rotateViewToCurrent]) {
			// manually set the status bar orientation 
			//[[UIApplication sharedApplication] setStatusBarOrientation:iOrientation];
			
			//[toolbarView setFrame:self.view.frame];
		}
		
	}
}

-(void)addView
{
	// add view to hierarchy so it receives events
//	[ofxiPhoneGetGLView() addSubview:self.view];
	
//	self.view.hidden = YES;
	
	// iPhone only
	if (toolView) {		
		[[[UIApplication sharedApplication] keyWindow] addSubview:toolView];

		toolView.hidden = YES;
		
		float toolbarHeight =[toolbarView bounds].size.height;
		
		CGSize s = [[[UIApplication sharedApplication] keyWindow] bounds].size;
		
		// position directly above the tool button in the toolbar
		CGRect toolFrame = CGRectMake(0, s.height-toolbarHeight*3, 
									  [toolView bounds].size.width, [toolView bounds].size.height);
		
		[toolView setFrame:toolFrame];
	}
	
//	[self rotateViewToCurrent];
	
	// fade out splash screen
	[self fadeSplash];
	
	// schedule to automatically fade in if no action at start 
	//[self scheduleFirstShow];	
}

- (void)showView
{	
	// display the UIViewController's view on top of the application window.
    // start an animation block
	
	appearing = true;
	
	RESET_IDLE_TIMER(YES);

	[self updateUIFields:NO];
	self.view.hidden = NO;
	
	[self.view setNeedsLayout];
	[self.view layoutIfNeeded];
	
	self.view.alpha = 0.0;
	
	toolView.hidden = YES;
	
	[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(finishAppear:finished:context:)];
	
	self.view.alpha = 1.0;
        
    // do it
    [UIView commitAnimations];	
}

-(void) dismissToolbar:(bool)animated
{
	[self dismissModalViewControllerAnimated:animated];
}

-(void) dismissModalViewControllerAnimated:(bool)animated
{
	return;
	if (self.view.hidden) return;
	
	toolView.hidden = YES;
	
	[self dismissPopups:animated];
	
	//RESET_IDLE_TIMER(YES);
	
	//self.view.alpha = 1.0;
	
	if (animated) {
		// start an animation block
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.75];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(finishDismiss:finished:context:)];
		
		// configure animation
		self.view.alpha = 0.0;
		
		// do it!
		[UIView commitAnimations];
	} else {
		self.view.hidden = YES;
	}
	
}

- (void) dismissPopupsHandler:(NSNotification *)notification
{
	[self dismissPopups:NO];
}

- (void) resetTimerHandler:(NSNotification *)notification
{
	RESET_IDLE_TIMER(YES);
}

- (void)dismissPopups:(bool)animated
{	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		if (popoverController != nil) {
			[popoverController dismissPopoverAnimated:animated];
			popoverController = nil;
		}
		//RESET_IDLE_TIMER(YES);
		
		// fixes a bug after emailing and changing rotation from landscape to portrait
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RotateViewToCurrent" object:nil];
	} else {
		// dismiss tool view if visible
		toolView.hidden = YES;
	}

}

// called when the popover view is dismissed
- (void)popoverControllerDidDismissPopover:
(UIPopoverController *)pc {
	
	[self updateUIFields:NO];	// in case of a changed state, e.g. music on/off

   // NSLog(@"popover dismissed");  
	popoverController = nil;
}


- (void)finishDismiss:(NSString *)animationId finished:(BOOL)finished context:(void *)context {
	self.view.hidden = YES;
}

- (void)finishAppear:(NSString *)animationId finished:(BOOL)finished context:(void *)context {
	self.appearing = false;
	//[self undoDoubleTap];
}


// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//[super touchesBegan:touches withEvent:event];
	
	bool passUp = false;
	CGPoint position;
	
	//  look for touches outside of interface to dismiss
	for (UITouch *touch in touches) {
		position = [touch locationInView:self.view];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			
			// dismiss toolbar if we click on the "background" - on iPad, outside of bottom toobar
			if (!CGRectContainsPoint([toolbarView frame], position)) {
				[self dismissToolbar:NO];
				passUp = true;
			}
		} else {
			
			// on iPhone, between two toolbars
			if (!CGRectContainsPoint([toolbarView frame], position)) {
				
				[self dismissToolbar:NO];
				passUp = true;
			}
		}
	}
	
	if (passUp) [super touchesBegan:touches withEvent:event];	// pass to super after dismiss
}

- (void) undoDoubleTap
{
	gBubbleHarp->undoDoubleTap();
}

- (void)fadeSplash
{
	
	// remove info and splash screen after both hidden
	[NSTimer 
	 scheduledTimerWithTimeInterval:15 
	 target:self 
	 selector:@selector(freeStartupViews) 
	 userInfo:nil repeats:NO];
	
	// fade out splash screen
	CGRect screenRect = [UIScreen mainScreen].bounds;
	// may need to change for different orientations
	splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
	
	splashView.image = [UIImage imageNamed:Parameters::params().splashString()];	

	[[[UIApplication sharedApplication] keyWindow] addSubview:splashView];
	[[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:splashView];
	
	splashView.alpha = 1.0;
		
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDelay:Parameters::params().getStartupScreenDelay()];
	[UIView setAnimationDuration:1.0];
	splashView.alpha = 0.0;
	
    // do it
    [UIView commitAnimations];	
}

- (void)freeStartupViews {
	/*
	if (infoOverlayButton != nil) {
		[infoOverlayButton removeFromSuperview];
		//[infoOverlayButton release];
	}
	 */
	
	if (splashView != nil) {
		[splashView removeFromSuperview];
	}
}

- (void)scheduleFirstShow {
	[NSTimer 
	 scheduledTimerWithTimeInterval:3 
	 target:self 
	 selector:@selector(showView) 
	 userInfo:nil repeats:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


// Fill in text and graphic fields based on current values
- (void)updateUIFields:(bool)animate
{
	//[self dismissPopups:YES];

	if (Parameters::params().eraser()) {
		[streamingButton setStyle:UIBarButtonItemStyleBordered];
		[nonStreamingButton setStyle:UIBarButtonItemStyleBordered];
		[eraserButton setStyle:UIBarButtonItemStyleDone];
	} else if (Parameters::params().streaming()) {
		[streamingButton setStyle:UIBarButtonItemStyleDone];
		[nonStreamingButton setStyle:UIBarButtonItemStyleBordered];
		[eraserButton setStyle:UIBarButtonItemStyleBordered];
	} else {
		[streamingButton setStyle:UIBarButtonItemStyleBordered];
		[nonStreamingButton setStyle:UIBarButtonItemStyleDone];
		[eraserButton setStyle:UIBarButtonItemStyleBordered];
	}
	
	if (Parameters::params().music()) {
		[musicButton setStyle:UIBarButtonItemStyleDone];
	} else {
		[musicButton setStyle:UIBarButtonItemStyleBordered];
	}
	
	streamLabel.text = [NSString stringWithFormat:@"%0.2f", (Parameters::params().streamPeriod() / 60.0)];	
	[streamSlider setValue:Parameters::params().streamPeriod() animated:animate];
	
	// update iPhone Toolview
	if (toolView != nil) {
		BHTool tool = [self getCurrentTool];
		switch (tool) {
			default:
			case BHTool_Streaming:
				[toolButton setImage: [UIImage imageNamed:@"multi.png"]];
				[toolButton2 setImage: [UIImage imageNamed:@"single.png"]];
				[toolButton3 setImage: [UIImage imageNamed:@"eraser.png"]];				
				break;
				
			case BHTool_Single:
				[toolButton setImage: [UIImage imageNamed:@"single.png"]];
				[toolButton2 setImage: [UIImage imageNamed:@"multi.png"]];
				[toolButton3 setImage: [UIImage imageNamed:@"eraser.png"]];
				break;
				
			case BHTool_Eraser:
				[toolButton setImage: [UIImage imageNamed:@"eraser.png"]];
				[toolButton2 setImage: [UIImage imageNamed:@"multi.png"]];
				[toolButton3 setImage: [UIImage imageNamed:@"single.png"]];
				break;
		}
	}
	
	[self.view setNeedsDisplay];
	
	//RESET_IDLE_TIMER(YES);
}

- (void)resetIdleTimer:(bool)set {
    if (idleTimer) {
        [idleTimer invalidate];
    }
	
	if (set) {
		idleTimer = [NSTimer scheduledTimerWithTimeInterval:maxIdleTime target:self selector:@selector(idleTimerExceeded) userInfo:nil repeats:NO];
		//NSLog(@"Timer : ON");
	} else {
		idleTimer = nil;
		//NSLog(@"Timer: OFF");
	}
}

- (void)idleTimerExceeded {
    //NSLog(@"idle time exceeded");
	//Parameters::params().setDefaults(YES);
	//Parameters::params().setGalleryMode(YES); // have to restore into gallery mode after resetting parameters
	if (!self.view.hidden) [self dismissModalViewControllerAnimated:YES];
}

- (bool)isInCorner:(CGPoint) p {
	bool cornerTouch = NO;
	
	CGSize s = [[[UIApplication sharedApplication] keyWindow] bounds].size;
	CGSize touchArea = CGSizeMake(s.width * Parameters::params().cornerTouch(), s.height * Parameters::params().cornerTouch());
	
	if ((p.x < touchArea.width && p.y < touchArea.height) ||
		(p.x < touchArea.width && p.y > s.height - touchArea.height) ||
		(p.x > s.width - touchArea.width && p.y < touchArea.height) ||
		(p.x > s.width - touchArea.width && p.y > s.height - touchArea.height)) {
		cornerTouch = YES;
	}
	
	return cornerTouch;
}

- (bool)isInBottom:(CGPoint) p {
	// frame of view contains only the toolbar and is exactly its size.
	//return CGRectContainsPoint(self.view.frame, p);
	
	// $$ more flexible way
	CGSize s = [[[UIApplication sharedApplication] keyWindow] bounds].size;

	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	
	float touchHeight = 2 * [toolbarView bounds].size.height;
	
	switch (orientation) {
		default:
		case UIDeviceOrientationPortrait:
			if (p.y > s.height - touchHeight) return true;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			if (p.y < touchHeight) return true;
			break;
		case UIDeviceOrientationLandscapeLeft:
			if (p.x < touchHeight) return true;
			break;
		case UIDeviceOrientationLandscapeRight:
			if (p.x > s.width - touchHeight) return true;
			break;
	}
	return false;
}

- (bool)isOnSides:(CGPoint) p {
	// frame of view contains only the toolbar and is exactly its size.
	//return CGRectContainsPoint(self.view.frame, p);
	
	// $$ more flexible way
	CGSize s = [[[UIApplication sharedApplication] keyWindow] bounds].size;
	
	float touchHeight = 2 * [toolbarView bounds].size.height;
	
	// only test bottom  on iPhone
	if (p.y > s.height - touchHeight) return true;
	
	// test sides and top too if iPad
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (p.y < touchHeight) return true;
		if (p.x < touchHeight) return true;
		else if (p.x > s.width - touchHeight) return true;
	}
	
	return false;
}

#pragma mark- Actions

#pragma mark- App specific Actions
- (IBAction)setNumColors:(id)sender {
	Parameters::params().setNumColors((int)(((UISlider*)sender).value));
}

// handle output volume changes
- (IBAction)setStreamTime:(UISlider *)sender
{
	Parameters::params().setStreamPeriod(sender.value);
	[self updateUIFields:NO];
}

// handle input on/off switch action
- (IBAction)setEraser:(id)sender
{
	Parameters::params().setEraser(YES);
	[self updateUIFields:NO];
}

// handle input on/off switch action
- (IBAction)setStreaming:(id)sender
{
	Parameters::params().setStreaming(YES);
	Parameters::params().setEraser(NO);
	
	//[streamingButton setImage:[UIImage imageNamed:@"music-note.png"]];
	
	//UIImage *img = [UIImage imageNamed:@"music-note.png"];
	//streamingButton.image = img;

	[self updateUIFields:NO];
}

- (BHTool)getCurrentTool
{
	BHTool tool = BHTool_Streaming;
	
	if (Parameters::params().eraser()) {
		tool = BHTool_Eraser;
	} else if (!Parameters::params().streaming()) {
		tool = BHTool_Single;
	}
	
	return tool;
}
- (IBAction)save:(id)sender {
	gBubbleHarp->tempSave();
}
- (IBAction)load:(id)sender {
	gBubbleHarp->tempLoad();
}

// handle tool choice buttons on iPhone interface
- (IBAction)setTool:(id)sender
{
	BHTool tool = [self getCurrentTool];
	BHTool newTool = tool;
	
	if (sender == toolButton) {
		// show tool view if hidden
		if (toolView.hidden == YES) {
			// show toolView
			toolView.hidden = NO;
		} else {
			// dismiss toolView
			toolView.hidden = YES;
		}
		
	} else if (sender == toolButton2) {
		// set from toolButton2
		switch (tool) {
			case BHTool_Streaming: 
				newTool = BHTool_Single;
				break;
			case BHTool_Single:
			case BHTool_Eraser:
				newTool = BHTool_Streaming;
				break;
		}
		
		// dismiss tool view
		toolView.hidden = YES;
		
	} else if (sender == toolButton3) {
		// set from toolButton3
		switch (tool) {
			case BHTool_Streaming: 
			case BHTool_Single:
				newTool = BHTool_Eraser;
				break;

			case BHTool_Eraser:
				newTool = BHTool_Single;
				break;
		}
		
		// dismiss tool view
		toolView.hidden = YES;
	}
	
	switch (newTool) {
		case BHTool_Streaming:
			Parameters::params().setEraser(NO);
			Parameters::params().setStreaming(YES);
			break;
		case BHTool_Single:
			Parameters::params().setEraser(NO);
			Parameters::params().setStreaming(NO);
			break;
		case BHTool_Eraser:
			Parameters::params().setEraser(YES);
			break;
	}
	
	//[streamingButton setImage:[UIImage imageNamed:@"music-note.png"]];
	
	//UIImage *img = [UIImage imageNamed:@"music-note.png"];
	//streamingButton.image = img;
	
	[self updateUIFields:NO];
}

/*
// handle input on/off switch action
- (IBAction)setMusic:(id)sender
{
	if (Parameters::params().music()) {
		Parameters::params().setMusic(NO);
	} else {
		Parameters::params().setMusic(YES);
	}
	
	[self updateUIFields:NO];
}
*/

// handle input on/off switch action
- (IBAction)setNonStreaming:(id)sender
{
	Parameters::params().setStreaming(NO);
	Parameters::params().setEraser(NO);
	
	[self updateUIFields:NO];
}

// handle the clear button
- (IBAction)clearAction:(id)sender
{
	gBubbleHarp->deleteFrames();
	
	// turn off eraser- confusing after screen goes blank
	if (Parameters::params().eraser()) {
		Parameters::params().setEraser(NO);
		
		[self updateUIFields:NO]; // updates tool buttons
	}
	
//	[self dismissPopups:YES];
	
	RESET_IDLE_TIMER(YES);
}

- (IBAction)popupAction:(id)sender
{	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{		
		UIViewController *contentController, *activeContentController = nil;
		
		if (popoverController != nil) {
			// there's a popup already up, below we will check if it's the same one, and hide
			
			activeContentController = popoverController.contentViewController;
		}
		
		if (sender == settingsButton) {
			contentController = settingsViewController;
			RESET_IDLE_TIMER(YES);
		} else if (sender == shareButton) {
			contentController = shareViewController;
			RESET_IDLE_TIMER(NO);
		} else if (sender == infoButton) {
			contentController = infoViewController;
			RESET_IDLE_TIMER(NO); // leave up info window for reading
		} else if (sender == musicButton) {
			contentController = musicViewController;
			RESET_IDLE_TIMER(YES);
			// turn music on by default first time
			//if (Parameters::params().firstMusic()) Parameters::params().setMusic(true);	// also turns off "firstMusic"
			if (!Parameters::params().music()) Parameters::params().setMusic(true); // turn on music if it's not on
		} else {
			return;
		}
		
		[self updateUIFields:NO];	// in case of change of state
		// hide any other popups
		[self dismissPopups:NO];
		
		// just return without re-popping up the same popup we just hid
		if (contentController == activeContentController) {
			return;
		}
		
		CGSize size = [contentController.view bounds].size;
		
		contentController.contentSizeForViewInPopover = size;
		
		//create a popover controller
		popoverController = [[UIPopoverController alloc]
							 initWithContentViewController:contentController];
		
		popoverController.delegate = self;
		
		//present the popover view non-modal with a
		//reference to the toolbar button which was pressed
		[popoverController presentPopoverFromBarButtonItem:sender
								  permittedArrowDirections:UIPopoverArrowDirectionDown
												  animated:YES];
	}
}

- (IBAction)modalViewAction:(id)sender
{	
	UIViewController *contentController;
	
	if (sender == settingsButton) {
		contentController = settingsViewController;
		RESET_IDLE_TIMER(YES);
	} else if (sender == shareButton) {
		contentController = shareViewController;
		RESET_IDLE_TIMER(NO);
	} else if (sender == infoButton || sender == infoButton2) {
		contentController = infoViewController;
		RESET_IDLE_TIMER(NO); // leave up info window for reading
	} else if (sender == musicButton) {
		contentController = musicViewController;
		RESET_IDLE_TIMER(YES);
		// turn music on by default first time
		//if (Parameters::params().firstMusic()) Parameters::params().setMusic(true);	// also turns off "firstMusic"
		if (!Parameters::params().music()) Parameters::params().setMusic(true); // turn on music if it's not on

	} else {
		return;
	}
	
	toolView.hidden = true;	// hide if visible to avoid overlaps
	
//	CGSize size = [contentController.view bounds].size;
	//contentController.contentSize = size;
	
	//present the navigation controller modally
	[self presentModalViewController:contentController animated:YES];
}
@end

