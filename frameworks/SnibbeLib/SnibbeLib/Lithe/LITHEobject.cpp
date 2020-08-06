// (c) 1998-2011 Scott Snibbe

#include <math.h>

#include "LITHEmass.h"
#include "LITHEforceSpring.h"
#include "LITHEforceAngleSpring.h"
#include "LITHEobject.h"
#include "Vector3D.h"

#define ROUNDINT( d ) ((int)((d) + ((d) > 0 ? 0.5 : -0.5)))

LITHEobject::LITHEobject(float elastic) :
	elastic_(elastic),
	vDamp_(1.0),
	enableF_(true)
{
	masses_ = new vector<LITHEmass*>;
	forces_ = new vector<LITHEforce*>;
	forces_->reserve(1024);
}

LITHEobject::~LITHEobject()
{
	clearMasses();
	clearForces();

	delete masses_;
	delete forces_;
}

void
LITHEobject::clearMasses()
{
	LITHEmass *m;

	while (!masses_->empty()) {
		m = (LITHEmass *) masses_->back();
		masses_->pop_back();

		delete m;
	}
}

void
LITHEobject::clearForces()
{
	LITHEforce *f;

	while (!forces_->empty()) {
		f = (LITHEforce *) forces_->back();
		forces_->pop_back();

		delete f;
	}
}

void
LITHEobject::addMass(
	LITHEmass *m)
{
	masses_->push_back(m);
}

void
LITHEobject::removeMass(LITHEmass *m)
{
	vector<LITHEmass*>::iterator mIt;
	for (mIt = masses_->begin(); mIt < masses_->end(); mIt++) {
		if (*mIt == m) {
            removeAndDeleteSpringsContaining(m); // remove springs connected to this mass, otherwise bad pointers
			masses_->erase(mIt);
			break;
		}
	}
}

void
LITHEobject::removeAndDeleteSpringsContaining(LITHEmass *m)
{
    LITHEforceSpring *springs[16];      // $$$$ hard-coded number - assumes no more than 16 springs on a mass!
    LITHEforceAngleSpring *aSprings[16];
    
    int nSprings;
    
    // remove springs
    springsContaining(m, springs, nSprings);
    
    for (int j=0; j< nSprings; j++) {
        // take this spring off of the LITHEobject
        removeForce(springs[j]);
        // delete this spring
        delete springs[j];
    }
    
    // remove angle springs
    angleSpringsContaining(m, aSprings, nSprings);
    
    for (int j=0; j< nSprings; j++) {
        // take this spring off of the LITHEobject
        removeForce(aSprings[j]);
        // delete this spring
        delete aSprings[j];
    }
}

void
LITHEobject::addForce(
	LITHEforce *f)
{
	forces_->push_back(f);
}

void
LITHEobject::removeForce(
	LITHEforce *f)
{
	vector<LITHEforce*>::iterator fIt;
	for (fIt = forces_->begin(); fIt < forces_->end(); fIt++) {
		if (*fIt == f) {
			forces_->erase(fIt);
			break;
		}
	}
}


// Returns true if added
bool
LITHEobject::addForceNoDup(
	LITHEforce *f)
{
	int nForces = forces_->size();
	int i;
	bool found = false;

	LITHEforce  *force;

	for (i = 0; i < nForces; i++) {
		force = forces_->at(i);
		if (force->equals(f)) {
			found = true;
			break;
		}
	}

	if (!found) forces_->push_back(f);

	return !found;
}

