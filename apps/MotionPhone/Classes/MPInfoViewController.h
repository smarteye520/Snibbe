//
//  MPInfoViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/22/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIViewControllerHiding.h"

@class MPUIOrientButton;


@interface MPInfoViewController : MPUIViewControllerHiding
{
    IBOutlet UIView *viewMainBG_;
    
    IBOutlet MPUIOrientButton * buttonHelp_;
    IBOutlet MPUIOrientButton * buttonEssay_;
}

- (IBAction) onButtonHelp: (id)sender;
- (IBAction) onButtonEssay: (id)sender;

@end

