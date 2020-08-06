//
//  FEperlin.h
//  Gravilux
//
//  Created by Colin Roache on 01/22/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#pragma once

#include "ForceEmitter.h"
#include "SnibbePerlin.h"

#define NOISE_COEFFICIENT 1000.

class FEperlin : ForceEmitter {
private:
	Force*			myForce;
	SnibbePerlin*	perlinGenerator;
	float time;
	
public:
	FEperlin(ForceState * fs);
	~FEperlin();
	void			simulate(float dt, float lows, float mids, float highs);
};