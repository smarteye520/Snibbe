//
//  MPSaveShareViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPSaveShareViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "defs.h"
#import "SnibbeCapture.h"
#import "UIImage+SnibbeTransformable.h"
#import "MPVideoRecordController.h"
#import "MPUIKitViewController.h"
#import "MPSaveLoad.h"
#import "MPTextController.h"
#import "SnibbeUtils.h"
#import "MPUIOrientButton.h"
#import "SnibbeYouTube.h"
#import "MPStatusController.h"
#import "Facebook.h"
#import "UIOrientView.h"

#import <Accounts/ACAccountType.h>
#import <Twitter/Twitter.h>
#import "FlurryAnalytics.h"




#define ALERT_NO_TWITTER 60000



// email subject
NSString * msgShareSubject = @"My MotionPhone Animation";

// used for FB post title and beginning of YouTube description
NSString * msgShareTextDescriptioniPadNoUrl = @"Created with MotionPhone for iPad";
NSString * msgShareTextDescriptioniPhoneNoUrl = @"Created with MotionPhone for iPhone";

// used for email and FB post contents
NSString * msgShareTextWatchiPadNoUrl = @"Watch this animation I created with MotionPhone for iPad!";
NSString * msgShareTextWatchiPhoneNoUrl = @"Watch this animation I created with MotionPhone for iPhone!";

//NSString * appStoreURL = @"iTunes App Store: http://itunes.com/apps/motionphonehd";
//NSString * appStoreURLPhone = @"iTunes App Store: http://itunes.com/apps/motionphone";
//NSString * appURL = @"Scott Snibbe Studio: http://snibbe.com/store/motionphone";

//NSString * allSnibbeAppStoreURL = @"iTunes App Store: http://itunes.apple.com/us/artist/scott-snibbe-studio-inc./id367739553";
NSString * allSnibbeAppStoreURL = @"iTunes App Store: http://itunes.com/scottsnibbestudioinc/";




// used for Twitter post contents
NSString * msgShareTwitteriPad = @"Watch this animation I created with #MotionPhone for iPad";
NSString * msgShareTwitteriPhone = @"Watch this animation I created with #MotionPhone for iPhone";



NSString * kStrKeywords = @"motion, phone, animation, abstract, motionphone, communication, network, iPad, iPhone, drawing, movement, gesture, painting, color, shapes, snibbe";


@interface MPSaveShareViewController()

//- (UIImage *) imageTransformedForSharing: (UIImage *) original;

- (void) onCanvasSaved;

- (void) notifyStatus: (NSString *) msg;
- (void) hideStatus;

- (void) beginEmailVideoShare;
- (void) beginEmailImageShare;

// video record delegate

- (void) clearSavedMoviePath;

- (void) onVideoCreated:(NSString *)path;
- (void) onVideoFailed;

// MPTextControllerDelegate methods

- (void) onCancel;
- (void) onPost: (NSString *) strPosting;


// FBRequestDelegate methods

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error;
- (void)request:(FBRequest *)request didLoad:(id)result;

- (void) clearFBController;
- (void) clearTwitterController;

// Facebook helpers
- (void) refreshFBLogoutButton;
- (void) onFBLogin;
- (void) onFBLogout;

// SnibbeYouTube methods

- (void) onVideoDidUpload: (NSString *) videoURL;
- (void) onVideoUploadProgress: (float) percent;
- (void) onVideoDidFail;

// youtube helpers
- (void) populateYouTubeUsernamePassword;
- (void) clearYouTube;

// MPStatusDelegate
- (void) onStatusCancel;

// MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;


@end



