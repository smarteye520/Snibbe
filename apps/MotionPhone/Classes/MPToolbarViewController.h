//
//  MPToolbarViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/9/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPUIViewControllerHiding.h"

@class MPUIOrientButton;

@interface MPToolbarViewController : MPUIViewControllerHiding
{    
    
    // toolbar buttons
    IBOutlet MPUIOrientButton * buttonPhone_;
    IBOutlet MPUIOrientButton * buttonColor_;
    IBOutlet MPUIOrientButton * buttonFPS_;
    IBOutlet MPUIOrientButton * buttonBrush_;
    IBOutlet MPUIOrientButton * buttonHome_;
    IBOutlet MPUIOrientButton * buttonUndo_;
    IBOutlet MPUIOrientButton * buttonTrash_;
    IBOutlet MPUIOrientButton * buttonRecord_;
    IBOutlet MPUIOrientButton * buttonInfo_;
    IBOutlet MPUIOrientButton * buttonDraw_;

    IBOutlet UIButton * buttonMoveDrawToggle_;
    IBOutlet UIImageView * imageViewMPTool_; 
    IBOutlet UIView * viewBG_;
    
    NSMutableArray * orientButtons_;    
    
}

- (IBAction) onTrashButton:(id)sender;
- (IBAction) onUndoButton:(id)sender;
- (IBAction) onHomeButton:(id)sender;
- (IBAction) onColorButton:(id)sender;
- (IBAction) onFPSButton:(id)sender;
- (IBAction) onBrushButton:(id)sender;
- (IBAction) onPhoneButton:(id)sender;
- (IBAction) onRecordButton:(id)sender;
- (IBAction) onInfoButton:(id)sender;
- (IBAction) onButtonMoveDrawToggle:(id)sender;
- (IBAction) onButtonDraw:(id)sender;

// for placement help
- (float) getFPSXPos;
- (float) getColorXPos;
- (float) getBrushXPos;
- (float) getRecordXPos;
- (float) getInfoXPos;
@end
