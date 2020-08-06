//
//  SnibbeColorPickerController.m
//  SnibbeLib
//
//  Created by Graham McDermott on 11/15/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "SnibbeColorPickerController.h"
#import <QuartzCore/QuartzCore.h>
#import "SnibbeUtilsiOS.h"
#import "UIOrientButton.h"

#define PREVIEW_CORNER_PIXEL_RADIUS 6.0f

// private interface
@interface SnibbeColorPickerController ()

- (void) updateTargetSelectionViews: (colorPickerTargetT) target;
- (void) setColorPickerTarget: (colorPickerTargetT) target;

- (void) updateValueSliderPos;
- (void) updateAlphaSliderPos;

- (void) notifyDelegate;

// helper
- (UIColor *) generateRGBAColor:  (UIColor *) base alpha: (float) alpha;

@end


@implementation SnibbeColorPickerController

@synthesize delegate_;
@synthesize sliderRotation_;
@synthesize sliderAlphaImageName_;
@synthesize sliderValueImageName_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) { 
        // Custom initialization
        
        colorBG_ = [[UIColor whiteColor] retain];
        colorFG_ = [[UIColor blackColor] retain];
        alphaFG_ = 1.0f;
        alphaBG_ = 1.0f;
        sliderRotation_ = 0.0f;
        sliderAlphaImageName_ = nil;
        sliderValueImageName_ = nil;
        
    }
    return self;
}

- (void) dealloc
{
    self.sliderAlphaImageName_ = nil;
    self.sliderValueImageName_ = nil;

    if ( colorBG_ )
    {
        [colorBG_ release];        
    }
    
    if ( colorFG_ )
    {
        [colorFG_ release];
    }
    
    [super dealloc];
}


                 
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
        
    
    // round the corners of the fg/bg color preview    
    buttonColorFG_.layer.cornerRadius = 4.0;
    buttonColorBG_.layer.cornerRadius = 4.0;
    
    CGRect rectColorWheel = imageViewColorWheelPlaceholder_.frame; // todo - need to modify?
    colorWheelView_ = [[ColorWheelView alloc] initWithFrame: rectColorWheel];
    
    imageViewColorWheelPlaceholder_.hidden = true;
    [self.view addSubview: colorWheelView_];
    colorWheelView_.delegate_ = self;
    [colorWheelView_ release];
    
    // setup sliders

    
    CGAffineTransform transRotControl = CGAffineTransformMakeRotation( sliderRotation_ );
    sliderValue_.transform = sliderAlpha_.transform = transRotControl;
    sliderValue_.center = sliderValueBG_.center;
    sliderAlpha_.center = sliderAlphaBG_.center;    
            
    


    NSString * alphaHandleName = sliderAlphaImageName_ ? sliderAlphaImageName_ : @"slider_handle_color.png";
    NSString * valueHandleName = sliderValueImageName_ ? sliderValueImageName_ : @"slider_handle_color.png";
    
    
    [sliderValue_ setThumbImage:[UIImage imageNamed:valueHandleName] forState:UIControlStateNormal];
    [sliderValue_ setThumbImage:[UIImage imageNamed:valueHandleName] forState:UIControlStateSelected];
    [sliderValue_ setThumbImage:[UIImage imageNamed:valueHandleName] forState:UIControlStateHighlighted];
    
    [sliderValue_ setMinimumTrackImage:[UIImage imageNamed:@"transparent_square.png"] forState:UIControlStateNormal];
    [sliderValue_ setMaximumTrackImage:[UIImage imageNamed:@"transparent_square.png"] forState:UIControlStateNormal];    

    [sliderAlpha_ setThumbImage:[UIImage imageNamed:alphaHandleName] forState:UIControlStateNormal];
    [sliderAlpha_ setThumbImage:[UIImage imageNamed:alphaHandleName] forState:UIControlStateSelected];
    [sliderAlpha_ setThumbImage:[UIImage imageNamed:alphaHandleName] forState:UIControlStateHighlighted];
    
    [sliderAlpha_ setMinimumTrackImage:[UIImage imageNamed:@"transparent_square.png"] forState:UIControlStateNormal];
    [sliderAlpha_ setMaximumTrackImage:[UIImage imageNamed:@"transparent_square.png"] forState:UIControlStateNormal];    
    
            
    [self setColorPickerTarget: eSSForeground];
    
    

    
    
}