void
LITHEobject::addPolygon(
	vector<Vector> *vertices,
    void *userData,
	bool closed,
    bool angleSprings,
	float Ks,
	float Kd)
{
	int i, nVerts = vertices->size(), startMass=nMasses();
	Vector v;
	LITHEmass *m, *m1, *m2, *m3;
	LITHEforceSpring *spring;

	for (i = 0; i < nVerts; i++) {
		v = vertices->at(i);

		if (i > 0) m1 = m;
		m = new LITHEmass(v);
        m->userData(userData);
		addMass(m);
		if (i > 0) {
			spring = new LITHEforceSpring(m1, m,
							(m1->pos() - m->pos()).length(), Ks, Kd);
			addForce(spring);
		}
	}
	if (closed) {	// Add spring from last to first point
		m1 = mass(0);
		spring = new LITHEforceSpring(m, m1,
						(m->pos() - m1->pos()).length(), Ks, Kd);
		addForce(spring);
	}

    
    if (angleSprings) {
        Vector v1, v2;
        float restAngle;
        
        LITHEforceAngleSpring *hinge;
        for (i = 0; i < nVerts-2; i++) {
            m1 = mass(startMass+i);
            m2 = mass(startMass+i+1);
            m3 = mass(startMass+i+2);
            
            v1 = Vector(m1->pos() - m2->pos());
            v2 = Vector(m3->pos() - m2->pos());
            
            v1.normalize();
            v2.normalize();
            restAngle = v1.angle(v2);
            
            if (restAngle > M_PI) restAngle = 2*M_PI - restAngle;
            if (restAngle != 0.0) {
                hinge = new LITHEforceAngleSpring(m1, m2, m3, restAngle, Ks, Kd);
                addForce(hinge);
            }
        }
        
        if (closed) {
            m1 = mass(startMass+nVerts-2);
            m2 = mass(startMass+nVerts-1);
            m3 = mass(0);
            
            v1 = Vector(m1->pos() - m2->pos());
            v2 = Vector(m3->pos() - m2->pos());
            
            restAngle = v1.angle(v2);
            
            if (restAngle != 0.0) {
                hinge = new LITHEforceAngleSpring(m1, m2, m3, restAngle, Ks, Kd);
                addForce(hinge);
            }
        }
        
    }
}

void
LITHEobject::addTriangulatedPolygon(
									vector<Vector> *vertices,
									float Ks,
									float Kd)
{
	int i, j, nVerts = vertices->size();
	Vector v;
	LITHEmass *m[3];
	LITHEforceSpring *spring;

	float epsilon = 0.000001, dist;

	for (i = 0; i < nVerts; i+=3) {
		// add or locate masses of triangle vertices
		for (j = 0; j < 3; j++) {
			v = vertices->at(i+j);
			dist = epsilon;
			m[j] = nearestMassAdd(v, &dist);
		}
		// add three springs of triangle
		for (j = 0; j < 3; j++) {
			spring = new LITHEforceSpring(m[j], m[(j+1)%3], (m[j]->pos() - m[(j+1)%3]->pos()).length(), Ks, Kd);
			addForce(spring);
		}
	}
}

int 
LITHEobject::indexOfMass(LITHEmass *m)
{
    int massI = -1;
    
    
    int nMasses = masses_->size();
    
	for (int i = 0; i < nMasses; i++) {
		LITHEmass *thisM = masses_->at(i);
        
		if (m == thisM) {
            massI = i;
            break;
        }
	}
    
    return massI;
}

LITHEmass*
LITHEobject::nearestMass(
	Vector pt,		// test point
	float *dist)	// output distance
{
	LITHEmass *m, *nearestMass;
	float distSq, minDistSq;
	Vector delta;
	int nMasses = masses_->size();
	int i;

	if (nMasses == 0) {
		return NULL;
	}

	nearestMass = m = masses_->at(0);
	delta = m->pos() - pt;
	minDistSq = delta.dot(delta);

	for (i = 1; i < nMasses; i++) {
		m = masses_->at(i);

		delta = m->pos() - pt;
		distSq = delta.dot(delta);

		if (distSq < minDistSq) {
			nearestMass = m;
			minDistSq = distSq;
		}
	}
	*dist = sqrt(minDistSq);
	return nearestMass;
}

// Add a mass at this point, if none found within <dist>
LITHEmass*
LITHEobject::nearestMassAdd(
	Vector pt,		// test point
	float *dist) 	// <> input: min dist, output: actual dist
{
	float mDist;
	LITHEmass *m = nearestMass(pt, &mDist);

	if (m && mDist <= *dist) {
		*dist = mDist;
	} else {
		m = new LITHEmass(pt);
		addMass(m);
	}

	return m;
}

void
LITHEobject::setAllSpringsRestLengthToCurrent()
{
	LITHEforceSpring *sForce;

	int nForces = forces_->size();
	int i;

	LITHEforce  *force;

	for (i = 0; i < nForces; i++) {
		force = forces_->at(i);

		sForce = dynamic_cast <LITHEforceSpring*> (force);

		if (sForce) {
			sForce->setRestLengthToCurrent();
		}
	}
}

// iterate through springs and look for one connecting these two masses
LITHEforceSpring* 
LITHEobject::springBetween(LITHEmass *m1, LITHEmass *m2)
{
	LITHEforceSpring *sForce, *retForce = 0;

	int nForces = forces_->size();
	int i;

	LITHEforce  *force;

	for (i = 0; i < nForces; i++) {
		force = forces_->at(i);

		sForce = dynamic_cast <LITHEforceSpring*> (force);

		if (sForce) {
			if ((m1 == sForce->mass1() && m2 == sForce->mass2()) ||
				(m1 == sForce->mass2() && m2 == sForce->mass1())) {
				retForce = sForce;
				break;
			}
		}
	}
	return retForce;
}

