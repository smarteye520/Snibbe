//
//  SettingsViewPhone.h
//  Scoop
//
//  Created by Graham McDermott on 4/12/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BeatListController.h"



@interface SettingsViewPhone : UIViewController <BeatSetNavDelegate> {
 

    id<ScoopBeatSetIDTarget> beatSetIDDelegate_;
    IBOutlet BeatListController *blController_;
    IBOutlet UIImageView *imageViewTempo_;
    IBOutlet UILabel *labelBPM_;
    IBOutlet UILabel *labelSelectBeatSet_;
    IBOutlet UILabel *labelTableBG_;
    IBOutlet UISlider *sliderTempo_;
    
}

- (IBAction) onTempoValueChanged: (id) sender;


@property (nonatomic, assign) id<ScoopBeatSetIDTarget> beatSetIDDelegate_;

@end
