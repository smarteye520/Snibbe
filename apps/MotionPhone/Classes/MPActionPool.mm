//
//  MPActionPool.mm
//  MotionPhone
//
//  Created by Graham McDermott on 2/15/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#import "MPActionPool.h"


// global pool definitions

MPActionPool<MPActionBrush, ACTION_POOL_SIZE> gPoolBrush;
MPActionPool<MPActionUpdateBrushVals, ACTION_POOL_SIZE> gPoolUpdateBrushVals;