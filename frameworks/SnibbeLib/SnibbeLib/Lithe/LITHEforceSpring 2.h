  /*
 * LITHEforceSpring.h
 * Scott Snibbe
 *
 * (c) 1998 Scott Snibbe
 */

#ifndef LITHEFORCESPRING
#define LITHEFORCESPRING

#include "LITHEmass.h"
#include "LITHEforce.h"
#include <assert.h>

class LITHEforceSpring : public LITHEforce {
public:

	LITHEforceSpring(
		LITHEmass *m1, 
		LITHEmass *m2, 
		float restLength, 
		float kS = 1.0, 
		float kD = 0.01);

	~LITHEforceSpring();

	Vector calcForce();
	void accumulateAccel();	// Apply forces to acceleration of connected masses

	void restLength(float r) { if (r >= 0) restLength_ = r; restLengthHigh_ = r; }
	float restLength() { return restLength_; }

	void breakLength(float r) { if (r >= 0) breakLength_ = r;}
	float breakLength() { return breakLength_; }

	void restLengths(float low, float high) { restLength_ = low; restLengthHigh_ = high; }

	void setRestLengthToCurrent();

	void kS(float ks) { kS_ = ks; }
	float kS() { return kS_; }
	void kD(float kd) { kD_ = kd; }
	float kD() { return kD_; }

	LITHEmass*	mass1() const { return m1_; }
	LITHEmass*	mass2() const { return m2_; }

	void mass1 (LITHEmass *m) { m1_ = m; }
	void mass2 (LITHEmass *m) { m2_ = m; }

	bool equals(LITHEforce *f);

private:

	float		 restLength_, restLengthHigh_, breakLength_;
	float		 kS_, kD_;

	LITHEmass	*m1_, *m2_;
};

// Calculate spring force using Hooke's law:
//		F = -Kspring * (length - rest_length) - Kdamp * (velocity in spring direction)

inline Vector
LITHEforceSpring::calcForce()
{
	Vector force;
    
    assert(m1_ && m2_);

	Vector deltaP = m1_->pos() - m2_->pos();

	float l = deltaP.length();

	float fMag=0;

	// Magnitude of spring force
	if (l < restLength_) {
		fMag = kS_*(restLength_ - l);
	} else if (l >= restLengthHigh_) {
		fMag = kS_*(restLengthHigh_ - l);
	}

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
LITHEforceSpring::accumulateAccel()
{
	Vector force = calcForce();

	Vector a1 = m1_->accel();
	Vector a2 = m2_->accel();

	m1_->accel(a1 + force / m1_->mass());
	m2_->accel(a2 - force / m2_->mass());
}

#endif // LITHEFORCESPRING