void
LITHEobject::springsContaining(LITHEmass *m, LITHEforceSpring **springs, int& nSprings)
{
	LITHEforceSpring *sForce;//, *retForce = 0;

	int nForces = forces_->size();
	int i;

	LITHEforce  *force;

	nSprings = 0;
	for (i = 0; i < nForces; i++) {
		force = forces_->at(i);

		sForce = dynamic_cast <LITHEforceSpring*> (force);

		if (sForce) {
			if (m == sForce->mass1() || m == sForce->mass2()) {
				springs[nSprings++] = sForce;
			}
		}
	}
}

void
LITHEobject::angleSpringsContaining(LITHEmass *m, LITHEforceAngleSpring **springs, int& nSprings)
{
	LITHEforceAngleSpring *sForce;//, *retForce = 0;
    
	int nForces = forces_->size();
	int i;
    
	LITHEforce  *force;
    
	nSprings = 0;
	for (i = 0; i < nForces; i++) {
		force = forces_->at(i);
        
		sForce = dynamic_cast <LITHEforceAngleSpring*> (force);
        
		if (sForce) {
			if (m == sForce->mass1() || m == sForce->mass2()) {
				springs[nSprings++] = sForce;
			}
		}
	}
}

LITHEmass*
LITHEobject::mass(int i)
{
	int nMasses = masses_->size();
	if (i >= nMasses) return NULL;

	return (LITHEmass*) masses_->at(i);
}

LITHEforce*
LITHEobject::force(int i)
{
	int nForces = forces_->size();
	if (i >= nForces) return NULL;

	return (LITHEforce*) forces_->at(i);
}

void
LITHEobject::edges(Vector *edgeList)	// return the edges as a list of points
{
	LITHEforceSpring *sForce;

	int nForces = forces_->size();
	int i;

	LITHEforce  *force;
	Vector		*v = edgeList;

	for (i = 0; i < nForces; i++) {
		force = forces_->at(i);

#ifdef sgi
#else
		sForce = dynamic_cast <LITHEforceSpring*> (force);
#endif
		if (sForce) {
			*v++ = sForce->mass1()->pos();
			*v++ = sForce->mass2()->pos();
		}

	}

}

#if 0
void
LITHEobject::intEdges(POINT *edgeList, int start, int end)	// return the edges as a list of points
{
	LITHEforceSpring *sForce;

	int nForces = forces_->size();
	int i;

	LITHEforce  *force;
	Vector		fPos;
	POINT		*v = edgeList;
	POINT		p;

	for (i = start; i < end; i++) {
		force = forces_->at(i);

#ifdef sgi
#else
		sForce = dynamic_cast <LITHEforceSpring*> (force);
#endif
		if (sForce) {
			fPos = sForce->mass1()->pos();
			p.x = ROUNDINT(fPos.x());
			p.y = ROUNDINT(fPos.y());
			*v++ = p;
			
			fPos = sForce->mass2()->pos();
			p.x = ROUNDINT(fPos.x());
			p.y = ROUNDINT(fPos.y());
			*v++ = p;
			
		}

	}

}
#endif

void
LITHEobject::zeroAccel()
{
	LITHEmass *m;
	int nMasses = masses_->size();
	int i;

	// zero out acceleration
	Vector zeroV = Vector(0,0,0);
	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);
		m->accel(zeroV);
	}
}

void
LITHEobject::accumulateAccel()
{
	int nForces = forces_->size();
	int i;

	if (!enableF_) return;

	LITHEforce  *force;
	Vector		f;

	for (i = 0; i < nForces; i++) {
		force = forces_->at(i);

		// calculate and apply force to related masses, alters the acceleration of each mass
		force->accumulateAccel();
	}
}

