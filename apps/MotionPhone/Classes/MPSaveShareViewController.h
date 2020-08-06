//
//  MPSaveShareViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIViewControllerHiding.h"
#import "MPVideoRecordController.h"
#import "MPTextController.h"
#import "SnibbeYouTube.h"
#import <Accounts/ACAccount.h>
#import <Accounts/ACAccountStore.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "Facebook.h"

@class SHKFacebook;
@class SHKTwitter;
@class MPUIOrientButton;
@class MPStatusController;
@class UIOrientView;

typedef enum
{
    eMPNone = 0,
    eMPEmail,
    eMPFacebook,
    eMPTwitter,
    eMPCameraRoll,
} MotionPhoneSharingT;

@interface MPSaveShareViewController : MPUIViewControllerHiding <MPVideoRecordDelegate, MPTextControllerDelegate, SnibbeYouTubeDelegate, MPStatusDelegate, MFMailComposeViewControllerDelegate, FBRequestDelegate>
{
    IBOutlet UIView *viewMainBG_;
    IBOutlet UIButton * buttonTwitter_;
    IBOutlet UIButton * buttonEmail_;
    IBOutlet UIButton * buttonCameraRoll_;
    IBOutlet UIButton * buttonLogOffFacebook_;
    IBOutlet UILabel  * labelEmail_;
    IBOutlet UILabel  * labelCameraroll_;
    IBOutlet UILabel  * labelTwitter_;
    IBOutlet UILabel  * labelLogOffFacebook_;
    
    
    
    // phone only
    IBOutlet UIOrientView * orientView_;
    IBOutlet UIButton * buttonFacebookFull_;
    IBOutlet UIButton * buttonFacebookPart_;    
    IBOutlet UIButton * buttonSave_;    
    
    NSString * strMoviePath_;
    
    SHKFacebook * fbController_;
    SHKTwitter * twitterController_;
    
    
    SnibbeYouTube * youTube_;
    
    MotionPhoneSharingT shareTarget_;
    MPStatusController * statusController_;
    MPStatusController * statusControllerNotify_;
    
    ACAccountStore * store_;
    
    NSArray *arrayYouTubeUsernames_;
    bool requestedFBVideo_;
}


- (IBAction) onButtonSave: (id)sender;
- (IBAction) onButtonEmail: (id)sender;
- (IBAction) onButtonFacebook: (id)sender;
- (IBAction) onButtonTwitter: (id)sender;
//- (IBAction) onButtonYoutube: (id)sender;
- (IBAction) onButtonCameraRoll: (id)sender;
- (IBAction) onButtonLogOffFacebook: (id)sender;

@end
