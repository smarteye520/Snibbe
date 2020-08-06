//
//  GraviluxViewController.h
//  Gravilux
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

#include "Gravilux.h"
#include "Parameters.h"
#import "GraviluxView.h"

class Gravilux;
@class InterfaceViewController, InAppPurchaseViewController;

@interface GraviluxViewController : UIViewController {
	GraviluxView				*graviluxView;
	EAGLContext					*context;
    GLuint						program;
    
    BOOL						animating;
    NSInteger					animationFrameInterval;
    CADisplayLink				*displayLink;
	NSTimer						*uiTimer;
}
@property (readonly, nonatomic, getter=isAnimating)	BOOL			animating;
@property (nonatomic)								NSInteger		animationFrameInterval;
@property (nonatomic, retain)						EAGLContext		*context;
@property (nonatomic, assign)						CADisplayLink	*displayLink;


- (void) startAnimation;
- (void) stopAnimation;

@end
