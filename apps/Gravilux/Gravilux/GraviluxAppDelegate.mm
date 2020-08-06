//
//  GraviluxAppDelegate.m
//  Gravilux
//
//  Created by Colin Roache on 9/7/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "GraviluxAppDelegate.h"
#import "FlurryAnalytics.h"

void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAnalytics logError:@"Uncaught" message:@"Crash!" exception:exception];
}

@implementation GraviluxAppDelegate

@synthesize window, viewController, rotationController;

- (void)dealloc
{
	[window release];
	[viewController release];
	[rotationController release];
//	delete gGravilux;
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
	[FlurryAnalytics startSession:@"2V63T54H685WFPTNLZJ7"];
	
	[application setDelegate:self];
	
	gGravilux = new Gravilux();
	
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	
	rotationController = [[RotationController alloc] initWithNibName:nil bundle:nil];
	
	viewController = [[GraviluxViewController alloc] init];
	
	// we add the RotationController first - this one will receive the autorotate messages
    // as part of the responder chain.  We want this view controller to autorotate,
    // and the main app controller ( GraviluxViewController ) to stay in portrait.
    // Only the first view controller receives auto rotation messages.

	[window addSubview:rotationController.view];
	[window addSubview:viewController.view];
	[window bringSubviewToFront:rotationController.view];
    
	[window makeKeyAndVisible];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[viewController stopAnimation];
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[viewController stopAnimation];
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[viewController startAnimation];
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[viewController startAnimation];
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[viewController stopAnimation];
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

@end
