//
//  MPMediaController.h
//  MotionPhone
//
//  Created by Graham McDermott on 1/12/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPUIViewControllerHiding.h"
#import <MediaPlayer/MPMediaPickerController.h>

@class UIOrientView;
@class MPMediaPickerController;
@protocol MPMediaPickerControllerDelegate;

@interface MPMediaController : MPUIViewControllerHiding <MPMediaPickerControllerDelegate>
{
    IBOutlet UIView *viewMainBG_;
    IBOutlet UIOrientView * orientView_;
    
    MPMediaPickerController * mediaPicker_;
}

@end
