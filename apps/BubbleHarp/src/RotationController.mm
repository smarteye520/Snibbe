//
//  RotationController.m
//  Gravilux
//
//  Created by Colin Roache on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "RotationController.h"
#include "BubbleHarp.h"

@implementation RotationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		
		UIView * controllerMainView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
        self.view = controllerMainView;
		
        self.view.userInteractionEnabled = YES;
		self.view.multipleTouchEnabled = YES;
		
		
		UIDevice* thisDevice = [UIDevice currentDevice];
		if(thisDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
		{
			// iPad
			interfaceVC = [[InterfaceViewController alloc] initWithNibName:@"InterfaceView-iPad" bundle:[NSBundle mainBundle]];
		}
		else
		{
			// iPhone
			interfaceVC = [[InterfaceViewController alloc] initWithNibName:@"InterfaceView-iPhone" bundle:[NSBundle mainBundle]];
		}
		[self.view addSubview:interfaceVC.view];
		interfaceVC.view.frame = CGRectMake(0, self.view.bounds.size.height - interfaceVC.view.frame.size.height, interfaceVC.view.frame.size.width, interfaceVC.view.frame.size.height);
		[interfaceVC showView];
    }
    return self;
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
	[interfaceVC willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	gBubbleHarp->touchesBegan(touches);
}


- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	gBubbleHarp->touchesMoved(touches);
}


- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	gBubbleHarp->touchesEnded(touches);
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	gBubbleHarp->touchesEnded(touches);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) dealloc
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		return interfaceOrientation == UIInterfaceOrientationPortrait;
	}
	
	if (UIDeviceOrientationIsValidInterfaceOrientation( interfaceOrientation )) {
		// If we get a useful orientation, save it
		lastValidDeviceOrientation = interfaceOrientation;
//		interfaceVC.currentOrientation = interfaceOrientation;
		return YES;
	}
	return NO;
}

@end
