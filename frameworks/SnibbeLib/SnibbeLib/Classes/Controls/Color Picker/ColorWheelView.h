//
//  ColorWheelView.h
//  SnibbeLib
//
//  Created by Colin Roache on 10/6/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//
//  class ColorWheelView
//  --------------------
//  DGM - adapted from Gravilux color wheel code.
//  Represents a self-contained color wheel view.
//  
//  Client code can set the baseline color (full brightness)
//  and luminance at any time.  The wheel can display itself at the appropriate
//  brightness level given its luminance value.
//
//  Through the ColorWheelDelegate protocol the class can report back when color has
//  changed.  The value will be the current color multiplied by the luminance.


#import <UIKit/UIKit.h>



@protocol ColorWheelDelegate

@required

- (void) onColorChanged: (CGColorRef) newColor;


@end



@interface ColorWheelView : UIView 
{
    
	UIImage *		colorWheelImage;
    UIImage *       colorWheelOutline;
    UIImage *       colorWheelMask;
    //UIImage *       colorWheelWithLuminosity;	
	
	CGPathRef		circlePath;		
	
	UIColor *		color;
	UIColor *		colorPreMult;
    UIColor *       colorLuma;

	CGPoint			colorPoint;
	CGPoint			colorWheelCenter;	
	CGRect          colorWheelBGRect;
    CGRect          colorWheelOutlineRect;
    
    //CGPoint			colorPoint;
	CGPoint			colorWheelCenterParentRel;	
	CGRect          colorWheelBGRectParentRel;
    CGRect          colorWheelOutlineRectParentRel;
    
    
	BOOL			draggingColor;
    
    
@private
	NSData *		colorWheelData;
    
    float           luminosity;
 
    id<ColorWheelDelegate> delegate_;
    
}


//- (void) setColor: (UIColor *) color;

@property (nonatomic, retain) UIColor * color;   // color multiplied by luminosity ("final color")
@property (nonatomic) float luminosity;          // luminosity of the current color
@property (nonatomic, assign) id<ColorWheelDelegate> delegate_;


@end
