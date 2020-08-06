//
//  SnibbeUtils.mm
//  SnibbeLib
//
//  Created by Graham McDermott on 5/13/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//

#include "SnibbeUtils.h"
#include <cstdlib>

#pragma mark comparison

//
// compare two floats within a certain epsilon range
bool fuzzyCompare( float a, float b, float epsilon )
{
    return ( a - epsilon <= b && b <= a + epsilon );
}


#pragma mark random


//
//
float randFloat( float minVal, float maxVal )
{
    
    float r = (float)rand()/(float)RAND_MAX; // 0 - 1.0
    return (maxVal - minVal) * r + minVal;
    
}


#pragma mark easing functions


//
//
float easeInOutMinMax( float min, float max, float input )
{
    float interp = (input - min) / (max - min);
    
    interp = MAX( interp, 0.0f );
    interp = MIN( interp, 1.0f );
    
    float smoothed = interp * interp * (3.0f - 2.0f * interp);
    
    smoothed = MAX( smoothed, 0.0f );
    smoothed = MIN( smoothed, 1.0f );
    
    return smoothed;
}

//
//
float easeInOutRange( float min, float range, float input )
{
    return easeInOutMinMax(min, min+range, input);
}

//
//
float easeInOutMinMaxd( double min, double max, double input )
{
    float interp = (input - min) / (max - min);
    
    interp = MAX( interp, 0.0f );
    interp = MIN( interp, 1.0f );
    
    float smoothed = interp * interp * (3.0f - 2.0f * interp);
    
    smoothed = MAX( smoothed, 0.0f );
    smoothed = MIN( smoothed, 1.0f );
    
    return smoothed;
}

//
//
float easeInOutRanged( double min, double range, double input )
{
    return easeInOutMinMaxd(min, min+range, input);
}