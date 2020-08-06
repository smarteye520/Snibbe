//
//  MPArchiveShapeInstance.m
//  MotionPhone
//
//  Created by Graham McDermott on 12/2/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPArchiveShapeInstance.h"

NSString * keySIShapeID = @"mp_si_shape_id";
NSString * keySIPoints = @"mp_si_points";
NSString * keySINumPoints = @"mp_si_num_points";
NSString * keySIPos = @"mp_si_pos";
NSString * keySIScale = @"mp_si_scale";
NSString * keySIStretch = @"mp_si_stretch";
NSString * keySIRot = @"mp_si_rot";
NSString * keySIFill = @"mp_si_fill";
NSString * keySIConstantOutline = @"mp_si_constant_outline";

// private interface
@interface MPArchiveShapeInstance()


- (void) reset;

@end



@implementation MPArchiveShapeInstance


@synthesize shapeID_;
@synthesize curPos_;
@synthesize curShapeScale_;
@synthesize curStretch_;
@synthesize curRot_;
@synthesize curFill_;
@synthesize constantOutlineWidth_;



//
//
- (void) encodeWithCoder:(NSCoder *) aCoder
{
    // for saving shape data to the coder
    
    [aCoder encodeInt: shapeID_ forKey:keySIShapeID];
    
    [aCoder encodeBytes:(unsigned char *)cachedPoints_  length:sizeof(CGPoint) * numCachedPoints_ forKey: keySIPoints];    
    [aCoder encodeInteger:numCachedPoints_ forKey:keySINumPoints];
    [aCoder encodeCGPoint:curPos_ forKey:keySIPos];
    [aCoder encodeFloat:curShapeScale_ forKey:keySIScale];
    [aCoder encodeFloat:curStretch_ forKey:keySIStretch];
    [aCoder encodeFloat:curRot_ forKey:keySIRot];
    [aCoder encodeBool:curFill_ forKey:keySIFill];
    [aCoder encodeBool:constantOutlineWidth_ forKey:keySIConstantOutline];
}

//
//
- (id) init
{
    if ( ( self = [super init] ) )
    {
        numCachedPoints_ = 0;
        [self reset];
    }
    return self;
}


//
//
- (id) initWithCoder:(NSCoder *) aDecoder;
{
    // in this case super doesn't conform to initWithCoder
    
    if ( ( self = [super init] ) )
    {
        
        [self reset];                 
        
        curPos_ = [aDecoder decodeCGPointForKey: keySIPos];
        curShapeScale_ = [aDecoder decodeFloatForKey: keySIScale];
        curStretch_ = [aDecoder decodeFloatForKey: keySIStretch];
        curRot_ = [aDecoder decodeFloatForKey: keySIRot];
        curFill_ = [aDecoder decodeBoolForKey: keySIFill];
        numCachedPoints_ = [aDecoder decodeIntegerForKey: keySINumPoints];                
        
        NSUInteger pointLen = 0;
        const unsigned char * pointMem = [aDecoder decodeBytesForKey:keySIPoints returnedLength: &pointLen];
        memcpy( cachedPoints_, pointMem, pointLen );            
        
        shapeID_ = [aDecoder decodeIntForKey: keySIShapeID];
        
        constantOutlineWidth_ = DEFAULT_CONSTANT_OUTLINE_WIDTH;        
        
        // introduced in 1.1
        if ( [aDecoder containsValueForKey:keySIConstantOutline] )
        {        
            constantOutlineWidth_ = [aDecoder decodeBoolForKey: keySIConstantOutline];
        }
        else
        {
            // version 1.0
            constantOutlineWidth_ = false;
        }

        
    }
    
    return self;
    
}

- (void) dealloc
{

    
    [super dealloc];
}

//
//
- (void) addCachedPt: (CGPoint) pt
{
    cachedPoints_[numCachedPoints_++] = pt;        
}

//
//
- (int) numCachedPts
{
    return numCachedPoints_;
        
}

//
//
- (CGPoint) cachedPtAtIndex: (int) iIndex
{
    
    if ( iIndex >= 0 && iIndex < numCachedPoints_ )
    {
        return cachedPoints_[iIndex];
    }
    
    return CGPointZero;
}



#pragma mark private implementation

- (void) reset
{

    numCachedPoints_ = 0;    
    curPos_ = CGPointZero;
    curShapeScale_ = 1.0f;
    curStretch_ = 1.0f;
    curRot_ = 0.0f;
    curFill_ = true;
    constantOutlineWidth_ = DEFAULT_CONSTANT_OUTLINE_WIDTH;
    
}


@end



























