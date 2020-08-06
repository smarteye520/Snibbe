//
//  FEspine.h
//  Gravilux
//
//  Created by Colin Roache on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#pragma once

#include "ForceEmitter.h"

class FEspine : ForceEmitter {
private:
	Force*			spineForce;
	CGRect			screenSize;
	float			integrator;
	
public:
	FEspine(ForceState * fs);
	~FEspine();
	void			simulate(float dt, float lows, float mids, float highs);
};