- (void)viewDidUnload
{
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


// IBActions
#pragma mark IBActions

//
//
- (IBAction) onBGButton:(id)sender
{
    [self setColorPickerTarget: eSSBackground];
}

//
//
- (IBAction) onFGButton:(id)sender
{
    [self setColorPickerTarget: eSSForeground];
}

//
//
- (IBAction) onValueValuechanged :(id)sender
{
    float newVal = ((UISlider *) sender).value;
    newVal = MIN( newVal, 1.0f );
    newVal = MAX( newVal, 0.0f );
    
    colorWheelView_.luminosity = newVal;
    
    // we should get a callback from the color wheel...
}

- (IBAction) onAlphaValuechanged :(id)sender
{
    float newVal = ((UISlider *) sender).value;
    
    float * pAlpha = ( pickerTarget_ == eSSBackground ? &alphaBG_ : &alphaFG_ );        
    *pAlpha = newVal;

    
    UIColor * colorBase = (pickerTarget_ == eSSBackground ? colorBG_ : colorFG_ );            
    UIColor *fullColor = [self generateRGBAColor: colorBase alpha: newVal];            
    
    [self onColorChanged: fullColor.CGColor];   
    
}

//
//
- (IBAction) onRandomButton:(id)sender
{
    float existingAlpha = ( pickerTarget_ == eSSBackground ) ? alphaBG_ : alphaFG_; 

    float r = rand() / (float) RAND_MAX;
    float g = rand() / (float) RAND_MAX;
    float b = rand() / (float) RAND_MAX;
    
    UIColor * newColor = [UIColor colorWithRed:r green:g blue:b alpha:existingAlpha];        
    
    if ( pickerTarget_ == eSSBackground )
    {
        [self setBGColor: newColor];
    }
    else
    {
        [self setFGColor: newColor];
    }
     
    [self onColorChanged: newColor.CGColor]; 
}


//
// called by clients to set foreground color
- (void) setFGColor: (UIColor *) col
{
    
    if ( !col )
    {
        return;
    }
    
    if ( colorFG_ )
    {
        [colorFG_ release];
    }
    

    
    colorFG_ = [col retain];    
    alphaFG_ = colorAlpha( colorFG_.CGColor );
    
    if ( pickerTarget_ == eSSForeground )
    {
        colorWheelView_.color = colorFG_;        

        [self updateValueSliderPos];
        [self updateAlphaSliderPos];        
    }
    
     buttonColorFG_.backgroundColor = colorFG_;
            
    [self updateTargetSelectionViews: pickerTarget_];
         
    
}

//
// called by clients to set background color
- (void) setBGColor: (UIColor *) col
{
    if ( !col )
    {
        return;
    }
    
    if ( colorBG_ )
    {
        [colorBG_ release];        
    }
    
    colorBG_ = [col retain];
    alphaBG_ = colorAlpha( colorBG_.CGColor );
    
    if ( pickerTarget_ == eSSBackground )
    {
        colorWheelView_.color = colorBG_;
                
        [self updateValueSliderPos];
        [self updateAlphaSliderPos];        
    }
    
    buttonColorBG_.backgroundColor = colorBG_;
}

//
//
- (void) refresh
{        
    [self setFGColor: [self generateRGBAColor: colorFG_ alpha: alphaFG_ ]];
    [self setBGColor: [self generateRGBAColor: colorBG_ alpha: alphaBG_ ]];
}


// If this color picker view is embedded as a sub-view with rotation
// this helps us to inform certain controls to compensate
//
// sort of a hack for the iPad version
- (void) onViewSetRotation: (float) rot
{
    buttonRandomize_.orientOffset_ = -rot;
    [buttonRandomize_ orientWithInterpTime: 0];
}

#pragma mark ColorWheelDelegate methods


//
// ColorWheelDelegate methods
// the color w/ luminance has changed.  Update the appropriate color value
// locally and inform our delegate as well.
//
// Alpha isn't part of this reported color from the wheel (who doesn't deal
// with alpha) so we include it in the reporting to our our own delegate
- (void) onColorChanged:(CGColorRef) newColor
{
    
    UIButton *buttonToChange = (pickerTarget_ == eSSBackground ? buttonColorBG_ : buttonColorFG_);    
    UIColor ** colorToChange = (pickerTarget_ == eSSBackground ? &colorBG_ : &colorFG_ );    
    
    float alphaVal = (pickerTarget_ == eSSBackground ? alphaBG_ : alphaFG_ );    
    
    // update the appropriate button background
    UIColor * colorForButton = [UIColor colorWithCGColor: newColor];  
    UIColor * colorWithAlpha = [colorForButton colorWithAlphaComponent: alphaVal];
    buttonToChange.backgroundColor = colorWithAlpha;  
    

    // update the actual reference color value
    if ( *colorToChange )
    {
        [(*colorToChange) release];
    }
    
    *colorToChange = [colorForButton retain];
        
    
    [self notifyDelegate];
    
    //NSLog( @"color b: %f: \n", colorLuminance( newColor ) );
    
}

// private implementation
#pragma mark private implementation


//
//
- (void) updateTargetSelectionViews: (colorPickerTargetT) target
{
    if ( target == eSSBackground )
    {        
        imageViewFGBackground_.image = [UIImage imageNamed: @"colorbox_outline_gray.png" ];
        imageViewBGBackground_.image = [UIImage imageNamed: @"colorbox_outline_white.png" ];
    }
    else if ( target == eSSForeground )
    {        
        imageViewFGBackground_.image = [UIImage imageNamed: @"colorbox_outline_white.png" ];
        imageViewBGBackground_.image = [UIImage imageNamed: @"colorbox_outline_gray.png" ];        
    }

}


- (void) setColorPickerTarget: (colorPickerTargetT) target
{
    UIColor * colorTarget = 0;
    
    [self updateTargetSelectionViews: target];
    
    if ( target == eSSBackground )
    {
        colorTarget = colorBG_;
    }
    else if ( target == eSSForeground )
    {
        colorTarget = colorFG_;
    }
    
    pickerTarget_ = target;
    
    colorWheelView_.color = colorTarget;
    [self updateAlphaSliderPos];
    [self updateValueSliderPos];
    
    sliderAlpha_.hidden = (target == eSSBackground);
    sliderAlphaBG_.hidden = (target == eSSBackground);
    
    if ( delegate_ )
    {
        [delegate_ onColorTargetChanged];
    }
        
    
}

//
//
- (void) updateValueSliderPos
{
    
    
    UIColor * colorTarget = ( pickerTarget_ == eSSBackground ? colorBG_ : colorFG_ );
        
    // set the alpha and value sliders
    float brightness = colorLuminance( colorTarget.CGColor );
    sliderValue_.value = brightness;
    
}

//
//
- (void) updateAlphaSliderPos
{
     
    float alpha = ( pickerTarget_ == eSSBackground ? alphaBG_ : alphaFG_ );    
    sliderAlpha_.value = alpha;
        
}

//
//
- (void) notifyDelegate
{
    // notify the outside world...
    if ( delegate_ )
    {
        
        // need to integrate the alpha value
        float alphaToUse = (pickerTarget_ == eSSBackground ? alphaBG_ : alphaFG_);            
        UIColor * colorBase = (pickerTarget_ == eSSBackground ? colorBG_ : colorFG_ );            
        UIColor *fullColor = [self generateRGBAColor: colorBase alpha:alphaToUse];                
        
        if ( pickerTarget_ == eSSBackground )
        {                                 
            [delegate_ onBGColorChanged: fullColor.CGColor];
        }
        else
        {
            [delegate_ onFGColorChanged: fullColor.CGColor];   
        }
    }

}


//
// Helper
- (UIColor *) generateRGBAColor:  (UIColor *) base alpha: (float) alpha
{
    return [UIColor colorWithRed:colorRed( base.CGColor ) green:colorGreen(base.CGColor) blue:colorBlue(base.CGColor) alpha:alpha];    
}




@end
