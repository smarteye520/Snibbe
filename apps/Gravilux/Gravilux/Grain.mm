/* Grain.cpp
 * Scott Snibbe
 *
 * (c) 1998-2010
 */

#include "Grain.h"

Grain::Grain(
	CGPoint p, 
	float mass, 
	float damp,
	float hs)
{
	pos_ = p;
	vel_.x = vel_.y = 0;
	acc_.x = acc_.y = 0;
	vel_.x = vel_.y = 0;

	mass_ = mass;
	massInv_ = 1.0 / mass;
	damp_ = damp;
	heatScale_ = hs;
	radius_ = 0.5;
	size_ = 1;

	showHeat_ = showColor_ = false;
}

void	
Grain::simulate(float dt)
{
	lastPos_.x = pos_.x;
	lastPos_.y = pos_.y;
	
	vel_.x = vel_.x*damp_ + acc_.x*dt;
	vel_.y = vel_.y*damp_ + acc_.y*dt;
	pos_.x = pos_.x + vel_.x*dt;
	pos_.y = pos_.y + vel_.y*dt;
}

void	
Grain::clearForce()
{
	acc_.x = acc_.y = 0;
}

