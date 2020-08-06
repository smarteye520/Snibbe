//
//  MPToolbarViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/9/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPToolbarViewController.h"
#import "MPUIOrientButton.h"
#import "Parameters.h"
#import "MPNetworkManager.h"
#import "defs.h"
#import "MPUtils.h"
#import "SnibbeUtils.h"

// private interface

@interface MPToolbarViewController ()

- (void) setAllButtonImagesOn: (bool) bOnOff;
- (void) updateUIForMPTool: (MotionPhoneTool) tool;
- (void) updateToolUI;

// notification observers

- (void) onMatchBegin;
- (void) onMatchEnd;

- (void) onFPSShown;
- (void) onFPSHidden;
- (void) onColorShown;
- (void) onColorHidden;
- (void) onBrushShown;
- (void) onBrushHidden;
- (void) onRecordShown;
- (void) onRecordHidden;
- (void) onInfoShown;
- (void) onInfoHidden;

- (void) onMinFrameTimeChanged;
- (void) onBGColorChanged;

- (void) updateButtonPhone;

- (void) ensureBrushMode;

@end


@implementation MPToolbarViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        bShown_ = false;
        orientButtons_ = nil;
    }
    return self;
}

//
//
- (void) dealloc
{
  
    if ( orientButtons_ )
    {
        [orientButtons_ release];
        orientButtons_ = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
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
    
    // setup the on/off images 
    [buttonPhone_ setImageNamesOn: @"phone_on.png" off:@"phone_off.png"];
    [buttonColor_ setImageNamesOn: @"color_on.png" off:@"color_off.png"];
    [buttonFPS_ setImageNamesOn: @"blank_on.png" off:@"blank_off.png"];
    [buttonBrush_ setImageNamesOn: @"brushes_on.png" off:@"brushes_off.png"];
    [buttonHome_ setImageNamesOn: @"home.png" off:@"home.png"];
    [buttonUndo_ setImageNamesOn: @"undo.png" off:@"undo.png"];
    [buttonTrash_ setImageNamesOn: @"trash.png" off:@"trash.png"];
    [buttonRecord_ setImageNamesOn: @"camera_on.png" off:@"camera_off.png"];
    [buttonInfo_ setImageNamesOn: @"info_on.png" off:@"info_off.png"];
    [buttonDraw_ setImageNamesOn: @"hand_on.png" off:@"hand_off.png" ];
    
    orientButtons_ = [[NSMutableArray alloc] initWithObjects:buttonPhone_, buttonColor_, buttonFPS_, buttonBrush_, buttonHome_, buttonUndo_, buttonTrash_, buttonRecord_, buttonInfo_, buttonDraw_, nil ];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatchBegin) name:gNotificationBeginMatch object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatchEnd) name:gNotificationEndMatch object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFPSShown) name:gNotificationFPSViewOn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFPSHidden) name:gNotificationFPSViewOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushShown) name:gNotificationBrushViewOn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushHidden) name:gNotificationBrushViewOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onColorShown) name:gNotificationColorViewOn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onColorHidden) name:gNotificationColorViewOff object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecordShown) name:gNotificationRecordViewOn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecordHidden) name:gNotificationRecordViewOff object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onInfoShown) name:gNotificationInfoViewOn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onInfoHidden) name:gNotificationInfoViewOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateToolUI) name:gNotificationToolModeChanged object:nil];    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateButtonPhone) name:gNotificationToolbarShown object:nil];    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMinFrameTimeChanged) name:gNotificationMinFrameTimeChanged object:nil];                
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBGColorChanged) name:gNotificationBGColorChanged object:nil];                
    
    
    [MPUtils updateFPSIndicator: buttonFPS_];
    [self updateUIForMPTool: gParams->tool() ];
    
    [self updateViewBackground: viewBG_];    
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



#pragma mark UI Actions
 

//
//
- (IBAction) onTrashButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestEraseCanvas object:nil];    
    [self ensureBrushMode];
}

//
//
- (IBAction) onUndoButton:(id)sender
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestUndo object:nil];
    [self ensureBrushMode];
}

//
//
- (IBAction) onHomeButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestGoHome object:nil];
    [self ensureBrushMode];
}

//
//
- (IBAction) onColorButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestColorViewOnOff object:nil];
    [self ensureBrushMode];
}

//
//
- (IBAction) onFPSButton:(id)sender
{    
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestFPSViewOnOff object:nil];
    [self ensureBrushMode];
}

//
//
- (IBAction) onBrushButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestBrushViewOnOff object:nil];
    [self ensureBrushMode];
}

