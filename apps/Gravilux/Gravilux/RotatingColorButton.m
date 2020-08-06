//
//  RotatingColorButton.m
//  Gravilux
//
//  Created by Colin Roache on 11/18/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "RotatingColorButton.h"

@implementation RotatingColorButton
@synthesize render;
- (void) dealloc
{
	[startTime release];
	[imageOff release];
	[imageOn release];
	[mask release];
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
    if (self) {
		render = NO;
		
		// Start with opaque black
		color[0] = 0.;
		color[1] = 0.;
		color[2] = 0.;
		color[3] = 1.;
		
		// Record the current time of which		to base all animation off
		startTime = [[NSDate date] retain];

		// Load in the button image and a useful mask image that has the center of the button filled
		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2){
			imageOff = [[UIImage imageNamed:@"color_music_off@2x.png"] retain];
			imageOn = [[UIImage imageNamed:@"color_music_on@2x.png"] retain];
		} else {
			imageOff = [[UIImage imageNamed:@"color_music_off.png"] retain];
			imageOn = [[UIImage imageNamed:@"color_music_on.png"] retain];
		}
		mask = [[UIImage imageNamed:@"circle_mask.png"] retain];

		// Set up UIView properties to allow us to have a transparent background
		self.clearsContextBeforeDrawing = NO;
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	// Base the display image on the UIControl.selected state
	UIImage *displayImage = self.selected?imageOn:imageOff;
	
	// Update color based on animation time
	NSTimeInterval elapsedTime = -1. * [startTime timeIntervalSinceNow];
	int elapsedSeconds = floor(elapsedTime);
	for (int i = 0; i < 3; i++) {
		color[++elapsedSeconds%3] = 1. - ABS((elapsedTime - elapsedSeconds) * 2. - 1.);
	}
	
    // Draw
	CGContextRef c = UIGraphicsGetCurrentContext();
	
	// Push clip mask
	CGContextSaveGState(c);
	
	// Clip the filled color to our mask, which will prevent us from coloring around the edge of the image
	CGContextClipToMask(c, rect, mask.CGImage);
	
	// Fill with the current color
	CGContextSetFillColor(c, color);
	CGContextFillRect(c, rect);
	
	// Pop clip mask
	CGContextRestoreGState(c);
	
	// Draw display image (the one that is being drawn behind
	[displayImage drawInRect:rect];
	
	// Shade when disabled
//	if (!self.enabled) {
//		self.alpha = .5;
//	} else {
//		self.alpha = 1.;
//	}
	
	// Tie into render loop
	if (render) {
		[self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:0. inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, UITrackingRunLoopMode, nil]];
	}
}

@end
