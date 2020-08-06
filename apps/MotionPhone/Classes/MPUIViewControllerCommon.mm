//
//  MPUIViewControllerCommon.m
//  MotionPhone
//
//  Created by Graham McDermott on 1/31/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#import "MPUIViewControllerCommon.h"
#import "MPGradientController.h"
#import <QuartzCore/QuartzCore.h>
#import "MPNetworkManager.h"
#import "Parameters.h"
#import "MPUIOrientButton.h"

#import "defs.h"



@implementation MPUIViewControllerCommon

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

    [playerLabels_ release];
    [gradientController_ release];
    
    [super dealloc];

}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startShowingPendingAnimation) name:gNotificationPendingBegin object:nil];        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopShowingPendingAnimation) name:gNotificationPendingEnd object:nil];        
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startShowingGradient) name:gNotificationShowFixedBlockingGradient object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopShowingGradient) name:gNotificationHideFixedBlockingGradient object:nil];        
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( onLabelUpdateEvent ) name:gNotificationGlobalOrientationChanged object:nil];            
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( onMatchPlayersChanged ) name:gNotificationMatchPlayersChanged object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( onLabelUpdateEvent ) name:gNotificationToolbarHidden object:nil];        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( onLabelUpdateEvent ) name:gNotificationToolbarShown object:nil];            
    
    
    imageViewBusy_ = nil;
    
    
    gradientController_ = [[MPGradientController alloc] initWithNibName:nil bundle:nil];
    
    [self setPlayerLabelText: @"" playerNum: 0];
    [self setPlayerLabelText: @"" playerNum: 1];
    [self setPlayerLabelText: @"" playerNum: 2];
    [self setPlayerLabelText: @"" playerNum: 3];
    
    playerLabels_ = [[NSMutableArray alloc] initWithObjects: labelPlayer1_, labelPlayer2_, labelPlayer3_, labelPlayer4_, nil];
    
    
    for ( UILabel *curLabel in playerLabels_ )
    {
        curLabel.hidden = true;
        curLabel.alpha = 0.0f;
        curLabel.center = CGPointMake(4000, 4000);
    }
    
        
    [buttonShowToolbar_ setImageNamesOn: @"symbol_on.png" off: @"symbol_off.png"];    
    
    [super viewDidLoad];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


//
//
- (void) ensureBrushMode
{
    if ( gParams->tool() == MotionPhoneTool_Hand )
    {
        gParams->setTool( MotionPhoneTool_Brush );
    }
}


#pragma mark player labels

//
// helper
- (void) rotatePlayerLabels: (float) angle
{
    labelPlayer1_.transform = CGAffineTransformMakeRotation( angle );
    labelPlayer2_.transform = CGAffineTransformMakeRotation( angle );
    labelPlayer3_.transform = CGAffineTransformMakeRotation( angle );
    labelPlayer4_.transform = CGAffineTransformMakeRotation( angle );
}

//
// helper
- (void) alignPlayerLabels: (UITextAlignment) align
{
    labelPlayer1_.textAlignment = align;
    labelPlayer2_.textAlignment = align;
    labelPlayer3_.textAlignment = align;
    labelPlayer4_.textAlignment = align;
}

