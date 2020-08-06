// (c) 1998-2011 Scott Snibbe

#include "litheforcedipole.h"


LITHEforceDipole::LITHEforceDipole(
                 LITHEmassPolar *m1, 
                 LITHEmassPolar *m2, 
                 float influenceLength, 
                 float kS, 
                 float kD)
{
}

LITHEforceDipole::~LITHEforceDipole(void)
{
}

bool
LITHEforceDipole::equals(LITHEforce *f)
{
	bool result = false;
#ifdef sgi
	if ((void*)f == (void*)this)
        result = true;
	else
        result = false;
#else
	LITHEforceDipole *fDipole = dynamic_cast<LITHEforceDipole*> (f);
	if (!fDipole) {
		// false
	} else if ((void*)fDipole == (void*)this) {
		result = true;
	}
#endif
	return result;
}