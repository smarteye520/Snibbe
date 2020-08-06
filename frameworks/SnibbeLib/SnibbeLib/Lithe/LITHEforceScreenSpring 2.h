/*
 * LITHEforceScreenSpring.h
 * Scott Snibbe
 *
 * (c) 1998 Scott Snibbe
 */

#ifndef LITHEFORCESCREENSPRING
#define LITHEFORCESCREENSPRING

#include "LITHEmass.h"
#include "LITHEforce.h"

class LITHEforceScreenSpring : public LITHEforce {
public:

	LITHEforceScreenSpring(
		LITHEmass *m1, 
		float guardLength, // distance at which to start applying force
		int screenWidth,
		int screenHeight,
		float kS = 1.0, 
		float kD = 0.01);

	~LITHEforceScreenSpring();

	Vector calcForce();
	void accumulateAccel();	// Apply forces to acceleration of connected masses

	void kS(float ks) { kS_ = ks; }
	float kS() { return kS_; }
	void kD(float kd) { kD_ = kd; }
	float kD() { return kD_; }

	LITHEmass*	mass1() const { return m1_; }

	void mass1 (LITHEmass *m) { m1_ = m; }

	bool equals(LITHEforce *f);

private:

	float		 kS_, kD_;
	int screenHeight_, screenWidth_;
	float guardLength_;


	LITHEmass	*m1_;
};

// Calculate spring force using Hooke's law:
//		F = -Kspring * (length - rest_length) - Kdamp * (velocity in spring direction)

inline Vector
LITHEforceScreenSpring::calcForce()
{
	Vector force;

	float mx = m1_->pos().x();
	float my = m1_->pos().y();

	if (mx > guardLength_ && mx < screenWidth_ - guardLength_ &&
		my > guardLength_ && my < screenHeight_ - guardLength_) {
			// inside bounds
			return Vector(0.0, 0.0, 0.0);
	}

	// TODO make vector always point into screen
	Vector rebound(m1_->pos());
	if (mx < guardLength_) {
		rebound.x(-20);
	} else if (mx > screenWidth_ - guardLength_) {
		rebound.x(screenWidth_+20);
	}

	if (my < guardLength_) {
		rebound.y(-20);
	} else if (my > screenHeight_ - guardLength_) {
		rebound.y(screenHeight_+20);
	}

	Vector deltaP = m1_->pos() - rebound;

	float l = deltaP.length();

	float fMag=0;

	// Magnitude of spring force
	fMag = -kS_*(guardLength_ - l);

	// Damping
	if (kD_ != 0.0) {
		Vector deltaV = m1_->vel();
		// Project spring velocity onto spring vector
		float damp = deltaV.dot(deltaP) / l;
		// Reduce force proportional to velocity in spring direction
		fMag -= kD_ * damp;
	}

	fMag /= l;
	force = fMag * deltaP;

	return force;
}

inline void
LITHEforceScreenSpring::accumulateAccel()
{
	Vector force = calcForce();

	Vector a1 = m1_->accel();

	m1_->accel(a1 + force / m1_->mass());
}

#endif
