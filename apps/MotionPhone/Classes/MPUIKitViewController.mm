//
//  MPUIKitViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIKitViewController.h"
#import "MPNetworkManager.h"
#import "defs.h"
#include "QuartzCore/CAAnimation.h"
#include "UIOrientButton.h"
#import "SnibbeUtils.h"


#define ALERT_VIEW_DISCONNECT_TAG 701
#define GRADIENT_SHOW_DURATION 0.5f
#define ORIENT_RESIZE_DURATION 0.5f
#define UI_END_DELAY_MULTIPLAYER_PHONE 0.5f

NSString * keyVC = @"vc";
NSString * keyFullscreen = @"fc";


static MPUIKitViewController * theUIKitController_ = 0; // singleton

// private interface

@interface MPUIKitViewController()

// notification responders
- (void) onMultiPlayerButtonPressed;
- (void) onFinalizeMultiplayerInit;
- (void) onMatchBegin;
- (void) onUnableToBeginMatch;
- (void) onOrientationChanged;

- (void) installInvitationHandler;
- (void) initiateMatchMaker;

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;  // after animation

- (void) bringViewToFront;
- (void) sendViewToBack;

- (void) positionModalVCs;
- (void) doOrientChanged: (bool) bForce;
- (void) doOrientChanged;



#if USE_GAMECENTER

// GKMatchMakerViewControllerDelegate methods

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController;
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error;
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match;
//- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindPlayers:(NSArray *)playerIDs;
//- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didReceiveAcceptFromHostedPlayer:(NSString *)playerID __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0);

#else

// GKPeerPickerControllerDelegate methods


// - (void)peerPickerController:(GKPeerPickerController *)picker didSelectConnectionType:(GKPeerPickerConnectionType)type;
// - (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type;

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session;
- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker;


#endif


// UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

// MPOrientingUIKitParent methods
- (void) onViewControllerRequestDismissal: (UIViewController *) vc;


@end

@implementation MPUIKitViewController

@synthesize matchMakerDelegate_;

#pragma mark class methods


// assign, doesn't retain. just for one point of access from different
// parts of the code
+ (void) setUIKitViewController: (MPUIKitViewController *) vc
{
    theUIKitController_ = vc;
}


// for one point of access from different
// parts of the code
+ (MPUIKitViewController *) getUIKitViewController
{
    return theUIKitController_;
}


#pragma mark implementation

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
           
        //curOrientation_ = UIDeviceOrientationUnknown;
        
        // create view        
        UIView * controllerMainView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];        
        self.view = controllerMainView;                
        controllerMainView.userInteractionEnabled = true;
        
        orientationLast_ = UIDeviceOrientationUnknown;
        arrayModalVC_ = [[NSMutableArray alloc] init];
        self.matchMakerDelegate_ = nil;
        
        [controllerMainView release];
        
        // notifications
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMultiPlayerButtonPressed) name:gNotificationMultiplayerButtonPressed object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFinalizeMultiplayerInit) name:gNotificationFinalizeMultiplayerInit object:nil];        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatchBegin) name:gNotificationBeginMatch object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUnableToBeginMatch) name:gNotificationUnableToBeginMatch object:nil];        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationChanged) name:UIDeviceOrientationDidChangeNotification object:nil];        

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUIBegin) name:gNotificationShowBlockingGradient object:nil];        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUIEnd) name:gNotificationHideBlockingGradient object:nil];        
        
        
        
        validDeviceOrientFound_ = false;
        
        
        UIImage * imageGradient = [UIImage imageNamed: @"square_gradient.png"];
        imageViewGradient_ = [[[UIImageView alloc] initWithImage: imageGradient] retain];        
        
        float portraitWidth = [[UIScreen mainScreen] bounds].size.width;
        float portraitHeight = [[UIScreen mainScreen] bounds].size.height;
        
        self.view.frame = CGRectMake(0, 0, portraitWidth, portraitHeight);
        imageViewGradient_.frame = self.view.frame;
        
        imageViewGradient_.hidden = true;
        imageViewGradient_.alpha = 0.0f;
            
        
#if PEER_2_PEER        
        peerPickerController_ = nil;
#endif
        
        
        [self doOrientChanged];
        
    }
    return self;
}

