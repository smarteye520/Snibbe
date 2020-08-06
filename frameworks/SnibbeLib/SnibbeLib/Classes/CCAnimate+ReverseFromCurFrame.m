//
//  CCAnimate+ReverseFromCurFrame.m
//  SnibbeLib
//
//  Created by Graham McDermott on 7/1/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//
#ifdef USING_COCOS_2D

#import "CCAnimate+ReverseFromCurFrame.h"
#import "CCSprite.h"
#import "CCAnimation.h"

@implementation CCAnimate ( ReverseFromCurFrame )


// Create a new CCAnimate object representing the reverse of this object, starting
// at its current frame and continuing to its beginning.
- (CCActionInterval *) reverseFromCurPointInAnim
{

    NSArray *oldArray = animation_.frames;
    int iNumTotalFrames = [oldArray count];
	NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:iNumTotalFrames];
    NSEnumerator *enumerator = [oldArray reverseObjectEnumerator];

    CCSprite *sprite = target_;
    
    bool bFound = false;
    
    int iNumFramesIncluded = 0;
    
    for (id element in enumerator)
    {
            
        if ( !bFound && [sprite isFrameDisplayed: element] )
        {
            bFound = true; // we found the current frame (or one that matches at least)                
        }
        
        if ( bFound )
        {
            ++iNumFramesIncluded;
            [newArray addObject:[[element copy] autorelease]];
        }                            
        
    }
    
    float newDuration = duration_ * (iNumFramesIncluded / (float) iNumTotalFrames);
	
	CCAnimation *newAnim = [CCAnimation animationWithFrames:newArray delay:animation_.delay];
	return [[self class] actionWithDuration:newDuration animation:newAnim restoreOriginalFrame:restoreOriginalFrame];
    
}


@end

#endif
