
//  SnibbeNavController.m
//  MotionPhone
//
//  Created by Graham McDermott on 1/30/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//


#define SNIBBE_NAV_SLIDE_DUR 0.45f

#import "SnibbeNavController.h"


@interface SnibbeNavController()

- (void) popComplete;

@end



@implementation SnibbeNavController

@synthesize animStyle_;
@synthesize pushDir_;
@synthesize parentVC_;


//
//
- (id) init
{
    if ( ( self = [super init] ) )
    {
        vcStack_ = [[NSMutableArray alloc] init];
        self.animStyle_ = eSnibbeAnimNone;
        self.pushDir_ = eSNCRight;
        self.parentVC_ = nil;
    }
    
    return self;
}



//
//
- (void) dealloc
{        
    
    [vcStack_ release];
    vcStack_ = nil;
    
    [super dealloc];
}

//
//
- (void) pushVC: (UIViewController<SnibbeNavControllerDelegate> *) vc
{
    [self pushVC: vc withStyle:animStyle_];            
}



//
//
- (void) pushVC: (UIViewController<SnibbeNavControllerDelegate> *) vc withStyle: (SnibbeNavControllerAnimStyleT) s
{
    if ( parentVC_ && vc )
    {
        
        
        [vc setSnibbeNavController: self];
        
        if ( [vcStack_ count] == 0 )
        {
        
            // root view controller
            
            [vcStack_ addObject: vc];
            
            if ( vc.view.superview == nil )
            {
                assert(vc.view.superview == parentVC_.view );
            }
            else
            {
                [parentVC_.view addSubview: vc.view];
            }
            
            // don't mess with the frame - let the client set that for the root view controller
            
            // also anim style doesn't apply with the root
        }
        else
        {
            
            
            
            
            // here we place the new view next to the previous view in the stack
            // based on the direction we've specified
            
            [vcStack_ addObject: vc];
            [parentVC_.view addSubview: vc.view];
            
            // place the new view next to the current view
            
            UIViewController * vcPrev = [vcStack_ objectAtIndex: [vcStack_ count] - 2];
            CGRect prevFrame = vcPrev.view.frame;
            CGRect curFrame = vc.view.frame;
            CGPoint animPosDelta = CGPointZero;
            
            switch (pushDir_)
            {
                case eSNCUp:
                {                 
                    vc.view.frame = CGRectMake( prevFrame.origin.x, prevFrame.origin.y - curFrame.size.height, curFrame.size.width, curFrame.size.height );
                    animPosDelta = CGPointMake( 0.0f, -curFrame.size.height );
                    break;
                }

                case eSNCDown:
                {
                    vc.view.frame = CGRectMake( prevFrame.origin.x, prevFrame.origin.y + prevFrame.size.height, curFrame.size.width, curFrame.size.height );
                    animPosDelta = CGPointMake( 0.0f, curFrame.size.height );
                    break;
                }

                case eSNCLeft:
                {
                    vc.view.frame = CGRectMake( prevFrame.origin.x - curFrame.size.width, prevFrame.origin.y, curFrame.size.width, curFrame.size.height );
                    animPosDelta = CGPointMake( curFrame.size.width, 0.0f );
                    break;
                }
                        
                case eSNCRight:
                default:
                {
                    vc.view.frame = CGRectMake( prevFrame.origin.x + prevFrame.size.width, prevFrame.origin.y, curFrame.size.width, curFrame.size.height );
                    //NSLog ( @"frame: %@\n", NSStringFromCGRect( vc.view.frame ) );
                    animPosDelta = CGPointMake( -curFrame.size.width, 0.0f );
                    break;
                }
                
            }
            
            // now it's placed.  begin the animation where we move the current visible view out of the way!
            
            
            if ( s == eSnibbeAnimNone )
            {
             
                for ( UIViewController * curVC in vcStack_ )
                {
                    CGRect frame = curVC.view.frame;
                    curVC.view.frame = CGRectMake( frame.origin.x + animPosDelta.x, frame.origin.y + animPosDelta.y, frame.size.width, frame.size.height );
                }
                    
            }
            else if ( s == eSnibbeAnimSlide )
            {
             
                [UIView beginAnimations: @"snibbe nav slide" context:nil];
                [UIView setAnimationBeginsFromCurrentState:true];
                [UIView setAnimationDuration: SNIBBE_NAV_SLIDE_DUR];
                
                for ( UIViewController * curVC in vcStack_ )
                {
                    CGRect frame = curVC.view.frame;
                    curVC.view.frame = CGRectMake( frame.origin.x + animPosDelta.x, frame.origin.y + animPosDelta.y, frame.size.width, frame.size.height );
                }
                
                [UIView commitAnimations];
            }

        }
        

    }
    
}

