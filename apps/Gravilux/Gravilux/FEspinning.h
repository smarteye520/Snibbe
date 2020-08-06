//
//  FEspinning.h
//  Gravilux
//
//  Created by Colin Roache on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#pragma once

#include "ForceEmitter.h"

class FEspinning : ForceEmitter {
private:
	Force*		spinningForce;
	float		theta;
	float		x;
	float		y;
	
public:
	FEspinning(ForceState * fs);
	~FEspinning();
	void			simulate(float dt, float lows, float mids, float highs);
};