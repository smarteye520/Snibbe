/*
     File: MusicViewController.h
	 (c) 2010 Scott Snibbe
 
 */

#include "defs.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "ScalePickerDataSource.h"

@interface MusicViewController : UIViewController {
	
	UISwitch					*__unsafe_unretained musicSwitch;
	IBOutlet UIPickerView		*__unsafe_unretained scalePickerView;
	ScalePickerDataSource		*scalePickerDataSource;
	
	IBOutlet UISlider	*__unsafe_unretained tempoSlider;
	UILabel				*tempoLabel;	
	
}

@property (unsafe_unretained, readonly, nonatomic) IBOutlet UIPickerView			*scalePickerView;
@property (unsafe_unretained, readonly, nonatomic) IBOutlet UISwitch				*musicSwitch;
@property (nonatomic) ScalePickerDataSource *scalePickerDataSource;

@property(unsafe_unretained, readonly, nonatomic) IBOutlet UISlider	*tempoSlider;
@property(nonatomic) IBOutlet UILabel		*tempoLabel;

- (void)updateUIFields:(bool)animate;

- (IBAction)musicAction:(id)sender;
- (IBAction)setTempo:(UISlider *)sender;
- (IBAction)doneAction:(id)sender;	// for done button on iPhones

@end
