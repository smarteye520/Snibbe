// SnibbePerlin.mm
// SnibbeLib
// (c) 2007 Scott Snibbe, Inc.

#include <stdlib.h>
#include "SnibbePerlin.h"

SnibbePerlin::SnibbePerlin(int noiseArraySize)
{
	nGradients_ = noiseArraySize;
	gradients_ = new float [nGradients_];
	
	for (int i = 0; i < nGradients_; i++) {
		gradients_[i] = FRAND(-4,4);
	}
}

SnibbePerlin::~SnibbePerlin()
{
	delete [] gradients_;
}

float 
SnibbePerlin::noise(float t)
{
	// noise function doesn't work when < 0
	while (t < 0) { 
		t += nGradients_;
	}
	
	int lowIndex = ((int) t) % nGradients_;
	int highIndex = ((int) (t+1)) % nGradients_;
	if (highIndex == nGradients_) 
		highIndex = 0;
	
	float grad1 = gradients_[lowIndex];
	float grad2 = gradients_[highIndex];
	
	t = t - floor(t);
	float t2 = t*t, t3 = t2*t;
	
	float c3 = t3 - 2*t2 + t;
	float c4 = t3 - t2;
	
	// start and end points are 0, so 1st 2 coefficient's don't matter
	return c3 * grad1 + c4 *grad2;
}

float 
SnibbePerlin::f(
			  FuncType type, 
			  float t)
{
	switch (type) {
		case RSIN:
			return rsin(t);
			break;
		case RCOS:
			return rcos(t);
			break;
		case RSIN2:
			return rsin2(t);
			break;
		case RCOS2:
			return rcos2(t);
			break;
		case NOISE1:
			return noise1(t);
			break;
		case NOISE2:
			return noise2(t);
			break;
		case NOISE3:
			return noise3(t);
			break;
		default:
			return 0;
			break;
	}
}


