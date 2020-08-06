//
//  UIOrientListener.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/30/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//
//  class UIOrientListener
//  ----------------------
//  Class to listen for and remember orientation changes, only paying attention
//  to those that are useful in most programs (skipping faceup / facedown)

#import <UIKit/UIKit.h>


extern NSString * notificationFirstValidOrientation;

@interface UIOrientListener : NSObject
{
    UIDeviceOrientation lastValidOrientation_;
    bool bSeenValidOrient_;
}

- (bool) hasSeenValidOrientation;

@property (nonatomic, readonly) UIDeviceOrientation lastValidOrientation_;

@end
