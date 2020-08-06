/*
 *  SnibbeAudioUtils.h
 *  Shared
 *
 *  Created by Graham McDermott on 2/25/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */


#ifndef __AUDIO_UTILS_H__
#define __AUDIO_UTILS_H__


#include "fmod.h"
#include "fmod.hpp"
#include <string>
#include "Uint64P.h"


///////////////////////////////////////////////////////////////////////////////
// BPM calculations
///////////////////////////////////////////////////////////////////////////////

extern "C" float calculateBPM( float loopLength, int beatsPerLoop );




///////////////////////////////////////////////////////////////////////////////
// FMOD helpers
///////////////////////////////////////////////////////////////////////////////


// FMOD error checking helper functions

extern "C" void ERRCHECK(FMOD_RESULT result);
extern "C" void ERRCHECK_CHANNEL(FMOD_RESULT result);



extern "C" FMOD::System * GetFMODSystem();          // global getter for fmod system
extern void SetFMODSystem( FMOD::System * s);    // global setter for fmod system

extern "C" void InitGlobalAudioVals();
extern "C" Uint64P ConvertSecToDSPTicks( double s );
extern "C" Uint64P ConvertMsToDSPTicks( unsigned int ms );
extern "C" unsigned int ConvertDSPTicksToMs( Uint64P ticks );

extern "C" float BpmToMSPerBeat( float bpm );
extern "C" float MsPerBeatToBpm( float msPerBeat );

extern "C" double getFMODBufferDuration();


#ifdef __OBJC__

extern "C" FMOD::Sound * CreateFMODSound( NSString *name, NSString *ext, bool bStreaming );
extern "C" FMOD::Sound * CreateFMODSoundURL( NSURL *url, bool bStreaming );

#endif

extern "C" FMOD::Sound * CreateFMODSoundFromPath( const char * fullPath, bool bStreaming );

extern int fmodSystemSampleRate;
extern double invFMODSystemSampleRate;



#endif // __AUDIO_UTILS_H__