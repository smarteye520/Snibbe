//
//  MPRecordViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/22/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPRecordViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MPUIKitViewController.h"
#import "MPUIOrientButton.h"
#import "defs.h"


// private interface
@interface MPRecordViewController()


- (void) onSaveShareShown;
- (void) onSaveShareHidden;
- (void) onLoadShown;
- (void) onLoadHidden;
- (void) onMediaShown;
- (void) onMediaHidden;

- (void) refreshMediaButton;
- (void) doRefreshMediaButton: (bool) bForce;

@end

@implementation MPRecordViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

//
//
- (void) dealloc
{
    MPMusicPlayerController * musicPlayer = [MPMusicPlayerController iPodMusicPlayer];    
    [musicPlayer endGeneratingPlaybackNotifications];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [super dealloc];
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
    
    [buttonLoad_ setImageNamesOn: @"load_on.png" off:@"load_off.png" ];
    [buttonSaveShare_ setImageNamesOn: @"share_on.png" off:@"share_off.png" ];
    

    
    [self doRefreshMediaButton: true];
    
    MPMusicPlayerController * musicPlayer = [MPMusicPlayerController iPodMusicPlayer];        
    [musicPlayer beginGeneratingPlaybackNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSaveShareShown) name:gNotificationSaveShareViewOn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSaveShareHidden) name:gNotificationSaveShareViewOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLoadShown) name:gNotificationLoadViewOn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLoadHidden) name:gNotificationLoadViewOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaShown) name:gNotificationMediaViewOn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaHidden) name:gNotificationMediaViewOff object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBGColorChanged) name:gNotificationBGColorChanged object:nil];           
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMediaButton) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMediaButton) name:gNotificationRefreshMediaButton object:nil];
    
    
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
- (IBAction) onButtonShare: (id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestSaveShareViewOnOff object:nil];
}


//
//
- (IBAction) onButtonLoad: (id)sender
{    
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestLoadViewOnOff object:nil];
}

//
//
- (IBAction) onButtonMusic: (id)sender
{    
    
    MPMusicPlayerController * musicPlayer = [MPMusicPlayerController iPodMusicPlayer];  
    if ( musicPlayer &&  musicPlayer.playbackState == MPMusicPlaybackStatePlaying )
    {    
        [musicPlayer stop];
    }
    else
    {    
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestMediaViewOnOff object:nil];
    }
    
    
    
}

#pragma mark private implementation


//
//
- (void) onSaveShareShown
{
    [buttonSaveShare_ setOn: true];
}

//
//
- (void) onSaveShareHidden
{
    [buttonSaveShare_ setOn: false];    
}

//
//
- (void) onLoadShown
{
    [buttonLoad_ setOn: true];
}

//
//
- (void) onLoadHidden
{
    [buttonLoad_ setOn: false];    
}

//
//
- (void) onMediaShown
{
    [buttonMusic_ setOn:true];
}

//
//
- (void) onMediaHidden
{
    [buttonMusic_ setOn:false];   
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRefreshMediaButton object:nil];
}


//
//
- (void) refreshMediaButton
{
    [self doRefreshMediaButton: false];
}

//
//
- (void) doRefreshMediaButton: (bool) bForce
{
    MPMusicPlayerController * musicPlayer = [MPMusicPlayerController iPodMusicPlayer];    
    
    
    if ( musicPlayer && ( musicPlayer.playbackState != musicPlayerState_ || bForce ) )
    {
        switch ( musicPlayer.playbackState )
        {
            case MPMusicPlaybackStatePlaying:
            {
                [buttonMusic_ setImageNamesOn: @"stop_music.png" off: @"stop_music.png"];                                
                break;
            }
                
            default:
            {
                [buttonMusic_ setImageNamesOn: @"pick_song_on.png" off: @"picksong.png"];                                
                break;
            }
        }
        
        musicPlayerState_ = musicPlayer.playbackState;
    }
    
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
