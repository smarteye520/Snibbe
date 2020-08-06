//
//  MPPhoneUIViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 1/31/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPUIViewControllerCommon.h"
#import "SnibbeNavController.h"



@class MPPhoneToolbarViewController;


@interface MPPhoneUIViewController : MPUIViewControllerCommon <SnibbeNavControllerDelegate>
{
    MPPhoneToolbarViewController * toolbarController_;
    UIViewController             * parentVC_;
    SnibbeNavController     * snibbeNavController;
}

@property (nonatomic, assign) UIViewController * parentVC_;

- (void) update;

- (IBAction) showToolbarButtonPressed;

// SnibbeNavControllerDelegate methods
- (void) setSnibbeNavController:(SnibbeNavController *)snc;

@end
