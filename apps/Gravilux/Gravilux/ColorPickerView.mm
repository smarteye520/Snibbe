//
//  ColorPickerView.m
//  Gravilux
//
//  Created by Colin Roache on 10/6/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "ColorPickerView.h"

#import "SnibbeUtils.h"
#import "GraviluxViewController.h"
#import "Visualizer.h"
	
//
// returns the maximum of R,G,B
float colorLuminance( CGColorRef colorToAnalyze )
{
	const CGFloat* components = CGColorGetComponents(colorToAnalyze);
	
	float maxComponent = MAX( components[0], components[1] );
	maxComponent = MAX( maxComponent, components[2] );
	
	
	return maxComponent;
}

//
// returns average of R,G,B
float colorBrightness( CGColorRef colorToAnalyze )
{
	const CGFloat* components = CGColorGetComponents(colorToAnalyze);
	return (components[0] + components[1] + components[2]) / 3.;
}

//
//
float colorRed( CGColorRef colorToAnalyze )
{
	const CGFloat* components = CGColorGetComponents(colorToAnalyze);
	return components[0];        
}

//
//
float colorGreen( CGColorRef colorToAnalyze )
{
	const CGFloat* components = CGColorGetComponents(colorToAnalyze);
	return components[1];        
}

//
//
float colorBlue( CGColorRef colorToAnalyze )
{
	const CGFloat* components = CGColorGetComponents(colorToAnalyze);
	return components[2];        
}

//
//
float colorAlpha( CGColorRef colorToAnalyze )
{
	const CGFloat* components = CGColorGetComponents(colorToAnalyze);
	return components[3];        
}


//
//
float colorHue( CGColorRef colorToAnalyze )
{
	const CGFloat* components = CGColorGetComponents(colorToAnalyze);
	float r = components[0];        
	float g = components[1];        
	float b = components[2];        
	
	// calculation from http://en.wikipedia.org/wiki/Hue
	float rads = atan2f( 2*r - g - b, sqrtf(3.0) * (g-b) );
	if ( rads < 0 )
	{
		rads += M_PI * 2;
	}
	
	return rads;
}


//
//
float colorSat( CGColorRef colorToAnalyze )
{
	const CGFloat* components = CGColorGetComponents(colorToAnalyze);
	float r = components[0];        
	float g = components[1];        
	float b = components[2];        
	
	float maxVal = MAX( r, g );
	maxVal = MAX( maxVal, b );
	
	float minVal = MIN( r, g );
	minVal = MIN( minVal, b );
	
	float delta = maxVal - minVal;
	
	delta = MAX( delta, 0.0f );
	delta = MIN( delta, 1.0f );
	
	if ( maxVal > .0001 )
	{
		return delta / maxVal;
	}
	
	return 0.0f;
	
}

#define RADIUS_CONSTRAIN 0.97f
#define PICKER_RADIUS		11
#define COLOR_RADIUS		65
#define COLOR_WHEEL_X		79
#define COLOR_WHEEL_Y		105
#define LUMA_RADIUS			112
#define LUMA_ANGLE_MIN		.25*M_PI+.01
#define LUMA_ANGLE_MAX		.75*M_PI
#define RAD_CORRECTION		-(128.0f/360.0f) * 2.0f * M_PI

