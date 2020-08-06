//
//  ScoopAppDelegate.h
//  Scoop
//
//  Created by Scott Snibbe on 7/18/10.
//  Copyright Snibbe Interactive 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIViewControllerScoop;


@interface ScoopAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
    UIViewControllerScoop *viewControllerScoop_;
    bool retinaEnabled_;
}

@property (nonatomic, retain) UIWindow *window;

@end
