/*
 * LITHEforceGlobal.h
 * Scott Snibbe
 *
 * (c) 1998-2011 Scott Snibbe
 */

#ifndef LITHEFORCEGLOBAL
#define LITHEFORCEGLOBAL

#include "LITHEmass.h"
#include "LITHEforce.h"

#include <vector>
using namespace std ;

#ifndef RANDOM_0_1
#define RANDOM_0_1() ((random() / (float)0x7fffffff ))
#endif

class LITHEforceGlobal : public LITHEforce {
public:

    typedef enum {
        ForceType_Direction,
        ForceType_Point
    } ForceType;
    
    // for Direction
	LITHEforceGlobal(
        vector<LITHEmass*> *masses,
        Vector gravityVec,             
        float viscosity);

    // for Point
    LITHEforceGlobal(
         vector<LITHEmass*> *masses,
         Vector point_,             // either direction, or position
         float magnitude,
         float viscosity);

	~LITHEforceGlobal();

	void forceVector(Vector f) { gravityVec_ = f; }
    
    void point(Vector p) { pointVec_ = p; }
    
    void magnitude(float m) { magnitude_ = m; }
    float magnitude() { return magnitude_; }
    
    void variance(float v) { variance_ = v; }

	Vector calcForce();
	void accumulateAccel();	// Apply forces to acceleration of masses

	bool equals(LITHEforce *f);

private:

	Vector gravityVec_, pointVec_;
	float viscosity_, magnitude_, variance_;
    ForceType   forceType_;
	vector<LITHEmass*> *masses_;
};

inline Vector
LITHEforceGlobal::calcForce()
{
	Vector force;

	force = gravityVec_;

	return force;
}

inline void
LITHEforceGlobal::accumulateAccel()
{

	LITHEmass *m;
	int nMasses = masses_->size();

    switch (forceType_) {
        case ForceType_Direction:
        {
            Vector force = calcForce();
            for (int i = 0; i < nMasses; i++) {
                m = masses_->at(i);
                m->accel(force - viscosity_ * m->vel());
            }
            
            break;
        }
        case ForceType_Point:
        {
            float halfVariance = variance_ * 0.5;
            
            if (magnitude_ != 0) {
                Vector force;
                for (int i = 0; i < nMasses; i++) {
                    m = masses_->at(i);
                    
                    // apply force towards point
                    force = pointVec_ - m->pos();
                    force.normalize();
                    force *= magnitude_ + (RANDOM_0_1() * variance_ - halfVariance);
                    
                    m->accel(force - viscosity_ * m->vel());
                }
            }
            
            break;
        }            
            break;
    }
    
}

#endif // LITHEFORCEGLOBAL
