//
//  UIOrientView.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//
//  class UIOrientView
//  -------------------------------------------------------
//  Self-orienting view class.
//  Used in interfaces where the top-level orientation doesn't change but 
//  views themselves must self-rotate to respect the device's current orientation.
//
//  note: currently assumes the app is permanently "officially" in portrait mode.
//  If not we need to update the angle calculations to work for other orientations.
//
//  Can be used as a shim between parent and child views to achieve rotation for any
//  sub-view

#import <UIKit/UIKit.h>

@protocol UIOrientViewDelegate <NSObject>

- (void) onOrientChanged: (UIDeviceOrientation) orient;

@end


@interface UIOrientView : UIView
{    
    UIDeviceOrientation curDeviceOrientation_;   
    float curRotation_; // the current label's rotation in radians
    bool hasOriented_;
    
    bool adjustBoundsOnOrient_;
    CGPoint orientCenter_;
    CGRect orientBoundsLandscape_;
    CGRect orientBoundsPortrait_;
    id <UIOrientViewDelegate> orientDelegate_;
}

- (void) forceUpdate: (float) interpTime;
- (void) setOrientDelegate: ( id<UIOrientViewDelegate> ) del; // doesn't retain

@property (nonatomic, readonly) UIDeviceOrientation curDeviceOrientation_;

// warning - dynamically adjusting center and bounds on orientation doesn't play nicely
// with subviews.  Not recommended when using subviews of the orienting view.
@property (nonatomic) bool adjustBoundsOnOrient_;
@property (nonatomic) CGPoint orientCenter_;
@property (nonatomic) CGRect orientBoundsLandscape_;
@property (nonatomic) CGRect orientBoundsPortrait_;


+ (void) startup;   // call at program startup if using this class
+ (void) shutdown;  // call at program shutdown if using this class 


@end
