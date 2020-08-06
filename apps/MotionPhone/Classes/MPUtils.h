//
//  MPUtils.h
//  MotionPhone
//
//  Created by Graham McDermott on 1/18/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPUIOrientButton;

@interface MPUtils : NSObject

+ (float) thetaAugForBrushStroke;
+ (void) updateFPSIndicator: (MPUIOrientButton *) buttonFPS;

@end
