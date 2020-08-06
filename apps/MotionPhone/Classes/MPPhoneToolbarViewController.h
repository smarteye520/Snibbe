//
//  MPPhoneToolbarViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 1/30/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#import "MPUIViewControllerHiding.h"
#import <MediaPlayer/MediaPlayer.h>

@class MPUIOrientButton;
@class MPUIVCInfo;
@class MPFPSViewController;
@class MPRecordViewController;

@interface MPPhoneToolbarViewController : MPUIViewControllerHiding
{
    

    // toolbar buttons
    IBOutlet MPUIOrientButton * buttonBrush_;
    IBOutlet MPUIOrientButton * buttonColor_;
    IBOutlet MPUIOrientButton * buttonUndo_;
    IBOutlet MPUIOrientButton * buttonTrash_;
    
    IBOutlet MPUIOrientButton * buttonFPS_;
    IBOutlet MPUIOrientButton * buttonMusic_;
    IBOutlet MPUIOrientButton * buttonIAP_;
    IBOutlet MPUIOrientButton * buttonHome_;
    
    IBOutlet UIButton * buttonMoveDrawToggle_;
    IBOutlet UIImageView * imageViewMPTool_;     
    IBOutlet MPUIOrientButton * buttonDraw_;     
    
    IBOutlet UIView * viewBottomBar_;
    IBOutlet UIView * viewTopBar_;
    
    IBOutlet MPUIOrientButton * buttonHelp_;
    IBOutlet MPUIOrientButton * buttonEssay_;    
    IBOutlet MPUIOrientButton * buttonPhone_;
    IBOutlet MPUIOrientButton * buttonRecord_;

    //IBOutlet UIView * viewBG_;

    
    // toggleable sub controls
    
    MPUIVCInfo * vcInfoFPS_;
    MPUIVCInfo * vcInfoRecord_;
    
    MPFPSViewController * fpsController_;
    MPRecordViewController *recordController_;
    
    MPMusicPlaybackState musicPlayerState_;
    
    NSMutableArray * orientButtons_;   
    

}

- (void) hideSubControls: (float) time;

- (IBAction) onBrushButton:(id)sender;
- (IBAction) onColorButton:(id)sender;
- (IBAction) onUndoButton:(id)sender;
- (IBAction) onTrashButton:(id)sender;

- (IBAction) onFPSButton:(id)sender;
- (IBAction) onMusicButton:(id)sender;
- (IBAction) onIAPButton:(id)sender;
- (IBAction) onHomeButton:(id)sender;

- (IBAction) onButtonMoveDrawToggle:(id)sender;

- (IBAction) onButtonHelp: (id)sender;
- (IBAction) onButtonEssay: (id)sender;
- (IBAction) onPhoneButton:(id)sender;
- (IBAction) onRecordButton:(id)sender;





@end
