/*
     File: MusicViewController.m
		(c) 2010 Scott Snibbe
 
 */

#import "MusicViewController.h"
#import "ScaleView.h"
#include "Parameters.h"

@implementation MusicViewController

@synthesize musicSwitch, scalePickerView, scalePickerDataSource, tempoSlider, tempoLabel;

#pragma mark 

- (void)createCustomPicker
{	
	// setup the data source and delegate for this picker
	scalePickerDataSource = [[ScalePickerDataSource alloc] init];
	scalePickerView.dataSource = scalePickerDataSource;
	scalePickerView.delegate = scalePickerDataSource;
}

- (void)viewDidLoad
{		
	[super viewDidLoad];
	
	[self createCustomPicker];
	
	[self updateUIFields:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
		[self updateUIFields:NO];
}

// called after the view controller's view is released and set to nil.
// For example, a memory warning which causes the view to be purged. Not invoked as a result of -dealloc.
// So release any properties that are loaded in viewDidLoad or can be recreated lazily.
//
- (void)viewDidUnload
{
	[super viewDidUnload];
	
	// release and set out IBOutlets to nil	
	//self.scalePickerView = nil;
	self.scalePickerDataSource = nil;
}


// eat touches to prevent them from being passed to window below
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)updateUIFields:(bool)animate
{
	musicSwitch.on = Parameters::params().music();
	tempoSlider.value = Parameters::params().tempo();
	tempoLabel.text = [NSString stringWithFormat:@"%0.1f", Parameters::params().tempo()];	
	[tempoSlider setValue:Parameters::params().tempo() animated:animate];
	
	// select the row of picker based on current scale
	[scalePickerView selectRow:Parameters::params().scaleIndex() inComponent:0 animated:animate];

	gBubbleHarp->resetIdleTimer(YES);
}

- (IBAction)musicAction:(id)sender
{
	Parameters::params().setMusic(musicSwitch.isOn);

	[self updateUIFields:NO];
}

- (IBAction)setTempo:(UISlider*)sender
{
	Parameters::params().setTempo(sender.value);
	
	[self updateUIFields:NO];
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

