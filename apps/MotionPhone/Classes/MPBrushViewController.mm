//
//  MPBrushViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/21/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPBrushViewController.h"
#import "MPUIBrushPreviewView.h"
#import <QuartzCore/QuartzCore.h>
#import "Parameters.h"
#import "defs.h"
#import "MPShapeSetViewController.h"
#import "MShapeLibrary.h"

// private interface
@interface MPBrushViewController()

- (void) onBrushParamsChanged;

- (void) createShapeSetViews;

@end

@implementation MPBrushViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        


        
    }
    return self;
}

//
//
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    // create the brush preview view        
    brushPreviewView_ = [[MPUIBrushPreviewView alloc] initWithFrame: brushPreviewViewArea_.frame];
    [self.view addSubview: brushPreviewView_];
    [self.view bringSubviewToFront: brushPreviewView_];        
    [brushPreviewView_ release];
    
    brushPreviewViewArea_.hidden = true;
    
    // set up the brush size slider
    
    CGAffineTransform transRotControl = CGAffineTransformMakeRotation( -.5 * M_PI );
    sliderBrushSize_.transform = transRotControl;
    
    float normBrushWidth = (gParams->brushWidth() - MIN_BRUSH_WIDTH) / (MAX_BRUSH_WIDTH - MIN_BRUSH_WIDTH);
    sliderBrushSize_.value = normBrushWidth;
    
    [sliderBrushSize_ setThumbImage:[UIImage imageNamed:@"slider_handle.png"] forState:UIControlStateNormal];
    [sliderBrushSize_ setThumbImage:[UIImage imageNamed:@"slider_handle.png"] forState:UIControlStateSelected];
    [sliderBrushSize_ setThumbImage:[UIImage imageNamed:@"slider_handle.png"] forState:UIControlStateHighlighted];
    
    [sliderBrushSize_ setMinimumTrackImage:[UIImage imageNamed:@"transparent_square.png"] forState:UIControlStateNormal];
    [sliderBrushSize_ setMaximumTrackImage:[UIImage imageNamed:@"transparent_square.png"] forState:UIControlStateNormal];    

    sliderBrushSize_.center = viewSliderBG_.center;

    
    // hide the add brush button in 1.0!    
    buttonAddBrushes_.hidden = true;
    
    
    // set up the segment controls
    
    imageViewSegmentOrient_.transform = transRotControl;
    imageViewSegmentFill_.transform = transRotControl;
    

        
#ifdef MOTION_PHONE_MOBILE

    imageViewSegmentOrient_.center = buttonOrient_.center;
    imageViewSegmentFill_.center = buttonFill_.center;
    
#else
    
    buttonOrient_.transform = transRotControl;
    buttonFill_.transform = transRotControl;
    imageViewSegmentOrient_.frame = CGRectMake( viewMainBG_.frame.size.width - 24.0f - imageViewSegmentOrient_.frame.size.width,
                                                viewMainBG_.frame.size.height - 18.0f - imageViewSegmentOrient_.frame.size.height,
                                                imageViewSegmentOrient_.frame.size.width, 
                                                imageViewSegmentOrient_.frame.size.height ); 
    
    // in 1.0 move the fill segment to the right (where the add button normaly is)
    
    imageViewSegmentFill_.frame = CGRectMake( viewMainBG_.frame.size.width - 24.0f - imageViewSegmentFill_.frame.size.width ,
                                             18.0f,
                                             imageViewSegmentFill_.frame.size.width, 
                                             imageViewSegmentFill_.frame.size.height ); 
    
    // for 1.1
    /*
    imageViewSegmentFill_.frame = CGRectMake( viewMainBG_.frame.size.width - 24.0f - imageViewSegmentFill_.frame.size.width ,
                                               viewMainBG_.frame.size.height - 18.0f - imageViewSegmentFill_.frame.size.height * 2 - 34.0f,
                                               imageViewSegmentFill_.frame.size.width, 
                                               imageViewSegmentFill_.frame.size.height ); 
    
    */
    
    buttonFill_.frame = imageViewSegmentFill_.frame;
    buttonOrient_.frame = imageViewSegmentOrient_.frame;
    
#endif
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushParamsChanged) name:gNotificationBrushOrientChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushParamsChanged) name:gNotificationBrushFillChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBGColorChanged) name:gNotificationBGColorChanged object:nil];                
    [self updateViewBackground: viewMainBG_];
    
    [self onBrushParamsChanged];
    
    [self createShapeSetViews];
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

#pragma mark public interface

//
//
- (CGRect) getJoinFrame
{
    return imageViewJoin_.frame;
}


#pragma mark IBActions

//
//
- (IBAction) onAddBrushButton:(id)sender
{
    
}

//
//
- (IBAction) onOrientButton:(id)sender
{
    bool bNewOrient = !gParams->brushOrient();
    gParams->setBrushOrient( bNewOrient );
}

//
//
- (IBAction) onFillButton:(id)sender
{
    bool bNewFill = !gParams->brushFill();
    gParams->setBrushFill( bNewFill );
}


//
//
- (IBAction) brushSizeSliderValueChanged:(UISlider *)sender
{
    float norm = sender.value;    
    gParams->setBrushWidth( norm * (MAX_BRUSH_WIDTH - MIN_BRUSH_WIDTH) + MIN_BRUSH_WIDTH );
}

#pragma mark private implementation

//
//
- (void) onBrushParamsChanged
{
  
    bool bOrient = gParams->brushOrient();
    bool bFill = gParams->brushFill();
    
    imageViewSegmentOrient_.image = [UIImage imageNamed: ( bOrient ? @"switch_orient_yes.png" : @"switch_orient_no.png" )];
    imageViewSegmentFill_.image = [UIImage imageNamed: ( bFill ? @"switch_solid_yes.png" : @"switch_solid_no.png" )];
    
    
}



//
//
- (void) createShapeSetViews
{
    // for 1.0 just create a view for the default shape set
    
    NSString * nibSS = IS_IPAD ? @"MPShapeSetViewController-iPad" : @"MPShapeSetViewController";    
    MPShapeSetViewController * vcSS = [[MPShapeSetViewController alloc] initWithNibName:nibSS bundle:nil];
    
    MShapeLibrary *lib = [MShapeLibrary lib];    
    [vcSS setShapeSet: [lib shapeSetAtIndex: 0]];
    
#ifdef MOTION_PHONE_MOBILE

    
    vcSS.view.frame = CGRectMake(18, 200, vcSS.view.frame.size.width, vcSS.view.frame.size.height );    
    
#else
    
    float startingX = sliderBrushSize_.center.x + 39.0f; // $$$ this may change on phone - dgm        
    vcSS.view.frame = CGRectMake(startingX, 18, vcSS.view.frame.size.width, brushPreviewViewArea_.frame.size.height );    
    
#endif
    
    [self.view addSubview: vcSS.view];
    [self.view bringSubviewToFront: vcSS.view];
    
    UIView *v = vcSS.view;
    v.hidden = false;
    
}

//
//
- (void) onBGColorChanged
{ 
    [self updateViewBackground: viewMainBG_];
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
