//
//  ColorViewController.h
//  MotionPhone
//
//  Created by Scott Snibbe on 5/16/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ColorViewController : UIViewController {
    // color swatches
    IBOutlet UIImageView     *bgSwatchesImageView, *fgSwatchesImageView;
    IBOutlet UIImageView     *bgCrossHairs, *fgCrossHairs;
    
    // brush preview
    IBOutlet  UIImageView     *brushImageView;
    
    UISlider	*alphaSlider;
    
    CGRect			bgSwatchesTouchRect, fgSwatchesTouchRect;
	CGSize			swatchBoxSize;
//    MColor			*colors;
}

@property(readonly, nonatomic) IBOutlet UISlider *alphaSlider;

- (void)updateUIFields:(bool)animate;
- (void) buildColorView:(UIImageView *)cView;
- (void)animateView:(UIImageView *)theView toPosition:(CGPoint) thePosition;

@end
