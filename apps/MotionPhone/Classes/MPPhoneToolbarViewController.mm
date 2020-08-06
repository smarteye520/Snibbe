//
//  MPPhoneToolbarViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 1/30/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#import "MPPhoneToolbarViewController.h"
#import "defs.h"
#import "Parameters.h"
#import "MPUIOrientButton.h"
#import "MPFPSViewController.h"
#import "MPRecordViewController.h"
#import "MPUIViewController.h"
#import "MPUIVCInfo.h"
#import "MPUtils.h"


// private interface
@interface MPPhoneToolbarViewController()

- (void) ensureBrushMode;
- (void) updateToolUI;
- (void) updateUIForMPTool: (MotionPhoneTool) tool;

- (void) refreshMediaButton;
- (void) doRefreshMediaButton: (bool) bForce;

// sub-controls
- (void) createFPS;
- (void) destroyFPS;
- (void) onFPSViewOnOff: (float) time;

- (void) createRecord;
- (void) destroyRecord;
- (void) onRecordViewOnOff: (float) time;

// notifications
- (void) onFPSShown;
- (void) onFPSHidden;
- (void) onCanvasTouchDown;

- (void) onMatchBegin;
- (void) onMatchEnd;

@end


@implementation MPPhoneToolbarViewController

//
//
- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ( ( self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil] ) )
    {
        vcInfoFPS_ = nil;
        vcInfoRecord_ = nil;
        fpsController_ = nil;
    }
    
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // setup the on/off images 
    [buttonBrush_ setImageNamesOn: @"brushes_on.png" off:@"brushes_off.png"];
    [buttonColor_ setImageNamesOn: @"color_on.png" off:@"color_off.png"];
    [buttonUndo_ setImageNamesOn: @"undo.png" off:@"undo.png"];
    [buttonTrash_ setImageNamesOn: @"trash.png" off:@"trash.png"];
    
    [buttonFPS_ setImageNamesOn: @"blank_on.png" off:@"blank_off.png"];
    [buttonMusic_ setImageNamesOn: @"music_on.png" off:@"music_off.png"];
    [buttonIAP_ setImageNamesOn: @"purchase_on.png" off:@"purchase_off.png"];
    [buttonHome_ setImageNamesOn: @"home.png" off:@"home.png"];
        
    [buttonHelp_ setImageNamesOn: @"help_on.png" off:@"help_off.png" ];
    [buttonEssay_ setImageNamesOn: @"info_on.png" off:@"info_off.png" ];    
    [buttonPhone_ setImageNamesOn: @"phone_on.png" off:@"phone_off.png"];      
    [buttonRecord_ setImageNamesOn: @"camera_on.png" off:@"camera_off.png"];
    
    //[buttonInfo_ setImageNamesOn: @"info_on.png" off:@"info_off.png"];
    
    [buttonDraw_ setImageNamesOn: @"hand_off.png" off:@"hand_on.png" ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFPSShown) name:gNotificationFPSViewOn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFPSHidden) name:gNotificationFPSViewOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCanvasTouchDown) name:gNotificationCanvasTouchDown object:nil];                        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatchBegin) name:gNotificationBeginMatch object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatchEnd) name:gNotificationEndMatch object:nil];
    
    
    // until we support IAP, shuffle icons around to plug the hole
    // made by the missing button
    
    buttonIAP_.hidden = true;
    buttonRecord_.center = buttonPhone_.center;
    buttonPhone_.center = buttonIAP_.center;
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMinFrameTimeChanged) name:gNotificationMinFrameTimeChanged object:nil];                
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateToolUI) name:gNotificationToolModeChanged object:nil];    
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMediaButton) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMediaButton) name:gNotificationRefreshMediaButton object:nil];
    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBGColorChanged) name:gNotificationBGColorChanged object:nil];                
    
    vcInfoFPS_ = [[MPUIVCInfo alloc] initWithCreate: @selector(createFPS) destroy: @selector(destroyFPS) vc: &fpsController_ active: false ];    
    vcInfoRecord_ = [[MPUIVCInfo alloc] initWithCreate: @selector(createRecord) destroy: @selector(destroyRecord) vc: &recordController_ active: false ];    
        
    [self doRefreshMediaButton: true];
    
    [MPUtils updateFPSIndicator: buttonFPS_];
    [self updateUIForMPTool: gParams->tool() ];
    
    // update the view bg color
    [self onBGColorChanged];
    
}