//
//
- (void) dealloc
{
    
#if PEER_2_PEER        
    if ( peerPickerController_ )
    {    
        [peerPickerController_ release];
        peerPickerController_ = nil;        
    }
#endif

    
    [imageViewGradient_ release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [arrayModalVC_ release];
    
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
    
    self.view.autoresizesSubviews = YES;
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];   
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{        
    
#ifdef PERFORMANCE_MODE
    return interfaceOrientation == UIInterfaceOrientationPortrait;
#else    
    return UIDeviceOrientationIsValidInterfaceOrientation( interfaceOrientation );    
#endif
    
    
}




//
//
- (void) onUIBegin
{

    
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector(completeUIEnd) object:nil];
    
    imageViewGradient_.alpha = 0.0f;
    imageViewGradient_.hidden = false;
    
    [self.view addSubview: imageViewGradient_];
    
#ifdef MOTION_PHONE_MOBILE
    // on mobile we want the gradient behind everything (if there at all)
    [self.view sendSubviewToBack: imageViewGradient_];
#else
    // on iPad it's fine if it's in front
    [self.view bringSubviewToFront: imageViewGradient_];
#endif
    
    [self bringViewToFront];
    
    [UIView beginAnimations: @"show gradient" context:nil];
    
    [UIView setAnimationBeginsFromCurrentState:YES];    
    [UIView setAnimationDuration: GRADIENT_SHOW_DURATION];

    imageViewGradient_.alpha = 1.0f;
    [UIView commitAnimations];
    
    [self doOrientChanged: true];
}

//
//
- (void) completeUIEnd
{
    [self sendViewToBack];
    imageViewGradient_.hidden = true;
    
    [imageViewGradient_ removeFromSuperview];
        
}

//
//
- (void) onUIEnd
{
 

    

    [UIView beginAnimations: @"hide gradient" context:nil];    
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration: GRADIENT_SHOW_DURATION];
    imageViewGradient_.alpha = 0.0f;
    [UIView commitAnimations];
    
    [self performSelector: @selector(completeUIEnd) withObject:nil afterDelay:GRADIENT_SHOW_DURATION];
    
}


//
//
- (void) showVCAsModal: (UIViewController *) vc fullscreen: (bool) bFullscreen
{
    
 
    // this needs to have this method to work
    if ( [vc respondsToSelector: @selector( setOrientingParentDelegate_: )] )
    {
        [vc performSelector:@selector( setOrientingParentDelegate_: ) withObject:self];
    }
            
    
    if ( bFullscreen )
    {
        
        float portraitWidth = [[UIScreen mainScreen] bounds].size.width;
        float portraitHeight = [[UIScreen mainScreen] bounds].size.height;
        
        float longDim = MAX( portraitWidth, portraitHeight );
        float shortDim = MIN( portraitWidth, portraitHeight );
        
        if ( UIDeviceOrientationIsLandscape( gDeviceOrientation ) )
        {        
            vc.view.frame = CGRectMake( 0, 0, longDim, shortDim );
        }
        else
        {
            vc.view.frame = CGRectMake( 0, 0, shortDim, longDim );
        }
                        
    }
    
    [self.view addSubview: vc.view];
    
    // store a dictionary in the modal vc array so we can tack on additional info
    NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys: vc, keyVC, [NSNumber numberWithBool: bFullscreen], keyFullscreen, nil];
    
    [arrayModalVC_ addObject: dict];        
    
    [self positionModalVCs];
    
    [self onUIBegin];
}


///////////////////////////////////////////////////////////////////////////////////////
// private implementation
///////////////////////////////////////////////////////////////////////////////////////
#pragma mark private implementation





//
//
- (void) onMultiPlayerButtonPressed
{
    
    
    
    if ( ![MPNetworkManager gameKitAvailable] )
    {
        UIAlertView * notAvail = [[[UIAlertView alloc] initWithTitle:@"Multiplayer not supported" message:@"Please update to the latest version of iOS to enable multiplayer support" delegate:self cancelButtonTitle: @"OK" otherButtonTitles:nil] autorelease];        
        [notAvail show];
        return;
    }
    

    if ( [[MPNetworkManager man] multiplayerSessionActive] )
    {
     
        // todo - offer to cancel (maybe change icon while session is active to cancel?)
        
        UIAlertView * alertCancelRequest = [[UIAlertView alloc] initWithTitle:@"Disconnect?" message:@"Would you like to disconnect from the shared canvas?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: @"Disconnect", nil];
                    
        alertCancelRequest.tag = ALERT_VIEW_DISCONNECT_TAG;
        
        [alertCancelRequest show];
        [alertCancelRequest release];
        
        
    }
    else if ( [[MPNetworkManager man] multiplayerSessionPending] )
    {
        // nothing...
    }
    else
    {
        [self initiateMatchMaker];
    }
        
}

//
//
- (void) onFinalizeMultiplayerInit
{
    [self installInvitationHandler];
}

//
//
- (void) onMatchBegin
{
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationPendingEnd object:nil];    
}

//
//
- (void) onUnableToBeginMatch
{
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationPendingEnd object:nil];    
}

