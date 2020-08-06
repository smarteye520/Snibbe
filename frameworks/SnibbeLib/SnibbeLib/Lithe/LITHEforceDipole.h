/**
 * Represents a force on a polar mass
 *
 * (c) 2006 Scott Snibbe
 *
 */

#ifndef LITHEFORCEDIPOLE
#define LITHEFORCEDIPOLE

#include "Vector3D.h"
#include "LITHEforce.h"
#include "LITHEmassPolar.h"

class LITHEforceDipole : public LITHEforce {
public:

	LITHEforceDipole(
		LITHEmassPolar *m1, 
		LITHEmassPolar *m2, 
		float influenceLength, 
		float kS = 1.0, 
		float kD = 0.01);

	~LITHEforceDipole();

	Vector calcForce();
	void accumulateAccel();	// Apply forces to acceleration of connected masses

	void influenceLength(float influenceLength) { influenceLength_ = influenceLength; }
	float influenceLength(void) { return influenceLength_; }
	void kS(float ks) { kS_ = ks; }
	float kS() { return kS_; }
	void kD(float kd) { kD_ = kd; }
	float kD() { return kD_; }

	LITHEmassPolar*	mass1() const { return m1_; }
	LITHEmassPolar*	mass2() const { return m2_; }

	void mass1 (LITHEmassPolar *m) { m1_ = m; }
	void mass2 (LITHEmassPolar *m) { m2_ = m; }

	bool equals(LITHEforce *f);

private:

	float		 influenceLength_;
	float		 kS_, kD_;

	LITHEmassPolar	*m1_, *m2_;
};

// Calculate spring force using Hooke's law:
//		F = -Kspring * (length - rest_length) - Kdamp * (velocity in spring direction)

inline Vector
LITHEforceDipole::calcForce()
{
	// XXX finish
	Vector force;

	Vector deltaP = m1_->pos() - m2_->pos();

	float l = deltaP.length();

	float fMag=0;

	// Magnitude of spring force
	/*
	if (l < restLength_) {
		fMag = kS_*(restLength_ - l);
	} else if (l >= restLengthHigh_) {
		fMag = kS_*(restLengthHigh_ - l);
	}
	*/

	// Damping
	if (kD_ != 0.0) {
		Vector deltaV = m1_->vel() - m2_->vel();
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
LITHEforceDipole::accumulateAccel()
{
	// XXX finish
	Vector force = calcForce();

	Vector a1 = m1_->accel();
	Vector a2 = m2_->accel();

	m1_->accel(a1 + force / m1_->mass());
	m2_->accel(a2 - force / m2_->mass());
}


#endif
