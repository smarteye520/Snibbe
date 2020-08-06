//
//  MotionPhoneAppDelegate.m
//  MotionPhone
//
//  Created by Scott Snibbe on 11/12/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#import "defs.h"
#import "Parameters.h"
#import "MotionPhoneAppDelegate.h"
#import "MotionPhoneViewController.h"
#import "ToolbarViewController.h"
#import "MPUIKitViewController.h"
#import "UIOrientView.h"
#import "UIOrientButton.h"
#import "MPSaveLoad.h"
#import "FlurryAnalytics.h"
#import "iRate.h"
#import "MPNetworkManager.h"
#import "SnibbeUtils.h"


@interface MotionPhoneAppDelegate()

// FBSessionDelegate methods

- (void)fbDidLogin;

@end




@implementation MotionPhoneAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize facebook;

//
//
void uncaughtExceptionHandler(NSException *exception) 
{
    [FlurryAnalytics logError: [exception name] message: [exception reason] exception:exception];
}


//
//
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Start mtiks -- antipiracy 
    // [[mtiks sharedSession] start:@"?"];         // $$$$
    
    srand( time(NULL) );
    
    NSSetUncaughtExceptionHandler( &uncaughtExceptionHandler );
    
        
#ifdef MOTION_PHONE_MOBILE
    [FlurryAnalytics startSession:@"7GW9X53JTEU8AAPWUKME"];  // flurry for iPhone version    
#else
    [FlurryAnalytics startSession:@"QIJRXZXR96U9V8K8UM6N"];  // flurry for iPad version
#endif
    
    
    // create the viewcontroller    
    NSString *nibName = ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) ? @"MotionPhoneViewController-iPad" : @"MotionPhoneViewController";    
    viewController = [[MotionPhoneViewController alloc] initWithNibName: nibName bundle:nil];

#ifdef MOTION_PHONE_MOBILE
    facebook = [[Facebook alloc] initWithAppId:@"298820593506223" andDelegate:self];
#else
    facebook = [[Facebook alloc] initWithAppId:@"129990520368856" andDelegate:self];    
#endif
    
    
    gFacebook = facebook;
    
    if ( gParams->getFBAccessToken() && gParams->getFBExpirationDate() )
    {
        facebook.accessToken = gParams->getFBAccessToken();
        facebook.expirationDate = gParams->getFBExpirationDate();        
    }    
    
    [MPSaveLoad startup];
    [UIOrientView startup];
    [UIOrientButton startup];
    
    // setup the viewControllers
    
    // we add the UIKitViewController first - this one will receive the autorotate messages
    // as part of the responder chain.  We want this view controller to autorotate,
    // and the main app controller ( MotionPhoneViewController ) to stay in portrait.
    // Only the first view controller receives auto rotation messages.
    
    uiKitViewController = [[MPUIKitViewController alloc] initWithNibName:nil bundle:nil];
    [self.window addSubview: uiKitViewController.view];
    
    
    // set up the singleton
    [MPUIKitViewController setUIKitViewController: uiKitViewController];
   
    
    [self.window addSubview:self.viewController.view];          
    //[self.window sendSubviewToBack: uiKitViewController.view];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	
    if ( [MPNetworkManager gameKitAvailable] )
    {
        [self.viewController multiplayerInit];
    }

    // record iOS version with Flurry
    NSMutableDictionary * dictSysInfo = [[NSMutableDictionary alloc] init ];
    [dictSysInfo setObject:[[UIDevice currentDevice] systemVersion] forKey: gEventParamIOSVersionNumber];    
    [FlurryAnalytics logEvent:gEventIOSVersion withParameters:dictSysInfo];    
    [dictSysInfo release];
    
    // 
    // configure iRate for app rating behavior
    //
    
#ifdef  MOTION_PHONE_MOBILE
    [iRate sharedInstance].appStoreID = MOTION_PHONE_APP_ID_PHONE;
#else    
	[iRate sharedInstance].appStoreID = MOTION_PHONE_APP_ID_PAD;
#endif
    
    // user must use the app this number of days AND this number of times to
    // receive a prompt
    [iRate sharedInstance].daysUntilPrompt = 5;  
    [iRate sharedInstance].usesUntilPrompt = 5;
    
    // remind the user N days at minimum after choosing "remind me later"
    [iRate sharedInstance].remindPeriod = 5;
    
    // if YES forces the prompt every time
	//[iRate sharedInstance].debug = YES;
    
    
    
    return YES;
} 

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.viewController stopAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.viewController startAnimation];
    gParams->loadSettingsBundleParams();   
    
#ifdef MOTION_PHONE_MOBILE
    // this shouldn't be necessary if we get the media player notifications we're supposed to, but they aren't being
    // generated properly on the phone
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRefreshMediaButton object: nil];
#endif
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.viewController stopAnimation];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Handle any background procedures not related to animation here.
    
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationAppDidEnterBG object: nil];
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Handle any foreground procedures not related to animation here.
}

- (void)dealloc
{

    [MPSaveLoad shutdown];
    [UIOrientButton shutdown];
    [UIOrientView shutdown];
    [uiKitViewController release];
    [viewController release];
    [window release];
    
    [super dealloc];
}


#pragma mark FGSessionDelegate methods


//
//
- (void) delayFBNotify
{
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationFBLoggedOn object:nil];
}

//
//
- (void)fbDidLogin
{
    
    gParams->setFBCredentials( [facebook accessToken], [facebook expirationDate] );
    gParams->saveIfDirty();
        
    // give time for orientation to update post facebook login (always returns portrait,
    // need to to adjust to landscape if required
    [self performSelector: @selector(delayFBNotify) withObject:nil afterDelay: 1.0f];
    
}

//
//
- (void) fbDidLogout
{
    gParams->setFBCredentials( nil, nil );
    gParams->saveIfDirty();
    
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationFBLoggedOff object:nil];
}

//
// UIApplication delegate method for FB integration
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation 
{
    return [facebook handleOpenURL:url]; 
}


@end
