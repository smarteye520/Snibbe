// (c) 1998-2011 Scott Snibbe

#include "lithemasspolar.h"

LITHEmassPolar::LITHEmassPolar(Vector pos, float negMass, float posMass, float separationDistance) :
	LITHEmass(pos, negMass+posMass), negMass_(negMass), posMass_(posMass), separation_(separationDistance)
{
	radians_ = 0.0;
	angularMomentum_ = 0.0;
}