@implementation MPSaveShareViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        strMoviePath_ = nil;
        fbController_ = nil;
        youTube_ = nil;
        statusController_ = nil;
        statusControllerNotify_ = nil;
        
        store_ = [[ACAccountStore alloc] init];
        
        arrayYouTubeUsernames_ = [[NSArray alloc] initWithObjects: 
                                  @"MotionPhone01",
                                  @"MotionPhone02",
                                  @"MotionPhone03",
                                  @"MotionPhone04",
                                  @"MotionPhone05",
                                  @"MotionPhone06",
                                  @"MotionPhone07",
                                  @"MotionPhone08",
                                  @"MotionPhone09",
                                  @"MotionPhone10",
                                  @"MotionPhone11",
                                  @"MotionPhone12",                                  
                                  nil];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [arrayYouTubeUsernames_ release];
    [store_ release];
           
    if ( statusController_ )
    {
        [statusController_ release];
        statusController_ = nil;
    }
    
    if ( statusControllerNotify_ )
    {
        [statusControllerNotify_ release];
        statusControllerNotify_ = nil;
    }
    
    if ( youTube_ )
    {
        [youTube_ release];
        youTube_ = nil;
    }
    
    if ( fbController_ )
    {
        [fbController_ release];
        fbController_ = nil;
    }
    
    if ( twitterController_ )
    {
        [twitterController_ release];
        twitterController_ = nil;
    }
        
    
    [self clearSavedMoviePath];
    
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
    
    shareTarget_ = eMPNone;
    requestedFBVideo_ = false;
    
    [self clearSavedMoviePath];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBGColorChanged) name:gNotificationBGColorChanged object:nil];                
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCanvasSaved) name:gNotificationSavedCanvas object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFBLogin) name:gNotificationFBLoggedOn object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFBLogout) name:gNotificationFBLoggedOff object:nil];    
    
    
    
    [self updateViewBackground: viewMainBG_];    
    
    
    
#if MOTION_PHONE_MOBILE    
    
    // on the phont version, make sure the scroll view is set up properly
    
    float shortDim = MIN( orientView_.frame.size.width, orientView_.frame.size.height );
    float longDim = MAX( orientView_.frame.size.width, orientView_.frame.size.height );        
    
    orientView_.adjustBoundsOnOrient_ = true;
    orientView_.orientCenter_ = orientView_.center;
    
    orientView_.orientBoundsPortrait_ = CGRectMake(0, 0, shortDim, longDim);
    orientView_.orientBoundsLandscape_ = CGRectMake(0, 0, longDim, shortDim);
    
    [orientView_ forceUpdate: 0.0f];
    
#endif
    
    
    

    if ( !twitterSupported() )
    {
    

        // if we're on a version of iOS pre-twitter integration, hide
        // the twitter button and shift the other buttons
        
#ifdef  MOTION_PHONE_MOBILE
        
        
        // iPhone version
        
        float adjust = buttonTwitter_.frame.size.height + 18.0f; // button size + spacing
        
        buttonCameraRoll_.center = CGPointMake(buttonCameraRoll_.center.x, buttonCameraRoll_.center.y - adjust);
        buttonEmail_.center = CGPointMake(buttonEmail_.center.x, buttonEmail_.center.y - adjust);
        buttonSave_.center = CGPointMake(buttonSave_.center.x, buttonSave_.center.y - adjust);
        buttonFacebookFull_.center = CGPointMake(buttonFacebookFull_.center.x, buttonFacebookFull_.center.y - adjust);
        buttonFacebookPart_.center = CGPointMake(buttonFacebookPart_.center.x, buttonFacebookPart_.center.y - adjust);
        buttonLogOffFacebook_.center = CGPointMake(buttonLogOffFacebook_.center.x, buttonLogOffFacebook_.center.y - adjust);
#else
        
        // done differently on iPad

        
        buttonLogOffFacebook_.frame = buttonCameraRoll_.frame;                
        buttonCameraRoll_.frame = buttonEmail_.frame;
        buttonEmail_.frame = buttonTwitter_.frame;
        
        labelLogOffFacebook_.frame = CGRectMake(labelCameraroll_.frame.origin.x, labelCameraroll_.frame.origin.y, labelLogOffFacebook_.frame.size.width, labelLogOffFacebook_.frame.size.height );
        labelCameraroll_.frame = CGRectMake(labelEmail_.frame.origin.x, labelEmail_.frame.origin.y, labelCameraroll_.frame.size.width, labelCameraroll_.frame.size.height );
        labelEmail_.frame = CGRectMake(labelTwitter_.frame.origin.x, labelTwitter_.frame.origin.y, labelEmail_.frame.size.width, labelEmail_.frame.size.height );
                
        labelTwitter_.hidden = true;

#endif
        
        buttonTwitter_.hidden = true;


    }
    

    [self refreshFBLogoutButton];
    
    
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
	return interfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark IBAction methods

