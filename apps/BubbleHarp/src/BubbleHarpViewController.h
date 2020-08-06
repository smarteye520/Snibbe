//
//  BubbleHarpViewController.h
//  BubbleHarp
//
//  Created by Colin Roache on 9/14/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//
#pragma once
#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <QuartzCore/QuartzCore.h>

#include "BubbleHarp.h"
#include "Parameters.h"
#import "BubbleHarpView.h"

class BubbleHarp;
class ofxMSAShape3D;
//@class InterfaceViewController, InAppPurchaseViewController;

@interface BubbleHarpViewController : UIViewController {
	BubbleHarpView				*bubbleHarpView;
	EAGLContext					*context;
    GLuint						program;
    
    BOOL						animating;
    NSInteger					animationFrameInterval;
    CADisplayLink				*__unsafe_unretained displayLink;
	NSTimer						*uiTimer;
}
@property (readonly, nonatomic, getter=isAnimating)	BOOL			animating;
@property (nonatomic)								NSInteger		animationFrameInterval;
@property (nonatomic)						EAGLContext		*context;
@property (nonatomic, unsafe_unretained)						CADisplayLink	*displayLink;


- (void) startAnimation;
- (void) stopAnimation;

@end
