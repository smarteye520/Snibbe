//
//  FEtemplate.h
//  Gravilux
//
//  Created by Colin Roache on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#pragma once

#include "ForceEmitter.h"

class FEtemplate : ForceEmitter {
private:
	Force*		myForce;
	float		theta;
	
public:
	FEtemplate(ForceState * fs);
	~FEtemplate();
	void			simulate(float dt, float lows, float mids, float highs);
};