// (c) 1998-2011 Scott Snibbe

#include "LITHEforceScreenSpring.h"

LITHEforceScreenSpring::LITHEforceScreenSpring(
	LITHEmass *m1,
	float guardLength,
	int screenWidth,
	int screenHeight,
	float kS,
	float kD)
{
	m1_ = m1;
	kS_ = kS;
	kD_ = kD;
	screenWidth_ = screenWidth;
	screenHeight_ = screenHeight;
	guardLength_ = guardLength;
}

LITHEforceScreenSpring::~LITHEforceScreenSpring()
{
}

bool
LITHEforceScreenSpring::equals(LITHEforce *f)
{
	bool result = false;
#ifdef sgi
	if ((void*)f == (void*)this)
	     result = true;
	else
	     result = false;
#else
	LITHEforceScreenSpring *fScreenSpring = dynamic_cast<LITHEforceScreenSpring*> (f);
	if (!fScreenSpring) {
		// false
	} else if ((void*)fScreenSpring == (void*)this) {
		result = true;
	}
#endif
	return result;
}

