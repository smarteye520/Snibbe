//
//  BubbleHarpViewController.m
//  BubbleHarp
//
//  Created by Colin Roache on 9/14/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "BubbleHarpViewController.h"
#import <CoreFoundation/CoreFoundation.h>

@interface BubbleHarpViewController()
- (void)loadTextures;

@end

@implementation BubbleHarpViewController

@synthesize animating, animationFrameInterval, context, displayLink;

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
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
	bubbleHarpView = [[BubbleHarpView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.view = bubbleHarpView;
	
	 
	
	// force to 1.1 OpenGL
	EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	
	if (!aContext)
		NSLog(@"Failed to create ES context");
	else if (![EAGLContext setCurrentContext:aContext])
		NSLog(@"Failed to set ES context current");
	
	self.context = aContext;
	self.displayLink = nil;
	
	[bubbleHarpView setContext:self.context];
	
	[self loadTextures];
	
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
	
	[bubbleHarpView setFramebuffer];
	
	glClearColor(0.0, 0.0, 0.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);
#warning Move to BubbleHarpView
	gBubbleHarp->update(1.f/60.f);
	gBubbleHarp->draw();
	
	[bubbleHarpView presentFramebuffer];
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

#pragma mark - Private Methods
- (void)loadTextures
{
	UIImage *image = [UIImage imageNamed:@"picture1_1.png"];
	
	CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    GLvoid *imageData = malloc( screenSize.height * screenSize.width * sizeof(GLubyte[4]));
    CGContextRef bmcontext = CGBitmapContextCreate( imageData, screenSize.width, screenSize.height, 8, 4 * screenSize.width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
    CGColorSpaceRelease( colorSpace );
    CGContextClearRect( bmcontext, CGRectMake( 0, 0, screenSize.width, screenSize.height ) );
	
	// Switch from UIKit to CoreGraphics coordinate systems
	CGContextScaleCTM(bmcontext, 1.f, -1.f);
	CGContextTranslateCTM(bmcontext, 0.f, -screenSize.height);
	
	if (image) {
		CGContextDrawImage( bmcontext, [UIScreen mainScreen].bounds, image.CGImage );
	}
	
	glActiveTexture(GL_TEXTURE0);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, screenSize.width, screenSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
	
    CGContextRelease(bmcontext);
    
    free(imageData);
}
@end