- (void)viewDidUnload
{
    [vcInfoFPS_ release];
    vcInfoFPS_ = nil;
    
    
    [self destroyFPS];
 
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


//
//
- (void) viewWillAppear:(BOOL)animated
{
    [self refreshMediaButton];
}

#pragma mark UI Actions


//
//
- (IBAction) onBrushButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestBrushViewOnOff object:nil];
    [self ensureBrushMode];
}


//
//
- (IBAction) onColorButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestColorViewOnOff object:nil];
    [self ensureBrushMode];
}

//
//
- (IBAction) onUndoButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestUndo object:nil];
    [self ensureBrushMode];
}


//
//
- (IBAction) onTrashButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestEraseCanvas object:nil];    
    [self ensureBrushMode];
}


//
//
- (IBAction) onFPSButton:(id)sender
{    
    [self onFPSViewOnOff: TOOLBAR_ANIMATION_TIME_PHONE];
    [self ensureBrushMode];
}


//
//
- (IBAction) onMusicButton:(id)sender
{    
    MPMusicPlayerController * musicPlayer = [MPMusicPlayerController iPodMusicPlayer];  
    if ( musicPlayer &&  musicPlayer.playbackState == MPMusicPlaybackStatePlaying )
    {    
        [musicPlayer stop];
        [self refreshMediaButton]; // we should be getting a media player notification making this call unnecessary, but it's not happening
    }
    else
    {    
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestMediaViewOnOff object:nil];
    }
    
    [self ensureBrushMode];
}


//
//
- (IBAction) onIAPButton:(id)sender
{    
    //[[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestFPSViewOnOff object:nil];
    [self ensureBrushMode];
}

//
//
- (IBAction) onHomeButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestGoHome object:nil];
    [self ensureBrushMode];
}


//
// one invisible button to toggle between move and draw
- (IBAction) onButtonMoveDrawToggle:(id)sender
{
    MotionPhoneTool newTool = ( gParams->tool() == MotionPhoneTool_Hand ? MotionPhoneTool_Brush : MotionPhoneTool_Hand );        
    gParams->setTool( newTool);    
    
}



//
//
- (IBAction) onButtonHelp: (id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestHelpViewOnOff object:nil];
    [self ensureBrushMode];
}

//
//
- (IBAction) onButtonEssay: (id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestEssayViewOnOff object:nil];
    [self ensureBrushMode];
}

//
//
- (IBAction) onPhoneButton:(id)sender
{                    
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationMultiplayerButtonPressed object:nil];    
    [self ensureBrushMode];
}

//
//
- (IBAction) onRecordButton:(id)sender
{
    [self onRecordViewOnOff: TOOLBAR_ANIMATION_TIME_PHONE];
    [self ensureBrushMode];
}







#pragma mark private interface

//
//
- (void) ensureBrushMode
{
    if ( gParams->tool() == MotionPhoneTool_Hand )
    {
        gParams->setTool( MotionPhoneTool_Brush );
    }
}

//
//
- (void) hideSubControls: (float) time
{
    if ( fpsController_ && fpsController_.bActive_ )
    {
        [self onFPSViewOnOff: time];
    }
    
    if ( recordController_ && recordController_.bActive_ )
    {
        [self onRecordViewOnOff: time];
    }
}

//
//
- (void) onMinFrameTimeChanged
{
    [MPUtils updateFPSIndicator: buttonFPS_];
}

//
//
- (void) onBGColorChanged
{ 
    [self updateViewBackground: viewBottomBar_];
    [self updateViewBackground: viewTopBar_];
}

//
//
- (void) updateToolUI
{
    [self updateUIForMPTool: gParams->tool()];
}


//
//
- (void) updateUIForMPTool: (MotionPhoneTool) tool
{
    if ( tool == MotionPhoneTool_Hand )
    {
        // brush (confusing image/enum naming...)
        [imageViewMPTool_ setImage: [UIImage imageNamed: @"long_pill_bottom.png"]];        
        [buttonDraw_ setOn: true];
    }
    else
    {        
        [imageViewMPTool_ setImage: [UIImage imageNamed: @"long_pill_top.png"]];
        [buttonDraw_ setOn: false];                
    }
}


//
//
- (void) refreshMediaDelayed
{
    [self doRefreshMediaButton: false];
}

//
//
- (void) refreshMediaButton
{
#ifdef MOTION_PHONE_MOBILE
    // phone needs this delay
    [self performSelector:@selector(refreshMediaDelayed) withObject:nil afterDelay:.1f];
#else
    [self doRefreshMediaButton: false];
#endif
}

//
//
- (void) doRefreshMediaButton: (bool) bForce
{
    MPMusicPlayerController * musicPlayer = [MPMusicPlayerController iPodMusicPlayer];    
    
    //NSLog( @"called\n" );
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
        //NSLog( @"state: %d\n", musicPlayerState_ );
    }
    
}


