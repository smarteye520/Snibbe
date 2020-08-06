/*
 * LITHEforce.h
 * Scott Snibbe
 *
 * (c) 1998 Scott Snibbe
 */

#ifndef LITHEFORCE
#define LITHEFORCE

#include "Vector3D.h"

class LITHEforce;

class LITHEforce {
public:
	//virtual Vector calcForce() =0;
	virtual void accumulateAccel() =0;	// Apply forces to acceleration of connected masses

	virtual bool equals(LITHEforce *f) =0;
private:
};

#endif // LITHEFORCE
