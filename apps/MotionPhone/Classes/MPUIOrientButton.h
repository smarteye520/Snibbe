//
//  MPUIOrientButton.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/10/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//
//  class MPUIOrientButton
//  -----------------------------
//  MotionPhone-specific UIOrientButton subclass that has two visual states and
//  two corresponding images - one for on, and one for off.
// 
// 


#import "UIOrientButton.h"

@interface MPUIOrientButton : UIOrientButton
{
    UIImage *imageOn_;
    UIImage *imageOff_;
    
    bool bOn_;
}

- (void) setImageNamesOn: (NSString *) imageOn off: (NSString *) imageOff;

- (void) setOn: (bool) bOn;
- (bool) getOn;

@end
