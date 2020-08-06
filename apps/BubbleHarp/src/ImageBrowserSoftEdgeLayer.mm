/* File: ImageBrowserSoftEdgeLayer.m
 
 Abstract: Implementation file for edge masking layer subclass.
 
 Version: 1.0
 
 (c) 2010 Scott Snibbe */

#import "ImageBrowserSoftEdgeLayer.h"
#include "defs.h"

#define EDGE_SIZE_IPAD 100
#define EDGE_SIZE_IPHONE 50
#define BG_COLOR 1.0

@implementation ImageBrowserSoftEdgeLayer

- (void)layoutSublayers
{
	if (IS_IPAD) {
		edgeSize = EDGE_SIZE_IPAD;
	} else {
		edgeSize = EDGE_SIZE_IPHONE;
	}
	
	/* When the layer is being used as a mask the alpha at the edge of the
     layer should be zero and one in the middle. When the layer is
     composited over the scroller the alpha should be one at the edge
     and zero in the middle (in which case we only need the two edge
     layers, not the 'middle' layer as well). */
	
	BOOL invert_alpha = self.superlayer.mask == self;
	
	CAGradientLayer *left_edge = nil, *right_edge = nil;
	CALayer *middle = nil;
	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	if ([self.sublayers count] == 0)
    {
		/* We're assuming in the non-masking case (invert_alpha = YES)
         that the backdrop created by our superlayer is white. So
         create a white gradient whose alpha varies from opaque to
         transparent, with the opaque edge aligned to the inside of the
         layer. In the case where this layer is being used to mask the
         backdrop (invert_alpha = NO) only the alpha values we create
         are relevant, and in that case we want the opaque gradient
         edge to be on the inside, so that only the edges are masked
         out. */
		
		NSArray *colors = [NSArray arrayWithObjects:
						   (id)[UIColor colorWithWhite:BG_COLOR alpha:1].CGColor,
						   (id)[UIColor colorWithWhite:BG_COLOR alpha:0].CGColor,
						   nil];
		
		CGPoint axis0 = CGPointMake(0, 0.5);
		CGPoint axis1 = CGPointMake(1, 0.5);
		
		left_edge = [CAGradientLayer layer];
		left_edge.colors = colors;
		left_edge.startPoint = !invert_alpha ? axis0 : axis1;
		left_edge.endPoint = !invert_alpha ? axis1 : axis0;
		
		right_edge = [CAGradientLayer layer];
		right_edge.colors = colors;
		right_edge.startPoint = !invert_alpha ? axis1 : axis0;
		right_edge.endPoint = !invert_alpha ? axis0 : axis1;
		
		if (invert_alpha)
        {
			middle = [CALayer layer];
			middle.backgroundColor = [UIColor whiteColor].CGColor;
        }
		
		self.sublayers = [NSArray arrayWithObjects:
						  left_edge, right_edge, middle, nil];
    }
	else
    {
		left_edge = [self.sublayers objectAtIndex:0];
		right_edge = [self.sublayers objectAtIndex:1];
		middle = invert_alpha ? [self.sublayers objectAtIndex:2] : nil;
    }
	
	CGRect bounds = self.bounds;
	
	left_edge.frame = CGRectMake(bounds.origin.x, bounds.origin.y,
								 edgeSize, bounds.size.height);
	right_edge.frame = CGRectMake((bounds.origin.x + bounds.size.width)- edgeSize, bounds.origin.y,
								  edgeSize, bounds.size.height);
	if (invert_alpha)
		middle.frame = CGRectInset(bounds, 0, edgeSize);
	
	self.masksToBounds = YES;
	
	[CATransaction commit];
}

@end
