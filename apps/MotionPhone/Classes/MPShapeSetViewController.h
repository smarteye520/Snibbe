//
//  MPShapeSetViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/22/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MShapeSet;


@interface MPShapeSetViewController : UIViewController
{

    MShapeSet * shapeSet_;
    NSMutableArray *shapeButtons_;
    
    IBOutlet UIScrollView *scrollView_;
    
}

- (void) setShapeSet: (MShapeSet *) s; // doesn't retain

@end