//
//
- (void) positionPlayerLabels
{
    CGRect f = self.view.frame;
    float width = MIN( f.size.width, f.size.height );
    //float height = MAX( f.size.width, f.size.height );
    
    
    float sideMargin = 15.0f;
    
#ifdef MOTION_PHONE_MOBILE
    bool bToolbar = gParams->toolbarShown();
    float phoneToolbarTopHeight = 126.0f;
#endif
    
    CGSize lSize = CGSizeMake( MAX( labelPlayer1_.frame.size.height, labelPlayer1_.frame.size.width ), MIN( labelPlayer1_.frame.size.height, labelPlayer1_.frame.size.width ) );
    
    float angle = 0.0f;
    
    float vert1 = 18.0f;
    float vert2 = 48.0f;
    float vert3 = 78.0f;
    float vert4 = 108.0f;
    

#ifdef MOTION_PHONE_MOBILE   

    vert1 = 5.0f;
    vert2 = 30.0f;
    vert3 = 55.0f;
    vert4 = 80.0f;
    
#endif
    
    float labelShift = 0.0f;
    
#ifdef MOTION_PHONE_MOBILE              
    // if the toolbar is visible on the phone, shift the labels out of the way
    labelShift = bToolbar ? phoneToolbarTopHeight : 0.0f;
#endif
    
    switch (gDeviceOrientation) 
    {
        case UIDeviceOrientationPortraitUpsideDown:
        {
            angle = DEGREES_TO_RADIANS * 180.0f;
            [self rotatePlayerLabels: angle];            
            [self alignPlayerLabels: UITextAlignmentRight];       
            
            labelPlayer1_.frame = CGRectMake( sideMargin, vert1 + labelShift, lSize.width, lSize.height ); 
            labelPlayer2_.frame = CGRectMake( sideMargin, vert2 + labelShift, lSize.width, lSize.height ); 
            labelPlayer3_.frame = CGRectMake( sideMargin, vert3 + labelShift, lSize.width, lSize.height ); 
            labelPlayer4_.frame = CGRectMake( sideMargin, vert4 + labelShift, lSize.width, lSize.height ); 
            
            break;
        }
        case UIDeviceOrientationLandscapeLeft:
        {   
            
            angle = DEGREES_TO_RADIANS * 90.0f;
            [self rotatePlayerLabels: angle];
            [self alignPlayerLabels: UITextAlignmentLeft];
            
            labelPlayer1_.frame = CGRectMake( width - vert1 - lSize.height, sideMargin + labelShift, lSize.height, lSize.width ); 
            labelPlayer2_.frame = CGRectMake( width - vert2 - lSize.height, sideMargin + labelShift, lSize.height, lSize.width ); 
            labelPlayer3_.frame = CGRectMake( width - vert3 - lSize.height, sideMargin + labelShift, lSize.height, lSize.width ); 
            labelPlayer4_.frame = CGRectMake( width - vert4 - lSize.height, sideMargin + labelShift, lSize.height, lSize.width ); 
            
            break;
        }
        case UIDeviceOrientationLandscapeRight:
        {
            angle = DEGREES_TO_RADIANS * -90.0f;
            [self rotatePlayerLabels: angle];
            [self alignPlayerLabels: UITextAlignmentRight];
            
            labelPlayer1_.frame = CGRectMake( vert1, sideMargin + labelShift, lSize.height, lSize.width ); 
            labelPlayer2_.frame = CGRectMake( vert2, sideMargin + labelShift, lSize.height, lSize.width ); 
            labelPlayer3_.frame = CGRectMake( vert3, sideMargin + labelShift, lSize.height, lSize.width ); 
            labelPlayer4_.frame = CGRectMake( vert4, sideMargin + labelShift, lSize.height, lSize.width ); 
            
            break;
        }
        default:
        case UIDeviceOrientationPortrait:
        {
            
            angle = DEGREES_TO_RADIANS * 0.0f;
            [self rotatePlayerLabels: angle];            
            [self alignPlayerLabels: UITextAlignmentRight];
            
            labelPlayer1_.frame = CGRectMake( width - lSize.width - sideMargin, vert1 + labelShift, lSize.width, lSize.height ); 
            labelPlayer2_.frame = CGRectMake( width - lSize.width - sideMargin, vert2 + labelShift, lSize.width, lSize.height ); 
            labelPlayer3_.frame = CGRectMake( width - lSize.width - sideMargin, vert3 + labelShift, lSize.width, lSize.height ); 
            labelPlayer4_.frame = CGRectMake( width - lSize.width - sideMargin, vert4 + labelShift, lSize.width, lSize.height ); 
            
            break;
        }
            
    }
    
    
    
    
    // ok, they're in the correct place... but for any players that aren't currently in the
    // match, let's put the labels far offscreen
    int iNumPlayers = [[MPNetworkManager man] numPlayersInMatch];
    int iNumLabels = [playerLabels_ count];
    for ( int iLabel = 0; iLabel < iNumLabels; ++iLabel )
    {
        if ( iLabel >= iNumPlayers )
        {
            UILabel * curLabel = [playerLabels_ objectAtIndex:iLabel];
            curLabel.center = CGPointMake(4000, 4000);
        }
    }
     
    
    
}


