/*
 *  defs.h
 *  gravilux
 *
 *  Created by Scott Snibbe on 2/25/10.
 *  Copyright 2010 Scott Snibbe. All rights reserved.
 *
 */

#pragma once

#include <vector>
using std::vector; 

// global application instance
class Gravilux;
extern Gravilux *gGravilux;
//extern vector<ofImage*> gTextures;

typedef struct FPoint {
	float x;
	float y;
	inline FPoint operator+(const FPoint &rhs) const
	{
		FPoint ret;
		ret.x = x + rhs.x;
		ret.y = y + rhs.y;
		return ret;
	}
} FPoint;

typedef struct Color {
	float r,g,b;
} Color;

typedef struct ColorSet {
	Color fast,medium,slow;
} ColorSet;

typedef struct TPoint {
	float	time;
	FPoint	point;
} TPoint;

#define SETCOLOR(C, R, G, B) {(C).r = (R);(C).g = (G);(C).b = (B); }
#define ROUNDINT( d ) ((int)((d) + ((d) > 0 ? 0.5 : -0.5)))
/*
 #define ABS(X) ((X) < 0 ? -(X) : (X))
 #define MAX(X, Y) ((X) < (Y) ? (Y) : (X))
 #define MIN(X, Y) ((X) > (Y) ? (Y) : (X))
 */
#define DISTANCE_SQ(A, B) \
(((A).x - (B).x)*((A).x - (B).x) + ((A).y - (B).y)*((A).y - (B).y))

#define DISTANCE(A, B) sqrtf(DISTANCE_SQ(A,B))

#define LERP(A, B, I) ((A)*(1.0-I) + (B)*(I))

#define RANDOM(LOWER , UPPER) ((rand() / RAND_MAX ) * ((UPPER)-(LOWER)) - (LOWER))
