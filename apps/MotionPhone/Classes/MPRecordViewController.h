//
//  MPRecordViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/22/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIViewControllerHiding.h"
#import <MediaPlayer/MediaPlayer.h>

@class MPUIOrientButton;


@interface MPRecordViewController : MPUIViewControllerHiding 
{
    IBOutlet UIView *viewMainBG_;
    MPMusicPlaybackState musicPlayerState_;
    
    IBOutlet MPUIOrientButton * buttonSaveShare_;
    IBOutlet MPUIOrientButton * buttonLoad_;
    IBOutlet MPUIOrientButton * buttonMusic_;
}

- (IBAction) onButtonShare: (id)sender;
- (IBAction) onButtonLoad: (id)sender;
- (IBAction) onButtonMusic: (id)sender;


@end
