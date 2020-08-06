//
//  MPPhoneToolbarViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 1/30/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#import "MPPhoneToolbarViewController.h"
#import "defs.h"
#import "Parameters.h"

// private interface
@interface MPPhoneToolbarViewController()

- (void) ensureBrushMode;

@end


@implementation MPPhoneToolbarViewController



#pragma mark UI Actions


//
//
- (IBAction) onBrushButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestBrushViewOnOff object:nil];
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
- (IBAction) onUndoButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestUndo object:nil];
    [self ensureBrushMode];
}


//
//
- (IBAction) onTrashButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestEraseCanvas object:nil];    
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
- (IBAction) onMusicButton:(id)sender
{    
    //[[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestFPSViewOnOff object:nil];
    [self ensureBrushMode];
}


//
//
- (IBAction) onIAPButton:(id)sender
{    
    //[[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestFPSViewOnOff object:nil];
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
- (IBAction) onHelpButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestHelpViewOnOff object:nil];
    [self ensureBrushMode];
}

//
//
- (IBAction) onEssayButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestEssayViewOnOff object:nil];
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



#pragma mark private interface

//
//
- (void) ensureBrushMode
{
    if ( gParams->tool() == MotionPhoneTool_Hand )
    {
        gParams->setTool( MotionPhoneTool_Brush );
    }
}


@end
