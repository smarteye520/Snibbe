//
//  ColorWheelView.m
//  SnibbeLib
//
//  Created by Colin Roache on 10/6/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "ColorWheelView.h"
#import "SnibbeUtilsiOS.h"


#define PICKER_RADIUS		11
#define RADIUS_CONSTRAIN 0.97f



@interface ColorWheelView (Private)

- (void) doSetColor: (UIColor *) c informDelegate: (bool) bInform resampleLuma: (bool) resample;
- (void) doSetLuminosity: (float) luma resampleColor: (bool) resample;

- (void)drawFilledCircleWithColor:(CGColorRef)circleColor atPoint:(CGPoint)p scale:(CGFloat)s;
- (void)calculateColor;
- (CGFloat)preceivedLuminosity:(CGColorRef)colorToAnalyze;
- (void) sampleColorAtPoint:(CGPoint)p;
- (CGPoint) touchPointToColorWheelPoint: (CGPoint) p;
- (CGPoint) colorWheelPointToTouchPoint: (CGPoint) p;
- (void)sampleLumaAtPoint:(CGPoint)p;
- (UIColor *)colorOfImage:(CGImageRef)img withData:(NSData*)imageData atPoint:(CGPoint)p useLuma:(BOOL)useLuma;
- (BOOL)hitTestPoint:(CGPoint)p forImage:(CGImageRef)img withData:(NSData *)imgData useAlpha:(BOOL)useAlpha;
- (CGPoint)constrainToLumaStrip:(CGPoint)touch;
- (CGPoint)constrainToColorWheel:(CGPoint)touch;


- (CGPoint) imagePointForColor: (CGColorRef) c;


- (void) onLuminosityChange;

@end


@implementation ColorWheelView


#pragma mark property implementations

@synthesize delegate_;

@dynamic color;

// Changing the color should also change the luminosity
-(void) setColor:(UIColor *)c
{
 
    // update our handle position
    CGPoint newColorPoint = [self imagePointForColor: c.CGColor];
    //newColorPoint = [self colorWheelPointToTouchPoint: newColorPoint];
    colorPoint = newColorPoint;
    
    [self doSetColor: c informDelegate: false  resampleLuma: true];
}

- (UIColor *) color
{
    return color;
}


@dynamic luminosity;

//
// Changing the luminosity should also change the resulting color
-(void) setLuminosity:(float) l
{        
    
    [self doSetLuminosity: l resampleColor:true];
        

}

- (float) luminosity
{
    return luminosity;
}


- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame: frame];
	
    if(self) 
    {
		
        draggingColor = NO;		
		self.delegate_ = nil;        

		colorWheelImage = [[UIImage imageNamed:@"color_wheel.png"] retain];		        
		colorWheelMask= [[UIImage imageNamed: @"color_wheel_mask.png"] retain];
        colorWheelOutline = [[UIImage imageNamed: @"color_wheel_outline.png"] retain];
        
        
        colorWheelData = (NSData*) CGDataProviderCopyData(CGImageGetDataProvider(colorWheelImage.CGImage));
        
        //colorWheelWithLuminosity = nil;        


        
        colorWheelBGRectParentRel = CGRectMake( (frame.size.width - colorWheelImage.size.width) * 0.5f + frame.origin.x,
                                       (frame.size.height - colorWheelImage.size.height) * 0.5f + frame.origin.y,
                                        colorWheelImage.size.width, colorWheelImage.size.height);
        
        colorWheelBGRect = CGRectMake( (frame.size.width - colorWheelImage.size.width) * 0.5f,
                                      (frame.size.height - colorWheelImage.size.height) * 0.5f,
                                      colorWheelImage.size.width, colorWheelImage.size.height);
        

        colorWheelOutlineRectParentRel = CGRectMake( (frame.size.width - colorWheelOutline.size.width) * 0.5f + frame.origin.x,
                                           (frame.size.height - colorWheelOutline.size.height) * 0.5f + frame.origin.y,
                                           colorWheelOutline.size.width, colorWheelOutline.size.height);
        
        colorWheelOutlineRect = CGRectMake( (frame.size.width - colorWheelOutline.size.width) * 0.5f,
                                            (frame.size.height - colorWheelOutline.size.height) * 0.5f,
                                            colorWheelOutline.size.width, colorWheelOutline.size.height);
        
        colorWheelCenterParentRel = CGPointMake( colorWheelBGRectParentRel.origin.x + colorWheelBGRectParentRel.size.width * 0.5f,
                                       colorWheelBGRectParentRel.origin.y + colorWheelBGRectParentRel.size.height * 0.5f );
        
        colorWheelCenter = CGPointMake( colorWheelBGRect.origin.x + colorWheelBGRect.size.width * 0.5f,
                                       colorWheelBGRect.origin.y + colorWheelBGRect.size.height * 0.5f );
        
        
		colorPoint = colorWheelCenter;
        
        
        
        color = nil;
        colorPreMult = nil;

        [self doSetColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] informDelegate:false  resampleLuma: false];		
        
        colorLuma = nil;
		self.luminosity = 1.0f;        
        		
        // creat the path that helps us draw our selection circle
		// Create a mutable path, draw the circle, copy into an immutable class
		// variable and release our mutable copy
		CGMutablePathRef circleWorkingPath = CGPathCreateMutable();
		int definition = ceil(PICKER_RADIUS*PICKER_RADIUS);
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
	}
	return self;
}

