//
//  MPFPSViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/14/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPFPSViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "defs.h"
#import "Parameters.h"

@implementation MPFPSViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

//
//
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];    
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
    
#ifdef MOTION_PHONE_MOBILE
    viewMainBG_.layer.cornerRadius = UI_CORNER_RADIUS_PHONE;
#else
    viewMainBG_.layer.cornerRadius = UI_CORNER_RADIUS;
#endif
    
    CGAffineTransform transRotSlider = CGAffineTransformMakeRotation( -.5 * M_PI );
    slider_.transform = transRotSlider;
    

    float minFrameTime = gParams->minFrameTime();
    float fps = 1.0f / minFrameTime;
    float normal = (fps - MIN_FPS) / ( MAX_FPS - MIN_FPS );         
    int sign = gParams->frameDir();
    
    normal = MAX( normal, 0.0f );
    normal = MIN( normal, 1.0f );    
    normal *= sign;
    
    slider_.value = normal;
    
    slider_.center = viewSliderBG_.center;
        
    [slider_ setThumbImage:[UIImage imageNamed:@"slider_handle.png"] forState:UIControlStateNormal];
    [slider_ setThumbImage:[UIImage imageNamed:@"slider_handle.png"] forState:UIControlStateSelected];
    [slider_ setThumbImage:[UIImage imageNamed:@"slider_handle.png"] forState:UIControlStateHighlighted];
    
    [slider_ setMinimumTrackImage:[UIImage imageNamed:@"transparent_square.png"] forState:UIControlStateNormal];
    [slider_ setMaximumTrackImage:[UIImage imageNamed:@"transparent_square.png"] forState:UIControlStateNormal];    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBGColorChanged) name:gNotificationBGColorChanged object:nil];                
    [self updateViewBackground: viewMainBG_];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}


//
//
- (IBAction) sliderValueChanged:(UISlider *)sender
{

    // we're treating "rightmost" (though depends on orientation) as fastest (normal) framerate
    // and leftmost as slowest
    
    float val = fabs( sender.value );
    //val = 1.0f - val;
    
    int sign = sender.value > 0 ? 1 : -1;
    

    float fps = val * (MAX_FPS - MIN_FPS) + MIN_FPS;
    float frameTime = 1.0f / fps;
    
    //float minFrameTime = val * (MIN_FRAME_TIME_MAX - MIN_FRAME_TIME_MIN) + MIN_FRAME_TIME_MIN;
    //minFrameTime = MAX( minFrameTime, MIN_FRAME_TIME_MIN );
    //minFrameTime = MIN( minFrameTime, MIN_FRAME_TIME_MAX );
    
    gParams->setMinFrameTime( frameTime );
    gParams->setFrameDir( sign );  
    
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationMinFrameTimeChanged object:nil];
    
}

//
//
- (void) onBGColorChanged
{ 
    [self updateViewBackground: viewMainBG_];
}

// we want this whole view to suck up touches so they aren't passed down to the 
// eagl view

//
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}

//
//
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}

//
//
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
}

//
//
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
{
}

@end
