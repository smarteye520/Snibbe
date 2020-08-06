//
//  UIOrientButton.m
//  SnibbeLib
//
//  Created by Graham McDermott on 11/8/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "UIOrientButton.h"
#import "SnibbeUtils.h"
#import "UIOrientView.h"
#import "UIOrientListener.h"


#define ICON_ROTATION_ROTATE_TIME 0.5f
#define ICON_ROTATION_DELAY 0.15f

static UIOrientListener * buttonOrientListener = 0;

// private interface
@interface UIOrientButton()

- (void)  onOrientationChanged;
- (void)  doOrientationChangedWithInterpTime: (float) rotationSeconds forceUpdate: (bool) force;
- (void)  doOrientationChangedImmediate;
- (void)  doOrientationChanged;
- (float) angleForOrientation: (UIDeviceOrientation) orient;
- (void)  initSelf;
- (float) closestValA: (float) valA valB: (float) valB target: (float) target;

- (void) onFirstValidOrientation;

@end



@implementation UIOrientButton

@synthesize orientOffset_;

#pragma mark class methods

//
// call once at program startup
+ (void) startup
{
    if ( !buttonOrientListener )
    {
        buttonOrientListener = [[UIOrientListener alloc] init];
    }
}

//
// call once at program shutdown
+ (void) shutdown
{
    if ( buttonOrientListener )
    {
        [buttonOrientListener release];
        buttonOrientListener = nil;
    }
}


#pragma mark public implementation

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ( ( self = [super initWithCoder: aDecoder] ) )
    {
        [self initSelf];        
    }
    
    return self;
    
}

//
//
- (id) initWithFrame:(CGRect)frame
{

    if ( ( self = [super initWithFrame: frame] ) )
    {        
        [self initSelf];    
    }
    
    
    return self;
}


     

//
//
- (void) dealloc
{

    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [super dealloc];
}

//
//
- (void) orientWithInterpTime: (float) dur
{
    [self doOrientationChangedWithInterpTime: dur forceUpdate: true];
}

#pragma mark private implementation


//
// Delayed handling of orientation changes
- (void) doOrientationChangedWithInterpTime: (float) rotationSeconds forceUpdate: (bool) force
{

    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];    
    
    if ( !hasOriented_ && buttonOrientListener && [buttonOrientListener hasSeenValidOrientation] )
    {
        orientation = buttonOrientListener.lastValidOrientation_;
    }    

    if ( force && !UIDeviceOrientationIsValidInterfaceOrientation( orientation ) )
    {
        orientation = buttonOrientListener.lastValidOrientation_;
    }
    
    if ( UIDeviceOrientationIsValidInterfaceOrientation( orientation ) && 
         ( orientation != curDeviceOrientation_ || force ) )
    {
        curRotation_ = [self angleForOrientation: orientation];
        
        if ( rotationSeconds > .001 )
        {
            // rotate it        
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration: ICON_ROTATION_ROTATE_TIME];
            self.transform = CGAffineTransformMakeRotation( curRotation_ );     
            [UIView commitAnimations];
        }
        else
        {        
            self.transform = CGAffineTransformMakeRotation( curRotation_ );     
        }
        
        //NSLog( @"setting orientation to %f rad for value %d\n", curRotation_, orientation );
        
        curDeviceOrientation_ = orientation;        
        hasOriented_ = true;
    }
    
}



// Notofication observer for orientation changes.  We set the orientation immediately
// the first time around, then interpolate after a delay thereafter
- (void) onOrientationChanged
{
        
    
    UIDeviceOrientation orient = [UIDevice currentDevice].orientation;
    if ( UIDeviceOrientationIsValidInterfaceOrientation( orient ) )
    {
                
        if ( !hasOriented_ )
        {
            // immediate orientation setting first time around
            [self doOrientationChangedImmediate];            
        }
        else
        {                            
            // once things are up and running introduce a nice delay and smooth rotation
            [[self class] cancelPreviousPerformRequestsWithTarget: self selector:@selector(doOrientationChanged) object:nil];            
            [self performSelector: @selector(doOrientationChanged) withObject:nil afterDelay: ICON_ROTATION_DELAY];  
        }
    }    
    
    
}





//
// Handling of orientation changes with immediate rotate time
- (void) doOrientationChangedImmediate
{ 
    [self doOrientationChangedWithInterpTime:0.0f forceUpdate: false];   
}

//
// Handling of orientation changes with default rotate time
- (void) doOrientationChanged
{ 
    [self doOrientationChangedWithInterpTime:ICON_ROTATION_ROTATE_TIME forceUpdate: false];   
}


// assumes app in portrait, returns angle in radians to orient button
// facing up.  Always returns the radian representation of the angle closest
// to the current orientation (i.e. M_PI vs. -M_PI).
- (float) angleForOrientation: (UIDeviceOrientation) orient
{
    
    float theta = 0.0f;
    
    switch (orient)
	{
		case UIDeviceOrientationPortrait:
        {         
            theta = [self closestValA:M_PI * 2.0 valB:0.0f target:curRotation_];            
            break;
        }
  		case UIDeviceOrientationPortraitUpsideDown:
        {
            theta = [self closestValA:M_PI valB: -M_PI target:curRotation_];            
            break;
        }        
        case UIDeviceOrientationLandscapeLeft:
        {
            theta = [self closestValA:M_PI * .5 valB: -M_PI * 1.5 target:curRotation_];            
            break;
        }
  		case UIDeviceOrientationLandscapeRight:
        {
            theta = [self closestValA:M_PI * -.5 valB: M_PI * 1.5 target:curRotation_];            
            break;
        }
                                 
		case UIDeviceOrientationFaceUp :
  		case UIDeviceOrientationFaceDown :
  		default:
        {
			// do nothing
    		break;
        }
	} 
    
    return theta + orientOffset_;
    
}

//
// Common initialization code
- (void) initSelf
{
    hasOriented_ = false;
    self.orientOffset_ = 0.0f;
    
    // add orientation notifications        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationChanged) name:UIDeviceOrientationDidChangeNotification object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFirstValidOrientation) name:notificationFirstValidOrientation object:buttonOrientListener];
    
    // initial orientation (if we can at this point in initialization)
    [self doOrientationChangedWithInterpTime: 0.0f forceUpdate: false];  

    

    
}
                
//
// return the value closest to the target
- (float) closestValA: (float) valA valB: (float) valB target: (float) target;
{

    float aDiff = abs( valA - target );
    float bDiff = abs( valB - target );
    
    if ( aDiff < bDiff )
    {
        return valA;
    }
    
    return valB;
}
 

//
//
- (void) onFirstValidOrientation
{
    [self doOrientationChangedWithInterpTime: 0.0f forceUpdate: false];
}


@end
