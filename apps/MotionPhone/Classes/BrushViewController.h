//
//  BrushViewController.h
//  Motion Phone
//
//  Created by Scott Snibbe on April 29, 2011
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#include "defs.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

class Parameters;

@interface BrushViewController : UIViewController {
			
	UISlider	*sizeSlider;
	UISlider	*alphaSlider;

	UISegmentedControl *brushSegmentedControl;
	UISegmentedControl *orientSegmentedControl;
	UISegmentedControl *fillSegmentedControl;
    
    UIImageView *brushImageView;

//    NSMutableArray     *filledIcons, *unfilledIcons, *filledOrientIcons, *unfilledOrientIcons;
//	Parameters			*params;
}

@property(readonly, nonatomic) IBOutlet UISlider *sizeSlider;
@property(readonly, nonatomic) IBOutlet UISlider *alphaSlider;

@property(nonatomic,retain) IBOutlet UISegmentedControl	*brushSegmentedControl;
@property(nonatomic,retain) IBOutlet UISegmentedControl	*orientSegmentedControl;
@property(nonatomic,retain) IBOutlet UISegmentedControl	*fillSegmentedControl;

@property(nonatomic,retain) IBOutlet UIImageView	*brushImageView;

//@property(nonatomic,retain) NSMutableArray *filledIcons, *unfilledIcons, *filledOrientIcons, *unfilledOrientIcons;

-(void) updateUIFields:(bool)animate;

-(IBAction) brushIndexChanged:(id)sender;
-(IBAction) orientIndexChanged:(id)sender;
-(IBAction) fillIndexChanged:(id)sender;
-(IBAction) setBrushWidth:(UISlider *)sender;
-(IBAction) setBrushAlpha:(UISlider *)sender;

//- (IBAction)doneAction:(id)sender;	// for done button

@end

