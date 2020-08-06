//
//  MShapeSet.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/10/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>

#include <vector>
#import "MShape.h"



@interface MShapeSet : NSObject
{
    std::vector<MShape *> shapes_;
    NSString * setName_;
}


- (id) initFromPlist: (NSString *) pListName;
- (int) numShapes;
- (MShape *) shapeAtIndex: (int) iIndex;
- (MShape *) shapeForID: (ShapeID) theID;


@end
