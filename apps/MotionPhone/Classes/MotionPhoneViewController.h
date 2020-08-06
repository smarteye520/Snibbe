//
//  MotionPhoneViewController.h
//  MotionPhone
//
//  Created by Scott Snibbe on 11/12/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <map>
#import <GameKit/GameKit.h>

class MCanvas;
class ofxMSAShape3D;

@class MPUIViewController;
@class MPPhoneUIViewController;
@class ToolbarViewController;
@class MPUIOrientButton;

@interface MotionPhoneViewController : UIViewController <UIGestureRecognizerDelegate>
{
    EAGLContext *context;
    GLuint program;
    
    BOOL animating;
    NSInteger animationFrameInterval;
    CADisplayLink *displayLink;
	
	ofxMSAShape3D			*shape3D_;
	MCanvas					*mCanvas_;
    
    
    // interface

#ifndef MOTION_PHONE_MOBILE    
    MPUIViewController      *uiViewController;
#else
    MPPhoneUIViewController * uiViewController;
    MPUIOrientButton * orientButtonBackupLogo_; // fills in during a period when we need to fill a gap in time when no logo button
#endif
    
    
    
    IBOutlet UIImageView    *imageViewFadeSplash;
    
    UIDeviceOrientation     deviceOrientation_;
    bool                    seenValidOrientation_;
    
    UIPanGestureRecognizer   *gestureRecognizerPan_;
    UIPinchGestureRecognizer *gestureRecognizerPinch_;
    bool                      gestureRecognizersInstalled_;
    
    CGPoint panGestureTranslationPrev_; // the previously calculated relative translation value for the current touch sequence
    float   pinchGestureScaleBaseline_; // the baseline scale value for the current touch sequence
    
    double                  curTime_;
    double                  lastParamSaveCheckTime_;
    //double                  timeAllowNextBrushTouch_;
    

    
    // performance mode data
    bool                    performanceMode_;  // mode with discreet UI for performances    
    double                  performanceModeFGColorUpdateTime_;
    double                  performanceModeBrushSizeUpdateTime_;
    
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

@property (nonatomic, retain) IBOutlet ToolbarViewController *toolbarViewController;

- (void) multiplayerInit;

- (void) startAnimation;
- (void) stopAnimation;

@end


