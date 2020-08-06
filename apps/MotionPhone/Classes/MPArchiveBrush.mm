//
//  MPArchiveBrush.m
//  MotionPhone
//
//  Created by Graham McDermott on 12/2/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPArchiveBrush.h"

NSString * keyUserData = @"mp_brush_userdata";
NSString * keyCenter = @"mp_brush_center";
NSString * keyScaleX = @"mp_brush_scale_x";
NSString * keyScaleY = @"mp_brush_scale_y";
NSString * keyRot = @"mp_brush_rot";
NSString * keyZOrder = @"mp_brush_z_order";
NSString * keyUniqueID = @"mp_brush_unique_id";
NSString * keyPoint1 = @"mp_brush_point_1";
NSString * keyPoint2 = @"mp_brush_point_2";
NSString * keyWidth = @"mp_brush_width";
NSString * keyFill = @"mp_brush_fill";
NSString * keyColor = @"mp_brush_color";
NSString * keyShapeInstance = @"mp_brush_shape_instance";
NSString * keyConstantOutline = @"mp_constant_outline";

@implementation MPArchiveBrush

@synthesize fill;
@synthesize userData_;
@synthesize centerPt_;
@synthesize scaleX_;
@synthesize scaleY_;
@synthesize rot_;
@synthesize zOrder_;
@synthesize uniqueID_;
@synthesize width;
@synthesize constantOutlineWidth_;



- (void) reset
{

    userData_ = 0;
    centerPt_ = CGPointZero;    
    scaleX_ = 1.0f;
    scaleY_ = 1.0f;
    rot_ = 0.0f;
    constantOutlineWidth_ = DEFAULT_CONSTANT_OUTLINE_WIDTH;
    
    zOrder_ = 0;
    uniqueID_ = 0;


    p1[0] = 0.0f;
    p1[1] = 0.0f;    
    p2[0] = 1.0f;
    p2[1] = 1.0f;
    
    width = 1.0f;
    
    fill = FALSE;
    si_ = 0;

    MCOLOR_SET( color, 1.0, 1.0, 1.0, 1.0 );

    
}


//
//
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    // for saving brush data to the coder
    
    [aCoder encodeInt: userData_ forKey:keyUserData];
    [aCoder encodeCGPoint: centerPt_ forKey:keyCenter];
    [aCoder encodeFloat:scaleX_ forKey:keyScaleX];
    [aCoder encodeFloat:scaleY_ forKey:keyScaleY];
    [aCoder encodeFloat:rot_ forKey:keyRot];
    [aCoder encodeInt:zOrder_ forKey:keyZOrder];
    [aCoder encodeInt:uniqueID_ forKey:keyUniqueID];
    [aCoder encodeBool:constantOutlineWidth_ forKey:keyConstantOutline];
    
    CGPoint point1 = CGPointMake( p1[0], p1[1] );
    CGPoint point2 = CGPointMake( p2[0], p2[1] );
    
    [aCoder encodeCGPoint: point1 forKey:keyPoint1];
    [aCoder encodeCGPoint: point2 forKey:keyPoint2];
    
    [aCoder encodeFloat:width forKey:keyWidth];
    [aCoder encodeBool:fill forKey:keyFill];
    
    unsigned int iCol = 0;
    MCOLOR_TO_INT32( color,  iCol );
    
    [aCoder encodeInt32:iCol forKey:keyColor];
    
    [aCoder encodeObject: si_ forKey:keyShapeInstance];
}

//
//
- (id)init
{
    
    if ( ( self = [super init] ) )
    {
        [self reset];
    }
    
    return self;
    
}


//
//
- (id)initWithCoder:(NSCoder *)aDecoder
{
    
    // in this case super doesn't conform to initWithCoder
    if ( ( self = [super init] ) )
    {
        // load in the the brush data        
        [self reset];
        
        
        userData_ = [aDecoder decodeIntForKey: keyUserData];
        centerPt_ = [aDecoder decodeCGPointForKey: keyCenter];
        scaleX_ =  [aDecoder decodeFloatForKey: keyScaleX];
        scaleY_ = [aDecoder decodeFloatForKey: keyScaleY];
        rot_ = [aDecoder decodeFloatForKey: keyRot];
        zOrder_ = [aDecoder decodeIntForKey: keyZOrder];
        uniqueID_ = [aDecoder decodeIntForKey: keyUniqueID];
        
        constantOutlineWidth_ = DEFAULT_CONSTANT_OUTLINE_WIDTH;        
        
        // introduced in 1.1
        if ( [aDecoder containsValueForKey:keyConstantOutline] )
        {        
            constantOutlineWidth_ = [aDecoder decodeBoolForKey: keyConstantOutline];
        }
        else
        {
            // version 1.0
            constantOutlineWidth_ = false;
        }
        
        
        CGPoint point1 = [aDecoder decodeCGPointForKey: keyPoint1];
        CGPoint point2 = [aDecoder decodeCGPointForKey: keyPoint2];
        
        p1[0] = point1.x;
        p1[1] = point1.y;
        
        p2[0] = point2.x;
        p2[1] = point2.y;
        
        width = [aDecoder decodeFloatForKey: keyWidth];
        fill = [aDecoder decodeBoolForKey: keyFill];                
        
        unsigned int iCol = [aDecoder decodeInt32ForKey: keyColor];
        MCOLOR_FROM_INT32( color, iCol );                
        
        si_ = [aDecoder decodeObjectForKey:keyShapeInstance];
        if ( si_ )
        {
            [si_ retain];
        }
    }
    
    return self;
    
}

//
//
- (void) dealloc
{
    if ( si_ )
    {
        [si_ release];
    }
    
    [super dealloc];
}


//
//
- (void) setShapeInstance: (MPArchiveShapeInstance *) si
{
    if ( si_ )
    {
        [si_ release];
    }
    
    si_ = [si retain];
}

//
//
- (MPArchiveShapeInstance *) getShapeInstance
{
    return si_;
}


//
//
- (void) setPointsP1: (float[2]) point1 P2: (float[2]) point2
{
    p1[0] = point1[0];
    p1[1] = point1[1];
    
    p2[0] = point2[0];
    p2[1] = point2[1];
    
}


//
//
- (void) getPointsP1: (float[2]) point1 P2: (float[2]) point2
{
    point1[0] = p1[0];
    point1[1] = p1[1];
    
    point2[0] = p2[0];
    point2[1] = p2[1];
    
}


//
//
- (void) setColor: (MColor) col
{
    MCOLOR_COPY( color, col );
}

//
//
- (void) getColor: (MColor) outColor
{

    MCOLOR_COPY( outColor, color);
}


@end
