//
//  MPFPSViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/14/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPUIViewControllerHiding.h"

@interface MPFPSViewController : MPUIViewControllerHiding
{

    IBOutlet UIView *viewMainBG_;
    IBOutlet UIImageView *viewSliderBG_;
    IBOutlet UISlider *slider_;
}


- (IBAction) sliderValueChanged:(UISlider *)sender;
    
@end
