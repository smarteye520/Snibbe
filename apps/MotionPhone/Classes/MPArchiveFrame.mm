//
//  MPArchiveFrame.m
//  MotionPhone
//
//  Created by Graham McDermott on 12/2/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPArchiveFrame.h"

NSString * keyBrushArray = @"mp_brush_array";

@implementation MPArchiveFrame





//
//
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    // creation of archive
    
    [aCoder encodeObject:arrayBrushes_ forKey:keyBrushArray];
    
}

//
//
- (id) init
{
    if ( ( self = [super init] ) )
    {
        arrayBrushes_ = [[NSMutableArray alloc] init];
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
        // load in the array of brushes        
        arrayBrushes_ = [aDecoder decodeObjectForKey: keyBrushArray];    
        if ( arrayBrushes_ )
        {
            [arrayBrushes_ retain];
        }
    }
 
    
    return self;
    
}

//
//
- (void) dealloc
{
    if ( arrayBrushes_ )    
    {
        [arrayBrushes_ release];        
    }
}



//
//
- (void) addBrush: (MPArchiveBrush *) b
{
    if ( arrayBrushes_ )
    {
        [arrayBrushes_ addObject: b];
    }
}

//
//
- (int) numBrushes
{
    return arrayBrushes_ ? [arrayBrushes_ count] : 0;
}

//
//
- (MPArchiveBrush *) brushAtIndex: (int) iIndex
{
    if ( arrayBrushes_ && iIndex < [arrayBrushes_ count] )
    {
        return [arrayBrushes_ objectAtIndex: iIndex];
    }
    
    return nil;
}



@end