//
//
- (IBAction) onButtonSave: (id)sender
{
    [[MPSaveLoad getSL] save];   
}

//
// email is currently photo sharing, rather than video like the other two (fb, twitter)
- (IBAction) onButtonEmail: (id)sender
{
    
    if ( [MFMailComposeViewController canSendMail] )
    {        
        [self beginEmailVideoShare];
    }
    
}


//
//
- (void) doBeginFBVideoRecording
{
    
    if ( [gFacebook isSessionValid] )
    {
        
        [self clearSavedMoviePath];
        
        NSString * theNib = IS_IPAD ? @"MPVideoRecordController-iPad" : @"MPVideoRecordController";
        MPVideoRecordController * recordingVC = [[MPVideoRecordController alloc] initWithNibName:theNib bundle:nil];
        recordingVC.videoDelegate_ = self;
        recordingVC.maxTimeScale_ = VIDEO_SHARE_FB_MAX_TIMESCALE;
        recordingVC.optimize_ = true;
        
        shareTarget_ = eMPFacebook;
        
        MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];    
        [rotatingView showVCAsModal: recordingVC fullscreen: false];
    
        [recordingVC release];
    }
}

//
//
- (IBAction) onButtonFacebook: (id)sender
{
    
    
    if (![gFacebook isSessionValid]) 
    {
        requestedFBVideo_ = true;
        NSArray *permissions = [[NSArray alloc] initWithObjects:
                                @"publish_stream",
                                nil];
        
        [gFacebook authorize:permissions];
    }
    else
    {
        // we have a valid session
        [self doBeginFBVideoRecording];
    }
    
    
    
}


//
//
- (void) buttonTwitterBeginRecording
{
    
    
    if ( !canTweet() )
    {
        
        UIAlertView * alert = [[[UIAlertView alloc] init] autorelease];
        alert.title = @"Unable to Tweet";
        alert.message = @"Sorry, tweeting isn't available at the moment.";
        [alert show];
        return;
    }
    
    NSString * theNib = IS_IPAD ? @"MPVideoRecordController-iPad" : @"MPVideoRecordController";
    MPVideoRecordController * recordingVC = [[MPVideoRecordController alloc] initWithNibName:theNib bundle:nil];
    recordingVC.videoDelegate_ = self;
    recordingVC.maxTimeScale_ = VIDEO_SHARE_TWITTER_MAX_TIMESCALE;
    recordingVC.optimize_ = true;
    
    shareTarget_ = eMPTwitter;
    
    MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];    
    [rotatingView showVCAsModal: recordingVC fullscreen: false];
    
    [recordingVC release];
}

//
//
- (IBAction) onButtonTwitter: (id)sender
{
 
    // check for twitter accounts and make sure you can tweet
    
    ACAccountType * accountType = [store_ accountTypeWithAccountTypeIdentifier: ACAccountTypeIdentifierTwitter];
    
    // Request access from the user to use their Twitter accounts.
    [store_ requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
        if(granted) 
        {            
            
			// Get the list of Twitter accounts.
            NSArray *accountsArray = [store_ accountsWithAccountType:accountType];
			
            if ( [accountsArray count] > 0 )
            {
                // we have at least one twitter account
                
                [self performSelectorOnMainThread: @selector(buttonTwitterBeginRecording) withObject:nil waitUntilDone:false];
                
            }
            else
            {
                // no twitter accounts!
                
                UIAlertView * alertViewNoTwitter = [[UIAlertView alloc] initWithTitle:@"No Twitter account" message:@"To use Twitter with MotionPhone you must first set up a Twitter account in your Settings.  Would you like to go there now?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Settings", nil];
                
                alertViewNoTwitter.tag = ALERT_NO_TWITTER;
                [alertViewNoTwitter show];
            }
        
        }
	}];

    
    
    
    
    
    
}


