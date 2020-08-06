//
//  TPoint.h
//  SnibbeLib
//
//  Created by Colin Roache on 6/18/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef SnibbeLib_TPoint_h
#define SnibbeLib_TPoint_h
#include "FPoint.h"

typedef struct TPoint {
	float	time;
	FPoint	point;
    int		timeStepDenominator; // Treated as: tempo/(1<<ts)
} TPoint;

typedef struct TPoint1_0 {
	float	time;
	FPoint	point;
} TPoint1_0;

#endif
