//
//  SnibbeUtils.h
//  SnibbeLib
//
//  Created by Graham McDermott on 5/13/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//

#ifndef SNIBBE_UTILS_H_
#define SNIBBE_UTILS_H_

#define ROUNDINT( d ) ((int)((d) + ((d) > 0 ? 0.5 : -0.5)))

#ifndef MAX
#define MAX(a, b) (((a) > (b)) ? (a) : (b))
#endif

#ifndef MIN
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#endif

// comparison
extern "C" bool fuzzyCompare( float a, float b, float epsilon = .000001 );

// random
extern "C" float randFloat( float minVal, float maxVal );

// easing functions
extern "C" float easeInOutMinMax( float min, float max, float input );
extern "C" float easeInOutRange( float min, float range, float input );

extern "C" float easeInOutMinMaxd( double min, double max, double input );
extern "C" float easeInOutRanged( double min, double range, double input );

#endif // #ifndef SNIBBE_UTILS_H_