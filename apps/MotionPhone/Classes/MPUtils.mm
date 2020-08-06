//
//  MPUtils.m
//  MotionPhone
//
//  Created by Graham McDermott on 1/18/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#import "MPUtils.h"
#import "defs.h"
#import "Parameters.h"


@implementation MPUtils



// given the device orientation and the orient brush style return an angle in
// radians that should be added to the brush's angle for drawing purposes

+ (float) thetaAugForBrushStroke
{
    
    bool brushOrient = gParams->brushOrient();
    
    // in the case where we aren't orienting the brush to the direction of the stroke
    // we need to modify the theta to reflect the user's device orientation so that
    // the symbol appears face-up
    switch (gDeviceOrientation) 
    {
        case UIDeviceOrientationPortrait:
        {
            return (brushOrient ? PIOVER2 : 0);
        }
        case UIDeviceOrientationPortraitUpsideDown:
        {
            return (brushOrient ? PIOVER2 : PI);
        }
        case UIDeviceOrientationLandscapeLeft:
        {
            return (brushOrient ? PIOVER2 : -PIOVER2);
        }
        case UIDeviceOrientationLandscapeRight:
        {
            return (brushOrient ? PIOVER2 : PIOVER2);
        }                        
        default:
        {
            return 0.0f;
        }
    }
}



//
// helper for updating fps button
+ (void) updateFPSIndicator: (MPUIOrientButton *) buttonFPS
{
    
    UIColor *textCol = gParams->fpsShown() ? [UIColor blackColor] : [UIColor whiteColor];
    
    double frameTime = gParams->minFrameTime();
    double fps = 1.0f / frameTime;
    
    double normalized = (fps - MIN_FPS) / (double) (MAX_FPS - MIN_FPS);
    //normalized = 1.0f - normalized;
    
    normalized = MIN( normalized, 0.99f );    
    normalized = MAX( normalized, 0.01f );
    
    int fpsNum = normalized * (MAX_DISPLAY_FPS-MIN_DISPLAY_FPS + 1) + MIN_DISPLAY_FPS - 1;
    fpsNum++;
    
    fpsNum *= gParams->frameDir();
    
    NSString *labelTitle = [NSString stringWithFormat:@"%d", fpsNum];            
    
    [buttonFPS setTitle:labelTitle forState:UIControlStateNormal ];
    [buttonFPS setTitleColor:textCol forState:UIControlStateNormal ];
    
}

@end
