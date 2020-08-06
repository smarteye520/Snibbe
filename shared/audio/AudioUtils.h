/*
 *  AudioUtils.h
 *  Shared
 *
 *  Created by Graham McDermott on 2/25/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */


#ifndef __AUDIO_UTILS_H__
#define __AUDIO_UTILS_H__

#include "fmod.hpp"

///////////////////////////////////////////////////////////////////////////////
// BPM calculations
///////////////////////////////////////////////////////////////////////////////

extern float calculateBPM( float loopLength, int beatsPerLoop );


///////////////////////////////////////////////////////////////////////////////
// Uint64P - 64-bit int class for use with FMOD
///////////////////////////////////////////////////////////////////////////////

typedef unsigned long long Uint64;

class Uint64P
{
public:
	
    Uint64P(Uint64 val = 0);
    
	Uint64 value() const;
    void operator+=(const Uint64P &rhs);
    void operator-=(const Uint64P &rhs);
	
	void assignNow();
    void clear() { mHi = mLo = 0; }
	
    unsigned int mHi;
    unsigned int mLo;
};


///////////////////////////////////////////////////////////////////////////////
// FMOD helpers
///////////////////////////////////////////////////////////////////////////////


// FMOD error checking helper functions

extern void ERRCHECK(FMOD_RESULT result);
extern void ERRCHECK_CHANNEL(FMOD_RESULT result);



extern FMOD::System * GetFMODSystem();          // global getter for fmod system
extern void SetFMODSystem( FMOD::System * s);    // global setter for fmod system

extern void InitGlobalAudioVals();

extern Uint64P ConvertMsToDSPTicks( unsigned int ms );


extern int fmodSystemSampleRate;



#endif // __AUDIO_UTILS_H__