- (void)dealloc
{


    if ( colorWheelImage )
    {
        [colorWheelImage release];
    }

    if ( colorWheelMask )
    {
        [colorWheelMask release];
    }
    
    if ( colorWheelOutline )
    {
        [colorWheelOutline release];
    }
    
    
//    if ( colorWheelWithLuminosity )
//    {
//        [colorWheelWithLuminosity release];
//    }
       
    if ( color )
    {
        [color release];
        color = nil;    
    }
        
	
    if ( colorPreMult )
    {            
        [colorPreMult release];
    }


    if ( colorWheelData )
    {
        CFRelease( colorWheelData );
    }
    
	CGPathRelease(circlePath);
    
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSaveGState(context);
	{	
        CGColorSpaceRef	colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextSetFillColorSpace(context, colorSpace);
        CGContextSetStrokeColorSpace(context, colorSpace);
        CGColorSpaceRelease(colorSpace);		
        
        
		CGContextSetBlendMode(context, kCGBlendModeNormal);		
		[colorWheelImage drawInRect: colorWheelBGRect];
        
        CGContextSaveGState(context);
        
        CGContextSetBlendMode(context, kCGBlendModeMultiply);
        CGContextClipToMask(context, colorWheelBGRect, colorWheelMask.CGImage);
        [colorLuma setFill];        
        CGContextFillRect(context, colorWheelBGRect);
        
        CGContextRestoreGState(context);
        
        
        
        //kCGBlendModeDarken
        
        //kCGBlendModeDestinationIn
        
        //
        //
        //CGImageRelease(mask);
        
//        CGContextDrawImage(context, CGRectMake(0, 0, _w, _h), handle());
//         // Don't apply the clip mask to 'other', since it already has it
//        
//        CGContextDrawImage(context, CGRectMake(0, 0, other->width(), other->height()), other->handle());
        
        //[colorWheelWithLuminosity drawInRect: rect];
        
        
        
        
        //CGContextSetBlendMode(context, kCGBlendModeDestinationIn);	
        
        
		CGContextSetBlendMode(context, kCGBlendModeNormal);		
		[colorWheelOutline drawInRect: colorWheelOutlineRect];

        
        //[context s
        
        
        
		// Color circle
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        UIColor *colorFullAlpha = [color colorWithAlphaComponent: 1.0f];
		[self drawFilledCircleWithColor:colorFullAlpha.CGColor atPoint:colorPoint scale:1.];
        
        //CGContextRestoreGState(context);
        
	}
	CGContextRestoreGState(context);

}

#pragma mark - Touch events
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint touchPoint = [(UITouch*)[touches anyObject] locationInView:self];

	if ([self hitTestPoint:touchPoint forImage:colorWheelImage.CGImage withData:colorWheelData useAlpha:YES]) 
    {
		draggingColor = YES;				
		[self sampleColorAtPoint:touchPoint];
	}
    
	if (draggingColor) {
		[self setNeedsDisplay];
	}
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint touchPoint = [(UITouch*)[touches anyObject] locationInView:self];
	if (draggingColor) {
		[self sampleColorAtPoint:touchPoint];
	}
    	
	if (draggingColor) {
		[self setNeedsDisplay];
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	draggingColor = NO;
}

#pragma mark - Private Methods


//
//
- (void) doSetColor: (UIColor *) c informDelegate: (bool) bInform  resampleLuma: (bool) resample
{
    
    if ( color )
    {
        [color release];
        color = nil;    
    }
    
    color = [c retain];        
    
    if ( resample )
    {
        // update our luminosity and the resulting color wheel image
        // (without resampling the color since we just set it here... would create
        // circular dependency)
        [self doSetLuminosity: colorLuminance( color.CGColor ) resampleColor: false];
        
        [self onLuminosityChange];    
    }
    
    [self setNeedsDisplay];
    
    if ( delegate_ && bInform )
    {                
        CGColorRef colRef = c.CGColor;        
        [delegate_ onColorChanged: colRef];
    }
    
}