//
//
- (IBAction) onPhoneButton:(id)sender
{                    
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationMultiplayerButtonPressed object:nil];    
    [self ensureBrushMode];
}

//
//
- (IBAction) onRecordButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestRecordViewOnOff object:nil];
    [self ensureBrushMode];
}

//
//
- (IBAction) onInfoButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestInfoViewOnOff object:nil];
    [self ensureBrushMode];
}

//
// one invisible button to toggle between move and draw
- (IBAction) onButtonMoveDrawToggle:(id)sender
{
    MotionPhoneTool newTool = ( gParams->tool() == MotionPhoneTool_Hand ? MotionPhoneTool_Brush : MotionPhoneTool_Hand );        
    gParams->setTool( newTool);    
    
}

//
// no longer used since we're toggling with one invisible button
- (IBAction) onButtonDraw:(id)sender
{
//    if ( gParams->tool() != MotionPhoneTool_Brush )
//    {
//        [self updateUIForMPTool: MotionPhoneTool_Brush];
//        gParams->setTool( MotionPhoneTool_Brush);
//        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationToolModeChanged object:nil];
//    }
}


// methods to help clients with element placement

//
// 
- (float) getFPSXPos
{        
    return buttonFPS_.frame.origin.x + buttonFPS_.frame.size.width * .5;
}

//
//
- (float) getColorXPos
{
    return buttonColor_.frame.origin.x + buttonColor_.frame.size.width * .5;    
}

//
//
- (float) getBrushXPos
{
    return buttonBrush_.frame.origin.x + buttonBrush_.frame.size.width * .5;    
}

//
//
- (float) getRecordXPos
{
    return buttonRecord_.frame.origin.x + buttonBrush_.frame.size.width * .5;    
}

//
//
- (float) getInfoXPos
{
    return buttonInfo_.frame.origin.x + buttonBrush_.frame.size.width * .5;    
}

#pragma mark private implementation

//
//
- (void) setAllButtonImagesOn: (bool) bOnOff
{
    
    for ( MPUIOrientButton * curButton in orientButtons_ )
    {
        [curButton setOn: bOnOff];
    }
        
}


- (void) updateToolUI
{
    [self updateUIForMPTool: gParams->tool()];
}


//
//
- (void) updateUIForMPTool: (MotionPhoneTool) tool
{
    if ( tool == MotionPhoneTool_Hand )
    {
        [imageViewMPTool_ setImage: [UIImage imageNamed: @"switch_mover.png"]];
        [buttonDraw_ setOn: false];
        
    }
    else
    {
        // brush (confusing image/enum naming...)
        [imageViewMPTool_ setImage: [UIImage imageNamed: @"switch_hand.png"]];        
        [buttonDraw_ setOn: true];
    }
}


#pragma  mark notification observers

- (void) onMatchBegin
{
    [buttonPhone_ setOn: true];
}

- (void) onMatchEnd
{
    [buttonPhone_ setOn: false];
}

//
//
- (void) onFPSShown
{
    [buttonFPS_ setOn: true];
    [MPUtils updateFPSIndicator: buttonFPS_];
}

//
//
- (void) onFPSHidden
{
    [buttonFPS_ setOn: false];    
    [MPUtils updateFPSIndicator: buttonFPS_];
}

//
//
- (void) onColorShown
{
    [buttonColor_ setOn: true];
}

//
//
- (void) onColorHidden
{
    [buttonColor_ setOn: false];    
}
//
//
- (void) onBrushShown
{
    [buttonBrush_ setOn: true];
}

//
//
- (void) onBrushHidden
{
    [buttonBrush_ setOn: false];    
}

//
//
- (void) onRecordShown
{
    [buttonRecord_ setOn:true];
}

//
//
- (void) onRecordHidden
{
    [buttonRecord_ setOn:false];    
}

//
//
- (void) onInfoShown
{
    [buttonInfo_ setOn:true];
}

//
//
- (void) onInfoHidden
{
    [buttonInfo_ setOn:false];    
}


//
//
- (void) onMinFrameTimeChanged
{
    [MPUtils updateFPSIndicator: buttonFPS_];
}

//
//
- (void) onBGColorChanged
{ 
    [self updateViewBackground: viewBG_];
}

//
//
- (void) updateButtonPhone
{    
    [buttonPhone_ setOn: [[MPNetworkManager man] multiplayerSessionActive] ];    
}

//
//
- (void) ensureBrushMode
{
    if ( gParams->tool() == MotionPhoneTool_Hand )
    {
        gParams->setTool( MotionPhoneTool_Brush );
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
