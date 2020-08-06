// (c) 1998-2011 Scott Snibbe

#include "LITHEforceGlobal.h"

LITHEforceGlobal::LITHEforceGlobal(
	vector<LITHEmass*> *masses,
	Vector gravityVec,
	float viscosity)
{
    forceType_ = ForceType_Direction;
    
	masses_ = masses;
	gravityVec_ = gravityVec;
	viscosity_ = viscosity;
    variance_ = 0.0;
}

LITHEforceGlobal::LITHEforceGlobal(
                 vector<LITHEmass*> *masses,
                 Vector point_,             // either direction, or position
                 float magnitude,
                 float viscosity)
{
    forceType_ = ForceType_Point;
    
	masses_ = masses;
	pointVec_ = point_;
    magnitude_ = magnitude;
	viscosity_ = viscosity;
    variance_ = 0.0;
}

LITHEforceGlobal::~LITHEforceGlobal()
{
}

bool
LITHEforceGlobal::equals(LITHEforce *f)
{
	bool result = false;

#ifdef sgi
	if ((void*)f == (void*)this)
	     result = true;
	else
	     result = false;
#else
	LITHEforceGlobal *fGlobal = dynamic_cast<LITHEforceGlobal*> (f);

	if (!fGlobal) {
		// false
	} else if ((void*)fGlobal == (void*)this) {
		result = true;
	}
#endif
	return result;
}