- (void) doSetLuminosity: (float) luma resampleColor: (bool) resample
{
    
    luminosity = luma;
    
    if ( colorLuma )
    {
        [colorLuma release];
    }
    
    
    colorLuma = [[UIColor colorWithRed:luminosity green:luminosity blue:luminosity alpha:1.0f] retain];
    
    [self onLuminosityChange];
    
    if ( resample )
    {
        [self sampleColorAtPoint: colorPoint];
    }
    
    [self setNeedsDisplay];
    
}
- (void)drawFilledCircleWithColor:(CGColorRef)circleColor atPoint:(CGPoint)p scale:(CGFloat)s
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	CGContextSetLineWidth(context, 2.0);
	CGContextTranslateCTM(context, p.x, p.y);
	CGContextScaleCTM(context, s, s);
	
	CGContextSetFillColor(context, CGColorGetComponents(circleColor));
	[[UIColor whiteColor] setStroke];
	CGContextSetBlendMode(context, kCGBlendModeCopy);
	
	CGContextAddPath(context, circlePath);
	CGContextDrawPath(context, kCGPathFillStroke);

	CGContextRestoreGState(context);
}

//
//
- (void)calculateColor
{    
    
	const CGFloat* colorComponents = CGColorGetComponents(colorPreMult.CGColor);
	UIColor * multipliedColor = [UIColor colorWithRed:colorComponents[0]*luminosity
												green:colorComponents[1]*luminosity
												 blue:colorComponents[2]*luminosity
												alpha:colorComponents[3]];
	
	//[self setValue:multipliedColor forKey:@"color"];
    
    [self doSetColor: multipliedColor informDelegate:true  resampleLuma: false];
    
	[self setNeedsDisplay];
}




//
//
- (CGFloat)preceivedLuminosity:(CGColorRef)colorToAnalyze
{
	// Calculate preceived brightness using photometric/digital ITU-R color weighting
	// Source: http://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color
	// Y = 0.2126 R + 0.7152 G + 0.0722 B
	const CGFloat* components = CGColorGetComponents(colorToAnalyze);
	CGFloat luma = 0.2126 * components[0] + 0.7152 * components[1] + 0.0722 * components[2];
	return luma;
}

//
//
- (void)sampleColorAtPoint:(CGPoint)p
{
	colorPoint = [self constrainToColorWheel:p]; // color point in frame coords, not image coords
        
    // first translate point
    CGPoint imagePoint = [self touchPointToColorWheelPoint: colorPoint];    
    imagePoint = CGPointMult(imagePoint, self.contentScaleFactor);
    
	UIColor * colorSample = [self colorOfImage:colorWheelImage.CGImage withData: colorWheelData atPoint:imagePoint useLuma:YES];
	        
    if ( colorPreMult )
    {
        [colorPreMult release];
    }
    
	colorPreMult = [colorSample retain];	    
    
	[self calculateColor];
            
}

//
//
- (CGPoint) touchPointToColorWheelPoint: (CGPoint) p
{
    CGPoint delta = CGPointSub( colorWheelBGRectParentRel.origin, self.frame.origin );
    CGPoint colorP = CGPointSub( p, delta);
    return colorP;    
}

//
//
- (CGPoint) colorWheelPointToTouchPoint: (CGPoint) p
{
    CGPoint delta = CGPointSub( colorWheelBGRect.origin, self.frame.origin );
    CGPoint colorP = CGPointAdd( p, delta);
    return colorP;    
}


//
//
- (UIColor *)colorOfImage:(CGImageRef)img withData:(NSData*)imageData atPoint:(CGPoint)p useLuma:(BOOL)useLuma
{
    

    
	unsigned char* data = (unsigned char *)[imageData bytes];
	int bytesPerRow = CGImageGetBytesPerRow(img);
	int bytesPerPixel = CGImageGetBitsPerPixel(img) / 8;
	int byteIndex = (bytesPerRow * ROUNDINT(p.y)) + bytesPerPixel * ROUNDINT(p.x);
		
	// We are in RGBA
	Byte red = data[byteIndex + 0];
	Byte green = data[byteIndex + 1];
	Byte blue = data[byteIndex + 2];
	Byte alpha = data[byteIndex + 3];
	
	CGFloat brightness = 1.;
//	if (useLuma) {
//		brightness = [self brightness:lumaColor.CGColor]*2.;
//	}
	
	return [UIColor colorWithRed:MIN(((float)red*brightness/255.0f), 1.0f)
						   green:MIN(((float)green*brightness/255.0f), 1.0f)
							blue:MIN(((float)blue*brightness/255.0f), 1.0f)
						   alpha:(float)(alpha/255.0f)];
}

