//
//  MPUIViewControllerHiding.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/15/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//
//  class MPUIViewControllerHiding
//  ------------------------------
//  UIViewController subclass that adds easy animated show/hide as well as tracking
//  other flags.

// 
#import <UIKit/UIKit.h>
#import "SnibbeNavController.h"


@interface MPUIViewControllerHiding : UIViewController<SnibbeNavControllerDelegate>
{
    bool bShown_;
    bool bActive_;
    
    NSString * notifyOn_;
    NSString * notifyOff_;
    
    SnibbeNavController * snibbeNav_;
    
}


@property (nonatomic, readonly) bool bShown_;
@property (nonatomic) bool bActive_;
@property (nonatomic, retain) NSString * notifyOn_;
@property (nonatomic, retain) NSString * notifyOff_;


- (void) show: (bool) visible withAnimation: (bool) bAnimate time: (float) t fullOpacity: (float) fullOpacity forceUpdate: (bool) bForce;
- (void) toggleActive;
- (void) setActive: (bool) active;

- (void) updateViewBackground: (UIView *) bgView;

// SnibbeNavControllerDelegate methods
- (void) setSnibbeNavController:(SnibbeNavController *)snc;

// for iPhone version
- (IBAction) onCloseButton:(id)sender;
- (IBAction) onLogoButton:(id)sender;

@end