void
LITHEobject::rungeKutta(
	float h)	// time step
{
	int nMasses = masses_->size();
	int i;

	LITHEmass *m;

	zeroAccel();

	accumulateAccel();

	// k1 step
	// k1 = h * f(t_i, X_i)
	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);

		m->curPos_ = m->pos_;
		m->curVel_ = m->vel_;

		m->k1Pos_ = m->vel_ * h;
		m->k1Vel_ = m->accel_ * h;

		m->pos_ = m->curPos_ + m->k1Pos_ / 2;
		m->vel_ = m->curVel_ + m->k1Vel_ / 2;
	}

	accumulateAccel();

	// k2 step
	// k2 = h * f(t_i + h/2, X_i + k1/2)
	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);

		m->k2Pos_ = m->vel_ * h;
		m->k2Vel_ = m->accel_ * h;

		m->pos_ = m->curPos_ + m->k2Pos_ / 2;
		m->vel_ = m->curVel_ + m->k2Vel_ / 2;
	}

	accumulateAccel();

	// k3 step
	// k3 = h * f(t_i + h/2, X_i + k2/2)
	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);

		m->k3Pos_ = m->vel_ * h;
		m->k3Vel_ = m->accel_ * h;

		m->pos_ = m->curPos_ + m->k3Pos_;
		m->vel_ = m->curVel_ + m->k3Vel_;
	}

	accumulateAccel();

	// k4 step
	// k4 = h * f(t_h, X_i + k3)
	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);

		m->k4Pos_ = m->vel_ * h;
		m->k4Vel_ = m->accel_ * h;
	}

	// Compute next position
	// X_i+1 = X_i + h/6 (k1 + 2*k2 + 2*k3 + k4)
	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);
	/*
		m->pos_ = m->curPos_ +
			(m->k1Pos_ + 2 * m->k2Pos_ + 2 * m->k3Pos_ + m->k4Pos_) / 6;
		m->vel_ = m->curVel_ +
			(m->k1Vel_ + 2 * m->k2Vel_ + 2 * m->k3Vel_ + m->k4Vel_) / 6;
			*/
		m->pos_ = m->curPos_ +
			(m->k1Pos_/2 + m->k2Pos_ + m->k3Pos_ + m->k4Pos_/2) / 3;
		m->vel_ = m->curVel_ +
			(m->k1Vel_/2 + m->k2Vel_ + m->k3Vel_ + m->k4Vel_/2) / 3;
	}
}

void
LITHEobject::euler(
	float h)	// time step
{
	int nMasses = masses_->size();
	int i;

	LITHEmass *m;

	accumulateAccel();

	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);

        if (m->state_ == LITHEmass::State_Mobile) {
            m->vel_ = vDamp_ * m->vel_ + h * m->accel_;
            m->pos_ = m->pos_ + h * m->vel_;
        }
	}
	zeroAccel();
}

void
LITHEobject::translate(
	Vector t)
{
	int nMasses = masses_->size();
	int i;

	LITHEmass *m;

	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);

		m->pos_ = m->pos_ + t;
	}

}

void
LITHEobject::scale(
	Vector s)
{
	int nMasses = masses_->size();
	int i;

	LITHEmass *m;

	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);

		m->pos_ = m->pos_ * s;
	}
}


void
LITHEobject::addVelocity(Vector v)
{
	int nMasses = masses_->size();
	int i;

	LITHEmass *m;

	// Compute center of mass
	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);
		m->vel(m->vel() + v);
	}
}

void
LITHEobject::addAngularVelocity(float v)
{
	int nMasses = masses_->size();
	int i;

	Vector com(0,0,0);
	LITHEmass *m;

	// Compute center of mass
	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);
		com +=	m->pos_;
	}
	com /= (float) nMasses;

	Vector vel, delta;
	// impart angular velocity
	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);
		delta = m->pos() - com;
		delta = Vector(-delta.y(), delta.x(), 0);
		delta *= v;
		m->vel(m->vel() + delta);
	}
}

bool
LITHEobject::offscreen(float left, float top, float right, float bottom)
{
	int nMasses = masses_->size();
	int i;

	LITHEmass *m;

	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);

		if (m->pos_.x() >= left && m->pos_.y() >= top &&
			m->pos_.x() < right && m->pos_.y() < bottom)
			return false;
	}
	return true;
}

void
LITHEobject::handleCollisions(float left, float top, float right, float bottom)
{
	int nMasses = masses_->size();
	int i;

	LITHEmass *m;

	for (i = 0; i < nMasses; i++) {
		m = masses_->at(i);

		if (m->pos_.y() <= bottom && m->vel_.y() < 0) {
			m->vel_ = Vector(m->vel_.x(), -elastic_ * m->vel_.y(), m->vel_.z());
			m->pos_[1] = bottom;
		}
	}
}

LITHEobject*
LITHEobject::copy()
{
	return NULL;
}
