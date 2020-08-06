//
//  MotionPhoneAppDelegate.h
//  MotionPhone
//
//  Created by Scott Snibbe on 11/12/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"

@class MotionPhoneViewController;
@class MPUIKitViewController;

@interface MotionPhoneAppDelegate : NSObject <UIApplicationDelegate, FBSessionDelegate> {
    
    UIWindow                    *window;
    MotionPhoneViewController   *viewController;
    MPUIKitViewController       *uiKitViewController;
    Facebook *facebook;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MotionPhoneViewController *viewController;
@property (nonatomic, retain) Facebook *facebook;

@end