#pragma mark sub-controls

//
//
- (void) createFPS
{
    if ( !fpsController_ )
    {
        fpsController_ = [[MPFPSViewController alloc] initWithNibName:@"MPFPSViewController" bundle:nil];
        
        [self.view addSubview: fpsController_.view];

        // position it
        fpsController_.view.center = buttonFPS_.center;
        fpsController_.view.frame = CGRectMake(fpsController_.view.frame.origin.x, 126.0f, fpsController_.view.frame.size.width, fpsController_.view.frame.size.height );                
        
        fpsController_.notifyOn_ = gNotificationFPSViewOn;
        fpsController_.notifyOff_ = gNotificationFPSViewOff;
        
    }
}


- (void) destroyFPS;
{
    if ( fpsController_ )
    {
        [fpsController_.view removeFromSuperview];
        [fpsController_ release];
        fpsController_ = nil;
    }
}


//
// special case here b/c of need to set global params
//
// most code here duped from iPad version
- (void) onFPSViewOnOff: (float) time
{
    
    if ( !fpsController_ )
    {
        [self createFPS];
    }    
    
    [fpsController_ toggleActive];    
    [fpsController_ show:fpsController_.bActive_ withAnimation:true time:time fullOpacity:TOOLBAR_FULL_OPACITY forceUpdate:false];                                     
    
    
    if ( fpsController_.bActive_ )
    {
        gParams->setFPSShown( true );
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationFPSViewOn object:nil];        
        
    }
    else
    {
        gParams->setFPSShown( false );
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationFPSViewOff object:nil];        
    }
        
    if ( fpsController_.bActive_ )
    {
        [vcInfoFPS_ onShowBegin];
    }
    else
    {
        [vcInfoFPS_ onHideBeginWithTime: TOOLBAR_ANIMATION_TIME_PHONE];
    }
    
    [buttonFPS_ setOn:fpsController_.bActive_];
    
}

//
//
- (void) createRecord
{
    if ( !recordController_ )
    {
        recordController_ = [[MPRecordViewController alloc] initWithNibName:@"MPRecordViewController" bundle:nil];
        
        [self.view addSubview: recordController_.view];
        
        // position it
        recordController_.view.center = buttonRecord_.center;
        
        
        recordController_.view.frame = CGRectMake( recordController_.view.frame.origin.x + 1, // +1 to prevent artifact b/c of closeness to edge of screen 
                                                   self.view.frame.size.height - viewBottomBar_.frame.size.height - recordController_.view.frame.size.height, 
                                                   recordController_.view.frame.size.width, 
                                                   recordController_.view.frame.size.height );                
        
        recordController_.notifyOn_ = gNotificationRecordViewOn;
        recordController_.notifyOff_ = gNotificationRecordViewOff;
        
    }

}

//
//
- (void) destroyRecord
{
    if ( recordController_ )
    {
        [recordController_.view removeFromSuperview];
        [recordController_ release];
        recordController_ = nil;
    }
}

//
// this could be generalized to a common method if we ever have any additional sub-views
- (void) onRecordViewOnOff: (float) time
{    
    if ( !recordController_ )
    {
        [self createRecord];
    }    
    
    [recordController_ toggleActive];    
    [recordController_ show:recordController_.bActive_ withAnimation:true time:time fullOpacity:TOOLBAR_FULL_OPACITY forceUpdate:false];                                     
    
    
    if ( recordController_.bActive_ )
    {
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRecordViewOn object:nil];        
        
    }
    else
    {        
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRecordViewOff object:nil];        
    }
    
    if ( recordController_.bActive_ )
    {
        [vcInfoRecord_ onShowBegin];
    }
    else
    {
        [vcInfoRecord_ onHideBeginWithTime: TOOLBAR_ANIMATION_TIME_PHONE];
    }
    
    [buttonRecord_ setOn:recordController_.bActive_];

}


#pragma mark notification

//
//
- (void) onFPSShown
{
    [buttonFPS_ setOn: true];
    [MPUtils updateFPSIndicator: buttonFPS_];
}

//
//
- (void) onFPSHidden
{
    [buttonFPS_ setOn: false];    
    [MPUtils updateFPSIndicator: buttonFPS_];
}


//
//
- (void) onCanvasTouchDown
{
    
    if ( gParams->drawingHidesUI() )
    {        
        [self hideSubControls: 0.0f];                
    }
    
}

- (void) onMatchBegin
{
    [buttonPhone_ setOn: true];
}

- (void) onMatchEnd
{
    [buttonPhone_ setOn: false];
}



@end
