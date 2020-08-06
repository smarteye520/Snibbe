//
//  SnibbeColorPickerController.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/15/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//
//  class SnibbeColorPickerController
//  ---------------------------------
//  Self-contained color picker control.  Including foreground
//  and background color selector.  Modify as needed in the future
//  if FG/BG distinction isn't needed for a project.
// 
//  features:
// 
//  - color wheel (hue, saturation)
//  - value slider
//  - alpha slider
//  - foreground / background selector
//
//  Client code can set the foreground / background color of the controls
//  at any time, and receives notifications about color changes initiated
//  within the control through ColorPickerDelegate methods.


#import <UIKit/UIKit.h>
#import "ColorWheelView.h"

@class UIOrientButton;

@protocol ColorPickerDelegate

@required

- (void) onFGColorChanged: (CGColorRef) newColor;
- (void) onBGColorChanged: (CGColorRef) newColor;
- (void) onColorTargetChanged;

@end



typedef enum 
{
    eSSForeground = 0,
    eSSBackground
} colorPickerTargetT;

@interface SnibbeColorPickerController : UIViewController <ColorWheelDelegate>
{
    IBOutlet UIButton * buttonColorFG_;
    IBOutlet UIButton * buttonColorBG_;
    IBOutlet UIImageView *imageViewColorWheelPlaceholder_;
    
    IBOutlet UIImageView * sliderValueBG_;
    IBOutlet UIImageView * sliderAlphaBG_;
    IBOutlet UISlider *sliderValue_;
    IBOutlet UISlider *sliderAlpha_;
    
    IBOutlet UIImageView * imageViewFGBackground_;
    IBOutlet UIImageView * imageViewBGBackground_;
    
    ColorWheelView * colorWheelView_;
    IBOutlet UIOrientButton * buttonRandomize_;
    
    colorPickerTargetT pickerTarget_;
    
    id<ColorPickerDelegate> delegate_;
    
    // we store the color with hue, sat, val separate from alpha because the color
    // wheel doesn't deal with alpha values.
    
    UIColor * colorBG_; // color w/o alpha
    UIColor * colorFG_; // color w/o alpha
    float alphaFG_;
    float alphaBG_;
    
    float sliderRotation_; // rotation of the sliders in radians
    NSString * sliderAlphaImageName_; // possibly override default slider handle image names
    NSString * sliderValueImageName_; // 
}

@property (nonatomic, assign) id<ColorPickerDelegate> delegate_;
@property (nonatomic) float sliderRotation_;
@property (nonatomic, retain) NSString * sliderAlphaImageName_;
@property (nonatomic, retain) NSString * sliderValueImageName_;


- (IBAction) onBGButton:(id)sender;
- (IBAction) onFGButton:(id)sender;

- (IBAction) onValueValuechanged :(id)sender;
- (IBAction) onAlphaValuechanged :(id)sender;

- (IBAction) onRandomButton:(id)sender;

- (void) setFGColor: (UIColor *) col;
- (void) setBGColor: (UIColor *) col;

- (void) onViewSetRotation: (float) rot;
- (void) refresh;

// ColorWheelDelegate methods
- (void) onColorChanged:(CGColorRef) newColor;

@end
