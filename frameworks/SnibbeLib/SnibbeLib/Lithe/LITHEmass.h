/*
 * LITHEmass.h
 * Scott Snibbe
 *
 * (c) 1998-2011 Scott Snibbe
 */

#ifndef LITHEMASS
#define LITHEMASS

#include "Vector3D.h"

class LITHEmass {
public:
friend class LITHEobject;

	LITHEmass(Vector pos, float mass = 1.0);
	~LITHEmass();

	typedef enum State {
		State_Fixed,
		State_Mobile
	} State;

	float mass()		  const { return mass_; }
	void   mass(const float m) { mass_ = m; }

	float elasticity()		    const { return elasticity_; }
	void   elasticity(const float e) { elasticity_ = e; }

	Vector pos()		 const { return pos_; }
	void   pos(const Vector p) { pos_ = p; }

	Vector vel()		 const { return vel_; }
	void   vel(const Vector v) { vel_ = v; }

	Vector accel()		const    { return accel_; }
	void   accel(const Vector a) { accel_ = a; }

	void	userData(void *data) { userData_ = data; }
	void*	userData() { return userData_; }
    
    void    state(State s)  {state_ = s;}
    State   state() { return state_; }

private:
	Vector pos_;
	Vector vel_;
	Vector accel_;

	float mass_;
	float elasticity_;

	// Temporary variables for Runge-Kutte
	Vector	curPos_, curVel_;
	Vector	oldPos_, oldVel_;
	Vector	k1Pos_, k1Vel_, k2Pos_, k2Vel_, k3Pos_, k3Vel_, k4Pos_, k4Vel_;

	State state_;

	void *userData_;
	// $$$$ do we want links back to all forces?
};

#endif // LITHEMASS
