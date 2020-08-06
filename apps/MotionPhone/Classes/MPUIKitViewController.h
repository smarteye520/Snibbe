//
//  MPUIKitViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//
//  class MPUIKitViewController
//  ----------------------------
//  Class to manage the view that autorotates and handles basic UIKit
//  elements that must also auto-rotate, such as GameCenter UI and 
//  alert views.
//
//  The rest of the app doesn't auto rotate.

#import <UIKit/UIKit.h>
#import "GameKit/GameKit.h"
#import "MPProtocols.h"
#import "defs.h"

#if USE_GAMECENTER
@interface MPUIKitViewController : UIViewController <UIAlertViewDelegate, GKMatchmakerViewControllerDelegate, MPOrientingUIKitParent>
#else
@interface MPUIKitViewController : UIViewController <UIAlertViewDelegate, GKPeerPickerControllerDelegate, MPOrientingUIKitParent>
#endif

{
    
    id<MPMatchMakerUIDelegate> matchMakerDelegate_;
    UIImageView * imageViewGradient_;
    NSMutableArray * arrayModalVC_;
    bool validDeviceOrientFound_;
    
#if PEER_2_PEER
    
    GKPeerPickerController * peerPickerController_;
    
#endif
    
    UIDeviceOrientation orientationLast_;
}

@property (nonatomic, assign) id<MPMatchMakerUIDelegate> matchMakerDelegate_;



- (void) onUIBegin;
- (void) onUIEnd;

// our own pseudo-modal here
- (void) showVCAsModal: (UIViewController *) vc fullscreen: (bool) bFullscreen;



+ (void) setUIKitViewController: (MPUIKitViewController *) vc;
+ (MPUIKitViewController *) getUIKitViewController;



@end
