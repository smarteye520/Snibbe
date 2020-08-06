//
//  ColorCircle.m
//  Gravilux
//
//  Created by Colin Roache on 10/10/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "ColorCircle.h"

@implementation ColorCircle
@synthesize color;
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
		self.clearsContextBeforeDrawing = NO;
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		
		color = [[UIColor colorWithRed:1. green:1. blue:1. alpha:1.] retain];
		
		// Create a mutable path, draw the circle, copy into an immutable class
		// variable and release our mutable copy
		CGMutablePathRef circleWorkingPath = CGPathCreateMutable();
		int radius = MIN(self.frame.size.height, self.frame.size.width) / 2;
		int definition = ceil(radius * radius);
		CGPathMoveToPoint(circleWorkingPath, NULL, radius*sinf(0), radius*cosf(0));
		for (int i = 0; i < definition; i++) {
			float radians = ((float)i/(float)definition)*M_PI*2.;
			CGPathAddLineToPoint(circleWorkingPath, NULL, radius*sinf(radians), radius*cosf(radians));
		}
		CGPathCloseSubpath(circleWorkingPath);
		circlePath = CGPathCreateCopy(circleWorkingPath);
		CGPathRelease(circleWorkingPath);
    }
    return self;
}

- (void)dealloc
{
	[color release];
	CGPathRelease(circlePath);
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	CGPoint centerPoint = CGPointMake(rect.size.width / 2 + rect.origin.x, rect.size.height / 2 + rect.origin.y);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSaveGState(context);
	CGContextSetLineWidth(context, 2.0);
	CGContextTranslateCTM(context, centerPoint.x, centerPoint.y);
	
	CGContextSetFillColor(context, CGColorGetComponents(color.CGColor));
	[[UIColor whiteColor] setStroke];
	CGContextSetBlendMode(context, kCGBlendModeCopy);
	
	CGContextAddPath(context, circlePath);
	CGContextDrawPath(context, kCGPathFill);
	
	CGContextRestoreGState(context);
}

- (UIColor *)getColor
{
	return color;
}

- (void)setColor:(UIColor *)colorIn
{
	
//		const CGFloat* components = CGColorGetComponents(colorIn.CGColor);
//		NSLog(@"Red: %f", components[0]);
//		NSLog(@"Green: %f", components[1]);
//		NSLog(@"Blue: %f", components[2]);
	//	NSLog(@"Alpha: %f", CGColorGetAlpha(color.CGColor));
	[color release];
	color = [colorIn retain];
	[self setNeedsDisplay];
}

@end
