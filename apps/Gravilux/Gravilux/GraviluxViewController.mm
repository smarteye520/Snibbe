//
//  GraviluxViewController.m
//  Gravilux
//
//  Created by Colin Roache on 9/14/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "GraviluxViewController.h"
#import <CoreFoundation/CoreFoundation.h>


@implementation GraviluxViewController

@synthesize animating, animationFrameInterval, context, displayLink;

- (id)init
{
	self = [super init];
	if(self) {
	}
	return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
	if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	[context release];
	[graviluxView release];
//	delete gGravilux;
// $$$ should work! ^
	
	
	[super dealloc];
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
	graviluxView = [[GraviluxView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.view.multipleTouchEnabled = YES;
	[self.view addSubview:graviluxView];
	
	 
	
	// force to 1.1 OpenGL
	EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	
	if (!aContext)
		NSLog(@"Failed to create ES context");
	else if (![EAGLContext setCurrentContext:aContext])
		NSLog(@"Failed to set ES context current");
	
	self.context = aContext;
	[aContext release];
	self.displayLink = nil;
	
	[graviluxView setContext:self.context];
	
	animating = FALSE;
	animationFrameInterval = 1;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self startAnimation];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)drawFrame
{
	if(!animating) {
		return;
	}
	
	if(gGravilux->params()->getTimeSinceLastInteraction() > 30.f) {
		gGravilux->params()->setInteractionTime();
		
		gGravilux->resetGrains();
		
		gGravilux->params()->setAntigravity(!gGravilux->params()->antigravity());
		gGravilux->params()->setGravity((rand()%5000)/100.);
		NSLog(@"resetting: antigravity: %@ gravity: %f", gGravilux->params()->antigravity()?@"YES":@"NO", gGravilux->params()->gravity());
	}
	
	[graviluxView setFramebuffer];
	
	glClearColor(0.0, 0.0, 0.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);
#warning Move to GraviluxView
	gGravilux->update();
	gGravilux->draw();
	
	[graviluxView presentFramebuffer];
}

- (void)startAnimation
{
    if (!animating)
    {
		SEL drawCall = @selector(drawFrame);
		
		// Use a display link to stay synced with screen refreshes
		CADisplayLink *aDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:drawCall];
        [aDisplayLink setFrameInterval:animationFrameInterval];
		[aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = aDisplayLink;
		
		// Use a 60fps NSTimer when UIKit is blocking the displaylink
		uiTimer = [NSTimer timerWithTimeInterval:1./60. target:self selector:drawCall userInfo:nil repeats:YES]; 
		[[NSRunLoop currentRunLoop] addTimer:uiTimer forMode:UITrackingRunLoopMode];
        
        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
		if(uiTimer) {
			[uiTimer invalidate];
			uiTimer = nil;
		}
		animating = FALSE;
	}
}

#pragma mark - Hardware interaction
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIDeviceOrientationIsValidInterfaceOrientation(interfaceOrientation);
}
@end
