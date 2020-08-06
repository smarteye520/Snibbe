// SnibbePerlin.h
// SnibbeLib
// (c) 2007 Scott Snibbe, Inc.

#ifndef SNIBBEPERLIN_H
#define SNIBBEPERLIN_H

#include <math.h>
#ifndef M_PI
#define M_PI 3.141592654
#endif
#define FRAND(MIN, MAX) \
 (((float) rand() / (float) RAND_MAX) * ((MAX) - (MIN)) + (MIN))
 
// periodic functions - utility class
class SnibbePerlin {
public:
	
	typedef float (MotionFunc)(float) ;
	
	enum FuncType {
		RSIN,
		RCOS,
		RSIN2,
		RCOS2,
		NOISE1,
		NOISE2,
		NOISE3,
		CUSTOM
	};
	
	SnibbePerlin(int noiseArraySize = 512);
	~SnibbePerlin();
	
	float f(FuncType type, float t);
	
	// All functions normalized to serve as interpolating variable: [0, 1]
	
	float rsin(float t) { return (1 + sin(t*M_PI)) / 2; }
	float rcos(float t) { return (1 + cos(t*M_PI)) / 2; }
	float rsin2(float t) { return rsin(2*t); }
	float rcos2(float t) { return rcos(2*t); }
	
	// independent coherent normalized noise sources
	float noise1(float t) { return .5 * (1 + noise(t)); }
	float noise2(float t) { return .5 * (1 + noise(t+100)); }
	float noise3(float t) { return .5 * (1 + noise(t+200)); }
	
	// coherent noise source w/ zeros at integer time values: [-1, 1]
	float noise(float t);
	
private:
	
	int nGradients_;
	float *gradients_;
};

#endif // SNIBBEPERLIN_H