//
// Alert view dismissal delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;  // after animation
{
    if ( alertView && alertView.tag == ALERT_NO_TWITTER )
    {
        if ( buttonIndex == 1 )
        {
            
            // go to twitter settings!            
            // this is iOS5 only! (but we should only get here if we have twitter 
            // framework)
            
            NSString *stringURL = @"prefs:root=TWITTER";
            NSURL *url = [NSURL URLWithString:stringURL];
            [[UIApplication sharedApplication] openURL:url];

        }
    }
}


//
//
- (IBAction) onButtonCameraRoll: (id)sender
{

    NSString * theNib = IS_IPAD ? @"MPVideoRecordController-iPad" : @"MPVideoRecordController";
    MPVideoRecordController * recordingVC = [[MPVideoRecordController alloc] initWithNibName:theNib bundle:nil];
    recordingVC.videoDelegate_ = self;
    recordingVC.videoNumLoops_ = VIDEO_SHARE_NUM_LOOPS_CAMERA_ROLL;    
    
    shareTarget_ = eMPCameraRoll;
    
    MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];    
    [rotatingView showVCAsModal: recordingVC fullscreen: false];
    
    [FlurryAnalytics logEvent:gEventSavedCameraRoll];
    
    [recordingVC release];
    
}

//
//
- (IBAction) onButtonLogOffFacebook: (id)sender
{
    if ( gFacebook )
    {
        [gFacebook logout];
        
        [self performSelector:@selector(notifyStatus:) withObject:@"Logged Out of Facebook" afterDelay:0.25f];
    }
}


#pragma mark private implementation


/*
// Returns a new UIImage scaled and rotated according to the platform and
// device orientation.  
- (UIImage *) imageTransformedForSharing: (UIImage *) original
{

    UIDeviceOrientation orient = gDeviceOrientation;
    
    float scaleFactor = (IS_IPAD) ? SHARING_IMAGE_SCALE_FACTOR_IPAD : SHARING_IMAGE_SCALE_FACTOR_IPHONE;    
    UIImage *imageScaled = [original imageByScalingToSize: CGSizeMake( original.size.width * scaleFactor, original.size.height * scaleFactor ) ];

    if ( orient == UIDeviceOrientationPortrait )                                 
    {    
        return imageScaled;                                  
    }
    else
    {
        float degToRotate = 0.0f;
        
        if ( orient == UIDeviceOrientationPortraitUpsideDown )
        {
            degToRotate = 180.0f;
        }
        else if ( orient == UIDeviceOrientationLandscapeLeft )
        {
            degToRotate = -90.0f;
        }
        else if ( orient == UIDeviceOrientationLandscapeRight )
        {
            degToRotate = 90.0f;
        }
        
        UIImage *imageRotated = [imageScaled imageRotatedByDegrees: degToRotate];
        return imageRotated;
    }
        
    
}

 */
 
//
// the canvas has saved successfully
- (void) onCanvasSaved
{
    [self performSelector:@selector(notifyStatus:) withObject:@"Saved" afterDelay:0.5f];
}

//
//
- (void) notifyStatus: (NSString *) msg
{
    if ( !statusControllerNotify_ )
    {
        statusControllerNotify_ = [[MPStatusController alloc] initWithNibName: IS_IPAD ? @"MPStatusViewController-iPad" : @"MPStatusViewController-iPhoneStatusOnly" bundle:nil];
    }
    
    
    MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];    
    [rotatingView showVCAsModal: statusControllerNotify_ fullscreen: false];
    
    [statusControllerNotify_ setProgress: 0.0f];    
    statusControllerNotify_.statusDelegate_ = nil;
    [statusControllerNotify_ setLabelText: msg];
    [statusControllerNotify_ showLabelOnly];
    [statusControllerNotify_ fadeViewIn];
    
    [self performSelector: @selector(hideStatus) withObject:nil afterDelay: STATUS_MESSAGE_DURATION + STATUS_MESSAGE_FADE_DURATION];
    [self performSelector: @selector(beginStatusFade) withObject: nil afterDelay: STATUS_MESSAGE_DURATION];
}


