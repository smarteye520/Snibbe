/*
 * LITHEforceAngleSpring.h
 * Scott Snibbe
 *
 * (c) 1998-2011 Scott Snibbe
 */

#ifndef LITHEFORCEANGLESPRING
#define LITHEFORCEANGLESPRING

#include "LITHEmass.h"
#include "LITHEforce.h"
#include <assert.h>

#ifndef M_PI
#define M_PI 3.141592654
#endif

class LITHEforceAngleSpring : public LITHEforce {
public:

	LITHEforceAngleSpring(
		LITHEmass *m1, 
		LITHEmass *m2, 
		LITHEmass*m3, 
		float restAngle,
		float kS = 1.0, 
		float kD = 0.01);

	~LITHEforceAngleSpring();

	void calcForce(Vector& f1, Vector& f2);
	void accumulateAccel();	// Apply forces to acceleration of connected masses

	void restAngle(float r) { if (r >= 0) restAngle_ = r; }
	float restAngle() { return restAngle_; }

	void kS(float ks) { kS_ = ks; }
	float kS() { return kS_; }
	void kD(float kd) { kD_ = kd; }
	float kD() { return kD_; }

	LITHEmass*	mass1() const { return m1_; }
	LITHEmass*	mass2() const { return m2_; }
	LITHEmass*	mass3() const { return m3_; }

	bool equals(LITHEforce *f);

private:

	float		 restAngle_;
	float		 kS_, kD_;

	LITHEmass	*m1_, *m2_, *m3_;

};

// Calculate spring force using Hooke's law:
//		F = -Kspring * (length - rest_length) - Kdamp * (velocity in spring direction)

inline void
LITHEforceAngleSpring::calcForce(Vector& f1, Vector& f2)
{
	Vector force;

	Vector v1(m1_->pos() - m2_->pos());
	Vector v2(m3_->pos() - m2_->pos());

	v1.normalize();
	v2.normalize();

	// 0 to 2pi
	float angle = v1.angle(v2);
//    assert(angle != angle); // tests for NaN

	// Magnitude of spring force
	float fMag = kS_*(angle - restAngle_);

	// force is perpendicular to hinge
	f1 = Vector(-v1.y(), v1.x(), 0);
	f2 = Vector(v2.y(), -v2.x(), 0);

	// Damping
	if (kD_ != 0.0) {
		// Project mass velocity onto force vectors
		float damp1 = m1_->vel().dot(f1);
		float damp2 = m3_->vel().dot(f2);
		
		// Reduce force proportional to velocity in direction of the force
		f1 *= fMag - kD_ * damp1;
		f2 *= fMag - kD_ * damp2;
	} else {
		f1 *= fMag;
		f2 *= fMag;
	}
}

inline void
LITHEforceAngleSpring::accumulateAccel()
{
	Vector f1, f2;

	calcForce(f1, f2);

	Vector a1 = m1_->accel();
	Vector a2 = m3_->accel();

	m1_->accel(a1 + f1 / m1_->mass());
	m3_->accel(a2 + f2 / m3_->mass());
}

#endif // LITHEFORCEANGLESPRING
