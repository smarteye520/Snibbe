// (c) 1998-2011 Scott Snibbe

#include "LITHEforceAngleSpring.h"

LITHEforceAngleSpring::LITHEforceAngleSpring(
	LITHEmass *m1,
	LITHEmass *m2,
	LITHEmass*m3,
	float restAngle,
	float kS,
	float kD)
{
	m1_ = m1;
	m2_ = m2;
	m3_ = m3;
	restAngle_ = restAngle;
	kS_ = kS;
	kD_ = kD;
}

LITHEforceAngleSpring::~LITHEforceAngleSpring()
{
}

bool
LITHEforceAngleSpring::equals(LITHEforce *f)
{
	bool result = false;

#ifdef sgi
	if ((void*)f == (void*)this)
	     result = true;
	else
	     result = false;
#else
	LITHEforceAngleSpring *fSpring = dynamic_cast<LITHEforceAngleSpring*> (f);

	if (!fSpring) {
		// false
	} else if ((void*)fSpring == (void*)this) {
		result = true;
	}
#endif
	return result;
}
