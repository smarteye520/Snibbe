//
//  UIOrientView.m
//  SnibbeLib
//
//  Created by Graham McDermott on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "UIOrientView.h"
#import "UIOrientListener.h"


#define VIEW_ROTATION_ROTATE_TIME 0.5f
#define VIEW_ROTATION_DELAY 0.15f

static UIOrientListener * viewOrientListener = 0;


// private interface
@interface UIOrientView()

- (void) doOrientationChangedWithInterpTime: (float) rotationSeconds force: (bool) bForce;
- (void)  onOrientationChanged;
- (void)  doOrientationChangedImmediate;
- (void)  doOrientationChanged;
- (float) angleForOrientation: (UIDeviceOrientation) orient;
- (CGRect) boundsForOrientation: (UIDeviceOrientation) orient;
- (CGPoint) centerForOrientation: (UIDeviceOrientation) orient;
- (void)  initSelf;
- (float) closestValA: (float) valA valB: (float) valB target: (float) target;

- (void) onFirstValidOrientation;

@end




@implementation UIOrientView

@synthesize curDeviceOrientation_;
@synthesize adjustBoundsOnOrient_;
@synthesize orientCenter_;
@synthesize orientBoundsLandscape_;
@synthesize orientBoundsPortrait_;

#pragma mark class methods

//
// call once at program startup
+ (void) startup
{
    if ( !viewOrientListener )
    {
        viewOrientListener = [[UIOrientListener alloc] init];
    }
}

//
// call once at program shutdown
+ (void) shutdown
{
    if ( viewOrientListener )
    {
        [viewOrientListener release];
        viewOrientListener = nil;
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
- (void) forceUpdate: (float) interpTime
{
    [self doOrientationChangedWithInterpTime: interpTime force:true];
}

//
//
- (void) setOrientDelegate: ( id<UIOrientViewDelegate> ) del
{
    // don't retain
    orientDelegate_ = del;
}

#pragma mark private implementation


//
// Delayed handling of orientation changes
- (void) doOrientationChangedWithInterpTime: (float) rotationSeconds force: (bool) bForce
{
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];    
    
    if ( !hasOriented_ && viewOrientListener && [viewOrientListener hasSeenValidOrientation] )
    {
        orientation = viewOrientListener.lastValidOrientation_;
    }    
    
    if ( bForce || 
         ( UIDeviceOrientationIsValidInterfaceOrientation( orientation ) && 
           orientation != curDeviceOrientation_ ) )
    {
        curRotation_ = [self angleForOrientation: orientation];
        CGAffineTransform trans = CGAffineTransformMakeRotation( curRotation_ );
        
        bool bAnimate = rotationSeconds > .001;

        
        
        if ( bAnimate )
        {
            // rotate it        
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration: VIEW_ROTATION_ROTATE_TIME]; // bug? use rotation time...
            [UIView setAnimationBeginsFromCurrentState: true];
        }
               
        self.transform = trans;     
        
        if ( bAnimate )        
        {        
            [UIView commitAnimations];
        }

        if ( adjustBoundsOnOrient_ )
        {

            self.center = [self centerForOrientation: orientation];
            self.bounds = [self boundsForOrientation: orientation];
            
            //NSLog( @"new center: : %@\n", NSStringFromCGPoint([self centerForOrientation: orientation]) );
            //NSLog( @"new bound: %@\n", NSStringFromCGRect( [self boundsForOrientation: orientation] ));
        }
        
        
        //NSLog( @"setting orientation to %f rad for value %d\n", curRotation_, orientation );
        
        curDeviceOrientation_ = orientation;        
        hasOriented_ = true;
        
        if ( orientDelegate_ )
        {
            [orientDelegate_ onOrientChanged: orientation];
        }
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
            [self performSelector: @selector(doOrientationChanged) withObject:nil afterDelay: VIEW_ROTATION_DELAY];  
        }
    }    
    
    
}





//
// Handling of orientation changes with immediate rotate time
- (void) doOrientationChangedImmediate
{ 
    [self doOrientationChangedWithInterpTime:0.0f force:false];   
}

//
// Handling of orientation changes with default rotate time
- (void) doOrientationChanged
{ 
    [self doOrientationChangedWithInterpTime:VIEW_ROTATION_ROTATE_TIME force: false];   
}


// assumes app in portrait, returns angle in radians to orient view
// facing up.  Always returns the radian representation of the angle closest
// to the current orientation (i.e. M_PI vs. -M_PI).
- (float) angleForOrientation: (UIDeviceOrientation) orient
{
    
    switch (orient)
	{
		case UIDeviceOrientationPortrait:
        {         
            return [self closestValA:M_PI * 2.0 valB:0.0f target:curRotation_];            
        }
  		case UIDeviceOrientationPortraitUpsideDown:
        {
            return [self closestValA:M_PI valB: -M_PI target:curRotation_];            
        }        
        case UIDeviceOrientationLandscapeLeft:
        {
            return [self closestValA:M_PI * .5 valB: -M_PI * 1.5 target:curRotation_];            
        }
  		case UIDeviceOrientationLandscapeRight:
        {
            return [self closestValA:M_PI * -.5 valB: M_PI * 1.5 target:curRotation_];            
        }
            
		case UIDeviceOrientationFaceUp :
  		case UIDeviceOrientationFaceDown :
  		default:
        {
			// do nothing
    		break;
        }
	} 
    
    return 0.0f;
}

//
//
- (CGRect) boundsForOrientation: (UIDeviceOrientation) orient
{
    switch (orient)
	{
      
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
        {
            return orientBoundsLandscape_;         
        }
        case UIDeviceOrientationPortrait:
  		case UIDeviceOrientationPortraitUpsideDown:
        default:
        {
            return orientBoundsPortrait_;
        }  
                        
	} 
    

}

//
//
- (CGPoint) centerForOrientation: (UIDeviceOrientation) orient
{
    return orientCenter_;
}

//
// we use this technique so that adding subviews can be completed before the
// initial orientation is set
- (void) delayedInit
{
    // initial orientation (if we can at this point in initialization)
    [self doOrientationChangedWithInterpTime: 0.0f force: false];            
}

//
// Common initialization code
- (void) initSelf
{
    hasOriented_ = false;
    
    orientDelegate_ = nil;
    adjustBoundsOnOrient_ = false;
    orientCenter_ = CGPointZero;
    
    // add orientation notifications        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationChanged) name:UIDeviceOrientationDidChangeNotification object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFirstValidOrientation) name:notificationFirstValidOrientation object:viewOrientListener];
    

    // we use this technique so that adding subviews can be completed before the
    // initial orientation is set
    [self performSelector:@selector(delayedInit) withObject:nil afterDelay:0.001];
    
    
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
    [self doOrientationChangedWithInterpTime: 0.0f force:false];
}





@end
