//
//  UIOrientButton.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/8/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//
//  class UIOrientButton
//  -------------------------------------------------------
//  Self-orienting button class.
//  Used in interfaces where the top-level orientation doesn't change but 
//  buttons themselves must self-rotate to respect the device's current orientation.
//
//  note: currently assumes the app is permanently "officially" in portrait mode.
//  If not we need to update the angle calculations to work for other orientations.


#import <UIKit/UIKit.h>

@interface UIOrientButton : UIButton 
 {
 
    UIDeviceOrientation curDeviceOrientation_;   
    float curRotation_; // the current label's rotation in radians
    bool hasOriented_;
    float orientOffset_; // allow clients to correct orientation by a fixed offset
}

@property (nonatomic) float orientOffset_;

- (void) orientWithInterpTime: (float) dur;

+ (void) startup;   // call at program startup if using this class
+ (void) shutdown;  // call at program shutdown if using this class 


@end
