//
//  UIViewControllerAudioTuning.m
//  Scoop
//
//  Created by Graham McDermott on 3/30/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import "UIViewControllerAudioTuning.h"
#import "Scoop.h"

@implementation UIViewControllerAudioTuning

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        scoop = nil;
    }
    return self;
}

- (void)dealloc
{
    [toneFreqLabel_ release];
    [toneRangeLabel_ release];
    [filterMinCutoffLabel_ release];
    [filterMaxCutoffLabel_ release];
    [filterResonanceLabel_ release];
    [toneVolMaxLabel_ release];
    [beatVolLabel_ release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [toneFreqLabel_ release];
    toneFreqLabel_ = nil;
    [toneRangeLabel_ release];
    toneRangeLabel_ = nil;
    [filterMinCutoffLabel_ release];
    filterMinCutoffLabel_ = nil;
    [filterMaxCutoffLabel_ release];
    filterMaxCutoffLabel_ = nil;
    [filterResonanceLabel_ release];
    filterResonanceLabel_ = nil;
    [toneVolMaxLabel_ release];
    toneVolMaxLabel_ = nil;
    [beatVolLabel_ release];
    beatVolLabel_ = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void) setScoop: (Scoop *) s
{
    scoop = s;
}

- (IBAction)SetToneFrequency:(id)sender {
    float val = ((UISlider *) sender).value;
    //NSLog( @"tone frequency: %f\n", val );
    
    
    int iVal = val;
    
    // these are the 1/2 steps from 220 hz
    
    float newFreq = pow( pow( 2, 1/12.0f ), iVal ) * 220.0f;    
    
    scoop->SetToneFrequency(newFreq);
    [toneFreqLabel_ setText: [NSString stringWithFormat:@"%.2f", newFreq]];
    
}

- (IBAction)SetToneRange:(id)sender {
    float val = ((UISlider *) sender).value;
    //NSLog( @"tone range: %f\n", val );
    

    
    scoop->SetToneRange(val);
    [toneRangeLabel_ setText: [NSString stringWithFormat:@"%.2f", val]];
}

- (IBAction)SetMinCutoff:(id)sender {
    float val = ((UISlider *) sender).value;
    //NSLog( @"min cutoff: %f\n", val );
    
    scoop->SetMinCutoff(val);
    [filterMinCutoffLabel_ setText: [NSString stringWithFormat:@"%.2f", val]];
}

- (IBAction)SetMaxCutoff:(id)sender {
    float val = ((UISlider *) sender).value;
    //NSLog( @"max cutoff: %f\n", val );
    
    scoop->SetMaxCutoff(val);
    [filterMaxCutoffLabel_ setText: [NSString stringWithFormat:@"%.2f", val]];
}

- (IBAction)SetResonance:(id)sender {
    float val = ((UISlider *) sender).value;
    //NSLog( @"resonance: %f\n", val );
    
    scoop->SetResonance(val);
    [filterResonanceLabel_ setText: [NSString stringWithFormat:@"%.2f", val]];
}

- (IBAction)SetToneVolMax:(id)sender {
    float val = ((UISlider *) sender).value;
    //NSLog( @"tone vol max: %f\n", val );
    
    scoop->SetToneVolMax(val);
    [toneVolMaxLabel_ setText: [NSString stringWithFormat:@"%.2f", val]];
}

- (IBAction)SetBeatVol:(id)sender {
    float val = ((UISlider *) sender).value;
    //NSLog( @"beat vol: %f\n", val );
    
    scoop->SetBeatVol(val);
    [beatVolLabel_ setText: [NSString stringWithFormat:@"%.2f", val]];
}
@end
