//
//  MPArchiveFrame.h
//  MotionPhone
//
//  Created by Graham McDermott on 12/2/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPArchiveBrush;

@interface MPArchiveFrame : NSObject <NSCoding>
{
    NSMutableArray * arrayBrushes_;  // MParchiveBrush object
    
}

- (void) addBrush: (MPArchiveBrush *) b;
- (int) numBrushes;
- (MPArchiveBrush *) brushAtIndex: (int) iIndex;


- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end