//
//
- (void) hideStatus
{
    if ( statusControllerNotify_ )
    {
        MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];  
        [rotatingView onViewControllerRequestDismissal: statusControllerNotify_];
    }
}

//
//
- (void) beginStatusFade
{
    if ( statusControllerNotify_ )
    {
        [statusControllerNotify_ fadeViewOut];
                
    }
}

//
//
- (void) beginEmailVideoShare
{
    NSString * theNib = IS_IPAD ? @"MPVideoRecordController-iPad" : @"MPVideoRecordController";
    MPVideoRecordController * recordingVC = [[MPVideoRecordController alloc] initWithNibName:theNib bundle:nil];
    recordingVC.videoDelegate_ = self;
    recordingVC.optimize_ = true;
    
    shareTarget_ = eMPEmail;
    
    MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];    
    [rotatingView showVCAsModal: recordingVC fullscreen: false];
    
    [recordingVC release];
}

//
//
- (void) beginEmailImageShare
{
 
    // not used (but works!)

    /*
    MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
    mailVC.mailComposeDelegate = self;
    
    [mailVC setSubject:@"Hello from California!"];        
    
    // Attach the video to the email                  
    //[mailVC addAttachmentData:movieData mimeType:@"video/mp4" fileName:@"motionphone"];
    
    
    UIImage *sharingImage = [self imageTransformedForSharing: imageViewScreenShot_.image];   
    if ( sharingImage )
    {
        NSData *imageData = UIImagePNGRepresentation( sharingImage );    
        [mailVC addAttachmentData:imageData mimeType:@"image/png" fileName:@"motionphone"];
    }
    
    
    // Fill out the email body text
    NSString *emailBody = @"It is raining in sunny California!";
    [mailVC setMessageBody:emailBody isHTML:NO];
    
    [self presentModalViewController:mailVC animated:YES];
    
    [mailVC release];
     
     */
    
}



#pragma mark video delegate methods


// A video has been created for sharing on Twitter.  Proceed to upload to a
// YouTube account.  Once upload is complete the user will be presented with
// a Tweet Sheet to author their tweet with link attached.
- (void) onTwitterVideoCreated
{       
    

    
    if ( !youTube_ )
    {
        youTube_ = [[SnibbeYouTube alloc] init];
    }
    
    [self populateYouTubeUsernamePassword];    
    
    youTube_.developerKey_ = MOTION_PHONE_YOUTUBE_DEVELOPER_KEY;
    youTube_.delegate_ = self;
        
    
    // old method with 2 urls
    
    /*
    NSString *videoDesc = [NSString stringWithFormat:@"%@\n%@\n%@", 
                           IS_IPAD ? msgShareTextDescriptioniPadNoUrl : msgShareTextDescriptioniPhoneNoUrl,
                           IS_IPAD ? appStoreURL : appStoreURLPhone,
                           appURL];
    
    */

    // new method with single url 
    
    NSString *videoDesc = [NSString stringWithFormat:@"%@\n%@", 
                           IS_IPAD ? msgShareTextDescriptioniPadNoUrl : msgShareTextDescriptioniPhoneNoUrl,
                           allSnibbeAppStoreURL];
    
    
    
    
    [youTube_ uploadVideo: strMoviePath_ title:@"A MotionPhone Creation" category:@"Film" description:videoDesc keywords: kStrKeywords];
    
    if ( statusController_ )
    {
        [statusController_ release];
    }
    
    statusController_ = [[MPStatusController alloc] initWithNibName: IS_IPAD ? @"MPStatusViewController-iPad" : @"MPStatusViewController" bundle:nil];
   
    
    MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];    
    [rotatingView showVCAsModal: statusController_ fullscreen: false];
    
    [statusController_ setProgress: 0.0f];
    [statusController_ showProgressBar: true];
    statusController_.statusDelegate_ = self;
    [statusController_ setLabelText: @"Preparing video for sharing"];
    
   
}

