/*
 * LITHEobject.h
 * Scott Snibbe
 *
 * (c) 1998-2011 Scott Snibbe
 */

#ifndef LITHEOBJECT
#define LITHEOBJECT

#include "LITHEmass.h"
#include "LITHEforce.h"
#include "LITHEforceSpring.h"
#include "LITHEforceAngleSpring.h"

#include <vector>
using namespace std ;

class LITHEobject {
public:
	LITHEobject(float elastic = 1.0);
	~LITHEobject();

	void addMass(LITHEmass *m);
	void addForce(LITHEforce *f);
	bool addForceNoDup(LITHEforce *f);

	void addPolygon(vector<Vector> *vertices, void *userData=NULL, 
                    bool closed=false, bool angleSprings=true, float Ks=1.0, float Kd=1.0);

	void addTriangulatedPolygon(vector<Vector> *vertices, float Ks=1.0, float Kd=1.0);
    
	void removeForce(LITHEforce *f);
    void removeMass(LITHEmass *m);
    void removeAndDeleteSpringsContaining(LITHEmass *m);

	void clearMasses();
	void clearForces();

	void enableForces(bool enable) { enableF_ = enable; }
	void rungeKutta(float h);
	void euler(float h);

	void viscousDamping(float d) { vDamp_ = d; }
	float viscousDamping() { return vDamp_; }

	// walls, etc.
	void handleCollisions(float left, float top, float right, float bottom);

	LITHEmass* mass(int i);
	LITHEforce* force(int i);
    
    int indexOfMass(LITHEmass *m);

	LITHEmass* nearestMass(
					Vector pt,		// test point
					float *dist);	// output distance

	// Add a mass at this point, if none found within <dist>
	LITHEmass* nearestMassAdd(
					Vector pt,		// test point
					float *dist);	// <> input: min dist, output: actual dist

	// return spring connecting masses, if exists
	LITHEforceSpring* springBetween(LITHEmass *m1, LITHEmass *m2); 
	void springsContaining(LITHEmass *m, LITHEforceSpring **springs, int& nSprings);
    void angleSpringsContaining(LITHEmass *m, LITHEforceAngleSpring **springs, int& nSprings);


	void setAllSpringsRestLengthToCurrent();

	int nMasses() { return masses_->size(); }
	int nForces() { return forces_->size(); }

	void edges(Vector *edgeList);	// return the edges as a list of points
//	void intEdges(POINT *edgeList, int start, int end);	// return the edges as a list of points

	bool offscreen(float left, float top, float right, float bottom);

	void elastic(float e) { elastic_ = e; }
	float elastic() { return elastic_; }

	void addVelocity(Vector v);
	void addAngularVelocity(float v);

	void translate(Vector t);
	void scale(Vector s);

	LITHEobject* copy();
    
    // bad! don't use these unless absolutely necessary
    vector<LITHEmass*>* masses() { return masses_; }
	vector<LITHEforce*>* forces() { return forces_; }

private:
	void accumulateAccel();
	void zeroAccel();

	vector<LITHEmass*> *masses_;
	vector<LITHEforce*> *forces_;

	float elastic_;
	float vDamp_;
	bool enableF_;
};

#endif // LITHEOBJECT
