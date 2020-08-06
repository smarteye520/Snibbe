// (c) 1998-2011 Scott Snibbe

#include "LITHEmass.h"

LITHEmass::LITHEmass(
	Vector pos, 
	float mass)
{
	pos_ = pos;
	mass_ = mass;
	elasticity_ = 1.0;
	
	vel_ = accel_ = Vector(0,0,0);

	state_ = State_Mobile;
    userData_ = 0;
}

LITHEmass::~LITHEmass()
{
}
