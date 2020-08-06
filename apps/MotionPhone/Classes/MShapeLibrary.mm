//
//  MShapeLibrary.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/10/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MShapeLibrary.h"
#import "MShapeSet.h"
#import "MShape.h"

MShapeLibrary * shapeLibrary = 0; // the singleton

@implementation MShapeLibrary


- (id) init
{

    if ( ( self = [super init] ) )
    {
        shapeSets_ = [[NSMutableArray alloc] init];
    }
    
    return self;

}

//
//
- (void) dealloc
{
    if ( shapeSets_ )
    {
        [shapeSets_ release];
    }
}

//
//
- (int) numShapeSets
{
    return [shapeSets_ count];
}

//
//
- (MShapeSet *) shapeSetAtIndex: (int) iIndex
{
    if ( iIndex >= 0 && iIndex < [shapeSets_ count] )
    {
        return [shapeSets_ objectAtIndex: iIndex];
    }
    
    return 0;
}

//
//
- (MShape *) shapeForID: (ShapeID) theID;
{
    for ( MShapeSet * curSS in shapeSets_ )
    {
        
        MShape *pS = [curSS shapeForID: theID];
        if ( pS )
        {
            return pS;
        }
    }
    
    return nil;
}

//
//
- (MShape *) defaultShape
{
    MShapeSet * defSet = [shapeSets_ objectAtIndex:0];
    return [defSet shapeAtIndex:0];
}

//
//
+ (void) initLibrary
{
    shapeLibrary = [[MShapeLibrary alloc] init]; 
    
    // populate        
    
    [shapeLibrary->shapeSets_ addObject: [[MShapeSet alloc] initFromPlist: @"shapes_default" ]]; 
    
    
}

//
//
+ (void) releaseLibrary
{
    if ( shapeLibrary )
    {
        [shapeLibrary release];
        shapeLibrary = 0;
    }
}

//
//
+ (MShapeLibrary *) lib
{
    return shapeLibrary;
}


@end