@interface ColorPickerView (Private)
- (void)drawFilledCircleWithColor:(CGColorRef)circleColor atPoint:(CGPoint)p scale:(CGFloat)s;
- (CGFloat)preceivedLuminosity:(CGColorRef)colorToAnalyze;
- (void)sampleColorAtPoint:(CGPoint)p;
- (void)sampleLumaAtPoint:(CGPoint)p;
- (UIColor *)colorOfImage:(CGImageRef)img withData:(NSData*)imageData atPoint:(CGPoint)p;
- (BOOL)hitTestPoint:(CGPoint)p forImage:(CGImageRef)img withData:(NSData *)imgData useAlpha:(BOOL)useAlpha;
- (CGPoint)constrainToLumaStrip:(CGPoint)touch;
- (CGPoint)constrainToColorWheel:(CGPoint)touch;
- (CGPoint)pointForColor:(UIColor*)c;
- (void) multiplyColor;
@end
@implementation ColorPickerView

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if(self) {
		draggingColor = NO;
		draggingLuma = NO;
		
		colorPickerDisplayImage = [[UIImage imageNamed:@"color_wheel_outline.png"] retain];
		colorWheelImage = [[UIImage imageNamed:@"color_wheel_separate.png"] retain];
		colorWheelMask = [[UIImage imageNamed:@"color_wheel_mask.png"] retain];
		luminositySliderImage = [[UIImage imageNamed:@"color_wheel_luma_hit.png"] retain];
		
		colorWheelData = (NSData*) CGDataProviderCopyData(CGImageGetDataProvider(colorWheelImage.CGImage));
		lumaData = (NSData*) CGDataProviderCopyData(CGImageGetDataProvider(luminositySliderImage.CGImage));
		
		
		colorWheelCenter = CGPointMake(COLOR_WHEEL_X, COLOR_WHEEL_Y);
		
		lumaColor = [[UIColor colorWithRed:1. green:1. blue:1. alpha:1.] retain];
		lumaPoint = CGPointMake(LUMA_RADIUS * sinf(.75*M_PI) + colorWheelCenter.x,
								LUMA_RADIUS * cosf(.75*M_PI) + colorWheelCenter.y);
		colorPreMult = [[UIColor colorWithRed:1. green:1. blue:1. alpha:1.] retain];
		color = [[UIColor colorWithRed:1. green:1. blue:1. alpha:1.] retain];
		colorPoint = colorWheelCenter;
		
		// Create a mutable path, draw the circle, copy into an immutable class
		// variable and release our mutable copy
		CGMutablePathRef circleWorkingPath = CGPathCreateMutable();
		int definition = PICKER_RADIUS*4;
		CGPathMoveToPoint(circleWorkingPath, NULL, PICKER_RADIUS*sinf(0), PICKER_RADIUS*cosf(0));
		for (int i = 0; i < definition; i++) {
			float radians = ((float)i/(float)definition)*M_PI*2.;
			CGPathAddLineToPoint(circleWorkingPath, NULL, PICKER_RADIUS*sinf(radians), PICKER_RADIUS*cosf(radians));
		}
		CGPathCloseSubpath(circleWorkingPath);
		circlePath = CGPathCreateCopy(circleWorkingPath);
		CGPathRelease(circleWorkingPath);
		
		
		
		self.clearsContextBeforeDrawing = NO;
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		
		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
			float s = [[UIScreen mainScreen] scale];
			screenScale = CGAffineTransformMakeScale(s, s);
		} else {
			screenScale = CGAffineTransformMakeScale(1.f, 1.f);
		}
	}
	return self;
}

- (void)dealloc
{
	CGDataProviderRelease(CGImageGetDataProvider(colorWheelImage.CGImage));
	CGDataProviderRelease(CGImageGetDataProvider(luminositySliderImage.CGImage));
	[color release];
	[colorPreMult release];
	[lumaColor release];
	[colorPickerDisplayImage release];
	[colorWheelImage release];
	[colorWheelMask release];
	[luminositySliderImage release];
	CGPathRelease(circlePath);
}

#pragma mark - View Lifecycle
- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSaveGState(context);
	{	
		CGColorSpaceRef	colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextSetFillColorSpace(context, colorSpace);
		CGContextSetStrokeColorSpace(context, colorSpace);
		CGColorSpaceRelease(colorSpace);
		
		CGContextSetBlendMode(context, kCGBlendModeCopy);
		
		// Draw layers:
		//  Fully composited background image
		//  Luma circle and arm
		//  Isolated color wheel
		//	Luma color (blend with color wheel, mask with wheel mask)
		//  Color circle
		
		// Full display
		CGContextScaleCTM(context, 1.f, -1.f);
		CGRect displayRect = CGContextConvertRectToUserSpace(context, rect);
		displayRect = CGRectApplyAffineTransform(displayRect, screenScale);
		CGContextDrawImage(context, displayRect, colorPickerDisplayImage.CGImage);
		CGContextScaleCTM(context, 1.f, -1.f);
		
		// Luminance arm
		CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
		CGContextMoveToPoint(context, colorWheelCenter.x, colorWheelCenter.y);
		CGContextAddLineToPoint(context, lumaPoint.x, lumaPoint.y);
		CGContextDrawPath(context, kCGPathStroke);
		
		// Luminance circle
		[self drawFilledCircleWithColor:lumaColor.CGColor atPoint:lumaPoint scale:1.];
		
		// Fill area over the color wheel with luma color and blend
		CGContextSaveGState(context);
		{
			CGContextSetBlendMode(context, kCGBlendModeNormal);
			CGContextScaleCTM(context, 1.f, -1.f);
			CGContextDrawImage(context, displayRect, colorWheelImage.CGImage);
			CGContextScaleCTM(context, 1.f, -1.f);
			
			CGContextClipToMask(context, rect, colorWheelMask.CGImage);
			CGContextSetBlendMode(context, kCGBlendModeMultiply);
			CGContextSetFillColorWithColor(context, lumaColor.CGColor);
			CGContextFillRect(context, rect);
		}
		CGContextRestoreGState(context);
		
		
		// Color circle
		[self drawFilledCircleWithColor:color.CGColor atPoint:colorPoint scale:1.];
	}
	CGContextRestoreGState(context);

}

