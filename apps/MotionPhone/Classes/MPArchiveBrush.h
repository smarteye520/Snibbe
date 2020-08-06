//
//  MPArchiveBrush.h
//  MotionPhone
//
//  Created by Graham McDermott on 12/2/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "defs.h"

@class MPArchiveShapeInstance;


@interface MPArchiveBrush : NSObject <NSCoding>
{
    
    
    unsigned int userData_;
    
    CGPoint    centerPt_;
    float      scaleX_;
    float      scaleY_;
    float      rot_;
    
    unsigned   int zOrder_;
    unsigned   int uniqueID_;
    
    float      p1[2], p2[2];
    float      width;          // in vp coordinates
    
    bool        fill;
    MColor      color;
    
    bool        constantOutlineWidth_;
    
    MPArchiveShapeInstance * si_;
    
    
}

- (void) encodeWithCoder:(NSCoder *) aCoder;
- (id) initWithCoder:(NSCoder *) aDecoder;

- (void) setShapeInstance: (MPArchiveShapeInstance *) si;
- (MPArchiveShapeInstance *) getShapeInstance;
- (void) setPointsP1: (float[2]) point1 P2: (float[2]) point2;
- (void) getPointsP1: (float[2]) point1 P2: (float[2]) point2;
- (void) setColor: (MColor) col;
- (void) getColor: (MColor) outColor;


@property (nonatomic, assign) bool fill;
@property (nonatomic, assign) unsigned int userData_;
@property (nonatomic, assign) CGPoint centerPt_;
@property (nonatomic, assign) float scaleX_;
@property (nonatomic, assign) float scaleY_;
@property (nonatomic, assign) float rot_;
@property (nonatomic, assign) unsigned int zOrder_;
@property (nonatomic, assign) unsigned int uniqueID_;
@property (nonatomic, assign) float width;
@property (nonatomic, assign) bool constantOutlineWidth_;


@end
