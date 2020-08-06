//
//  UIOrientListener.m
//  SnibbeLib
//
//  Created by Graham McDermott on 11/30/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "UIOrientListener.h"


NSString * notificationFirstValidOrientation = @"sss_first_valid_orientation";


@interface UIOrientListener()

- (void) onOrientationChanged;

@end




@implementation UIOrientListener

@synthesize lastValidOrientation_;

- (id) init
{

    if ( ( self = [super init] ) )
    {
        lastValidOrientation_ = [UIDevice currentDevice].orientation;
        bSeenValidOrient_ = false;
        
        if ( UIDeviceOrientationIsValidInterfaceOrientation( lastValidOrientation_ ) )
        {
            [[NSNotificationCenter defaultCenter] postNotificationName: notificationFirstValidOrientation object:self];
            bSeenValidOrient_ = true;
        }
        
        // add orientation notifications        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationChanged) name:UIDeviceOrientationDidChangeNotification object:nil];  
    }
    return self;
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}


//
//
- (bool) hasSeenValidOrientation
{
    return bSeenValidOrient_;    
}

#pragma mark private implementation

//
//
- (void) onOrientationChanged
{
    UIDeviceOrientation orient = [UIDevice currentDevice].orientation;
    if ( UIDeviceOrientationIsValidInterfaceOrientation( orient ) )
    {     
        
        lastValidOrientation_ = orient;  
        
        if ( !bSeenValidOrient_  )
        {
            [[NSNotificationCenter defaultCenter] postNotificationName: notificationFirstValidOrientation object:self];
            bSeenValidOrient_ = true;
        }
    }    

}

@end
