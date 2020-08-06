/*
     File: ScaleView.m
	(c) 2010 Scott Snibbe
 
 */

#include "defs.h"
#include "Parameters.h"
#import "ScaleView.h"

#define MAIN_FONT_SIZE 20
#define MIN_MAIN_FONT_SIZE 16

@implementation ScaleView

@synthesize title, color, scaleIndex;

const CGFloat kViewWidth = 300;
const CGFloat kViewHeight = 44;
const float	  kSwatchLength = 45;
const float	  kSwatchWidth = 6;

+ (CGFloat)viewWidth
{
    return kViewWidth;
}

+ (CGFloat)viewHeight 
{
    return kViewHeight;
}

- (id)initWithFrame:(CGRect)frame
{
	// use predetermined frame size
	if (self = [super initWithFrame:CGRectMake(0.0, 0.0, kViewWidth, kViewHeight)])
	{
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.backgroundColor = [UIColor clearColor];	// make the background transparent
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	// draw the image and title using their draw methods
	CGFloat yCoord = self.bounds.size.height / 2;
	CGPoint point = CGPointMake(10.0, yCoord);
	//[self.image drawAtPoint:point];
	// set line color
	// draw line from (10,yCoord) to (10+kSwatchLength,yCoord) $$$$
	
	CGContextRef c = UIGraphicsGetCurrentContext();
	
    //CGFloat *rgba = gBubbleHarp->params()->scaleColor();
	CGContextSetLineWidth(c, kSwatchWidth);
    CGContextSetStrokeColor(c, color);
    CGContextBeginPath(c);
    CGContextMoveToPoint(c, 10.0f, yCoord);
    CGContextAddLineToPoint(c, 10.0f + kSwatchLength, yCoord);
    CGContextStrokePath(c);
	
	yCoord = (self.bounds.size.height - MAIN_FONT_SIZE) / 2;
	point = CGPointMake(10.0 + kSwatchLength + 10.0, yCoord-1);
	[self.title drawAtPoint:point
					forWidth:self.bounds.size.width
					withFont:[UIFont boldSystemFontOfSize:MAIN_FONT_SIZE]
					minFontSize:MIN_MAIN_FONT_SIZE
					actualFontSize:NULL
					lineBreakMode:UILineBreakModeTailTruncation
					baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
}

- (void)dealloc
{
	color = nil;
	
}

@end