//
//
- (void) popLastVC
{
    [self popLastVCWithStyle: animStyle_];
}

- (void) popLastVCWithStyle: (SnibbeNavControllerAnimStyleT) s
{
    int stackCount = [vcStack_ count];
    if ( parentVC_ && stackCount > 0 )
    {
        
        if ( stackCount == 1 )
        {
            // just pop it - already on screen so no animation
            [self popComplete];            
        }
        else
        {
            
            
            UIViewController * vcLast = [vcStack_ objectAtIndex: [vcStack_ count] - 1];
            CGRect lastFrame = vcLast.view.frame;
            CGPoint animPosDelta = CGPointZero;
            
            switch (pushDir_)
            {
                case eSNCUp:
                {                 
                    animPosDelta = CGPointMake( 0.0f, lastFrame.size.height );
                    break;
                }
                    
                case eSNCDown:
                {
                    animPosDelta = CGPointMake( 0.0f, -lastFrame.size.height );
                    break;
                }
                    
                case eSNCLeft:
                {                   
                    animPosDelta = CGPointMake( -lastFrame.size.width, 0.0f );
                    break;
                }
                    
                case eSNCRight:
                default:
                {
                    
                    animPosDelta = CGPointMake( lastFrame.size.width, 0.0f );
                    break;
                }
                    
            }
            
            //  begin the animation where we pop off the the current visible view!
            
            
            if ( s == eSnibbeAnimNone )
            {
                
                for ( UIViewController * curVC in vcStack_ )
                {
                    CGRect frame = curVC.view.frame;
                    curVC.view.frame = CGRectMake( frame.origin.x + animPosDelta.x, frame.origin.y + animPosDelta.y, frame.size.width, frame.size.height );
                }
                
                [self popComplete];
                
            }
            else if ( s == eSnibbeAnimSlide )
            {
                
                [UIView beginAnimations: @"snibbe nav slide" context:nil];
                [UIView setAnimationBeginsFromCurrentState:true];
                [UIView setAnimationDuration: SNIBBE_NAV_SLIDE_DUR];
                
                for ( UIViewController * curVC in vcStack_ )
                {
                    CGRect frame = curVC.view.frame;
                    curVC.view.frame = CGRectMake( frame.origin.x + animPosDelta.x, frame.origin.y + animPosDelta.y, frame.size.width, frame.size.height );
                }
                
                [UIView commitAnimations];
                
                [self performSelector:@selector(popComplete) withObject:nil afterDelay:SNIBBE_NAV_SLIDE_DUR];
            }

            
        }
        

        
    }
    
}

//
//
- (int) numVCs
{

    if ( vcStack_ )
    {
        return [vcStack_ count];
    }
    
    return 0;
}

//
//
- (UIViewController *) vcAtIndex: (int) iIndex
{
    if ( vcStack_ )
    {
        return [vcStack_ objectAtIndex: iIndex];
    }
    
    return nil;
}

//
//
- (void) clear
{
    for ( UIViewController * vc in vcStack_ )
    {                    
        [vc.view removeFromSuperview];
    }

    [vcStack_ removeAllObjects];
    
}

//
//
- (void) clearToIndex: (int) iIndex
{
    while( [vcStack_ count] > iIndex )
    {
        [self popLastVCWithStyle: eSnibbeAnimNone];
    }
            
}


#pragma mark private implementation

//
//
- (void) popComplete
{
    if ( [vcStack_ count] > 0 )
    {
                
        UIViewController * vcLast = [vcStack_ objectAtIndex: [vcStack_ count] - 1];
        if ( vcLast )
        {        
            [vcLast.view removeFromSuperview];
            [vcStack_ removeLastObject];
        }
    }
}


@end
