//
//  FEline.h
//  Gravilux
//
//  Created by Colin Roache on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#pragma once

#include "ForceEmitter.h"

class FEline : ForceEmitter {
private:
	Force*		bottomLeft;
	Force*		bottomRight;
	
public:
	FEline(ForceState * fs);
	~FEline();
	void			simulate(float dt, float lows, float mids, float highs);
};