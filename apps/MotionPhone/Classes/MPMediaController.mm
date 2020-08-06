//
//  MPMediaController.m
//  MotionPhone
//
//  Created by Graham McDermott on 1/12/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#import "MPMediaController.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIOrientView.h"
#import "defs.h"
#import "SnibbeUtils.h"

// private interface
@interface MPMediaController()

- (void) onBGColorChanged;

// MPMediaPickerControllerDelegate methods

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection;
- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker;


@end

@implementation MPMediaController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc
{
    if ( mediaPicker_ )
    {
        [mediaPicker_ release];
    }
    
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
    

    if ( IS_IPAD )
    {
        viewMainBG_.layer.cornerRadius = UI_CORNER_RADIUS;    
    }
        
    mediaPicker_ = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];        
    
    
    
#ifdef MOTION_PHONE_MOBILE
    
    // the media picker is a tricky beast - behaves difference on various versions of 
    // iOS and on different hardware.  Tried to triage and make the best of it.  best case scenario
    // on iPhone is iOS 5.0+.  Still in this situation we orient it correctly when it becomes visible, then
    // keep that orientation even if the device rotates.  On pre iOS 5.0 it's always in portrait.
    
    
    if ( iOSVersionAtLeast( @"5.0" ) )
    {
        
        
        mediaPicker_.view.center = CGPointMake( 160.0f, 208.0f );
        
        switch ( gDeviceOrientation ) {
            case UIDeviceOrientationLandscapeLeft:
            {
                mediaPicker_.view.bounds = CGRectMake( 0, 0, 416.0f, 320.0f );
                mediaPicker_.view.transform = CGAffineTransformMakeRotation( M_PI_2 );
                break;
            }
            case UIDeviceOrientationLandscapeRight:
            {
                mediaPicker_.view.bounds = CGRectMake( 0, 0, 416.0f, 320.0f );
                mediaPicker_.view.transform = CGAffineTransformMakeRotation( -M_PI_2 );
                break;
            }
            case UIDeviceOrientationPortrait:
            {
                mediaPicker_.view.bounds = CGRectMake( 0, 0, 320.0f, 416.0f);
                mediaPicker_.view.transform = CGAffineTransformMakeRotation( 0.0f );
                break;
            }
            case UIDeviceOrientationPortraitUpsideDown:
            {
                mediaPicker_.view.bounds = CGRectMake( 0, 0, 320.0f, 416.0f);
                mediaPicker_.view.transform = CGAffineTransformMakeRotation( M_PI );
                break;
            }
                
               
            default:
                break;
       
        }
        
    }
    else
    {
        // this is neede b/c prior to iOS 5.0, the media player can't be properly
        // resized, so we put it in the middle.  Not the prettiest solution.
        
        mediaPicker_.view.frame = CGRectMake(0.0f, 0.0f, 320.0f, 480.0f );
                
        
    }
    
#else
    
    if ( iOSVersionAtLeast( @"5.0" ) )
    {
        mediaPicker_.view.frame = CGRectMake( 0, 
                                              0, 
                                              orientView_.frame.size.width, 
                                              orientView_.frame.size.height);
        
    }
    else
    {
        // this is neede b/c prior to iOS 5.0, the media player can't be properly
        // resized, so we put it in the middle.  Not the prettiest solution.
        mediaPicker_.view.frame = CGRectMake( (orientView_.frame.size.width - 320.0f) / 2.0f, 
                                              0, 
                                             320.0f, 
                                             orientView_.frame.size.height);
        
    }
    
#endif
    
    
    
    mediaPicker_.allowsPickingMultipleItems = false;
    
    
#ifdef MOTION_PHONE_MOBILE
    
    // on the phone we're not rotation the media view since it's hardwired
    // by apple to be a portrait control and we don't have the screen real estate
    // to give it room to rotate in a square
    [self.view addSubview: mediaPicker_.view];
    
    // on pre iOS5 3GS we're getting a transparent bar at the top the size of the status bar.  weird.
    //NSLog( @"self: %@\n", NSStringFromCGRect( self.view.frame ));
    //NSLog( @"picker: %@\n", NSStringFromCGRect( mediaPicker_.view.frame ));
    //NSLog( @"picker bounds: %@\n", NSStringFromCGRect( mediaPicker_.view.bounds ));
    
#else
    [orientView_ addSubview: mediaPicker_.view];
#endif
    mediaPicker_.delegate = self;
    
    
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

#pragma mark private implementation

//
//
- (void) onBGColorChanged
{ 
    [self updateViewBackground: viewMainBG_];
}

#pragma mark MPMediaPickerControllerDelegate

//
//
- (void) phonePopView
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRefreshMediaButton object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: notifyOff_ object:nil];
    [snibbeNav_ popLastVC];
}

//
//
- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{    
    
    
    MPMusicPlayerController * musicPlayer = [MPMusicPlayerController iPodMusicPlayer];    
    if ( mediaItemCollection && musicPlayer )
    {
        
        
        // Assign the selected item(s) to the music player and start playback.
        [musicPlayer stop];
        [musicPlayer setQueueWithItemCollection:mediaItemCollection];
        [musicPlayer play];        
               
    }

#ifdef MOTION_PHONE_MOBILE
    [self phonePopView];
#else
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestMediaViewOnOff object:nil];
#endif
    
}

//
//
- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
#ifdef MOTION_PHONE_MOBILE
    [self phonePopView];
#else
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestMediaViewOnOff object:nil];
#endif
    
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