//
//
- (void) onEmailVideoCreated
{

   
    
    NSData *movieData = [NSData dataWithContentsOfFile:strMoviePath_];
    if ( movieData )
    {
        
        
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        mailVC.mailComposeDelegate = self;

        [mailVC setSubject: msgShareSubject];        

        // Attach the video to the email                  
        [mailVC addAttachmentData:movieData mimeType:@"video/mp4" fileName:@"motionphone.mp4"];


        
        // Fill out the email body text
        
        
        // old method with 2 urls

        /*
        NSString *emailBody = [NSString stringWithFormat:@"%@\n\n%@\n%@", 
                               IS_IPAD ? msgShareTextWatchiPadNoUrl : msgShareTextWatchiPhoneNoUrl,
                               IS_IPAD ? appStoreURL : appStoreURLPhone,
                               appURL];
        */
        

        
        // new method with 1 url
        
        NSString *emailBody = [NSString stringWithFormat:@"%@\n\n%@", 
                               IS_IPAD ? msgShareTextWatchiPadNoUrl : msgShareTextWatchiPhoneNoUrl,
                               allSnibbeAppStoreURL];
        
        
        
        
        
        
        [mailVC setMessageBody:emailBody isHTML:NO];
        
        MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];    
        [rotatingView presentModalViewController:mailVC animated:YES];
       
        [mailVC release];

    }
    
   

}

//
//
- (void) onFBVideoCreated
{
    
    NSString * theNib = IS_IPAD ? @"MPTextController-iPad" : @"MPTextController";
    MPTextController * textController = [[MPTextController alloc] initWithNibName: theNib bundle:nil]; 
    textController.strButtonPostText_ = @"Post";
    textController.strButtonCancelText_ = @"Cancel";
    textController.strTitle_ = IS_IPAD ? @"Share video on Facebook" : @"Facebook";
    
    
    // old method with 2 urls
    
    /*
    textController.strTextViewInitialContents_ = [NSString stringWithFormat:@"%@\n\n%@\n%@", 
                                                  IS_IPAD ? msgShareTextWatchiPadNoUrl : msgShareTextWatchiPhoneNoUrl,
                                                  IS_IPAD ? appStoreURL : appStoreURLPhone,
                                                  appURL];
    
    */
    
    // new method with 1 url
    
    textController.strTextViewInitialContents_ = [NSString stringWithFormat:@"%@\n\n%@", 
                           IS_IPAD ? msgShareTextWatchiPadNoUrl : msgShareTextWatchiPhoneNoUrl,
                           allSnibbeAppStoreURL];
        
    
    
    
    
    
    textController.textDelegate_ = self;        
    
    MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];    
    


    [rotatingView showVCAsModal: textController fullscreen: IS_IPAD ? false : true];

       
}

//
//
- (void) clearSavedMoviePath
{
    if ( strMoviePath_ )
    {
        [strMoviePath_ release];
        strMoviePath_ = nil;
    }
}

//
//
- (void) onVideoCreated:(NSString *)path
{
    if ( [[NSFileManager defaultManager] fileExistsAtPath: path] )
    {
 
        

        
        
        
                
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path error: nil];
        NSString *fileSize = [fileAttributes objectForKey:@"NSFileSize"];
        if ( fileSize )
        {
            NSLog( @"video created for sharing.  Size: %@\n", fileSize );
        }
        
        

        
        switch (shareTarget_ )
        {
            case eMPEmail:
            {
                //NSMutableData * videoData = [NSMutableData dataWithContentsOfFile: path];        
                
                
                
                [self clearSavedMoviePath];
                strMoviePath_ = [path retain];
                
                [self performSelector:@selector(onEmailVideoCreated) withObject:nil afterDelay: .10f ];
                
                break;
            }
            case eMPFacebook:
            {
                
                [self clearSavedMoviePath];
                strMoviePath_ = [path retain];
               
                [self performSelector:@selector(onFBVideoCreated) withObject:nil afterDelay:.10f];
                break;
            }
            case eMPTwitter:
            {
                [self clearSavedMoviePath];
                strMoviePath_ = [path retain];
                
                [self performSelector:@selector(onTwitterVideoCreated) withObject:nil afterDelay:.10f];
                break;
                
            }
            case eMPCameraRoll:
            {
                                
                if ( UIVideoAtPathIsCompatibleWithSavedPhotosAlbum( path ) )
                {
                    UISaveVideoAtPathToSavedPhotosAlbum( path, nil, nil, nil );
                    [self performSelector:@selector(notifyStatus:) withObject:@"Saved to Camera Roll" afterDelay:0.25f];
                }
                else
                {
                    [self performSelector:@selector(notifyStatus:) withObject:@"Unable to save" afterDelay:0.25f];
                }
                        
                break;
            }
            case eMPNone:
            default:
            {
                break;
            }
                            
        }
    }
    else
    {
        // alert!
    }
    
}

