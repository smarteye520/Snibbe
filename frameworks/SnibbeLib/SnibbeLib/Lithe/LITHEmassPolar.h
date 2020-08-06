/**
 * Represents a polar mass (e.g. a water molecule)
 *
 * (c) 2006 Sona Research
 *
 * Creation Date:  2006-07-18
 * Initial Author: Michael Ang <michael@snibbe.com>
 */

#ifndef LITHEMASSPOLAR
#define LITHEMASSPOLAR

#include "LITHEmass.h"

class LITHEmassPolar: public LITHEmass
{
public:
	/// Create using the given masses and separation (equal charge is assumed)
	LITHEmassPolar(Vector pos, float negMass, float posMass, float separationDistance);
	~LITHEmassPolar(void);

	/// Get the current rotation in radians
	float radians(void) { return radians_; }
	void radians(float radians) { radians_ = radians; }
	
	/// Current angular momentum
	float angularMomentum(void) { return angularMomentum_; }
	void angularMomentum(float angularMomentum) { angularMomentum_ = angularMomentum; }

private:
	float negMass_, posMass_, separation_, radians_, angularMomentum_;
};

#endif
