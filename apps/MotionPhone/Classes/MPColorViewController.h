//
//  MPColorViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/15/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIViewControllerHiding.h"
#import "SnibbeColorPickerController.h"


@class MPUIBrushPreviewView;

@interface MPColorViewController : MPUIViewControllerHiding <ColorPickerDelegate>
{
    IBOutlet UIView *viewMainBG_;
    IBOutlet UIView *brushPreviewViewArea_;
    IBOutlet UIView *colorPickerViewArea_;
    IBOutlet UIImageView *imageViewJoin_;
    
    MPUIBrushPreviewView * brushPreviewView_;
    
    SnibbeColorPickerController * ssColorController_;
    
    NSString * colorPickerXIBOverride_;
    
}

@property (nonatomic, retain) NSString * colorPickerXIBOverride_;

- (CGRect) getJoinFrame;

// ColorPickerDelegate methods
- (void) onFGColorChanged:(CGColorRef)newColor;
- (void) onBGColorChanged:(CGColorRef)newColor;
- (void) onColorTargetChanged;

- (void) colorRefToFloats: (CGColorRef) cRef outVals: (float[4]) rgba;




@end
