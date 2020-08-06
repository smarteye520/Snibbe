//
//  MPColorViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/15/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPColorViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Parameters.h"
#import "defs.h"
#import "MPUIBrushPreviewView.h"


@implementation MPColorViewController

@synthesize colorPickerXIBOverride_;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.colorPickerXIBOverride_ = nil;
    }
    return self;
}




- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];    
    
    ssColorController_.delegate_ = nil;
    [ssColorController_ release];
    ssColorController_ = nil;
    
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
    
    
    if ( IS_IPAD )
    {
        viewMainBG_.layer.cornerRadius = UI_CORNER_RADIUS;
    }
    
    // set up the embedded SnibbeLib color picker
    
    NSString * colorNib = @"SnibbeColorPickerController";
    
    if ( colorPickerXIBOverride_ )
    {
        // clients can supply their own XIB file to arrange the color picker controls
        // as long as it adheres to the same conventions and IBOutlets, etc as the sample XIB
        colorNib = colorPickerXIBOverride_;
    }
    
    ssColorController_ = [[SnibbeColorPickerController alloc] initWithNibName: colorNib bundle:nil];

#ifdef MOTION_PHONE_MOBILE
    ssColorController_.sliderRotation_ = -.5 * M_PI;  
    ssColorController_.sliderAlphaImageName_ = @"slider_handle_alpha.png";
    ssColorController_.sliderValueImageName_ = @"slider_handle_lightness.png";        
#endif
    
    [self.view addSubview: ssColorController_.view];
    
#ifndef MOTION_PHONE_MOBILE
    float rot = -M_PI * .5;
    ssColorController_.view.transform = CGAffineTransformMakeRotation( rot );
#endif
    
    ssColorController_.view.center = colorPickerViewArea_.center;
    ssColorController_.delegate_ = self;
    
#ifndef MOTION_PHONE_MOBILE
    [ssColorController_ onViewSetRotation: rot];
#endif

    colorPickerViewArea_.hidden = true;    
    
    // create the brush preview view
    
    brushPreviewView_ = [[MPUIBrushPreviewView alloc] initWithFrame: brushPreviewViewArea_.frame];
    [self.view addSubview: brushPreviewView_];
    [self.view bringSubviewToFront: brushPreviewView_];

    [brushPreviewView_ release];

    brushPreviewViewArea_.hidden = true;
    
    MColor fgCol;
    gParams->getFGColor(fgCol);
        
    MColor bgCol;
    gParams->getBGColor(bgCol);
        
    [self.view bringSubviewToFront: ssColorController_.view];
    
    [ssColorController_ setFGColor: [UIColor colorWithRed: fgCol[0] green:fgCol[1] blue:fgCol[2] alpha:fgCol[3] ] ];
    [ssColorController_ setBGColor: [UIColor colorWithRed: bgCol[0] green:bgCol[1] blue:bgCol[2] alpha:bgCol[3] ] ];
    
    [self updateViewBackground: viewMainBG_];
    
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
	return YES;
}


#pragma mark public implementation

- (CGRect) getJoinFrame
{
    return imageViewJoin_.frame;
}


//
// ColorPickerDelegate methods
- (void) onFGColorChanged:(CGColorRef)newColor
{
    if ( newColor )
    {           
        
        MColor mCol;
        [self colorRefToFloats: newColor outVals: mCol];
        gParams->setFGColor( mCol );    
        
    }
}

//
//
- (void) onBGColorChanged:(CGColorRef)newColor
{
    if ( newColor )
    {   
        
        MColor mCol;
        [self colorRefToFloats: newColor outVals: mCol];                
        
        gParams->setBGColor( mCol );        
                
        [self updateViewBackground: viewMainBG_];
    }
}

//
//
- (void) onColorTargetChanged
{

}

               
- (void) colorRefToFloats: (CGColorRef) cRef outVals: (float[4]) rgba               
{

    if ( cRef )
    {
        
        int iNumComponents = CGColorGetNumberOfComponents( cRef );
        rgba[0] = rgba[1] = rgba[2] = rgba[3] = 1.0f;            
        int iNumToExtract = MIN( 4, iNumComponents );

        const float * components = CGColorGetComponents( cRef );
        
        for ( int i = 0; i < iNumToExtract; ++i )
        {
            rgba[i] = components[i];       
        }

   }
}
   


// we want this whole view to suck up touches so they aren't passed down to the 
// eagl view

//
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}

//
//
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}

//
//
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
}

//
//
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
{
}

@end