//
//
- (void) doOrientChanged: (bool) bForce
{
 
    UIDeviceOrientation orient = gDeviceOrientation;
    
    if ( orient != orientationLast_  || bForce )
    {
        
        orientationLast_ = orient;
        
        // resize everything!
        float portraitWidth = [[UIScreen mainScreen] bounds].size.width;
        float portraitHeight = [[UIScreen mainScreen] bounds].size.height;
        
        
        
        [UIView beginAnimations: @"orient view changes" context:nil];        
        [UIView setAnimationDuration: ORIENT_RESIZE_DURATION];
                                
        [self positionModalVCs];
        
        if ( UIDeviceOrientationIsLandscape( orient ) )
        {        
            
            imageViewGradient_.frame = CGRectMake(0.0, 0.0, portraitHeight, portraitWidth );                 
        }
        else
        {
            imageViewGradient_.frame = CGRectMake(0.0, 0.0, portraitWidth, portraitHeight);     
        }
        
        
        
        [UIView commitAnimations];
        
        
    }
}
//
//
- (void) doOrientChanged
{
    [self doOrientChanged: false];      
}

//
//
- (void) onOrientationChanged;
{
    [self performSelector: @selector( doOrientChanged ) withObject:nil afterDelay:.10f];
    
    
}

//
//
- (void) positionModalVCs
{
    
    
    float portraitWidth = [[UIScreen mainScreen] bounds].size.width;
    float portraitHeight = [[UIScreen mainScreen] bounds].size.height;
    
    for ( NSDictionary * curDict in arrayModalVC_ )
    {
        
        UIViewController * curVC = [curDict objectForKey: keyVC];
        bool bFullscreen = [[curDict objectForKey: keyFullscreen] boolValue];
        
        if ( !bFullscreen )
        {
                    
            float w = curVC.view.frame.size.width;
            float h = curVC.view.frame.size.height;
                        
            if ( UIDeviceOrientationIsPortrait( orientationLast_ ) )
            {   
                curVC.view.frame = CGRectMake( portraitWidth * 0.5f - w * 0.5f, portraitHeight * 0.5f - h * 0.5f, w, h );
            }
            else
            {
                curVC.view.frame = CGRectMake( portraitHeight * 0.5f - w * 0.5f, portraitWidth * 0.5f - h * 0.5f, w, h );                
            }
        }
    }
    
}

// 
// invitation-initiated match request handling
- (void) installInvitationHandler
{
    
#if USE_GAMECENTER
    
    if ( [MPNetworkManager gameKitAvailable] )
    {
        
        [GKMatchmaker sharedMatchmaker].inviteHandler = ^(GKInvite *acceptedInvite, NSArray *playersToInvite) 
        {
            
            [[MPNetworkManager man] disconnectFromMatch: false];
            
            if (acceptedInvite)
            {
                GKMatchmakerViewController *mmvc = [[[GKMatchmakerViewController alloc] initWithInvite:acceptedInvite] autorelease];
                mmvc.matchmakerDelegate = self;
                
#ifdef MOTION_PHONE_MOBILE
                // on the phone, presenting the modal controller doesn't work unless the view is in front
                [self onUIBegin];
#endif
                
                [self presentModalViewController:mmvc animated:YES];
            }
            else if (playersToInvite)
            {
                GKMatchRequest *request = [[[GKMatchRequest alloc] init] autorelease];
                request.minPlayers = MULTIPLAYER_NUM_PLAYERS_MIN;
                request.maxPlayers = MULTIPLAYER_NUM_PLAYERS_MAX;
                request.playersToInvite = playersToInvite;
                
                GKMatchmakerViewController *mmvc = [[[GKMatchmakerViewController alloc] initWithMatchRequest:request] autorelease];
                mmvc.matchmakerDelegate = self;
                
#ifdef MOTION_PHONE_MOBILE
                // on the phone, presenting the modal controller doesn't work unless the view is in front
                [self onUIBegin];
#endif
                
                [self presentModalViewController:mmvc animated:YES];
            }
        };
        
    }   
    
#endif
    
}


//
// App-initiated matchmaker request handling
- (void) initiateMatchMaker
{
    
    
#if USE_GAMECENTER
    
    GKMatchRequest *request = [[[GKMatchRequest alloc] init] autorelease];
    request.minPlayers = MULTIPLAYER_NUM_PLAYERS_MIN;
    request.maxPlayers = MULTIPLAYER_NUM_PLAYERS_MAX;
    
    GKMatchmakerViewController *mmvc = [[[GKMatchmakerViewController alloc] initWithMatchRequest:request] autorelease];
    mmvc.matchmakerDelegate = self;
    
#ifdef MOTION_PHONE_MOBILE
    // on the phone, presenting the modal controller doesn't work unless the view is in front
    [self onUIBegin];
#endif
    
    [self presentModalViewController:mmvc animated:YES];
    
    
#else
    
    // peer to peer!
    
    if ( peerPickerController_ )
    {
        [peerPickerController_ release];
        peerPickerController_ = nil;
    }
    
    peerPickerController_ = [[GKPeerPickerController alloc] init];
    peerPickerController_.delegate = self;
    [peerPickerController_ show];    
    
#endif
    
    
}

