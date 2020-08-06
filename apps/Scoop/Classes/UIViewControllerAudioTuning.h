//
//  UIViewControllerAudioTuning.h
//  Scoop
//
//  Created by Graham McDermott on 3/30/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>

class Scoop;

@interface UIViewControllerAudioTuning : UIViewController {
    
    Scoop *scoop;
    
    IBOutlet UILabel *toneFreqLabel_;
    IBOutlet UILabel *toneRangeLabel_;
    IBOutlet UILabel *filterMinCutoffLabel_;
    IBOutlet UILabel *filterMaxCutoffLabel_;
    IBOutlet UILabel *filterResonanceLabel_;
    IBOutlet UILabel *toneVolMaxLabel_;
    IBOutlet UILabel *beatVolLabel_;
}

- (void) setScoop: (Scoop *) s;

- (IBAction)SetToneFrequency:(id)sender;
- (IBAction)SetToneRange:(id)sender;
- (IBAction)SetMinCutoff:(id)sender;
- (IBAction)SetMaxCutoff:(id)sender;
- (IBAction)SetResonance:(id)sender;
- (IBAction)SetToneVolMax:(id)sender;
- (IBAction)SetBeatVol:(id)sender;

@end