#pragma mark Touch events
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (gGravilux->visualizer()->running() && gGravilux->visualizer()->colorWalk()) {
		return;
	}
	CGPoint touchPoint = [(UITouch*)[touches anyObject] locationInView:self];

	if ([self hitTestPoint:touchPoint forImage:colorWheelImage.CGImage withData:colorWheelData useAlpha:YES]) {
		draggingColor = YES;
		draggingLuma = NO;
		
		[self sampleColorAtPoint:touchPoint];
	}
	else if ([self hitTestPoint:touchPoint forImage:luminositySliderImage.CGImage withData: lumaData useAlpha:YES]) {
		draggingColor = NO;
		draggingLuma = YES;
		
		[self sampleLumaAtPoint:touchPoint];
	}
	
	if (draggingColor || draggingLuma) {
		[self setNeedsDisplay];
	}
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint touchPoint = [(UITouch*)[touches anyObject] locationInView:self];
	if (draggingColor) {
		[self sampleColorAtPoint:touchPoint];
	}
	else if(draggingLuma) {
		[self sampleLumaAtPoint:touchPoint];
	}
	
	if (draggingColor || draggingLuma) {
		[self setNeedsDisplay];
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	draggingColor = NO;
	draggingLuma = NO;
}

#pragma mark Accessors

- (UIColor *)color
{
	return color;
}

- (void) setColor:(UIColor *)colorIn
{
	float hue = colorHue( colorIn.CGColor );
	float sat = colorSat( colorIn.CGColor );
	float luma = colorLuminance( colorIn.CGColor );
	hue = (hue / (2. * M_PI));
	
	if (color)
		[color release];
	color = [colorIn retain];
	if (colorPreMult) {
		[colorPreMult release];
	}
	colorPreMult = [[UIColor colorWithHue:hue saturation:sat brightness:1. alpha:1.] retain];
	
	// Calculate where the this color is located
	colorPoint = [self pointForColor:colorIn];
	
	if (lumaColor) {
		[lumaColor release];
	}
	lumaColor = [[UIColor colorWithRed:luma
								 green:luma
								  blue:luma
								 alpha:1.] retain];

	const float range = LUMA_ANGLE_MAX - LUMA_ANGLE_MIN;
	float theta = (luma * range) - .5 * range;
	lumaPoint = CGPointMake(LUMA_RADIUS * sinf(.5*M_PI + theta) + colorWheelCenter.x,
							LUMA_RADIUS * cosf(.5*M_PI + theta) + colorWheelCenter.y);
	
	[self setNeedsDisplay];
}

#pragma mark - Private Methods

- (void)drawFilledCircleWithColor:(CGColorRef)circleColor atPoint:(CGPoint)p scale:(CGFloat)s
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	CGContextSetLineWidth(context, 2.0);
	CGContextTranslateCTM(context, p.x, p.y);
	CGContextScaleCTM(context, s, s);
	
	CGContextSetFillColorWithColor(context, circleColor);
	CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
	CGContextSetBlendMode(context, kCGBlendModeCopy);
	
	CGContextAddPath(context, circlePath);
	CGContextDrawPath(context, kCGPathFillStroke);

	CGContextRestoreGState(context);
}

- (CGFloat)preceivedLuminosity:(CGColorRef)colorToAnalyze
{
	// Calculate preceived brightness using photometric/digital ITU-R color weighting
	// Source: http://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color
	// Y = 0.2126 R + 0.7152 G + 0.0722 B
	const CGFloat* components = CGColorGetComponents(colorToAnalyze);
	CGFloat luma = 0.2126 * components[0] + 0.7152 * components[1] + 0.0722 * components[2];
	return luma;
}

- (void)sampleColorAtPoint:(CGPoint)p
{
	colorPoint = [self constrainToColorWheel:p];
	
	
	UIColor * sampledColor = [self colorOfImage:colorWheelImage.CGImage withData: colorWheelData atPoint:colorPoint];
	
	if (colorPreMult) {
		[colorPreMult release];
	}
	float hue = (colorHue(sampledColor.CGColor) / (2.*M_PI));
	colorPreMult = [[UIColor colorWithHue:hue saturation:colorSat( sampledColor.CGColor ) brightness:1. alpha:1.] retain];
	
	[self multiplyColor];
}

- (void)sampleLumaAtPoint:(CGPoint)p
{
	lumaPoint = [self constrainToLumaStrip:p];
	UIColor * lumaSample = [self colorOfImage:luminositySliderImage.CGImage withData: lumaData atPoint:lumaPoint];
	[lumaColor release];
	float luminance = colorLuminance( lumaSample.CGColor );
	lumaColor = [[UIColor colorWithRed:luminance green:luminance blue:luminance alpha:1.] retain];
	
	[self multiplyColor];
}