//
//
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // nothing
}

//
//
- (void) bringViewToFront
{
    [self.view.superview bringSubviewToFront: self.view];    
}

//
//
- (void) sendViewToBack
{
    [self.view.superview sendSubviewToBack: self.view];
}




#if USE_GAMECENTER

#pragma mark GKMatchMakerViewControllerDelegate

// The user has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    
#ifdef MOTION_PHONE_MOBILE
    [self performSelector: @selector(onUIEnd) withObject:nil afterDelay: UI_END_DELAY_MULTIPLAYER_PHONE];
#endif
    
    [self dismissModalViewControllerAnimated:YES];
    
    
}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    
#ifdef MOTION_PHONE_MOBILE
    [self performSelector: @selector(onUIEnd) withObject:nil afterDelay: UI_END_DELAY_MULTIPLAYER_PHONE];
#endif
    
    [self dismissModalViewControllerAnimated:YES];
    
    // actually display error to user?    
    UIAlertView * matchFailed = [[[UIAlertView alloc] initWithTitle:@"Matchmaking failed" 
                                                            message:@"MotionPhone was unable to create a multiplayer match" 
                                                           delegate:self 
                                                  cancelButtonTitle: @"OK" 
                                                  otherButtonTitles:nil] autorelease];    
    [matchFailed show];
    
    
}


// A peer-to-peer match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    
    
#ifdef MOTION_PHONE_MOBILE
    [self performSelector: @selector(onUIEnd) withObject:nil afterDelay: UI_END_DELAY_MULTIPLAYER_PHONE];
#endif
    
    [self dismissModalViewControllerAnimated:YES];

    // inform the delegate object
    if ( matchMakerDelegate_ )
    {
        [matchMakerDelegate_ mpDidFindMatch: match];
        [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationPendingBegin object:nil];        
    }

    
}


//// Players have been found for a server-hosted game, the game should start
//- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindPlayers:(NSArray *)playerIDs
//{
//    
//}
//
//// An invited player has accepted a hosted invite.  Apps should connect through the hosting server and then update the player's connected state (using setConnected:forHostedPlayer:)
//- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didReceiveAcceptFromHostedPlayer:(NSString *)playerID __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0)
//{
//    
//}


#else

#pragma mark GKPeerPickerControllerDelegate


// the GameKit peer picker controller has established a 2 player bluetooth session.  Time
// to report this to our delegate
- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session
{
    
    // we're currently only supporting a 2 player peer picker scenario, so this means we're ready to go
    
    NSMutableArray * arrayPeers = [NSMutableArray arrayWithObject: peerID];
    
    // todo - test that we're getting both IDs!
    [arrayPeers addObject: session.peerID];    
    NSLog( @"all peers ids: %@\n", [arrayPeers description] );
    

    // inform the delegate object
    if ( matchMakerDelegate_ )
    {
        [matchMakerDelegate_ mpDidFindSession: session withPeers: arrayPeers];
        //[[NSNotificationCenter defaultCenter] postNotificationName:gNotificationPendingBegin object:nil];        // not needed?
    }
    
    
    // Remove the picker.
    peerPickerController_ = nil;
    picker.delegate = nil;
    [picker dismiss];
    [picker autorelease];
    
    
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker
{
    peerPickerController_ = nil;
    picker.delegate = nil;
    // The controller dismisses the dialog automatically.
    [picker autorelease];

    
}

//
// Provide a custom session that has a custom session ID. This is also an opportunity to provide a session with a custom display name.
//
- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type 
{ 
	GKSession *session = [[GKSession alloc] initWithSessionID: @"Motion_Phone" displayName:nil sessionMode:GKSessionModePeer]; 
	return [session autorelease]; // peer picker retains a reference, so autorelease ours so we don't leak.
}

#endif



#pragma mark UIAlertViewDelegate

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( alertView.tag == ALERT_VIEW_DISCONNECT_TAG )
    {

        if ( buttonIndex == 0 )
        {
            // cancel, do nothing
        }
        else if ( buttonIndex == 1 )
        {
            // disconnect!
            [[MPNetworkManager man] disconnectFromMatch: true];            
        }
        
    }
 
    
}

#pragma mark MPOrientingUIKitParent

//
//
- (void) onViewControllerRequestDismissal: (UIViewController *) vc
{
    for ( NSDictionary * curDict in arrayModalVC_ )
    {
        
        UIViewController * curVC = [curDict objectForKey: keyVC];        
        
        if ( curVC == vc )
        {

            [vc.view removeFromSuperview];
            [arrayModalVC_ removeObject: curDict];                        
            [self onUIEnd];
            
            break;
        }
    }
}


@end
