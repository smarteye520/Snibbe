//
//  FEpushPull.h
//  Gravilux
//
//  Created by Colin Roache on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#pragma once

#include "ForceEmitter.h"

class FEpushPull : ForceEmitter {
private:
	Force		*lowsForce, *midsForce, *highsForce;
	float		rollingAverages[3];
	float		windowingFunction(float input, float* feedback);
public:
	FEpushPull(ForceState * fs);
	~FEpushPull();
	void			simulate(float dt, float lows, float mids, float highs);
};