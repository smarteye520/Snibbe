//
//  BubbleHarpAppDelegate.h
//  BubbleHarp
//
//  Created by Colin Roache on 9/7/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "BubbleHarpViewController.h"
#include "RotationController.h"
#include "Parameters.h"

@class BubbleHarpViewController;

@interface BubbleHarpAppDelegate : UIResponder <UIApplicationDelegate> {
	UIWindow *window;
	RotationController		    *rotationController;
	BubbleHarpViewController	*viewController;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) BubbleHarpViewController *viewController;
@property (strong, nonatomic) RotationController *rotationController;

@end