//
//
- (void) setPlayerLabelText: ( NSString * ) text playerNum: (int) iNum
{
    UILabel * label = nil;
    
    switch (iNum)
    {
        case 0:            
            label = labelPlayer1_;
            break;
        case 1: 
            label = labelPlayer2_;
            break;
        case 2: 
            label = labelPlayer3_;
            break;
        case 3:
            label = labelPlayer4_;
            break;                                    
        default:
            break;
    }
    
    if ( label )
    {
        
        
        
        if ( [text length] == 0 )
        {
            label.text = text;
        }
        else
        {        
            label.text = [text uppercaseString];             
            label.shadowColor = [UIColor blackColor];
            label.shadowOffset = CGSizeMake(0, 1);
            
        }
        
    }
}

//
//
- (void) onMatchPlayersChanged
{
    [self updatePlayerLabels];
}


//
//
- (void) completeUpdatePlayerLabels
{
    
    // show them
    [UIView beginAnimations: @"player labels restore" context:nil];
    [UIView setAnimationDuration: PLAYER_LABEL_FADE_TIME];
    [UIView setAnimationBeginsFromCurrentState: true];
    
    labelPlayer1_.alpha = 1.0f;
    labelPlayer2_.alpha = 1.0f;
    labelPlayer3_.alpha = 1.0f;
    labelPlayer4_.alpha = 1.0f;
    
    [UIView commitAnimations];
}

//
//
- (void) doUpdatePlayerLabels
{
    
    
    
    // update with the current player aliases
    
    int iNumPlayers = [[MPNetworkManager man] numPlayersInMatch];
    
    //NSLog( @"num players: %d\n", iNumPlayers );
    
    for ( int i = 0; i < [playerLabels_ count]; ++i )
    {
        UILabel * curLabel = [playerLabels_ objectAtIndex: i];
        if ( i < iNumPlayers )
        {
            curLabel.hidden = false;
            [self setPlayerLabelText: [[MPNetworkManager man] playerAlias: i] playerNum:i];
        }
        else
        {
            curLabel.hidden = true;
            curLabel.text = @"";
            
            // for debugging
            //curLabel.hidden = false;
            //[self setPlayerLabelText: [NSString stringWithFormat: @"PLAYER NUM: %d", i] playerNum:i];
            
        }
    }
     
    
    [self positionPlayerLabels];
    
    
}

//
//
- (void) updatePlayerLabels
{
    
    
#if USE_MULTIPLAYER_LABELS
    
    //NSLog( @"updating player labels...\n" );
    
    float fadetime = PLAYER_LABEL_FADE_TIME;
    
#ifdef MOTION_PHONE_MOBILE   
    fadetime = .2f;    // faster fadeouton the phone
#endif
    
    // hide them
    [UIView beginAnimations: @"player labels update" context:nil];
    [UIView setAnimationDuration: fadetime];
    [UIView setAnimationBeginsFromCurrentState: true];
    
    labelPlayer1_.alpha = 0.0f;
    labelPlayer2_.alpha = 0.0f;
    labelPlayer3_.alpha = 0.0f;
    labelPlayer4_.alpha = 0.0f;
    
    [UIView commitAnimations];
    
    [self performSelector: @selector(doUpdatePlayerLabels) withObject:nil afterDelay: fadetime];
    [self performSelector: @selector(completeUpdatePlayerLabels) withObject:nil afterDelay: fadetime + .1];
    
#else
    
    // do nothing
    
#endif
    
}

//
//
- (void) onLabelUpdateEvent
{
    
    if ( [[MPNetworkManager man] multiplayerSessionActive] || [[MPNetworkManager man] multiplayerSessionPending] )
    {
        [self updatePlayerLabels];
    }
    
}

