/*
 *  SnibbeAudioUtils.mm
 *  SnibbeLib
 *
 *  Created by Graham McDermott on 2/25/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */


#include "Uint64P.h"
#include "SnibbeAudioUtils.h"





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



