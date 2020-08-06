//
//  MPUIBrushPreviewView.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/21/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>

class MShapeInstance;

@interface MPUIBrushPreviewView : UIView
{
    MShapeInstance * shapeInst_;
    bool dirty_;
    
}

@property (nonatomic) bool dirty_;

@end