//
//
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
	int byteIndex = (bytesPerRow * ROUNDINT(p.y)) + bytesPerPixel * ROUNDINT(p.x);
	
	
	// We are in RGBA
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


- (CGPoint)constrainToColorWheel:(CGPoint)touch
{
    //NSLog( @"touch: %@\n", NSStringFromCGPoint( touch ) );    
    
    CGPoint imagePoint =[ self touchPointToColorWheelPoint: touch];
    imagePoint = CGPointMult(imagePoint, self.contentScaleFactor);
    
	if([self hitTestPoint:imagePoint forImage:colorWheelImage.CGImage withData:colorWheelData useAlpha:YES]) {
		return touch;
	}
    
    CGSize colorWheelSize = colorWheelImage.size;
    float radius = colorWheelSize.width * 0.5f;
    
    radius *= RADIUS_CONSTRAIN; // don't get off the wheel
    
	CGPoint dragVector = CGPointMake(touch.x - colorWheelCenter.x, touch.y - colorWheelCenter.y);
	float dragVectorLength = sqrt(dragVector.x*dragVector.x + dragVector.y*dragVector.y);
	CGPoint dragUnitVector = CGPointMake(dragVector.x / dragVectorLength, dragVector.y / dragVectorLength);
	CGPoint	constrainedPoint = CGPointMake(dragUnitVector.x * radius + colorWheelCenter.x,
											  dragUnitVector.y * radius + colorWheelCenter.y);

    return constrainedPoint;
    
}

//
//
- (CGPoint) imagePointForColor: (CGColorRef) c
{
    
    // hue is in radians from 0 to 2 PI
    float hue = colorHue( c );
    float sat = colorSat( c );
    
    
    // our image is rotated by 128 deg clockwise.
    
    float radCorrectionForImage = -(128.0f/360.0f) * 2.0f * M_PI;
    hue += radCorrectionForImage;
    
    CGPoint hueVec = CGPointMake( sinf(hue), cosf(hue));
    
    CGSize colorWheelSize = colorWheelImage.size;
    float radius = colorWheelSize.width * 0.5f * RADIUS_CONSTRAIN * sat;
    
    return CGPointMake(colorWheelCenter.x + hueVec.x * radius, colorWheelCenter.y - hueVec.y * radius);        
    
}


// this creates a new color wheel UIImage with premultiplied luminosity.
// Turned out to be too computationally expensive for realtime slider adjustment
// but useful for the future so keeping it around.  :)
- (void) onLuminosityChange
{

    /*
    
    if ( colorWheelWithLuminosity )
    {
        [colorWheelWithLuminosity release];
    }    
            
    
    CGImageRef colorRef = colorWheelImage.CGImage;    
    CGContextRef ctx;     
    
    // make a copy of the image data from the unmodified color wheel image
    CFDataRef colorDataRef = CGDataProviderCopyData( CGImageGetDataProvider( colorRef ) );     
    
    // get a pointer to the pixel bytes
    UInt8 * pixelData = (UInt8 *) CFDataGetBytePtr(colorDataRef);     

    
    // adjust brightness
    int length = CFDataGetLength(colorDataRef);     
    for (int index = 0; index < length; index += 4) 
    { 
  
        unsigned char * pixelComponents = (&pixelData[index]);
        
        pixelComponents[0] = (unsigned char) ROUNDINT( pixelComponents[0] * luminosity );
        pixelComponents[1] = (unsigned char) ROUNDINT( pixelComponents[1] * luminosity );       
        pixelComponents[2] = (unsigned char) ROUNDINT( pixelComponents[2] * luminosity );                          
        
    } 
    
    
        
    ctx = CGBitmapContextCreate(pixelData, 
                                CGImageGetWidth( colorRef ), 
                                CGImageGetHeight( colorRef ), 
                                CGImageGetBitsPerComponent( colorRef ), 
                                CGImageGetBytesPerRow( colorRef ), 
                                CGImageGetColorSpace( colorRef ), 
                                kCGImageAlphaPremultipliedLast ); 
    
    
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx); 
    colorWheelWithLuminosity = [UIImage imageWithCGImage:imageRef]; 
    [colorWheelWithLuminosity retain];
        
    CFRelease( imageRef );
    CFRelease( colorDataRef );    
    CGContextRelease(ctx); 
        
     */
}


@end