#pragma mark pending anim

//
// shart showing a "busy" animation on top of the main view
- (void) startShowingPendingAnimation
{
    
    
    if ( !imageViewBusy_ )
    {
        
        //[self bringViewToFront];
        
        
        //SSLog(@"starting pending anim\n" );
        
        UIImage * imageForView = [UIImage imageNamed: @"wait.png"]; 
        imageViewBusy_ = [[UIImageView alloc] initWithImage: imageForView];        
                
        UIView * parentView = self.view;
                
        imageViewBusy_.center = parentView.center;         
        
        imageViewBusy_.hidden = false;
        imageViewBusy_.alpha = 0.0f;
        
        // fade it in
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration: PENDING_ANIM_FADE_TIME];
        imageViewBusy_.alpha = 1.0f;        
        //imageViewGradientPending_.alpha = 1.0f;
        [UIView commitAnimations];
        
        // rotate it                
        CABasicAnimation* spinAnimation = [CABasicAnimation
                                           animationWithKeyPath:@"transform.rotation"];        
        const int numRotations = 99999;        
        spinAnimation.toValue = [NSNumber numberWithFloat: numRotations * -2 * M_PI];
        spinAnimation.duration = PENDING_ANIM_ROTATE_TIME * numRotations;
        [imageViewBusy_.layer addAnimation:spinAnimation forKey:@"spinAnimation"];
        
        
        // fade in and add the gradient view to block touches and darken screen
        
        [self.view addSubview: gradientController_.view];
        [gradientController_ startShowingGradient: PENDING_ANIM_FADE_TIME];        
        [self.view bringSubviewToFront: gradientController_.view];
        
        
        [self.view addSubview: imageViewBusy_];
        //[self.view addSubview: imageViewGradientPending_];
        //[self.view bringSubviewToFront: imageViewGradientPending_];
        [self.view bringSubviewToFront: imageViewBusy_];        
        
        
        
    }
}


//
//
- (void) doStopShowingPendingAnim
{
    [imageViewBusy_ removeFromSuperview];
    [imageViewBusy_ release];
    imageViewBusy_ = nil;
    
    //[imageViewGradientPending_ removeFromSuperview]; // don't release this one - we reuse it
    
    //imageViewGradientPending_.exclusiveTouch = false;
    //[self sendViewToBack];
    
    [gradientController_.view removeFromSuperview];
}


//
// stop showing a "busy" animation on top of the main view
- (void) stopShowingPendingAnimation
{
    
    
    if ( imageViewBusy_ )
    {
        //SSLog(@"stopping pending anim\n" );
        
        // fade it out
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration: PENDING_ANIM_FADE_TIME];
        
        imageViewBusy_.alpha = 0.01f;
        //imageViewGradientPending_.alpha = 0.01f;
        
        [UIView commitAnimations];
        
        
        [gradientController_ stopShowingGradient: PENDING_ANIM_FADE_TIME];
        
        [self performSelector: @selector(doStopShowingPendingAnim) withObject:nil afterDelay:PENDING_ANIM_FADE_TIME];
    }
    
}



#pragma mark gradient functions

//
//
- (void) startShowingGradient
{
    // fade in and add the gradient view to block touches and darken screen
    
    
    UIView * parentView = self.view;    
    
    if ( [gradientController_.view superview] != parentView )
    {
        [parentView addSubview: gradientController_.view];
        [gradientController_ startShowingGradient: PENDING_ANIM_FADE_TIME];        
        [parentView bringSubviewToFront: gradientController_.view];
    }
    
    
}

//
//
- (void) doStopShowingGradient
{
    
    [gradientController_.view removeFromSuperview];
    
}

//
//
- (void) stopShowingGradient
{
    UIView * parentView = self.view;    

    
    if ( [gradientController_.view superview] == parentView )
    {
        [gradientController_ stopShowingGradient: PENDING_ANIM_FADE_TIME];    
        [self performSelector: @selector(doStopShowingGradient) withObject:nil afterDelay:PENDING_ANIM_FADE_TIME];
    }
    
}


@end
