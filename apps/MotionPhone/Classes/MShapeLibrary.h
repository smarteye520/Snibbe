//
//  MShapeLibrary.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/10/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "defs.h"

@class MShapeSet;
class MShape;

@interface MShapeLibrary : NSObject
{
    NSMutableArray * shapeSets_;
}

- (int) numShapeSets;
- (MShapeSet *) shapeSetAtIndex: (int) iIndex;
- (MShape *) shapeForID: (ShapeID) theID;
- (MShape *) defaultShape;

+ (void) initLibrary;
+ (void) releaseLibrary;

+ (MShapeLibrary *) lib;


// todo - populate 

@end
