//
//  ColorPickerView.h
//  Gravilux
//
//  Created by Colin Roache on 10/6/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ColorPickerView : UIView {
	UIImage *		colorPickerDisplayImage;
	UIImage *		colorWheelImage;
	UIImage *		colorWheelMask;
	UIImage *		luminositySliderImage;
	
	CGPathRef		circlePath;
	
	CGContextRef	colorWheelContext;
	CGContextRef	lumaSliderContext;
	
	CGPoint			colorWheelCenter;
	
	UIColor *		color;
	UIColor *		colorPreMult;
	CGPoint			colorPoint;
	
	UIColor *		lumaColor;
	CGPoint			lumaPoint;
	
	BOOL			draggingColor;
	BOOL			draggingLuma;

@private
	NSData *		colorWheelData;
	NSData *		lumaData;
	
	CGAffineTransform	screenScale;
}

@property (retain) UIColor * color;

- (void) setColor:(UIColor *)color;

@end
