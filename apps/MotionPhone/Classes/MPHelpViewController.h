//
//  MPHelpViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIViewControllerHiding.h"
@class UIOrientView;


@interface MPHelpViewController : MPUIViewControllerHiding
{
    IBOutlet UIView *viewMainBG_;
    IBOutlet UIOrientView * orientView_;
    IBOutlet UIScrollView * scrollView_;
}

@end