#pragma mark MPTextControllerDelegate methods

//
//
- (void) onVideoFailed
{
    
}


//
// this is a cancel event from the text controller (currently only used by FB)
- (void) onCancel
{
    
}

//
// this is a post event  from the text controller (currently only used by FB)
- (void) onPost: (NSString *) strPosting
{
    
    
    if ( shareTarget_ == eMPFacebook )
    {
        
        
        NSData *videoData = [NSData dataWithContentsOfFile: strMoviePath_];        
        if ( videoData )
        {
        NSString * title = IS_IPAD ? msgShareTextDescriptioniPadNoUrl : msgShareTextDescriptioniPhoneNoUrl;        
        
        NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       title, @"title", 
                                       @"video/mp4", @"contentType",
                                       strPosting, @"description",                                        
                                       videoData, @"motionphone.mov",
                                       nil];
        
        [gFacebook requestWithGraphPath:@"me/videos" andParams:params andHttpMethod:@"POST" andDelegate:self];
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationPendingBegin object:nil];
        
                
        }
    }
     
           
}



#pragma mark FBRequestDelegate methods

//
// Called when an error prevents the request from completing successfully.
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error
{
    SSLog( @"facebook error: %@\n", [error description] );
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationPendingEnd object:nil];
    [self performSelector:@selector(notifyStatus:) withObject:@"Facebook post failed" afterDelay:0.1f];
    
}

//
// Called when a request returns and its response has been parsed into
// an object.
//
// The resulting object may be a dictionary, an array, a string, or a number,
// depending on thee format of the API response.
- (void)request:(FBRequest *)request didLoad:(id)result
{
    SSLog( @"facebook did load\n" );
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationPendingEnd object:nil];
    [self performSelector:@selector(notifyStatus:) withObject:@"Posted to Facebook" afterDelay:0.1f];
    
    [FlurryAnalytics logEvent:gEventSharedFB];
}

//
//
- (void) clearFBController
{
    if ( fbController_ )
    {
        [fbController_ release];
        fbController_ = nil;
    }
}

//
//
- (void) clearTwitterController
{
    if ( twitterController_ )
    {
        [twitterController_ release];
        twitterController_ = nil;
    }
}

//
//
- (void) refreshFBLogoutButton
{
 
    bool validSession = gFacebook && [gFacebook isSessionValid];
    
#ifdef  MOTION_PHONE_MOBILE
    
    buttonFacebookFull_.hidden = validSession;
    buttonFacebookPart_.hidden = !validSession;
    buttonLogOffFacebook_.hidden = !validSession;
    
#else
    
    buttonLogOffFacebook_.hidden = true;
    labelLogOffFacebook_.hidden = true;
    if ( validSession )
    {
        buttonLogOffFacebook_.hidden = false;
        labelLogOffFacebook_.hidden = false;    
    }
    
#endif
    
}

- (void) onFBLogin
{ 
    [self refreshFBLogoutButton];
    
    if ( requestedFBVideo_ )
    {
        [self performSelectorOnMainThread:@selector(doBeginFBVideoRecording) withObject:nil waitUntilDone:false];
        requestedFBVideo_ = false;
    }
}

- (void) onFBLogout
{
    [self refreshFBLogoutButton];
}

#pragma mark Snibbe YouTube delegates

