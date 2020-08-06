//
//  FEquad.h
//  Gravilux
//
//  Created by Colin Roache on 11/01/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#pragma once

#include "ForceEmitter.h"

class FEquad : ForceEmitter {
private:
	Force		*topLeft, *topRight, *bottomLeft, *bottomRight, *middleLeft, *middleRight, *middleTop, *middleBottom;
	float		middleStrength;
	
public:
	FEquad(ForceState * fs);
	~FEquad();
	void		simulate(float dt, float lows, float mids, float highs);
};