//
//  SettingsViewController.h
//  Bubble Harp
//
//  Created by Scott Snibbe on 5/30/10
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#include "defs.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

class Parameters;

@interface SettingsViewController : UIViewController {
			
	IBOutlet UISlider	*__unsafe_unretained streamSlider;
	IBOutlet UISlider	*__unsafe_unretained pointsSlider;

	UILabel				*streamLabel;	
	UILabel				*pointsLabel;
	UIButton			*galleryButton;
	UISwitch			*__unsafe_unretained gallerySwitch;
}

@property(unsafe_unretained, readonly, nonatomic) IBOutlet UISlider *streamSlider;
@property(unsafe_unretained, readonly, nonatomic) IBOutlet UISlider *pointsSlider;
@property(unsafe_unretained, readonly, nonatomic) IBOutlet UISwitch *gallerySwitch;

@property(nonatomic) IBOutlet UILabel	*streamLabel;
@property(nonatomic) IBOutlet UILabel	*pointsLabel;
@property(nonatomic) IBOutlet UIButton	*galleryButton;

- (void)updateUIFields:(bool)animate;

- (IBAction)resetAction:(id)sender;
- (IBAction)galleryModeAction:(id)sender;
- (IBAction)setStreamTime:(UISlider *)sender;
- (IBAction)setMaxPoints:(UISlider *)sender;
- (IBAction)doneAction:(id)sender;	// for done button

@end

