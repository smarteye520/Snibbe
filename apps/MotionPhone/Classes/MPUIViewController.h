//
//  MPUIViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/9/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//
//  Top-level UI view for the iPad

#import <UIKit/UIKit.h>
#import "MPUIViewControllerCommon.h"
#import "MPUIVCInfo.h"

@class MPToolbarViewController;
@class UIOrientButton;
@class MPFPSViewController;
@class MPColorViewController;
@class MPBrushViewController;
@class MPRecordViewController;
@class MPInfoViewController;
@class MPUIViewControllerHiding;
@class MPLoadViewController;
@class MPSaveShareViewController;
@class MPEssayViewController;
@class MPHelpViewController;
@class MPMediaController;





@interface MPUIViewController : MPUIViewControllerCommon
{

    
    MPToolbarViewController * toolbarController_;
    MPFPSViewController * fpsController_;
    MPColorViewController * colorController_;
    MPBrushViewController * brushController_;
    MPRecordViewController * recordController_;
    MPInfoViewController * infoController_;
    MPEssayViewController * essayController_;
    MPHelpViewController * helpController_;
    MPSaveShareViewController * saveShareController_;
    MPLoadViewController * loadController_;
    MPMediaController *mediaController_;
    
        
    NSMutableArray * arrayVCInfo_;
    
    
}


- (int) numSubControlsShown;
- (IBAction) showToolbarButtonPressed;
- (bool) anyUISubViewsActive;

- (void) update;


@end
