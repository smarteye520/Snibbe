//
//  FEupwards.h
//  Gravilux
//
//  Created by Colin Roache on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#pragma once

#include "ForceEmitter.h"

class FEupwards : ForceEmitter {
private:
	Force*		topLeft;
	Force*		topRight;
	float		theta;
	
public:
	FEupwards(ForceState * fs);
	~FEupwards();
	void			simulate(float dt, float lows, float mids, float highs);
};