//
// We uploaded a video to YouTube for sharing.  Currently this is only used for Twitter
// sharing, so we complete the twitter authoring process
- (void) onVideoDidUpload: (NSString *) videoURL
{
  
    SSLog( @"Youtube video did upload with url: %@\n", videoURL );
    
    MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];    
    [rotatingView onViewControllerRequestDismissal: statusController_];
    
    
    // now we compose the tweet!
     
     
     // Set up the built-in twitter composition view controller.
     TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
    
    NSString * tweetText = IS_IPAD ? msgShareTwitteriPad : msgShareTwitteriPhone;  
    
     // Set the initial tweet text. See the framework for additional properties that can be set.
    [tweetViewController setInitialText: tweetText ];
    
    NSURL * urlVideoLink = [NSURL URLWithString: videoURL];
    [tweetViewController addURL: urlVideoLink];    
     
     // Create the completion handler block.
    [tweetViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) 
    {
         
         switch (result) 
        {
        
            case TWTweetComposeViewControllerResultCancelled:
            {
                
                // The cancel button was tapped.             
                // delete the video
                
                if ( youTube_ )
                {
                    [youTube_ deleteVideo];
                }
                
                break;
            }                
             
            case TWTweetComposeViewControllerResultDone:
            {
                // The tweet was sent.
                [FlurryAnalytics logEvent:gEventSharedTwitter];
                break;
            }
             
            default:
            {                            
                break;
            }
     }
     
         //[self performSelectorOnMainThread:@selector(displayText:) withObject:output waitUntilDone:NO];
         
         // Dismiss the tweet composition view controller.
         [self dismissModalViewControllerAnimated:YES];
     }];
     
     // Present the tweet composition view controller modally.
     [self presentModalViewController:tweetViewController animated:YES];
     
     
    
}

//
//
- (void) onVideoUploadProgress: (float) percent
{
    SSLog( @"youtube progress: %f\n", percent );    
    [statusController_ setProgress: percent];
}

//
//
- (void) onVideoDidFail
{
    SSLog( @"Youtube video upload did fail!!!\n" );
            
    MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];    
    [rotatingView onViewControllerRequestDismissal: statusController_];
    
    [self performSelector: @selector(clearYouTube) withObject:nil afterDelay:.1f];
    
    [self performSelector:@selector(notifyStatus:) withObject:@"Unable to share video" afterDelay:1.0f];
}

#pragma mark YouTube helpers




//
// We randomly select from a collection of accounts.
- (void) populateYouTubeUsernamePassword
{

    
    if ( youTube_ )
    {
        
        int iNumAccounts = [arrayYouTubeUsernames_ count];        
        int iIndex = rand() % iNumAccounts;        
                
        youTube_.userName_ = [arrayYouTubeUsernames_ objectAtIndex: iIndex];
        youTube_.password_ = @"AlmondButter";        
        
    }
}

//
//
- (void) clearYouTube;
{
    if ( youTube_ )
    {
        [youTube_ release];
        youTube_ = nil;
    }
    
}

//
// cancel the status window (currently only twitter/youtube uploading)
- (void) onStatusCancel
{
    if ( youTube_ )
    {
        [youTube_ cancelUpload];
        MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];    
        [rotatingView onViewControllerRequestDismissal: statusController_];
        
        [youTube_ release];
        youTube_ = nil;
    }
}

#pragma mark MFMailComposeViewControllerDelegate methods


// this is needed because on the phone when the email controller is presented modally and dismissed
// it changes the order of the presenting view for some reason.
// This method restores things to normal
- (void) delayedReorderViews
{
    MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];    
    [[rotatingView.view superview] sendSubviewToBack: rotatingView.view];

}

//
//
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if ( controller )
    {
       

        
        MPUIKitViewController * rotatingView = [MPUIKitViewController getUIKitViewController];                    
        [rotatingView dismissModalViewControllerAnimated:true];

        
#ifdef MOTION_PHONE_MOBILE        
        // this is needed because on the phone when the email controller is presented modally and dismissed
        // it changes the order of the presenting view for some reason.
        [self performSelector:@selector(delayedReorderViews) withObject:nil afterDelay:1.0f];
#endif
        
      
        
                
                
    }
    
    if ( result == MFMailComposeResultSent )
    {
        [FlurryAnalytics logEvent:gEventSharedEmail];
    }
}

//
//
- (void) onBGColorChanged
{ 
    [self updateViewBackground: viewMainBG_];
}

#pragma mark touch methods

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
