/*
 *  Uint64P.h
 *  Shared
 *
 *  Created by Graham McDermott on 2/25/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */


#ifndef __UINT64P_H__
#define __UINT64P_H__




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



#endif // __UINT64P_H__