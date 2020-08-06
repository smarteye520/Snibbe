//
//  MPGradientController.h
//  MotionPhone
//
//  Created by Graham McDermott on 12/5/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MPGradientController : UIViewController
{
    UIImageView * imageViewGradient_;
    bool bShowingGradient_;
}

- (void) startShowingGradient: (float) fadeDuration;
- (void) stopShowingGradient: (float) fadeDuration;

@end
