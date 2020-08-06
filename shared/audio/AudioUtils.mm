/*
 *  AudioUtils.mm
 *  Shared
 *
 *  Created by Graham McDermott on 2/25/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */

#include "AudioUtils.h"
#include <stdio.h>
#include "fmod_errors.h"


///////////////////////////////////////////////////////////////////////////////
// BPM calculations
///////////////////////////////////////////////////////////////////////////////

float calculateBPM( float loopLength, int beatsPerLoop )
{	
	float bps = beatsPerLoop / loopLength;
	return bps * 60.0f;		
}


///////////////////////////////////////////////////////////////////////////////
// Uint64P
///////////////////////////////////////////////////////////////////////////////

//
//
Uint64P::Uint64P( Uint64 val ) : 
mHi( (unsigned int) (val >> 32)), 
mLo( (unsigned int) (val & 0xFFFFFFFF))
{
}

//
//
Uint64 Uint64P::value() const
{
	return (Uint64(mHi) << 32) + mLo;
}

//
//
void Uint64P::operator+=(const Uint64P &rhs)
{
	FMOD_64BIT_ADD(mHi, mLo, rhs.mHi, rhs.mLo);
}

//
//
void Uint64P::operator-=(const Uint64P &rhs)
{
	FMOD_64BIT_SUB(mHi, mLo, rhs.mHi, rhs.mLo);
}



//
//
void Uint64P::assignNow()
{
	FMOD::System *sys = GetFMODSystem();
	sys->getDSPClock( &mHi, &mLo );
	
}

///////////////////////////////////////////////////////////////////////////////
// FMOD helpers
///////////////////////////////////////////////////////////////////////////////

int fmodSystemSampleRate = 0;
FMOD::System * system_ = 0;

//
//
void ERRCHECK(FMOD_RESULT result)
{
    if (result != FMOD_OK)
    {
        fprintf(stderr, "FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));
    }
}

//
//
void ERRCHECK_CHANNEL(FMOD_RESULT result)
{
    if (result != FMOD_OK && result != FMOD_ERR_INVALID_HANDLE
        && result != FMOD_ERR_CHANNEL_STOLEN)
    {
        fprintf(stderr, "FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));        
    }
}


//
// global setter for fmod system
FMOD::System * GetFMODSystem()
{    
    return system_;
}

//
// global setter for fmod system
void SetFMODSystem( FMOD::System * s)    
{
    system_ = s;
}

//
//
void InitGlobalAudioVals()
{
	GetFMODSystem()->getSoftwareFormat( &fmodSystemSampleRate, NULL, NULL, NULL, NULL, NULL );
}

//
// milliseconds expressed in fmod DSP clock ticks
Uint64P ConvertMsToDSPTicks( unsigned int ms )
{
	
	return Uint64P( fmodSystemSampleRate * ms * .001 );
	
}