- (UIColor *)colorOfImage:(CGImageRef)img withData:(NSData*)imageData atPoint:(CGPoint)p
{
	unsigned char* data = (unsigned char *)[imageData bytes];
	int bytesPerRow = CGImageGetBytesPerRow(img);
	int bytesPerPixel = CGImageGetBitsPerPixel(img) / 8;
	int byteIndex = (bytesPerRow * roundf(p.y)) + bytesPerPixel * roundf(p.x);
		
	// We are in RGBA
	Byte red = data[byteIndex + 0];
	Byte green = data[byteIndex + 1];
	Byte blue = data[byteIndex + 2];
	Byte alpha = data[byteIndex + 3];
	
	return [UIColor colorWithRed:((float)red/255.0f)
						   green:((float)green/255.0f)
							blue:((float)blue/255.0f)
						   alpha:(float)(alpha/255.0f)];
}

- (BOOL)hitTestPoint:(CGPoint)p forImage:(CGImageRef)img withData:(NSData *)imgData useAlpha:(BOOL)useAlpha
{
	if ( p.x < 0 || p.y < 0
		|| p.x >= CGImageGetWidth(img)
		|| p.y >= CGImageGetHeight(img) ) {
		return NO;
	}
	unsigned char* data = (unsigned char *)[imgData bytes];
	int bytesPerRow = CGImageGetBytesPerRow(img);
	int bytesPerPixel = CGImageGetBitsPerPixel(img) / 8;
	int byteIndex = (bytesPerRow * roundf(p.y)) + bytesPerPixel * roundf(p.x);
	
	
	// We are in ARGB
	if (useAlpha) {
		Byte alpha = data[byteIndex + 3];
		return alpha == 255;
	}
	else {
		Byte red = data[byteIndex + 0];
		Byte green = data[byteIndex + 1];
		Byte blue = data[byteIndex + 2];
		return red+green+blue!=0;
	}
}

- (CGPoint)constrainToLumaStrip:(CGPoint)touch
{
	// Find the angle of the drag to the center of the color wheel
	CGPoint dragVector = CGPointMake(touch.x - colorWheelCenter.x, touch.y - colorWheelCenter.y);
	float dragVectorLength = sqrtf(dragVector.x*dragVector.x + dragVector.y*dragVector.y);
	CGPoint dragUnitVector = CGPointMake(dragVector.x / dragVectorLength, dragVector.y / dragVectorLength);
	float theta = acosf(dragUnitVector.y);
	
	// Restrict the angle
	theta = MAX(MIN(theta, LUMA_ANGLE_MAX), LUMA_ANGLE_MIN);
	
	// Project the vector to the radius
	return CGPointMake(LUMA_RADIUS * sinf(theta) + colorWheelCenter.x,
					   LUMA_RADIUS * cosf(theta) + colorWheelCenter.y);
}
- (CGPoint)constrainToColorWheel:(CGPoint)touch
{
	if([self hitTestPoint:touch forImage:colorWheelImage.CGImage withData:colorWheelData useAlpha:YES]) {
		return touch;
	}
	CGPoint dragVector = CGPointMake(touch.x - colorWheelCenter.x, touch.y - colorWheelCenter.y);
	float dragVectorLength = sqrt(dragVector.x*dragVector.x + dragVector.y*dragVector.y);
	CGPoint dragUnitVector = CGPointMake(dragVector.x / dragVectorLength, dragVector.y / dragVectorLength);
	CGPoint	dragProjectedVector = CGPointMake(dragUnitVector.x * COLOR_RADIUS + colorWheelCenter.x,
											  dragUnitVector.y * COLOR_RADIUS + colorWheelCenter.y);
	return dragProjectedVector;
}

- (CGPoint)pointForColor:(UIColor*)c
{
	float hue = colorHue( c.CGColor );
	float sat = colorSat( c.CGColor );
	
	
	// our image is rotated by 128 deg clockwise.
	hue += RAD_CORRECTION;
	
	CGPoint hueVec = CGPointMake( sinf(hue), cosf(hue));
	
	float radius = COLOR_RADIUS * sat;//colorWheelSize.width * 0.5f * RADIUS_CONSTRAIN * sat;
	
	return CGPointMake(colorWheelCenter.x + hueVec.x * radius, colorWheelCenter.y - hueVec.y * radius);
}

- (void) multiplyColor
{
	float hue = colorHue( colorPreMult.CGColor );
	hue = (hue / (2.*M_PI));
	float sat = colorSat( colorPreMult.CGColor );
	float luma = colorLuminance( lumaColor.CGColor );
	if (color) {
		[color release];
	}
	color = [[UIColor colorWithHue:hue saturation:sat brightness:luma alpha:1.] retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ColorPickerDidUpdateNotification" object:self];
	
}
@end
