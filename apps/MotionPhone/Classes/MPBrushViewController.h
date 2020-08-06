//
//  MPBrushViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/21/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIViewControllerHiding.h"

@class MPUIBrushPreviewView;


@interface MPBrushViewController : MPUIViewControllerHiding
{
    IBOutlet UIView *viewMainBG_;
    IBOutlet UIView *brushPreviewViewArea_;
    IBOutlet UIView *viewSliderBG_;
    IBOutlet UIImageView *imageViewJoin_;
    IBOutlet UISlider *sliderBrushSize_;

    IBOutlet UIImageView *imageViewSegmentOrient_;
    IBOutlet UIImageView *imageViewSegmentFill_;

    IBOutlet UIButton *buttonOrient_;
    IBOutlet UIButton *buttonFill_;
    IBOutlet UIButton *buttonAddBrushes_;
    
    MPUIBrushPreviewView * brushPreviewView_;
    
}

- (CGRect) getJoinFrame;

- (IBAction) onAddBrushButton:(id)sender;
- (IBAction) onOrientButton:(id)sender;
- (IBAction) onFillButton:(id)sender;
- (IBAction) brushSizeSliderValueChanged:(UISlider *)sender;

@end
