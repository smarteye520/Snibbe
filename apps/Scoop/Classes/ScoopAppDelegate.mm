//
//  ScoopAppDelegate.m
//  Scoop
//
//  Created by Scott Snibbe on 7/18/10.
//  Copyright Snibbe Interactive 2010. All rights reserved.
//

#import "ScoopAppDelegate.h"
#import "cocos2d.h" 
#import "CrownsScene.h"
#import "SettingsManager.h"
#import "UIViewControllerScoop.h"
#import "ScoopUtils.h"
#import "FlurryAnalytics.h"
//#import "mtiks.h"
#import "SnibbeStore.h"

@implementation ScoopAppDelegate

NSString *mticksKey = @"1fd6fbd9f7db8c64c6320c28e";

@synthesize window;

//
//
void uncaughtExceptionHandler(NSException *exception) 
{
    [FlurryAnalytics logError: [exception name] message: [exception reason] exception:exception];
}


- (void) applicationDidFinishLaunching:(UIApplication*)application
{
    
    NSSetUncaughtExceptionHandler( &uncaughtExceptionHandler );

    [FlurryAnalytics startSession:@"VQS1X5J1SMN965IETIUD"];  // OscilloScoop flurry key
    
    // record iOS version with Flurry
    NSMutableDictionary * dictSysInfo = [[NSMutableDictionary alloc] init ];
    [dictSysInfo setObject:[[UIDevice currentDevice] systemVersion] forKey: gEventParamIOSVersionNumber];    
    [FlurryAnalytics logEvent:gEventIOSVersion withParameters:dictSysInfo];    
    [dictSysInfo release];
    
    //[[mtiks sharedSession] start:mticksKey];
    
	// CC_DIRECTOR_INIT()
	//
	// 1. Initializes an EAGLView with 0-bit depth format, and RGB565 render buffer
	// 2. EAGLView multiple touches: disabled
	// 3. creates a UIWindow, and assign it to the "window" var (it must already be declared)
	// 4. Parents EAGLView to the newly created window
	// 5. Creates Display Link Director
	// 5a. If it fails, it will use an NSTimer director
	// 6. It will try to run at 60 FPS
	// 7. Display FPS: NO
	// 8. Device orientation: Portrait
	// 9. Connects the director to the EAGLView
	//
	//CC_DIRECTOR_INIT();
	
    
    
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
	if( ![CCDirector setDirectorType:kCCDirectorTypeDisplayLink] )
    {
        [CCDirector setDirectorType:kCCDirectorTypeNSTimer];
    }
    
	CCDirector *director = [CCDirector sharedDirector];
	
    // select whether to multisample based on platform
    
    bool bUseMultiSampling = false; // todo - update per-platform
    
    
    
    
    [director setAnimationInterval:1.0/60];													
	EAGLView *view = [EAGLView viewWithFrame:[window bounds]
                                     pixelFormat:kEAGLColorFormatRGBA8							
                                     depthFormat:0 /* GL_DEPTH_COMPONENT24_OES */				
                                     preserveBackbuffer:NO												
                                     sharegroup:nil												
                                     multiSampling:bUseMultiSampling												
                                     numberOfSamples:bUseMultiSampling ? 4 : 0 ];											
	[director setOpenGLView:view];														
	[window addSubview:view];																
	[window makeKeyAndVisible];																	

    		
	[director setDeviceOrientation:kCCDeviceOrientationPortrait];    
	[director setDisplayFPS:NO];
    
    retinaEnabled_ = [director enableRetinaDisplay:true];
    setRetinaEnabled( retinaEnabled_ );
    
    viewControllerScoop_ = [[UIViewControllerScoop alloc] initWithNibName:nil bundle:nil];
	viewControllerScoop_.wantsFullScreenLayout = YES;
    
    // initialize the store
    [SnibbeStore startup];
    
    
    
    testForIPad();
    
    
	[view setMultipleTouchEnabled:YES];
    [view removeFromSuperview];
    
    [viewControllerScoop_ setRetinaEnabled:retinaEnabled_];
    [viewControllerScoop_ setView: view];
    [window addSubview: viewControllerScoop_.view];
    [window setBackgroundColor:[UIColor colorWithRed: 232.0f/255 green:239.0f/255 blue:243.0f/255 alpha:1.0f]];
    
    [director setOpenGLView: view];
    
	// Tell the UIDevice to send notifications when the orientation changes
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kTexture2DPixelFormat_RGBA8888];
		
    [SettingsManager init];
    
    CCScene *c = [Crowns scene: retinaEnabled_ withViewController:viewControllerScoop_];    
	[[CCDirector sharedDirector] runWithScene: c];
}


// tell the director that the orientation has changed
//- (void) orientationChanged:(NSNotification *)notification
//{
//	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
//	//[[CCDirector sharedDirector] setDeviceOrientation:(ccDeviceOrientation)orientation];
//}



- (void)applicationWillResignActive:(UIApplication *)application {
	
    //[[mtiks sharedSession] stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"app_resigning_active" object:nil];        
    [[CCDirector sharedDirector] pause];
        

    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    //[[mtiks sharedSession] start:mticksKey];  
    [[NSNotificationCenter defaultCenter] postNotificationName:@"app_becoming_active" object:nil];        
    [[CCDirector sharedDirector] resume];
      
	
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCDirector sharedDirector] purgeCachedData];
}

-(void) applicationDidEnterBackground:(UIApplication*)application {
	
    [[CCDirector sharedDirector] stopAnimation];
    //[[mtiks sharedSession] stop];

}

-(void) applicationWillEnterForeground:(UIApplication*)application {
	[[CCDirector sharedDirector] startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {

	[[CCDirector sharedDirector] end];
    [SnibbeStore shutdown];
    //[[mtiks sharedSession] stop];
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[[CCDirector sharedDirector] release];
    [SettingsManager shutdown];
	[window release];
	[super dealloc];
}

@end
