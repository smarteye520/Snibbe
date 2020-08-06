//
//  GraviluxAppDelegate.h
//  Gravilux
//
//  Created by Colin Roache on 9/7/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "GraviluxViewController.h"
#include "RotationController.h"

@class GraviluxViewController;

@interface GraviluxAppDelegate : UIResponder <UIApplicationDelegate> {
	UIWindow *window;
	RotationController		*rotationController;
	GraviluxViewController	*viewController;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) GraviluxViewController *viewController;
@property (strong, nonatomic) RotationController *rotationController;

@end
