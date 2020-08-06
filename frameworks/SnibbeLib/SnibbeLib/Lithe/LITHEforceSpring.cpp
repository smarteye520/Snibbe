// (c) 1998-2011 Scott Snibbe

#include "LITHEforceSpring.h"

LITHEforceSpring::LITHEforceSpring(
	LITHEmass *m1,
	LITHEmass *m2,
	float restLength,
	float kS,
	float kD)
{
	m1_ = m1;
	m2_ = m2;
	restLength_ = restLengthHigh_ = restLength;
	kS_ = kS;
	kD_ = kD;
}

LITHEforceSpring::~LITHEforceSpring()
{
}

bool
LITHEforceSpring::equals(LITHEforce *f)
{
	bool result = false;
#ifdef sgi
	if ((void*)f == (void*)this)
	     result = true;
	else
	     result = false;
#else
	LITHEforceSpring *fSpring = dynamic_cast<LITHEforceSpring*> (f);
	if (!fSpring) {
		// false
	} else if ((void*)fSpring == (void*)this) {
		result = true;
	}
#endif
	return result;
}

void
LITHEforceSpring::setRestLengthToCurrent()
{
	Vector deltaP = m1_->pos() - m2_->pos();

	float l = deltaP.length();

	if (l > 0) {
		restLength_ = restLengthHigh_ = l;
	}
}