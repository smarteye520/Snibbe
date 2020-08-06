/*
 *  ScoopEnvelopeManager.h
 *  Scoop
 *
 *  Created by Graham McDermott on 3/11/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */

#ifndef __SCOOP_ENVELOPE_MANAGER__
#define __SCOOP_ENVELOPE_MANAGER__

#include <vector>

struct EnvPt
{
	EnvPt( float x, float y ) { x_=x; y_=y; } 
	
	float x_; // normalized (0-1) point within the 
	float y_;
};

//
//
class ScoopEnvelope
{
	
public:
	
	ScoopEnvelope( float x1, float y1, float x2, float y2, float x3, float y3 );
	~ScoopEnvelope();

	void getEnvelopeVal( float inVal, float& outVal );

	// our envelopes are simple - max of 3 points
	
	EnvPt pt1; // x is always 0
	EnvPt pt2; // possibly in middle
	EnvPt pt3; // x is always 1
};


//
//
class ScoopEnvelopeManager
{
public:

	static void Init();
	static void Release();
	static ScoopEnvelopeManager *Manager();

	
	ScoopEnvelopeManager();
	~ScoopEnvelopeManager();
	
	void setLoopDuration( float loopDur );         // duration of audio loop
	void setNumEnvCyclesPerLoop( int numCycles );  // set the number of envelope cycles in each complete loop  
	
	void update( float timeWithinInLoop );
	
	
	
	void getEnvelopePoints( int envIndex, float timeBegin, float timeEnd, float& outBegin, float& outEnd );
	int  getEnvelopeIndex( float normalizedVal );
	
	
	
private:

	static ScoopEnvelopeManager *msManager;
	
	
	void init();  // sets up envelope data structures
	
	
	void addEnvelope( float x1, float y1, float x2, float y2, float x3, float y3 );
	
	
	
	std::vector<ScoopEnvelope> envelopes_;
	

	float loopDuration_;    // duration of the entire audio loop
	float cycleDuration_;   // how long it takes to pass through a single envelope completely
	int   cyclesPerLoop_;   // set the number of envelope cycles in each complete loop  

	
	float timeCurEnvBegin_;
	float timeCurEnvEnd_;

	
	// data structure for envelopes
	// num envelopes
	
	// cur envelope
	
	// envelope length
	

	
	
};


#endif __SCOOP_ENVELOPE_MANAGER__