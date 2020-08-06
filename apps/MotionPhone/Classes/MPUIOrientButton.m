//
//  MPUIOrientButton.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/10/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIOrientButton.h"

@implementation MPUIOrientButton

//
//
- (void) releaseImages
{
    if ( imageOn_ )
    {
        [imageOn_ release];
        imageOn_ = nil;
    }
    
    if ( imageOff_ )
    {
        [imageOff_ release];
        imageOff_ = nil;
    }

}

//
//
- (id) initWithFrame:(CGRect)frame
{
 
    if ( ( self = [super initWithFrame: frame] ) )
    {
        bOn_ = false;
        imageOn_ = nil;
        imageOff_ = nil;
    }
    
    return self;
}


//
//
- (void) dealloc
{
    
    [self releaseImages];
    
    
    [super dealloc];
    
}


//
//
- (void) setImageNamesOn: (NSString *) imageOn off: (NSString *) imageOff
{

    [self releaseImages];
    
    imageOn_ = [[UIImage imageNamed: imageOn] retain];
    imageOff_ = [[UIImage imageNamed: imageOff] retain];
    
    [self setOn: false];
}

//
//
- (void) setOn: (bool) bOn
{
    
    if ( imageOn_ && imageOff_ )
    {    
        [self setBackgroundImage: bOn ? imageOn_ : imageOff_ forState: UIControlStateNormal];    
    }
    
    bOn_ = bOn;
    
    
}

//
//
- (bool) getOn
{
    return bOn_;
}





@end
