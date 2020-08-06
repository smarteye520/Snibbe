//
//  InterfaceViewController.h
//  Gravilux
//
//  Created by Colin Roache on 10/4/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//
#pragma once
#import <UIKit/UIKit.h>

#include "Gravilux.h"
#include "ForceState.h"
#include "Visualizer.h"
//#import "GraviluxViewController.h"
#import "ColorPickerView.h"
#import "ColorCircle.h"
#import "InfoViewController.h"
#import "HelpViewController.h"
#import "MusicViewController.h"
#import "ShareViewController.h"

#define G_SLIDER_EXPONENT 2.0

@interface InterfaceViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate, UITextFieldDelegate> {
	UIInterfaceOrientation		currentOrientation;
	InfoViewController			*infoVC;
	HelpViewController			*helpVC;
	
	// Top Level UI
	IBOutlet	UIView			*controlBar;		// iPad: everything, iPhone: bottom bar
	IBOutlet	UIView			*topBar;			// iPad: nil, iPhone: top bar
	IBOutlet	UIView			*menuStandard;		// iPad: nil, iPhone: view to be placed in top scroll
	IBOutlet	UIScrollView	*buttonScrollView;	// iPad: nil, iPhone: scroll view
	IBOutlet	UIView			*centerNavigation;	// iPad: tabView&seperation line for centering, iPhone: nil
	IBOutlet	UIView			*tabView;			// The view that the current panel is inserted into
	IBOutlet	UIImageView		*seperationLine;	// iPad: 1xY grey image, iPhone: nil
	BOOL						hidden;
	
	// Left Navigation
	IBOutlet	UIButton		*logo;
	IBOutlet	UIButton		*antigravityButton;
	IBOutlet	UIButton		*playPauseButton;
	
	// Right Navigation
	
	IBOutlet	UIButton		*settingsButton;
	IBOutlet	UIButton		*colorsButton;
	IBOutlet	UIButton		*textButton;
	IBOutlet	UIButton		*loadSaveButton;
	IBOutlet	UIButton		*shareButton;
	IBOutlet	UIButton		*infoButton;
	IBOutlet	UIButton		*musicButton;
	
	// Settings
	IBOutlet	UIView			*settingsView;
	IBOutlet	UISlider		*sizeSlider;
	IBOutlet	UILabel			*sizeLabel;
	IBOutlet	UISlider		*densitySlider;
	IBOutlet	UILabel			*densityLabel;
	IBOutlet	UISlider		*gravitySlider;
	IBOutlet	UILabel			*gravityLabel;
	
	// Color
	IBOutlet	UIView			*colorView;
	IBOutlet	UIButton		*colorToggle;
	IBOutlet	ColorPickerView	*colorPicker;
	IBOutlet	ColorCircle		*colorCircle1;
	IBOutlet	UIImageView		*colorIndicator1;
	IBOutlet	ColorCircle		*colorCircle2;
	IBOutlet	UIImageView		*colorIndicator2;
	IBOutlet	ColorCircle		*colorCircle3;
	IBOutlet	UIImageView		*colorIndicator3;
	UIColor						*activeColor;
	
	// Load/Save
	IBOutlet	UIView			*loadSaveView;
	IBOutlet	UIButton		*save1;
	IBOutlet	UIButton		*save2;
	IBOutlet	UIButton		*save3;
	IBOutlet	UIButton		*save4;
	IBOutlet	UIButton		*load1;
	IBOutlet	UIButton		*load2;
	IBOutlet	UIButton		*load3;
	IBOutlet	UIButton		*load4;
	
	// Music
	IBOutlet	MusicViewController	*musicVC;
	
	// Type
	IBOutlet	UIView			*typeAuxView;
	IBOutlet	UITextField		*typeAuxText;
	IBOutlet	UISlider		*typeAuxSize;
	IBOutlet	UIView			*typeView;
	IBOutlet	UITextField		*typeText;
	IBOutlet	UISlider		*typeSize;
	int							rowSkip;
	
	// Share
	IBOutlet	ShareViewController	*shareVC;
}

@property(nonatomic, readwrite) UIInterfaceOrientation currentOrientation;

// Top-level UI Actions
- (IBAction)toggleInterface:(id)sender;
- (IBAction)toggleAntigravity:(id)sender;
- (IBAction)togglePlayPause:(id)sender;
- (IBAction)resetGrid:(id)sender;
- (IBAction)resetAll:(id)sender;
- (IBAction)switchTab:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)iap:(id)sender;
- (IBAction)help:(id)sender;

// Settings UI Actions
- (IBAction)updateSetting:(id)sender;
- (IBAction)finishUpdatingSetting:(id)sender;

// Color UI Actions
- (IBAction)toggleColor:(UIButton *)sender;
- (IBAction)selectColor:(UIButton *)sender;
- (IBAction)randomColor:(UIButton *)sender;
- (IBAction)greyColor:(UIButton *)sender;

// Load/Save UI Actions
- (IBAction)load:(id)sender;
- (IBAction)save:(id)sender;

// Type UI Actions
- (IBAction)resizeType:(id)sender;
@end
