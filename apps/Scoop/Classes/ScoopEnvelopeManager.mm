/*
 *  ScoopEnvelopeManager.mm
 *  Scoop
 *
 *  Created by Graham McDermott on 3/11/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */

#include "ScoopEnvelopeManager.h"

///////////////////////////////////////////////////////////////////////////////
// class ScoopEnvelope
///////////////////////////////////////////////////////////////////////////////

//
//
ScoopEnvelope::ScoopEnvelope( float x1, float y1, float x2, float y2, float x3, float y3 ) :
	pt1( x1, y1 ),
	pt2( x2, y2 ),
	pt3( x3, y3 )
{
}

//
//
ScoopEnvelope::~ScoopEnvelope()
{
	
}

//
//
void ScoopEnvelope::getEnvelopeVal( float inVal, float& outVal )
{
	// is the value between pt1 and pt2 or pt2 and pt3?
	
	assert (inVal >= 0.0f && inVal <= 1.0f );
	
	float totalRange = 0.0f;
	float percent = 0.0f;
	
	if ( inVal <= pt2.x_ )
	{
		// between 1 and 2		
		float xDelta = inVal - pt1.x_;
		totalRange = pt2.x_ - pt1.x_;
		if ( totalRange == 0 )
		{
			outVal = pt1.y_;
			return;
		}
		else 
		{
			percent = (xDelta / totalRange );
			outVal = percent * (pt2.y_ - pt1.y_) + pt1.y_;
		}
		 
		
	}
	else
	{
		// between 2 and 3
		float xDelta = inVal - pt2.x_;		
		totalRange = pt3.x_ - pt2.x_;
		
		if ( totalRange == 0 )
		{
			outVal = pt2.y_;
		}		
		else
		{
			percent = (xDelta / totalRange );
			outVal = percent * (pt3.y_ - pt2.y_) + pt2.y_;
		}
			
						
	}
}


///////////////////////////////////////////////////////////////////////////////
// class ScoopEnvelopeManager
///////////////////////////////////////////////////////////////////////////////


ScoopEnvelopeManager *ScoopEnvelopeManager::msManager = nil;

//
// static 
void ScoopEnvelopeManager::Init()
{
	if ( !msManager )
	{
		msManager = new ScoopEnvelopeManager();	
		msManager->init();
	}
}

//
// static
void ScoopEnvelopeManager::Release()
{
	if ( msManager )
	{
		delete msManager;
		msManager = nil;
	}
}

//
// static
ScoopEnvelopeManager *ScoopEnvelopeManager::Manager()
{
	return msManager;
}


//
//
ScoopEnvelopeManager::ScoopEnvelopeManager()
{
	cyclesPerLoop_ = -1;
}

//
//
ScoopEnvelopeManager::~ScoopEnvelopeManager()
{
}


// duration of audio loop
// setNumEnvCyclesPerLoop should have been called before this method
void ScoopEnvelopeManager::setLoopDuration( float loopDur )
{
	assert( cyclesPerLoop_ > 0 );  
	
	loopDuration_ = loopDur;	
	cycleDuration_ = loopDur / cyclesPerLoop_;
	
}

//
// the number of envelope cycles in each complete loop  
void ScoopEnvelopeManager::setNumEnvCyclesPerLoop( int numCycles )
{
	assert ( numCycles >= 1 );
	cyclesPerLoop_ = numCycles;
}


//
//
void ScoopEnvelopeManager::getEnvelopePoints( int envIndex, float timeBegin, float timeEnd, float& outBegin, float& outEnd )
{
	
	int numEnv = envelopes_.size();

	if ( envIndex < 0 || envIndex >= numEnv )
	{
		outBegin = 0.0f;
		outEnd = 0.0f;
	}
	else 
	{
	
		ScoopEnvelope env = envelopes_[envIndex];
		
		
		// what time offsets within the envelope are we dealing with?
		// this will cross over the wraparound point but the size is so small the tiny error won't matter
		float envTimeBegin = fmodf( timeBegin, cycleDuration_ );
		float envTimeEnd = fmodf( timeEnd, cycleDuration_ );		
		
		float normBegin = envTimeBegin / cycleDuration_;
		float normEnd = envTimeEnd / cycleDuration_;		
	
		env.getEnvelopeVal( normBegin, outBegin );
		env.getEnvelopeVal( normEnd, outEnd );

		
	}
	

	
}


// which envelope "bucket" does the value correspond to?  
// normalizedVal should be (0-1)
int ScoopEnvelopeManager::getEnvelopeIndex( float normalizedVal )
{

	assert( normalizedVal >= 0.0f && normalizedVal <= 1.0f );
	
	int numEnv = envelopes_.size();
	
	int iEnv = numEnv * normalizedVal;
	if ( numEnv == iEnv )
	{
		iEnv--;
	}
	
	return iEnv;
	
}


//
//
void ScoopEnvelopeManager::init()
{
	// add all envelopes we're using	
	// based on the visual diagrams by Lukas Girling
	
	addEnvelope( 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f );
	addEnvelope( 0.0f, 0.25f, 0.25f, 0.0f, 0.0f, 0.0f );
	addEnvelope( 0.0f, 0.5f, 0.5f, 0.0f, 0.0f, 0.0f );
	addEnvelope( 0.0f, 0.75f, 0.75f, 0.0f, 0.0f, 0.0f );
	addEnvelope( 0.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f );
	addEnvelope( 0.0f, 0.85f, 1.0f, 0.15f, 1.0f, 0.15f );
	addEnvelope( 0.0f, 0.75f, 1.0f, 0.25f, 1.0f, 0.25f );
	addEnvelope( 0.0f, 0.63f, 1.0f, 0.37f, 1.0f, 0.37f );
	addEnvelope( 0.0f, 0.5f, 1.0f, 0.5f, 1.0f, 0.5f );
	addEnvelope( 0.0f, 0.37f, 1.0f, 0.63f, 1.0f, 0.63f );
	addEnvelope( 0.0f, 0.25f, 1.0f, 0.75f, 1.0f, 0.75f );
	addEnvelope( 0.0f, 0.15f, 1.0f, 0.85f, 1.0f, 0.85f );
	addEnvelope( 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f );
	addEnvelope( 0.0f, 0.25f, 0.75f, 1.0f, 1.0f, 1.0f );
	addEnvelope( 0.0f, 0.5f, 0.5f, 1.0f, 1.0f, 1.0f );
	addEnvelope( 0.0f, 0.75f, 0.25f, 1.0f, 1.0f, 1.0f );
	addEnvelope( 0.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f );
}



// envelopes are added in order - earliest corresponding to 0 index
// and latest corresponding to size-1 index
void ScoopEnvelopeManager::addEnvelope( float x1, float y1, float x2, float y2, float x3, float y3 )
{
	envelopes_.push_back( ScoopEnvelope( x1, y1, x2, y2, x3, y3 ) );
	
}