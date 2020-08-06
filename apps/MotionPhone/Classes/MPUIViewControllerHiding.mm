//
//  MPUIViewControllerHiding.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/15/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIViewControllerHiding.h"
#import "defs.h"
#import "Parameters.h"


@implementation MPUIViewControllerHiding

@synthesize bShown_;
@synthesize bActive_;
@synthesize notifyOn_;
@synthesize notifyOff_;


//
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	bShown_ = false;
    bActive_ = false;
    self.view.alpha = 0;
    self.notifyOff_ = nil;
    self.notifyOn_ = nil;
    
	[super viewDidLoad];
}

- (void) dealloc
{

    self.notifyOn_ = nil;
    self.notifyOff_ = nil;
    
    [super dealloc];
}

//
//
- (void) show: (bool) visible withAnimation: (bool) bAnimate time: (float) t fullOpacity: (float) fullOpacity forceUpdate: (bool) bForce
{
    
    if ( visible != bShown_ || bForce )
    {
        float targetAlpha = visible ? fullOpacity : 0.0f;
        
        if ( bAnimate )
        {
            [UIView beginAnimations:@"mpviewcontroller_show" context:nil];
            [UIView setAnimationDuration: t];
            [UIView setAnimationBeginsFromCurrentState: true];
        }
        
        self.view.alpha = targetAlpha;
        
        if ( bAnimate )
        {
            [UIView commitAnimations];
        }
        
        bShown_ = visible;
    }
}

//
//
- (void) toggleActive
{
    bActive_ = !bActive_;
}

//
//
- (void) setActive: (bool) active
{
    bActive_ = active;
}

//
//
- (void) updateViewBackground: (UIView *) bgView
{
    if ( bgView )
    {
        // background value
        MColor colBG;
        gParams->getBGColor( colBG );
        
        
        // calculate luminance
                        
        float maxComponent = MAX( colBG[0], colBG[1] );
        float minLuminanceAtBlack = 0.15f;
        float tolerance = .008f;
        maxComponent = MAX( maxComponent, colBG[2] );
        
        if ( maxComponent < minLuminanceAtBlack )
        {
            float grayVal = minLuminanceAtBlack - maxComponent;
            if ( fabs( maxComponent - grayVal ) < tolerance )
            {
                grayVal = maxComponent + tolerance;
            }
            bgView.backgroundColor = [UIColor colorWithRed:grayVal green:grayVal blue:grayVal alpha:1.0f];
        }
        else
        {
            bgView.backgroundColor = [UIColor blackColor];
        }
        
        
    }
    
}


#pragma mark IBAction methods

//
//
- (IBAction) onCloseButton:(id)sender
{
    
#ifdef MOTION_PHONE_MOBILE
        
    if ( notifyOff_ )
    {
        // we trigger this notification here  only in the mobile version b/c of differences
        // between the iPad and iPhone structure for UI creation/destruction
        
        [[NSNotificationCenter defaultCenter] postNotificationName: notifyOff_ object:nil];
    }
    
#endif
    
    [snibbeNav_ popLastVC];
}

//
//
- (IBAction) onLogoButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationDismissUIDeep object:nil];
}


#pragma mark SnibbeNavControllerDelegate methods

//
//
- (void) setSnibbeNavController:(SnibbeNavController *)snc
{
    // don't retain
    snibbeNav_ = snc;
}


@end
