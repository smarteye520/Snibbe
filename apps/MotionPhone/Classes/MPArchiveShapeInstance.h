//
//  MPArchiveShapeInstance.h
//  MotionPhone
//
//  Created by Graham McDermott on 12/2/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "defs.h"


@interface MPArchiveShapeInstance : NSObject <NSCoding>
{
 

    int shapeID_;            
    
    CGPoint cachedPoints_[MAX_POLYGON_POINTS * 2];
    int numCachedPoints_;
    
    CGPoint curPos_;
    float curShapeScale_;
    float curStretch_;
    float curRot_;
    bool  curFill_;
    bool  constantOutlineWidth_;
}


- (void) encodeWithCoder:(NSCoder *) aCoder;
- (id) initWithCoder:(NSCoder *) aDecoder;

- (void) addCachedPt: (CGPoint) pt;
- (int) numCachedPts;
- (CGPoint) cachedPtAtIndex: (int) iIndex;

@property (nonatomic, assign) int shapeID_;
@property (nonatomic, assign) CGPoint curPos_;
@property (nonatomic, assign) float curShapeScale_;
@property (nonatomic, assign) float curStretch_;
@property (nonatomic, assign) float curRot_;
@property (nonatomic, assign) bool curFill_;
@property (nonatomic, assign) bool constantOutlineWidth_;

@end
